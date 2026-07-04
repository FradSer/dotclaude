# Task 016: Writing-Plans Touchpoints Test (RED)

**depends-on**: ["007"]

## BDD Scenario

```gherkin
Scenario: writing-plans consult-before refuses an expired design
  Given the writing-plans SKILL.md exists
  When its Initialization step 1 is examined
  Then it contains a directive to run lib/docs-index.sh show <design-path>
  And it contains a directive to refuse if the status is expired: (mirroring the JUST-01 refusal pattern)

Scenario: writing-plans upsert-after records a plan
  Given the writing-plans SKILL.md exists
  When its Phase 5 step 0 is examined
  Then it contains a directive to run upsert plan <new-plan-path> --status active --summary "<one-line>"
  And the allowed-tools frontmatter includes "Bash(${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh:*)"
```

**Covers design scenarios (verbatim titles):**
- "Upsert-after — writing-plans records a new plan"
- "writing-plans consult-before refuses an expired design"

## Interfaces

```bash
# SKILL.md frontmatter addition:
#   "Bash(${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh:*)"
# SKILL.md body additions:
#   - Initialization step 1: consult-before + refuse-on-expired
#   - Phase 5 step 0: upsert-after
```

## Files

- `tests/test-skill-touchpoints.sh` — append writing-plans assertions
- `skills/writing-plans/SKILL.md` (read-only here; edited in task 017)

## Steps

1. Append grep assertions to `tests/test-skill-touchpoints.sh` for: (a) the docs-index.sh allowed-tools entry, (b) a `show <design-path>` consult-before directive, (c) a refuse-on-expired directive, (d) an `upsert plan` upsert-after directive.
2. Run — FAIL.

## Verification

```bash
cd /Users/FradSer/Developer/FradSer/dotclaude/superpowers
bash tests/test-skill-touchpoints.sh
# Expect: writing-plans assertions FAIL (RED)
```
