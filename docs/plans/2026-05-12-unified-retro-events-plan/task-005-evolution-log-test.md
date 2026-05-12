# Task 005: evolution-log.sh Wrapper — Tests (Red)

**depends-on**: task-002-retro-events-impl, task-001

## Description

Write failing tests for `lib/evolution-log.sh`, the wrapper `helper` that exposes `log_evolution_event <event_type> <payload_jq_filter> [args...]` and appends to `docs/retros/evolution-log.jsonl`. The channel carries six event shapes (`item_added`, `item_removed`, `item_modified`, `item_promoted`, `retrospective_run`, `component_reinstated`) and the helper must reproduce each shape byte-for-byte under deterministic timestamp substitution against the pre-migration inline `bash` blocks in `retrospective/SKILL.md` Phase 4 + Phase 6.

The schema is flat (like `observations.sh`, unlike `skill-events.sh`): `{event, timestamp, ...payload}`. Nested sub-objects (`self_value`, `post_plan_diff`, evidence) MUST preserve their key order — the consumer in retrospective Phase 1 step 5 walks rows as a homogeneous stream and any reordering would surface as a diff in the parity test.

Also covers the cross-channel "consumer parses mixed stream identically" scenario (§3.13) since the consumer is the retrospective Phase 1 step 5 reader and the row format is fully owned by this wrapper.

## Execution Context

**Task Number**: 005 of 21
**Phase**: Core lib helpers
**Prerequisites**: Task 001 shipped `tests/fixtures/legacy-retrospective-run.sh` and `legacy-evolution-item-added.sh`; Task 002 shipped `lib/retro-events.sh`.

## BDD Scenarios

```gherkin
Scenario: log_evolution_event mirrors the legacy retrospective_run schema verbatim
  Given a retrospective Phase 6 closure that previously hand-built the retrospective_run JSON with jq -nc and --argjson self_value
  When the same closure is rewritten as log_evolution_event retrospective_run '<filter>' --argjson sv "$self_value_json" ...
  Then the produced line is byte-equivalent to the legacy line under deterministic timestamp substitution
  And nested sub-objects (self_value, optional post_plan_diff) preserve their key order and field types
  And post_plan_diff is omitted (not nullified) when no plan in plans_analyzed carries a completion_commit

Scenario: Phase 6 closure legacy bash vs log_evolution_event produce identical retrospective_run rows
  Given a fixture tests/fixtures/legacy-retrospective-run.jsonl from the pre-migration Phase 6 closure
  When the same closure is re-emitted via log_evolution_event retrospective_run ...
  Then top-level keys match in order and nested sub-objects (self_value, post_plan_diff when present) match in key order
  And disable_test stays null or a supported identifier — never a free-text component name

Scenario: retrospective Phase 1 consumer parses old and new rows identically
  Given docs/retros/evolution-log.jsonl contains a mix of legacy and helper-emitted lines
  When retrospective Phase 1 step 5 builds the per-item_id history table
  And Pre-Check B reads consecutive_zero_change from the most recent retrospective_run
  Then no parser branches on row origin and no "schema_version" field is consulted

Scenario: existing evolution-log.jsonl rows are not rewritten
  Given a project with legacy item_added / item_removed / retrospective_run rows in docs/retros/evolution-log.jsonl
  When log_evolution_event appends a new row
  Then prior rows are byte-unchanged
  And the consumer in retrospective Phase 1 step 5 (per-item_id history table) reads the file as a single homogeneous stream
```

**Spec Source**: `../2026-05-12-unified-retro-events-design/bdd-specs.md` §1.4, §3.12, §3.13, §5.20

## Files to Modify/Create

- Modify: `superpowers/tests/test_evolution_log_sh.py` (empty after Task 001).

## Steps

### Step 1: Test Helpers
- Add constants:
  ```python
  EVOLUTION_LOG_SH = SUPERPOWERS_DIR / "lib" / "evolution-log.sh"
  LEGACY_ITEM_ADDED = SUPERPOWERS_DIR / "tests" / "fixtures" / "legacy-evolution-item-added.sh"
  LEGACY_RETRO_RUN = SUPERPOWERS_DIR / "tests" / "fixtures" / "legacy-retrospective-run.sh"
  ```

### Step 2: TestCase — `EvolutionLogExecutedTests`
- `test_executed_item_added_row` — invoke with the canonical `item_added` payload (mode/item_id/description/rationale/driving_plans/checklist_version/retrospective_report); assert key set equals the documented schema (§Components in architecture.md, `item_added` row).
- `test_executed_item_removed_row` — same shape with `event=item_removed`.
- `test_executed_item_modified_row` — same shape with `event=item_modified`.
- `test_executed_item_promoted_row` — same shape with `event=item_promoted`.
- `test_executed_retrospective_run_row` — full schema with nested `self_value`; assert `entry["self_value"]["proposals_total"] == N`, `entry["self_value"]["disable_test_set"] in (True, False)`, `entry["self_value"]["consecutive_zero_change"] == M`.
- `test_executed_component_reinstated_row` — invoke with `component`, `previously_disabled_in`, `reinstatement_method`, nested `evidence` sub-object, `rationale`. Assert key set + key order in the nested `evidence` object.

### Step 3: TestCase — `EvolutionLogSourcedTests`
- `test_sourced_log_evolution_event_writes_row` — body sources file + calls function for one event kind.
- `test_sourcing_does_not_run_main_branch`.
- `test_sourcing_under_set_e_does_not_abort`.

### Step 4: TestCase — `EvolutionLogParityTests` — **critical**
- `test_byte_parity_with_legacy_item_added_fixture` — capture fixture stdout; invoke `log_evolution_event item_added ...` with matching args; pipe both through `jq -S 'del(.timestamp)'`; assertEqual.
- `test_byte_parity_with_legacy_retrospective_run_fixture` — same approach with the Phase 6 closure fixture; **must include nested `self_value` and `post_plan_diff`**; assert key order of nested objects via raw string substring matching (`'"proposals_total":' before '"disable_test_set":' before '"consecutive_zero_change":'`). (§1.4, §3.12)
- `test_post_plan_diff_omitted_when_absent` — invoke `log_evolution_event retrospective_run` WITHOUT a `post_plan_diff` arg; assert the resulting row has NO `post_plan_diff` key (use `assertNotIn`). NOT nullified — entirely omitted. (§1.4 "post_plan_diff is omitted (not nullified)")
- `test_disable_test_accepts_null_or_identifier_only` — invoke twice, once with `--argjson dt null` and once with `--arg dt evaluator_per_batch`; assert both rows are well-formed; assert no free-text values are accepted (the **caller** controls this; the helper just transports, but the test documents the architectural constraint by asserting the legitimate cases).

### Step 5: TestCase — `EvolutionLogConsumerParityTests` — covers §3.13
- `test_mixed_legacy_and_helper_rows_parse_homogeneously` — build a jsonl file with the sequence `[legacy_row, helper_row, legacy_row]` covering `item_added` events; run a minimal Python re-implementation of the retrospective Phase 1 step 5 walker:
  ```python
  history = collections.defaultdict(list)
  for line in jsonl_lines:
      row = json.loads(line)
      if row["event"] in ("item_added", "item_removed", "item_modified", "item_promoted"):
          history[row["item_id"]].append(row["event"])
  ```
  Assert `history` has the expected entry from every row regardless of origin (legacy vs helper).
- `test_no_schema_version_field_consulted` — assert no row produced by the helper carries a `"schema_version"` key (negative check guards future drift).

### Step 6: TestCase — `EvolutionLogBackwardCompatTests`
- `test_existing_rows_not_rewritten` — same pattern as Task 004 `ObservationsBackwardCompatTests` but on `evolution-log.jsonl`. (§5.20)
- `test_file_remains_valid_ndjson_stream`.

### Step 7: TestCase — `EvolutionLogDegradationTests`
- Three degradation cases (jq missing, unwritable, repo_root empty) mirroring Task 004.

### Step 8: Confirm RED
- All tests fail.

## Verification Commands

```bash
cd /Users/FradSer/Developer/FradSer/dotclaude
python3 -m pytest superpowers/tests/test_evolution_log_sh.py -v 2>&1 | tail -50
```

## Success Criteria

- `test_evolution_log_sh.py` ships ≥ 17 test methods across six TestCases.
- BDD §1.4, §3.12, §3.13, §5.20 each map to ≥ one test.
- All tests fail RED.
- Nested-object key-order assertions use raw string substring checks (the strongest available proof of preserved jq ordering).
