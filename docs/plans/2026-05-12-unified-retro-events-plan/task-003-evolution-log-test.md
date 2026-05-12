# Task 003-test: evolution-log.sh helper test (Red)

**depends-on**: _(none — independent Red test)_

## Description

Write the failing test file `superpowers/tests/test_evolution_log_sh.py` covering the public contract of `lib/evolution-log.sh::log_evolution_event`. Mirror the three-mode structure of `tests/test_bail_log_sh.py`: Executed / Sourced / Degradation TestCases, plus a per-event-type schema test covering every `evolution-log.jsonl` event kind (`item_added`, `item_removed`, `item_modified`, `item_promoted`, `retrospective_run`, `component_reinstated`).

## Execution Context

**Task Number**: 003-test of 15
**Phase**: Core Features (Red)
**Prerequisites**: None.

## BDD Scenario

```gherkin
Scenario: log_evolution_event mirrors the legacy retrospective_run schema verbatim
  Given a retrospective Phase 6 closure that previously hand-built the retrospective_run JSON with jq -nc and --argjson self_value
  When the same closure is rewritten as `log_evolution_event retrospective_run '<filter>' --argjson sv "$self_value_json" ...`
  Then the produced line is byte-equivalent to the legacy line under deterministic timestamp substitution
  And nested sub-objects (`self_value`, optional `post_plan_diff`) preserve their key order and field types
  And `post_plan_diff` is omitted (not nullified) when no plan in plans_analyzed carries a completion_commit

Scenario: jq is absent from PATH
Scenario: docs/retros is on a read-only filesystem
Scenario: repo_root resolution fails
Scenario: date command fails to emit an ISO-8601 timestamp
  (all → helper returns 0, writes nothing, no stderr noise)

Scenario: existing evolution-log.jsonl rows are not rewritten
  Given a project with legacy item_added / item_removed / retrospective_run rows
  When log_evolution_event appends a new row
  Then prior rows are byte-unchanged
  And the consumer in retrospective Phase 1 step 5 reads the file as a single homogeneous stream
```

**Spec Source**: `../2026-05-12-unified-retro-events-design/bdd-specs.md` §1.4, §2 (all), §5.3.

## Files to Modify/Create

- Create: `superpowers/tests/test_evolution_log_sh.py`

## Steps

### Step 1: Verify Scenario
- Confirm scenarios above appear in `bdd-specs.md`.
- Cross-reference `architecture.md` §`lib/evolution-log.sh` for the envelope shape: `{event, timestamp, ...payload}`.

### Step 2: Implement Test (Red)
- Three TestCases plus a fourth for per-event-type schema:
  - `class EvolutionLogExecutedTests(unittest.TestCase)` — for each of the six event kinds (`item_added`, `item_removed`, `item_modified`, `item_promoted`, `retrospective_run`, `component_reinstated`):
    - invoke `bash lib/evolution-log.sh <event_type> '<payload_jq_filter>' --arg/--argjson ...` with fixture args matching the schema from `evolution-protocol.md` lines 85-170
    - assert exit 0, one new line appended to `docs/retros/evolution-log.jsonl`, the line parses, and the field set matches the architecture table verbatim
    - assert that appending two rows to an existing file preserves the first row byte-for-byte (covers §5.3)
  - `class EvolutionLogSourcedTests(unittest.TestCase)` — sources the helper under `set -euo pipefail`; asserts exit 0 and parity with Executed mode.
  - `class EvolutionLogDegradationTests(unittest.TestCase)` — one test per §2 scenario:
    - `test_silent_skip_when_jq_missing`
    - `test_returns_zero_when_docs_retros_unwritable`
    - `test_returns_zero_when_repo_root_empty`
    - `test_returns_zero_when_date_fails`
  - `class EvolutionLogPayloadSchemaTests(unittest.TestCase)` — for the `retrospective_run` shape specifically:
    - `test_retrospective_run_payload_includes_nested_self_value` — asserts the produced line has `self_value.proposals_total`, `self_value.disable_test_set`, `self_value.consecutive_zero_change` in that order under `jq -S` projection
    - `test_retrospective_run_omits_post_plan_diff_when_absent` — asserts `post_plan_diff` key is NOT present when the caller does not pass it (matches §1.4 "post_plan_diff is omitted, not nullified")
    - `test_retrospective_run_includes_post_plan_diff_when_provided` — asserts inclusion under the opposite case
- Reuse `tests/conftest.py` fixtures.
- **PROHIBITED**: do not implement `superpowers/lib/evolution-log.sh` in this task.

### Step 3: Verify Test Fails (Red)
- Run `cd superpowers && python3 -m unittest tests.test_evolution_log_sh -v`.
- **Verification**: all tests MUST FAIL meaningfully (file-not-found or non-zero exit). No `ImportError`.

## Verification Commands

```bash
cd /Users/FradSer/Developer/FradSer/dotclaude/superpowers
python3 -m unittest tests.test_evolution_log_sh -v
echo "Expected non-zero exit code (Red): $?"
```

## Success Criteria

- `superpowers/tests/test_evolution_log_sh.py` exists with four TestCases covering Executed, Sourced, Degradation, and Payload Schema.
- Tests cover all six `evolution-log.jsonl` event kinds.
- Tests fail loudly when run (file-not-found, not `ImportError`).
- No production code touched.
