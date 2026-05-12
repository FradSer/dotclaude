# Task 006: Migrate retrospective Phase 5c (Harness Observations) — Implementation (Green)

**depends-on**: task-006-migrate-phase5c-test

## Description

Edit `superpowers/skills/retrospective/SKILL.md` Phase 5c so the inline `jq -nc ... >> docs/retros/harness-observations.jsonl` `bash` block is replaced by a `bash "${CLAUDE_PLUGIN_ROOT}/lib/observations.sh"` invocation per refusal-gate sub-case (`component_unsupported`, `component_unknown`). The `harness-config.json` write that lives alongside the NDJSON append remains untouched — only the NDJSON path migrates.

## Execution Context

**Task Number**: 006 of 21
**Phase**: Migration of retrospective SKILL.md
**Prerequisites**: Task 006 test ships textual RED + behavioral GREEN checks.

## BDD Scenario

See `task-006-migrate-phase5c-test.md`. Plus architectural cross-reference from `_index.md:373–384` ("Migrate `retrospective` Phase 5c").

**Spec Source**: `../2026-05-12-unified-retro-events-design/bdd-specs.md` §5.19; `../2026-05-12-unified-retro-events-design/_index.md` Migration order step 5.

## Files to Modify/Create

- Modify: `superpowers/skills/retrospective/SKILL.md` Phase 5c section.

## Steps

### Step 1: Locate Phase 5c
- Open `superpowers/skills/retrospective/SKILL.md`; locate the Phase 5c section. The refusal-gate prose anchor begins at the CRITICAL refusal-gate description; the inline `jq -nc ... >> docs/retros/harness-observations.jsonl` invocation is the migration target.

### Step 2: Replace the Inline Block — `component_unsupported` case
- Replace the inline `jq -nc ... >> docs/retros/harness-observations.jsonl` with:
  ```
  bash "${CLAUDE_PLUGIN_ROOT}/lib/observations.sh" \
    component_unsupported \
    '{component:$c, retrospective_id:$r}' \
    --arg c "<component-id>" \
    --arg r "<retrospective-report-path>"
  ```
- Keep the surrounding prose explaining when the refusal fires (this is the load-bearing CRITICAL marker; do not strip it).

### Step 3: Replace the Inline Block — `component_unknown` case
- Same shape; first arg becomes `component_unknown`.

### Step 4: Verify the `harness-config.json` Write Path is Untouched
- The Phase 5c section also writes to `harness-config.json` (separate file, not a `channel`). Confirm that path is unchanged — only the jsonl append migrates.

### Step 5: Preserve the CRITICAL Marker
- Per `feedback_skill_level_enforcement.md`, the L2 SKILL.md's CRITICAL refusal-gate marker must survive this refactor. Re-read the section after editing; confirm the marker (the bold/uppercase prose declaring the refusal-gate as CRITICAL) is intact.

### Step 6: Run Tests (Green)
- Run Task 006's test module; the textual TestCase now passes; the behavioral TestCase remains passing.
- Run the full superpowers test suite; assert no regression.

### Step 7: Manual Spot-Check
- Render the migrated section in a markdown viewer (or `glow` if available) to confirm prose flow and code-block fencing are intact.

## Verification Commands

```bash
cd /Users/FradSer/Developer/FradSer/dotclaude
python3 -m pytest superpowers/tests/test_migration_parity.py::RetrospectiveMigrationPhase5cTests -v 2>&1 | tail -30
# Expect: all PASS
python3 -m pytest superpowers/tests/ -q 2>&1 | tail -10
# Expect: full suite still green
```

## Success Criteria

- Task 006's textual TestCase passes (Green).
- No occurrence of `>> docs/retros/harness-observations.jsonl` remains in `skills/retrospective/SKILL.md`.
- Two helper invocations appear in Phase 5c, one per refusal-gate event kind.
- Full superpowers test suite remains green.
- The Phase 5c CRITICAL refusal-gate prose is preserved.
