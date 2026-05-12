# Task 007: Migrate retrospective Phase 4 (Item Events) — Implementation (Green)

**depends-on**: task-007-migrate-phase4-items-test

## Description

Edit `retrospective/SKILL.md` Phase 4 to replace the inline `jq -nc ... >> docs/retros/evolution-log.jsonl` blocks with one or more `bash "${CLAUDE_PLUGIN_ROOT}/lib/evolution-log.sh" <item_event> ...` invocations covering all four item-event kinds (`item_added`, `item_removed`, `item_modified`, `item_promoted`).

## Execution Context

**Task Number**: 007 of 21
**Phase**: Migration of retrospective SKILL.md
**Prerequisites**: Task 007 test is RED; Task 006 impl already merged the Phase 5c migration (sequential edit on same file).

## BDD Scenario

See `task-007-migrate-phase4-items-test.md`.

**Spec Source**: `../2026-05-12-unified-retro-events-design/_index.md` Migration order step 6 (item-events portion).

## Files to Modify/Create

- Modify: `superpowers/skills/retrospective/SKILL.md` Phase 4 section.

## Steps

### Step 1: Locate Phase 4 Proposal-Emit Block
- Open SKILL.md; locate the Phase 4 section. The text "Append one JSON object per approved proposal to `docs/retros/evolution-log.jsonl`" is the anchor.

### Step 2: Replace the Inline Block
- Per `architecture.md:236–243`, the canonical replacement for `item_added` is:
  ```
  bash "${CLAUDE_PLUGIN_ROOT}/lib/evolution-log.sh" \
    item_added '{mode: $mode, item_id: $id, description: $d, rationale: $r,
                 driving_plans: $plans, checklist_version: $v,
                 retrospective_report: $report}' \
    --arg mode "$MODE" --arg id "$ITEM_ID" --arg d "$DESC" \
    --arg r "$RATIONALE" --argjson plans "$PLANS_JSON" \
    --arg v "$VERSION" --arg report "$REPORT"
  ```
- Replicate the same block shape for `item_removed`, `item_modified`, `item_promoted` — either as four parallel examples or one templated example with a per-kind table of differences. Choose whichever produces the clearest L2 instruction for Claude executing the skill (the L2 prose tradeoff between repetition and clarity is the L2 author's call; the test asserts all four kinds are mentioned).

### Step 3: Preserve the Reference Cross-Link
- The line `See ./references/evolution-protocol.md for schema.` must remain — that file is the schema source of truth. The helper transports; it does not validate.

### Step 4: Verify Tests
- Run Task 007's test module; all textual tests pass.
- Run the full suite; no regressions.

### Step 5: Manual Spot-Check
- Render the migrated section; confirm prose remains coherent (no orphaned sentences, no broken markdown).

## Verification Commands

```bash
cd /Users/FradSer/Developer/FradSer/dotclaude
python3 -m pytest superpowers/tests/test_migration_parity.py::RetrospectiveMigrationPhase4ItemsTests -v 2>&1 | tail -30
python3 -m pytest superpowers/tests/ -q 2>&1 | tail -10
```

## Success Criteria

- Task 007's textual TestCase passes (Green).
- All four item-event kinds appear in Phase 4 as helper invocation `<event_type>` args.
- The `evolution-protocol.md` cross-link is preserved.
- Full suite remains green.
