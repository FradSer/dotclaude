# Task 007: Update evaluator code mode to binary checklist

**depends-on**: task-004

## Description

Update the evaluator's code mode to integrate binary checklist evaluation alongside verification command execution. Verification commands remain the primary verdict basis (exit code 0 = PASS). The code checklist adds prohibited pattern checks (TODO, stubs) applied after verification. Remove Step 4 rubric scoring and replace with checklist execution. Update pivot flag logic to use binary results (consecutive FAIL rounds, not score-based).

## Execution Context

**Task Number**: 007 of 015
**Phase**: Core Features
**Prerequisites**: code-v1.md exists (task-004)

## BDD Scenario

```gherkin
Feature: Command Exit Code as the Sole Verdict Basis in Code Mode
  As the superpowers-evaluator in code mode
  I want to determine task verdict from verification command exit codes only
  So that code quality judgment is objective and does not depend on LLM assessment

  Background:
    Given docs/plans/2026-04-01-auth-evals/sprint-contract-batch-2.md lists tasks 003, 004, 005
    And the code checklist at docs/retros/checklists/code-v1.md is loaded

  Scenario: All verification commands pass and no prohibited patterns produce PASS verdict
    Given task 003 verification commands: "pnpm test auth.spec.ts" and "tsc --noEmit"
    And both commands exit with code 0
    And auth/handler.ts contains no TODO, FIXME, or stub patterns
    When the evaluator runs verification for task 003
    Then CODE-VER-01 result is PASS
    And the evidence block records: command, exit code 0, last 10 lines of output
    And task 003 verdict is PASS

  Scenario: Non-zero exit code produces REWORK with command output as evidence
    Given task 004 verification command: "pnpm test user.spec.ts"
    And "pnpm test user.spec.ts" exits with code 1
    And the output contains "AssertionError: expected 403 but got 200 at auth.test.ts:45"
    When the evaluator runs verification for task 004
    Then CODE-VER-01 result is FAIL
    And the rework item states: "'pnpm test user.spec.ts' exited with code 1"
    And the rework item includes the failing test output (last 30 lines)
    And the rework item does not contain subjective quality assessments

  Scenario: Evaluator re-runs commands independently when generator claims success
    Given the generator's completion message states "all tests pass"
    And the evaluator runs "pnpm test" independently
    And "pnpm test" exits with code 1 (contradicting the generator report)
    When the evaluator records the result
    Then the verdict is REWORK based on the independent run result
    And the rework item notes: "generator claimed tests pass; independent run produced exit code 1"

  Scenario: TODO placeholder in produced file triggers CODE-QUAL-01 FAIL
    Given task 005 produced auth/handler.ts
    And auth/handler.ts line 28 contains "// TODO: implement rate limiting"
    And checklist item CODE-QUAL-01 prohibits TODO comments in produced files
    When the evaluator applies CODE-QUAL-01 to task 005 produced files
    Then CODE-QUAL-01 result is FAIL
    And evidence states: "auth/handler.ts:28 -- TODO comment present"
    And rework item states: "implement rate limiting at auth/handler.ts:28 or remove the placeholder"

  Scenario: Pivot flag set when same task fails verification in 2 consecutive rounds
    Given task 006 is REWORK in docs/plans/2026-04-01-auth-evals/evaluation-round-1-batch-2.md (CODE-VER-01 FAIL, exit 1)
    And task 006 is REWORK in docs/plans/2026-04-01-auth-evals/evaluation-round-2-batch-2.md (CODE-VER-01 FAIL, exit 1, same error)
    When the evaluator assesses the pivot flag for round 2
    Then pivot is set to true
    And pivot rationale states: "task-006 has failed the same verification command with the same error in 2 consecutive rounds -- implementation approach may be architecturally blocked"
    And the recommended action is to review the task specification, not retry the same implementation
```

**Spec Source**: `../2026-04-03-eval-harness-design/bdd-specs.md` (Feature: Command Exit Code -- Code Mode)

## Files to Modify/Create

- Modify: `superpowers/agents/superpowers-evaluator.md` (Code Mode section, approximately lines 117-204)

## Steps

### Step 1: Restructure code mode steps

Replace Steps 3-4 (Run Verification + Score Against Rubrics) with:

1. Read sprint contract (unchanged)
2. Read produced artifacts (unchanged)
3. Run verification commands per task -- exit codes determine task PASS/FAIL
4. Read code checklist from path in spawn context
5. Apply prohibited pattern checks from code checklist against produced files
6. Produce rework items from failed verifications + FAIL checklist items
7. Assess pivot flag (updated logic: consecutive FAIL rounds with same error)
8. Write evaluation report using updated format (no scores table)

### Step 2: Update pivot flag logic with trajectory analysis

Change pivot trigger from score-based (dimensions <= 2 across rounds) to binary-based with transcript analysis:
- Same task has REWORK verdict (same CODE-VER-01 FAIL, same error) in 2 consecutive rounds
- Pivot rationale must reference the specific error pattern
- Recommended action: review task spec, not retry implementation

Additionally, detect "thrashing" patterns from generator trajectory:
- If the generator oscillated between approaches (>3 distinct implementation attempts within a single round), flag as a pivot candidate even before 2 consecutive failures
- Record trajectory metrics per task: tool call count, distinct file edit count, revert-and-retry count
- If trajectory metrics exceed thresholds (e.g., >20 tool calls for a task estimated at <10), include in pivot rationale as supporting evidence

### Step 3: Remove scoring dimensions

Remove the 5-dimension scoring table, type-aware weighting references, and configurable thresholds from code mode.

### Step 4: Enforce independent verification

Ensure the code mode explicitly states that commands must be re-run independently, and that generator claims are never trusted. Note discrepancy explicitly in rework items when detected.

### Step 5: Verify changes

Confirm code mode uses command exit codes + checklist checks, no dimension scoring.

## Verification Commands

```bash
# Code mode contains independent verification language
grep -c "independent" superpowers/agents/superpowers-evaluator.md | xargs test 0 -lt && echo "PASS: independent verification"

# No dimension scoring in code mode
! grep -i "correctness.*completeness.*code quality" superpowers/agents/superpowers-evaluator.md && echo "PASS: no dimension scoring"

# Pivot flag still present
grep -c "pivot" superpowers/agents/superpowers-evaluator.md | xargs test 0 -lt && echo "PASS: pivot flag present"

# Plugin validation
python3 plugin-optimizer/scripts/validate-plugin.py superpowers/ --check=frontmatter
```

## Success Criteria

- Verification commands are primary verdict basis (exit code 0 = PASS)
- Code checklist adds prohibited pattern checks (CODE-QUAL-01)
- Independent re-run explicitly required (generator claims not trusted)
- Pivot flag uses consecutive FAIL rounds (not score thresholds)
- Pivot flag enhanced with trajectory thrashing detection (oscillation, excessive tool calls)
- Trajectory metrics recorded per task: tool call count, file edit count, revert-and-retry count
- No dimension scoring, rubric references, or type-aware weighting
- Rework items reference command output, not subjective assessments
