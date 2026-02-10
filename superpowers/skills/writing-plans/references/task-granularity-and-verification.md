# Task Granularity & Verification

## BDD Granularity

**Preferred: 1 Scenario = 2 Tasks (Red + Green).**

To strictly enforce BDD, split work into:
1. **Task A (Red)**: Create failing test for Scenario X.
2. **Task B (Green)**: Implement Scenario X to pass test.

**Alternative (Single Task)**:
If using a single task, the steps MUST be strictly ordered:
1. Create Test -> 2. Verify Fail (Red) -> 3. Implement -> 4. Verify Pass (Green).

Do not group multiple scenarios into one task unless they are trivial variations.

## Verification Strategy

**Verification is strictly tied to the BDD Scenario.**

1. **Red (Failing Test):**
   - The task must start by creating/enabling a test case that maps 1:1 to the BDD scenario.
   - It must fail with a meaningful error (e.g., `AssertionError: Expected X, got None`, not `ImportError`).

2. **Green (Passing Test):**
   - Implement the minimal code to satisfy the scenario.
   - Run the specific test case again.
   - It must pass.

3. **Refactor:**
   - Clean up code while keeping the test passing.
   - Ensure no regressions.

## Task Output

Every task in the plan must result in:
1. A committed BDD test case (in `tests/`).
2. Implementation code (in `src/`).
3. A green test run.

## Example Task Sequence (Red -> Green)

> **Task 01: [TEST] 'User logs in successfully' (RED)**
>
> **Spec:** `bdd-specs.md` -> Scenario: "User logs in successfully"
>
> **Steps:**
> 1. Create `tests/features/login_test.py`.
> 2. Implement test case mapping to Given/When/Then.
> 3. **Verify**: Run `npm test tests/features/login_test.py` -> MUST FAIL (Red).
>
> **Task 02: [IMPL] 'User logs in successfully' (GREEN)**
>
> **Spec:** `bdd-specs.md` -> Scenario: "User logs in successfully"
>
> **Steps:**
> 1. Update `src/auth_service.ts`.
> 2. Implement `login` method to validate credentials and return token.
> 3. **Verify**: Run `npm test tests/features/login_test.py` -> MUST PASS (Green).

## Execution Handoff

After saving the plan, offer execution choice via Agent Teams:

**"Plan complete and saved to `docs/plans/<filename>.md`. Execution options:**

**1. Orchestrated Execution (Recommended)** - Use Skill tool load `superpowers:executing-plans` skill to manage execution (it will spawn an Agent Team for parallel work).

**2. Direct Agent Team** - Use Skill tool load `superpowers:agent-team-driven-development` skill to spawn a team immediately (Architecture/Implementation/Review).

**3. Manual / Serial** - Execute tasks one by one in this session (slower)."

