# BDD Specifications: Eval Harness System

Comprehensive Gherkin scenarios for the eval harness pipeline:
`orchestrator → evaluator (per golden artifact) → bias-analyzer → rubric-optimizer`

Plus score trend tracking in executing-plans for multi-iteration optimization.

---

## Research Summary (informs scenario design)

**Evaluator Calibration Techniques**
Production LLM systems calibrate judges via pilot rounds against human-annotated gold standards, measuring inter-annotator agreement (Cohen's kappa >= 0.7 is the accepted threshold). The Rubric-Reasoning-Result pattern forces judges to justify scores before outputting them, reducing anchoring bias. Few-shot calibration with 3-5 gold examples in the prompt achieves ~80% agreement with human baselines. Calibration sweep: test evaluator against 20+ gold artifacts, measure mean absolute error (MAE) against human scores; accept if MAE <= 0.5 on a 1-5 scale.

**Evaluator Bias Detection**
Research identifies two primary systematic biases: leniency bias and harshness bias. Detection method: compute per-dimension mean delta = mean(evaluator_score - human_score) across all gold artifacts. Research-based MAE threshold is <= 0.5; however, the **design threshold for optimization triggers is mean_delta > 1.0** (see `architecture.md` Canonical Bias Thresholds table). Research thresholds are informational only — all scenario Then clauses use the design threshold of 1.0. Dimension-specific bias is more insidious than global bias: an evaluator may be well-calibrated overall but systematically lenient on one dimension. The CALM framework categorizes 12 bias types; leniency/harshness and dimension-anchoring are the highest-priority cases.

**Score Trend Analysis**
ScoreFlow and similar frameworks use decimal convergence criteria (± 0.2 for plateau). Superpowers uses **integer rubric scores (1-5)**, so trend classification uses integer deltas: `improving` = at least one dimension increased by >= 1 integer point with no dimension decreasing; `plateau` = all applicable dimension scores identical to prior round; `declining` = at least one dimension score decreased. After 2 plateau rounds without PASS, the executing-plans skill escalates per `blocker-and-escalation.md`. Research maximum of 5 rounds aligns with the executing-plans limit.

**Golden Dataset Design**
Gold artifacts must be: accurate (human-verified correct/incorrect), complete (cover edge cases and boundary conditions), consistent (uniform format and metadata), and adversarial (include intentionally flawed examples to test evaluator rejection). 20-30 artifacts per mode (design/plan/code) is sufficient for a stable baseline. Each artifact needs: the artifact itself, a human baseline score per dimension, a rationale for each score, and a verdict (PASS/REWORK/FAIL). Silver-to-gold promotion requires at least two independent human raters with agreement >= 80%.

---

## Feature: Evaluator Calibration

```gherkin
Feature: Evaluator Calibration Against Golden Artifacts
  As an orchestrator running the eval harness
  I want to verify the superpowers-evaluator is well-calibrated against human baselines
  So that evaluation scores are reliable and unbiased before use in production pipelines

  Background:
    Given a golden artifact set containing 20 design artifacts
    And each artifact has human baseline scores for all 5 dimensions
    And each artifact has a human verdict (PASS or REWORK)
    And the rubric file is readable at "superpowers/skills/brainstorming/references/evaluation-rubrics.md"

  # --- PASS CASES ---

  Scenario: All golden artifacts produce scores within acceptable delta of human baseline
    Given the evaluator is invoked on each golden artifact in design mode
    When all 20 evaluation reports are collected
    Then the mean absolute error (MAE) between evaluator scores and human scores is <= 0.5 per dimension
    And no individual artifact has a per-dimension delta > 1.5 from its human baseline
    And the calibration report records "CALIBRATED" status

  Scenario: Verdict agreement rate meets threshold
    Given the evaluator has produced verdicts for all 20 golden artifacts
    When verdict agreement is computed against human verdicts
    Then the agreement rate is >= 85%
    And the calibration report records verdict_agreement: 0.85 or higher
    And the calibration report records "CALIBRATED" status

  Scenario: Calibration passes with few-shot gold examples injected
    Given the evaluator prompt includes 3 few-shot gold examples from the golden set
    And the remaining 17 artifacts are used as the test set
    When the evaluator scores all 17 test artifacts
    Then the MAE across all dimensions is <= 0.4
    And the calibration report notes "few-shot calibration used"

  # --- FAIL CASES ---

  Scenario: Leniency bias detected when evaluator scores are consistently higher than human
    Given a golden artifact set where human scores average 3.2 across all dimensions
    And the evaluator consistently scores 1.2 points higher than human on every artifact
    When the bias-analyzer computes per-dimension mean delta
    Then the bias report flags "LENIENCY_BIAS" for all 5 dimensions
    And the bias report records mean_delta > 1.0 for each dimension
    And the calibration report records "BIAS_DETECTED" status
    And no "CALIBRATED" status is issued

  Scenario: Harshness bias detected when evaluator scores are consistently lower than human
    Given a golden artifact set where human scores average 3.8 across all dimensions
    And the evaluator consistently scores 1.1 points lower than human on every artifact
    When the bias-analyzer computes per-dimension mean delta
    Then the bias report flags "HARSHNESS_BIAS" for all 5 dimensions
    And the bias report records mean_delta < -1.0 for each dimension
    And the calibration report records "BIAS_DETECTED" status
    And the rubric-optimizer is triggered automatically

  Scenario: Systematic bias detected in a single dimension only
    Given the evaluator is well-calibrated on 4 of 5 dimensions (|mean_delta| <= 0.75)
    And the evaluator scores RiskCoverage 1.5 points higher than human on average
    When the bias-analyzer computes per-dimension mean delta
    Then the bias report flags "LENIENCY_BIAS" for dimension "RiskCoverage" only
    And the other 4 dimensions are recorded as "CALIBRATED"
    And the calibration report records "DIMENSION_BIAS_DETECTED" status
    And the rubric-optimizer is triggered with scope: ["RiskCoverage"]
```

---

## Feature: Rubric Optimization

```gherkin
Feature: Rubric Optimization After Bias Detection
  As the eval harness pipeline
  I want to automatically update rubric language when bias is detected
  So that the evaluator re-calibrates toward human baseline without overcorrecting

  Background:
    Given bias has been detected in the previous calibration run
    And the bias-analyzer has produced a bias report with flagged dimensions
    And the rubric-optimizer has read the current rubric file

  Scenario: Bias detected triggers rubric update and recalibration improves
    Given the bias report flags LENIENCY_BIAS on "RiskCoverage" with mean_delta = 1.5
    When the rubric-optimizer updates the RiskCoverage dimension rubric
    And stricter language is injected for score levels 4 and 5 (e.g., "all significant risks must have concrete mitigations with rollback procedures")
    And recalibration is run against the same golden artifact set
    Then the new mean_delta for RiskCoverage is in range [-0.75, 0.75]
    And the bias report records "RECALIBRATION_IMPROVED"

  Scenario: Rubric update does not overcorrect into harshness
    Given the bias report flags LENIENCY_BIAS on "BDD Completeness" with mean_delta = 1.2
    When the rubric-optimizer applies correction to BDD Completeness
    And recalibration is run
    Then the new mean_delta for BDD Completeness is in range [-0.75, 0.75]
    And no HARSHNESS_BIAS is introduced on any previously-calibrated dimension
    And the calibration report records "NO_OSCILLATION_DETECTED"

  Scenario: Prior rubric content is snapshotted before amendment is applied
    Given the rubric-optimizer is about to apply an amendment to the "RiskCoverage" dimension
    When the orchestrator writes the calibration report
    Then the calibration report contains a "prior_rubric_snapshot" field with the full current text of the rubric section
    And the snapshot is written before any rubric file modification occurs
    And the snapshot enables manual rollback by copying the prior_rubric_snapshot content back to the file

  Scenario: Repeated bias after two rubric updates triggers escalation
    Given the rubric-optimizer has updated the rubric twice for "ArchitectureSoundness"
    And recalibration still shows mean_delta = 0.6 after both updates
    When the third recalibration completes
    Then the pipeline does not attempt a third automatic rubric update
    And the harness writes a "MANUAL_REVIEW_REQUIRED" flag to the calibration report
    And the escalation note lists: affected dimension, current mean_delta, attempts made

  Scenario: Rubric update preserves all unaffected dimensions
    Given the bias report flags only "DocumentConsistency" for correction
    When the rubric-optimizer modifies the DocumentConsistency rubric
    And recalibration runs on all 20 golden artifacts
    Then scores for RequirementsTraceability, BDDCompleteness, ArchitectureSoundness, and RiskCoverage are unchanged (within ±0.1 MAE vs previous run)
    And no new bias flags appear on previously-calibrated dimensions
```

---

## Feature: Score Trend Tracking in Executing Plans

```gherkin
Feature: Score Trend Tracking for Multi-Iteration Optimization
  As the executing-plans skill
  I want to track evaluator scores across rounds and inject trend context into the generator
  So that the generator can adapt its strategy based on whether scores are improving, plateauing, or declining

  Background:
    Given a plan with evaluator mode "on"
    And evaluation-history.json exists in the plan directory
    And the file records per-task scores across evaluation rounds

  Scenario: Improving trend causes generator to continue with refinement prompt
    Given evaluation-history.json contains for task 003:
      | round | Correctness | Completeness | verdict |
      | 1     | 2           | 3            | REWORK  |
      | 2     | 3           | 4            | REWORK  |
    When the executing-plans skill reads the trend for task 003
    Then the computed trend is "IMPROVING" (Correctness increased by 1, Completeness increased by 1, no decreases)
    And the generator's next prompt includes: "Scores are improving (round 1 → 2). Continue refining the same approach."
    And execution proceeds to round 3

  Scenario: Plateau trend after 2 rounds with identical scores triggers escalation
    Given evaluation-history.json contains for task 005:
      | round | Correctness | Completeness | verdict |
      | 1     | 3           | 2            | REWORK  |
      | 2     | 3           | 2            | REWORK  |
    When the executing-plans skill reads the trend for task 005 after round 2
    Then the computed trend is "PLATEAU" (all dimension scores identical across 2 consecutive rounds)
    And plateau_count for task 005 is recorded as 2
    And the task is added to "escalated_tasks" in evaluation-history.json
    And execution does not proceed to a third rework round for task 005

  Scenario: Declining trend triggers immediate pivot recommendation
    Given evaluation-history.json contains for task 007:
      | round | Correctness | Completeness | verdict |
      | 1     | 4           | 3            | REWORK  |
      | 2     | 3           | 2            | REWORK  |
    When the executing-plans skill reads the trend for task 007
    Then the computed trend is "DECLINING" (Correctness decreased by 1, Completeness decreased by 1)
    And the generator's next prompt includes: "Scores are declining. Pivot required — review the implementation strategy."
    And the pivot flag in the evaluation report is set to true
    And execution pauses for user review before proceeding

  Scenario: Max rounds reached without PASS triggers escalation
    Given evaluation-history.json contains 5 rounds for task 009
    And task 009 has not achieved PASS verdict in any round
    When the executing-plans skill checks whether max rounds have been reached
    Then execution does not attempt a 6th evaluation round
    And the harness writes a blocker entry: "Task 009: max evaluation rounds (5) reached without PASS"
    And the escalation procedure in blocker-and-escalation.md is triggered
    And the user is notified via AskUserQuestion with the blocker details

  Scenario: First round has no trend (baseline only)
    Given evaluation-history.json is empty for task 002
    When the evaluator completes the first evaluation round for task 002
    Then the trend is recorded as "BASELINE" (not IMPROVING/PLATEAU/DECLINING)
    And no trend context is injected into the generator's prompt
    And the score is written to evaluation-history.json as round 1

  Scenario: Score delta below integer threshold treated as plateau not improvement
    Given evaluation-history.json contains for task 004:
      | round | Correctness | Completeness | verdict |
      | 1     | 3           | 3            | REWORK  |
      | 2     | 3           | 3            | REWORK  |
    When the executing-plans skill reads the trend for task 004
    Then the computed trend is "PLATEAU" (all dimension scores identical — no integer-point change)
    And the generator receives a plateau-context prompt
```

---

## Feature: Golden Artifact Validation

```gherkin
Feature: Golden Artifact Validation Before Calibration
  As the eval harness orchestrator
  I want to validate golden artifact structure before running calibration
  So that calibration fails fast on malformed input rather than producing invalid results

  Background:
    Given the golden artifact set directory is "eval-harness/golden/design/"
    And the harness reads artifact metadata from each artifact's "human-scores.json" (authoritative source for expected_verdict and human baseline scores)
    And the harness reads artifact type metadata from each artifact's "manifest.json" (name, mode, quality tier only)

  Scenario: Well-formed artifact with all required files is accepted
    Given a golden artifact "design-high-001" contains:
      | file               | present |
      | _index.md          | yes     |
      | bdd-specs.md       | yes     |
      | architecture.md    | yes     |
      | best-practices.md  | yes     |
      | human-scores.json  | yes     |
      | manifest.json      | yes     |
    And "human-scores.json" includes scores for all 5 design dimensions
    And "human-scores.json" includes expected_verdict: "PASS"
    When the harness validates the artifact
    Then validation reports "VALID" for "design-high-001"
    And the artifact is included in the calibration run

  Scenario: Malformed artifact missing _index.md is rejected with clear error
    Given a golden artifact "design-bad-001" contains only "bdd-specs.md" and "architecture.md"
    And "_index.md" is absent
    When the harness validates the artifact
    Then validation reports "INVALID" for "design-bad-001"
    And the error message states: "Missing required file: _index.md"
    And the artifact is excluded from the calibration run
    And the calibration report lists "design-bad-001" in the "excluded_artifacts" section

  Scenario: Artifact without human-scores.json is rejected before calibration runs
    Given a golden artifact "design-no-scores-001" has all required design files
    But "human-scores.json" is absent
    When the harness validates the artifact
    Then validation reports "INVALID" for "design-no-scores-001"
    And the error message states: "Missing required file: human-scores.json"
    And calibration does not run until all artifacts pass validation

  Scenario: Artifact with partial human baseline scores is rejected
    Given a golden artifact "design-partial-001" has human-scores.json with scores for 3 of 5 dimensions
    And dimensions "ArchitectureSoundness" and "RiskCoverage" are absent from human-scores.json
    When the harness validates the artifact
    Then validation reports "INVALID" for "design-partial-001"
    And the error message lists the specific missing dimensions
    And the artifact is excluded from calibration

  Scenario: All artifacts pass validation and calibration proceeds
    Given 20 golden artifacts all pass individual validation
    When the harness completes the validation phase
    Then the validation report records 20 valid artifacts and 0 invalid artifacts
    And the calibration phase begins immediately
    And no manual intervention is required
```

---

## Feature: Full Pipeline Integration

```gherkin
Feature: End-to-End Eval Harness Pipeline Execution
  As a developer running the eval harness skill
  I want the full pipeline to execute without manual intervention
  So that evaluator calibration, bias detection, and rubric optimization run atomically

  Background:
    Given the eval-harness skill is invoked
    And 20 validated golden artifacts are available in design mode
    And the rubric file exists at the configured path
    And evaluation-history.json is initialized (empty or pre-existing)

  Scenario: Full pipeline succeeds when evaluator is well-calibrated
    Given all golden artifacts pass validation
    When the orchestrator spawns the evaluator on each artifact
    And the bias-analyzer receives all 20 evaluation reports
    Then bias-analyzer computes mean_delta per dimension
    And no dimension has |mean_delta| > 1.0
    And the calibration report records "CALIBRATED"
    And the rubric-optimizer is NOT invoked
    And the pipeline completes with status "HARNESS_READY"

  Scenario: Full pipeline runs bias correction cycle when leniency bias is found
    Given calibration reveals leniency bias on "RiskCoverage" (mean_delta = 1.5)
    When the bias-analyzer writes the bias report
    Then the rubric-optimizer is triggered automatically
    And the rubric-optimizer updates the RiskCoverage rubric
    And recalibration runs on the same 20 artifacts
    And the new mean_delta for RiskCoverage is in range [-0.75, 0.75]
    And the pipeline records "BIAS_CORRECTED" in the final calibration report
    And the pipeline completes with status "HARNESS_READY"

  Scenario: Pipeline halts at bias analysis when --dry-run flag is provided
    Given the eval-harness skill is invoked with "--dry-run" flag
    And calibration reveals leniency bias on "ArchitectureSoundness" (mean_delta = 1.2)
    When the bias-analyzer completes analysis
    Then the calibration report is written with bias findings
    And the rubric-optimizer is NOT invoked
    And no rubric file is modified
    And the pipeline completes with status "DRY_RUN_COMPLETE: bias detected, rubric changes NOT applied"

  Scenario: Pipeline writes rubric amendments only when --apply-rubric-changes flag is provided
    Given the eval-harness skill is invoked with "--apply-rubric-changes" flag
    And the rubric-optimizer has produced amendment proposals for "RiskCoverage"
    When the user approves the proposals via AskUserQuestion
    Then the rubric-optimizer writes the amendments to the rubric file
    And the calibration report records the prior rubric content in "prior_rubric_snapshot"
    And the pipeline completes with status "RUBRIC_AMENDED"

  Scenario: Pipeline writes rubric amendments only when --apply-rubric-changes flag is NOT provided
    Given the eval-harness skill is invoked WITHOUT "--apply-rubric-changes" flag
    And bias has been detected and rubric-optimizer has produced proposals
    When the orchestrator presents proposals to the user
    Then no rubric file is modified regardless of user response
    And the proposals are written to the calibration report for review
    And the pipeline completes with status "PROPOSALS_GENERATED: rerun with --apply-rubric-changes to apply"

  Scenario: Pipeline writes evaluation-history.json on first calibration run
    Given evaluation-history.json does not exist
    When calibration completes successfully
    Then evaluation-history.json is created in the plan directory
    And it records: calibration_timestamp, per-artifact scores, per-dimension MAE, verdict_agreement_rate
    And subsequent runs append to the history rather than overwriting

  Scenario: Pipeline produces deterministic output when run twice on same artifacts
    Given calibration run 1 has completed and produced a calibration report
    When calibration run 2 is executed on the same artifacts with the same rubric
    Then the per-artifact scores differ by no more than ±0.1 from run 1
    And both runs produce the same "CALIBRATED" or "BIAS_DETECTED" status
    And the calibration report notes "DETERMINISM_CHECK: PASS"

  Scenario: Pipeline handles mixed artifact modes (design + plan + code)
    Given the golden artifact set contains:
      | mode   | count |
      | design | 10    |
      | plan   | 5     |
      | code   | 5     |
    When the orchestrator dispatches evaluators with mode-appropriate rubrics
    Then design artifacts are evaluated using design mode rubrics
    And plan artifacts are evaluated using plan mode rubrics
    And code artifacts are evaluated using code mode rubrics
    And the bias-analyzer computes bias separately per mode
    And the calibration report contains a per-mode summary
```

---

## Scenario Count Summary

| Feature | Scenarios |
|---------|-----------|
| Evaluator Calibration | 6 |
| Rubric Optimization | 5 (+ snapshot/rollback) |
| Score Trend Tracking | 6 |
| Golden Artifact Validation | 5 |
| Full Pipeline Integration | 8 (+ dry-run, apply-rubric-changes x2) |
| **Total** | **30** |

All scenarios meet the following criteria:
- Each scenario tests exactly one rule or behavior (single responsibility)
- Every Then clause is specific and verifiable (no vague assertions)
- Scenarios are independent of each other (no shared mutable state)
- Business language used throughout (no implementation-specific terms like "JSON key", "function call")
- Given/When/Then structure is preserved with And for multi-step clauses
