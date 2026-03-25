#!/bin/bash
#
# task-start.sh — UserPromptSubmit hook: enforce task clarity before execution
#
# Fires when the user submits a prompt. Does two things:
#   1. Persists the user's prompt to a session-scoped state file.
#      - First prompt: task = user_prompt (verbatim).
#      - Subsequent prompts: saved as pending_prompt; stop-hook.sh
#        merges it with the assistant's response into one coherent task.
#   2. Instructs Claude to evaluate completion criteria and ask the user via
#      AskUserQuestion if the task is too vague to deliver.
#
# State file: ~/.claude/projects/<project-key>/<session_id>.superpowers.json
#   project-key = $PWD with '/' replaced by '-'
# State file persists across turns — stop-hook.sh evolves the task on each exit.

set -euo pipefail

# Guard: running inside the merge sub-session — skip everything
[[ "${SUPERPOWERS_MERGE_SESSION:-}" == "1" ]] && exit 0

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

# Detect slash commands — persist state but skip system message injection
#
# Three-tier detection (hook fires before Claude Code injects <command-name>):
#   1. <command-name> tag in .prompt — present when .prompt contains expanded content
#   2. Raw slash command pattern — present when .prompt = "/init" or "/plugin:skill args"
#   3. Transcript fallback — last resort if .prompt is empty
#
# Each tier sets COMMAND_NAME (and RAW_ARGS for tier 2).
# Normalization runs once after: strip leading slash + plugin prefix → SKILL_SHORT,
# then format USER_PROMPT as "Use <skill> skill. [args]".
IS_SLASH_COMMAND=false
COMMAND_NAME=""
RAW_ARGS=""

if echo "$USER_PROMPT" | grep -q '<command-name>'; then
  COMMAND_NAME=$(echo "$USER_PROMPT" | sed -n 's/.*<command-name>\([^<]*\)<\/command-name>.*/\1/p')
elif echo "$USER_PROMPT" | grep -qE '^/[a-zA-Z][a-zA-Z0-9:_-]*( |$)'; then
  COMMAND_NAME=$(echo "$USER_PROMPT" | grep -oE '^/[a-zA-Z][a-zA-Z0-9:_-]*')
  RAW_ARGS=$(echo "$USER_PROMPT" | sed 's|^[^ ]* *||')
elif [[ -n "$TRANSCRIPT_FILE" && -f "$TRANSCRIPT_FILE" ]]; then
  LAST_USER_CONTENT=$(grep '"type":"user"' "$TRANSCRIPT_FILE" \
    | grep -v '"isMeta":true' \
    | tail -1 \
    | jq -r '.message.content | if type == "string" then . elif type == "array" then (map(select(.type == "text") | .text // "") | join(" ")) else "" end' \
    2>/dev/null || echo "")
  if echo "$LAST_USER_CONTENT" | grep -q '<command-name>'; then
    COMMAND_NAME=$(echo "$LAST_USER_CONTENT" | sed -n 's/.*<command-name>\([^<]*\)<\/command-name>.*/\1/p')
  fi
fi

# Normalize once: "/superpowers:brainstorming" → "brainstorming", "/init" → "init"
if [[ -n "$COMMAND_NAME" ]]; then
  IS_SLASH_COMMAND=true
  SKILL_SHORT=$(echo "$COMMAND_NAME" | sed 's|^/||; s|^[^:]*:||')
  if [[ -n "$RAW_ARGS" ]]; then
    USER_PROMPT="Use ${SKILL_SHORT} skill. ${RAW_ARGS}"
  else
    USER_PROMPT="Use ${SKILL_SHORT} skill."
  fi
fi

STATE_DIR="$(state_dir)"
mkdir -p "$STATE_DIR"
STATE_FILE="${STATE_DIR}/${SESSION_ID}.superpowers.json"
NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Guard: if existing state file has corrupted JSON, remove and recreate
if [[ -f "$STATE_FILE" ]] && ! jq empty "$STATE_FILE" 2>/dev/null; then
  rm -f "$STATE_FILE"
fi

# Bypass: novet in prompt skips verification for this turn only
# Match as whole word to avoid false positives (e.g., "innovet" won't match)
# Skip for slash commands — novet in arguments is not a bypass intent
# Skip when superpower loop is active — during a loop, novet is ignored
if [[ "$IS_SLASH_COMMAND" == "false" ]] && echo "$USER_PROMPT" | grep -qwF 'novet'; then
  LOOP_ACTIVE=false
  if [[ -f "$STATE_FILE" ]] && jq -e '.active == true' "$STATE_FILE" >/dev/null 2>&1; then
    LOOP_ACTIVE=true
  fi

  if [[ "$LOOP_ACTIVE" == "false" ]]; then
    if [[ -f "$STATE_FILE" ]]; then
      TEMP="${STATE_FILE}.tmp.$$"
      jq --arg ts "$NOW" '.skip_turn = true | .updated_at = $ts' "$STATE_FILE" > "$TEMP" && mv "$TEMP" "$STATE_FILE"
    else
      jq -n --arg session "$SESSION_ID" --arg ts "$NOW" \
        '{session_id: $session, skip_turn: true, created_at: $ts, updated_at: $ts}' > "$STATE_FILE"
    fi
    exit 0
  fi
  # Loop is active — fall through, novet ignored
fi

if [[ -f "$STATE_FILE" ]]; then
  # Existing session — queue prompt for merge at Stop time
  if [[ -n "$USER_PROMPT" && "$USER_PROMPT" != "null" ]]; then
    TEMP="${STATE_FILE}.tmp.$$"
    if [[ "$IS_SLASH_COMMAND" == "true" && -n "$SKILL_SHORT" ]]; then
      jq \
        --arg prompt "$USER_PROMPT" \
        --arg skill "$SKILL_SHORT" \
        --arg ts "$NOW" \
        '.pending_prompt = $prompt | .skill_name = $skill | .updated_at = $ts' \
        "$STATE_FILE" > "$TEMP" && mv "$TEMP" "$STATE_FILE"
    else
      jq \
        --arg prompt "$USER_PROMPT" \
        --arg ts "$NOW" \
        'del(.skill_name) | .pending_prompt = $prompt | .updated_at = $ts' \
        "$STATE_FILE" > "$TEMP" && mv "$TEMP" "$STATE_FILE"
    fi
  fi
else
  # First prompt — only create state file when we have a non-empty task.
  if [[ -n "$USER_PROMPT" && "$USER_PROMPT" != "null" ]]; then
    if [[ "$IS_SLASH_COMMAND" == "true" && -n "$SKILL_SHORT" ]]; then
      jq -n \
        --arg session "$SESSION_ID" \
        --arg task "$USER_PROMPT" \
        --arg skill "$SKILL_SHORT" \
        --arg ts "$NOW" \
        '{
          session_id: $session,
          task: $task,
          skill_name: $skill,
          created_at: $ts,
          updated_at: $ts
        }' > "$STATE_FILE"
    else
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
fi

# Inject task clarity instructions into Claude's context
# Skip for slash commands — they have their own instructions
if [[ "$IS_SLASH_COMMAND" == "false" ]]; then
  jq -n '{
    "systemMessage": "Before starting, classify this prompt:\n\n1. **Discussion/Question** — the user is asking why something happens, reporting a problem, seeking analysis, or exploring options. For these: analyze the problem, present your findings, and let the user decide next steps. Do NOT offer to implement a fix or ask \"shall I implement this?\" — that skips the user'\''s decision. Wait for an explicit implementation request.\n\n2. **Implementation request** — the user explicitly asks you to build, fix, change, or create something. For these: evaluate whether the task has clear enough completion criteria. If the request is vague, lacks explicit success criteria, or has key ambiguities, you MUST use the AskUserQuestion tool to resolve them before doing any work. If clear, define your done checklist and start working immediately — no \"I will...\" preamble.\n\nRegardless of type, the final deliverable must be finished and working, not a draft. If something fails or looks wrong, fix it before reporting back — do not hand problems back to the user. Once done and verified, append <verified>Fully Vetted.</verified> at the end of your response (only output this when you have genuinely verified the work — do not lie to exit)."
  }'
fi

exit 0
