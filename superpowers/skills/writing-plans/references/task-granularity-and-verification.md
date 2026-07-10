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
- File naming pattern: `task-<NNN>-<feature>-<type>.md`
- Example: `task-001-setup.md`, `task-002-login-test.md`, `task-002-login-impl.md`
- **Test and implementation tasks for the same feature share the same NN prefix**
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

After saving the plan, transition to execution:

**"Plan complete and saved to `docs/plans/<filename>.md`. Load `superpowers:executing-plans` skill using the Skill tool — it orchestrates per-batch sub-agent coordinators through the full Phase 1-6 pipeline."**


## Dependency Rules (depends-on)

`**depends-on**` lists only TRUE technical prerequisites — tasks whose output is required before this task can start:

- A test task (Red) for feature X has no dependency on test tasks for other features
- An implementation task (Green) depends only on its paired test task (Red), not on other features' implementations
- Tasks that touch different files and test different scenarios are independent by default

**PROHIBITED**: Do not chain tasks sequentially just to impose execution order — use `depends-on` only when there is a real technical reason (e.g., "implement auth middleware" must precede "implement protected route test").
