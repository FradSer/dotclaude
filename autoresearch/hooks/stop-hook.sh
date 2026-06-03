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

ITERATION=$(fm_get iteration)
MAX_ITERATIONS=$(fm_get max_iterations)
MAX_SECONDS=$(fm_get max_seconds)
STARTED_AT_EPOCH=$(fm_get started_at_epoch)
COMPLETION_PROMISE=$(fm_get completion_promise | sed 's/^"\(.*\)"$/\1/')

# Session isolation: only respond to the session that started the loop
STATE_SESSION=$(fm_get session_id)
HOOK_SESSION=$(echo "$HOOK_INPUT" | jq -r '.session_id // ""')
if [[ -n "$STATE_SESSION" ]] && [[ "$STATE_SESSION" != "$HOOK_SESSION" ]]; then
  exit 0
fi

# Validate numeric fields
if [[ ! "$ITERATION" =~ ^[0-9]+$ ]]; then
  echo "Autoresearch: State file corrupted — 'iteration' is not a number (got: '$ITERATION')" >&2
  echo "Removing state file. Run /autoresearch:start to start fresh." >&2
  rm "$STATE_FILE"
  exit 0
fi

if [[ ! "$MAX_ITERATIONS" =~ ^[0-9]+$ ]]; then
  echo "Autoresearch: State file corrupted — 'max_iterations' is not a number (got: '$MAX_ITERATIONS')" >&2
  echo "Removing state file. Run /autoresearch:start to start fresh." >&2
  rm "$STATE_FILE"
  exit 0
fi

# Check max iterations
if [[ $MAX_ITERATIONS -gt 0 ]] && [[ $ITERATION -ge $MAX_ITERATIONS ]]; then
  echo "Autoresearch loop: Max experiments ($MAX_ITERATIONS) reached."
  rm "$STATE_FILE"
  exit 0
fi

# Check wall-clock budget (independent of iteration count, so a stuck or
# fast-spinning agent still terminates). Only enforced when both fields are
# valid integers; a missing/corrupt epoch must not silently disable the bound.
if [[ "${MAX_SECONDS:-0}" =~ ^[0-9]+$ ]] && [[ $MAX_SECONDS -gt 0 ]]; then
  if [[ ! "${STARTED_AT_EPOCH:-}" =~ ^[0-9]+$ ]]; then
    echo "Autoresearch: State file corrupted — 'started_at_epoch' is not a number (got: '${STARTED_AT_EPOCH:-}')" >&2
    echo "Removing state file. Run /autoresearch:start to start fresh." >&2
    rm "$STATE_FILE"
    exit 0
  fi
  NOW_EPOCH=$(date +%s)
  ELAPSED=$((NOW_EPOCH - STARTED_AT_EPOCH))
  if [[ $ELAPSED -ge $MAX_SECONDS ]]; then
    echo "Autoresearch loop: Wall-clock budget (${MAX_SECONDS}s) reached after ${ELAPSED}s."
    rm "$STATE_FILE"
    exit 0
  fi
fi

# Completion-promise detection (only when a promise is configured). The
# transcript is read solely for this check, so any failure to read or parse it
# is treated as transient: warn and keep looping — never delete state or stop
# the run over a momentarily-unreadable transcript.
if [[ "$COMPLETION_PROMISE" != "null" ]] && [[ -n "$COMPLETION_PROMISE" ]]; then
  TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | jq -r '.transcript_path // ""')

  LAST_OUTPUT=""
  if [[ -n "$TRANSCRIPT_PATH" ]] && [[ -f "$TRANSCRIPT_PATH" ]]; then
    # Parse each line independently with `try fromjson` so a single truncated or
    # malformed line (e.g. one still being flushed) cannot abort the whole
    # extraction. `try fromjson` (not `fromjson?`) keeps this working on jq 1.5.
    # Take the most recent assistant text block.
    LAST_OUTPUT=$(grep '"role":"assistant"' "$TRANSCRIPT_PATH" 2>/dev/null | tail -n 100 \
      | jq -R -r 'try fromjson | .message.content[]? | select(.type == "text") | .text' 2>/dev/null \
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
      rm "$STATE_FILE"
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
  echo "Autoresearch: State file missing prompt text. Stopping." >&2
  rm "$STATE_FILE"
  exit 0
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
if [[ "$COMPLETION_PROMISE" != "null" ]] && [[ -n "$COMPLETION_PROMISE" ]]; then
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
jq -n \
  --arg prompt "$PROMPT_TEXT" \
  --arg msg "$SYSTEM_MSG" \
  '{
    "decision": "block",
    "reason": $prompt,
    "systemMessage": $msg
  }'

exit 0
