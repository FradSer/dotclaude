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

# Append a `plan_completed` event to the project's plans-completed.jsonl
# when the loop completes for the executing-plans workflow skill. Empirical
# audit (agentbook real project, 2 completed plans) showed this file never
# existed despite the SKILL.md instructing Claude to write it in Phase 6
# step 2 — the manual instruction was being silently dropped, so the entire
# downstream feedback loop (retrospective `--across-all` auto-scope, the
# RETROSPECTIVE DUE reminder threshold, Phase 5c assumption tests) decayed
# to a no-op. This helper makes the write mechanical: hook-driven on
# promise detection, not Claude-instructed. Best-effort throughout — any
# step failing silently returns 0; promise completion must never be
# blocked by a missed log entry.
_loop_log_plan_completion_if_executing() {
  local state_file="$1"
  local skill_name prompt plan_path log_dir log_file now

  skill_name=$(state_read "$state_file" '.skill_name // ""')
  [[ "$skill_name" != "executing-plans" ]] && return 0

  # State.prompt carries the project-relative plan path embedded by
  # executing-plans first action. Pattern: `docs/plans/<topic>-plan` with
  # optional trailing slash. `|| true` swallows grep-no-match: under
  # `set -euo pipefail` an assignment whose command substitution returns
  # non-zero DOES propagate (despite folklore) — the regression test
  # `test_executing_plans_without_plan_path_in_prompt_skips_log` caught
  # exactly that.
  prompt=$(state_read "$state_file" '.prompt // ""')
  plan_path=$(printf '%s' "$prompt" | grep -oE 'docs/plans/[A-Za-z0-9_/.-]+-plan/?' | head -1) || true
  [[ -z "$plan_path" ]] && return 0
  plan_path="${plan_path%/}"

  log_dir="${PWD}/docs/retros"
  log_file="${log_dir}/plans-completed.jsonl"
  mkdir -p "$log_dir" 2>/dev/null || return 0

  now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  jq -nc \
    --arg plan "${PWD}/${plan_path}" \
    --arg ts "$now" \
    '{event: "plan_completed", plan: $plan, timestamp: $ts}' \
    >> "$log_file" 2>/dev/null || true
}

# Clear all loop-related fields on the state file in one atomic update.
# .edits_since_last_spawn survives — it's session-scoped (track-changes.sh /
# track-spawns.sh own it) so a follow-up loop inherits the right counter.
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
#
# Injection layout (all branches):
#   header (Continue / STUCK / base_prompt)
#   [modified-files snapshot — first re-injection only, next_iteration <= 2]
#   LOOP COMPLETION REQUIRED tail (carries the promise tag + last-line rule)
#
# The Continue header replaces the older "Use superpowers:X skill." which
# the harness treated as a slash-command-style re-entry signal — empirical
# audit showed Claude walking SKILL.md from the top each loop, wasting a
# turn per iteration. The footer's "as the very last line of your response —
# nothing after it" is the only completion criterion the loop's promise
# regex enforces, so we no longer extract a separate LOOP_REINJECT excerpt
# from SKILL.md (it was redundant with the footer).
_loop_emit_block() {
  local state_file="$1"
  local iteration="$2"
  local max_iterations="$3"
  local completion_promise="$4"
  local base_prompt="$5"
  local is_stuck_arg="${6:-0}"
  local edits_since_spawn="${7:-0}"

  local next_iteration=$((iteration + 1))
  local now
  now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  state_update "$state_file" \
    --argjson iter "$next_iteration" \
    --arg ts "$now" \
    '.iteration = $iter | .updated_at = $ts' \
    || { echo "Warning: state_update failed mid-loop-emit, falling through" >&2; return 0; }

  local skill_name
  skill_name=$(state_read "$state_file" '.skill_name // ""')

  local is_stuck=false
  [[ "$is_stuck_arg" == "1" ]] && is_stuck=true

  local iter_tag
  if [[ $max_iterations -gt 0 ]]; then
    iter_tag="iter ${next_iteration}/${max_iterations}"
  else
    iter_tag="iter ${next_iteration}"
  fi

  # systemMessage — continuation phrasing softens the harness UI's
  # "Stop hook error:" prefix on healthy progress.
  local system_msg label="${skill_name:-loop}"
  if [[ "$is_stuck" == "true" ]]; then
    system_msg="Superpower Loop ${iter_tag} | STUCK — ${edits_since_spawn} direct edits without a sub-agent spawn. Phase 3 step 2 violation."
  elif [[ -n "$completion_promise" && "$completion_promise" != "null" ]]; then
    system_msg="Superpower Loop ${iter_tag} | Continue ${label}. <promise>${completion_promise}</promise> when DONE (only when TRUE)."
  else
    system_msg="Superpower Loop ${iter_tag} | Continue ${label}."
  fi

  # Reason header.
  local injected
  if [[ "$is_stuck" == "true" ]]; then
    injected="**STUCK** — ${edits_since_spawn} direct file edits without an Agent tool call. executing-plans Phase 3 step 2 forbids inline batch execution.

Recovery: spawn the batch coordinator via the Agent tool, OR if all batch tasks are \`completed\` (run TaskList), proceed to Phase 5 → Phase 6. See \`./references/batch-execution-playbook.md\`."
  elif [[ -n "$skill_name" ]]; then
    injected="Continue superpowers:${skill_name} (${iter_tag})."
  else
    injected="$base_prompt"
  fi

  # Modified-files snapshot — first re-injection only (next_iteration <= 2).
  # After that the list is in state file and SKILL.md is in working context;
  # re-pasting the same list every turn is the pollution this plugin
  # claims to prevent. Capped at 20 with an overflow pointer.
  if [[ "$is_stuck" != "true" ]] && [[ $next_iteration -le 2 ]]; then
    local files_total files_lines files_md
    files_total=$(jq -r '.modified_files // [] | length' "$state_file" 2>/dev/null)
    [[ "$files_total" =~ ^[0-9]+$ ]] || files_total=0
    files_lines=$(jq -r '.modified_files // [] | .[]' "$state_file" 2>/dev/null | sort -u | head -20)
    files_md=""
    if [[ -n "$files_lines" ]]; then
      while IFS= read -r f; do
        [[ -n "$f" ]] && files_md="${files_md}- ${f}"$'\n'
      done <<< "$files_lines"
    fi
    if [[ -n "$files_md" ]]; then
      [[ $files_total -gt 20 ]] && files_md="${files_md}- ... ($((files_total - 20)) more — see state file)"$'\n'
      injected="${injected}

---
Already produced this session (Read or Edit existing files — do NOT recreate from scratch):
${files_md%$'\n'}"
    fi
  fi

  if [[ -n "$completion_promise" && "$completion_promise" != "null" ]]; then
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
    # Order matters: log BEFORE _loop_clear_state because the helper reads
    # state.prompt to extract the plan path, which clear_state deletes.
    _loop_log_plan_completion_if_executing "$state_file"
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

  # Stuck detection — scoped to executing-plans (the only skill where
  # main-agent direct edits past iter 1 violate a contract). Signal is
  # `edits_since_last_spawn`, fed by track-changes.sh (+1 per Edit) and
  # reset by track-spawns.sh (PostToolUse Agent). Threshold 5 leaves
  # headroom for the main-agent allow-list (handoff state, sprint
  # contract, evaluation report, maybe PIVOT _index.md).
  local skill_name edits_since_spawn is_stuck=0
  skill_name=$(state_read "$state_file" '.skill_name // ""')
  edits_since_spawn=$(state_read "$state_file" '.edits_since_last_spawn // 0')
  [[ "$edits_since_spawn" =~ ^[0-9]+$ ]] || edits_since_spawn=0

  if [[ "$skill_name" == "executing-plans" ]] \
     && [[ $iteration -ge 2 ]] \
     && [[ $edits_since_spawn -gt 5 ]]; then
    is_stuck=1
  fi

  _loop_emit_block "$state_file" "$iteration" "$max_iterations" "$completion_promise" "$prompt" "$is_stuck" "$edits_since_spawn"
}
