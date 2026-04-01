# Task 005: Create evaluation rubrics reference

**depends-on**: task-002

## Description

Create a Level 3 reference file defining the graded 1-5 scoring rubrics for the evaluator. This file defines 5 evaluation dimensions, concrete score-level examples for each, type-aware weighting tables, configurable thresholds, and the strategic pivot flag conditions. The evaluator agent reads this file on-demand during evaluation -- it is NOT embedded in the agent definition.

## Execution Context

**Task Number**: 005 of 10
**Phase**: Core Features (REQ-003)
**Prerequisites**: Task 002 (file formats define how scores appear in evaluation reports)

## BDD Scenario

```gherkin
Scenario: Five evaluation dimensions with concrete score-level examples
  Given the file evaluation-rubrics.md exists in executing-plans/references/
  When the scoring rubric is read
  Then it defines 5 dimensions: Correctness, Completeness, Code Quality, Test Coverage, Spec Compliance
  And each dimension has concrete examples for scores 1 through 5
  And score descriptions are specific enough to calibrate evaluator judgment
  And example: Correctness 3 = "Logic correct for primary path but misses an edge case in BDD scenario"

Scenario: Type-aware weighting adjusts dimensions by task type
  Given the evaluation rubrics reference
  When weights for task type "impl" are read
  Then Correctness and Code Quality are weighted highest
  And Test Coverage is secondary
  When weights for task type "test" are read
  Then Spec Compliance and Completeness are weighted highest
  When weights for task type "config" or "setup" are read
  Then only Correctness and Completeness apply
  And Code Quality, Test Coverage, Spec Compliance are marked N/A

Scenario: Strategic pivot flag triggered by sustained low scores
  Given the evaluation rubrics reference
  When the pivot conditions section is read
  Then it defines: scores of 2 or below on 2+ dimensions across 2 evaluation rounds triggers "pivot recommended"
  And the pivot flag is a recommendation, not an automatic action
  And the orchestrator decides whether to pivot based on context
```


## Files to Modify/Create

- Create: `superpowers/skills/executing-plans/references/evaluation-rubrics.md`

## Steps

### Step 1: Verify scenario alignment
- Read REQ-003 from requirements document
- Confirm dimensions, type-aware weighting, and pivot conditions

### Step 2: Create evaluation-rubrics.md
- Create the reference file at the specified path
- Use imperative style consistent with existing references
- Define the 5 evaluation dimensions
- For each dimension, provide concrete score-level descriptions (1-5) with examples
- Define type-aware weighting table:
  - `test` tasks: Spec Compliance (highest), Completeness (high), Code Quality (secondary)
  - `impl` tasks: Correctness (highest), Code Quality (high), Test Coverage (secondary)
  - `config`/`setup` tasks: Correctness and Completeness only; others N/A
  - `refactor` tasks: Code Quality (highest), Correctness (must remain unchanged)
- Define configurable thresholds: default pass >= 4, rework 2-3, fail 1
- Define pivot flag conditions and clarify it is advisory
- Include a "Calibration Examples" section with 2-3 worked examples showing how to apply rubrics to realistic scenarios

### Step 3: Verify completeness
- Confirm all 5 dimensions have 1-5 score descriptions
- Confirm 4 task types have weighting tables
- Confirm pivot conditions defined

## Verification Commands

```bash
# File exists
test -f superpowers/skills/executing-plans/references/evaluation-rubrics.md && echo "PASS: file exists"

# Contains all 5 dimensions
grep -q "Correctness" superpowers/skills/executing-plans/references/evaluation-rubrics.md && \
grep -q "Completeness" superpowers/skills/executing-plans/references/evaluation-rubrics.md && \
grep -q "Code Quality" superpowers/skills/executing-plans/references/evaluation-rubrics.md && \
grep -q "Test Coverage" superpowers/skills/executing-plans/references/evaluation-rubrics.md && \
grep -q "Spec Compliance" superpowers/skills/executing-plans/references/evaluation-rubrics.md && \
echo "PASS: all 5 dimensions present"

# Contains type-aware weighting
grep -q "impl" superpowers/skills/executing-plans/references/evaluation-rubrics.md && \
grep -q "test" superpowers/skills/executing-plans/references/evaluation-rubrics.md && \
grep -q "config" superpowers/skills/executing-plans/references/evaluation-rubrics.md && \
grep -q "refactor" superpowers/skills/executing-plans/references/evaluation-rubrics.md && \
echo "PASS: task type weighting present"

# Contains pivot flag
grep -qi "pivot" superpowers/skills/executing-plans/references/evaluation-rubrics.md && \
echo "PASS: pivot flag documented"
```

## Success Criteria

- File created at correct path
- 5 dimensions defined with concrete 1-5 score examples
- Type-aware weighting tables for test, impl, config/setup, refactor
- Default thresholds documented: pass >= 4, rework 2-3, fail 1
- Strategic pivot conditions defined (advisory, not automatic)
- Calibration examples section included
