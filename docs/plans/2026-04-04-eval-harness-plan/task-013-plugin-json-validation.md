# Task 013: Update plugin.json and validate plugin

**depends-on**: task-011, task-012

## Description

Run the plugin validation script to confirm the entire plugin structure is valid after all evaluator and skill updates.

## Execution Context

**Task Number**: 013 of 013
**Phase**: Refinement
**Prerequisites**: Phase 4 intra-plan learning complete (task-011), all references updated (task-012).

## BDD Scenario

```gherkin
Scenario: Plugin passes validation after evaluator and skill updates
  Given superpowers-evaluator.md has been updated to binary checklist format
  And executing-plans, writing-plans, and brainstorming skills have updated references
  When plugin validation runs
  Then python3 plugin-optimizer/scripts/validate-plugin.py superpowers/ exits with code 0
  And the plugin structure is valid with no MUST violations
  And no broken references to removed evaluation-rubrics.md files
```

**Spec Source**: `../2026-04-03-eval-harness-design/architecture.md` (Plugin.json Changes section)

## Files to Modify/Create

- Modify: `superpowers/.claude-plugin/plugin.json`

## Steps

### Step 1: Verify plugin.json commands array

Confirm the commands array is unchanged:

```json
"commands": [
  "./skills/brainstorming/",
  "./skills/writing-plans/",
  "./skills/executing-plans/",
  "./skills/need-vet/"
]
```

### Step 2: Run plugin validation

Run the full validation script to confirm all plugin components are valid:
- Structure checks
- Manifest checks
- Frontmatter checks
- Token budget checks

### Step 3: Fix any validation issues

If validation reports MUST violations or token budget critical (exit code 1 or 2), fix the issues before completing.

## Verification Commands

```bash
# Full plugin validation
python3 plugin-optimizer/scripts/validate-plugin.py superpowers/
echo "Exit code: $?"

# No broken references to removed files
! grep -r "evaluation-rubrics.md" superpowers/skills/executing-plans/SKILL.md && echo "PASS: no broken refs"

# Evaluator uses checklist terminology
grep -c "checklist\|PASS.*FAIL" superpowers/agents/superpowers-evaluator.md | xargs test 0 -lt && echo "PASS: evaluator updated"
```

## Success Criteria

- `python3 plugin-optimizer/scripts/validate-plugin.py superpowers/` exits with code 0
- No MUST violations or token budget critical warnings
- No broken references to removed evaluation-rubrics.md files
- Evaluator agent uses binary checklist terminology (no 1-5 scoring)
