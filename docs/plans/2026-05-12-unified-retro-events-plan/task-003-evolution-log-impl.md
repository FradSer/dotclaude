# Task 003-impl: evolution-log.sh helper impl (Green)

**depends-on**: task-003-test, task-002-impl

## Description

Implement `superpowers/lib/evolution-log.sh`, the second thin wrapper. Exposes `log_evolution_event <event_type> <payload_jq_filter> [args...]`. Sources `retro-events.sh` (already landed by task 002-impl) and produces the envelope `{event, timestamp, ...payload}` for each of the six event kinds defined in `evolution-protocol.md`. Goal: turn the Red test from 003-test into Green without regressing 002-impl's tests.

## Execution Context

**Task Number**: 003-impl of 15
**Phase**: Core Features (Green)
**Prerequisites**: 003-test exists and fails (Red). 002-impl shipped `retro-events.sh`.

## BDD Scenario

```gherkin
Scenario: log_evolution_event mirrors the legacy retrospective_run schema verbatim
  Given a retrospective Phase 6 closure that previously hand-built the retrospective_run JSON
  When the same closure is rewritten as `log_evolution_event retrospective_run '<filter>' --argjson sv "$self_value_json" ...`
  Then the produced line is byte-equivalent to the legacy line under deterministic timestamp substitution
  And nested sub-objects preserve their key order and field types
  And post_plan_diff is omitted (not nullified) when no plan carries a completion_commit

Scenario: jq is absent from PATH
Scenario: docs/retros is on a read-only filesystem
Scenario: repo_root resolution fails
Scenario: date command fails to emit an ISO-8601 timestamp
  (all → helper returns 0, no jsonl, no stderr noise)

Scenario: existing evolution-log.jsonl rows are not rewritten
```

**Spec Source**: `../2026-05-12-unified-retro-events-design/bdd-specs.md` §1.4, §2 (all), §5.3.

## Files to Modify/Create

- Create: `superpowers/lib/evolution-log.sh`

## Steps

### Step 1: Confirm Red
- Run `cd superpowers && python3 -m unittest tests.test_evolution_log_sh -v`. Confirm tests fail.

### Step 2: Implement evolution-log.sh
- File structure (mirrors `observations.sh`):
  - `[[ -n "${_EVOLUTION_LOG_LOADED:-}" ]] && return 0`
  - `source "$(dirname "${BASH_SOURCE[0]}")/retro-events.sh"`
  - Function signature: `log_evolution_event() { local event_type=$1; local payload_filter=$2; shift 2; … }` — body remains the implementer's contract-driven work.
  - The function must:
    - Call `jq_or_skip || return 0`
    - Resolve `repo_root` via `repo_root_or_skip` or `return 0`
    - Resolve `timestamp` via `timestamp_or_skip` or `return 0`
    - `ensure_log_dir "$repo_root/docs/retros" || return 0`
    - Build the envelope jq program by merging `{event: $event, timestamp: $timestamp}` with the caller-supplied `<payload_filter>`. Example shape: `'{event: $event, timestamp: $timestamp} + (<payload_filter>)'`. (Body is the implementer's call — the contract is "merge envelope + payload, write one NDJSON line".)
    - Call `write_jsonl "$repo_root/docs/retros/evolution-log.jsonl" '<merged filter>' --arg event "$event_type" --arg timestamp "$timestamp" "$@"`
  - `_EVOLUTION_LOG_LOADED=1`
  - Dual-mode footer: `if [[ "${BASH_SOURCE[0]:-$0}" == "${0}" ]]; then log_evolution_event "$@"; fi`
- **No top-level `set -`**.

### Step 3: Verify Test Passes (Green)
- Run `cd superpowers && python3 -m unittest tests.test_evolution_log_sh -v`. All tests MUST PASS.
- Run the full suite: `python3 -m unittest discover -s tests -v`. No regressions in 002's tests or pre-existing tests.

### Step 4: Refactor
- `shellcheck superpowers/lib/evolution-log.sh` clean.
- `grep -nE '^set -' superpowers/lib/evolution-log.sh` empty.

## Verification Commands

```bash
cd /Users/FradSer/Developer/FradSer/dotclaude/superpowers
python3 -m unittest tests.test_evolution_log_sh -v
python3 -m unittest discover -s tests -v
shellcheck lib/evolution-log.sh
grep -nE '^set -' lib/evolution-log.sh && echo "FAIL" || echo "OK"
```

## Success Criteria

- `superpowers/lib/evolution-log.sh` exists with `log_evolution_event` and dual-mode footer.
- All `tests/test_evolution_log_sh.py` tests pass.
- Full suite green (no regressions).
- `shellcheck` clean, no top-level `set -`.
