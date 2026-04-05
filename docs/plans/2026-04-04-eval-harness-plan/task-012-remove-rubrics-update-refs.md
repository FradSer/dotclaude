# Task 012: Remove old rubrics and update cross-references

**depends-on**: task-010

## Description

Remove the now-obsolete `evaluation-rubrics.md` from executing-plans references and update all cross-references in executing-plans, writing-plans, AND brainstorming skills. The writing-plans and brainstorming evaluation rubrics files should be updated to reflect the new binary checklist approach used by the evaluator. Scope covers ALL three skills that reference rubrics -- not just executing-plans and writing-plans.

## Execution Context

**Task Number**: 012 of 013
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
- Modify: `superpowers/skills/brainstorming/SKILL.md` (update evaluator references in Phase 4)
- Modify: `superpowers/skills/brainstorming/references/evaluation-rubrics.md` (update content for checklist approach)

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
- Rename the file content to reflect "Plan Evaluation Checklist Reference" (keep the filename for backward compatibility, or rename if references are updated)

### Step 5: Update brainstorming/SKILL.md evaluator references

Update Phase 4 (Design Reflection) references:
- Replace "scoring criteria" with "checklist evaluation"
- Update references to evaluation-rubrics.md to point to checklist documentation
- Ensure the evaluator spawn description in Evaluator Mode section mentions checklist path

### Step 6: Update brainstorming/references/evaluation-rubrics.md

Update this file to describe the new binary checklist approach:
- Replace 1-5 scoring dimensions with references to design checklist items
- Update the verdict rules to PASS/FAIL (not score-based)
- Rename content to reflect "Design Evaluation Checklist Reference"

### Step 7: Update output responsibility in writing-plans and brainstorming

Both writing-plans/SKILL.md and brainstorming/SKILL.md currently imply the evaluator produces and writes report files directly. Update these to match the output responsibility protocol from task-008:
- The evaluator outputs report content as text in its response
- The parent skill (writing-plans or brainstorming) is responsible for writing the evaluator's output to disk
- Update any language like "evaluator produces a report in the folder" to "evaluator produces report content; the skill writes it to disk"

### Step 8: Verify all references updated

Scan ALL THREE skills (executing-plans, writing-plans, brainstorming) for any remaining references to rubric scoring or incorrect output responsibility.

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

# Brainstorming references updated
grep -c "checklist" superpowers/skills/brainstorming/SKILL.md | xargs test 0 -lt && echo "PASS: brainstorming uses checklist"

# Brainstorming rubrics file updated
grep -c "checklist\|PASS.*FAIL\|binary" superpowers/skills/brainstorming/references/evaluation-rubrics.md | xargs test 0 -lt && echo "PASS: brainstorming rubrics updated"

# No rubric scoring language in any of the three skills
! grep -r "1-5\|rubric.*scor\|dimension.*score" superpowers/skills/{executing-plans,writing-plans,brainstorming}/SKILL.md && echo "PASS: no rubric scoring in any skill"
```

## Success Criteria

- `executing-plans/references/evaluation-rubrics.md` deleted
- No broken references to the removed file in executing-plans/SKILL.md
- executing-plans/SKILL.md uses "checklist" terminology
- writing-plans/SKILL.md evaluator references updated for checklist approach
- writing-plans/references/evaluation-rubrics.md content updated (binary checklist, not 1-5 scoring)
- brainstorming/SKILL.md evaluator references updated for checklist approach
- brainstorming/references/evaluation-rubrics.md content updated (binary checklist, not 1-5 scoring)
- No rubric scoring language remains in any of the three skills
