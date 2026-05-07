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
# Used by every "abort the loop but stay in session" path.
_loop_clear_state() {
  local state_file="$1"
  local now
  now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  state_update "$state_file" --arg ts "$now" \
    'del(.active, .iteration, .max_iterations, .completion_promise, .prompt, .started_at, .previous_modified_count, .stuck_count) | .updated_at = $ts' \
    || { echo "Warning: state_update failed mid-loop, falling through" >&2; return 0; }
}

# Decide whether a given iteration should re-inject the heavy "keyframe"
# blocks (SKILL.md LOOP_REINJECT excerpt + cumulative file list). Empirical
# audit (real executing-plans run, 5 consecutive Stops) showed every
# iteration re-injecting a 30+ line system reminder while modified_files
# barely changed — exactly the context pollution this plugin claims to
# prevent. Heavy blocks now ride only on the first re-injection
# (next_iteration <= 2) and every 5th iteration thereafter (5, 10, 15, ...);
# in-between iterations get the lean header + tail only. Keeps long loops
# anchored without burning ~1500 tokens × N turns.
_loop_is_keyframe_iteration() {
  local iter="$1"
  if [[ "$iter" -le 2 ]] || [[ $((iter % 5)) -eq 0 ]]; then
    return 0
  fi
  return 1
}

# Emit block JSON to continue the loop with the next iteration prompt.
# Exits with status 0 after emission.
_loop_emit_block() {
  local state_file="$1"
  local iteration="$2"
  local max_iterations="$3"
  local completion_promise="$4"
  local base_prompt="$5"
  local stuck_count="${6:-0}"

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

  # Is this iteration "stuck"? Threshold = 3 consecutive iterations with no
  # new modified files. Flagged in both systemMessage + reason so Claude
  # gets a strong recovery hint without being silently looped to death.
  local is_stuck=false
  if [[ "$stuck_count" =~ ^[0-9]+$ ]] && [[ $stuck_count -ge 3 ]]; then
    is_stuck=true
  fi

  # Build the iter-tag once — reused in systemMessage and header.
  local iter_tag
  if [[ $max_iterations -gt 0 ]]; then
    iter_tag="iter ${next_iteration}/${max_iterations}"
  else
    iter_tag="iter ${next_iteration}"
  fi

  # System message — present the loop as a continuation, not an error. The
  # harness UI prefixes blocked Stops with "Stop hook error:" which we
  # cannot change, but we control what follows: a continuation phrase
  # reads less alarming than the previous "To stop: output <promise>..."
  # line that always fired even on healthy progress.
  local system_msg
  if [[ "$is_stuck" == "true" ]]; then
    system_msg="Superpower Loop ${iter_tag} | STUCK — no new files in ${stuck_count} iterations. Spawn a sub-agent or emit the promise."
  elif [[ -n "$completion_promise" ]] && [[ "$completion_promise" != "null" ]]; then
    if [[ -n "$skill_name" ]]; then
      system_msg="Superpower Loop ${iter_tag} | Continue ${skill_name}. Promise: <promise>${completion_promise}</promise> when DONE (only when TRUE)."
    else
      system_msg="Superpower Loop ${iter_tag} | Promise: <promise>${completion_promise}</promise> when DONE (only when TRUE)."
    fi
  else
    if [[ -n "$skill_name" ]]; then
      system_msg="Superpower Loop ${iter_tag} | Continue ${skill_name}. No completion promise — runs to max_iterations."
    else
      system_msg="Superpower Loop ${iter_tag} | No completion promise — runs to max_iterations."
    fi
  fi

  # Header — first line of the reason field, which the UI surfaces directly
  # under the "Stop hook error:" prefix. The previous "Use superpowers:X
  # skill." form mimicked slash-command invocation syntax: empirical audit
  # showed Claude treating it as a re-entry signal and walking SKILL.md
  # from the top each iteration (re-evaluating "Bail-Out Check", "First
  # Action - Start Loop"), wasting a turn per loop. "Continue ..." is an
  # imperative continuation phrase that does not collide with skill-trigger
  # heuristics in the harness.
  local injected
  if [[ "$is_stuck" == "true" ]]; then
    injected="**STUCK DETECTED** — No new files modified in ${stuck_count} consecutive loop iterations. The main agent is likely failing to spawn a sub-agent for batch work, or repeating the same reasoning without writing artifacts.

Recovery: spawn a fresh batch coordinator via the Agent tool (Phase 3 step 2 of executing-plans) OR, if the work is genuinely complete, emit <promise>${completion_promise:-DONE}</promise> as the final standalone line. Do NOT continue describing what you will do without producing artifacts."
  elif [[ -n "$skill_name" ]]; then
    injected="Continue superpowers:${skill_name} (${iter_tag}). Resume from your current phase — do NOT re-run earlier phases or re-read the SKILL.md from the top."
  else
    injected="$base_prompt"
  fi

  # Always preserve the original task prompt as the second paragraph when
  # we have a skill_name + base_prompt. setup-superpower-loop.sh embeds the
  # phase progression hint there ("Phase 1 → Phase 2 → ..."), and dropping
  # it forced Claude to guess where to resume. Empirical audit showed the
  # main agent oscillating between Phase 1 and Phase 2 across iterations
  # because the only re-injection was "Use ... skill" with no phase hint.
  if [[ -n "$skill_name" ]] && [[ -n "$base_prompt" ]] && [[ "$is_stuck" != "true" ]]; then
    injected="${injected}

${base_prompt}"
  fi

  # Heavy keyframe blocks only on iteration 1 + every 5th iteration (or on
  # stuck — Claude needs the full picture to recover). In-between iterations
  # the lean header + tail is enough for an agent that already has SKILL.md
  # and the file list in working context.
  local include_heavy=false
  if [[ "$is_stuck" == "true" ]] || _loop_is_keyframe_iteration "$next_iteration"; then
    include_heavy=true
  fi

  # Re-inject the smallest fragment Claude needs every iteration: the
  # SKILL.md "completion criteria" excerpt framed by LOOP_REINJECT markers.
  # This is a protocol-level extraction (HTML-comment delimiters), not a
  # business-aware read — the hook does not interpret skill content, it
  # only forwards what the skill author tagged for re-injection. Without
  # this, long loops drift away from the terminate conditions because the
  # SKILL.md gets pushed out of context after a handful of iterations.
  if [[ "$include_heavy" == "true" ]] && [[ -n "$skill_name" ]]; then
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
  # owns writes to .modified_files.
  #
  # Capped at 20 on keyframe iterations only. Non-keyframe iterations
  # (next_iteration > 2 and not divisible by 5) omit the section entirely
  # — the agent already saw the list in the previous keyframe and re-pasting
  # it 4 out of every 5 turns is exactly the working-context pollution this
  # plugin is supposed to prevent. The previous "20 every iteration" design
  # meant a 30-iteration loop re-injected the same 1.6KB list ~30 times
  # even when the file set was stable.
  if [[ "$include_heavy" == "true" ]]; then
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
      if [[ $files_total -gt 20 ]]; then
        files_md="${files_md}- ... ($((files_total - 20)) more — see state file)"$'\n'
      fi
      injected="${injected}

---
Already produced this session (Read or Edit existing files — do NOT recreate from scratch):
${files_md%$'\n'}"
    fi
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

  # Stuck detection — when modified_files count has not grown for N
  # consecutive iterations, the agent is producing words but not artifacts.
  # Empirical audit (real executing-plans run) showed this pattern: main
  # agent stops 5 times in a row, each iteration adds 0-2 boilerplate
  # `__init__.py` files, and never spawns a sub-agent for actual batch
  # work. Tracking the file-count delta is a cheap signal — sub-agent runs
  # produce file modifications via the Edit/Write PostToolUse hook, so a
  # genuine batch coordinator invocation breaks the streak.
  #
  # Only checked from iteration 5 onward — early iterations may legitimately
  # have no file output (Phase 1 plan review, Phase 2 task creation via
  # TaskCreate which doesn't write files).
  local current_files_count previous_files_count stuck_count
  current_files_count=$(state_read "$state_file" '.modified_files // [] | length')
  [[ "$current_files_count" =~ ^[0-9]+$ ]] || current_files_count=0
  previous_files_count=$(state_read "$state_file" '.previous_modified_count // 0')
  [[ "$previous_files_count" =~ ^[0-9]+$ ]] || previous_files_count=0
  stuck_count=$(state_read "$state_file" '.stuck_count // 0')
  [[ "$stuck_count" =~ ^[0-9]+$ ]] || stuck_count=0

  if [[ $iteration -ge 5 ]] && [[ "$current_files_count" -le "$previous_files_count" ]]; then
    stuck_count=$((stuck_count + 1))
  else
    stuck_count=0
  fi

  state_update "$state_file" \
    --argjson cnt "$current_files_count" \
    --argjson stuck "$stuck_count" \
    '.previous_modified_count = $cnt | .stuck_count = $stuck' \
    || echo "Warning: state_update failed mid-loop-stuck-tracking, continuing" >&2

  _loop_emit_block "$state_file" "$iteration" "$max_iterations" "$completion_promise" "$prompt" "$stuck_count"
}
