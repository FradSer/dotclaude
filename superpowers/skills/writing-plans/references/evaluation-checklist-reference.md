# Plan Evaluation Checklist Reference

## Purpose

Reference for the superpowers-evaluator when operating in plan mode. The evaluator applies binary PASS/FAIL checklist items from `docs/retros/checklists/plan-v{N}.md` to determine whether a plan is ready for execution or needs rework.

## Checklist Source

The canonical checklist lives at `docs/retros/checklists/plan-v{N}.md` (latest version). The evaluator reads this file at spawn time via the path provided in the spawn context. This reference file provides context on how the checklist items map to plan quality dimensions.

## Checklist Item Categories

| Category | Example Items | What They Check |
|----------|---------------|-----------------|
| BDD Coverage | PLAN-COV-01 | Every design BDD scenario mapped to at least one task |
| Dependency Integrity | DEP-01, DEP-02 | No circular dependencies; all depends-on IDs resolve |
| Task Completeness | TASK-COMP-03 | Verification commands are executable (not descriptions) |
| Test Coverage | TEST-01 | Every impl task has a corresponding test task or justification |

## Verdict Rules

| Verdict | Condition |
|---------|-----------|
| **PASS** | All checklist items PASS |
| **REWORK** | Any checklist item FAIL (include count and IDs of failing items) |

When the verdict is REWORK, produce rework items for each FAIL with: item ID, file, location, issue, and rework action.

## Check Types

Each checklist item is annotated with a type:

- **Computational** (`# Type: computational`): Deterministic check (graph walks, pattern scans, ID matching). Two evaluators always produce the same result.
- **Inferential** (`# Type: inferential`): Requires evaluator judgment anchored to explicit check methods. The evaluator must follow the item's anchor constraint and note borderline results.

## Output Responsibility

The evaluator outputs report content as text. The parent skill (writing-plans) is responsible for writing the report to disk. The evaluator never writes files directly.

## Calibration Example

### Plan: `docs/plans/2026-03-15-user-auth-plan/`

The plan implements a user authentication feature with 8 tasks. The design defines 5 BDD scenarios.

**Checklist Evaluation:**

| Item ID | Check | Result | Evidence |
|---------|-------|--------|----------|
| PLAN-COV-01 | BDD scenario coverage | FAIL | session-expiry scenario has no mapped task |
| TASK-COMP-03 | Verification commands executable | FAIL | task-004: "Verify that rate limiting works" is a description |
| DEP-01 | No circular dependencies | PASS | no cycles detected |
| DEP-02 | All depends-on references resolve | PASS | all IDs match task files |
| TEST-01 | Impl tasks have test counterparts | PASS | all impl tasks paired |

**Verdict:** REWORK (2 items FAIL: PLAN-COV-01, TASK-COMP-03)

**Rework Items:**

| Item ID | File | Location | Issue |
|---------|------|----------|-------|
| PLAN-COV-01 | _index.md | BDD Coverage | Add task for session-expiry scenario |
| TASK-COMP-03 | task-004 | Verification | Replace description with executable command |
