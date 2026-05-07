#!/bin/bash
# Shared utilities for superpowers hooks and scripts

# Runtime dependency check — keep one source of truth. Each hook sources
# this file; if jq or perl are missing the hook should bail soft (exit 0)
# rather than crash the user's session. Sets _SUPERPOWERS_DEPS_MISSING=1
# so the caller can guard its main work with a single check.
if [[ -z "${_SUPERPOWERS_DEPS_CHECKED:-}" ]]; then
  _SUPERPOWERS_DEPS_CHECKED=1
  for _sp_cmd in jq perl; do
    if ! command -v "$_sp_cmd" >/dev/null 2>&1; then
      echo "warning: superpowers requires '$_sp_cmd' in PATH but did not find it; hooks will skip." >&2
      _SUPERPOWERS_DEPS_MISSING=1
    fi
  done
  unset _sp_cmd
fi

# Identify whether a skill name owns its own multi-phase verification (and
# therefore should bypass the generic vet phase). Keep this list in one place;
# loop.sh and vet.sh both call into it via bypass_vet_for_workflow_skill.
# Usage: if is_workflow_skill "$skill"; then ...
is_workflow_skill() {
  local skill_name="$1"
  case "$skill_name" in
    brainstorming|writing-plans|executing-plans|retrospective)
      return 0
      ;;
  esac
  return 1
}

# When the current task's skill_name is a workflow skill, clear need_vet and
# exit 0 to bypass the vet phase. Used by both the loop completion path
# (loop.sh) and the vet entrypoint (vet.sh) so the bypass logic lives in
# exactly one place. Returns 1 (no bypass) when the skill is not a workflow
# skill; never returns 0 — the bypass path exits the script directly.
# Usage: bypass_vet_for_workflow_skill "$STATE_FILE"
bypass_vet_for_workflow_skill() {
  local state_file="$1"
  local skill_name
  skill_name=$(state_read "$state_file" '.skill_name // ""')
  if is_workflow_skill "$skill_name"; then
    state_update "$state_file" 'del(.need_vet)'
    exit 0
  fi
  return 1
}

# Return the project-scoped state directory path (~/.claude/projects/<key>/)
# Usage: DIR=$(state_dir)
state_dir() {
  local project_key
  project_key=$(echo "${PWD:-$HOME}" | tr '/' '-')
  echo "$HOME/.claude/projects/${project_key}"
}

# Find the state file owned by a given session ID.
# Scans all *.superpowers.json files in the state dir, prefers an exact
# session_id match, and falls back to a legacy file without a session_id.
# Emits a stderr warning on legacy fallback so cross-session crosstalk is
# never silent — multiple concurrent Claude sessions in the same cwd are a
# known footgun and the warning is the only visible signal.
# Usage: FILE=$(find_state_file "$SESSION_ID")
find_state_file() {
  local session_id="$1"
  local dir
  dir="$(state_dir)"
  [[ -d "$dir" ]] || return 0

  # Collect matching files; handle zero matches gracefully
  local files
  files=$(find "$dir" -maxdepth 1 -name '*.superpowers.json' 2>/dev/null) || return 0
  [[ -z "$files" ]] && return 0

  local candidate
  local legacy_match=""
  local legacy_count=0
  for candidate in $files; do
    [[ -f "$candidate" ]] || continue
    local candidate_session
    candidate_session=$(jq -r '.session_id // ""' "$candidate" 2>/dev/null || echo "")
    if [[ "$candidate_session" == "$session_id" ]]; then
      echo "$candidate"
      return
    fi
    if [[ -z "$candidate_session" ]]; then
      legacy_count=$((legacy_count + 1))
      [[ -z "$legacy_match" ]] && legacy_match="$candidate"
    fi
  done

  if [[ -n "$legacy_match" ]]; then
    # Surface the count: multiple legacy files mean filesystem-order roulette
    # is picking one and silently ignoring the rest. The first-round fix only
    # warned about the picked file — that hid the multi-file footgun.
    echo "warning: find_state_file fell back to legacy file without session_id (session_id=${session_id}, file=${legacy_match}, ${legacy_count} legacy file(s) total). Cross-session crosstalk possible — consider removing stale state files." >&2
    echo "$legacy_match"
  fi
}

# Read a field from a JSON state file.
# Usage: VAL=$(state_read "$STATE_FILE" ".field")
state_read() {
  local file="$1"
  local query="$2"
  jq -r "$query" "$file" 2>/dev/null || echo ""
}

# Acquire an exclusive lock on a state file using mkdir (POSIX atomic).
# Stale locks from crashed processes are cleared via PID liveness check.
# Times out after $timeout tenths of a second (default 50 = 5s).
# macOS lacks flock(1) by default, so mkdir is the portable choice.
# Usage: acquire_state_lock "$STATE_FILE" [timeout_tenths] || handle_failure
acquire_state_lock() {
  local file="$1"
  local timeout="${2:-50}"
  local lockdir="${file}.lock"
  local elapsed=0
  while ! mkdir "$lockdir" 2>/dev/null; do
    if [[ -f "$lockdir/pid" ]]; then
      local holder
      holder=$(cat "$lockdir/pid" 2>/dev/null || echo "")
      # Use `ps -p` instead of `kill -0` — kill -0 returns non-zero on
      # macOS for alive-but-unprivileged PIDs (e.g. root processes), which
      # would falsely look dead and let us steal their lock. ps -p only
      # checks existence and works regardless of UID.
      if [[ -n "$holder" ]] && ! ps -p "$holder" >/dev/null 2>&1; then
        # Stale lock — original holder died. Reclaim.
        rm -rf "$lockdir" 2>/dev/null
        continue
      fi
    fi
    sleep 0.1
    elapsed=$((elapsed + 1))
    [[ $elapsed -ge $timeout ]] && return 1
  done
  echo $$ > "$lockdir/pid" 2>/dev/null || true
  return 0
}

# Release the lock on a state file ONLY if the current process owns it.
# This makes the function safe to register as an EXIT trap before
# acquire_state_lock — a failed acquire leaves no pid file with our PID,
# so release becomes a no-op rather than clobbering another process's lock.
# Usage: release_state_lock "$STATE_FILE"
release_state_lock() {
  local file="$1"
  local lockdir="${file}.lock"
  # No pid file ⇒ either no lock or someone else's partial init — do not touch.
  [[ -f "$lockdir/pid" ]] || return 0
  local holder
  holder=$(cat "$lockdir/pid" 2>/dev/null || echo "")
  [[ "$holder" == "$$" ]] || return 0
  rm -rf "$lockdir" 2>/dev/null || true
}

# Atomically update a JSON state file via jq filter.
# Uses tmp+mv for in-place atomic replacement and an inter-process mkdir
# lock to serialize concurrent writers — async PostToolUse hooks can
# otherwise race with sync UserPromptSubmit / Stop hooks and clobber state.
# On lock-acquisition timeout, falls back to an unlocked write rather than
# silently dropping the update — pre-locking behavior was racy but never
# silent, and silent drops would lose vet's task-synthesis result.
# Usage: state_update "$STATE_FILE" --arg key val '.field = $key'
state_update() {
  local file="$1"
  shift
  local temp="${file}.tmp.$$"

  if acquire_state_lock "$file"; then
    jq "$@" "$file" > "$temp" && mv "$temp" "$file"
    local rc=$?
    [[ -f "$temp" ]] && rm -f "$temp"
    release_state_lock "$file"
    return $rc
  fi

  # Lock contention timed out — fall back to unlocked write so the caller
  # sees their update applied. Surfaces a stderr warning so the failure
  # isn't invisible.
  echo "warning: state_update lock timeout on $file — falling back to unlocked write" >&2
  jq "$@" "$file" > "$temp" && mv "$temp" "$file"
  local rc=$?
  [[ -f "$temp" ]] && rm -f "$temp"
  return $rc
}

# Extract text from a final standalone <promise>...</promise> tag.
# Usage: TEXT=$(extract_promise_text "$MESSAGE")
extract_promise_text() {
  local msg="${1:-}"
  [[ -z "$msg" ]] && return 0
  printf '%s' "$msg" | perl -0777 -ne \
    's/\s+\z//; if (/(?:^|\n)[ \t]*<promise>([^<]*)<\/promise>[ \t]*\z/) { $x = $1; $x =~ s/^\s+|\s+$//g; $x =~ s/\s+/ /g; print $x }' \
    2>/dev/null || echo ""
}

# Extract the last assistant text block from a transcript file.
# Returns the final text content block from assistant messages.
# Usage: TEXT=$(extract_last_assistant_text "$TRANSCRIPT_PATH" [MAX_LINES])
extract_last_assistant_text() {
  local transcript_path="$1"
  local max_lines="${2:-100}"
  [[ -f "$transcript_path" ]] || return

  local last_lines
  last_lines=$(grep '"role":"assistant"' "$transcript_path" | tail -n "$max_lines")
  [[ -z "$last_lines" ]] && return

  set +e
  echo "$last_lines" | jq -rs '
    map(.message.content[]? | select(.type == "text") | .text) | last // ""
  ' 2>/dev/null
  set -e
}

# --- Vet utilities ---

# Canonical verified-tag content marker
STOP_CHAR="Fully Vetted."

# Extract content from a final standalone <verified>...</verified> tag.
# macOS-compatible: uses Perl instead of grep -P.
# Usage: TEXT=$(extract_verified_text "$MESSAGE")
extract_verified_text() {
  local msg="${1:-}"
  [[ -z "$msg" ]] && return 0
  printf '%s' "$msg" | perl -0777 -ne \
    's/\s+\z//; if (/(?:^|\n)[ \t]*<verified>([^<]*)<\/verified>[ \t]*\z/) { $x = $1; $x =~ s/^\s+|\s+$//g; $x =~ s/\s+/ /g; print $x }' \
    2>/dev/null || echo ""
}

# Send a prompt to Claude Haiku and return the text response.
# Uses Claude Code native auth via `claude --bare` (no API key env vars needed).
# Sets SUPERPOWERS_MERGE_SESSION=1 to prevent hook recursion.
# Usage: RESULT=$(run_haiku_merge "Synthesize a summary from: ...")
run_haiku_merge() {
  local prompt="${1:-}"
  [[ -z "$prompt" ]] && return 0

  # Guard against recursion — hooks check this var and exit immediately.
  # --bare also skips hook loading in the sub-session.
  export SUPERPOWERS_MERGE_SESSION=1

  # Use Claude Code native auth. --bare skips hooks/plugins to prevent recursion.
  local result
  result=$(claude --bare \
    --model claude-haiku-4-5-20251001 \
    --output-format text \
    -p "$prompt" \
    2>/dev/null) || return 0

  echo "$result"
}
