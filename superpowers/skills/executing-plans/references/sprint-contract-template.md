# Sprint Contract Template

## Overview

Sprint contracts are produced per-batch by the evaluator before execution begins. They replace implicit done criteria with concrete, testable checklists that the generator executes against.

**Core principle:** Execution does not start until the contract file exists. The evaluator writes the contract; the generator acknowledges it and implements against it.

The contract format follows the Sprint Contract Format defined in `evaluation-file-formats.md`.

| Property | Value |
|----------|-------|
| Written by | Evaluator agent |
| Acknowledged by | Generator (executing-plans skill) |
| Timing | Phase 3 step 0 -- before batch execution begins |
| File naming | `sprint-contract-batch-{N}.md` |

## Template Structure

Each sprint contract contains exactly 4 sections in this order, matching the Sprint Contract Format from `evaluation-file-formats.md`.

### Section 1: Tasks

Table listing every task in the batch with its identifier, subject, and type.

```markdown
# Batch 2 Sprint Contract

## Tasks

| ID | Subject | Type |
|----|---------|------|
| 003 | Create user authentication handler | impl |
| 004 | Add input validation middleware | impl |
| 005 | Write auth handler test | test |
```

### Section 2: Acceptance Criteria

Per-task checklist of testable, binary pass/fail items. Each criterion maps directly to a verifiable outcome.

```markdown
## Acceptance Criteria

### Task 003: Create user authentication handler

- [ ] Handler accepts username and password parameters
- [ ] Returns JWT token on successful authentication
- [ ] Returns 401 status on invalid credentials
- [ ] Logs authentication attempts with timestamp

### Task 005: Write auth handler test

- [ ] Covers successful login scenario
- [ ] Covers invalid password scenario
- [ ] Covers missing username scenario
```

### Section 3: Red-Green Pairs

Table mapping test tasks to their implementation counterparts with expected BDD states.

```markdown
## Red-Green Pairs

| Test Task | Impl Task | Expected Red State | Expected Green State |
|-----------|-----------|--------------------|----------------------|
| 005 | 003 | Test runs, assertions fail (no handler exists) | Test passes after handler implementation |

Tasks not part of a Red-Green pair have no Red state expectation.
```

### Section 4: Sign-off

Evaluator identity and approval status.

```markdown
## Sign-off

- **Evaluator:** evaluator-agent
- **Timestamp:** 2026-04-02T10:30:00Z
- **Status:** APPROVED
```

## Red-Green Pair Distinction

Red-Green pairs enforce the BDD cycle within the sprint contract. The evaluator identifies these pairs during contract generation and defines distinct done criteria for each role.

### Test Tasks (Red State)

A test task is done when: **tests are written and failing for the right reason (Red state).**

| Criterion | Pass | Fail |
|-----------|------|------|
| Test file exists and compiles | Yes | Missing or syntax errors |
| Test assertions target correct behavior | Yes | Assertions are trivial or unrelated |
| Test fails because production code is absent | Yes | Test fails due to test bug |
| Test failure message describes expected behavior | Yes | Opaque or misleading failure |

Example acceptance criterion for a test task:

```markdown
### Task 005: Write auth handler test

- [ ] Test file compiles without errors
- [ ] Running tests produces assertion failures (not import errors or syntax errors)
- [ ] Each test targets a specific BDD scenario from the feature spec
- [ ] Failure messages clearly state what behavior is missing
```

### Implementation Tasks (Green State)

An implementation task is done when: **all tests pass (Green state, exit code 0).**

| Criterion | Pass | Fail |
|-----------|------|------|
| All paired tests pass | Exit code 0 | Any assertion failure |
| No stub or placeholder code | Real logic in every function | `pass`, `TODO`, `NotImplementedError` |
| Existing tests still pass | Full suite green | Regression in unrelated tests |

Example acceptance criterion for an implementation task:

```markdown
### Task 003: Create user authentication handler

- [ ] All tests in auth handler test suite pass (exit code 0)
- [ ] No `TODO`, `FIXME`, or placeholder patterns in handler code
- [ ] Handler implements all scenarios defined in the BDD feature file
- [ ] Existing test suite shows no regressions
```

### Non-Paired Tasks

Tasks that are not part of a Red-Green pair (setup, config, refactor) use standard acceptance criteria. Done = verification command exits 0 and all checklist items satisfied.

## Acceptance Criteria Derivation

Derive testable criteria from BDD scenarios using this process.

### Step 1: Extract from Given/When/Then

Each BDD scenario maps to one or more acceptance criteria. Convert Then-clauses into binary checklist items.

| BDD Element | Maps To |
|-------------|---------|
| Given | Precondition the test must set up (not a criterion itself) |
| When | Action under test (not a criterion itself) |
| Then | One acceptance criterion per Then-clause |
| And (after Then) | Additional acceptance criterion |

Example derivation:

```gherkin
Scenario: Successful login
  Given a registered user with username "alice" and password "secret"
  When the user submits valid credentials
  Then the response status is 200
  And the response body contains a JWT token
  And the token expires in 24 hours
```

Produces three acceptance criteria:

```markdown
- [ ] Returns 200 status on valid credentials
- [ ] Response body contains a JWT token
- [ ] Token expiration is set to 24 hours
```

### Step 2: Ensure Binary Verifiability

Every criterion must be answerable with yes or no. Rewrite vague criteria until they pass this test.

| Vague (reject) | Binary (accept) |
|-----------------|------------------|
| "Handles errors properly" | "Returns 400 with JSON error body when input is missing" |
| "Performance is acceptable" | "Response completes within 200ms for 100 concurrent requests" |
| "UI looks correct" | "Login button is disabled while request is in flight" |

### Step 3: Identify Edge Cases

Scan BDD scenarios for missing coverage. Flag gaps and add criteria for:

| Edge Case Category | What to Look For |
|--------------------|------------------|
| Error paths | Missing Then-clauses for invalid input, network failure, timeout |
| Boundary conditions | Empty strings, zero values, maximum lengths, off-by-one |
| Concurrency | Duplicate submissions, race conditions, stale data |
| Security | Injection, unauthorized access, expired tokens |

If a BDD scenario lacks error path coverage, the evaluator adds criteria derived from the task type. Example: an auth handler task without a "wrong password" scenario gets:

```markdown
- [ ] Returns 401 when password is incorrect
- [ ] Returns 400 when username field is missing
```

## Ambiguity Detection and Flagging

The evaluator scans acceptance criteria for ambiguous language before approving the contract.

### Identifying Vague Then-Clauses

Flag any Then-clause that contains these patterns:

| Pattern | Example | Problem |
|---------|---------|---------|
| Subjective adjective | "Then the response is fast" | No measurable threshold |
| Passive with no actor | "Then the data is processed" | Unclear what "processed" means |
| Missing observable | "Then the system handles the error" | No visible outcome specified |
| Catch-all verb | "Then everything works correctly" | Not testable |

### Flagging and Resolution Protocol

When the evaluator detects ambiguity, flag it in the contract with a suggested concrete alternative:

```markdown
### Task 003: Create user authentication handler

- [ ] Returns JWT token on successful authentication
- [ ] **[AMBIGUOUS]** "Handles invalid input gracefully"
  - Suggested: "Returns 400 with JSON body `{\"error\": \"missing_field\", \"field\": \"<name>\"}` when a required field is absent"
- [ ] Logs authentication attempts with timestamp
```

### Negotiation Protocol

1. **Round 1**: Evaluator flags ambiguous items and proposes concrete alternatives in the contract draft
2. **Round 2**: Generator accepts, counter-proposes, or requests clarification. Evaluator revises and re-issues the contract
3. **Escalation**: If the item remains unresolved after 2 negotiation rounds, escalate to user via AskUserQuestion with the original and proposed alternatives presented side by side
4. **User-accepted risk**: If the user declines to clarify, mark the item as `[USER-ACCEPTED RISK]` and proceed with the evaluator's best interpretation

Maximum 2 negotiation rounds before unresolved items escalate to user. This prevents contract negotiation from stalling execution.

```markdown
- [ ] **[USER-ACCEPTED RISK]** "Handles edge cases appropriately"
  - Evaluator interpretation: validates non-empty strings and rejects payloads over 1MB
```

## Contract Lifecycle

The sprint contract follows a strict lifecycle tied to the batch execution phases.

```
Phase 3, Step 0          Generator              Execution              Grading
     |                      |                      |                     |
  Evaluator            Acknowledges           References            Scored against
  generates            contract               criteria              contract
  contract                                    during impl
     |                      |                      |                     |
  sprint-contract-     Generator confirms     Each task checks      Evaluation report
  batch-{N}.md         receipt and flags      its acceptance        references contract
  written              any objections         criteria              criteria
```

| Stage | Actor | Action | Artifact |
|-------|-------|--------|----------|
| Generation | Evaluator | Writes contract from plan tasks and BDD scenarios | `sprint-contract-batch-{N}.md` |
| Acknowledgement | Generator | Reads contract, flags objections or confirms | Updated contract if negotiation needed |
| Execution | Generator | Implements against acceptance criteria | Source code, test files |
| Grading | Evaluator | Scores work against contract criteria | `evaluation-round-{N}-batch-{M}.md` |

**Critical gate:** Execution does not start until the contract file exists in the plan directory. The generator MUST NOT begin any task in the batch before reading and acknowledging the contract.

## Light Intensity Mode

For `light` intensity, a simplified plan-level summary contract replaces per-batch contracts. This reduces overhead for smaller plans or when the user opts for faster iteration.

### Differences from Standard Mode

| Aspect | Standard (per-batch) | Light (plan-level) |
|--------|----------------------|--------------------|
| Granularity | One contract per batch | One contract for the entire plan |
| File naming | `sprint-contract-batch-{N}.md` | `sprint-contract-summary.md` |
| Acceptance criteria | Per-task checklist | Grouped by milestone or feature area |
| Red-Green pairs | Fully enumerated | Listed but not expanded with state descriptions |
| Negotiation rounds | Up to 2 per batch | Up to 2 for the entire plan |
| Sign-off | Per batch | Single sign-off for all tasks |

### Light Contract Template

```markdown
# Plan Sprint Contract (Light)

## Tasks

| ID | Subject | Type | Batch |
|----|---------|------|-------|
| 001 | Set up project scaffolding | setup | 1 |
| 002 | Write auth handler test | test | 1 |
| 003 | Implement auth handler | impl | 1 |
| 004 | Add input validation | impl | 2 |
| 005 | Write integration tests | test | 2 |

## Acceptance Summary

### Batch 1: Authentication Foundation

- Auth handler returns JWT on valid credentials and 401 on invalid
- Test suite covers success, invalid password, and missing username scenarios
- Project structure follows conventions from _index.md

### Batch 2: Validation Layer

- Input validation rejects missing fields with 400 status
- Integration tests cover end-to-end auth flow

## Red-Green Pairs

| Test Task | Impl Task |
|-----------|-----------|
| 002 | 003 |
| 005 | 004 |

## Sign-off

- **Evaluator:** evaluator-agent
- **Timestamp:** 2026-04-02T10:30:00Z
- **Status:** APPROVED
```

The evaluator produces this simplified contract at Phase 3 step 0 for the first batch. It covers all batches in the plan, so subsequent batches reference the same file rather than generating new contracts.

## Reference

The sprint contract format follows the Sprint Contract Format defined in `evaluation-file-formats.md`. Consult that reference for canonical field definitions and format conventions shared across all evaluation-related file types.
