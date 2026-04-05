# Task 010: Update executing-plans Phase 3f spawn context

**depends-on**: task-009

## Description

Update the executing-plans skill to pass a checklist path (instead of a rubric path) when spawning the superpowers-evaluator. The skill must determine the latest checklist version by scanning `docs/retros/checklists/` for files matching `{mode}-v{N}.md` and selecting the highest N. Add the checklist path table mapping mode to checklist file pattern.

## Execution Context

**Task Number**: 010 of 013
**Phase**: Integration
**Prerequisites**: Evaluation file formats updated (task-009)

## BDD Scenario

```gherkin
Scenario: Executing-plans spawns evaluator with latest checklist version
  Given docs/retros/checklists/ contains design-v1.md and design-v2.md
  When executing-plans prepares to spawn the evaluator in design mode
  Then it selects design-v2.md (highest version N=2)
  And the spawn context includes the path "docs/retros/checklists/design-v2.md"
  And files not matching {mode}-v{N}.md pattern are ignored (drafts, backups)

Scenario: Spawn context uses checklist path not rubric path
  Given the evaluator is spawned for a code mode evaluation
  When the spawn context is constructed
  Then it references "docs/retros/checklists/code-v{N}.md" (not "evaluation-rubrics.md")
  And the evaluator reads the checklist at that path
```

**Spec Source**: `../2026-04-03-eval-harness-design/architecture.md` (Phase 3f section)

## Files to Modify/Create

- Modify: `superpowers/skills/executing-plans/SKILL.md` (Phase 3, Step 0 and Step 2f sections)

## Steps

### Step 1: Add checklist path resolution

Add version selection logic to the skill. Before spawning the evaluator:

1. Scan `docs/retros/checklists/` for files matching `{mode}-v{N}.md`
2. Extract numeric suffix N from each matching filename
3. Select the file with the highest N
4. Files not matching the pattern (drafts, backups) are ignored
5. No hardcoded version in the skill definition

### Step 2: Update spawn context

Replace the rubric path references in the evaluator spawn context:

| Mode   | Checklist path pattern                               |
|--------|------------------------------------------------------|
| design | `docs/retros/checklists/design-v{N}.md` |
| plan   | `docs/retros/checklists/plan-v{N}.md`   |
| code   | `docs/retros/checklists/code-v{N}.md`   |

### Step 3: Update evaluator configuration section

Update the Initialization section to reference checklists instead of rubrics. Remove or update references to `evaluation-rubrics.md`.

### Step 3b: Add feedforward -- share checklist with generator

Per Anthropic's harness design finding that giving grading criteria to both generator AND evaluator improves first-iteration output quality:

1. When constructing the sprint contract for a batch, include a "Checklist Preview" section that lists the checklist items (ID + description) the evaluator will apply
2. This is informational only -- the generator is not required to self-evaluate, but awareness of evaluation criteria helps it produce better first-pass output
3. Format in sprint contract:

```markdown
## Evaluation Criteria Preview

The evaluator will apply the following checks after task completion:

| Item ID | Check |
|---------|-------|
| CODE-VER-01 | All verification commands exit with code 0 |
| CODE-QUAL-01 | No TODO/FIXME/HACK/XXX in produced files |
```

4. The preview is derived from the same checklist version passed to the evaluator -- no separate maintenance

### Step 4: Add evals directory creation

Ensure executing-plans creates the `docs/plans/YYYY-MM-DD-{topic}-evals/` directory (derived from the plan path by replacing `-plan/` with `-evals/`) before writing any evaluation artifacts. This directory is created on first use if it does not exist.

### Step 5: Verify spawn context change

Confirm the skill references checklist paths and not rubric paths.

## Verification Commands

```bash
# Checklist path referenced in executing-plans
grep -c "checklists" superpowers/skills/executing-plans/SKILL.md | xargs test 0 -lt && echo "PASS: checklist path referenced"

# Version selection logic present
grep -c "v{N}\|highest.*version\|latest.*version" superpowers/skills/executing-plans/SKILL.md | xargs test 0 -lt && echo "PASS: version selection"

# No rubric path reference in spawn context
! grep "evaluation-rubrics.md" superpowers/skills/executing-plans/SKILL.md && echo "PASS: no rubric reference in spawn"
```

## Success Criteria

- Evaluator spawn context passes checklist path (not rubric path)
- Version selection logic: scan for `{mode}-v{N}.md`, pick highest N
- Checklist path table documents all three modes
- No hardcoded version numbers in skill definition
- Evaluation-rubrics.md no longer referenced for spawning
- Sprint contract includes "Evaluation Criteria Preview" section (feedforward)
- Preview derived from same checklist version used by evaluator
- Evals directory created on first use (`*-evals/` sibling to `*-plan/`)
