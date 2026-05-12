# Task 004: observations.sh Wrapper — Implementation (Green)

**depends-on**: task-004-observations-test

## Description

Implement `lib/observations.sh` to turn Task 004 green. Function `log_harness_observation <event> <payload_jq_filter> [args...]` merges its envelope (`event`, `timestamp`) with the caller's filter at the top level (no nesting; the channel's pre-existing schema is flat) and appends one NDJSON line to `docs/retros/harness-observations.jsonl`.

No `args_hash`, no `repo_root`, no `skill`, no `payload` envelope — those are skill-events-channel concerns and would break the pre-migration consumer in retrospective Phase 1 step 6.

## Execution Context

**Task Number**: 004 of 21
**Phase**: Core lib helpers
**Prerequisites**: Task 004 test is RED.

## BDD Scenario

See `task-004-observations-test.md`. Primary:

```gherkin
Scenario: log_harness_observation produces a row indistinguishable from the legacy Phase 5c bash block
  When log_harness_observation component_unsupported '{component:$c, retrospective_id:$retro}' --arg c "<id>" --arg retro "<report>" is invoked
  Then the field set is identical: {event, component, timestamp, retrospective_id}
  And the field order in serialized form is identical
```

**Spec Source**: `../2026-05-12-unified-retro-events-design/bdd-specs.md` §1.3, §3.11

## Files to Modify/Create

- Create: `superpowers/lib/observations.sh`

## Steps

### Step 1: File Header
- Same shebang + comment block style as `bail-log.sh:1–34`.
- Document the schema as the **legacy-preserving** envelope:
  ```
  Schema per line (NDJSON, flat — no payload nesting):
    {"event":"<event>", "<caller-supplied fields...>", "timestamp":"<ISO8601 UTC>"}
  ```
- Document the rationale: matches the pre-migration retrospective Phase 5c output verbatim under deterministic timestamp substitution.

### Step 2: Idempotence + Sources
- Top-of-file idempotence guard via `_OBSERVATIONS_LOADED`; source `retro-events.sh` using the same resolution pattern Task 002 uses.

### Step 3: `log_harness_observation` Public Signature

```bash
log_harness_observation <event> <payload_jq_filter> [jq_args...]
```

- Both required positional args precede the variadic `[jq_args...]` block forwarded to `jq -nc`.

### Step 4: Function Behavior Contract

- Best-effort guards (`jq_or_skip`, `repo_root_or_skip`, `timestamp_or_skip`, `ensure_log_dir`) all short-circuit via `|| return 0` — same idiom Task 003 uses.
- The envelope is FLAT (`{event, …payload, timestamp}` — no `payload` nesting, no `args_hash`, no `repo_root`, no `skill`). The caller's filter contributes the middle fields; the helper contributes `event` first and `timestamp` last.
- Key-order requirement: serialized jq output must keep `event` first, caller's payload fields in their declared order, and `timestamp` last. The legacy Phase 5c bash block emits `{event, component, timestamp, retrospective_id}` in that order. The helper's composition must produce the same serialized order so `test_serialized_key_order_preserved` (Task 004 test) passes.
- The standard jq mechanism for preserving declaration order across two disjoint object sources is the `+` operator. The implementer uses that mechanism without inventing a new pattern.

### Step 5: Empty Filter Fallback

- If `payload_filter` is empty, substitute the literal `{}` so the envelope still serializes.

### Step 6: Append

- Invoke `write_jsonl` on `${root}/docs/retros/harness-observations.jsonl` with the composed envelope filter and forwarded caller args.

### Step 7: Executed-mode Footer

- Append the same dual-mode guard `bail-log.sh:83–85` uses, calling `log_harness_observation "$@"` when the file is executed directly.

### Step 8: Verification
- Run Task 004's tests; every test passes.
- `shellcheck`; only `SC1091` acceptable.
- Run the FULL test suite (`pytest superpowers/tests/`) to confirm no regression in prior tests.

## Verification Commands

```bash
cd /Users/FradSer/Developer/FradSer/dotclaude
python3 -m pytest superpowers/tests/test_observations_sh.py -v 2>&1 | tail -40
python3 -m pytest superpowers/tests/ -q 2>&1 | tail -10
shellcheck superpowers/lib/observations.sh || true
grep -nE "^set -" superpowers/lib/observations.sh    # must produce no output
```

## Success Criteria

- All tests in `test_observations_sh.py` pass; full suite still green.
- Byte-parity test passes against the legacy fixture.
- No top-level `set -e` / `set -u` / `set -o pipefail`.
