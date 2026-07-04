# Task 015: Brainstorming Touchpoints Impl (GREEN)

**depends-on**: ["014"]

## BDD Scenario

```gherkin
Scenario: Brainstorming SKILL.md has both touchpoints wired
  Given the tests from task 014 exist and currently FAIL
  When skills/brainstorming/SKILL.md is edited
  Then all brainstorming touchpoint tests PASS
  And the allowed-tools array includes the docs-index.sh scope
  And Initialization step 2 has the consult-before directive
  And Phase 3 step 0 has the upsert-after directive
  And the same-day -2 suffix rule is documented
```

## Interfaces

```bash
# Frontmatter addition to skills/brainstorming/SKILL.md allowed-tools:
#   append "Bash(${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh:*)"
# Body additions:
#   Initialization step 2 — extend "Read project context" to also consult the index
#   Phase 3 Wrap-up — new step 0 before `git add`
#   Phase 1 or footnote — same-day folder-name collision rule
```

## Files

- `skills/brainstorming/SKILL.md` (edit)

## Steps

1. Add `"Bash(${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh:*)"` to the `allowed-tools` array in the frontmatter (after the `seed-checklists.sh` entry).
2. Extend Initialization step 2 ("Read project context") with a sub-step: "Consult the docs index: run `bash "${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh" list --kind design --status active` and `list --status expired`. Treat any `expired:` design's conclusions as non-authoritative — create a fresh design rather than extending an expired one."
3. Add Phase 3 Wrap-up step 0 (before the existing `git add`): "Upsert the design into the docs index: `bash "${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh" upsert design <new-design-path> --status active --summary "<one-line>"`. If a prior active design on the same topic exists and is being replaced, first `set-status <prior-path> "superseded-by:<new-path>"`."
4. Document the same-day folder-name collision rule in Phase 1 or a References footnote: "If committing a second distinct design for the same topic on the same day, disambiguate the folder name with a `-2` suffix: `docs/plans/YYYY-MM-DD-<topic>-design-2/`."
5. Match the existing SKILL.md tone (imperative, CRITICAL markers where discipline is load-bearing — e.g., the upsert-after step should be marked CRITICAL do-not-defer, mirroring the evolution-log pattern in retrospective).

## Verification

```bash
cd /Users/FradSer/Developer/FradSer/dotclaude/superpowers
bash tests/test-skill-touchpoints.sh
# Expect: brainstorming assertions PASS (GREEN)
# Validate the plugin manifest still parses:
python3 plugin-optimizer/scripts/validate-plugin.py superpowers --check=frontmatter
```

**Covers design scenarios (verbatim titles):**
