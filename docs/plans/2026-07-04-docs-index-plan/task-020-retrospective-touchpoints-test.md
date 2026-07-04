# Task 020: Retrospective Touchpoints Test (RED)

**depends-on**: ["009"]

## BDD Scenario

```gherkin
Scenario: Retrospective consult-before reads the index in Phase 1
  Given the retrospective SKILL.md exists
  When its Phase 1 step 1 is examined
  Then it contains a directive to run lib/docs-index.sh list --kind plan --status implemented
  And a directive to run list --status expired for calibration input
  And the allowed-tools frontmatter includes "Bash(${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh:*)"

Scenario: Retrospective upsert-after records its own report
  Given the retrospective SKILL.md exists
  When its Phase 6 step 6 is examined
  Then it contains a directive to run upsert retro <retro-report-path> --status active --summary "<one-line>"

Scenario: Retrospective invalidate-after reads invalidates: lines
  Given the retrospective SKILL.md exists
  When its Phase 6 step 7 is examined
  Then it contains a directive to grep invalidates: <path> lines from the just-written retro report
  And for each, run set-status <path> "expired:retro-<date>:<reason>"
  And the directive states that the path MUST already be tracked (exit 3 = skip with warning)

Scenario: A REMOVE proposal does NOT invalidate a design
  Given the retrospective SKILL.md exists
  When its Phase 6 step 7 is examined
  Then it explicitly states that a Phase 3 REMOVE proposal on a checklist item does NOT trigger set-status on a design
  And only an explicit invalidates: <path> line triggers expiry

Scenario: Invalidation requires the path to already be tracked
  Given a retro report contains invalidates: docs/plans/never-tracked-design/
  When the invalidate-after step runs set-status on that path
  Then the script exits 3 and the skill logs a warning and skips
```

**Covers design scenarios (verbatim titles):**
- "Retrospective invalidates a design and records its own report"
- "Retrospective does not expire an already-implemented plan"
- "A retrospective REMOVE proposal does not invalidate a design"
- "Invalidation requires the path to already be tracked"

## Interfaces

```bash
# Frontmatter: append "Bash(${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh:*)" to allowed-tools
# Phase 1 step 1: consult-before
# Phase 6 step 6: upsert retro report
# Phase 6 step 7: invalidate-after (grep invalidates: lines, call set-status, handle exit 3)
```

## Files

- `tests/test-skill-touchpoints.sh` — append retrospective assertions
- `skills/retrospective/SKILL.md` (read-only here; edited in task 021)

## Steps

1. Append grep assertions for: (a) docs-index.sh allowed-tools, (b) `list --kind plan --status implemented` consult-before, (c) `upsert retro` upsert-after, (d) `invalidates:` grep directive in step 7, (e) the "REMOVE does NOT invalidate" boundary statement, (f) the exit-3-skip-with-warning handling.
2. Run — FAIL.

## Verification

```bash
cd /Users/FradSer/Developer/FradSer/dotclaude/superpowers
bash tests/test-skill-touchpoints.sh
# Expect: retrospective assertions FAIL (RED)
```
