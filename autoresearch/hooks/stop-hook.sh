#!/bin/bash

# Autoresearch Stop Hook
# Prevents session exit when an autoresearch loop is active.
# Feeds the same research prompt back to Claude to continue the experiment loop.

set -euo pipefail

HOOK_INPUT=$(cat)

STATE_FILE=".claude/autoresearch.local.md"

if [[ ! -f "$STATE_FILE" ]]; then
  exit 0
fi

# Parse YAML frontmatter — strictly the first --- ... --- block, so a later
# `---` inside the prompt body (e.g. the output-format reference) can't leak in.
FRONTMATTER=$(awk '/^---$/{n++; next} n==1{print} n>=2{exit}' "$STATE_FILE")

# Read one frontmatter field by key. Uses awk (not grep|sed): a missing key
# prints nothing and exits 0, so an absent field can't trip `set -e`/pipefail
# and abort before the corruption handlers below get a chance to clean up.
fm_get() {
  awk -v key="$1" '
    index($0, key ":") == 1 {
      val = substr($0, length(key) + 2)
      sub(/^ */, "", val)
      print val
      exit
    }
  ' <<< "$FRONTMATTER"
}

# Strip optional YAML double quotes from a scalar value.
# Inverse of the yaml_escape() in setup-autoresearch.sh — if you change one,
# update the other to preserve round-trip fidelity.
fm_unquote() {
  local v="$1"
  if [[ "$v" =~ ^\"(.*)\"$ ]]; then
    v="${BASH_REMATCH[1]}"
    v="${v//\\\"/\"}"
    v="${v//\\\\/\\}"
  fi
  printf '%s' "$v"
}

# Abort: print message, remove state file, exit cleanly.
abort_cleanup() {
  echo "Autoresearch: $*" >&2
  rm -f "$STATE_FILE"
  exit 0
}

# Validate a field is a non-negative integer; abort with a specific message if not.
require_uint() {
  local name="$1" val="$2"
  if [[ ! "$val" =~ ^[0-9]+$ ]]; then
    abort_cleanup "State file corrupted — '$name' is not a number (got: '$val'). Removing state file. Run /autoresearch:start to start fresh."
  fi
}

ITERATION=$(fm_get iteration)
MAX_ITERATIONS=$(fm_get max_iterations)
MAX_SECONDS=$(fm_get max_seconds)
STARTED_AT_EPOCH=$(fm_get started_at_epoch)
COMPLETION_PROMISE=$(fm_unquote "$(fm_get completion_promise)")
HAS_PROMISE=false
if [[ "$COMPLETION_PROMISE" != "null" ]] && [[ -n "$COMPLETION_PROMISE" ]]; then
  HAS_PROMISE=true
fi

# Session isolation: only respond to the session that started the loop.
# Extract both fields from hook input in one jq call.
read -r HOOK_SESSION TRANSCRIPT_PATH < <(
  echo "$HOOK_INPUT" | jq -r '[.session_id // "", .transcript_path // ""] | @tsv' 2>/dev/null || echo ""
)
STATE_SESSION=$(fm_unquote "$(fm_get session_id)")

if [[ -z "$STATE_SESSION" ]]; then
  abort_cleanup "State file missing session_id — removing stale state."
fi

if [[ "$STATE_SESSION" != "$HOOK_SESSION" ]]; then
  abort_cleanup "Session mismatch (state vs hook) — removing stale state. If another session started this loop, use that session or /autoresearch:cancel."
fi

# Validate numeric fields
require_uint iteration "$ITERATION"
require_uint max_iterations "$MAX_ITERATIONS"
require_uint max_seconds "$MAX_SECONDS"

# Reject unbounded state (setup enforces bounds at creation; tampering must not disable them).
if [[ $MAX_ITERATIONS -eq 0 ]] && [[ $MAX_SECONDS -eq 0 ]]; then
  abort_cleanup "State file has no stopping bounds — removing stale state."
fi

# Check max iterations
if [[ $MAX_ITERATIONS -gt 0 ]] && [[ $ITERATION -ge $MAX_ITERATIONS ]]; then
  echo "Autoresearch loop: Max experiments ($MAX_ITERATIONS) reached."
  rm -f "$STATE_FILE"
  exit 0
fi

# Check wall-clock budget (independent of iteration count, so a stuck or
# fast-spinning agent still terminates). Only enforced when both fields are
# valid integers; a missing/corrupt epoch must not silently disable the bound.
if [[ $MAX_SECONDS -gt 0 ]]; then
  require_uint started_at_epoch "${STARTED_AT_EPOCH:-}"
  NOW_EPOCH=$(date +%s)
  ELAPSED=$((NOW_EPOCH - STARTED_AT_EPOCH))
  if [[ $ELAPSED -lt 0 ]]; then
    ELAPSED=0
  fi
  if [[ $ELAPSED -ge $MAX_SECONDS ]]; then
    echo "Autoresearch loop: Wall-clock budget (${MAX_SECONDS}s) reached after ${ELAPSED}s."
    rm -f "$STATE_FILE"
    exit 0
  fi
fi

# Completion-promise detection (only when a promise is configured). The
# transcript is read solely for this check, so any failure to read or parse it
# is treated as transient: warn and keep looping — never delete state or stop
# the run over a momentarily-unreadable transcript.
if [[ "$HAS_PROMISE" == true ]]; then

  LAST_OUTPUT=""
  if [[ -n "$TRANSCRIPT_PATH" ]] && [[ -f "$TRANSCRIPT_PATH" ]]; then
    # Parse each line with jq (role spacing/format tolerant). `try fromjson`
    # (not `fromjson?`) keeps this working on jq 1.5.
    LAST_OUTPUT=$(tail -n 200 "$TRANSCRIPT_PATH" 2>/dev/null \
      | jq -R -r 'try fromjson
        | select((.role == "assistant") or (.message.role == "assistant"))
        | (.message.content // .content // [])[]
        | select(.type == "text") | .text' 2>/dev/null \
      | tail -n 1 || true)
  else
    echo "Autoresearch: Transcript unreadable this round — skipping promise check, continuing loop." >&2
  fi

  if [[ -n "$LAST_OUTPUT" ]]; then
    # Extract only the <promise>...</promise> content; prints nothing when the
    # tag is absent (so a single-token phrase can't match the whole message).
    PROMISE_TEXT=$(echo "$LAST_OUTPUT" | perl -0777 -ne 'if (m{<promise>(.*?)</promise>}s) { my $p=$1; $p =~ s/^\s+|\s+$//g; $p =~ s/\s+/ /g; print $p }' 2>/dev/null || echo "")
    if [[ -n "$PROMISE_TEXT" ]] && [[ "$PROMISE_TEXT" = "$COMPLETION_PROMISE" ]]; then
      echo "Autoresearch loop: Detected <promise>$COMPLETION_PROMISE</promise> — research complete."
      rm -f "$STATE_FILE"
      exit 0
    fi
  fi
fi

# Continue loop — increment iteration and feed prompt back
NEXT_ITERATION=$((ITERATION + 1))

# Extract prompt — everything after the 2nd `---`, preserving any later `---`
# lines in the body (e.g. the output-format reference block).
PROMPT_TEXT=$(awk 'seen>=2{print; next} /^---$/{seen++}' "$STATE_FILE")

if [[ -z "$PROMPT_TEXT" ]]; then
  abort_cleanup "State file missing prompt text. Stopping."
fi

# Atomically update iteration counter — anchored to the first frontmatter
# block so a stray `iteration:`-like line in the prompt body is never touched.
TEMP_FILE="${STATE_FILE}.tmp.$$"
awk -v n="$NEXT_ITERATION" '
  /^---$/ { blk++; print; next }
  blk == 1 && /^iteration:/ { print "iteration: " n; next }
  { print }
' "$STATE_FILE" > "$TEMP_FILE"
mv "$TEMP_FILE" "$STATE_FILE"

# Build system message
if [[ "$HAS_PROMISE" == true ]]; then
  SYSTEM_MSG="Autoresearch experiment $NEXT_ITERATION | To stop: output <promise>$COMPLETION_PROMISE</promise> (ONLY when genuinely true)"
else
  SYSTEM_MSG="Autoresearch experiment $NEXT_ITERATION | Runs until the configured bound — /autoresearch:cancel to stop early"
fi

# Block exit and feed the research prompt back. For a Stop hook, `reason` is
# the field fed back to Claude when `decision` is "block" — it becomes the next
# instruction, so the full prompt goes here (matching Anthropic's ralph-loop).
# `additionalContext` is NOT honored for Stop events (only SessionStart /
# UserPromptSubmit), so it must not carry the prompt. `systemMessage` shows the
# user the experiment counter / how to stop.
if ! jq -n \
  --arg prompt "$PROMPT_TEXT" \
  --arg msg "$SYSTEM_MSG" \
  '{
    "decision": "block",
    "reason": $prompt,
    "systemMessage": $msg
  }'; then
  echo "Autoresearch: Failed to emit stop-hook response — removing state to avoid a stuck loop." >&2
  rm -f "$STATE_FILE"
fi

exit 0
