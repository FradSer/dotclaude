#!/bin/bash
#
# verify-work.sh — Stop hook: require work verification before exit
#
# Fires when Claude tries to stop. Blocks exit until Claude appends
# <verified>Fully Vetted.</verified> to confirm work is done.
#
# Verification prompt includes:
#   - task (single synthesized description from task-start.sh)
#
# Task resolution order:
#   1. Session state file (~/.claude/projects/<project-key>/<id>.vetted.json)
#   2. Transcript parsing — last-prompt entry
#   3. Generic prompt — no task context
#
# Cleanup: deletes the session state file on successful verified exit.

set -euo pipefail

# Guard: running inside the merge sub-session — exit immediately
[[ "${VETTED_MERGE_SESSION:-}" == "1" ]] && exit 0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
# shellcheck source=../lib/utils.sh
source "${SCRIPT_DIR}/../lib/utils.sh"

HOOK_INPUT=$(cat)
LAST_MSG=$(echo "$HOOK_INPUT" | jq -r '.last_assistant_message // ""')
VERIFIED_TEXT=$(extract_verified_text "$LAST_MSG")

SESSION_ID=$(echo "$HOOK_INPUT" | jq -r '.session_id // "default"')
STATE_FILE="$(state_dir)/${SESSION_ID}.vetted.json"

# Verified — clean up state file and allow exit
if [[ -n "$VERIFIED_TEXT" ]] && [[ "$VERIFIED_TEXT" = "$STOP_CHAR" ]]; then
  [[ -f "$STATE_FILE" ]] && rm -f "$STATE_FILE"
  exit 0
fi

# --- Resolve task ---

USER_PROMPT=""

if [[ -f "$STATE_FILE" ]]; then
  USER_PROMPT=$(jq -r '.task // ""' "$STATE_FILE")
fi

# Fallback: transcript's last-prompt entry (transcript_path is provided for Stop hooks)
if [[ -z "$USER_PROMPT" ]]; then
  TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | jq -r '.transcript_path // ""')
  if [[ -n "$TRANSCRIPT_PATH" ]] && [[ -f "$TRANSCRIPT_PATH" ]]; then
    set +e
    USER_PROMPT=$(grep '"type":"last-prompt"' "$TRANSCRIPT_PATH" \
      | tail -1 \
      | jq -r '.lastPrompt // ""' \
      2>/dev/null || echo "")
    set -e
  fi
fi

# --- Build verification reason ---

SYSTEM_MSG="Verification checkpoint | Append <verified>${STOP_CHAR}</verified> at the end of your response once verified (only output this when work is genuinely verified — do not lie to exit)"

build_reason() {
  local primary="$1"
  local stop="<verified>${STOP_CHAR}</verified>"
  local nl=$'\n'

  local lines="You were asked to:${nl}\"${primary}\""

  lines="${lines}${nl}${nl}Do not report back until you have verified this is actually done:${nl}- Run any code or scripts and check the output${nl}- For web apps, open the page, click through flows, confirm rendering and interactions${nl}- Test with real or representative input and inspect results${nl}- Simulate edge cases if possible${nl}- If the task has no verifiable output (pure discussion, planning), you may skip verification${nl}${nl}Once verified (or confirmed no verification needed), append ${stop} at the end of your response, then report back."

  echo "$lines"
}

if [[ -n "$USER_PROMPT" ]]; then
  REASON=$(build_reason "$USER_PROMPT")
  jq -n \
    --arg reason "$REASON" \
    --arg msg "$SYSTEM_MSG" \
    '{
      "decision": "block",
      "reason": $reason,
      "systemMessage": $msg
    }'
else
  jq -n \
    --arg stop "<verified>Fully Vetted.</verified>" \
    --arg msg "$SYSTEM_MSG" \
    '{
      "decision": "block",
      "reason": "Do not report back until you have verified your work is actually done:\n- Run any code or scripts and check the output\n- For web apps, open the page, click through flows, confirm rendering and interactions\n- Test with real or representative input and inspect results\n- Simulate edge cases if possible\n- If the task has no verifiable output (pure discussion, planning), you may skip verification\n\nOnce verified (or confirmed no verification needed), append \($stop) at the end of your response, then report back.",
      "systemMessage": $msg
    }'
fi

exit 0
