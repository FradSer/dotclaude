# Evaluation File Formats

Single source of truth for all evaluation-related file formats. The evaluator agent and executing-plans skill both reference this file.

## File Location and Lifecycle

All evaluation files live in the plan directory alongside task files (e.g., `docs/plans/YYYY-MM-DD-feature-plan/`).

| Property | Value |
|----------|-------|
| Written by | Evaluator agent |
| Read by | Generator (executing-plans skill) |
| Committed | NOT committed by default -- these are ephemeral working artifacts |
| Cleanup | Deleted after plan execution completes, or kept if user explicitly requests |

## 1. Sprint Contract

**File naming:** `sprint-contract-batch-{N}.md` (e.g., `sprint-contract-batch-1.md`)

**Purpose:** Define the scope, acceptance criteria, and expected BDD states for a batch before execution begins. The evaluator writes this contract; the generator executes against it.

### Format

```markdown
# Batch {N} Sprint Contract

## Tasks

| ID | Subject | Type |
|----|---------|------|
| 003 | Create user authentication handler | impl |
| 004 | Add input validation middleware | impl |
| 005 | Write auth handler test | test |

## Acceptance Criteria

### Task 003: Create user authentication handler

- [ ] Handler accepts username and password parameters
- [ ] Returns JWT token on successful authentication
- [ ] Returns 401 status on invalid credentials
- [ ] Logs authentication attempts with timestamp

### Task 004: Add input validation middleware

- [ ] Validates required fields are present
- [ ] Sanitizes string inputs against XSS
- [ ] Returns 400 with field-level error messages on validation failure

### Task 005: Write auth handler test

- [ ] Covers successful login scenario
- [ ] Covers invalid password scenario
- [ ] Covers missing username scenario

## Red-Green Pairs

| Test Task | Impl Task | Expected Red State | Expected Green State |
|-----------|-----------|--------------------|----------------------|
| 005 | 003 | Test runs, assertions fail (no handler exists) | Test passes after handler implementation |

Tasks not part of a Red-Green pair have no Red state expectation.

## Sign-off

- **Evaluator:** [agent identifier]
- **Timestamp:** [ISO 8601 timestamp]
- **Status:** APPROVED
```

### Field Definitions

| Field | Required | Description |
|-------|----------|-------------|
| Tasks table | Yes | Every task in the batch with ID, subject, and type |
| Acceptance Criteria | Yes | Per-task checklist with testable, binary pass/fail items |
| Red-Green Pairs | Yes | Omit rows if batch has no pairs; keep the section with "None" |
| Sign-off | Yes | Evaluator identity and approval timestamp |

## 2. Evaluation Report

**File naming:** `evaluation-round-{N}-batch-{M}.md` (e.g., `evaluation-round-1-batch-2.md`)

**Purpose:** Score completed work against the sprint contract. Identifies rework items, recommendations, and whether execution should pivot.

### Format

```markdown
# Evaluation Round {N} -- Batch {M}

## Per-Task Scores

| Task ID | Correctness | Completeness | Code Quality | Test Coverage | Spec Compliance | Verdict |
|---------|-------------|--------------|--------------|---------------|-----------------|---------|
| 003 | 4 | 5 | 3 | N/A | 5 | PASS |
| 004 | 5 | 4 | 4 | N/A | 4 | PASS |
| 005 | 5 | 3 | 4 | 5 | 4 | REWORK |

### Scoring Scale

- **5** = Excellent, no issues
- **4** = Good, minor issues only
- **3** = Acceptable, some issues to address
- **2** = Below standard, significant rework needed
- **1** = Failing, major rework or rewrite needed
- **N/A** = Dimension not applicable to this task type

### Task Type Weighting

| Dimension | test | impl | setup | config | refactor |
|-----------|------|------|-------|--------|----------|
| Correctness | Yes | Yes | Yes | Yes | Yes |
| Completeness | Yes | Yes | Yes | Yes | Yes |
| Code Quality | Yes | Yes | N/A | N/A | Yes |
| Test Coverage | Yes | N/A | N/A | N/A | N/A |
| Spec Compliance | Yes | Yes | Yes | Yes | Yes |

### Verdict Rules

- **PASS**: All applicable dimensions >= 3 AND no dimension == 1
- **REWORK**: Any applicable dimension < 3 OR any dimension == 1

## Rework Items

| # | File Path | Line Range | Issue | Dimension | Severity |
|---|-----------|------------|-------|-----------|----------|
| 1 | src/auth/handler.ts | 42-58 | Missing error handling for expired tokens | Correctness | HIGH |
| 2 | src/middleware/validate.ts | 15-20 | Sanitization does not cover script tags in attributes | Completeness | MEDIUM |

### Severity Levels

- **HIGH**: Blocks acceptance, must fix before next evaluation round
- **MEDIUM**: Should fix, may defer to next batch if isolated
- **LOW**: Improvement opportunity, does not block acceptance

## Recommendations

Non-blocking observations that improve quality but do not require rework:

- Consider extracting token generation into a shared utility for reuse in refresh flow
- Auth handler would benefit from rate limiting in a future task

## Pivot Flag

- **Pivot:** false
- **Rationale:** All tasks on track. Rework items are localized fixes, not architectural issues.

When pivot is `true`, include:
- Root cause of the pivot decision
- Suggested plan modifications
- Tasks to cancel or re-scope
```

### Field Definitions

| Field | Required | Description |
|-------|----------|-------------|
| Per-Task Scores | Yes | One row per task, all applicable dimensions scored |
| Rework Items | Yes | Empty table if no rework needed; keep the section |
| Recommendations | Yes | Empty list if none; keep the section |
| Pivot Flag | Yes | Always present with true/false and rationale |

## 3. Handoff Summary

**File naming:** `handoff-summary-{N}.md` (e.g., `handoff-summary-1.md`)

**Purpose:** Capture cumulative state at the end of an evaluation cycle. Enables context recovery if the session restarts or a new agent takes over.

### Format

```markdown
# Handoff Summary {N}

## Completed Tasks

| ID | Subject | Scores (Corr/Comp/Qual/Test/Spec) | Batch |
|----|---------|-----------------------------------|-------|
| 001 | Set up project scaffolding | 5/5/N/A/N/A/5 | 1 |
| 002 | Configure CI pipeline | 5/4/N/A/N/A/4 | 1 |
| 003 | Create user authentication handler | 4/5/4/N/A/5 | 2 |

## Remaining Tasks

| ID | Subject | Status | Dependencies |
|----|---------|--------|--------------|
| 006 | Implement session management | pending | 003 |
| 007 | Add logout endpoint | pending | 003, 006 |
| 008 | Write session management test | pending | -- |

Use `--` for tasks with no dependencies.

## Key Decisions

- Chose JWT over session cookies for stateless auth (Batch 1, Task 003)
- Deferred rate limiting to a separate follow-up plan (Evaluation Round 1)
- Switched validation library from zod to valibot after benchmark showed 40% smaller bundle (Batch 2, Task 004)

## File Ownership

| File Path | Last Modified By Task |
|-----------|-----------------------|
| src/auth/handler.ts | 003 |
| src/auth/handler.test.ts | 005 |
| src/middleware/validate.ts | 004 |
| src/config/auth.ts | 001 |

## Blockers

- None

If blockers exist, list each with:
- Blocker description
- Affected task IDs
- Escalation status (reported / waiting / resolved)
```

### Field Definitions

| Field | Required | Description |
|-------|----------|-------------|
| Completed Tasks | Yes | All tasks marked completed across all batches so far |
| Remaining Tasks | Yes | All pending or in-progress tasks with dependency info |
| Key Decisions | Yes | Architectural or process decisions made during execution |
| File Ownership | Yes | Maps every modified file to the task that last changed it |
| Blockers | Yes | Active blockers; write "None" if clear |
