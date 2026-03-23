#!/bin/bash
#
# task-start.sh — UserPromptSubmit hook: enforce task clarity before execution
#
# Fires when the user submits a prompt. Does two things:
#   1. Persists a single synthesized task description to a session-scoped state
#      file so verify-work.sh can inject the current task without parsing the
#      transcript.
#      - First prompt: task = user_prompt (verbatim).
#      - Subsequent prompts: call claude --print (haiku) to merge the existing
#        task and the new prompt into one coherent sentence.
#      Calls claude --print with VETTED_MERGE_SESSION=1 to suppress hooks in
#      the merge sub-session (all three hooks exit 0 immediately when set).
#   2. Instructs Claude to evaluate completion criteria and ask the user via
#      AskUserQuestion if the task is too vague to deliver.
#
# State file: ~/.claude/projects/<project-key>/<session_id>.vetted.json
#   project-key = $PWD with '/' replaced by '-'
# Cleanup: verify-work.sh deletes the file on successful verified exit.

set -euo pipefail

# Guard: running inside the merge sub-session — skip everything
[[ "${VETTED_MERGE_SESSION:-}" == "1" ]] && exit 0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
# shellcheck source=../lib/utils.sh
source "${SCRIPT_DIR}/../lib/utils.sh"

HOOK_INPUT=$(cat)

SESSION_ID=$(echo "$HOOK_INPUT" | jq -r '.session_id // "default"')
USER_PROMPT=$(echo "$HOOK_INPUT" | jq -r '.prompt // ""')

# Fallback: parse transcript for the user's last message
if [[ -z "$USER_PROMPT" || "$USER_PROMPT" == "null" ]]; then
  TRANSCRIPT_FILE=$(echo "$HOOK_INPUT" | jq -r '.transcript_path // ""')
  if [[ -n "$TRANSCRIPT_FILE" && -f "$TRANSCRIPT_FILE" ]]; then
    USER_PROMPT=$(grep '"type":"user"' "$TRANSCRIPT_FILE" \
      | grep -v '"isMeta":true' \
      | tail -1 \
      | jq -r '.message.content | if type == "string" then . elif type == "array" then (map(select(.type == "text") | .text // "") | join(" ")) else "" end' \
      2>/dev/null || echo "")
  fi
fi

# Skip slash commands — user_prompt contains <command-name> XML when a slash command fires
if echo "$USER_PROMPT" | grep -q '<command-name>'; then
  exit 0
fi

STATE_DIR="$(state_dir)"
mkdir -p "$STATE_DIR"
STATE_FILE="${STATE_DIR}/${SESSION_ID}.vetted.json"
NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Extract last assistant message from transcript for merge context (truncated)
LAST_ASSISTANT=""
TRANSCRIPT_FILE=$(echo "$HOOK_INPUT" | jq -r '.transcript_path // ""')
if [[ -n "$TRANSCRIPT_FILE" && -f "$TRANSCRIPT_FILE" ]]; then
  LAST_ASSISTANT=$(grep '"type":"assistant"' "$TRANSCRIPT_FILE" \
    | tail -1 \
    | jq -r '.message.content | if type == "string" then . elif type == "array" then (map(select(.type == "text") | .text // "") | join(" ")) else "" end' \
    2>/dev/null | head -c 500 || echo "")
fi

if [[ -f "$STATE_FILE" ]]; then
  # Existing session — update task only when we have a non-empty prompt
  if [[ -n "$USER_PROMPT" && "$USER_PROMPT" != "null" ]]; then
    EXISTING_TASK=$(jq -r '.task // ""' "$STATE_FILE")

    if [[ -n "$EXISTING_TASK" && "$EXISTING_TASK" != "$USER_PROMPT" ]]; then
      # Merge existing task and new prompt into one sentence via claude --print
      CLAUDE_BIN=$(PATH="$HOME/.local/bin:$PATH" command -v claude 2>/dev/null || echo "")
      MERGED=""

      if [[ -n "$CLAUDE_BIN" ]]; then
        MERGE_PROMPT="Combine the following into a single concise task statement. Output only the merged task — no explanation, no preamble, no quotes.
Existing task: ${EXISTING_TASK}
New input: ${USER_PROMPT}"

        # Include last assistant response as context for more accurate merging
        if [[ -n "$LAST_ASSISTANT" ]]; then
          MERGE_PROMPT="${MERGE_PROMPT}
Last assistant response (for context): ${LAST_ASSISTANT}"
        fi

        MERGED=$(echo "$MERGE_PROMPT" | \
          VETTED_MERGE_SESSION=1 "$CLAUDE_BIN" \
            --print \
            --model haiku \
            --no-session-persistence \
            2>/dev/null | head -5 | tr '\n' ' ' | sed 's/[[:space:]]*$//' || echo "")
      fi

      # Fallback if merge failed or claude not found
      if [[ -z "$MERGED" ]]; then
        MERGED="${EXISTING_TASK} — updated: ${USER_PROMPT}"
      fi
    else
      MERGED="$USER_PROMPT"
    fi

    TEMP="${STATE_FILE}.tmp.$$"
    jq \
      --arg task "$MERGED" \
      --arg ts "$NOW" \
      '.task = $task | .updated_at = $ts' \
      "$STATE_FILE" > "$TEMP" && mv "$TEMP" "$STATE_FILE"
  fi
else
  # First prompt — only create state file when we have a non-empty task.
  # If all fallbacks failed (prompt unavailable), skip to avoid empty-task stubs.
  if [[ -n "$USER_PROMPT" && "$USER_PROMPT" != "null" ]]; then
    jq -n \
      --arg session "$SESSION_ID" \
      --arg task "$USER_PROMPT" \
      --arg ts "$NOW" \
      '{
        session_id: $session,
        task: $task,
        created_at: $ts,
        updated_at: $ts
      }' > "$STATE_FILE"
  fi
fi

# Inject task clarity instructions into Claude's context
jq -n '{
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": "Before starting, evaluate whether this task has clear enough completion criteria — can you define a concrete delivery checklist? If the request is vague, lacks explicit success criteria, or has key ambiguities that affect implementation, you MUST call the AskUserQuestion tool to resolve them before doing any work. Do not proceed without clarification when the task is unclear. If the task is clear, define your done checklist and start working immediately — no \"I will...\" preamble. Regardless, the final deliverable must be finished and working, not a draft. If something fails or looks wrong, fix it before reporting back — do not hand problems back to the user. Once done and verified, append <verified>Fully Vetted.</verified> at the end of your response (only output this when you have genuinely verified the work — do not lie to exit)."
  }
}'

exit 0
