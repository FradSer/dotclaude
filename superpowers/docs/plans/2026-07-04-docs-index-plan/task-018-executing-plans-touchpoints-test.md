# Task 018: Executing-Plans Touchpoints Test (RED)

**depends-on**: ["009"]

## BDD Scenario

```gherkin
Scenario: executing-plans consult-before reads the index in Initialization
  Given the executing-plans SKILL.md exists
  When its Initialization step 1 is examined
  Then it contains a directive to run lib/docs-index.sh show <plan-path>
  And it contains a directive to refuse if status is expired:
  And it contains a directive to flip implemented:<old-sha> to wip before batch 1 (rework after ship)
  And the allowed-tools frontmatter includes "Bash(${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh:*)"

Scenario: executing-plans flips plan to implemented at Phase 5
  Given the executing-plans SKILL.md exists
  When its Phase 5 step 0 is examined
  Then it contains a directive to run set-status <plan-path> "implemented:<short-sha>"
  And the SHA is captured as $(git rev-parse --short HEAD) AFTER the implementation commit
  And a dedicated tiny index commit follows (no --amend)

Scenario: Rework after ship flips implemented back to wip
  Given the index contains a plan with status=implemented:abc1234
  When executing-plans is re-invoked on that plan
  Then the consult-before step flips it to wip before spawning batch 1
  And on re-completion it is set to implemented:<new-sha>
```

**Covers design scenarios (verbatim titles):**
- "executing-plans marks the plan implemented at Phase 5 commit"
- "executing-plans rework flips implemented back to wip"

## Interfaces

```bash
# Frontmatter: append "Bash(${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh:*)"
# Initialization step 1: consult-before + refuse-on-expired + rework-flip-to-wip
# Phase 5: post-commit set-status + dedicated index commit (Option B from architecture.md)
```

## Files

- `tests/test-skill-touchpoints.sh` — append executing-plans assertions
- `skills/executing-plans/SKILL.md` (read-only here; edited in task 019)

## Steps

1. Append grep assertions for: (a) docs-index.sh allowed-tools, (b) `show <plan-path>` consult-before, (c) refuse-on-expired, (d) rework-flip-to-wip, (e) `set-status` implemented flip, (f) the no-`--amend` rule.
2. Run — FAIL.

## Verification

```bash
cd /Users/FradSer/Developer/FradSer/dotclaude/superpowers
bash tests/test-skill-touchpoints.sh
# Expect: executing-plans assertions FAIL (RED)
```
