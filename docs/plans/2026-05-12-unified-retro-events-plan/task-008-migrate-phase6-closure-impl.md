# Task 008: Migrate retrospective Phase 6 (retrospective_run + component_reinstated) — Implementation (Green)

**depends-on**: task-008-migrate-phase6-closure-test

## Description

Edit `retrospective/SKILL.md` Phase 6 to replace the inline `jq -nc ... >> docs/retros/evolution-log.jsonl` blocks with `bash "${CLAUDE_PLUGIN_ROOT}/lib/evolution-log.sh" retrospective_run ...` and (when reinstating a component) `... component_reinstated ...` invocations. The `consecutive_zero_change` computation logic stays in SKILL.md; only the final NDJSON append migrates.

After this task lands, the assertion "no `>> docs/retros/evolution-log.jsonl` anywhere in retrospective/SKILL.md" must hold globally.

## Execution Context

**Task Number**: 008 of 21
**Phase**: Migration of retrospective SKILL.md
**Prerequisites**: Task 008 test is RED; Task 007 impl is merged.

## BDD Scenario

See `task-008-migrate-phase6-closure-test.md`.

**Spec Source**: `../2026-05-12-unified-retro-events-design/_index.md` Migration order step 6 (closure portion).

## Files to Modify/Create

- Modify: `superpowers/skills/retrospective/SKILL.md` Phase 6 section.

## Steps

### Step 1: Locate Phase 6 Closure
- Open SKILL.md; locate the Phase 6 closure section (anchor: the `retrospective_run` event description with `consecutive_zero_change` mentioned).

### Step 2: Replace the `retrospective_run` Block

Replace the inline `jq -nc … >> docs/retros/evolution-log.jsonl` block with one `bash "${CLAUDE_PLUGIN_ROOT}/lib/evolution-log.sh" retrospective_run …` invocation. The invocation's payload-filter argument is a jq object expression that:

- Lists the required `retrospective_run` fields in declaration order (`plans_analyzed`, `report`, `proposals_approved`, `proposals_rejected`, `disable_test`, `self_value`) — match the existing schema in `superpowers/skills/retrospective/references/evolution-protocol.md` verbatim.
- Conditionally includes `post_plan_diff` only when a boolean flag the SKILL.md computes (set from "any plan in plans_analyzed has a `completion_commit`") is true. The omission mechanism uses jq's `if … then … else … end` construct around the `post_plan_diff` field so when the flag is false the helper writes a row without the `post_plan_diff` key — never a `null` (BDD §1.4 "post_plan_diff is omitted (not nullified)").
- Forwards `--argjson` for each typed value (`plans_analyzed` array, `proposals_approved`/`proposals_rejected` integers, `disable_test` null-or-string, `self_value` object, the boolean flag, and the optional `post_plan_diff` payload) and `--arg` for the single `report` string. The implementer reads the pre-migration inline `jq -nc` invocation once to inventory the existing arg pairs — the new invocation must cover the same pairs with no additions or omissions.

### Step 3: Replace the `component_reinstated` Block (if present)
- Same shape with `component_reinstated` as `<event_type>`; payload filter built from the documented fields (`component`, `previously_disabled_in`, `reinstatement_method`, nested `evidence`, `rationale`, optional `follow_up`).

### Step 4: Preserve `consecutive_zero_change` Logic
- The lines that READ the previous `retrospective_run` row and COMPUTE `consecutive_zero_change` are unchanged. Only the final write-to-disk path migrates. This is the calibration-vs-transport boundary the design draws.

### Step 5: Verify Tests
- Run Task 008's TestCase; all pass.
- Re-run Task 006 + Task 007 TestCases; all still pass (regression check).
- Run the full suite; no other failures.

### Step 6: Grep Final Verification
- `grep -n ">> docs/retros/evolution-log.jsonl" superpowers/skills/retrospective/SKILL.md` returns no output.
- `grep -n "lib/evolution-log.sh" superpowers/skills/retrospective/SKILL.md` returns at least 5 matches (item events × 4 in Phase 4 + at least one each in Phase 6 for retrospective_run and component_reinstated).

## Verification Commands

```bash
cd /Users/FradSer/Developer/FradSer/dotclaude
python3 -m pytest superpowers/tests/test_migration_parity.py -v 2>&1 | tail -30
python3 -m pytest superpowers/tests/ -q 2>&1 | tail -10
grep -n ">> docs/retros/evolution-log.jsonl" superpowers/skills/retrospective/SKILL.md   # must produce no output
```

## Success Criteria

- All tests in `test_migration_parity.py` pass.
- No `>> docs/retros/evolution-log.jsonl` substring anywhere in `retrospective/SKILL.md`.
- The conditional-`post_plan_diff` filter is present.
- Full suite green.
