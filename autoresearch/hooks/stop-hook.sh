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

# Parse YAML frontmatter (between --- delimiters)
FRONTMATTER=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$STATE_FILE")
ITERATION=$(echo "$FRONTMATTER" | grep '^iteration:' | sed 's/iteration: *//')
MAX_ITERATIONS=$(echo "$FRONTMATTER" | grep '^max_iterations:' | sed 's/max_iterations: *//')
COMPLETION_PROMISE=$(echo "$FRONTMATTER" | grep '^completion_promise:' | sed 's/completion_promise: *//' | sed 's/^"\(.*\)"$/\1/')

# Session isolation: only respond to the session that started the loop
STATE_SESSION=$(echo "$FRONTMATTER" | grep '^session_id:' | sed 's/session_id: *//' || true)
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

# Get transcript path from hook input
TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | jq -r '.transcript_path')

if [[ ! -f "$TRANSCRIPT_PATH" ]]; then
  echo "Autoresearch: Transcript file not found: $TRANSCRIPT_PATH" >&2
  echo "Stopping loop." >&2
  rm "$STATE_FILE"
  exit 0
fi

# Check for assistant messages in transcript
if ! grep -q '"role":"assistant"' "$TRANSCRIPT_PATH"; then
  echo "Autoresearch: No assistant messages found in transcript. Stopping." >&2
  rm "$STATE_FILE"
  exit 0
fi

# Extract the most recent assistant text block (capped at last 100 lines)
LAST_LINES=$(grep '"role":"assistant"' "$TRANSCRIPT_PATH" | tail -n 100)
if [[ -z "$LAST_LINES" ]]; then
  echo "Autoresearch: Failed to extract assistant messages. Stopping." >&2
  rm "$STATE_FILE"
  exit 0
fi

set +e
LAST_OUTPUT=$(echo "$LAST_LINES" | jq -rs '
  map(.message.content[]? | select(.type == "text") | .text) | last // ""
' 2>&1)
JQ_EXIT=$?
set -e

if [[ $JQ_EXIT -ne 0 ]]; then
  echo "Autoresearch: Failed to parse assistant message JSON: $LAST_OUTPUT" >&2
  echo "Stopping loop." >&2
  rm "$STATE_FILE"
  exit 0
fi

# Check for completion promise
if [[ "$COMPLETION_PROMISE" != "null" ]] && [[ -n "$COMPLETION_PROMISE" ]]; then
  PROMISE_TEXT=$(echo "$LAST_OUTPUT" | perl -0777 -pe 's/.*?<promise>(.*?)<\/promise>.*/$1/s; s/^\s+|\s+$//g; s/\s+/ /g' 2>/dev/null || echo "")
  if [[ -n "$PROMISE_TEXT" ]] && [[ "$PROMISE_TEXT" = "$COMPLETION_PROMISE" ]]; then
    echo "Autoresearch loop: Detected <promise>$COMPLETION_PROMISE</promise> — research complete."
    rm "$STATE_FILE"
    exit 0
  fi
fi

# Continue loop — increment iteration and feed prompt back
NEXT_ITERATION=$((ITERATION + 1))

# Extract prompt (everything after the closing ---)
PROMPT_TEXT=$(awk '/^---$/{i++; next} i>=2' "$STATE_FILE")

if [[ -z "$PROMPT_TEXT" ]]; then
  echo "Autoresearch: State file missing prompt text. Stopping." >&2
  rm "$STATE_FILE"
  exit 0
fi

# Atomically update iteration counter
TEMP_FILE="${STATE_FILE}.tmp.$$"
sed "s/^iteration: .*/iteration: $NEXT_ITERATION/" "$STATE_FILE" > "$TEMP_FILE"
mv "$TEMP_FILE" "$STATE_FILE"

# Build system message
if [[ "$COMPLETION_PROMISE" != "null" ]] && [[ -n "$COMPLETION_PROMISE" ]]; then
  SYSTEM_MSG="Autoresearch experiment $NEXT_ITERATION | To stop: output <promise>$COMPLETION_PROMISE</promise> (ONLY when genuinely true)"
else
  SYSTEM_MSG="Autoresearch experiment $NEXT_ITERATION | Loop runs indefinitely — use /autoresearch:cancel to stop manually"
fi

# Block exit and inject research prompt
jq -n \
  --arg prompt "$PROMPT_TEXT" \
  --arg msg "$SYSTEM_MSG" \
  '{
    "decision": "block",
    "reason": $prompt,
    "systemMessage": $msg
  }'

exit 0
