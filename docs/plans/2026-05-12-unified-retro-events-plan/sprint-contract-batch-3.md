# Batch 3 Sprint Contract

## Tasks

| ID | Subject | Type |
|----|---------|------|
| 005-test | shared-core single-source test (Red) | test |
| 005-impl | shared-core single-source impl (Green) | impl |
| 006-test | Migration parity test (Red) | test |
| 006-impl | Migration parity impl (Green) | impl |

## Acceptance Criteria

### Task 005-test: shared-core single-source test (Red)

Derived from `bdd-specs.md` §1.5 Then-clauses.

- [ ] `superpowers/tests/test_retro_events_sh.py` exists with `RetroEventsSharedCoreTests` TestCase
- [ ] `test_three_wrappers_share_utils_sh_single_source` asserts `_SUPERPOWERS_DEPS_CHECKED=1` after sourcing all three wrappers; asserts no duplicate deps-missing warnings on stderr
- [ ] `test_sourcing_order_independent` runs at least 3 source-order permutations; all set `_SUPERPOWERS_DEPS_CHECKED=1`
- [ ] `test_wrappers_set_their_loaded_guards` asserts `_OBSERVATIONS_LOADED`, `_EVOLUTION_LOG_LOADED`, `_SKILL_EVENTS_LOADED`, `_RETRO_EVENTS_LOADED` are all `1` after sourcing each wrapper
- [ ] `test_re_sourcing_is_idempotent` sources each wrapper twice; asserts no duplicate stderr warnings and function definitions remain intact
- [ ] Tests fail with meaningful assertion errors (NOT Python `ImportError`)
- [ ] No production code is touched

### Task 005-impl: shared-core single-source impl (Green)

Derived from `bdd-specs.md` §1.5 Then-clauses.

- [ ] `superpowers/lib/observations.sh` has `[[ -n "${_OBSERVATIONS_LOADED:-}" ]] && return 0` at top and `_OBSERVATIONS_LOADED=1` before the dual-mode footer
- [ ] `superpowers/lib/evolution-log.sh` has the same idempotency guard pattern with `_EVOLUTION_LOG_LOADED`
- [ ] `superpowers/lib/skill-events.sh` has the same idempotency guard pattern with `_SKILL_EVENTS_LOADED`
- [ ] `superpowers/lib/retro-events.sh` confirms `_RETRO_EVENTS_LOADED` guard is in place and that `source utils.sh` runs only on first source
- [ ] Function bodies are NOT modified — only the guard lines are added
- [ ] `grep -nE '^set -' superpowers/lib/{retro-events,observations,evolution-log,skill-events}.sh` returns empty
- [ ] All tests in `tests/test_retro_events_sh.py` pass (exit 0)
- [ ] Full unittest suite passes; zero regressions in 002/003/004 tests

### Task 006-test: Migration parity test (Red)

Derived from `bdd-specs.md` §3.1, §3.2, §3.3, §5.1 Then-clauses.

- [ ] `superpowers/tests/test_migration_parity.py` exists with four TestCases: `HarnessObservationParityTests`, `EvolutionLogParityTests`, `MixedStreamConsumerTests`, `PlansCompletedUntouchedTests`
- [ ] `test_helper_matches_legacy_bash_block_for_component_unsupported` compares fixture-vs-helper output under `jq -S 'del(.timestamp)'` byte-equality
- [ ] `test_helper_matches_legacy_for_component_unknown` covers the second event kind
- [ ] `test_retrospective_run_helper_matches_legacy_bash_block` verifies envelope + nested `self_value` + optional `post_plan_diff` parity
- [ ] `test_item_added_helper_matches_legacy_bash_block` verifies item-row parity
- [ ] `test_post_plan_diff_omitted_when_absent` asserts the `post_plan_diff` key is **absent** (not nulled) when caller omits the arg
- [ ] `test_consumer_parses_mixed_stream_identically` builds a `[legacy, helper, legacy]` mixed stream and asserts the Phase 1 step 5 grouping does not branch on row origin
- [ ] `test_consumer_reads_consecutive_zero_change_from_either_origin` asserts Pre-Check B reads `self_value.consecutive_zero_change` identically regardless of row origin
- [ ] `test_no_helper_writes_to_plans_completed_jsonl` asserts `plans-completed.jsonl` mtime is unchanged after the three new helpers run
- [ ] Tests fail with meaningful assertion errors (key-order diff, `post_plan_diff: null` vs absence, etc.)
- [ ] No production code is touched

### Task 006-impl: Migration parity impl (Green)

Derived from `bdd-specs.md` §3 (all), §5.1 Then-clauses.

- [ ] `superpowers/lib/observations.sh` jq envelope produces top-level keys in the order `{event, component, timestamp, retrospective_id}` matching the legacy fixture byte-for-byte (modulo timestamp)
- [ ] `superpowers/lib/evolution-log.sh` jq envelope produces top-level keys in the order matching the legacy Phase 6 closure bash block byte-for-byte
- [ ] Nested sub-objects (`self_value`, `post_plan_diff` when present) preserve their key order
- [ ] `post_plan_diff` is **omitted** (not `null`) when the caller passes no `--argjson post_plan_diff` — implemented as `if $has_diff then {post_plan_diff: $pd} else {} end` merged into envelope
- [ ] Function signatures unchanged; primitive functions in `retro-events.sh` unchanged
- [ ] No test files are modified
- [ ] All `tests/test_migration_parity.py` tests pass (exit 0)
- [ ] Full unittest suite passes; zero regressions in 002/003/004/005 tests
- [ ] `grep -nE '^set -' lib/observations.sh lib/evolution-log.sh` returns empty
- [ ] `plans-completed.jsonl` mtime is unchanged after helpers run (cross-cutting BC assertion)

## Red-Green Pairs

| Test Task | Impl Task | Expected Red State | Expected Green State |
|-----------|-----------|--------------------|----------------------|
| 005-test | 005-impl | Tests fail because `_*_LOADED` guards are absent from wrappers and/or idempotency invariants not satisfied | All `test_retro_events_sh.py` tests pass; guards land on all four files |
| 006-test | 006-impl | Tests fail due to subtle key-order mismatch or `post_plan_diff: null` instead of absence | All `test_migration_parity.py` tests pass; byte-equality under `jq -S 'del(.timestamp)'` |

## Execution Sequencing (critical)

005-impl and 006-impl **both modify** `superpowers/lib/observations.sh` and `superpowers/lib/evolution-log.sh`. They MUST execute **serially** to avoid edit conflicts:

1. **Phase A (parallel)**: spawn 005-test and 006-test sub-agents concurrently (disjoint test files; no production code modified)
2. **Phase B (serial)**: spawn 005-impl FIRST (mechanical guard additions, well-localized at file top + before footer)
3. **Phase C (serial)**: spawn 006-impl SECOND (jq envelope tweaks, well-localized to the jq filter lines inside the function bodies)
4. Verify each impl turns its paired test from Red → Green before proceeding to the next phase

005-impl's guards are mechanical (top + bottom of file); 006-impl's tweaks touch the function-body jq filter — the two edit regions do not overlap by design, but executing them serially avoids any race.

## Evaluation Criteria Preview

The evaluator will apply the following checklist items to this batch:

| Item ID | Description |
|---------|-------------|
| CODE-VER-01 | Verification commands exit with code 0 |
| CODE-QUAL-01 | No TODO, FIXME, HACK, XXX, or stub patterns in produced files |
| CODE-QUAL-02 | No stub implementations (`NotImplementedError`, lone `pass`, lone `...`) in produced files |

## Sign-off

- **Generator:** executing-plans
- **Timestamp:** 2026-05-12T15:42:00Z
- **Status:** READY
