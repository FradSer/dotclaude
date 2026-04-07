# Analysis Patterns Reference

Detailed analysis logic for the retrospective skill.

## Failure Frequency Analysis

For each checklist item across all input plans:

1. Read all `evaluation-round-*-batch-*.md` files
2. Parse the Checklist Results table for each report
3. Count distinct plans (not batches) where the item has at least one FAIL
4. Sort by frequency descending

Output format:

```markdown
## Failure Frequency

| Item ID | Mode | FAILed in N plans | Plans | Most common evidence |
|---------|------|-------------------|-------|---------------------|
| SCEN-CONC-01 | design | 3 | plan-1, plan-2, plan-3 | vague Given clauses |
| CODE-QUAL-01 | code | 2 | plan-1, plan-3 | TODO comments |
```

## Plateau Task Detection

A plateau task is one that received REWORK across 2+ consecutive evaluation rounds within a single plan, with the same or similar error each time.

Detection process:
1. For each plan, read evaluation rounds sequentially
2. Track per-task verdict history: `[PASS, REWORK, REWORK, PASS]`
3. Identify consecutive REWORK streaks of length >= 2
4. Extract the rework item from each round -- if the same Item ID FAILs, it's a plateau
5. Analyze the root cause: was the failure due to a missing checklist item or an implementation difficulty?

Output format:

```markdown
## Plateau Tasks

| Plan | Task | Consecutive REWORK rounds | Root cause | Checklist gap? |
|------|------|---------------------------|------------|----------------|
| plan-2 | task-004 | 2 (rounds 1-2) | verification command not executable | Yes: TASK-COMP-03 not enforced |
```

## Never-Failing Item Analysis

Items that have never FAILed may not be detecting genuine issues.

Detection process:
1. For each checklist item, count total evaluation reports where it was applied
2. Count total FAILs for that item
3. Items with 0 FAILs and 10+ total reports are candidates for REMOVE

Caveat: Some items are legitimately easy to satisfy (e.g., "file exists"). The user must confirm that the pattern is no longer a real failure mode before removing.

Output format:

```markdown
## Never-Failing Items

| Item ID | Mode | Reports evaluated | FAILs | Candidate action |
|---------|------|-------------------|-------|-----------------|
| PLAN-GRAN-01 | plan | 12 | 0 | REMOVE candidate |
```

## Variety Gap Analysis

Read executing-plans completion summaries for entries matching:
`"Batch {N}: all items PASS after {M} rework rounds"`

These indicate the checklist missed the failure mode that caused rework. Cross-reference with the batch's rework items to identify what was failing.

Output format:

```markdown
## Variety Gaps

| Plan | Batch | Rework rounds | Failure mode not covered |
|------|-------|---------------|------------------------|
| plan-3 | Batch 2 | 3 | Import path resolution errors |
```

## Harness Health Criteria

Evaluate each harness component against recent data:

| Component | Health signal | Recommendation if triggered |
|-----------|--------------|---------------------------|
| Evaluator | All tasks PASS on first round in 3+ consecutive plans | Reduce evaluation to `light` intensity |
| Sprint contracts | No "Recurring Failure Patterns" injection in 5+ batches | Sprint contracts still valuable for acceptance criteria; keep |
| Intra-plan learning | Recurring patterns injected but same items still FAIL | Review injection mechanism -- may need stronger generator guidance |
| Checklist mode X | Only regression items, all passing in 3+ plans | Reduce to spot-check (every 3rd batch) for that mode |
| Batch handoffs | N/A -- always lightweight | No action needed |

Output as "Harness Health" section with recommendations. Never auto-disable components.

## Cross-Layer Correlation

When a code-mode item (CODE-VER, CODE-QUAL) persistently FAILs, check whether the upstream design or plan checklist covered the related requirement:

- If the design checklist has no item for the requirement → propose ADD to design checklist
- If the plan checklist has the requirement but verification is weak → propose MODIFY to plan checklist
- If both upstream checklists pass but code still fails → the gap is in implementation guidance, not checklists
