# Task 004: observations.sh Wrapper — Tests (Red)

**depends-on**: task-002-retro-events-impl, task-001

## Description

Write failing tests for `lib/observations.sh`, the wrapper `helper` that exposes `log_harness_observation <event> <payload_jq_filter> [args...]` and writes to the **existing** `channel` `docs/retros/harness-observations.jsonl`. The on-disk schema is determined by the caller-supplied filter; the helper's job is to reproduce — byte-for-byte under deterministic timestamp substitution — what the legacy inline `bash` block in `retrospective/SKILL.md` Phase 5c currently emits. That parity is the load-bearing assertion of this test suite.

Unlike `skill-events.sh`, the envelope is **flat**: the legacy schema is `{event, component, timestamp, retrospective_id}` (no `payload` nesting, no `args_hash`). The helper merges its envelope fields (`event`, `timestamp`) with the caller's filter (`component`, `retrospective_id`, etc.) at the top level. Tests must assert the key set equals the legacy set with no extra fields.

## Execution Context

**Task Number**: 004 of 21
**Phase**: Core lib helpers
**Prerequisites**: Task 001 shipped `tests/fixtures/legacy-harness-observation.sh`; Task 002 shipped `lib/retro-events.sh`.

## BDD Scenarios

```gherkin
Scenario: log_harness_observation produces a row indistinguishable from the legacy Phase 5c bash block
  Given a retrospective run in Phase 5c that previously emitted the inline bash:
    jq -nc --arg event "component_unsupported" --arg c "$id" --arg ts "$now" --arg retro "$report" \
      '{event:$event, component:$c, timestamp:$ts, retrospective_id:$retro}' \
      >> docs/retros/harness-observations.jsonl
  When the same retrospective is run with the new helper as log_harness_observation component_unsupported '{component:$c, retrospective_id:$retro}' --arg c "<id>" --arg retro "<report>"
  Then the new line parses to the same JSON object shape as the legacy line
  And the field set is identical: {event, component, timestamp, retrospective_id}
  And the field order in serialized form is identical
  And both lines pass jq -e '.event and .component and .timestamp' validation

Scenario: Phase 5c legacy bash vs log_harness_observation produce identical channel rows
  Given a fixture tests/fixtures/legacy-harness-observation.jsonl written by the pre-migration bash block
  When the same logical event is re-emitted via log_harness_observation with matching args
  Then both lines have field set {event, component, timestamp, retrospective_id} with identical key order and JSON types
  And jq -S 'del(.timestamp)' produces byte-equal output on both lines
```

**Spec Source**: `../2026-05-12-unified-retro-events-design/bdd-specs.md` §1.3, §3.11

## Files to Modify/Create

- Modify: `superpowers/tests/test_observations_sh.py` (empty after Task 001).

## Steps

### Step 1: Test Helpers
- Add constants:
  ```python
  OBSERVATIONS_SH = SUPERPOWERS_DIR / "lib" / "observations.sh"
  LEGACY_FIXTURE = SUPERPOWERS_DIR / "tests" / "fixtures" / "legacy-harness-observation.sh"
  ```
- Add `run_executed` and `run_sourced` helpers (same pattern as Task 003).

### Step 2: TestCase — `ObservationsExecutedTests`
- `test_executed_writes_component_unsupported_row` — invoke `bash lib/observations.sh component_unsupported '{component:$c, retrospective_id:$retro}' --arg c "evaluator_per_batch" --arg retro "docs/retros/2026-05-12.md"`; parse one-line jsonl; assert key set == `{"event", "component", "timestamp", "retrospective_id"}` (use `assertEqual(set(entry.keys()), …)` — extra keys MUST fail). (§1.3)
- `test_executed_field_values` — same call; assert `entry["event"] == "component_unsupported"`, `entry["component"] == "evaluator_per_batch"`, `entry["retrospective_id"] == "docs/retros/2026-05-12.md"`, timestamp ISO-8601.
- `test_executed_supports_component_unknown` — same shape with `event=component_unknown`. (Phase 5c emits both kinds.)
- `test_executed_supports_disable_outcome` — same shape with `event=disable_outcome` and an additional payload field (e.g., `outcome=cleared`); assert key set is `{"event", "component", "timestamp", "retrospective_id", "outcome"}`.

### Step 3: TestCase — `ObservationsSourcedTests`
- `test_sourced_log_harness_observation_writes_row` — same body pattern as Task 003 sourced test, exercising `log_harness_observation` directly.
- `test_sourcing_does_not_run_main_branch` — assert no jsonl file created when only sourced.
- `test_sourcing_under_set_e_does_not_abort` — source + call with empty args + `echo still alive`.

### Step 4: TestCase — `ObservationsParityTests` — **critical**
- `test_byte_parity_with_legacy_fixture` — capture the fixture's stdout for known inputs (component_unsupported, evaluator_per_batch, docs/retros/foo.md); invoke `log_harness_observation` with matching args; read one line each from the legacy stdout and the new jsonl; pipe both through `jq -S 'del(.timestamp)'`; assertEqual the resulting byte strings. (§3.11 "byte-equal output").
- `test_serialized_key_order_preserved` — the legacy `jq -nc` emits keys in declaration order `{event, component, timestamp, retrospective_id}`; assert the new line's serialized (non-sorted) key order matches by raw string substring (`'"event":' before '"component":' before '"timestamp":' before '"retrospective_id":'`). (§1.3 "field order in serialized form is identical").
- `test_no_extra_envelope_fields` — assert `args_hash`, `repo_root`, `skill`, `payload` are NOT present in any harness-observation row (those are skill-events-channel fields). This protects against an accidental cross-pollination of the two wrappers.

### Step 5: TestCase — `ObservationsDegradationTests`
- `test_returns_zero_when_jq_missing` — sanitised PATH; assert exit 0 and no jsonl.
- `test_returns_zero_when_docs_retros_unwritable` — chmod 0500 root.
- `test_returns_zero_when_repo_root_empty` — empty env.

(Mirror the structure of `SkillEventsDegradationTests` but limited to the three scenarios that apply when no args_hash is used.)

### Step 6: TestCase — `ObservationsBackwardCompatTests`
- `test_existing_rows_not_rewritten` — pre-seed `docs/retros/harness-observations.jsonl` with three known rows; record `(mtime, sha256)` of each row's byte range; invoke `log_harness_observation` once; reassert the first three rows are byte-unchanged and the fourth row is the new emission. (§5.19)
- `test_file_remains_valid_ndjson_stream` — every line of the four-row file parses with `jq -e .`; assert exit 0.

### Step 7: Confirm RED
- Every test fails (file missing).

## Verification Commands

```bash
cd /Users/FradSer/Developer/FradSer/dotclaude
python3 -m pytest superpowers/tests/test_observations_sh.py -v 2>&1 | tail -40
```

## Success Criteria

- `test_observations_sh.py` ships ≥ 13 test methods across five TestCases.
- BDD §1.3 and §3.11 each map to ≥ one assertion.
- Every test fails RED.
- Parity assertions use `jq -S 'del(.timestamp)'` so the test is robust to acceptable serialization differences.
