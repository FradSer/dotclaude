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

**Purpose:** Assess completed work against the sprint contract using binary checklist evaluation. Identifies rework items, recommendations, and whether execution should pivot.

**Location convention:** Evaluation artifacts are stored in the plan directory (e.g., `docs/plans/YYYY-MM-DD-{topic}-plan/`). When a separate evals directory is used, derive the path by replacing `-plan/` with `-evals/` in the plan path.

### Format

```markdown
# Evaluation Round {N} -- Batch {M}

## Checklist Results

| Item ID       | Check                                   | Result | Evidence                                        |
|---------------|-----------------------------------------|--------|-------------------------------------------------|
| REQ-TRACE-01  | All requirements map to >=1 scenario    | PASS   | 7/7 requirements traced                         |
| SCEN-CONC-01  | Given clauses use specific data         | FAIL   | bdd-specs.md:23 -- "some valid user data"       |
| RISK-02       | Mitigations specify concrete actions    | PASS   | All 3 mitigations specify concrete mechanisms   |

## Rework Items

| Item ID      | File         | Location | Issue                                                                 |
|--------------|--------------|----------|-----------------------------------------------------------------------|
| SCEN-CONC-01 | bdd-specs.md | line 23  | Replace "some valid user data" with concrete values (email, password) |

## Recommendations

Non-blocking observations that improve quality but do not require rework:

- Consider extracting token generation into a shared utility for reuse in refresh flow
- Auth handler would benefit from rate limiting in a future task

## Pivot Flag

- **Pivot:** false
- **Rationale:** All tasks on track. Rework items are localized fixes, not architectural issues.

When pivot is `true`, include:
- Root cause referencing the specific repeated error pattern
- Suggested plan modifications
- Tasks to cancel or re-scope

## Run Metrics

| Metric | Value |
|--------|-------|
| Evaluator input tokens | {N or "N/A"} |
| Evaluator output tokens | {N or "N/A"} |
| Evaluation duration | {N}s |
| Checklist version | {mode}-v{N} |

Token counts are best-effort: extracted from API response `usage` field if available. Duration is wall-clock time from evaluator spawn to completion. This section is informational only -- it does not affect the verdict. Absence of token data does not block evaluation or rework.

## Verdict: REWORK
1 item FAIL: SCEN-CONC-01
```

### Field Definitions

| Field | Required | Description |
|-------|----------|-------------|
| Checklist Results | Yes | One row per checklist item with PASS/FAIL result and evidence |
| Rework Items | Yes | Empty table if no FAIL items; keep the section |
| Recommendations | Yes | Empty list if none; keep the section |
| Pivot Flag | Yes | Always present with true/false and rationale |
| Run Metrics | Yes | Best-effort token/duration tracking; use "N/A" when unavailable |

## 3. Handoff Summary

**File naming:** `handoff-summary-{N}.md` (e.g., `handoff-summary-1.md`)

**Purpose:** Capture cumulative state at the end of an evaluation cycle. Enables context recovery if the session restarts or a new agent takes over.

### Format

```markdown
# Handoff Summary {N}

## Completed Tasks

| ID | Subject | Checklist Result | Batch |
|----|---------|------------------|-------|
| 001 | Set up project scaffolding | PASS (all items) | 1 |
| 002 | Configure CI pipeline | PASS (all items) | 1 |
| 003 | Create user authentication handler | PASS (all items) | 2 |

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
