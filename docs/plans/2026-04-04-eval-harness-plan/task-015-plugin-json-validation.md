# Task 015: Update plugin.json and validate plugin

**depends-on**: task-011, task-013, task-014

## Description

Add the retrospective skill as a user-invocable command in the superpowers plugin.json. Run the plugin validation script to confirm the entire plugin structure is valid after all changes.

## Execution Context

**Task Number**: 015 of 015
**Phase**: Refinement
**Prerequisites**: Phase 4 intra-plan learning complete (task-011), retrospective skill complete (task-013), all references updated (task-014)

## BDD Scenario

```gherkin
Scenario: Plugin manifest includes retrospective command and passes validation
  Given superpowers/skills/retrospective/SKILL.md exists
  And the retrospective skill has user-invocable: true in frontmatter
  When plugin.json is updated and validation runs
  Then the commands array includes "./skills/retrospective/"
  And python3 plugin-optimizer/scripts/validate-plugin.py superpowers/ exits with code 0
  And the plugin structure is valid with no MUST violations
```

**Spec Source**: `../2026-04-03-eval-harness-design/architecture.md` (Plugin.json Changes section)

## Files to Modify/Create

- Modify: `superpowers/.claude-plugin/plugin.json`

## Steps

### Step 1: Add retrospective to commands

Add `"./skills/retrospective/"` to the `commands` array in plugin.json. The resulting commands array should be:

```json
"commands": [
  "./skills/brainstorming/",
  "./skills/writing-plans/",
  "./skills/executing-plans/",
  "./skills/need-vet/",
  "./skills/retrospective/"
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
# Retrospective in commands array
grep -c "retrospective" superpowers/.claude-plugin/plugin.json | xargs test 0 -lt && echo "PASS: retrospective in plugin.json"

# Full plugin validation
python3 plugin-optimizer/scripts/validate-plugin.py superpowers/
echo "Exit code: $?"
```

## Success Criteria

- `plugin.json` commands array includes `"./skills/retrospective/"`
- `python3 plugin-optimizer/scripts/validate-plugin.py superpowers/` exits with code 0
- No MUST violations or token budget critical warnings
