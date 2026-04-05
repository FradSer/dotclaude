# Task 006: Update evaluator plan mode to binary checklist

**depends-on**: task-003

## Description

Replace the rubric-based scoring in the evaluator's plan mode with binary checklist evaluation. Plan mode must read a plan checklist file (path from spawn context), execute each check method (dependency graph walk, field presence scan, command syntax check), and produce PASS/FAIL results. The existing Step 4 (Structural Integrity) checks are absorbed into the checklist items -- no separate structural sweep outside the checklist.

## Execution Context

**Task Number**: 006 of 013
**Phase**: Core Features
**Prerequisites**: plan-v1.md exists (task-003)

## BDD Scenario

```gherkin
Feature: Binary PASS/FAIL Checklist Evaluation for Plan Artifacts
  As the superpowers-evaluator in plan mode
  I want to verify plan structural integrity using binary checks
  So that plan gaps are reported with precise file and task references

  Background:
    Given a plan folder with _index.md and all task files
    And the plan checklist at docs/retros/checklists/plan-v1.md is loaded

  Scenario: BDD scenario with no mapped task triggers PLAN-COV-01 FAIL
    Given the design has scenario "Given user is unauthenticated, When accessing /profile, Then redirect to /login"
    And no task in the plan references this scenario
    When the evaluator applies PLAN-COV-01
    Then PLAN-COV-01 result is FAIL
    And evidence states: "Scenario 'unauthenticated profile access redirect' has no mapped task"
    And rework item directs: "add a task covering the unauthenticated redirect scenario"

  Scenario: Task with descriptive verification command triggers TASK-COMP-03 FAIL
    Given task-005-rate-limit-impl.md has verification: "Verify that rate limiting works correctly"
    And checklist item TASK-COMP-03 requires verification commands to be executable
    When the evaluator applies TASK-COMP-03 to task-005
    Then TASK-COMP-03 result is FAIL
    And evidence states: "task-005-rate-limit-impl.md -- 'Verify that rate limiting works correctly' is a description, not a command"
    And rework item directs: "replace with an executable command (e.g., 'pnpm test rate-limit.spec.ts')"

  Scenario: Circular dependency in task graph triggers DEP-01 FAIL
    Given task 003 depends on task 005
    And task 005 depends on task 003
    When the evaluator walks the dependency graph
    Then DEP-01 result is FAIL
    And evidence states: "Cycle detected: task-003 -> task-005 -> task-003"
    And rework item directs: "break the cycle by removing or reversing one dependency edge"

  Scenario: Impl task without a test task triggers TEST-01 FAIL
    Given task-007-payment-impl.md exists
    And no task with prefix "007" and type "test" exists in the plan
    And no explicit absence justification is present in task-007
    When the evaluator applies TEST-01
    Then TEST-01 result is FAIL
    And evidence states: "task-007-payment-impl.md has no corresponding test task (no task-007-*-test.md)"
    And rework item directs: "add test task for payment implementation or add justification for absence"

  Scenario: Structurally complete plan with all items passing produces PASS verdict
    Given all tasks have acceptance criteria and executable verification commands
    And all BDD scenarios are mapped to at least one task
    And no circular dependencies exist
    And every impl task has a corresponding test task
    When the evaluator applies the plan checklist
    Then all items PASS
    And the verdict is PASS
```

**Spec Source**: `../2026-04-03-eval-harness-design/bdd-specs.md` (Feature: Binary Checklist Evaluation -- Plan Mode)

## Files to Modify/Create

- Modify: `superpowers/agents/superpowers-evaluator.md` (Plan Mode section, approximately lines 68-115)

## Steps

### Step 1: Replace plan mode steps

Replace Steps 2-4 (Read Rubrics, Score Dimensions, Structural Integrity) with:

1. Read _index.md and all task files (unchanged)
2. Read plan checklist from path in spawn context
3. For each checklist item: execute the check method (dependency graph walk, task field presence, command syntax scan)
4. Record PASS/FAIL with evidence per item
5. Note: DEP-01 and DEP-02 perform cycle detection and ID resolution; PLAN-COV-01 detects unmapped scenarios
6. Produce rework items from all FAIL results
7. Verdict: PASS if all items PASS; REWORK if any item FAIL

### Step 2: Remove separate structural integrity section

The current Step 4 (Structural Integrity) checks are now covered by checklist items DEP-01, DEP-02, PLAN-COV-01, and TEST-01. Remove the separate structural sweep section.

### Step 3: Update plan mode output

Replace dimension scores table with Checklist Results table format.

### Step 4: Verify changes

Confirm plan mode uses checklist terminology with no scoring language.

## Verification Commands

```bash
# Plan mode section contains checklist references
grep -c "checklist" superpowers/agents/superpowers-evaluator.md | xargs test 2 -le && echo "PASS: checklist referenced"

# No separate structural integrity section (absorbed into checklist)
! grep -i "structural integrity" superpowers/agents/superpowers-evaluator.md && echo "PASS: no separate structural section"

# Plugin validation
python3 plugin-optimizer/scripts/validate-plugin.py superpowers/ --check=frontmatter
```

## Success Criteria

- Plan mode steps replaced with checklist execution process
- Structural integrity checks (cycles, orphans, coverage) absorbed into checklist items
- No separate Step 4 structural sweep
- Output uses Checklist Results table format
- No numeric scores or dimension tables
