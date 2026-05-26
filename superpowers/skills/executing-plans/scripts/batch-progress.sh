#!/bin/bash
# batch-progress.sh — Compute filesystem-derived batch progress for an
# executing-plans run. Outputs a precise next-action directive to stdout.
#
# Origin: extracted from the v2.x continuation runtime, formerly at
# loop.sh:241-307 (Removed in v3.0.0). The original code documented this
# mechanism as a bug-fix retrofit:
#
#   "Post-iter-2 the generic 'Re-check SKILL.md' header gave Claude no
#    concrete next action — main agent burned iters re-exploring the
#    plan dir via ls/stat/Read to reconstruct 'where am I?'."
#
# Counting `sprint-contract-batch-*.md` and `handoff-summary-*.md` on
# disk turns "where am I?" into a single actionable directive — the
# same data the loop used to inject, now produced inside the skill
# directory instead of the plugin-level Stop hook.
#
# Usage:
#   bash batch-progress.sh <plan-path>
#
# <plan-path> can be relative to the repo root (e.g.
# `docs/plans/2026-05-27-foo-plan/`) or an absolute path. The skill body
# invokes this as Step 1 of every executing-plans iteration and feeds the
# output into its planning context.
#
# Exit codes: 0 always (missing plan dir produces a helpful message).

set -u

if [[ $# -lt 1 ]]; then
  printf '%s\n' "batch-progress.sh: usage: batch-progress.sh <plan-path>" >&2
  exit 2
fi

PLAN_PATH="${1%/}"

# Resolve repo root — same logic as lib/utils.sh:repo_root(). Inlined
# rather than sourced so this script is portable when the skill dir is
# copied or symlinked outside the plugin layout.
if [[ -n "${CLAUDE_PROJECT_DIR:-}" ]]; then
  REPO_ROOT="$CLAUDE_PROJECT_DIR"
elif REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null); then
  :
else
  REPO_ROOT="${PWD:-}"
fi

# Allow absolute paths through unchanged; resolve relative paths against
# REPO_ROOT.
if [[ "$PLAN_PATH" = /* ]]; then
  PLAN_DIR="$PLAN_PATH"
else
  PLAN_DIR="${REPO_ROOT%/}/${PLAN_PATH}"
fi

if [[ ! -d "$PLAN_DIR" ]]; then
  printf '%s\n' "Plan dir not found: ${PLAN_DIR}"
  printf '%s\n' "Next action: verify the plan path, or run /superpowers:writing-plans first."
  exit 0
fi

contracts_count=0
summaries_count=0
for _f in "$PLAN_DIR"/sprint-contract-batch-*.md; do
  [[ -e "$_f" ]] && contracts_count=$((contracts_count + 1))
done
for _f in "$PLAN_DIR"/handoff-summary-*.md; do
  [[ -e "$_f" ]] && summaries_count=$((summaries_count + 1))
done

# Singular/plural noun matching — "1 sprint contract" reads as natural
# English; "1 sprint contracts" reads as a bug. The original loop's
# mismatched batch progress was a hint that the re-injection was
# machine-generated noise, not a real status line.
contract_word="sprint contracts"
summary_word="handoff summaries"
[[ $contracts_count -eq 1 ]] && contract_word="sprint contract"
[[ $summaries_count -eq 1 ]] && summary_word="handoff summary"

current_batch=$((summaries_count + 1))

printf 'Plan: %s\n' "${PLAN_PATH}"
printf 'Progress: %d %s, %d %s.\n' "$contracts_count" "$contract_word" "$summaries_count" "$summary_word"

if [[ $contracts_count -eq 0 ]] && [[ $summaries_count -eq 0 ]]; then
  # Plan dir exists but no batches have started yet — this is the
  # initial pass through Phase 1/2. The directive points at the first
  # batch setup, not at exploration.
  printf 'No batches started.\n'
  printf 'Next action: complete Phase 1 (Plan Review) and Phase 2 (Task Creation), then Phase 3 steps 0-1-2 in one response for Batch 1 — write sprint-contract-batch-1.md, refresh handoff-state.md, then Agent-spawn the coordinator. Steps 0-2 MUST go in one response with Agent last.\n'
elif [[ $contracts_count -gt 0 ]] && [[ $contracts_count -eq $summaries_count ]]; then
  # All known contracts have matching summaries. Two indistinguishable
  # cases from the filesystem alone: (a) plan is done, claude should
  # commit; (b) batch N closed but batch N+1 not yet started. This
  # script can't read TaskList, so it offers both pathways with
  # TaskList as the in-tool decision oracle — claude picks.
  printf 'Batch %d closed (sprint contract and handoff summary match).\n' "$contracts_count"
  printf 'Next action: Run TaskList.\n'
  printf '  - If all tasks completed → Phase 5 (git-agent commit) → Phase 6 (Completion).\n'
  printf '  - Else → Phase 3 steps 0-1-2 in one response for Batch %d — write sprint-contract-batch-%d.md, refresh handoff-state.md, then Agent-spawn the coordinator. Steps 0-2 MUST go in one response with Agent last.\n' "$current_batch" "$current_batch"
elif [[ -f "$PLAN_DIR/sprint-contract-batch-${current_batch}.md" ]]; then
  # Sprint contract for current batch exists, no matching summary →
  # the coordinator was spawned (or should have been) but the batch
  # is not yet closed. The next tool call MUST be Agent, not another
  # exploration round.
  printf 'Batch %d is active — sprint contract written, no handoff summary yet.\n' "$current_batch"
  printf 'The coordinator has not returned (or was never spawned). Your next tool call MUST be the Agent tool to spawn / await the Batch %d coordinator.\n' "$current_batch"
else
  # No contract for current batch → Phase 3 step 0 hasn't run yet.
  # Steps 0-1-2 (sprint contract → handoff state → Agent spawn) MUST
  # go in one response per the ATOMIC contract in
  # batch-execution-playbook.md.
  printf 'Batch %d not yet started.\n' "$current_batch"
  printf 'Next action: Phase 3 steps 0-1-2 in one response — write sprint-contract-batch-%d.md, refresh handoff-state.md, then Agent-spawn the coordinator. Steps 0-2 MUST go in one response with Agent last.\n' "$current_batch"
fi
