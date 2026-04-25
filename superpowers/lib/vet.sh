#!/bin/bash
#
# lib/vet.sh — Phase 2 of the Stop hook: Work verification (need-vet).
#
# Sourced by hooks/stop-hook.sh. Exposes:
#   vet_phase "<state_file>" "<last_message>" "<transcript_path>"
#
# Behavior:
#   - If need_vet is not set → exit 0 (skip verification entirely)
#   - If skill_name is a workflow skill → clear need_vet, exit 0 (skill bypass)
#   - If <verified>Fully Vetted.</verified> is found in LAST_MSG → synthesize
#     one-sentence task summary via Haiku, clear need_vet, exit 0
#   - Otherwise → merge pending_prompt into task, emit block JSON with
#     verification checkpoint message, exit 0
#
# Requires lib/utils.sh to already be sourced by the caller.

# Build the verification-checkpoint system message shown to the user.
_vet_build_system_message() {
  local current="$1"
  local synthesized="${2:-}"
  local files="${3:-}"
  local NL=$'\n'

  local msg="# Verification Checkpoint"
  msg="${msg}${NL}${NL}## Current Task${NL}> ${current}"

  if [[ -n "$synthesized" ]]; then
    msg="${msg}${NL}${NL}## Historical Context${NL}> ${synthesized}"
  fi

  if [[ -n "$files" ]]; then
    msg="${msg}${NL}${NL}## Modified Files${NL}\`\`\`${NL}${files}${NL}\`\`\`"
  fi

  msg="${msg}${NL}${NL}## Verification Steps"
  msg="${msg}${NL}- Run any code or scripts and check the output"
  msg="${msg}${NL}- For web apps, open the page, click through flows, confirm rendering and interactions"
  msg="${msg}${NL}- Test with real or representative input and inspect results"
  msg="${msg}${NL}- Simulate edge cases if possible"
  msg="${msg}${NL}${NL}Once verified, append \`<verified>${STOP_CHAR}</verified>\` at the end of your response, then report back."
  msg="${msg}${NL}${NL}**Only output the verified tag when you have genuinely verified the work — do not lie to exit.**"

  echo "$msg"
}

# Consume pending_prompt and merge with last assistant message into a
# synthesized one-sentence task summary. Populates SYNTHESIZED and updates
# CURRENT_PROMPT by reference via printing the values on separate lines
# (caller captures them).
_vet_merge_pending_prompt() {
  local state_file="$1"
  local last_msg="$2"

  local current_prompt=""
  local synthesized=""

  if [[ ! -f "$state_file" ]]; then
    printf '%s\n%s\n' "$current_prompt" "$synthesized"
    return
  fi

  local pending_prompt existing_task
  pending_prompt=$(jq -r '.pending_prompt // ""' "$state_file")
  existing_task=$(jq -r '.task // ""' "$state_file")

  if [[ -z "$pending_prompt" || "$pending_prompt" == "null" ]]; then
    current_prompt="$existing_task"
    printf '%s\n%s\n' "$current_prompt" "$synthesized"
    return
  fi

  current_prompt="$existing_task"
  [[ -z "$current_prompt" ]] && current_prompt="$pending_prompt"
  local now
  now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  local last_assistant="${last_msg:0:500}"

  local merge_input="Distill these inputs into one concise context sentence. Keep only the core intent and outcome. Plain text only, no quotes.
Prompt: ${pending_prompt}"
  [[ -n "$last_assistant" ]] && merge_input="${merge_input}
Output: ${last_assistant}"

  local merged
  merged=$(run_haiku_merge "$merge_input")
  if [[ -z "$merged" ]]; then
    if [[ -n "$existing_task" && "$existing_task" != "$pending_prompt" ]]; then
      merged="${existing_task} — ${pending_prompt}"
    else
      merged="$pending_prompt"
    fi
  fi

  if [[ "$merged" != "$current_prompt" ]]; then
    synthesized="$merged"
  fi

  state_update "$state_file" \
    --arg task "$merged" \
    --arg ts "$now" \
    '.task = $task | .updated_at = $ts | del(.pending_prompt)'

  printf '%s\n%s\n' "$current_prompt" "$synthesized"
}

# Synthesize a final one-sentence task summary after verification succeeds.
_vet_synthesize_final_task() {
  local state_file="$1"
  local last_msg="$2"

  [[ -f "$state_file" ]] || return 0

  local current_task="" turn_output=""
  current_task=$(jq -r '.task // ""' "$state_file")
  turn_output="${last_msg:0:500}"

  [[ -z "$current_task" || -z "$turn_output" ]] && return 0

  local merged
  merged=$(run_haiku_merge "Synthesize a one-sentence task summary from the inputs below. Extract the core intent and outcome — discard noise, hooks output, and duplicated context. Plain text only, no quotes.
Task: ${current_task}
Outcome: ${turn_output}")

  [[ -z "$merged" ]] && return 0

  local now
  now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  state_update "$state_file" \
    --arg task "$merged" \
    --arg ts "$now" \
    '.task = $task | .updated_at = $ts'
}

# Main entry point for Phase 2. Always exits the script.
vet_phase() {
  local state_file="$1"
  local last_msg="$2"
  local transcript_path="$3"

  # Default: skip verification unless need_vet is explicitly set.
  if ! jq -e '.need_vet == true' "$state_file" >/dev/null 2>&1; then
    exit 0
  fi

  # Workflow skills have built-in phase verification — skip vet.
  # need-vet is intentionally excluded (its entire purpose is to enforce vet).
  local skill_name
  skill_name=$(state_read "$state_file" '.skill_name // ""')
  case "$skill_name" in
    brainstorming|writing-plans|executing-plans|retrospective)
      state_update "$state_file" 'del(.need_vet)'
      exit 0
      ;;
  esac

  # Verified-tag match → synthesize summary and allow exit.
  local verified_text
  verified_text=$(extract_verified_text "$last_msg")
  if [[ -n "$verified_text" ]] && [[ "$verified_text" = "$STOP_CHAR" ]]; then
    state_update "$state_file" 'del(.need_vet)'
    _vet_synthesize_final_task "$state_file" "$last_msg"
    exit 0
  fi

  # Merge pending_prompt if present.
  local merge_output current_prompt synthesized
  merge_output=$(_vet_merge_pending_prompt "$state_file" "$last_msg")
  current_prompt=$(echo "$merge_output" | sed -n '1p')
  synthesized=$(echo "$merge_output" | sed -n '2p')

  # Transcript fallback for current prompt.
  if [[ -z "$current_prompt" ]]; then
    if [[ -n "$transcript_path" ]] && [[ -f "$transcript_path" ]]; then
      set +e
      current_prompt=$(grep '"type":"last-prompt"' "$transcript_path" \
        | tail -1 \
        | jq -r '.lastPrompt // ""' \
        2>/dev/null || echo "")
      set -e
    fi
  fi

  local modified_files=""
  if [[ -f "$state_file" ]]; then
    modified_files=$(jq -r '.modified_files // [] | .[]' "$state_file" 2>/dev/null | sort -u)
  fi

  local msg
  if [[ -n "$current_prompt" ]]; then
    msg=$(_vet_build_system_message "$current_prompt" "$synthesized" "$modified_files")
  else
    msg=$(_vet_build_system_message "(no task context available)" "" "$modified_files")
  fi

  jq -n --arg msg "$msg" '{"decision": "block", "reason": $msg}'
  exit 0
}
