#!/bin/bash

# Superpower Loop Stop Hook
# Prevents session exit when a superpower-loop is active
# Feeds Claude's output back as input to continue the loop

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
# shellcheck source=../lib/utils.sh
source "${SCRIPT_DIR}/../lib/utils.sh"

# Read hook input from stdin
HOOK_INPUT=$(cat)

HOOK_SESSION=$(echo "$HOOK_INPUT" | jq -r '.session_id // ""')

# Find the state file owned by this session
SUPERPOWER_STATE_FILE=$(find_state_file "$HOOK_SESSION")

if [[ -z "$SUPERPOWER_STATE_FILE" ]]; then
  # No active loop for this session - allow exit
  exit 0
fi

# Read all fields from JSON state in one pass
ITERATION=$(state_read "$SUPERPOWER_STATE_FILE" '.iteration // 0')
MAX_ITERATIONS=$(state_read "$SUPERPOWER_STATE_FILE" '.max_iterations // 0')
COMPLETION_PROMISE=$(state_read "$SUPERPOWER_STATE_FILE" '.completion_promise // ""')
PROMPT=$(state_read "$SUPERPOWER_STATE_FILE" '.prompt // ""')

# Validate numeric fields
if [[ ! "$ITERATION" =~ ^[0-9]+$ ]]; then
  echo "Warning: Superpower loop: State file corrupted" >&2
  echo "   File: $SUPERPOWER_STATE_FILE" >&2
  echo "   Problem: 'iteration' is not a valid number (got: '$ITERATION')" >&2
  echo "   Superpower loop is stopping. Run /superpower-loop again to start fresh." >&2
  rm "$SUPERPOWER_STATE_FILE"
  exit 0
fi

if [[ ! "$MAX_ITERATIONS" =~ ^[0-9]+$ ]]; then
  echo "Warning: Superpower loop: State file corrupted" >&2
  echo "   File: $SUPERPOWER_STATE_FILE" >&2
  echo "   Problem: 'max_iterations' is not a valid number (got: '$MAX_ITERATIONS')" >&2
  echo "   Superpower loop is stopping. Run /superpower-loop again to start fresh." >&2
  rm "$SUPERPOWER_STATE_FILE"
  exit 0
fi

# Check if max iterations reached
if [[ $MAX_ITERATIONS -gt 0 ]] && [[ $ITERATION -ge $MAX_ITERATIONS ]]; then
  echo "Superpower loop: Max iterations ($MAX_ITERATIONS) reached."
  rm "$SUPERPOWER_STATE_FILE"
  exit 0
fi

# Get transcript path from hook input
TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | jq -r '.transcript_path')

if [[ ! -f "$TRANSCRIPT_PATH" ]]; then
  rm "$SUPERPOWER_STATE_FILE"
  exit 0
fi

# Verify transcript has assistant messages
if ! grep -q '"role":"assistant"' "$TRANSCRIPT_PATH"; then
  echo "Warning: Superpower loop: No assistant messages found in transcript" >&2
  echo "   Superpower loop is stopping." >&2
  rm "$SUPERPOWER_STATE_FILE"
  exit 0
fi

# Extract the last assistant text block
LAST_OUTPUT=$(extract_last_assistant_text "$TRANSCRIPT_PATH" 100)

if [[ -z "$LAST_OUTPUT" ]]; then
  echo "Warning: Superpower loop: Failed to extract assistant message" >&2
  echo "   Superpower loop is stopping." >&2
  rm "$SUPERPOWER_STATE_FILE"
  exit 0
fi

# Check for completion promise (only if set)
if [[ -n "$COMPLETION_PROMISE" ]] && [[ "$COMPLETION_PROMISE" != "null" ]]; then
  PROMISE_TEXT=$(extract_promise_text "$LAST_OUTPUT")

  # Use = for literal string comparison (not glob pattern matching)
  if [[ -n "$PROMISE_TEXT" ]] && [[ "$PROMISE_TEXT" = "$COMPLETION_PROMISE" ]]; then
    echo "Superpower loop: Detected <promise>$COMPLETION_PROMISE</promise>"
    rm "$SUPERPOWER_STATE_FILE"
    exit 0
  fi
fi

# Not complete - continue loop
NEXT_ITERATION=$((ITERATION + 1))

if [[ -z "$PROMPT" ]]; then
  echo "Warning: Superpower loop: State file has no prompt" >&2
  echo "   Superpower loop is stopping." >&2
  rm "$SUPERPOWER_STATE_FILE"
  exit 0
fi

# Update iteration atomically
NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
state_update "$SUPERPOWER_STATE_FILE" \
  --argjson iter "$NEXT_ITERATION" \
  --arg ts "$NOW" \
  '.iteration = $iter | .updated_at = $ts'

# Build system message
if [[ -n "$COMPLETION_PROMISE" ]] && [[ "$COMPLETION_PROMISE" != "null" ]]; then
  SYSTEM_MSG="Superpower loop iteration $NEXT_ITERATION | To stop: output <promise>$COMPLETION_PROMISE</promise> (ONLY when statement is TRUE - do not lie to exit!)"
else
  SYSTEM_MSG="Superpower loop iteration $NEXT_ITERATION | No completion promise set - loop runs infinitely"
fi

# Append completion instruction to prompt for context continuity
if [[ -n "$COMPLETION_PROMISE" ]] && [[ "$COMPLETION_PROMISE" != "null" ]]; then
  INJECTED_PROMPT="${PROMPT}

---
LOOP COMPLETION REQUIRED: When the above task is genuinely complete, output the following tag as the very last line of your response — nothing after it:
<promise>${COMPLETION_PROMISE}</promise>"
else
  INJECTED_PROMPT="$PROMPT"
fi

# Output JSON to block the stop and feed prompt back
jq -n \
  --arg prompt "$INJECTED_PROMPT" \
  --arg msg "$SYSTEM_MSG" \
  '{
    "decision": "block",
    "reason": $prompt,
    "systemMessage": $msg
  }'

exit 0
