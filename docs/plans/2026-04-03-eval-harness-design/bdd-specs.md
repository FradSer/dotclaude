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

---

## Feature: Checklist Evolution Candidate Signal

```gherkin
Feature: Plan Completion Signals for Checklist Evolution
  As the executing-plans skill on plan completion
  I want to identify persistent failure patterns and checklist gaps
  So that manual checklist review has explicit, data-driven entry points

  Scenario: Persistent FAIL across 3+ batches flagged as evolution candidate
    Given evaluation reports show SCEN-CONC-01 FAIL in batches 1, 2, and 3
    And SCEN-CONC-01 resolved in batch 4 after rework
    When the plan completes and executing-plans produces the plan completion summary
    Then the summary includes a "Checklist Evolution Candidates" section
    And SCEN-CONC-01 is listed with "FAILed in batches: 1, 2, 3" and "Resolved: Yes (round 4)"
    And a root cause hypothesis is provided
    And the section recommends reviewing the relevant checklist file

  Scenario: Batch requiring 3+ evaluation rounds to reach all-PASS flagged as potential gap
    Given batch 3 took 3 evaluation rounds: round 1 had 2 FAIL items, round 2 had 1 different FAIL item, round 3 shows all items PASS
    And each round's failures were on different checklist items
    When the plan completes and executing-plans produces the plan completion summary
    Then the summary includes a "Potential Checklist Gaps" section
    And batch 3 is listed with "3 evaluation rounds, all items PASS on final round"
    And a note states: "repeated failures on different items suggest a root cause the checklist does not directly target"

  Scenario: Clean plan with no evolution candidates produces no evolution section
    Given all batches completed with all checklist items PASS on first evaluation
    And no batch required more than 1 rework round
    When the plan completes
    Then the plan completion summary does not include a "Checklist Evolution Candidates" section
    And the plan completion summary does not include a "Potential Checklist Gaps" section
```

---

## Feature: Check Type Awareness in Evaluation

```gherkin
Feature: Evaluator Handles Computational and Inferential Checks Differently
  As the superpowers-evaluator
  I want to read check type annotations and anchor inferential judgments explicitly
  So that observer variability is visible and minimized

  Scenario: Computational check produces deterministic result with no borderline note
    Given checklist item CODE-QUAL-01 is annotated "# Type: computational"
    And auth/handler.ts line 28 contains "// TODO: implement rate limiting"
    When the evaluator applies CODE-QUAL-01
    Then the result is FAIL with evidence "auth/handler.ts:28 -- TODO comment present"
    And no borderline note is included

  Scenario: Inferential check with clear match produces PASS with no borderline note
    Given checklist item REQ-TRACE-01 is annotated "# Type: inferential"
    And _index.md lists "REQ-005: Rate limiting"
    And bdd-specs.md contains a scenario with "REQ-005" in its Given clause
    When the evaluator applies REQ-TRACE-01
    Then the result is PASS
    And no borderline note is included (explicit ID match is unambiguous)

  Scenario: Inferential check with implicit match produces PASS with borderline note
    Given checklist item REQ-TRACE-01 is annotated "# Type: inferential"
    And _index.md lists "REQ-005: Rate limiting on login attempts"
    And bdd-specs.md contains a scenario titled "Login rate limiting" that does not cite "REQ-005" by ID
    When the evaluator applies REQ-TRACE-01
    Then the result is PASS
    And a borderline note states: "scenario covers REQ-005 semantically via feature name, not by explicit ID"
    And the borderline note does not affect the PASS/FAIL verdict
```

---

## Feature: Batch-Boundary Context Management

```gherkin
Feature: Structured Batch Handoff at Context Boundaries
  As the executing-plans skill at batch boundaries
  I want to emit structured handoff summaries
  So that context pressure is reduced and prior-batch details are recoverable

  Scenario: Batch handoff emitted after successful batch with correct structure
    Given batch 2 completes with tasks 003, 004, all PASS
    And 5 of 13 total tasks are now complete
    And no recurring failure patterns were detected in this plan
    When executing-plans emits the batch handoff
    Then the handoff contains progress "5/13 tasks complete"
    And the handoff lists completed task IDs for this batch: 003, 004
    And the handoff lists modified files from this batch
    And the handoff states next batch scope with task IDs
    And the handoff is under 30 lines

  Scenario: Batch handoff includes active failure patterns when present
    Given batch 3 completes with tasks 005, 006, all PASS after rework
    And SCEN-CONC-01 failed in batches 1 and 2 of this plan
    When executing-plans emits the batch handoff
    Then the handoff "Recurring patterns" field lists SCEN-CONC-01
    And the handoff is under 30 lines

  Scenario: Batch handoff excludes full content and implementation details
    Given batch 4 completes with tasks 007, 008, all PASS
    When executing-plans emits the batch handoff
    Then the handoff does not contain full task file content
    And the handoff does not contain evaluation report content
    And the handoff does not contain implementation details from completed tasks
    And the handoff references file paths instead of inlining content
```

---

## Feature: Evaluation Run Metrics

```gherkin
Feature: Cost and Duration Tracking in Evaluation Reports
  As the evaluation report consumer
  I want to see run metrics in each evaluation report
  So that I can measure evaluator overhead over time

  Scenario: Evaluation report includes run metrics with available token data
    Given the evaluator completes a design mode evaluation
    And the API response includes usage metadata
    When the evaluation report is produced
    Then the report contains a "Run Metrics" section
    And the section includes the checklist version used
    And the section includes evaluation duration
    And the section includes evaluator input and output token counts

  Scenario: Missing token data does not block evaluation or affect verdict
    Given the evaluator completes a code mode evaluation
    And the API response does not include usage metadata
    When the evaluation report is produced
    Then the "Run Metrics" section shows "N/A" for token counts
    And the verdict is produced normally
    And no error or warning is raised about missing token data
```

---

## Feature: Evaluator Output Responsibility Protocol

```gherkin
Feature: Evaluator Produces Content Without Writing Files
  As the superpowers-evaluator agent
  I want to produce report content as structured text without writing files
  So that I cannot accidentally modify artifacts I am evaluating

  Scenario: Evaluator returns structured text and parent writes to disk
    Given the evaluator completes a code mode evaluation
    When the evaluator produces its response
    Then the response contains the full evaluation report as structured markdown
    And the evaluator has not invoked Write or Edit tools during the evaluation
    And the parent agent writes the report to the evaluation file path

  Scenario: Evaluator reads checklist from spawn context path
    Given executing-plans spawns the evaluator with checklist path "docs/retros/checklists/design-v2.md"
    When the evaluator begins evaluation
    Then the evaluator reads the checklist from the provided path
    And the evaluator does not search for or select checklist versions independently
```

---

## Scenario Count Summary

| Feature | Scenarios |
|---------|-----------|
| Binary Checklist -- Design Mode | 6 |
| Binary Checklist -- Plan Mode | 5 |
| Command Exit Code -- Code Mode | 5 |
| Checklist Evolution Candidate Signal | 3 |
| Check Type Awareness in Evaluation | 3 |
| Batch-Boundary Context Management | 3 |
| Evaluation Run Metrics | 2 |
| Evaluator Output Responsibility Protocol | 2 |
| **Total** | **29** |

All scenarios meet:
- Single responsibility: each scenario tests exactly one rule or behavior
- Verifiable Then clauses: no vague assertions ("should be correct", "should work well")
- Business language: no implementation terms (no "JSON key", "function call", "regex")
- Independence: no shared mutable state between scenarios; each has explicit Given setup

New scenarios cover: cybernetic control enhancements (Checklist Evolution, Check Type Awareness), context management at batch boundaries (Batch-Boundary), cost observability (Run Metrics), and separation of concerns (Output Responsibility Protocol).
