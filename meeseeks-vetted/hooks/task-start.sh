#!/bin/bash
#
# task-start.sh — UserPromptSubmit hook: enforce task clarity before execution
#
# Fires when the user submits a prompt. Does two things:
#   1. Persists the user's prompt to a session-scoped state file.
#      - First prompt: task = user_prompt (verbatim).
#      - Subsequent prompts: saved as pending_prompt; verify-work.sh (Stop hook)
#        merges it with the assistant's response into one coherent task.
#   2. Instructs Claude to evaluate completion criteria and ask the user via
#      AskUserQuestion if the task is too vague to deliver.
#
# State file: ~/.claude/projects/<project-key>/<session_id>.vetted.json
#   project-key = $PWD with '/' replaced by '-'
# State file persists across turns — verify-work.sh evolves the task on each exit.

set -euo pipefail

# Guard: running inside the merge sub-session — skip everything
[[ "${VETTED_MERGE_SESSION:-}" == "1" ]] && exit 0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
# shellcheck source=../lib/utils.sh
source "${SCRIPT_DIR}/../lib/utils.sh"

HOOK_INPUT=$(cat)

# Extract structured fields in one pass (safe for @tsv: IDs and paths only)
# User prompt extracted separately because it may contain tabs/newlines
read -r SESSION_ID TRANSCRIPT_FILE < <(
  echo "$HOOK_INPUT" | jq -r '[.session_id // "default", .transcript_path // ""] | @tsv'
)
USER_PROMPT=$(echo "$HOOK_INPUT" | jq -r '.prompt // ""')

# Fallback: parse transcript for the user's last message
if [[ -z "$USER_PROMPT" || "$USER_PROMPT" == "null" ]]; then
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

if [[ -f "$STATE_FILE" ]]; then
  # Existing session — queue prompt for merge at Stop time
  # (verify-work.sh will combine it with the assistant's response)
  if [[ -n "$USER_PROMPT" && "$USER_PROMPT" != "null" ]]; then
    TEMP="${STATE_FILE}.tmp.$$"
    jq \
      --arg prompt "$USER_PROMPT" \
      --arg ts "$NOW" \
      '.pending_prompt = $prompt | .updated_at = $ts' \
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
  "systemMessage": "Before starting, classify this prompt:\n\n1. **Discussion/Question** — the user is asking why something happens, reporting a problem, seeking analysis, or exploring options. For these: analyze the problem, present your findings, and let the user decide next steps. Do NOT offer to implement a fix or ask \"shall I implement this?\" — that skips the user'\''s decision. Wait for an explicit implementation request.\n\n2. **Implementation request** — the user explicitly asks you to build, fix, change, or create something. For these: evaluate whether the task has clear enough completion criteria. If the request is vague, lacks explicit success criteria, or has key ambiguities, you MUST use the AskUserQuestion tool to resolve them before doing any work. If clear, define your done checklist and start working immediately — no \"I will...\" preamble.\n\nRegardless of type, the final deliverable must be finished and working, not a draft. If something fails or looks wrong, fix it before reporting back — do not hand problems back to the user. Once done and verified, append <verified>Fully Vetted.</verified> at the end of your response (only output this when you have genuinely verified the work — do not lie to exit)."
}'

exit 0
