# Evaluation Rubrics

Graded 1-5 scoring rubrics for the evaluator agent. Apply these rubrics when scoring tasks in evaluation reports. Each dimension has concrete score-level descriptions and type-aware weighting rules.

## Scoring Dimensions

### 1. Correctness

Does the code do what the spec says?

| Score | Description | Example Indicators |
|-------|-------------|--------------------|
| 5 | All logic correct, edge cases handled, matches spec exactly | Every branch produces the expected output; boundary conditions explicitly handled; no off-by-one errors |
| 4 | Logic correct for all specified cases, one minor edge case slightly imprecise | Primary and secondary paths work; a rare boundary condition returns a slightly suboptimal (but not wrong) result |
| 3 | Logic correct for primary path but misses an edge case described in a BDD scenario | Happy path works; one `Then` clause in a secondary scenario produces incorrect output |
| 2 | Primary path mostly works but has a logic error affecting observable behavior | Core function returns correct type but wrong value for a common input variant |
| 1 | Fundamental logic error, does not produce correct output for the primary case | Function always returns a hardcoded value, throws an unhandled exception on normal input, or inverts a boolean condition |

### 2. Completeness

Are all requirements addressed?

| Score | Description | Example Indicators |
|-------|-------------|--------------------|
| 5 | Every requirement in the task file and referenced BDD scenarios is fully implemented | All acceptance criteria checked off; no `Given`/`When`/`Then` clause left unaddressed |
| 4 | All requirements addressed, one minor detail partially implemented | All scenarios covered; one scenario's `And` clause implemented with a simplified approach that still passes |
| 3 | Most requirements addressed, one full scenario or acceptance criterion missing | 4 out of 5 acceptance criteria implemented; the missing one is non-trivial |
| 2 | Multiple requirements missing or only partially implemented | Only the happy-path scenario implemented; error-handling and validation scenarios absent |
| 1 | Majority of requirements not addressed, implementation is skeletal | Only type signatures or scaffolding present; no meaningful business logic |

### 3. Code Quality

Is the code clean, maintainable, and well-structured?

| Score | Description | Example Indicators |
|-------|-------------|--------------------|
| 5 | Clean, idiomatic code; clear naming; single-responsibility functions; no duplication | Follows project conventions; functions under 30 lines; meaningful variable names; consistent error handling patterns |
| 4 | Well-structured with minor style inconsistencies | One function slightly too long; a variable name could be clearer; otherwise follows project patterns |
| 3 | Functional but with noticeable structural issues | Some code duplication across two functions; inconsistent naming conventions; a function doing two distinct things |
| 2 | Messy structure that hinders understanding | Deeply nested conditionals; copy-pasted blocks with slight variations; magic numbers without constants; mixed abstraction levels |
| 1 | Unmaintainable code requiring a rewrite | Single 200-line function; no separation of concerns; variables named `x`, `temp`, `data2`; no consistent pattern |

### 4. Test Coverage

Are tests thorough and meaningful?

| Score | Description | Example Indicators |
|-------|-------------|--------------------|
| 5 | All paths tested with meaningful assertions; edge cases and error conditions covered | Tests for happy path, error path, boundary values, and invalid input; assertions verify specific values, not just truthiness |
| 4 | Primary and secondary paths tested; one edge case test missing or using a weak assertion | Good coverage of main flows; a boundary test asserts on return type instead of exact value |
| 3 | Primary path tested, secondary paths partially covered | Happy-path test is solid; error-path test exists but only checks that an exception is thrown, not the message or type |
| 2 | Minimal test coverage, only happy path | One test for the success case; no error-handling, boundary, or integration tests |
| 1 | Tests are stubs or meaningless | Tests contain `assert True`, `pass`, or only verify that the function is callable without checking output |

### 5. Spec Compliance

Does the implementation match BDD scenarios exactly?

| Score | Description | Example Indicators |
|-------|-------------|--------------------|
| 5 | Every `Given`/`When`/`Then` clause maps to implementation and test code with exact fidelity | Step definitions match scenario wording; test names reference scenario titles; implementation structure mirrors spec flow |
| 4 | All scenarios matched, minor deviation in naming or structure that does not affect behavior | A test covers the right behavior but uses a slightly different name than the scenario title |
| 3 | Most scenarios matched, one scenario implemented with a behavioral deviation | Scenario says "returns 404" but implementation returns 400; functionally close but not spec-exact |
| 2 | Multiple deviations from spec; implementation interprets requirements loosely | Function signatures differ from spec; response formats do not match; error codes substituted |
| 1 | Implementation does not follow the spec; built from assumptions instead of scenarios | No correlation between BDD scenarios and actual code; scenarios ignored entirely |

## Type-Aware Weighting

Not all dimensions carry equal weight for every task type. Use this table to determine which dimensions apply and their relative priority when making verdict decisions.

| Dimension | test | impl | setup | config | refactor |
|-----------|------|------|-------|--------|----------|
| Correctness | Applies | **Highest priority** | Applies | Applies | Must remain unchanged |
| Completeness | **High priority** | Applies | Applies | Applies | Applies |
| Code Quality | Secondary | **High priority** | N/A | N/A | **Highest priority** |
| Test Coverage | **Highest priority** | Secondary | N/A | N/A | N/A |
| Spec Compliance | **Highest priority** | Applies | Applies | Applies | Applies |

**Reading the table:**
- **Highest priority**: This dimension is the primary success criterion for this task type. A score below 4 here is weighted more heavily toward a REWORK verdict.
- **High priority**: Important but not the single deciding factor. A score of 3 is tolerable if other dimensions are strong.
- **Applies**: Dimension is scored normally. Follows standard threshold rules.
- **Secondary**: Dimension is scored but given less weight in verdict decisions. A score of 3 alone does not trigger REWORK.
- **N/A**: Dimension does not apply. Leave blank or mark `N/A` in the evaluation report. Do not factor into the verdict.
- **Must remain unchanged**: For refactor tasks, verify that external behavior is identical before and after. Score by running the existing test suite and confirming all tests pass without modification.

## Configurable Thresholds

Default thresholds determine the verdict for each task. These apply when no plan-level overrides are specified.

### Default Thresholds

| Verdict | Rule |
|---------|------|
| **PASS** | All applicable dimensions >= 4 |
| **REWORK** | Any applicable dimension scores 2 or 3 |
| **FAIL** | Any applicable dimension == 1 |

### Evaluation Order

1. Check for FAIL first: if any dimension == 1, verdict is FAIL regardless of other scores.
2. Check for REWORK: if any applicable dimension is 2 or 3, verdict is REWORK.
3. Otherwise, verdict is PASS.

### Plan-Level Overrides

Override default thresholds by adding a `thresholds` key to the plan `_index.md` metadata:

```yaml
evaluation:
  thresholds:
    pass: 4        # Minimum score for PASS (default: 4)
    rework-floor: 2  # Scores at or above this trigger REWORK (default: 2)
    fail-ceiling: 1   # Scores at or below this trigger FAIL (default: 1)
```

When overriding, maintain the invariant: `fail-ceiling < rework-floor <= pass`. The evaluator rejects invalid threshold configurations and falls back to defaults.

## Strategic Pivot Flag

The pivot flag signals that the current execution approach may be fundamentally misaligned. It is advisory -- the orchestrator decides whether to act on it.

### Trigger Condition

Raise the pivot flag when **both** of the following are true:
1. Two or more dimensions score 2 or below on the same task
2. This pattern repeats across 2 consecutive evaluation rounds (same task failing twice, or different tasks exhibiting the same dimensional weakness)

### Pivot Recommendation Contents

When raising the pivot flag, include all three of the following in the evaluation report:

| Section | Content |
|---------|---------|
| **Root cause** | Identify the underlying reason for repeated low scores (e.g., "spec ambiguity in authentication flow", "wrong architectural pattern chosen in task 002") |
| **Suggested modifications** | Concrete changes to the plan or approach (e.g., "rewrite task 006 to use repository pattern instead of direct DB access", "add a new clarification task before task 008") |
| **Tasks to cancel or re-scope** | List specific task IDs that should be canceled, merged, split, or re-scoped, with brief rationale for each |

### Pivot Flag Format in Report

```markdown
## Pivot Flag

- **Pivot:** true
- **Trigger:** Tasks 003 and 005 scored <=2 on Correctness and Completeness across rounds 1 and 2
- **Root cause:** BDD scenarios for the payment flow reference an API contract that was never finalized
- **Suggested modifications:**
  - Add a new task to define and validate the payment API contract before implementation
  - Re-scope task 005 to depend on the new contract task
- **Tasks to cancel or re-scope:**
  - Task 007 (payment integration test): cancel until contract is stable
  - Task 008 (payment error handling): re-scope to cover only the finalized error codes
```

## Calibration Examples

### Example 1: Implementation Task Scoring Well

**Task:** Implement user registration endpoint (type: `impl`)

| Dimension | Score | Rationale |
|-----------|-------|-----------|
| Correctness | 5 | All input validation, hashing, and DB insertion logic produces correct results; tested against BDD scenarios |
| Completeness | 4 | All 6 acceptance criteria met; email uniqueness check uses a slightly simplified query but still correct |
| Code Quality | 5 | Clean separation between controller, service, and repository layers; follows existing project patterns |
| Test Coverage | N/A | This is an impl task; test coverage is secondary and scored on the paired test task |
| Spec Compliance | 5 | Every `Given`/`When`/`Then` clause from the registration scenarios maps directly to implementation |

**Verdict:** PASS (all applicable dimensions >= 4)

### Example 2: Test Task with Rework Needed

**Task:** Write tests for password reset flow (type: `test`)

| Dimension | Score | Rationale |
|-----------|-------|-----------|
| Correctness | 4 | Test assertions are accurate for the scenarios they cover |
| Completeness | 2 | Only 2 of 5 BDD scenarios have corresponding tests; missing expired-token, rate-limit, and invalid-email scenarios |
| Code Quality | 4 | Test structure is clean; uses proper setup/teardown; consistent naming |
| Test Coverage | 3 | Happy path and one error path covered; three error paths from the spec are missing |
| Spec Compliance | 2 | Test file references only 2 of 5 scenarios; remaining scenarios have no test representation |

**Verdict:** REWORK (Completeness = 2, Test Coverage = 3, Spec Compliance = 2)

**Rework items:**
1. Add tests for the expired-token scenario (`Scenario: User attempts reset with expired token`)
2. Add tests for the rate-limit scenario (`Scenario: User exceeds reset request limit`)
3. Add test for invalid-email scenario (`Scenario: User requests reset for non-existent email`)

### Example 3: Config Task Showing N/A Handling

**Task:** Configure CI pipeline for staging environment (type: `config`)

| Dimension | Score | Rationale |
|-----------|-------|-----------|
| Correctness | 5 | Pipeline triggers on the correct branch, uses the right environment variables, deploys to staging |
| Completeness | 5 | All config requirements met: branch filter, secrets injection, artifact caching, notification webhook |
| Code Quality | N/A | Config tasks are not scored on code quality |
| Test Coverage | N/A | Config tasks are not scored on test coverage |
| Spec Compliance | 4 | Pipeline matches the spec; notification webhook uses a slightly different event name (`deploy_success` vs spec's `deployment_success`) but triggers correctly |

**Verdict:** PASS (all applicable dimensions >= 4; N/A dimensions excluded from evaluation)
