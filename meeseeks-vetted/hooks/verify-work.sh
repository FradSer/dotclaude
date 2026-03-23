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

# Verified — synthesize final task summary, keep state file
if [[ -n "$VERIFIED_TEXT" ]] && [[ "$VERIFIED_TEXT" = "$STOP_CHAR" ]]; then
  if [[ -f "$STATE_FILE" ]]; then
    CURRENT_TASK=$(jq -r '.task // ""' "$STATE_FILE")
    TURN_OUTPUT="${LAST_MSG:0:500}"

    if [[ -n "$CURRENT_TASK" && -n "$TURN_OUTPUT" ]]; then
      MERGED=$(run_haiku_merge "Synthesize a one-sentence task summary from the inputs below. Extract the core intent and outcome — discard noise, hooks output, and duplicated context. Plain text only, no quotes.
Task: ${CURRENT_TASK}
Outcome: ${TURN_OUTPUT}")

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
      MERGE_INPUT="Distill these inputs into one concise task sentence. Keep only the core intent and any new direction — strip duplicated context, hook output, and verbose details. Plain text only, no quotes.
Previous: ${EXISTING_TASK}
New direction: ${PENDING_PROMPT}"

      if [[ -n "$LAST_ASSISTANT" ]]; then
        MERGE_INPUT="${MERGE_INPUT}
Done so far: ${LAST_ASSISTANT}"
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

# --- Resolve task and changes ---

USER_PROMPT=""
CHANGES_SUMMARY=""

if [[ -f "$STATE_FILE" ]]; then
  USER_PROMPT=$(jq -r '.task // ""' "$STATE_FILE")

  # Read modified_files from state and build a changes summary
  MODIFIED_FILES=()
  while IFS= read -r f; do
    [[ -n "$f" && "$f" != "null" ]] && MODIFIED_FILES+=("$f")
  done < <(jq -r '.modified_files // [] | .[]' "$STATE_FILE" 2>/dev/null)

  if [[ ${#MODIFIED_FILES[@]} -gt 0 ]]; then
    CHANGES_SUMMARY=$(build_changes_section "${MODIFIED_FILES[@]}")
  fi
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
  local changes="${2:-}"
  local NL=$'\n'

  local msg="# Verification Checkpoint"
  msg="${msg}${NL}${NL}You were asked to:${NL}> ${primary}"

  if [[ -n "$changes" ]]; then
    msg="${msg}${NL}${NL}## Changes Made${NL}\`\`\`${NL}${changes}${NL}\`\`\`"
  fi

  msg="${msg}${NL}${NL}## Verification Steps${NL}First, classify the task: was it a discussion/question or an implementation request?"
  msg="${msg}${NL}${NL}**If discussion/question** (analysis, problem investigation, exploring options):${NL}- Verify your analysis is grounded in evidence (code reads, logs, docs)${NL}- Confirm you presented findings without prematurely offering to implement a fix${NL}- Skip code execution verification — this is not an implementation task"
  msg="${msg}${NL}${NL}**If implementation request** (build, fix, change, create):${NL}- Run any code or scripts and check the output"
  msg="${msg}${NL}- For web apps, open the page, click through flows, confirm rendering and interactions"
  msg="${msg}${NL}- Test with real or representative input and inspect results"
  msg="${msg}${NL}- Simulate edge cases if possible"
  msg="${msg}${NL}${NL}Once verified (or confirmed no verification needed), append \`${STOP_TAG}\` at the end of your response, then report back."
  msg="${msg}${NL}${NL}**Only output the verified tag when you have genuinely verified the work — do not lie to exit.**"

  echo "$msg"
}

if [[ -n "$USER_PROMPT" ]]; then
  MSG=$(build_system_message "$USER_PROMPT" "$CHANGES_SUMMARY")
  jq -n --arg msg "$MSG" '{"systemMessage": $msg}' >&2
else
  NL=$'\n'
  MSG="# Verification Checkpoint${NL}${NL}First, classify the task: was it a discussion/question or an implementation request?${NL}${NL}**If discussion/question** (analysis, problem investigation, exploring options):${NL}- Verify your analysis is grounded in evidence${NL}- Confirm you presented findings without prematurely offering to implement${NL}- Skip code execution verification${NL}${NL}**If implementation request** (build, fix, change, create):${NL}- Run any code or scripts and check the output${NL}- For web apps, open the page, click through flows, confirm rendering and interactions${NL}- Test with real or representative input and inspect results${NL}- Simulate edge cases if possible${NL}${NL}Once verified (or confirmed no verification needed), append \`${STOP_TAG}\` at the end of your response, then report back.${NL}${NL}**Only output the verified tag when you have genuinely verified the work — do not lie to exit.**"
  jq -n --arg msg "$MSG" '{"systemMessage": $msg}' >&2
fi

exit 2
