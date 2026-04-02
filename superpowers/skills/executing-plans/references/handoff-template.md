# Handoff Summary Template

## Overview

Handoff summaries are structured documentation artifacts produced during long plan executions (16+ tasks). They provide a human-readable snapshot of progress at configurable boundaries, capturing completed work, remaining tasks, architectural decisions, file ownership, and blockers.

**Scope limitation:** Handoff summaries are documentation only. They do NOT reset, compress, or modify Claude Code's conversation context. TaskList remains the authoritative source of task state at all times. The orchestrator produces these files for progress tracking and auditability -- they have no effect on agent memory or context windows.

## When to Produce

Generate a handoff summary file when any of these boundaries is reached:

| Trigger | Default | Description |
|---------|---------|-------------|
| Batch count | Every 3 batches | Produce after the 3rd, 6th, 9th, ... completed batch |
| Task count | Every 15 tasks | Produce after the 15th, 30th, 45th, ... completed task |
| Plan threshold | 16+ tasks | Only activate handoff mode for plans with 16 or more tasks |

**Configuration precedence:** skill argument > plan metadata (`handoff-boundary` key in `_index.md` YAML) > defaults above.

If both batch and task triggers fire at the same boundary, produce a single summary (do not duplicate).

## File Naming and Location

Place handoff summary files in the plan directory alongside task files:

```
docs/plans/YYYY-MM-DD-topic-plan/
  _index.md
  task-001-setup.md
  task-002-impl.md
  ...
  handoff-summary-1.md    # After first boundary
  handoff-summary-2.md    # After second boundary
```

**Naming pattern:** `handoff-summary-{N}.md` where `{N}` is a sequential integer starting at 1.

## Template Structure

Each handoff summary contains exactly 5 sections in this order. Follow the Handoff Summary Format defined in `evaluation-file-formats.md` for the canonical field definitions.

### Section 1: Completed Tasks

Table of all tasks marked `completed` up to this boundary.

```markdown
## Completed Tasks

| ID | Subject | Scores | Batch |
|----|---------|--------|-------|
| 001 | Set up project structure | C:5 Cm:5 Q:4 T:N/A S:5 | 1 |
| 002 | Write auth handler tests | C:4 Cm:4 Q:5 T:5 S:4 | 1 |
| 003 | Implement auth handler | C:5 Cm:5 Q:4 T:5 S:5 | 1 |
```

**Column definitions:**
- **ID**: Task identifier from the plan
- **Subject**: Brief imperative title from the task
- **Scores**: Evaluation dimension scores (Correctness, Completeness, code Quality, Test coverage, Spec compliance). Use `N/A` for dimensions not applicable to the task type. Omit the Scores column entirely if evaluation mode is not active.
- **Batch**: Batch number in which the task was executed

### Section 2: Remaining Tasks

Table of all tasks not yet completed at this boundary.

```markdown
## Remaining Tasks

| ID | Subject | Status | Dependencies |
|----|---------|--------|--------------|
| 004 | Create API endpoints | pending | 003 |
| 005 | Write integration tests | pending | 004 |
| 006 | Add error handling | in_progress | 003 |
```

**Column definitions:**
- **ID**: Task identifier from the plan
- **Subject**: Brief imperative title from the task
- **Status**: Current TaskList status (`pending`, `in_progress`, `blocked`)
- **Dependencies**: Comma-separated list of task IDs this task depends on, or `none`

### Section 3: Key Decisions

Bulleted list of architectural or design decisions made during execution that affect remaining work.

```markdown
## Key Decisions

- Chose PostgreSQL connection pooling over per-request connections (task 002) -- affects all DB tasks
- Adopted repository pattern for data access layer (task 003) -- remaining impl tasks must follow
- Deferred pagination to a follow-up plan (task 004 blocker discussion) -- do not implement in remaining tasks
```

Include only decisions that influence how remaining tasks should be executed. Omit routine implementation choices.

### Section 4: File Ownership

Table mapping files modified during execution to the last task that modified them.

```markdown
## File Ownership

| File Path | Last Modified By Task |
|-----------|-----------------------|
| src/auth/handler.ts | 003 |
| src/auth/handler.test.ts | 002 |
| src/db/connection.ts | 001 |
| src/config/database.yml | 001 |
```

**Column definitions:**
- **File Path**: Relative path from project root
- **Last Modified By Task**: ID of the most recent task that wrote to this file

This map helps identify potential merge conflicts and clarifies which task owns each file for remaining work.

### Section 5: Blockers

List of unresolved blockers accumulated during execution.

```markdown
## Blockers

- [BLOCKER-001] Missing API specification for `/users` endpoint -- blocks task 005 (reported at batch 2)
- [BLOCKER-002] Flaky CI on macOS runner -- intermittent failure in task 004 verification (reported at batch 3)
```

If no blockers exist, state explicitly:

```markdown
## Blockers

None.
```

## Production Rules

1. **Read TaskList** to get current task statuses before generating any section
2. **Populate all 5 sections** -- do not omit any section, even if empty (use "None." for empty lists)
3. **Increment the summary number** sequentially from the last handoff file in the plan directory
4. **Do not modify TaskList** -- the handoff summary reflects state, it does not change state
5. **Do not commit by default** -- handoff files are ephemeral artifacts unless the user opts in to committing them

## Reference

Handoff summary files follow the Handoff Summary Format defined in `evaluation-file-formats.md`. Consult that reference for canonical field definitions, scoring abbreviations, and format conventions shared across all evaluation-related file types.
