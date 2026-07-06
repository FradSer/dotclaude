# Task 017: Writing-Plans Touchpoints Impl (GREEN)

**depends-on**: ["016"]

## BDD Scenario

```gherkin
Scenario: writing-plans SKILL.md has both touchpoints wired
  Given the tests from task 016 exist and currently FAIL
  When skills/writing-plans/SKILL.md is edited
  Then all writing-plans touchpoint tests PASS
```

## Interfaces

```bash
# Frontmatter: append "Bash(${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh:*)" to allowed-tools
# Initialization step 1: consult-before + refuse-on-expired
# Phase 5 step 0: upsert-after (before git add)
```

## Files

- `skills/writing-plans/SKILL.md` (edit)

## Steps

1. Add the `docs-index.sh:*` entry to `allowed-tools`.
2. Extend Initialization step 1 ("Design Check") with: "Consult the docs index: `bash "${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh" show <design-path>`. If the status is `expired:`, REFUSE to proceed — the design's conclusions are invalidated. Mirror the JUST-01 refusal: output a one-line note citing the expired status and exit; do not create a plan folder."
3. Add Phase 5 step 0 (before `git add`): "Upsert the plan into the docs index: `bash "${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh" upsert plan <new-plan-path> --status active --summary "<one-line>"`. CRITICAL do-not-defer — the index update lands in the same commit-group as the plan folder."
4. Match existing tone.

## Verification

```bash
cd /Users/FradSer/Developer/FradSer/dotclaude/superpowers
bash tests/test-skill-touchpoints.sh
python3 plugin-optimizer/scripts/validate-plugin.py superpowers --check=frontmatter
```

**Covers design scenarios (verbatim titles):**
