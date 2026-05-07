#!/bin/bash
#
# lib/loop.sh — Phase 1 of the Stop hook: Superpower Loop iteration.
#
# Sourced by hooks/stop-hook.sh. Exposes:
#   loop_phase "<state_file>" "<transcript_path>"
#
# Behavior:
#   - If no active loop → return 0 (fall through to Phase 2 / vet)
#   - If loop state is corrupted / max iterations / no transcript → clear loop
#     fields on state file, return 0 (fall through)
#   - If loop is active and completion promise detected → clear loop fields.
#       - Workflow skills (brainstorming|writing-plans|executing-plans|retrospective)
#         skip vet and the function calls `exit 0`.
#       - Other skills return 0 (fall through to vet).
#   - If loop is active and promise NOT detected → emit block JSON and `exit 0`
#     to continue the loop.
#
# Requires lib/utils.sh to already be sourced by the caller.

# Clear all loop-related fields on the state file in one atomic update.
# Used by every "abort the loop but stay in session" path.
_loop_clear_state() {
  local state_file="$1"
  local now
  now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  state_update "$state_file" --arg ts "$now" \
    'del(.active, .iteration, .max_iterations, .completion_promise, .prompt, .started_at) | .updated_at = $ts' \
    || { echo "Warning: state_update failed mid-loop, falling through" >&2; return 0; }
}

# Emit block JSON to continue the loop with the next iteration prompt.
# Exits with status 0 after emission.
_loop_emit_block() {
  local state_file="$1"
  local iteration="$2"
  local max_iterations="$3"
  local completion_promise="$4"
  local base_prompt="$5"

  local next_iteration=$((iteration + 1))
  local now
  now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  state_update "$state_file" \
    --argjson iter "$next_iteration" \
    --arg ts "$now" \
    '.iteration = $iter | .updated_at = $ts' \
    || { echo "Warning: state_update failed mid-loop-emit, falling through" >&2; return 0; }

  # System message
  local system_msg
  if [[ -n "$completion_promise" ]] && [[ "$completion_promise" != "null" ]]; then
    system_msg="Superpower loop iteration $next_iteration | To stop: output <promise>$completion_promise</promise> as the final standalone line (ONLY when statement is TRUE - do not lie to exit!)"
  else
    system_msg="Superpower loop iteration $next_iteration | No completion promise set - loop runs infinitely"
  fi

  # Prefer concise skill reference when skill_name is known
  local skill_name injected
  skill_name=$(state_read "$state_file" '.skill_name // ""')
  if [[ -n "$skill_name" ]]; then
    injected="Use superpowers:${skill_name} skill."
  else
    injected="$base_prompt"
  fi

  # Re-inject the smallest fragment Claude needs every iteration: the
  # SKILL.md "completion criteria" excerpt framed by LOOP_REINJECT markers.
  # This is a protocol-level extraction (HTML-comment delimiters), not a
  # business-aware read — the hook does not interpret skill content, it
  # only forwards what the skill author tagged for re-injection. Without
  # this, long loops drift away from the terminate conditions because the
  # SKILL.md gets pushed out of context after a handful of iterations.
  if [[ -n "$skill_name" ]]; then
    local lib_dir skill_md_path reinject
    lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
    skill_md_path="${lib_dir}/../skills/${skill_name}/SKILL.md"
    if [[ -f "$skill_md_path" ]]; then
      reinject=$(awk '
        /<!-- LOOP_REINJECT_BEGIN -->/ { in_block=1; next }
        /<!-- LOOP_REINJECT_END -->/   { in_block=0; next }
        in_block { print }
      ' "$skill_md_path")
      if [[ -n "$reinject" ]]; then
        injected="${injected}

---
${reinject}"
      fi
    fi
  fi

  # Cumulative artifact snapshot from track-changes.sh — surfaces what the
  # session has already produced so iteration N+1 picks up where N left off
  # instead of recreating files. Hook is read-only here; track-changes.sh
  # owns writes to .modified_files. Mirrors vet.sh's pattern verbatim.
  local files_lines files_md
  files_lines=$(jq -r '.modified_files // [] | .[]' "$state_file" 2>/dev/null | sort -u)
  files_md=""
  if [[ -n "$files_lines" ]]; then
    while IFS= read -r f; do
      [[ -n "$f" ]] && files_md="${files_md}- ${f}"$'\n'
    done <<< "$files_lines"
  fi
  if [[ -n "$files_md" ]]; then
    injected="${injected}

---
Already produced this session (Read or Edit existing files — do NOT recreate from scratch):
${files_md%$'\n'}"
  fi

  if [[ -n "$completion_promise" ]] && [[ "$completion_promise" != "null" ]]; then
    injected="${injected}

---
LOOP COMPLETION REQUIRED: When the above task is genuinely complete, output the following tag as the very last line of your response — nothing after it:
<promise>${completion_promise}</promise>"
  fi

  jq -n \
    --arg prompt "$injected" \
    --arg msg "$system_msg" \
    '{
      "decision": "block",
      "reason": $prompt,
      "systemMessage": $msg
    }'
  exit 0
}

# Main entry point for Phase 1.
# Returns 0 (fall through to vet) or exits 0 (loop handled).
loop_phase() {
  local state_file="$1"
  local transcript_path="$2"

  local is_loop_active
  is_loop_active=$(state_read "$state_file" '.active // false')
  [[ "$is_loop_active" != "true" ]] && return 0

  local iteration max_iterations completion_promise prompt
  iteration=$(state_read "$state_file" '.iteration // 0')
  max_iterations=$(state_read "$state_file" '.max_iterations // 0')
  completion_promise=$(state_read "$state_file" '.completion_promise // ""')
  prompt=$(state_read "$state_file" '.prompt // ""')

  # Numeric-field validation — clear loop state on corruption, fall through to vet.
  if [[ ! "$iteration" =~ ^[0-9]+$ ]]; then
    echo "Warning: Superpower loop: 'iteration' is not numeric (got: '$iteration')" >&2
    echo "   Loop stopping. Run /superpower-loop again to start fresh." >&2
    _loop_clear_state "$state_file"
    return 0
  fi

  if [[ ! "$max_iterations" =~ ^[0-9]+$ ]]; then
    echo "Warning: Superpower loop: 'max_iterations' is not numeric (got: '$max_iterations')" >&2
    echo "   Loop stopping. Run /superpower-loop again to start fresh." >&2
    _loop_clear_state "$state_file"
    return 0
  fi

  # Max iterations reached — stop loop.
  if [[ $max_iterations -gt 0 ]] && [[ $iteration -ge $max_iterations ]]; then
    echo "Superpower loop: Max iterations ($max_iterations) reached."
    _loop_clear_state "$state_file"
    return 0
  fi

  # Transcript must exist and contain assistant messages.
  if [[ ! -f "$transcript_path" ]]; then
    _loop_clear_state "$state_file"
    return 0
  fi

  if ! grep -q '"role":"assistant"' "$transcript_path"; then
    echo "Warning: Superpower loop: No assistant messages found in transcript" >&2
    echo "   Superpower loop is stopping." >&2
    _loop_clear_state "$state_file"
    return 0
  fi

  local last_output
  last_output=$(extract_last_assistant_text "$transcript_path" 100)
  if [[ -z "$last_output" ]]; then
    echo "Warning: Superpower loop: Failed to extract assistant message" >&2
    echo "   Superpower loop is stopping." >&2
    _loop_clear_state "$state_file"
    return 0
  fi

  # Check for completion promise.
  local loop_complete=false
  if [[ -n "$completion_promise" ]] && [[ "$completion_promise" != "null" ]]; then
    local promise_text
    promise_text=$(extract_promise_text "$last_output")
    if [[ -n "$promise_text" ]] && [[ "$promise_text" = "$completion_promise" ]]; then
      echo "Superpower loop: Detected <promise>$completion_promise</promise>"
      loop_complete=true
    fi
  fi

  if [[ "$loop_complete" == "true" ]]; then
    _loop_clear_state "$state_file"
    # Workflow skills exit 0 from inside the helper; non-workflow skills
    # return 1, which `|| true` swallows so we fall through to vet_phase
    # in stop-hook.sh. Both branches eventually return 0 from loop_phase.
    bypass_vet_for_workflow_skill "$state_file" || true
    return 0
  fi

  # Not complete — continue loop.
  if [[ -z "$prompt" ]]; then
    echo "Warning: Superpower loop: State file has no prompt" >&2
    echo "   Superpower loop is stopping." >&2
    _loop_clear_state "$state_file"
    return 0
  fi

  _loop_emit_block "$state_file" "$iteration" "$max_iterations" "$completion_promise" "$prompt"
}
