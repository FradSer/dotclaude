# BDD Specifications: Superpowers Harness Optimizations

Based on Anthropic's "Harness Design for Long-Running Apps" research, these specifications
cover 6 optimizations that introduce separation of generation from evaluation into the
superpowers executing-plans workflow.

## Feature 1: Independent Evaluator Agent

```gherkin
Feature: Independent Evaluator Agent
  As a plan executor
  I want an independent evaluator agent to assess batch output
  So that quality issues caught by self-evaluation bias are detected

  Background:
    Given a plan with at least one batch of tasks
    And the executing-plans skill is active
    And the Superpower Loop is running

  Scenario: Evaluator runs after batch execution completes
    Given a batch of 4 tasks has been executed by generator agents
    And all tasks report verification commands passing
    When the batch enters Phase 4 (Verification & Feedback)
    Then an independent evaluator agent is launched
    And the evaluator receives the batch output artifacts but NOT the generator's self-assessment
    And the evaluator produces a structured evaluation report

  Scenario: Evaluator catches quality issue that self-evaluation missed
    Given a batch where the generator marked all tasks as passing
    But the implementation contains a subtle logic error visible in test coverage
    When the evaluator reviews the batch output
    Then the evaluator identifies the quality gap in its report
    And the affected task is marked back to "in_progress"
    And the generator receives the evaluator's findings for remediation

  Scenario: Evaluator grades below threshold and batch fails back to generator
    Given a batch with evaluation criteria requiring minimum score of 3 out of 5
    When the evaluator scores functionality at 2 out of 5
    Then the batch is marked as "needs_rework"
    And the evaluation report is written to a file in the plan folder
    And the generator agent is relaunched with the evaluation feedback
    And the rework count for the batch is incremented

  Scenario: Evaluator passes all criteria and batch proceeds
    Given a batch where all tasks produce complete working implementations
    When the evaluator scores every criterion at 3 or above
    Then the batch is marked as "verified"
    And the evaluation report is written with all passing scores
    And the workflow proceeds to user confirmation

  Scenario: Evaluator skipped for simple tasks as cost optimization
    Given a batch containing only configuration or setup tasks
    And the task types are all "config" or "setup"
    When the batch completes execution
    Then the evaluator agent is NOT launched
    And verification relies on standard exit-code checks only
    And the skip reason is logged as "simple_task_bypass"
```

## Feature 2: Sprint Contract Negotiation

```gherkin
Feature: Sprint Contract Negotiation
  As an evaluator agent
  I want to review and negotiate acceptance criteria before execution begins
  So that the definition of "done" is concrete and testable before any code is written

  Background:
    Given a plan with batches ready for execution
    And the evaluator agent is available
    And the executing-plans skill is in Phase 3

  Scenario: Evaluator reviews acceptance criteria before batch execution
    Given a batch with 3 tasks each containing BDD scenarios
    When the batch is about to begin execution
    Then the evaluator reviews all BDD scenarios in the batch
    And the evaluator produces a sprint contract listing testable acceptance criteria
    And the generator acknowledges the contract before writing any code

  Scenario: Evaluator flags ambiguous BDD scenario
    Given a task with BDD scenario containing "Then the system works correctly"
    When the evaluator reviews the sprint contract
    Then the evaluator flags the scenario as ambiguous
    And the evaluator proposes a concrete alternative: "Then the response status is 200 and the body contains a valid JSON payload"
    And the ambiguous scenario is rewritten before execution begins

  Scenario: Contract negotiation adds missing edge-case criteria
    Given a task with BDD scenario covering only the happy path
    And the feature involves user input validation
    When the evaluator reviews the sprint contract
    Then the evaluator identifies missing error-path coverage
    And the evaluator adds criteria for invalid input handling
    And the evaluator adds criteria for boundary conditions
    And the updated contract is saved to the plan folder as sprint-contract-batch-N.md

  Scenario: Generator and evaluator reach agreement on contract
    Given the evaluator has proposed modifications to 2 of 5 acceptance criteria
    When the generator reviews the proposed modifications
    Then the generator accepts or counter-proposes each modification
    And a final agreed contract is produced
    And the contract file records both the original and negotiated criteria
```

## Feature 3: Graded Evaluation Criteria

```gherkin
Feature: Graded Evaluation Criteria
  As an evaluator agent
  I want to score each quality dimension on a 1-5 scale with defined thresholds
  So that evaluation is concrete and reproducible rather than subjective

  Background:
    Given a batch has completed execution
    And the evaluator agent is reviewing the output
    And a grading rubric is loaded from the plan configuration

  Scenario: Each criterion scored 1-5 with minimum threshold
    Given the evaluation rubric defines 4 criteria:
      | criterion        | min_threshold | weight |
      | functionality    | 3             | 0.35   |
      | code_quality     | 3             | 0.25   |
      | test_coverage    | 3             | 0.25   |
      | spec_compliance  | 4             | 0.15   |
    When the evaluator assesses a completed batch
    Then each criterion receives a score between 1 and 5
    And each score includes a one-sentence justification
    And the scores are recorded in the evaluation report

  Scenario: One criterion below threshold fails the batch
    Given the evaluation rubric requires functionality >= 3
    When the evaluator scores functionality at 2
    And all other criteria score at 4 or above
    Then the overall batch verdict is "FAIL"
    And the failure report identifies functionality as the blocking criterion
    And the report includes specific remediation guidance for the failing dimension

  Scenario: All criteria above threshold passes the batch
    Given the evaluation rubric with 4 criteria each requiring >= 3
    When the evaluator scores:
      | criterion        | score |
      | functionality    | 4     |
      | code_quality     | 3     |
      | test_coverage    | 4     |
      | spec_compliance  | 5     |
    Then the overall batch verdict is "PASS"
    And the weighted average score is calculated and recorded
    And the batch proceeds to user confirmation

  Scenario: Criteria weights differ by task type
    Given a batch containing implementation tasks
    Then the rubric uses implementation weights:
      | criterion        | weight |
      | functionality    | 0.35   |
      | code_quality     | 0.25   |
      | test_coverage    | 0.25   |
      | spec_compliance  | 0.15   |
    When the batch instead contains refactoring tasks
    Then the rubric switches to refactoring weights:
      | criterion        | weight |
      | functionality    | 0.20   |
      | code_quality     | 0.40   |
      | test_coverage    | 0.20   |
      | spec_compliance  | 0.20   |

  Scenario Outline: Rubric threshold calibration per task criticality
    Given a task with criticality level "<criticality>"
    When the evaluator loads the grading rubric
    Then the minimum threshold for all criteria is <threshold>

    Examples:
      | criticality | threshold |
      | low         | 2         |
      | normal      | 3         |
      | high        | 4         |
      | critical    | 5         |
```

## Feature 4: Context Reset for Long Plans

```gherkin
Feature: Context Reset for Long Plans
  As a plan executor
  I want the harness to detect when context is becoming stale
  So that long plans maintain consistent quality across all batches

  Background:
    Given the executing-plans skill is active
    And the Superpower Loop is running

  Scenario: Plan with 16 or more tasks triggers handoff mode
    Given a plan containing 18 tasks across 5 batches
    When the plan is loaded in Phase 1
    Then the harness marks the plan as "long_plan"
    And handoff mode is enabled for inter-batch transitions
    And the handoff strategy is recorded in the execution state file

  Scenario: Handoff artifact written with completed task state
    Given batch 2 of 5 has just completed and been verified
    And handoff mode is enabled
    When the batch transitions to the next batch
    Then a handoff artifact is written to .claude/handoff-batch-N.md
    And the artifact contains:
      | section             | content                                      |
      | completed_tasks     | IDs, subjects, and verification status         |
      | pending_tasks       | IDs, subjects, and dependency state            |
      | files_modified      | Paths of all files created or changed          |
      | decisions_made      | Key architectural or design decisions          |
      | current_batch       | The next batch number to execute               |
      | blockers            | Any unresolved issues from previous batches    |
    And the artifact is under 2000 tokens to fit in a fresh context

  Scenario: Fresh session reads handoff and continues execution
    Given a handoff artifact exists at .claude/handoff-batch-3.md
    And batch 3 has 4 pending tasks
    When a fresh session starts with the Superpower Loop
    Then the session reads the handoff artifact first
    And the session reconstructs task state from the artifact
    And execution resumes at batch 3 without re-reading completed batch outputs
    And the fresh session loads only the task files for the current batch

  Scenario: Short plans use normal Superpower Loop without handoff
    Given a plan containing 8 tasks across 2 batches
    When the plan is loaded in Phase 1
    Then the harness marks the plan as "short_plan"
    And handoff mode is NOT enabled
    And the standard Superpower Loop manages all context within a single session

  Scenario: Handoff artifact validated before session resume
    Given a handoff artifact exists at .claude/handoff-batch-2.md
    But the artifact is missing the "pending_tasks" section
    When a fresh session attempts to read the handoff
    Then the session reports the artifact as malformed
    And the session falls back to re-reading the full plan state from task files
    And a warning is logged about the incomplete handoff
```

## Feature 5: Harness Model Calibration

```gherkin
Feature: Harness Model Calibration
  As a harness operator
  I want evaluation frequency and depth adjusted based on the active model
  So that stronger models are not over-evaluated and weaker models get sufficient checks

  Background:
    Given the executing-plans skill is active
    And a calibration configuration is available

  Scenario: Opus model reduces evaluator frequency
    Given the active model is "claude-opus-4-6"
    And the calibration config specifies opus evaluation frequency as "every_other_batch"
    When a batch completes execution
    Then the evaluator runs only on even-numbered batches
    And odd-numbered batches use self-evaluation with verification commands only
    And the calibration decision is logged with reason "opus_high_confidence"

  Scenario: Sonnet model uses full evaluation pipeline
    Given the active model is "claude-sonnet-4-6"
    And the calibration config specifies sonnet evaluation frequency as "every_batch"
    When a batch completes execution
    Then the evaluator agent runs after every batch
    And sprint contract negotiation is mandatory before every batch
    And the calibration decision is logged with reason "sonnet_standard_pipeline"

  Scenario: Calibration config consulted at each decision point
    Given a calibration configuration file at .claude/harness-calibration.yml
    And the config contains:
      | model_pattern     | eval_frequency    | contract_required | context_reset_threshold |
      | claude-opus-*     | every_other_batch | optional          | 24                      |
      | claude-sonnet-*   | every_batch       | mandatory         | 16                      |
      | *                 | every_batch       | mandatory         | 12                      |
    When the harness reaches a decision point (batch start, batch end, or session boundary)
    Then the harness reads the calibration config
    And applies the matching row based on the current model identifier
    And logs the applied calibration parameters

  Scenario: Unknown model defaults to conservative evaluation
    Given the active model identifier does not match any calibration config pattern
    When the harness reaches an evaluation decision point
    Then the harness applies the wildcard default row
    And evaluation runs after every batch
    And sprint contract negotiation is mandatory
    And context reset threshold is set to 12 tasks

  Scenario: Calibration config missing falls back to full pipeline
    Given no calibration configuration file exists
    When the harness starts execution
    Then the harness logs a warning "No calibration config found, using defaults"
    And the evaluator runs after every batch
    And sprint contracts are mandatory
    And context reset threshold is 16 tasks
```

## Feature 6: File-Based Communication

```gherkin
Feature: File-Based Communication Between Generator and Evaluator
  As a multi-agent harness
  I want generator and evaluator to communicate through structured files
  So that evaluation history is persistent, auditable, and survives context resets

  Background:
    Given the executing-plans skill is active
    And the plan folder exists at docs/plans/YYYY-MM-DD-topic-plan/
    And the evaluator agent is enabled

  Scenario: Evaluator writes evaluation-round-N.md after each assessment
    Given batch 2 has completed execution
    When the evaluator finishes grading the batch
    Then the evaluator writes docs/plans/YYYY-MM-DD-topic-plan/evaluation-round-1.md
    And the file contains:
      | section              | content                                    |
      | batch_id             | The batch number evaluated                  |
      | timestamp            | ISO 8601 evaluation timestamp               |
      | criteria_scores      | Each criterion with score and justification  |
      | verdict              | PASS or FAIL with overall weighted score     |
      | remediation          | Specific fixes required (if FAIL)            |
      | files_reviewed       | List of files the evaluator inspected        |
    And the round number increments for each subsequent evaluation

  Scenario: Generator reads evaluation feedback before retry
    Given evaluation-round-1.md exists with verdict "FAIL"
    And the remediation section lists 2 specific issues
    When the generator is relaunched for rework
    Then the generator reads evaluation-round-1.md before writing any code
    And the generator's prompt includes the remediation items as mandatory fixes
    And the generator does not repeat the patterns identified as failures

  Scenario: Multiple evaluation rounds tracked with incrementing filenames
    Given batch 3 failed evaluation twice
    When the evaluator completes its third assessment
    Then the following files exist in the plan folder:
      | filename                | verdict |
      | evaluation-round-1.md   | FAIL    |
      | evaluation-round-2.md   | FAIL    |
      | evaluation-round-3.md   | PASS    |
    And each file references the previous round's findings
    And the final passing round confirms all prior issues are resolved

  Scenario: Sprint contract written as a file before execution begins
    Given batch 1 is about to start execution
    When the evaluator and generator negotiate the sprint contract
    Then the contract is written to docs/plans/YYYY-MM-DD-topic-plan/sprint-contract-batch-1.md
    And the contract file contains the agreed acceptance criteria
    And the generator references this file during implementation
    And the evaluator references this file during grading

  Scenario: Evaluation files survive context reset
    Given handoff mode is active for a long plan
    And evaluation-round-1.md and sprint-contract-batch-2.md exist
    When a context reset occurs between batches
    Then the fresh session reads evaluation files from the plan folder
    And the evaluation history is fully available without context window memory
    And the handoff artifact references the latest evaluation round number

  Scenario: Evaluation file format validated on write
    Given the evaluator produces an evaluation report
    When the report is written to evaluation-round-N.md
    Then the file is validated against the required schema
    And missing required sections cause a warning log
    And the evaluation proceeds but flags the incomplete report for review
```
