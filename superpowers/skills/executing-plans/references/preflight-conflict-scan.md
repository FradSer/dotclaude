# Pre-Flight Conflict Scan

Runs once, in Phase 1, before Phase 2 task creation and before any batch is dispatched. Catches contradictions between what the plan's task text mandates and what the resolved code checklist (`code-v{N}.md`) will grade against — surfacing them before execution starts is cheaper than discovering them as a REWORK verdict after a sub-agent has already implemented the contradictory version.

## What Counts as a Conflict

A task's explicit wording asks for something the checklist would FAIL. Concrete patterns:

| Task text pattern | Checklist item it collides with | Example |
|---|---|---|
| Task mandates an assertion-free or trivially-true test ("write a smoke test that just imports the module") | `CODE-QUAL-01`/anti-stub items forbidding vacuous tests | Task 004 says "add a placeholder test" but code-v2.md FAILs assertion-free tests |
| Task mandates copy-pasting a block verbatim into a second location | Anti-duplication / DRY checklist items | Task 007 says "duplicate the validation logic in both handlers" but checklist flags duplication |
| Task mandates a hardcoded/stub return for a documented "future work" reason | `CODE-QUAL-02` (no hardcoded stubs) | Task 010 says "return a fixed placeholder pending API access" |
| Task mandates skipping or disabling an existing test | Live-test / no-skip checklist items | Task 003 says "temporarily skip the flaky integration test" |

This is a different check from evaluator Design Mode's `JUST-01` (which looks for an explicit NOT-JUSTIFIED status marker in a design folder) — this scan compares individual task instructions against the checklist that will grade the resulting code, at the plan level, before any code exists.

## Procedure

1. Read every task file's full text (already required by Phase 1 step 1/2).
2. Read the resolved `code-v{N}.md` checklist (same resolution rule as elsewhere: highest `N` in `docs/retros/checklists/` unless the plan pins one).
3. For each task, check its explicit instructions against the checklist item table above (and any other checklist item whose Check-method text plainly contradicts what the task asks for). This is a targeted grep-and-read, not a re-derivation of the whole checklist.
4. If no conflicts are found, this step is a no-op — do not create a file, do not mention it beyond the batch-progress orientation.
5. If conflicts are found, write `preflight-conflicts.md` in the plan directory:

```markdown
# Pre-Flight Conflicts

| Task ID | Task Instruction | Checklist Item | Conflict | Resolution |
|---------|-------------------|-----------------|----------|------------|
| 007 | "duplicate the validation logic in both handlers" | CODE-QUAL-DEDUP-01 | Task asks for the exact pattern the checklist forbids | AUTO-RESOLVED: extract to a shared helper both handlers call; task acceptance criteria updated to match |
```

6. Apply the same Autonomous Resolution Protocol used for ambiguous acceptance criteria (`sprint-contract-template.md` §Autonomous Resolution Protocol): pick the interpretation that satisfies the checklist over the literal task wording, mark it `AUTO-RESOLVED`, and log the applied interpretation in `preflight-conflicts.md`. This skill never prompts the user mid-run — a genuine conflict is resolved the same way an ambiguous Then-clause is resolved, not escalated.
7. Carry the resolution forward into the affected task's sprint contract acceptance criteria (Phase 3 step 0) so the batch coordinator and its sub-agents see the resolved instruction, not the original contradictory one.

## When the Conflict Cannot Be Resolved Concretely

If neither the task instruction nor the checklist item can be reconciled into a single concrete interpretation (e.g., the checklist item itself looks wrong for this plan's domain), log it in `preflight-conflicts.md` with `Resolution: UNRESOLVED — flagged for retrospective` and proceed with the checklist's rule taking precedence for execution purposes (the checklist governs what ships; the plan can be corrected later via `/superpowers:retrospective`). Do not stall Phase 2 waiting on it.
