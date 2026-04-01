# Task 007: Update executing-plans SKILL.md with evaluator integration

**depends-on**: task-002, task-004, task-005, task-006

## Description

Modify the executing-plans SKILL.md to integrate the evaluator as an optional layer. Add evaluator configuration parsing during Initialization, Sprint Contract generation as step 0 of Phase 3 batch loop, Evaluator Assessment as a new step after batch execution, intensity preset handling, and pivot support. All additions must be conditional on evaluator being enabled -- disabling returns to current behavior unchanged.

This is the most complex task: it touches the core execution flow. Read the full current SKILL.md before making changes.

## Execution Context

**Task Number**: 007 of 10
**Phase**: Integration (REQ-001, REQ-002, REQ-003, REQ-005)
**Prerequisites**: Tasks 002 (file formats), 004 (evaluator agent), 005 (rubrics), 006 (sprint contract template)

## BDD Scenario

```gherkin
Scenario: Evaluator configuration parsed during initialization
  Given the executing-plans skill is loaded with a plan that has evaluator metadata
  When initialization reads _index.md
  Then it parses the optional evaluator: YAML block
  And applies configuration precedence: skill argument > plan metadata > plugin defaults
  And defaults are: mode=auto, intensity=standard, pass>=4, rework>=2, fail=1

Scenario: Auto mode activates evaluator for complex plans
  Given evaluator mode is "auto" (default)
  When the plan has 5+ tasks or any task has 3+ BDD scenarios
  Then the evaluator is activated for this execution
  When the plan has fewer than 5 tasks and no task has 3+ BDD scenarios
  Then the evaluator is skipped and current self-verification (Phase 4) is used

Scenario: Sprint Contract step added as step 0 of Phase 3 batch loop
  Given the evaluator is enabled
  When a batch enters Phase 3 execution
  Then step 0 spawns the evaluator sub-agent to produce a sprint contract
  And the contract file must exist before step 1 (execution mode selection) begins
  And the contract follows the format from references/sprint-contract-template.md

Scenario: Evaluator Assessment step added after batch execution
  Given the evaluator is enabled and a batch completes execution
  When the batch reaches the evaluation step (after verification gate)
  Then the evaluator sub-agent is spawned to assess batch output
  And the evaluator reads the sprint contract and produced artifacts
  And the evaluator writes an evaluation report to the plan directory
  And the generator reads the evaluation file for rework instructions if verdict is REWORK or FAIL

Scenario: Intensity presets control evaluation frequency
  Given the evaluator is enabled with intensity "thorough"
  Then the evaluator runs per-task
  Given intensity is "standard" (default)
  Then the evaluator runs per-batch
  Given intensity is "light"
  Then the evaluator runs once at end-of-plan
  And sprint contracts use a simplified plan-level summary

Scenario: Pivot handling for sustained low scores
  Given a task receives scores of 2 or below on 2+ dimensions across 2 evaluation rounds
  When the evaluation report includes "pivot recommended" flag
  Then the orchestrator considers rearchitecting the approach
  And the pivot decision is logged but not automatic
```


## Files to Modify/Create

- Modify: `superpowers/skills/executing-plans/SKILL.md`

## Steps

### Step 1: Read current SKILL.md completely
- Understand the current Phase 1-6 structure
- Identify insertion points for evaluator steps

### Step 2: Add evaluator configuration to Initialization section
- After "Plan Check" and "Context" steps, add a new step: "Evaluator Configuration"
- Parse optional `evaluator:` YAML block from `_index.md`
- Document configuration precedence: skill argument > plan metadata > defaults
- Document auto mode logic: activate if 5+ tasks or any task has 3+ BDD scenarios
- Keep this section concise -- reference `references/evaluation-rubrics.md` for threshold details

### Step 3: Add Sprint Contract to Phase 3 batch loop
- Add "Step 0: Sprint Contract (if evaluator enabled)" before the current "Choose Execution Mode" step
- Describe: spawn evaluator sub-agent to produce sprint contract for the batch
- Contract must exist before execution starts
- Reference `references/sprint-contract-template.md` for format
- All additions wrapped in "if evaluator enabled" condition

### Step 4: Add Evaluator Assessment to Phase 3 batch loop
- Add a new step after the Verification Gate (current step 2d)
- Describe: spawn evaluator sub-agent to assess batch output
- Evaluator reads sprint contract + artifacts, writes evaluation report
- Generator reads evaluation file for rework if REWORK/FAIL
- Maximum 2 evaluation-rework rounds before escalation
- Reference `references/evaluation-rubrics.md` for scoring
- Reference `references/evaluation-file-formats.md` for report format

### Step 5: Add intensity preset handling
- Document the 3 presets and how they modify evaluation frequency
- `thorough`: per-task evaluation
- `standard`: per-batch evaluation (default)
- `light`: end-of-plan evaluation with simplified contract
- Keep descriptions concise; reference supporting docs for details

### Step 6: Add pivot handling
- In the evaluator assessment step, note the pivot flag condition
- Clarify it is advisory -- orchestrator decides
- Reference `references/evaluation-rubrics.md` for pivot conditions

### Step 7: Verify backwards compatibility
- Confirm all additions are conditional on evaluator being enabled
- Confirm existing Phase 1-6 structure is preserved
- Confirm existing verification gate (Phase 4 evidence blocks) remains as baseline

## Verification Commands

```bash
# File still exists and is valid
test -f superpowers/skills/executing-plans/SKILL.md && echo "PASS: SKILL.md exists"

# Contains evaluator configuration section
grep -q "evaluator" superpowers/skills/executing-plans/SKILL.md && echo "PASS: evaluator config present"

# Contains sprint contract step
grep -q "Sprint Contract" superpowers/skills/executing-plans/SKILL.md && echo "PASS: sprint contract step present"

# Contains intensity presets
grep -q "thorough" superpowers/skills/executing-plans/SKILL.md && \
grep -q "standard" superpowers/skills/executing-plans/SKILL.md && \
grep -q "light" superpowers/skills/executing-plans/SKILL.md && \
echo "PASS: intensity presets present"

# Contains pivot handling
grep -qi "pivot" superpowers/skills/executing-plans/SKILL.md && echo "PASS: pivot handling present"

# Still contains existing phases
grep -q "Phase 1" superpowers/skills/executing-plans/SKILL.md && \
grep -q "Phase 2" superpowers/skills/executing-plans/SKILL.md && \
grep -q "Phase 3" superpowers/skills/executing-plans/SKILL.md && \
grep -q "Phase 4" superpowers/skills/executing-plans/SKILL.md && \
echo "PASS: existing phases preserved"

# Plugin validation
python3 plugin-optimizer/scripts/validate-plugin.py superpowers/ --check=frontmatter
```

## Success Criteria

- Evaluator configuration parsing added to Initialization (with precedence rules)
- Auto mode logic documented (5+ tasks or 3+ BDD scenarios)
- Sprint Contract as step 0 of Phase 3 batch loop (conditional)
- Evaluator Assessment after verification gate (conditional)
- 3 intensity presets documented with clear frequency semantics
- Pivot handling documented as advisory
- All additions conditional -- disabling evaluator returns to current behavior
- Existing Phase 1-6 structure and verification gate preserved
- SKILL.md stays under token budget (check with validation)
