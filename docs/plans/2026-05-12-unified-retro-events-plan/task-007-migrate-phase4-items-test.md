# Task 007: Migrate retrospective Phase 4 (Item Events) — Tests (Red)

**depends-on**: task-005-evolution-log-impl, task-006-migrate-phase5c-impl

## Description

Write failing textual-contract tests for the migration of `retrospective` Phase 4 — the section that emits `item_added` / `item_removed` / `item_modified` / `item_promoted` per approved proposal. The migration replaces the inline `jq -nc ... >> docs/retros/evolution-log.jsonl` block(s) with a `bash "${CLAUDE_PLUGIN_ROOT}/lib/evolution-log.sh" item_added ...` invocation per event kind.

Sequenced AFTER Task 006 impl because both edits target the same file (`retrospective/SKILL.md`); back-to-back sequencing eliminates merge conflicts. Phase 6 migration (Task 008) follows the same pattern; that task likewise depends on this one finishing.

## Execution Context

**Task Number**: 007 of 21
**Phase**: Migration of retrospective SKILL.md
**Prerequisites**: Tasks 005 impl (helper exists), 006 impl (Phase 5c migration landed first).

## BDD Scenario

```gherkin
Scenario: existing evolution-log.jsonl rows are not rewritten
  Given a project with legacy item_added / item_removed / retrospective_run rows in docs/retros/evolution-log.jsonl
  When log_evolution_event appends a new row
  Then prior rows are byte-unchanged
  And the consumer in retrospective Phase 1 step 5 (per-item_id history table) reads the file as a single homogeneous stream
```

**Spec Source**: `../2026-05-12-unified-retro-events-design/bdd-specs.md` §5.20; `../2026-05-12-unified-retro-events-design/_index.md` Migration order step 6 (sub-step covering Phase 4 item events).

## Files to Modify/Create

- Modify: `superpowers/tests/test_migration_parity.py` (extend with a new TestCase; do not touch existing TestCases from Task 006).

## Steps

### Step 1: TestCase — `RetrospectiveMigrationPhase4ItemsTests`
- `test_phase_4_invokes_evolution_log_helper` — read SKILL.md; locate the Phase 4 proposal-emit section (anchor on prose like "Append one JSON object per approved proposal" or the existing reference to `./references/evolution-protocol.md`); assert the new invocation string `bash "${CLAUDE_PLUGIN_ROOT}/lib/evolution-log.sh"` appears in Phase 4.
- `test_phase_4_no_inline_jq_to_evolution_log` — assert no occurrence of `>> docs/retros/evolution-log.jsonl` remains in Phase 4 (or anywhere in SKILL.md — Phase 6 still has it at this point but Task 008 will remove it). Scope this test to the Phase 4 section only by splitting SKILL.md text on the Phase 5 heading.
- `test_phase_4_covers_all_four_item_event_kinds` — assert the four event names (`item_added`, `item_removed`, `item_modified`, `item_promoted`) appear within Phase 4 as positional `<event_type>` args to the helper. If the SKILL.md uses a single templated invocation with `$EVENT_TYPE` as the arg, accept the templated form by asserting all four kinds appear as concrete strings somewhere in the section's prose or `bash` blocks (the L2 instruction must communicate which event kinds are valid).
- `test_phase_4_preserves_required_payload_fields` — assert the helper invocation in Phase 4 includes `--arg`/`--argjson` pairs for each required field in the `item_added` schema (`mode`, `item_id`, `description`, `rationale`, `driving_plans`, `checklist_version`, `retrospective_report`). Use substring matching on `--arg mode`, `--arg id`, etc. The test guards against the migration accidentally dropping a payload field.

### Step 2: Behavioral Companion (passes already since Task 005 ships)
- `test_helper_appends_to_existing_evolution_log_unchanged` — covered by `test_evolution_log_sh.py::EvolutionLogBackwardCompatTests::test_existing_rows_not_rewritten` (Task 005). No duplication here.

### Step 3: Confirm RED
- All textual tests in this new TestCase fail until SKILL.md is migrated.

## Verification Commands

```bash
cd /Users/FradSer/Developer/FradSer/dotclaude
python3 -m pytest superpowers/tests/test_migration_parity.py::RetrospectiveMigrationPhase4ItemsTests -v 2>&1 | tail -30
# Expect: all FAIL
```

## Success Criteria

- ≥ 4 failing tests in `RetrospectiveMigrationPhase4ItemsTests`.
- Each test anchors a different aspect: invocation presence, legacy pattern absence, event-kind coverage, payload-field coverage.
