#!/bin/bash
#
# stop-hook.sh — Unified Stop hook: Superpower Loop + Work Verification
#
# Phase 1 (Loop): If a superpower loop is active, check for completion promise.
#   - Promise NOT found → continue loop iteration (block with prompt)
#   - Promise found OR max_iterations → clear loop fields, fall through to Phase 2
#
# Phase 2 (Vet): Require work verification before exit.
#   - <verified>Fully Vetted.</verified> found → synthesize summary, allow exit
#   - Not found → block exit with verification prompt
#
# State file: ~/.claude/projects/<project-key>/<session_id>.superpowers.json

set -euo pipefail

# Guard: running inside the merge sub-session — exit immediately
[[ "${SUPERPOWERS_MERGE_SESSION:-}" == "1" ]] && exit 0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
# shellcheck source=../lib/utils.sh
source "${SCRIPT_DIR}/../lib/utils.sh"

# Read hook input from stdin
HOOK_INPUT=$(cat)

# Extract structured fields
HOOK_SESSION=$(echo "$HOOK_INPUT" | jq -r '.session_id // ""')
TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | jq -r '.transcript_path // ""')
LAST_MSG=$(echo "$HOOK_INPUT" | jq -r '.last_assistant_message // ""')

# Find the state file owned by this session
SUPERPOWER_STATE_FILE=$(find_state_file "$HOOK_SESSION")

if [[ -z "$SUPERPOWER_STATE_FILE" ]]; then
  # No state file for this session — allow exit
  exit 0
fi

# Guard: corrupted JSON — remove and allow exit
if ! jq empty "$SUPERPOWER_STATE_FILE" 2>/dev/null; then
  echo "Warning: State file corrupted, removing: $SUPERPOWER_STATE_FILE" >&2
  rm -f "$SUPERPOWER_STATE_FILE"
  exit 0
fi

# ============================================================================
# PHASE 1: LOOP CHECK
# ============================================================================

IS_LOOP_ACTIVE=$(state_read "$SUPERPOWER_STATE_FILE" '.active // false')

if [[ "$IS_LOOP_ACTIVE" == "true" ]]; then
  # Read loop fields
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
    # Clear loop fields but preserve vet state
    NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    state_update "$SUPERPOWER_STATE_FILE" --arg ts "$NOW" \
      'del(.active, .iteration, .max_iterations, .completion_promise, .prompt, .started_at) | .updated_at = $ts'
    # Fall through to verification
  elif [[ ! "$MAX_ITERATIONS" =~ ^[0-9]+$ ]]; then
    echo "Warning: Superpower loop: State file corrupted" >&2
    echo "   File: $SUPERPOWER_STATE_FILE" >&2
    echo "   Problem: 'max_iterations' is not a valid number (got: '$MAX_ITERATIONS')" >&2
    echo "   Superpower loop is stopping. Run /superpower-loop again to start fresh." >&2
    NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    state_update "$SUPERPOWER_STATE_FILE" --arg ts "$NOW" \
      'del(.active, .iteration, .max_iterations, .completion_promise, .prompt, .started_at) | .updated_at = $ts'
    # Fall through to verification
  elif [[ $MAX_ITERATIONS -gt 0 ]] && [[ $ITERATION -ge $MAX_ITERATIONS ]]; then
    # Max iterations reached — clear loop fields, fall through to verification
    echo "Superpower loop: Max iterations ($MAX_ITERATIONS) reached."
    NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    state_update "$SUPERPOWER_STATE_FILE" --arg ts "$NOW" \
      'del(.active, .iteration, .max_iterations, .completion_promise, .prompt, .started_at) | .updated_at = $ts'
    # Fall through to verification
  else
    # Loop is active and within limits — check for completion

    if [[ ! -f "$TRANSCRIPT_PATH" ]]; then
      NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
      state_update "$SUPERPOWER_STATE_FILE" --arg ts "$NOW" \
        'del(.active, .iteration, .max_iterations, .completion_promise, .prompt, .started_at) | .updated_at = $ts'
      # Fall through to verification
    elif ! grep -q '"role":"assistant"' "$TRANSCRIPT_PATH"; then
      echo "Warning: Superpower loop: No assistant messages found in transcript" >&2
      echo "   Superpower loop is stopping." >&2
      NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
      state_update "$SUPERPOWER_STATE_FILE" --arg ts "$NOW" \
        'del(.active, .iteration, .max_iterations, .completion_promise, .prompt, .started_at) | .updated_at = $ts'
      # Fall through to verification
    else
      LAST_OUTPUT=$(extract_last_assistant_text "$TRANSCRIPT_PATH" 100)

      if [[ -z "$LAST_OUTPUT" ]]; then
        echo "Warning: Superpower loop: Failed to extract assistant message" >&2
        echo "   Superpower loop is stopping." >&2
        NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        state_update "$SUPERPOWER_STATE_FILE" --arg ts "$NOW" \
          'del(.active, .iteration, .max_iterations, .completion_promise, .prompt, .started_at) | .updated_at = $ts'
        # Fall through to verification
      else
        # Check for completion promise
        LOOP_COMPLETE=false
        if [[ -n "$COMPLETION_PROMISE" ]] && [[ "$COMPLETION_PROMISE" != "null" ]]; then
          PROMISE_TEXT=$(extract_promise_text "$LAST_OUTPUT")
          if [[ -n "$PROMISE_TEXT" ]] && [[ "$PROMISE_TEXT" = "$COMPLETION_PROMISE" ]]; then
            echo "Superpower loop: Detected <promise>$COMPLETION_PROMISE</promise>"
            LOOP_COMPLETE=true
          fi
        fi

        if [[ "$LOOP_COMPLETE" == "true" ]]; then
          # Loop complete — clear loop fields
          NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
          state_update "$SUPERPOWER_STATE_FILE" --arg ts "$NOW" \
            'del(.active, .iteration, .max_iterations, .completion_promise, .prompt, .started_at) | .updated_at = $ts'

          # Skills with built-in phase verification skip vet
          SKILL_NAME=$(state_read "$SUPERPOWER_STATE_FILE" '.skill_name // ""')
          case "$SKILL_NAME" in
            brainstorming|writing-plans|executing-plans)
              state_update "$SUPERPOWER_STATE_FILE" 'del(.need_vet)'
              exit 0
              ;;
          esac
          # Other skills fall through to verification
        else
          # Not complete — continue loop iteration
          NEXT_ITERATION=$((ITERATION + 1))

          if [[ -z "$PROMPT" ]]; then
            echo "Warning: Superpower loop: State file has no prompt" >&2
            echo "   Superpower loop is stopping." >&2
            NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
            state_update "$SUPERPOWER_STATE_FILE" --arg ts "$NOW" \
              'del(.active, .iteration, .max_iterations, .completion_promise, .prompt, .started_at) | .updated_at = $ts'
            # Fall through to verification
          else
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

            # Build continuation prompt
            # If skill_name is available, use concise skill reference instead of full prompt
            SKILL_NAME=$(state_read "$SUPERPOWER_STATE_FILE" '.skill_name // ""')
            if [[ -n "$SKILL_NAME" ]]; then
              INJECTED_PROMPT="Use superpowers:${SKILL_NAME} skill."
            else
              INJECTED_PROMPT="$PROMPT"
            fi

            # Append completion instruction
            if [[ -n "$COMPLETION_PROMISE" ]] && [[ "$COMPLETION_PROMISE" != "null" ]]; then
              INJECTED_PROMPT="${INJECTED_PROMPT}

---
LOOP COMPLETION REQUIRED: When the above task is genuinely complete, output the following tag as the very last line of your response — nothing after it:
<promise>${COMPLETION_PROMISE}</promise>"
            fi

            # Block exit and feed prompt back
            jq -n \
              --arg prompt "$INJECTED_PROMPT" \
              --arg msg "$SYSTEM_MSG" \
              '{
                "decision": "block",
                "reason": $prompt,
                "systemMessage": $msg
              }'
            exit 0
          fi
        fi
      fi
    fi
  fi
fi

# ============================================================================
# PHASE 2: VERIFICATION CHECK
# Reached when: no loop was active, OR loop just completed/errored
# ============================================================================

# Default: skip verification. Only run when need_vet is explicitly set.
# need_vet is cleared only on verified-tag match or skill bypass — persistent enforcement.
if ! jq -e '.need_vet == true' "$SUPERPOWER_STATE_FILE" >/dev/null 2>&1; then
  exit 0
fi

# Skill bypass: workflow skills with built-in phase verification skip vet.
# This covers direct slash command invocations (no loop).
# Loop-completed invocations are already handled by Phase 1 (lines 131-136).
PHASE2_SKILL=$(state_read "$SUPERPOWER_STATE_FILE" '.skill_name // ""')
case "$PHASE2_SKILL" in
  brainstorming|writing-plans|executing-plans)
    state_update "$SUPERPOWER_STATE_FILE" 'del(.need_vet)'
    exit 0
    ;;
esac

# Check for verified tag in last assistant message
VERIFIED_TEXT=$(extract_verified_text "$LAST_MSG")
if [[ -n "$VERIFIED_TEXT" ]] && [[ "$VERIFIED_TEXT" = "$STOP_CHAR" ]]; then
  # Verified — clear need_vet and synthesize final task summary
  state_update "$SUPERPOWER_STATE_FILE" 'del(.need_vet)'
  if [[ -f "$SUPERPOWER_STATE_FILE" ]]; then
    CURRENT_TASK=$(jq -r '.task // ""' "$SUPERPOWER_STATE_FILE")
    TURN_OUTPUT="${LAST_MSG:0:500}"

    if [[ -n "$CURRENT_TASK" && -n "$TURN_OUTPUT" ]]; then
      MERGED=$(run_haiku_merge "Synthesize a one-sentence task summary from the inputs below. Extract the core intent and outcome — discard noise, hooks output, and duplicated context. Plain text only, no quotes.
Task: ${CURRENT_TASK}
Outcome: ${TURN_OUTPUT}")

      if [[ -n "$MERGED" ]]; then
        NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        state_update "$SUPERPOWER_STATE_FILE" \
          --arg task "$MERGED" \
          --arg ts "$NOW" \
          '.task = $task | .updated_at = $ts'
      fi
    fi
  fi
  exit 0
fi

# --- Merge pending prompt (pending_prompt + last_assistant_message) ---

CURRENT_PROMPT=""
SYNTHESIZED=""

if [[ -f "$SUPERPOWER_STATE_FILE" ]]; then
  PENDING_PROMPT=$(jq -r '.pending_prompt // ""' "$SUPERPOWER_STATE_FILE")
  EXISTING_TASK=$(jq -r '.task // ""' "$SUPERPOWER_STATE_FILE")

  if [[ -n "$PENDING_PROMPT" && "$PENDING_PROMPT" != "null" ]]; then
    CURRENT_PROMPT="$EXISTING_TASK"
    [[ -z "$CURRENT_PROMPT" ]] && CURRENT_PROMPT="$PENDING_PROMPT"
    NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    LAST_ASSISTANT="${LAST_MSG:0:500}"

    MERGE_INPUT="Distill these inputs into one concise context sentence. Keep only the core intent and outcome. Plain text only, no quotes.
Prompt: ${PENDING_PROMPT}"
    [[ -n "$LAST_ASSISTANT" ]] && MERGE_INPUT="${MERGE_INPUT}
Output: ${LAST_ASSISTANT}"

    MERGED=$(run_haiku_merge "$MERGE_INPUT")
    # Fallback: combine existing task + pending prompt (preserve both)
    if [[ -z "$MERGED" ]]; then
      if [[ -n "$EXISTING_TASK" && "$EXISTING_TASK" != "$PENDING_PROMPT" ]]; then
        MERGED="${EXISTING_TASK} — ${PENDING_PROMPT}"
      else
        MERGED="$PENDING_PROMPT"
      fi
    fi
    # Only show Historical Context if it differs from Current Task
    if [[ "$MERGED" != "$CURRENT_PROMPT" ]]; then
      SYNTHESIZED="$MERGED"
    fi

    state_update "$SUPERPOWER_STATE_FILE" \
      --arg task "$MERGED" \
      --arg ts "$NOW" \
      '.task = $task | .updated_at = $ts | del(.pending_prompt)'
  else
    CURRENT_PROMPT="$EXISTING_TASK"
  fi
fi

# Fallback: transcript's last-prompt entry
if [[ -z "$CURRENT_PROMPT" ]]; then
  if [[ -n "$TRANSCRIPT_PATH" ]] && [[ -f "$TRANSCRIPT_PATH" ]]; then
    set +e
    CURRENT_PROMPT=$(grep '"type":"last-prompt"' "$TRANSCRIPT_PATH" \
      | tail -1 \
      | jq -r '.lastPrompt // ""' \
      2>/dev/null || echo "")
    set -e
  fi
fi

# --- Read modified files from state ---

MODIFIED_FILES=""
if [[ -f "$SUPERPOWER_STATE_FILE" ]]; then
  MODIFIED_FILES=$(jq -r '.modified_files // [] | .[]' "$SUPERPOWER_STATE_FILE" 2>/dev/null | sort -u)
fi

# --- Build verification message ---

STOP_TAG="<verified>${STOP_CHAR}</verified>"

build_system_message() {
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
  msg="${msg}${NL}${NL}Once verified, append \`${STOP_TAG}\` at the end of your response, then report back."
  msg="${msg}${NL}${NL}**Only output the verified tag when you have genuinely verified the work — do not lie to exit.**"

  echo "$msg"
}

if [[ -n "$CURRENT_PROMPT" ]]; then
  MSG=$(build_system_message "$CURRENT_PROMPT" "$SYNTHESIZED" "$MODIFIED_FILES")
else
  MSG=$(build_system_message "(no task context available)" "" "$MODIFIED_FILES")
fi

jq -n --arg msg "$MSG" '{"decision": "block", "reason": $msg}'
exit 0
