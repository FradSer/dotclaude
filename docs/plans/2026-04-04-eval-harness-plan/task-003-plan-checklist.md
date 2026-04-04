# Task 003: Create initial plan checklist

**depends-on**: task-001

## Description

Create `docs/retros/checklists/plan-v1.md` containing binary PASS/FAIL checklist items for evaluating plan artifacts. Items must target structural properties of plans that can be verified mechanically (dependency graph analysis, field presence, command syntax).

## Execution Context

**Task Number**: 003 of 015
**Phase**: Foundation
**Prerequisites**: docs/retros/checklists/ directory exists (task-001)

## BDD Scenario

```gherkin
Feature: Binary PASS/FAIL Checklist Evaluation for Plan Artifacts

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
    And evidence states: "task-007-payment-impl.md has no corresponding test task"
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

- Create: `docs/retros/checklists/plan-v1.md`

## Steps

### Step 1: Define checklist items

Create `plan-v1.md` with these minimum items:

- **PLAN-COV-01**: Every BDD scenario from the design has at least one mapped task
  - Check: cross-reference design bdd-specs.md scenarios with task file BDD sections
  - Evidence: scenario title + absence note
- **TASK-COMP-03**: All verification commands are executable (begin with a binary name, not a description verb)
  - Check: scan verification command sections for non-executable patterns
  - Evidence: task file -- quoted command text
- **DEP-01**: No circular dependencies in the task dependency graph
  - Check: walk the dependency graph from depends-on fields; detect cycles
  - Evidence: cycle path (task-A -> task-B -> task-A)
- **DEP-02**: All depends-on references resolve to existing task IDs
  - Check: extract all depends-on IDs and verify each matches a task file
  - Evidence: task file -- unresolved ID
- **TEST-01**: Every impl task has a corresponding test task (same NNN prefix) or explicit absence justification
  - Check: match task filenames by NNN prefix; check for test+impl pairs
  - Evidence: task file -- missing test counterpart

### Step 2: Add file header and format

Include version, mode, creation date. Each item has ID, description, check method, evidence format.

### Step 3: Verify checklist content

Confirm all items exist with executable check annotations.

## Verification Commands

```bash
# File exists
test -f docs/retros/checklists/plan-v1.md && echo "PASS: plan-v1.md exists"

# Contains required item IDs
grep -c "PLAN-COV-01" docs/retros/checklists/plan-v1.md && echo "PASS: PLAN-COV-01 present"
grep -c "TASK-COMP-03" docs/retros/checklists/plan-v1.md && echo "PASS: TASK-COMP-03 present"
grep -c "DEP-01" docs/retros/checklists/plan-v1.md && echo "PASS: DEP-01 present"
grep -c "TEST-01" docs/retros/checklists/plan-v1.md && echo "PASS: TEST-01 present"

# No scoring language
! grep -qi "score\|1-5\|rubric" docs/retros/checklists/plan-v1.md && echo "PASS: no scoring language"
```

## Success Criteria

- `plan-v1.md` exists with all 5+ checklist items
- Each item has ID, description, check method annotation, and evidence format
- Check methods are mechanically executable (graph walks, pattern scans, cross-references)
- No numeric scoring or rubric language present
