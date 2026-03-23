#!/bin/bash
#
# verify-work.sh — Stop hook: require work verification before exit
#
# Fires when Claude tries to stop. Blocks exit until Claude appends
# <verified>Fully Vetted.</verified> to confirm work is done.
#
# Also merges any pending_prompt (deferred from task-start.sh) with the
# assistant's response before verification — this ensures the task description
# reflects what Claude actually did, not just what was requested.
#
# Verification prompt includes:
#   - task (synthesized description, merged at Stop time with full context)
#
# Task resolution order:
#   1. Session state file (~/.claude/projects/<project-key>/<id>.vetted.json)
#   2. Transcript parsing — last-prompt entry
#   3. Generic prompt — no task context
#
# State file persists across turns — task evolves as prompts accumulate.
# On verified exit, the task is updated with this turn's output.

set -euo pipefail

# Guard: running inside the merge sub-session — exit immediately
[[ "${VETTED_MERGE_SESSION:-}" == "1" ]] && exit 0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
# shellcheck source=../lib/utils.sh
source "${SCRIPT_DIR}/../lib/utils.sh"

HOOK_INPUT=$(cat)

# Extract structured fields in one pass (safe for @tsv: IDs and paths only)
# last_assistant_message extracted separately because it may contain tabs/newlines
read -r SESSION_ID TRANSCRIPT_PATH < <(
  echo "$HOOK_INPUT" | jq -r '[.session_id // "default", .transcript_path // ""] | @tsv'
)
LAST_MSG=$(echo "$HOOK_INPUT" | jq -r '.last_assistant_message // ""')
VERIFIED_TEXT=$(extract_verified_text "$LAST_MSG")
STATE_FILE="$(state_dir)/${SESSION_ID}.vetted.json"

# Verified — merge this turn's output into evolving task, keep state file
if [[ -n "$VERIFIED_TEXT" ]] && [[ "$VERIFIED_TEXT" = "$STOP_CHAR" ]]; then
  if [[ -f "$STATE_FILE" ]]; then
    CURRENT_TASK=$(jq -r '.task // ""' "$STATE_FILE")
    TURN_OUTPUT="${LAST_MSG:0:500}"

    if [[ -n "$CURRENT_TASK" && -n "$TURN_OUTPUT" ]]; then
      MERGED=$(run_haiku_merge "Update this task description to reflect what was accomplished. Output only the updated task — no explanation, no preamble, no quotes.
Task: ${CURRENT_TASK}
What was done: ${TURN_OUTPUT}")

      if [[ -n "$MERGED" ]]; then
        NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        TEMP="${STATE_FILE}.tmp.$$"
        jq \
          --arg task "$MERGED" \
          --arg ts "$NOW" \
          '.task = $task | .updated_at = $ts' \
          "$STATE_FILE" > "$TEMP" && mv "$TEMP" "$STATE_FILE"
      fi
    fi
  fi
  exit 0
fi

# --- Merge pending prompt (deferred from UserPromptSubmit) ---

if [[ -f "$STATE_FILE" ]]; then
  # Single-pass extraction of pending_prompt and task from state file
  PENDING_PROMPT=$(jq -r '.pending_prompt // ""' "$STATE_FILE")
  EXISTING_TASK=$(jq -r '.task // ""' "$STATE_FILE")

  if [[ -n "$PENDING_PROMPT" && "$PENDING_PROMPT" != "null" ]]; then
    NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # LAST_MSG already holds the current turn's assistant response (from hook input)
    LAST_ASSISTANT="${LAST_MSG:0:500}"

    MERGED=""
    if [[ -n "$EXISTING_TASK" && "$EXISTING_TASK" != "$PENDING_PROMPT" ]]; then
      MERGE_INPUT="Combine the following into a single concise task statement. Output only the merged task — no explanation, no preamble, no quotes.
Existing task: ${EXISTING_TASK}
New input: ${PENDING_PROMPT}"

      if [[ -n "$LAST_ASSISTANT" ]]; then
        MERGE_INPUT="${MERGE_INPUT}
Assistant response (what was done): ${LAST_ASSISTANT}"
      fi

      MERGED=$(run_haiku_merge "$MERGE_INPUT")
      [[ -z "$MERGED" ]] && MERGED="${EXISTING_TASK} — updated: ${PENDING_PROMPT}"
    else
      MERGED="$PENDING_PROMPT"
    fi

    TEMP="${STATE_FILE}.tmp.$$"
    jq \
      --arg task "$MERGED" \
      --arg ts "$NOW" \
      '.task = $task | .updated_at = $ts | del(.pending_prompt)' \
      "$STATE_FILE" > "$TEMP" && mv "$TEMP" "$STATE_FILE"
  fi
fi

# --- Resolve task ---

USER_PROMPT=""

if [[ -f "$STATE_FILE" ]]; then
  USER_PROMPT=$(jq -r '.task // ""' "$STATE_FILE")
fi

# Fallback: transcript's last-prompt entry (transcript_path extracted at top)
if [[ -z "$USER_PROMPT" ]]; then
  if [[ -n "$TRANSCRIPT_PATH" ]] && [[ -f "$TRANSCRIPT_PATH" ]]; then
    set +e
    USER_PROMPT=$(grep '"type":"last-prompt"' "$TRANSCRIPT_PATH" \
      | tail -1 \
      | jq -r '.lastPrompt // ""' \
      2>/dev/null || echo "")
    set -e
  fi
fi

# --- Build verification message ---

STOP_TAG="<verified>${STOP_CHAR}</verified>"

build_system_message() {
  local primary="$1"
  local NL=$'\n'

  local msg="# Verification Checkpoint"
  msg="${msg}${NL}${NL}You were asked to:${NL}> ${primary}"
  msg="${msg}${NL}${NL}## Verification Steps${NL}Do not report back until you have verified this is actually done:"
  msg="${msg}${NL}- Run any code or scripts and check the output"
  msg="${msg}${NL}- For web apps, open the page, click through flows, confirm rendering and interactions"
  msg="${msg}${NL}- Test with real or representative input and inspect results"
  msg="${msg}${NL}- Simulate edge cases if possible"
  msg="${msg}${NL}- If the task has no verifiable output (pure discussion, planning), you may skip verification"
  msg="${msg}${NL}${NL}Once verified (or confirmed no verification needed), append \`${STOP_TAG}\` at the end of your response, then report back."
  msg="${msg}${NL}${NL}**Only output the verified tag when you have genuinely verified the work — do not lie to exit.**"

  echo "$msg"
}

if [[ -n "$USER_PROMPT" ]]; then
  MSG=$(build_system_message "$USER_PROMPT")
  jq -n --arg msg "$MSG" '{"systemMessage": $msg}' >&2
else
  NL=$'\n'
  MSG="# Verification Checkpoint${NL}${NL}Do not report back until you have verified your work is actually done:${NL}- Run any code or scripts and check the output${NL}- For web apps, open the page, click through flows, confirm rendering and interactions${NL}- Test with real or representative input and inspect results${NL}- Simulate edge cases if possible${NL}- If the task has no verifiable output (pure discussion, planning), you may skip verification${NL}${NL}Once verified (or confirmed no verification needed), append \`${STOP_TAG}\` at the end of your response, then report back.${NL}${NL}**Only output the verified tag when you have genuinely verified the work — do not lie to exit.**"
  jq -n --arg msg "$MSG" '{"systemMessage": $msg}' >&2
fi

exit 2
