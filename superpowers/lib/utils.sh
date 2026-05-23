#!/bin/bash
# Shared utilities for superpowers hooks and scripts

# Stuck-detection thresholds for the executing-plans loop, shared so the
# Stop-hook detector (loop.sh) and the PreToolUse front-stop
# (pre-tool-stuck.sh) never disagree on where the breach line sits.
# Past iteration 1 the main agent's direct-edit allow-list is ~4 files
# (handoff-state, sprint contract, evaluation report, PIVOT _index.md);
# exceeding the budget means it is doing batch work inline instead of
# spawning a coordinator.
SP_STUCK_MIN_ITER=2
SP_STUCK_EDIT_BUDGET=5
SP_STUCK_READ_BUDGET=15

# Runtime dependency check — keep one source of truth. Each hook sources
# this file; if jq or perl are missing the hook should bail soft (exit 0)
# rather than crash the user's session. Sets _SUPERPOWERS_DEPS_MISSING=1
# so the caller can guard its main work with a single check.
if [[ -z "${_SUPERPOWERS_DEPS_CHECKED:-}" ]]; then
  _SUPERPOWERS_DEPS_CHECKED=1
  _SUPERPOWERS_DEPS_MISSING_NAMES=""
  for _sp_cmd in jq perl; do
    if ! command -v "$_sp_cmd" >/dev/null 2>&1; then
      echo "warning: superpowers requires '$_sp_cmd' in PATH but did not find it; hooks will skip." >&2
      _SUPERPOWERS_DEPS_MISSING=1
      if [[ -n "$_SUPERPOWERS_DEPS_MISSING_NAMES" ]]; then
        _SUPERPOWERS_DEPS_MISSING_NAMES="${_SUPERPOWERS_DEPS_MISSING_NAMES}, ${_sp_cmd}"
      else
        _SUPERPOWERS_DEPS_MISSING_NAMES="$_sp_cmd"
      fi
    fi
  done
  unset _sp_cmd
fi

# Emit a Claude-Code-visible warning JSON to stdout (per the official hook
# protocol: stdout JSON + exit 0 surfaces a `systemMessage` to the user
# without blocking the event). Used by sync hooks (UserPromptSubmit, Stop)
# when _SUPERPOWERS_DEPS_MISSING=1 — replaces the previous silent `exit 0`
# that left the user unable to tell hooks had been skipped.
#
# This helper must NOT use jq (jq itself may be the missing dep). The
# message is fixed, embedded single-line, with no untrusted interpolation
# — `printf` produces valid JSON deterministically.
#
# Usage: emit_deps_missing_systemmessage
emit_deps_missing_systemmessage() {
  local names="${_SUPERPOWERS_DEPS_MISSING_NAMES:-jq/perl}"
  printf '{"continue":true,"systemMessage":"superpowers: missing runtime deps (%s) — hooks skipped this event. Install with `brew install jq` and/or `brew install perl`, then re-run."}\n' "$names"
}

# Resolve the project (repo) root path used by every writer that targets
# docs/retros/* under the project root.
#
# Resolution order:
#   1. ${CLAUDE_PROJECT_DIR}  — official Claude Code env var (set in every
#      hook event, and `claude` exports it in non-hook contexts as well).
#   2. `git rev-parse --show-toplevel` — fallback when running outside the
#      hook harness (e.g. test fixtures, direct CLI invocations).
#   3. ${PWD} — last-resort fallback when not in a git repo and the env var
#      is absent; preserves the pre-T-001 PWD-anchored behavior.
#
# Single source of truth — loop.sh, post-plan-diff.sh, and any future writer
# in this lib must call this helper rather than re-implementing the resolution.
# Usage: ROOT=$(repo_root)
repo_root() {
  if [[ -n "${CLAUDE_PROJECT_DIR:-}" ]]; then
    printf '%s' "$CLAUDE_PROJECT_DIR"
    return 0
  fi
  local git_root
  git_root=$(git rev-parse --show-toplevel 2>/dev/null || true)
  if [[ -n "$git_root" ]]; then
    printf '%s' "$git_root"
    return 0
  fi
  printf '%s' "${PWD:-}"
}

# Return the project-scoped state directory path (~/.claude/projects/<key>/)
# Usage: DIR=$(state_dir)
state_dir() {
  local project_key
  project_key=$(echo "${PWD:-$HOME}" | tr '/' '-')
  echo "$HOME/.claude/projects/${project_key}"
}

# Resolve the state file path for a given session ID. Strict UUID-only
# lookup — no legacy fallback to session_id="" files. Pre-v3 sessions wrote
# session_id="default"; those orphans are now cleaned via
# scripts/cleanup-legacy-state.sh, so the fallback path that existed here
# previously is dead code and a source of cross-session crosstalk.
# Returns empty string when no matching file exists.
# Usage: FILE=$(find_state_file "$SESSION_ID")
find_state_file() {
  local session_id="$1"
  local dir
  dir="$(state_dir)"
  [[ -d "$dir" ]] || return 0
  local candidate="${dir}/${session_id}.superpowers.json"
  if [[ -f "$candidate" ]]; then
    echo "$candidate"
  fi
  return 0
}

# Read a field from a JSON state file as a raw string (jq -r).
# Usage: VAL=$(state_read "$STATE_FILE" ".field")
state_read() {
  local file="$1"
  local query="$2"
  jq -r "$query" "$file" 2>/dev/null || echo ""
}

# Read a field from a JSON state file as compact JSON (jq -c). Use when the
# value will be passed back to jq via --argjson — state_read's `-r` would
# unwrap arrays/objects to text and break the round-trip.
# Usage: JSON=$(state_read_json "$STATE_FILE" '.modified_files // []')
state_read_json() {
  local file="$1"
  local query="$2"
  local out
  out=$(jq -c "$query" "$file" 2>/dev/null || true)
  [[ -z "$out" ]] && out="null"
  printf '%s' "$out"
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
# On lock-acquisition timeout, the function FAILS LOUDLY (rc=2 + stderr)
# rather than falling back to an unlocked write. The previous fallback
# traded silent clobber risk for "update applied" — empirically the
# clobber path was the bigger hazard because async PostToolUse and sync
# Stop racing on the same state file produced corrupted JSON that
# stop-hook's corruption guard then rm'd. Callers that genuinely need a
# best-effort write must check the return value and decide how to surface
# the failure (sync hooks should emit_deps_missing_systemmessage-style
# JSON; async hooks should exit 0 quietly since their stdout is not UI).
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

  # Lock contention timed out — fail loudly. Returning non-zero lets sync
  # hooks surface a systemMessage; async hooks ignoring the return are
  # losing this single update, which is strictly safer than risking an
  # unlocked clobber of a concurrent writer's in-progress tmp+mv.
  echo "warning: state_update lock timeout on $file — update dropped (no unlocked-write fallback)" >&2
  return 2
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
# Contract: empty output and exit 0 on missing/empty input — explicit `return 0`
# instead of bare `return` so a failed `[[ -f ... ]]` test does not silently
# leak rc=1 to set -e callers (would abort their pipeline).
# Usage: TEXT=$(extract_last_assistant_text "$TRANSCRIPT_PATH" [MAX_LINES])
extract_last_assistant_text() {
  local transcript_path="$1"
  local max_lines="${2:-100}"
  [[ -f "$transcript_path" ]] || return 0

  # Match either discriminator: real Claude Code transcripts tag assistant
  # lines with top-level "type":"assistant" (and carry "role":"assistant"
  # nested under .message); older / test-fixture shapes use a top-level
  # "role":"assistant". Accepting both survives the most likely schema drift
  # (the nested role field being dropped) without depending on which field is
  # canonical. The JSONL schema is an undocumented internal — see the canary
  # in lib/loop.sh that surfaces a parse failure if it changes further.
  local last_lines
  last_lines=$(grep -E '"(role|type)":"assistant"' "$transcript_path" | tail -n "$max_lines")
  [[ -z "$last_lines" ]] && return 0

  set +e
  echo "$last_lines" | jq -rs '
    map(.message.content[]? | select(.type == "text") | .text) | last // ""
  ' 2>/dev/null
  set -e
}

