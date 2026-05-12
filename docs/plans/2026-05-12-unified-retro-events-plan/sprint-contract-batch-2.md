# Batch 2 Sprint Contract

## Tasks

| ID | Subject | Type |
|----|---------|------|
| 003-test | evolution-log.sh helper test (Red) | test |
| 003-impl | evolution-log.sh helper impl (Green) | impl |
| 004-test | skill-events.sh helper test (Red) | test |
| 004-impl | skill-events.sh helper impl (Green) | impl |

## Acceptance Criteria

### Task 003-test: evolution-log.sh helper test (Red)

Derived from `bdd-specs.md` §1.4, §2 (all), §5.3 Then-clauses.

- [ ] `superpowers/tests/test_evolution_log_sh.py` exists with four TestCase classes: `EvolutionLogExecutedTests`, `EvolutionLogSourcedTests`, `EvolutionLogDegradationTests`, `EvolutionLogPayloadSchemaTests`
- [ ] Executed-mode tests cover all six event kinds: `item_added`, `item_removed`, `item_modified`, `item_promoted`, `retrospective_run`, `component_reinstated`
- [ ] For each event kind: assert exit 0, one new NDJSON line in `docs/retros/evolution-log.jsonl`, field set matches architecture envelope
- [ ] Appending two rows to an existing file preserves the first row byte-for-byte
- [ ] Sourced-mode test asserts the helper does not abort the caller under `set -euo pipefail`
- [ ] Degradation TestCase covers four tests: `test_silent_skip_when_jq_missing`, `test_returns_zero_when_docs_retros_unwritable`, `test_returns_zero_when_repo_root_empty`, `test_returns_zero_when_date_fails`
- [ ] Payload-schema TestCase asserts: `self_value` nested object preserves key order under `jq -S`, `post_plan_diff` is omitted (not nullified) when absent, `post_plan_diff` is included when provided
- [ ] Running the test suite produces file-not-found / function-not-defined failures (NOT Python `ImportError` from a typo)
- [ ] No production code (`superpowers/lib/evolution-log.sh`) is touched by this task

### Task 003-impl: evolution-log.sh helper impl (Green)

Derived from `bdd-specs.md` §1.4, §2 (all), §5.3 Then-clauses.

- [ ] `superpowers/lib/evolution-log.sh` exists with module guard `[[ -n "${_EVOLUTION_LOG_LOADED:-}" ]] && return 0` and `_EVOLUTION_LOG_LOADED=1` at end of file
- [ ] `evolution-log.sh` sources `retro-events.sh` once via `source "$(dirname "${BASH_SOURCE[0]}")/retro-events.sh"`
- [ ] `log_evolution_event <event_type> <payload_jq_filter> [args...]` is defined and returns 0 unconditionally
- [ ] Envelope merges `{event, timestamp}` with the caller-supplied payload filter (merge, not nested — matches `evolution-log.jsonl` schema)
- [ ] Dual-mode footer present: `if [[ "${BASH_SOURCE[0]:-$0}" == "${0}" ]]; then log_evolution_event "$@"; fi`
- [ ] No top-level `set -e`/`set -u`/`set -o pipefail` (NF3)
- [ ] All tests in `tests/test_evolution_log_sh.py` pass (exit 0)
- [ ] Full unittest suite passes; no regressions in `test_observations_sh.py`, `test_bail_log_sh.py`, etc.
- [ ] `grep -nE '^set -' lib/evolution-log.sh` returns empty
- [ ] (shellcheck if available on host; otherwise documented as host-skipped — NF3 enforced via grep)

### Task 004-test: skill-events.sh helper test (Red)

Derived from `bdd-specs.md` §1.1, §1.2, §2 (all) Then-clauses.

- [ ] `superpowers/tests/test_skill_events_sh.py` exists with four TestCase classes: `SkillEventsExecutedTests`, `SkillEventsSourcedTests`, `SkillEventsDegradationTests`, `SkillEventsArgsHashTests`
- [ ] Executed-mode tests assert envelope fields `{event, skill, timestamp, repo_root, args_hash, payload}` are all populated
- [ ] `test_payload_keys_do_not_collide_with_envelope` asserts top-level keys disjoint from payload keys
- [ ] `test_creates_docs_retros_when_missing` covers fresh-project bootstrap
- [ ] Sourced-mode tests: `test_sourced_then_called_writes_entry`, `test_sourcing_does_not_run_main`, `test_sourcing_under_set_e_does_not_abort_caller`, `test_executed_equals_sourced_modulo_timestamp`
- [ ] Degradation TestCase covers: `test_silent_skip_when_jq_missing`, `test_args_hash_empty_when_shasum_and_sha1sum_missing`, `test_returns_zero_when_docs_retros_unwritable`, `test_returns_zero_when_repo_root_empty`, `test_returns_zero_when_date_fails`
- [ ] ArgsHash TestCase covers: stable for identical args, differs for different args, format `^[0-9a-f]{12}$`
- [ ] Tests fail with file-not-found errors (NOT Python `ImportError`)
- [ ] No production code (`superpowers/lib/skill-events.sh`) is touched

### Task 004-impl: skill-events.sh helper impl (Green)

Derived from `bdd-specs.md` §1.1, §1.2, §2 (all) Then-clauses.

- [ ] `superpowers/lib/skill-events.sh` exists with module guard `[[ -n "${_SKILL_EVENTS_LOADED:-}" ]] && return 0`
- [ ] Sources `retro-events.sh` once
- [ ] `log_skill_event <skill> <event> <payload_jq_filter> [args...]` defined; returns 0 unconditionally
- [ ] Envelope **nests** payload (not merges): `{event, skill, timestamp, repo_root, args_hash, payload: (<filter>)}` — distinct from `evolution-log.sh` which merges
- [ ] `args_hash` computed via `shasum` with `sha1sum` fallback; both absent → `args_hash=""` (§2.2)
- [ ] Dual-mode footer present
- [ ] No top-level `set -`
- [ ] All `tests/test_skill_events_sh.py` tests pass
- [ ] Full unittest suite passes
- [ ] `grep -nE '^set -' lib/skill-events.sh` returns empty

## Red-Green Pairs

| Test Task | Impl Task | Expected Red State | Expected Green State |
|-----------|-----------|--------------------|----------------------|
| 003-test | 003-impl | Test suite fails with file-not-found because `lib/evolution-log.sh` does not exist | All `test_evolution_log_sh.py` tests pass; full suite green |
| 004-test | 004-impl | Test suite fails with file-not-found because `lib/skill-events.sh` does not exist | All `test_skill_events_sh.py` tests pass; full suite green |

The pairs run in parallel — they touch disjoint files. 003-test ↔ 003-impl is sequenced (Red then Green); same for 004-test ↔ 004-impl. The two pairs themselves run concurrently.

## Evaluation Criteria Preview

The evaluator will apply the following checklist items to this batch:

| Item ID | Description |
|---------|-------------|
| CODE-VER-01 | Verification commands exit with code 0 |
| CODE-QUAL-01 | No TODO, FIXME, HACK, XXX, or stub patterns in produced files |
| CODE-QUAL-02 | No stub implementations (`NotImplementedError`, lone `pass`, lone `...`) in produced files |

## Sign-off

- **Generator:** executing-plans
- **Timestamp:** 2026-05-12T15:37:00Z
- **Status:** READY
