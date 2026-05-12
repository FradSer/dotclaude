# Task 005: evolution-log.sh Wrapper — Implementation (Green)

**depends-on**: task-005-evolution-log-test

## Description

Implement `lib/evolution-log.sh` to turn Task 005 green. Function `log_evolution_event <event_type> <payload_jq_filter> [args...]` merges its envelope (`event`, `timestamp`) with the caller's filter at the top level and appends one NDJSON line to `docs/retros/evolution-log.jsonl`.

Critical preservation property: nested object key orders MUST match the pre-migration `jq -nc` invocation. The fix is identical to `observations.sh` — use jq's `+` operator with disjoint envelope-vs-payload keys so jq emits declaration-order. For `retrospective_run`, the optional `post_plan_diff` field is **conditionally** included by the caller's filter expression itself (e.g., `if $has_diff then {post_plan_diff: $ppd} else {} end`) so the helper transports an absent field as a fully omitted key, never a `null`.

## Execution Context

**Task Number**: 005 of 21
**Phase**: Core lib helpers
**Prerequisites**: Task 005 test is RED.

## BDD Scenario

See `task-005-evolution-log-test.md`. Primary:

```gherkin
Scenario: log_evolution_event mirrors the legacy retrospective_run schema verbatim
  Then the produced line is byte-equivalent to the legacy line under deterministic timestamp substitution
  And nested sub-objects (self_value, optional post_plan_diff) preserve their key order and field types
  And post_plan_diff is omitted (not nullified) when no plan in plans_analyzed carries a completion_commit
```

**Spec Source**: `../2026-05-12-unified-retro-events-design/bdd-specs.md` §1.4, §3.12, §3.13, §5.20

## Files to Modify/Create

- Create: `superpowers/lib/evolution-log.sh`

## Steps

### Step 1: File Header
- Comment block style as before.
- Document the six supported `event_type` values (item_added, item_removed, item_modified, item_promoted, retrospective_run, component_reinstated).
- Document that the schema is determined by the caller's payload filter — this helper is a thin envelope, not a schema validator (per architecture.md §evolution-log.sh "Differences from bail-log.sh"). Note that callers MUST conditionally compose `post_plan_diff` so absent values become omitted keys.

### Step 2: Idempotence + Sources
- Top-of-file idempotence guard via `_EVOLUTION_LOG_LOADED`; source `retro-events.sh` using the same resolution pattern.

### Step 3: `log_evolution_event` Public Signature

```bash
log_evolution_event <event_type> <payload_jq_filter> [jq_args...]
```

- `<event_type>` is one of the six documented kinds (`item_added`, `item_removed`, `item_modified`, `item_promoted`, `retrospective_run`, `component_reinstated`); the helper does not validate which — Task 005 test pins schema coverage.

### Step 4: Function Behavior Contract

- Same best-effort guard chain as `observations.sh` (Task 004 Step 4) — `jq_or_skip`, `repo_root_or_skip`, `timestamp_or_skip`, `ensure_log_dir`, each guarded with `|| return 0`.
- The envelope is FLAT (`{event, …payload, timestamp}`) using jq's `+` operator to preserve declaration-order serialization. Same shape as `observations.sh`.
- The caller's filter is responsible for `post_plan_diff` omission. The wrapper does not branch on field presence — the caller's filter must use a conditional expression so absent values produce omitted keys, never `null`. Task 008 impl carries the concrete conditional expression in its SKILL.md edit; the helper itself is shape-agnostic.

### Step 5: Empty-Filter Fallback

- If `payload_filter` is empty, substitute the literal `{}`.

### Step 6: Append

- Invoke `write_jsonl` on `${root}/docs/retros/evolution-log.jsonl` with the composed envelope filter and forwarded caller args.

### Step 7: Executed-mode Footer

- Append the same dual-mode guard `bail-log.sh:83–85` uses.

### Step 6: Verification
- Run Task 005 tests; all pass.
- `shellcheck`; `SC1091` only.
- Run full suite to verify the cross-task `EvolutionLogConsumerParityTests.test_mixed_legacy_and_helper_rows_parse_homogeneously` passes — this is the design's load-bearing "invisible migration" assertion.

## Verification Commands

```bash
cd /Users/FradSer/Developer/FradSer/dotclaude
python3 -m pytest superpowers/tests/test_evolution_log_sh.py -v 2>&1 | tail -50
python3 -m pytest superpowers/tests/ -q 2>&1 | tail -10
shellcheck superpowers/lib/evolution-log.sh || true
grep -nE "^set -" superpowers/lib/evolution-log.sh
```

## Success Criteria

- All tests in `test_evolution_log_sh.py` pass.
- Full suite remains green.
- Parity assertions against both `item_added` and `retrospective_run` fixtures pass.
- `post_plan_diff` is fully omitted (not nullified) when the caller's filter does not include it.
