# BDD Specifications: Executable Verification Eval Harness

Gherkin scenarios for the binary checklist evaluation pipeline and continuous evolution process.

---

## Feature: Binary Checklist Evaluation — Design Mode

```gherkin
Feature: Binary PASS/FAIL Checklist Evaluation for Design Artifacts
  As the superpowers-evaluator in design mode
  I want to apply binary PASS/FAIL checks against design artifacts
  So that evaluation results are concrete, actionable, and not subject to score drift

  Background:
    Given a design folder containing _index.md, bdd-specs.md, architecture.md, best-practices.md
    And the design checklist at docs/retros/checklists/design-v1.md is loaded from the spawn context path

  Scenario: All checklist items pass produces PASS verdict with no rework items
    Given all design artifacts satisfy every checklist item in design-v1.md
    When the evaluator applies the design checklist
    Then every row in the checklist results table shows PASS
    And the verdict is PASS
    And no rework items are produced
    And the report contains no numeric score fields

  Scenario: Vague Given clause triggers SCEN-CONC-01 FAIL with file and line evidence
    Given bdd-specs.md line 23 contains "Given some valid user data"
    And checklist item SCEN-CONC-01 requires all Given clauses to use specific data values
    When the evaluator applies SCEN-CONC-01
    Then SCEN-CONC-01 result is FAIL
    And the evidence field states: "bdd-specs.md:23 — 'some valid user data' is a vague placeholder"
    And the rework item states: "bdd-specs.md line 23: replace 'some valid user data' with concrete field values (e.g., email='user@example.com', password='hunter2')"
    And the verdict is REWORK

  Scenario: Requirement with no mapped scenario triggers REQ-TRACE-01 FAIL
    Given _index.md Requirements section lists "REQ-005: Rate limiting on login attempts"
    And bdd-specs.md contains no scenario mentioning "rate limit" or "REQ-005"
    When the evaluator applies REQ-TRACE-01
    Then REQ-TRACE-01 result is FAIL
    And evidence states: "REQ-005 appears in _index.md but no scenario references it"
    And rework item directs: "add BDD scenario for REQ-005 rate limiting behavior"
    And no other checklist item fails because of this gap

  Scenario: Inner-to-outer layer dependency described in architecture triggers ARCH-01 FAIL
    Given architecture.md line 47 states "domain service imports from ../../infra/database"
    And checklist item ARCH-01 requires no imports described from inner to outer layer
    When the evaluator applies ARCH-01
    Then ARCH-01 result is FAIL
    And evidence cites: "architecture.md:47 — describes domain→infrastructure import"
    And rework item states: "remove or invert the dependency described at architecture.md:47"

  Scenario: Risk section with vague mitigations triggers RISK-02 FAIL
    Given _index.md contains risk entry "Risk: API downtime — Mitigation: monitor closely"
    And checklist item RISK-02 requires each mitigation to be concrete
    When the evaluator applies RISK-02
    Then RISK-02 result is FAIL
    And evidence cites: "_index.md — mitigation 'monitor closely' specifies no action"
    And rework item directs: "replace 'monitor closely' with a concrete mitigation (e.g., circuit breaker with 30s timeout, fallback to cached data)"

  Scenario: Evaluator produces no numeric scores in any field
    Given any design artifact combination is evaluated
    When the evaluator produces the evaluation report
    Then the report contains no "score" column or score values (1-5 range)
    And every assessment is expressed as PASS or FAIL with a reason
    And the verdict line states "PASS" or "REWORK" with a count of FAIL items
```

---

## Feature: Binary Checklist Evaluation — Plan Mode

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
    And evidence states: "task-005-rate-limit-impl.md — 'Verify that rate limiting works correctly' is a description, not a command"
    And rework item directs: "replace with an executable command (e.g., 'pnpm test rate-limit.spec.ts')"

  Scenario: Circular dependency in task graph triggers DEP-01 FAIL
    Given task 003 depends on task 005
    And task 005 depends on task 003
    When the evaluator walks the dependency graph
    Then DEP-01 result is FAIL
    And evidence states: "Cycle detected: task-003 → task-005 → task-003"
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

---

## Feature: Verification Command Execution as Evaluation — Code Mode

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
    And evidence states: "auth/handler.ts:28 — TODO comment present"
    And rework item states: "implement rate limiting at auth/handler.ts:28 or remove the placeholder"

  Scenario: Pivot flag set when same task fails verification in 2 consecutive rounds
    Given task 006 is REWORK in docs/plans/2026-04-01-auth-evals/evaluation-round-1-batch-2.md (CODE-VER-01 FAIL, exit 1)
    And task 006 is REWORK in docs/plans/2026-04-01-auth-evals/evaluation-round-2-batch-2.md (CODE-VER-01 FAIL, exit 1, same error)
    When the evaluator assesses the pivot flag for round 2
    Then pivot is set to true
    And pivot rationale states: "task-006 has failed the same verification command with the same error in 2 consecutive rounds — implementation approach may be architecturally blocked"
    And the recommended action is to review the task specification, not retry the same implementation
```

---

## Feature: Retrospective Failure Pattern Analysis

```gherkin
Feature: Retrospective Analysis of Failure Patterns Across Plans
  As the retrospective skill
  I want to identify recurring checklist failures and never-failing items across plans
  So that the checklist evolves toward items that reliably detect real problems

  Background:
    Given retrospective skill is invoked with 3 plan directories
    And each plan has 3+ evaluation reports (design + plan + at least 1 code batch)

  Scenario: Item failing in 2+ plans generates ADD proposal for missing coverage
    Given SCEN-CONC-01 failed in plan-1 (tasks 002, 005) and plan-2 (task 007)
    And the failing evidence consistently shows vague HTTP error conditions in Given clauses
    And no checklist item currently targets HTTP status code specificity
    When retrospective skill aggregates failure patterns
    Then SCEN-CONC-01 appears in the failure frequency table with count 2 (2 distinct plans)
    And the analyzer proposes: ADD design/SCEN-CONC-03 "Error scenarios must name specific HTTP status codes"
    And the proposal rationale cites: "plan-1 tasks 002, 005 — plan-2 task 007 — all missing concrete status codes"

  Scenario: Item with 0 failures across 10+ reports generates REMOVE candidate proposal
    Given PLAN-GRAN-01 has PASS in 12 evaluation reports across 4 plans
    When retrospective skill aggregates the data
    Then PLAN-GRAN-01 appears in the never-failing items section with count 12
    And the analyzer proposes: REMOVE plan/PLAN-GRAN-01
    And the rationale states: "0 failures across 12 reports in 4 plans; check may not be detecting genuine issues"
    And the proposal notes: "user should confirm this pattern is no longer a real failure mode before removing"

  Scenario: Plateau task reveals gap in existing checklist coverage
    Given task-004 in plan-2 was REWORK in docs/plans/2026-04-01-auth-evals/evaluation-round-1-batch-2.md
    And task-004 was REWORK in docs/plans/2026-04-01-auth-evals/evaluation-round-2-batch-2.md
    And both rework items cite: "verification command is descriptive, not executable"
    And no checklist item currently checks for executable command syntax
    When retrospective skill identifies plateau tasks
    Then task-004 appears in the plateau task analysis with 2 consecutive REWORK rounds
    And root cause is stated: "verification command syntax not enforced by any checklist item"
    And the analyzer proposes: ADD plan/TASK-COMP-04 "Verification commands must begin with an executable binary name, not a description verb"

  Scenario: Retrospective with only 1 plan produces no ADD proposals
    Given only 1 plan directory is provided
    And it contains 3 evaluation reports
    When retrospective skill runs
    Then the retrospective report states: "ADD proposals require failures in 2+ distinct plans; only 1 plan provided"
    And no ADD evolution proposals are generated
    And the report recommends: "provide 2+ plan directories to enable ADD proposal analysis"

  Scenario: Retrospective with fewer than 10 reports per item produces no REMOVE proposals
    Given 2 plan directories are provided
    And the item with the most evaluation reports across both plans has fewer than 10 reports
    When retrospective skill runs
    Then the retrospective report states: "REMOVE proposals require 10+ evaluation reports per item; current maximum is N reports"
    And no REMOVE evolution proposals are generated
    And the report recommends: "run retrospective again after additional plan executions reach the 10-report threshold per item"

  Scenario: Retrospective enforces evolution rate limit per mode
    Given pattern analysis produces 5 valid ADD proposals for design mode
    When the retrospective report is finalized
    Then only 3 proposals are surfaced for design mode (rate limit: EVO-6)
    And the report notes: "2 proposals deferred — rerun retrospective after applying current approvals"
    And the deferred proposals are listed with their evidence for future reference
```

---

## Feature: Evolution Proposal Review and Checklist Update

```gherkin
Feature: User-Gated Checklist Evolution with Version Tracking
  As the retrospective skill
  I want to present each evolution proposal for explicit user approval
  So that checklist changes are deliberately considered and auditable

  Background:
    Given retrospective skill has produced 2 evolution proposals
    And the current design checklist is docs/retros/checklists/design-v1.md

  Scenario: User approves ADD proposal — new version file created and event logged
    Given proposal: ADD design/SCEN-CONC-03 "Error scenarios must name specific HTTP status codes"
    When the user approves the proposal
    Then docs/retros/checklists/design-v2.md is created with SCEN-CONC-03 appended
    And docs/retros/checklists/design-v1.md is preserved unchanged
    And an event is appended to evolution-log.jsonl:
      timestamp, event:"item_added", mode:"design", item_id:"SCEN-CONC-03", rationale, driving_plans
    And the retrospective report records "SCEN-CONC-03: APPROVED — design-v2.md created"

  Scenario: User rejects REMOVE proposal — checklist unchanged, rejection recorded
    Given proposal: REMOVE plan/PLAN-GRAN-01 "0 failures across 12 reports"
    When the user rejects the proposal
    Then plan-v1.md is unchanged
    And no evolution event is logged for PLAN-GRAN-01
    And the retrospective report records "PLAN-GRAN-01: REJECTED — user declined removal"

  Scenario: Pre-edit snapshot written to report before any checklist file is modified
    Given any evolution proposal is about to be applied
    When the retrospective skill prepares to write the checklist update
    Then the current full content of the target checklist is written to the retrospective report under "pre-edit snapshot"
    And the snapshot precedes any file edit in the execution sequence
    And the retrospective report notes: "rollback: copy pre-edit snapshot content to design-v1.md"

  Scenario: Version counter increments once per retrospective run regardless of approval count
    Given 3 proposals are approved in a single retrospective run for design mode
    When all 3 are applied
    Then design-v2.md is created containing all 3 changes (not design-v4.md)
    And the evolution-log.jsonl records 3 item_added events each referencing design-v2.md
    And design-v1.md is preserved for audit purposes

  Scenario: Second retrospective run with prior evolution history proposes against new version
    Given design-v2.md exists with SCEN-CONC-03 added
    And a new retrospective run identifies SCEN-CONC-03 as a failure source in 2 more plans
    When retrospective skill runs
    Then the never-failing candidate analysis uses design-v2.md as the current checklist
    And SCEN-CONC-03 is not proposed for removal (it has failed, not passed in all reports)
    And any new proposals reference design-v2.md as the base for the next version
```

---

## Scenario Count Summary

| Feature | Scenarios |
|---------|-----------|
| Binary Checklist — Design Mode | 6 |
| Binary Checklist — Plan Mode | 5 |
| Command Exit Code — Code Mode | 5 |
| Retrospective Failure Pattern Analysis | 6 |
| Evolution Proposal Review | 5 |
| **Total** | **27** |

All scenarios meet:
- Single responsibility: each scenario tests exactly one rule or behavior
- Verifiable Then clauses: no vague assertions ("should be correct", "should work well")
- Business language: no implementation terms (no "JSON key", "function call", "regex")
- Independence: no shared mutable state between scenarios; each has explicit Given setup
