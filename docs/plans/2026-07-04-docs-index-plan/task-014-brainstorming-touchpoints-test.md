# Task 014: Brainstorming Touchpoints Test (RED)

**depends-on**: ["007"]

## BDD Scenario

```gherkin
Scenario: Brainstorming consult-before reads the index in Initialization
  Given the brainstorming SKILL.md exists
  When its Initialization step 2 is examined
  Then it contains a directive to run lib/docs-index.sh list --kind design --status active and list --status expired
  And it contains a directive to treat expired: conclusions as non-authoritative
  And the allowed-tools frontmatter includes "Bash(${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh:*)"

Scenario: Brainstorming upsert-after in Phase 3 Wrap-up
  Given the brainstorming SKILL.md exists
  When its Phase 3 step 0 is examined
  Then it contains a directive to run upsert design <new-path> --status active --summary "<one-line>"
  And it contains a directive to set-status <prior-path> "superseded-by:<new-path>" when superseding a prior active design

Scenario: Same-day folder-name collision disambiguation
  Given brainstorming has already committed docs/plans/2026-07-04-feature-X-design/ today
  When brainstorming commits a second distinct design for the same topic on the same day
  Then the second folder is named docs/plans/2026-07-04-feature-X-design-2/
  And the SKILL.md documents the -2 suffix disambiguation rule
```

**Covers design scenarios (verbatim titles):**
- "Consult-before — prior active design on the same topic is superseded"
- "Consult-before — prior design already expired is not trusted"
- "Two designs on the same day and same topic get distinct folder names"
- "Every mutating skill consults before it mutates"

## Interfaces

```bash
# SKILL.md frontmatter addition (allowed-tools array):
#   "Bash(${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh:*)"
# SKILL.md body additions:
#   - Initialization step 2: consult-before directives
#   - Phase 3 step 0: upsert-after directives
#   - Phase 1 or a footnote: same-day -2 suffix rule
```

## Files

- `tests/test-skill-touchpoints.sh` (new) — a grep-based test that asserts the SKILL.md files contain the required directives
- `skills/brainstorming/SKILL.md` (read-only here; edited in task 015)

## Steps

1. Write a `tests/test-skill-touchpoints.sh` that greps `skills/brainstorming/SKILL.md` for: (a) the `docs-index.sh:*` allowed-tools entry, (b) a `list --kind design` consult-before directive, (c) an `upsert design` upsert-after directive, (d) the `-design-2/` disambiguation rule.
2. Run it — all assertions FAIL (the SKILL.md hasn't been edited yet).

## Verification

```bash
cd /Users/FradSer/Developer/FradSer/dotclaude/superpowers
bash tests/test-skill-touchpoints.sh
# Expect: brainstorming assertions FAIL (RED)
```
