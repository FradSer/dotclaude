# Task 014: Remove old rubrics and update cross-references

**depends-on**: task-010

## Description

Remove the now-obsolete `evaluation-rubrics.md` from executing-plans references and update all cross-references in executing-plans and writing-plans skills. The writing-plans evaluation rubrics file should be updated to reflect the new binary checklist approach used by the evaluator in plan mode.

## Execution Context

**Task Number**: 014 of 015
**Phase**: Refinement
**Prerequisites**: Phase 3f spawn context updated with checklist paths (task-010)

## BDD Scenario

```gherkin
Scenario: Old rubrics file removed and references updated
  Given superpowers/skills/executing-plans/references/evaluation-rubrics.md exists
  And executing-plans/SKILL.md references evaluation-rubrics.md
  When the cleanup task completes
  Then superpowers/skills/executing-plans/references/evaluation-rubrics.md no longer exists
  And executing-plans/SKILL.md references checklists instead of rubrics
  And writing-plans/SKILL.md evaluator references use checklist terminology
  And writing-plans/references/evaluation-rubrics.md is updated for checklist approach
```

**Spec Source**: `../2026-04-03-eval-harness-design/architecture.md` (File Layout section: evaluation-rubrics.md REMOVED)

## Files to Modify/Create

- Remove: `superpowers/skills/executing-plans/references/evaluation-rubrics.md`
- Modify: `superpowers/skills/executing-plans/SKILL.md` (update references)
- Modify: `superpowers/skills/writing-plans/SKILL.md` (update evaluator references)
- Modify: `superpowers/skills/writing-plans/references/evaluation-rubrics.md` (update content for checklist approach)

## Steps

### Step 1: Remove executing-plans evaluation-rubrics.md

Delete `superpowers/skills/executing-plans/references/evaluation-rubrics.md`. This file is replaced by the versioned checklists in `docs/retros/checklists/`.

### Step 2: Update executing-plans/SKILL.md references

Find and update all references to `evaluation-rubrics.md` in executing-plans/SKILL.md:
- Replace "See `./references/evaluation-rubrics.md` for scoring criteria" with checklist references
- Update the References section at the bottom to remove the rubrics entry
- Replace "rubric" terminology with "checklist" where applicable
- Keep references to `evaluation-file-formats.md` (already updated in task-009)

### Step 3: Update writing-plans/SKILL.md evaluator references

Update Phase 4 (Plan Reflection) references:
- Replace "scoring criteria" with "checklist evaluation"
- Update references to evaluation-rubrics.md to point to checklist documentation
- Ensure the evaluator spawn description mentions checklist path

### Step 4: Update writing-plans/references/evaluation-rubrics.md

This file is used by writing-plans Phase 4 for large plan reflection via the evaluator. Update it to describe the new binary checklist approach:
- Replace 1-5 scoring dimensions with references to plan checklist items
- Update the verdict rules to PASS/FAIL (not score-based)
- Update the calibration example to use checklist format
- Rename the file content to reflect "Plan Evaluation Checklist Reference" (keep the filename for backward compatibility, or rename if references are updated)

### Step 5: Verify all references updated

Scan both skills for any remaining references to the removed file or rubric scoring.

## Verification Commands

```bash
# Old rubrics file removed
! test -f superpowers/skills/executing-plans/references/evaluation-rubrics.md && echo "PASS: rubrics removed"

# No broken references to removed file in executing-plans
! grep "evaluation-rubrics.md" superpowers/skills/executing-plans/SKILL.md && echo "PASS: no broken refs in executing-plans"

# Writing-plans references updated
grep -c "checklist" superpowers/skills/writing-plans/SKILL.md | xargs test 0 -lt && echo "PASS: writing-plans uses checklist"

# Writing-plans rubrics file updated
grep -c "checklist\|PASS.*FAIL\|binary" superpowers/skills/writing-plans/references/evaluation-rubrics.md | xargs test 0 -lt && echo "PASS: writing-plans rubrics updated"
```

## Success Criteria

- `executing-plans/references/evaluation-rubrics.md` deleted
- No broken references to the removed file in executing-plans/SKILL.md
- executing-plans/SKILL.md uses "checklist" terminology
- writing-plans/SKILL.md evaluator references updated for checklist approach
- writing-plans/references/evaluation-rubrics.md content updated (binary checklist, not 1-5 scoring)
