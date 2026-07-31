# Blocker Detection & Escalation

## Remember
- Review plan critically first
- Follow plan steps exactly
- Don't skip verifications
- Reference skills when plan says to
- Between batches: report progress and proceed directly to the next batch — never pause for user confirmation
- On blocker: log a HARD BLOCKER entry and abort that batch, do NOT guess and do NOT prompt the user
- **Sub-agent Blocker:** If a spawned sub-agent hangs or returns an error, log the failure and abort the batch — do NOT retry in the main agent's context.
- **Sub-agent BLOCKED report:** Triage per `./batch-execution-playbook.md` §Handling Sub-Agent Report States before logging a HARD BLOCKER — supply missing context, escalate model tier, or split the task first. Never re-dispatch the identical prompt to the identical model expecting a different result; that is not triage, it is a wasted turn.
- Never start implementation on main/master branch — if the current branch is main/master, abort immediately with a HARD BLOCKER log entry
- **Autonomous mode:** This skill never prompts the user. On any blocker, log a HARD BLOCKER entry (with full evidence) to the plan directory, then abort that batch and continue with batches that are not affected. Only emit the Phase 6 human summary (`Plan execution complete. All N tasks verified and committed.`) when all non-blocked tasks are done and Phase 5 has committed. `/goal` continuation (if used) must phrase its condition against transcript narration (completion message + final commit hash), not filesystem state — see `executing-plans/SKILL.md` §For unattended multi-batch runs. The `plans-completed.jsonl` row is written by the plugin Stop hook from on-disk state, not from that summary string.

## Integration

**Required workflow skills (MANDATORY for all execution modes):**
- **Superpowers: Behavior Driven Development** - Load `superpowers:behavior-driven-development` skill using the Skill tool for BDD/TDD workflow guidance
- **Superpowers: Writing Plans** - Load `superpowers:writing-plans` skill using the Skill tool to create the plan this skill executes

## Evaluator Escalation

When the independent superpowers-evaluator is enabled, evaluation-driven escalation supplements existing escalation triggers.

### Trigger: Evaluator Rework After 2 Rounds

**Condition:** A task or batch receives REWORK or FAIL verdict from the superpowers-evaluator in 2 consecutive evaluation rounds.

**Evidence to include in escalation:**
- PASS/FAIL checklist results and FAIL items from both evaluation rounds
- Rework items from both rounds (file:line references, issue descriptions)
- Files reviewed by the superpowers-evaluator
- Evaluation report file paths (e.g., `evaluation-round-1-batch-2.md`, `evaluation-round-2-batch-2.md`)

**Autonomous handling (no user prompt):**
1. Log a HARD BLOCKER entry to `blocker-batch-{N}.md` in the plan directory with all evidence above
2. Mark the affected task(s) as `blocked` via TaskUpdate and skip them
3. Re-evaluate dependent tasks — if they can proceed without the blocked task, continue; otherwise mark them `blocked` too
4. Continue executing unblocked batches; the blocker appears in the final completion summary

### Trigger: Pivot Flag Raised

**Condition:** The superpowers-evaluator sets `pivot: true` in the evaluation report. This occurs when the same FAIL items recur across 2 consecutive evaluation rounds with the same error pattern, when multiple tasks share a common architectural root cause, or when rework items require changes outside the current batch scope.

**Evidence to include in escalation:**
- Pivot rationale from evaluation report
- Affected task IDs and scores
- Suggested plan modifications from the superpowers-evaluator

**Autonomous handling (no user prompt):**
1. Apply the superpowers-evaluator's suggested plan modifications directly to the remaining tasks
2. Log the pivot rationale and applied changes to `pivot-batch-{N}.md` in the plan directory
3. If the suggestions are ambiguous or empty, fall back to one additional rework round; if that also fails, log a HARD BLOCKER and skip the affected tasks

### Integration with Existing Triggers

Evaluator escalation triggers coexist with existing triggers (repeated verification failure, missing dependency, unclear instruction, sub-agent blocker). When multiple triggers fire simultaneously, log all of them in a single combined blocker entry and continue per the autonomous handling rules above — never prompt the user.
