#!/bin/bash
#
# lib/loop.sh — Stop hook: Superpower Loop iteration.
#
# Sourced by hooks/stop-hook.sh. Exposes:
#   loop_phase "<state_file>" "<transcript_path>"
#
# Behavior:
#   - If no active loop → return 0 (allow session exit)
#   - If loop state is corrupted / max iterations / no transcript → clear loop
#     fields on state file, return 0 (allow exit)
#   - If loop is active and completion promise detected → clear loop fields,
#     return 0 (allow exit)
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
  local index_file task_count=0 batch_count=0
  local completion_commit="" modified_files_json="[]"
  local root

  skill_name=$(state_read "$state_file" '.skill_name // ""')
  [[ "$skill_name" != "executing-plans" ]] && return 0

  # `|| true` swallows grep-no-match: under `set -euo pipefail` an assignment
  # whose command substitution returns non-zero DOES propagate (despite
  # folklore) — the regression test
  # `test_executing_plans_without_plan_path_in_prompt_skips_log` caught that.
  prompt=$(state_read "$state_file" '.prompt // ""')
  plan_path=$(printf '%s' "$prompt" | grep -oE 'docs/plans/[A-Za-z0-9_/.-]+-plan/?' | head -1) || true
  [[ -z "$plan_path" ]] && return 0
  plan_path="${plan_path%/}"  # normalize so trailing-slash variants dedup

  # Project root via the shared utils.sh::repo_root helper (T-001 fix):
  # CLAUDE_PROJECT_DIR first, then git rev-parse, then PWD. HEAD is fetched
  # separately so we can keep the commit-hash enrichment without re-resolving
  # the root. Falls back gracefully when not in a git repo (HEAD output empty
  # → completion_commit stays ""). repo-relative `plan` field stays
  # cross-worktree / cross-clone stable; pre-v2.8.2 absolute-path entries age
  # out naturally because dedup matches on the new form, not the old.
  root="$(repo_root)"
  completion_commit=$(git -C "$root" rev-parse HEAD 2>/dev/null || true)
  [[ "$completion_commit" =~ ^[a-f0-9]{7,40}$ ]] || completion_commit=""

  log_dir="${root}/docs/retros"
  log_file="${log_dir}/plans-completed.jsonl"
  mkdir -p "$log_dir" 2>/dev/null || return 0

  # plans-completed.jsonl is "first completion per plan" — multiple promise
  # fires (re-entry, amendment, partial rerun) on the same plan must not
  # inflate RETROSPECTIVE DUE counts. Empirical evidence: user-simulation
  # 2026-05-08 logged the same plan twice (slash + no-slash variants, 7.5h
  # apart). Tail-bounded grep is fast even on long-lived logs and survives
  # corrupt prior lines; anchored on the canonical `,"plan":"<path>",` form
  # so a substring of an unrelated field can't false-match.
  if [[ -f "$log_file" ]] \
     && tail -n 200 "$log_file" 2>/dev/null \
        | grep -qF ",\"plan\":\"${plan_path}\","; then
    return 0
  fi

  # Best-effort enrichment: 0 means "unknown" to retrospective, never aborts.
  # `grep -c || true` is required under set -euo pipefail (no-match returns 1).
  # batch_count uses an inline glob loop instead of `find | wc -l` so a
  # missing plan dir doesn't propagate find's exit-1 through the pipeline.
  index_file="${root}/${plan_path}/_index.md"
  if [[ -f "$index_file" ]]; then
    task_count=$(grep -cE '^[[:space:]]*-[[:space:]]*id:' "$index_file" 2>/dev/null || true)
    [[ "$task_count" =~ ^[0-9]+$ ]] || task_count=0
  fi
  local _bc_file
  for _bc_file in "${root}/${plan_path}"/sprint-contract-batch-*.md; do
    [[ -e "$_bc_file" ]] && batch_count=$((batch_count + 1))
  done

  # modified_files is the cross-batch accumulator written by track-changes.sh
  # (PostToolUse Edit/Write/MultiEdit). At plan completion it scopes
  # post-plan-diff to plan-touched files only — changes outside this set
  # are user evolution, not feedback on superpowers output.
  modified_files_json=$(state_read_json "$state_file" '.modified_files // []')
  [[ "$modified_files_json" == "null" ]] && modified_files_json="[]"

  now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  jq -nc \
    --arg plan "$plan_path" \
    --arg root "$root" \
    --arg ts "$now" \
    --arg commit "$completion_commit" \
    --argjson tc "$task_count" \
    --argjson bc "$batch_count" \
    --argjson mf "$modified_files_json" \
    '{event: "plan_completed", plan: $plan, repo_root: $root, task_count: $tc, batch_count: $bc, completion_commit: $commit, completion_modified_files: $mf, timestamp: $ts}' \
    >> "$log_file" 2>/dev/null || true
}

# Clear all loop-related fields on the state file in one atomic update.
# .edits_since_last_spawn survives — it's session-scoped (track-changes.sh /
# track-spawns.sh own it) so a follow-up loop inherits the right counter.
# .stall_count / .last_output_hash are loop-scoped (set only by the stall
# detector below) and must be deleted here so a follow-up loop starts fresh
# at 0 instead of inheriting a stale near-threshold counter.
_loop_clear_state() {
  local state_file="$1"
  local now
  now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  state_update "$state_file" --arg ts "$now" \
    'del(.active, .iteration, .max_iterations, .completion_promise, .prompt, .started_at, .stall_count, .last_output_hash) | .updated_at = $ts' \
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
  # stuck_kind: "none" | "edits" | "reads". "1" is accepted as legacy
  # alias for "edits" — older test fixtures and callers may still pass
  # the boolean form. Both map to the same recovery message.
  local stuck_kind="${6:-none}"
  local edits_since_spawn="${7:-0}"
  local reads_since_spawn="${8:-0}"
  [[ "$stuck_kind" == "1" ]] && stuck_kind="edits"
  [[ "$stuck_kind" == "0" ]] && stuck_kind="none"

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

  # is_stuck retains the boolean shape downstream code expects, but it's
  # now a derived flag from stuck_kind (any non-none value is stuck).
  local is_stuck=false
  [[ "$stuck_kind" != "none" ]] && is_stuck=true

  local iter_tag
  if [[ $max_iterations -gt 0 ]]; then
    iter_tag="iter ${next_iteration}/${max_iterations}"
  else
    iter_tag="iter ${next_iteration}"
  fi

  # systemMessage — continuation phrasing softens the harness UI's
  # "Stop hook error:" prefix on healthy progress. The two stuck kinds
  # name different operations (direct edits vs read-only thrash) so
  # claude can recognize which contract was violated from the banner
  # alone, before opening the reason body.
  local system_msg label="${skill_name:-loop}"
  if [[ "$stuck_kind" == "edits" ]]; then
    system_msg="Superpower Loop ${iter_tag} | STUCK — ${edits_since_spawn} direct edits without a sub-agent spawn. Phase 3 step 2 violation."
  elif [[ "$stuck_kind" == "reads" ]]; then
    system_msg="Superpower Loop ${iter_tag} | STUCK (read-only thrash) — ${reads_since_spawn} reads / Glob / Grep / Bash calls without a sub-agent spawn."
  elif [[ -n "$completion_promise" && "$completion_promise" != "null" ]]; then
    system_msg="Superpower Loop ${iter_tag} | Continue ${label}. <promise>${completion_promise}</promise> when DONE (only when TRUE)."
  else
    system_msg="Superpower Loop ${iter_tag} | Continue ${label}."
  fi

  # Reason header.
  local injected
  if [[ "$stuck_kind" == "edits" ]]; then
    injected="**STUCK** — ${edits_since_spawn} direct file edits without an Agent tool call. executing-plans Phase 3 step 2 forbids inline batch execution.

Recovery: spawn the batch coordinator via the Agent tool, OR if all batch tasks are \`completed\` (run TaskList), proceed to Phase 5 → Phase 6. See \`./references/batch-execution-playbook.md\`."
  elif [[ "$stuck_kind" == "reads" ]]; then
    # Read-stuck names a different recovery: the agent isn't writing the
    # wrong files (edits-stuck), it's reading too many files trying to
    # rediscover state. The fix is to act — TaskList tells you what's
    # pending, Agent spawns the coordinator. No more Reads / Bash ls.
    injected="**STUCK** — ${reads_since_spawn} reads (Read / Glob / Grep / Bash) since the last Agent spawn, with no Agent tool call. You are re-exploring state instead of acting.

Recovery (pick one — no more reads):
- Run TaskList → identify the next pending task.
- If batch N has \`sprint-contract-batch-N.md\` but no \`handoff-summary-N.md\`, spawn the Batch N coordinator via the Agent tool.
- If all tasks completed, proceed to Phase 5 (git-agent commit) → Phase 6 (\`<promise>${completion_promise}</promise>\`).

See \`./references/batch-execution-playbook.md\`."
  elif [[ -n "$skill_name" ]]; then
    # Generic phase-pointer hint (Fix A'). The bare "Continue X" header
    # dropped Claude's sense of which phase remained when SKILL.md fell
    # out of the working context (post-compact). Instead of re-pasting the
    # full base_prompt every iteration (4 KB / 50-iter pollution), surface
    # one actionable line that promotes a SKILL.md re-read. The promise
    # tag itself is appended by the LOOP COMPLETION REQUIRED footer below,
    # so this line stays promise-agnostic — no double-mention, no risk of
    # nested `<promise></promise>` when completion_promise is empty.
    injected="Continue superpowers:${skill_name} (${iter_tag}). Re-check SKILL.md for the current phase; do not restart from Phase 1 — resume from the next incomplete phase."
  else
    injected="$base_prompt"
  fi

  # executing-plans batch progress hint (precise, filesystem-derived).
  # Empirical bug: post-iter-2 the generic "Re-check SKILL.md" header
  # gave Claude no concrete next action — main agent burned iters
  # re-exploring the plan dir via ls/stat/Read to reconstruct
  # "where am I?". Counting `sprint-contract-batch-*.md` and
  # `handoff-summary-*.md` on disk turns the re-injection into a single
  # actionable directive. Skipped when:
  #   - skill is not executing-plans (other skills have no batches)
  #   - stuck branch is already firing (its recovery takes precedence)
  #   - iteration < 2 (no batch artifacts exist in setup-only iter 1)
  #   - plan path can't be extracted, or plan dir doesn't exist
  if [[ "$skill_name" == "executing-plans" ]] \
     && [[ "$is_stuck" != "true" ]] \
     && [[ $iteration -ge 2 ]]; then
    local _plan_path _plan_dir _root _contracts_count=0 _summaries_count=0
    _plan_path=$(printf '%s' "$base_prompt" | grep -oE 'docs/plans/[A-Za-z0-9_/.-]+-plan/?' | head -1) || true
    if [[ -n "$_plan_path" ]]; then
      _plan_path="${_plan_path%/}"
      _root="$(repo_root)"
      _plan_dir="${_root}/${_plan_path}"
      if [[ -d "$_plan_dir" ]]; then
        local _f
        for _f in "$_plan_dir"/sprint-contract-batch-*.md; do
          [[ -e "$_f" ]] && _contracts_count=$((_contracts_count + 1))
        done
        for _f in "$_plan_dir"/handoff-summary-*.md; do
          [[ -e "$_f" ]] && _summaries_count=$((_summaries_count + 1))
        done

        # Singular/plural noun matching — "1 sprint contract" reads as
        # natural English; "1 sprint contracts" reads as a bug. The
        # mismatched batch progress was a hint that the re-injection
        # was machine-generated noise, not a real status line.
        local _contract_word="sprint contracts"
        local _summary_word="handoff summaries"
        [[ $_contracts_count -eq 1 ]] && _contract_word="sprint contract"
        [[ $_summaries_count -eq 1 ]] && _summary_word="handoff summary"

        local _current_batch=$((_summaries_count + 1))
        local _hint
        _hint=$'\n\nPlan: '"${_plan_path}"$'\nProgress: '"${_contracts_count} ${_contract_word}, ${_summaries_count} ${_summary_word}."

        if [[ $_contracts_count -gt 0 ]] && [[ $_contracts_count -eq $_summaries_count ]]; then
          # All known contracts have matching summaries. Two indistinguishable
          # cases from the filesystem alone: (a) plan is done, claude should
          # commit; (b) batch N closed but batch N+1 not yet started. The
          # hook can't read TaskList, so it offers both pathways with
          # TaskList as the in-tool decision oracle — claude picks.
          _hint="${_hint} Batch ${_contracts_count} closed (sprint contract and handoff summary match)."$'\n''Next action: Run TaskList.'$'\n''  - If all tasks completed → Phase 5 (git-agent commit) → emit <promise>'"${completion_promise}"'</promise>.'$'\n''  - Else → Phase 3 steps 0-1-2 in one response for Batch '"${_current_batch}"' — write sprint-contract-batch-'"${_current_batch}"'.md, refresh handoff-state.md, then Agent-spawn the coordinator. Steps 0-2 MUST go in one response with Agent last.'
        elif [[ -f "$_plan_dir/sprint-contract-batch-${_current_batch}.md" ]]; then
          # Sprint contract for current batch exists, no matching summary →
          # the coordinator was spawned (or should have been) but the
          # batch is not yet closed. The first tool call MUST be Agent,
          # not another exploration round.
          _hint="${_hint} Batch ${_current_batch} is active — sprint contract written, no handoff summary yet."$'\n''The coordinator has not returned (or was never spawned). Your first tool call MUST be the Agent tool to spawn / await the Batch '"${_current_batch}"' coordinator.'
        else
          # No contract for current batch → Phase 3 step 0 hasn't run yet.
          # Steps 0-1-2 (sprint contract → handoff state → Agent spawn)
          # MUST go in one response per the ATOMIC contract in
          # batch-execution-playbook.md.
          _hint="${_hint} Batch ${_current_batch} not yet started."$'\n''Next action: Phase 3 steps 0-1-2 in one response — write sprint-contract-batch-'"${_current_batch}"'.md, refresh handoff-state.md, then Agent-spawn the coordinator. Steps 0-2 MUST go in one response with Agent last.'
        fi

        injected="${injected}${_hint}"
      fi
    fi
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

# Main loop entry point.
# Returns 0 (allow session exit) or exits 0 (loop handled).
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

  # Numeric-field validation — clear loop state on corruption, allow exit.
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
    return 0
  fi

  # Not complete — continue loop.
  if [[ -z "$prompt" ]]; then
    echo "Warning: Superpower loop: State file has no prompt" >&2
    echo "   Superpower loop is stopping." >&2
    _loop_clear_state "$state_file"
    return 0
  fi

  # Stall detection (Fix B). The promise regex is the ONLY completion
  # criterion the loop honours, so a skill that produces all artifacts in
  # iter 1 but never closes with `<promise>X</promise>` would otherwise
  # burn the entire max_iterations budget — empirically observed in
  # writing-plans where Phase 2 batch-completes Phase 3-6 ceremonial steps
  # get skipped, and "Continue superpowers:writing-plans" produces an
  # empty / identical re-output every iteration. Three consecutive
  # identical-or-empty outputs is the bound where retry stops being
  # productive: Agent spawns are single-turn (never cross Stop hook), and
  # AskUserQuestion blocks the harness UI before Stop fires, so neither
  # legitimate long-running path produces repeated identical outputs.
  local new_hash prior_hash stall_count
  new_hash=$(printf '%s' "$last_output" | shasum 2>/dev/null | awk '{print $1}')
  prior_hash=$(state_read "$state_file" '.last_output_hash // ""')
  stall_count=$(state_read "$state_file" '.stall_count // 0')
  [[ "$stall_count" =~ ^[0-9]+$ ]] || stall_count=0

  if [[ -z "$last_output" ]] || [[ "$new_hash" == "$prior_hash" ]]; then
    stall_count=$((stall_count + 1))
  else
    stall_count=0
  fi

  if [[ $stall_count -ge 3 ]]; then
    echo "Superpower loop: Stalled ${stall_count} iterations (no output progress) — force-clearing state." >&2
    _loop_clear_state "$state_file"
    # Surface to the user so the cleared state is observable, not silent.
    # `continue: true` lets the session exit cleanly (stop hook already
    # returned 0 effectively); the message names the failure mode so
    # follow-up debugging starts from the right hypothesis.
    jq -n --arg msg "Superpower Loop force-cleared: stalled ${stall_count} iterations with no output progress. State reset; re-invoke the skill if this was unintentional." \
      '{continue: true, systemMessage: $msg}'
    exit 0
  fi

  state_update "$state_file" \
    --arg h "$new_hash" \
    --argjson sc "$stall_count" \
    '.last_output_hash = $h | .stall_count = $sc' \
    || { echo "Warning: state_update failed mid-stall-track, continuing" >&2; }

  # Stuck detection — both branches scoped to executing-plans (the only
  # skill where main-agent direct work past iter 1 violates a contract).
  # Signals come from PostToolUse hooks:
  #   - edits_since_last_spawn — track-changes.sh (+1 per Edit/Write/MultiEdit)
  #   - reads_since_last_spawn — track-reads.sh (+1 per Read/Glob/Grep/Bash)
  # Both reset to 0 on Agent PostToolUse via track-spawns.sh.
  #
  # Thresholds (chosen for legitimate per-batch headroom):
  #   - Edits: >5 (main-agent allow-list = handoff-state, sprint contract,
  #     evaluation report, maybe PIVOT _index.md ≈ 4).
  #   - Reads: >15 (handoff-state read + sprint contract read + evaluation
  #     report read + task files referenced during PIVOT ≈ 8).
  #
  # Precedence: edits-stuck wins when both fire. Direct-edit violations
  # are the more severe breach (Phase 3 step 2 forbids inline batch
  # execution); read-stuck names a different recovery (Agent / TaskList,
  # not the Direct-Edit Allow-List) and would dilute the dominant message.
  local skill_name edits_since_spawn reads_since_spawn stuck_kind=none
  skill_name=$(state_read "$state_file" '.skill_name // ""')
  edits_since_spawn=$(state_read "$state_file" '.edits_since_last_spawn // 0')
  reads_since_spawn=$(state_read "$state_file" '.reads_since_last_spawn // 0')
  [[ "$edits_since_spawn" =~ ^[0-9]+$ ]] || edits_since_spawn=0
  [[ "$reads_since_spawn" =~ ^[0-9]+$ ]] || reads_since_spawn=0

  if [[ "$skill_name" == "executing-plans" ]] && [[ $iteration -ge $SP_STUCK_MIN_ITER ]]; then
    if [[ $edits_since_spawn -gt $SP_STUCK_EDIT_BUDGET ]]; then
      stuck_kind=edits
    elif [[ $reads_since_spawn -gt $SP_STUCK_READ_BUDGET ]]; then
      stuck_kind=reads
    fi
  fi

  _loop_emit_block "$state_file" "$iteration" "$max_iterations" "$completion_promise" "$prompt" "$stuck_kind" "$edits_since_spawn" "$reads_since_spawn"
}
