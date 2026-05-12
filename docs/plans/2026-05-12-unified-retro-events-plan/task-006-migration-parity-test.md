# Task 006-test: Migration parity test (Red)

**depends-on**: task-001, task-002-impl, task-003-impl

## Description

Write `superpowers/tests/test_migration_parity.py` covering the load-bearing migration guarantee: each helper produces output **byte-for-byte equivalent** (modulo intrinsically variable fields like `timestamp`) to the pre-migration inline `bash` block captured in task 001's fixture scripts. This test is the gate for tasks 007 and 008 — the SKILL.md swaps must not proceed until parity is green.

The test also covers the cross-cutting backward-compatibility scenario §5.1 (`plans-completed.jsonl` rows are not rewritten — verified by running the full helper suite against a tempdir that contains a seeded `plans-completed.jsonl` and asserting its mtime+content are unchanged).

## Execution Context

**Task Number**: 006-test of 15
**Phase**: Migration Safety (Red)
**Prerequisites**: Fixture scripts shipped (001). Both `observations.sh` and `evolution-log.sh` shipped (002-impl, 003-impl).

## BDD Scenario

```gherkin
Scenario: Phase 5c legacy bash vs log_harness_observation produce identical channel rows
  Given a fixture `tests/fixtures/legacy-harness-observation.sh` written by the pre-migration bash block
  When the same logical event is re-emitted via `log_harness_observation` with matching args
  Then both lines have field set {event, component, timestamp, retrospective_id} with identical key order and JSON types
  And `jq -S 'del(.timestamp)'` produces byte-equal output on both lines

Scenario: Phase 6 closure legacy bash vs log_evolution_event produce identical retrospective_run rows
  Given a fixture `tests/fixtures/legacy-retrospective-run.sh` from the pre-migration Phase 6 closure
  When the same closure is re-emitted via `log_evolution_event retrospective_run ...`
  Then top-level keys match in order and nested sub-objects (self_value, post_plan_diff when present) match in key order
  And disable_test stays null or a supported identifier — never a free-text component name

Scenario: retrospective Phase 1 consumer parses old and new rows identically
  Given docs/retros/evolution-log.jsonl contains a mix of legacy and helper-emitted lines
  When retrospective Phase 1 step 5 builds the per-item_id history table
  And Pre-Check B reads consecutive_zero_change from the most recent retrospective_run
  Then no parser branches on row origin and no "schema_version" field is consulted

Scenario: existing plans-completed.jsonl rows are not rewritten
  Given a project with a populated docs/retros/plans-completed.jsonl
  When the migration is applied and any new helper runs
  Then plans-completed.jsonl is not opened for write by any of the four new helpers
  And the file's mtime is unchanged
```

**Spec Source**: `../2026-05-12-unified-retro-events-design/bdd-specs.md` §3.1, §3.2, §3.3, §5.1.

## Files to Modify/Create

- Create: `superpowers/tests/test_migration_parity.py`

## Steps

### Step 1: Verify Scenario
- Confirm scenarios listed above appear in `bdd-specs.md`.
- Confirm fixture scripts from task 001 exist and produce valid NDJSON.

### Step 2: Implement Test (Red)
- Four TestCases:
  - `class HarnessObservationParityTests(unittest.TestCase)`:
    - `test_helper_matches_legacy_bash_block_for_component_unsupported` — set up a tempdir, run `tests/fixtures/legacy-harness-observation.sh` once with fixed args + fixed timestamp, then invoke `bash lib/observations.sh` with matching args and the same fixed timestamp. Compare both lines under `jq -S 'del(.timestamp)'` → MUST be byte-equal.
    - `test_helper_matches_legacy_for_component_unknown` — same pattern with the `component_unknown` event kind.
  - `class EvolutionLogParityTests(unittest.TestCase)`:
    - `test_retrospective_run_helper_matches_legacy_bash_block` — run `tests/fixtures/legacy-retrospective-run.sh` once with a representative payload (including nested `self_value` and optional `post_plan_diff`); invoke `bash lib/evolution-log.sh retrospective_run` with matching args; assert byte-equality.
    - `test_item_added_helper_matches_legacy_bash_block` — same pattern for `item_added` via `tests/fixtures/legacy-evolution-item.sh`.
    - `test_post_plan_diff_omitted_when_absent` — invoke the helper without a `post_plan_diff` arg; assert the produced line has NO `post_plan_diff` key at all (not even nulled). Mirrors §1.4's "omitted, not nullified" requirement.
  - `class MixedStreamConsumerTests(unittest.TestCase)`:
    - `test_consumer_parses_mixed_stream_identically` — build `evolution-log.jsonl` with `[legacy_row, helper_row, legacy_row]` (alternating). Run a minimal Python re-implementation of retrospective Phase 1 step 5 (group by `item_id`, take the latest per group). Assert all three rows contribute and the grouping result has no branching on row origin.
    - `test_consumer_reads_consecutive_zero_change_from_either_origin` — seed a `retrospective_run` row via the helper, then via the legacy script (or vice versa). Run the Pre-Check B equivalent (read most recent `retrospective_run`, extract `self_value.consecutive_zero_change`). Assert the value matches regardless of which row was most recent.
  - `class PlansCompletedUntouchedTests(unittest.TestCase)`:
    - `test_no_helper_writes_to_plans_completed_jsonl` — pre-seed `docs/retros/plans-completed.jsonl` with a known row + record `stat.st_mtime`. Invoke each of the three new helpers with valid args (each writes its own channel). After all three invocations, assert `plans-completed.jsonl` still has the seeded content and its `st_mtime` matches the pre-invocation value.
- **PROHIBITED**: do not modify any production code in this task.

### Step 3: Verify Test Fails (Red)
- Run `cd superpowers && python3 -m unittest tests.test_migration_parity -v`.
- **Expected failure modes**: subtle key-order mismatches (jq's `{}` literal order vs the helper's merged-envelope order), or `post_plan_diff: null` rather than omission. These are exactly the cases 006-impl will fix.

## Verification Commands

```bash
cd /Users/FradSer/Developer/FradSer/dotclaude/superpowers
python3 -m unittest tests.test_migration_parity -v
echo "Expected non-zero exit code (Red): $?"
```

## Success Criteria

- `superpowers/tests/test_migration_parity.py` exists with four TestCases.
- Tests fail with meaningful assertion errors (parity not yet achieved).
- All four `bdd-specs.md` parity scenarios are covered.
- No production code touched.
