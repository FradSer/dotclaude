# Task 021: Retrospective Touchpoints Impl (GREEN)

**depends-on**: ["020"]

## BDD Scenario

```gherkin
Scenario: retrospective SKILL.md has all three touchpoints wired
  Given the tests from task 020 exist and currently FAIL
  When skills/retrospective/SKILL.md is edited
  Then all retrospective touchpoint tests PASS
  And the invalidates: boundary is explicit (REMOVE does NOT trigger expiry)
```

## Interfaces

```bash
# Frontmatter: append "Bash(${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh:*)" to allowed-tools
# Phase 1 step 1: consult-before
# Phase 6 step 6: upsert retro report
# Phase 6 step 7: invalidate-after
```

## Files

- `skills/retrospective/SKILL.md` (edit)

## Steps

1. Add the `docs-index.sh:*` entry to `allowed-tools`.
2. Extend Phase 1 step 1 ("Resolve inputs") with: "Consult the docs index: `bash "${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh" list --kind plan --status implemented` to scope plans for analysis (complements the existing `plans-completed.jsonl` read). Also `list --status expired` to surface prior expirations as calibration input."
3. Add Phase 6 step 6 (after the existing summary step): "Upsert the retro report into the docs index: `bash "${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh" upsert retro <retro-report-path> --status active --summary "<one-line>"`."
4. Add Phase 6 step 7 (invalidate-after): "For each `invalidates: <path>` line in the just-written retro report, run `bash "${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh" set-status <path> "expired:retro-<date>:<reason>"`. If `set-status` exits 3 (path not tracked), log a warning and skip — do NOT upsert speculative entries. CRITICAL boundary: a Phase 3 REMOVE proposal on a checklist item does NOT trigger `set-status` on a design — only an explicit `invalidates: <path>` line in the retro report triggers expiry. Expiry is retrospective-only; the other three skills may not set `expired:`."
5. Match existing tone; mark step 7 CRITICAL.

## Verification

```bash
cd /Users/FradSer/Developer/FradSer/dotclaude/superpowers
bash tests/test-skill-touchpoints.sh
python3 plugin-optimizer/scripts/validate-plugin.py superpowers --check=frontmatter
```

**Covers design scenarios (verbatim titles):**
- "Retrospective invalidates a design and records its own report"
- "Retrospective does not expire an already-implemented plan"
- "A retrospective REMOVE proposal does not invalidate a design"
- "Invalidation requires the path to already be tracked"
