# Task 019: Executing-Plans Touchpoints Impl (GREEN)

**depends-on**: ["018"]

## BDD Scenario

```gherkin
Scenario: executing-plans SKILL.md has both touchpoints wired
  Given the tests from task 018 exist and currently FAIL
  When skills/executing-plans/SKILL.md is edited
  Then all executing-plans touchpoint tests PASS
```

## Interfaces

```bash
# Frontmatter: append "Bash(${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh:*)" to allowed-tools
# Initialization step 1: consult-before + refuse-on-expired + rework-flip-to-wip
# Phase 5: post-commit set-status + dedicated tiny index commit (Option B)
```

## Files

- `skills/executing-plans/SKILL.md` (edit)

## Steps

1. Add the `docs-index.sh:*` entry to `allowed-tools`.
2. Extend Initialization step 1 ("Plan Check") with: "Consult the docs index: `bash "${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh" show <plan-path>`. If status is `expired:`, REFUSE. If status is `implemented:<old-sha>` (rework after ship), run `set-status <plan-path> "wip"` BEFORE spawning batch 1."
3. Add Phase 5 post-commit step: "After the implementation commit lands, flip the plan's index row: `bash "${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh" set-status <plan-path> "implemented:$(git rev-parse --short HEAD)"`. Then commit the index update: `git-agent commit --no-stage --intent "mark <plan> implemented in docs index"`. NEVER use `--amend` — it would rewrite history and confuse the Stop hook's `completion_commit` detection."
4. Match existing tone; mark the set-status step CRITICAL do-not-defer.

## Verification

```bash
cd /Users/FradSer/Developer/FradSer/dotclaude/superpowers
bash tests/test-skill-touchpoints.sh
python3 plugin-optimizer/scripts/validate-plugin.py superpowers --check=frontmatter
```

**Covers design scenarios (verbatim titles):**
