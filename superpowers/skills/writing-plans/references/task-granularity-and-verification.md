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

## File Structure (MANDATORY)

**ONE TASK PER FILE**

- Each task must be in its own `.md` file
- File naming pattern: `task-<NNN>-<short-description>.md`
- Example: `task-001-implement-login-test.md`, `task-002-implement-login-logic.md`
- The `_index.md` file contains overview and references to all task files

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

> **Task 01: [TEST] 'Feature behavior' (RED)**
>
> **BDD Scenario**:
> ```gherkin
> Scenario: [concise scenario title]
>   Given [context or precondition]
>   When [action or event occurs]
>   Then [expected outcome]
>   And [additional conditions or outcomes]
> ```
>
> **Steps:**
> 1. Create `tests/path/to/test_file.ext`.
> 2. Implement test case mapping to Given/When/Then above.
> 3. **Verify**: Run `<test-command>` -> MUST FAIL (Red).
>
> **Task 02: [IMPL] 'Feature behavior' (GREEN)**
>
> **BDD Scenario**:
> ```gherkin
> Scenario: [concise scenario title]
>   Given [context or precondition]
>   When [action or event occurs]
>   Then [expected outcome]
>   And [additional conditions or outcomes]
> ```
>
> **Steps:**
> 1. Update `src/path/to/file.ext`.
> 2. Implement the functionality to satisfy the scenario above.
> 3. **Verify**: Run `<test-command>` -> MUST PASS (Green).

## Execution Handoff

After saving the plan, offer execution choice via Agent Teams:

**"Plan complete and saved to `docs/plans/<filename>.md`. Execution options:**

**1. Orchestrated Execution (Recommended)** - Use Skill tool load `superpowers:executing-plans` skill to manage execution (it will spawn an Agent Team for parallel work).

**2. Direct Agent Team** - Use Skill tool load `superpowers:agent-team-driven-development` skill to spawn a team immediately (Architecture/Implementation/Review).

**3. Manual / Serial** - Execute tasks one by one in this session (slower)."

