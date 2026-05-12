# Batch 1 Sprint Contract

## Tasks

| ID | Subject | Type |
|----|---------|------|
| 001 | Test fixtures and scaffolding | setup |
| 002-test | observations.sh helper test (Red) | test |
| 002-impl | observations.sh + retro-events.sh primitives impl (Green) | impl |

## Acceptance Criteria

### Task 001: Test fixtures and scaffolding

Derived from BDD scenarios in §3 (parity) — task is foundation infrastructure for tasks 006/007/008.

- [ ] `superpowers/tests/fixtures/legacy-harness-observation.sh` exists, is executable, and is self-contained (no project lib sourcing)
- [ ] `superpowers/tests/fixtures/legacy-retrospective-run.sh` exists, is executable, and is self-contained
- [ ] `superpowers/tests/fixtures/legacy-evolution-item.sh` exists, is executable, accepts `event_type` as `$2` covering `item_added`/`item_removed`/`item_modified`/`item_promoted`
- [ ] Each fixture script produces valid NDJSON when invoked with sample args (`jq -e .` returns 0)
- [ ] Each fixture script accepts the timestamp as an arg (so parity tests can substitute a deterministic value)
- [ ] `superpowers/tests/fixtures/README.md` documents the source line numbers in `retrospective/SKILL.md` for every script
- [ ] No file under `superpowers/lib/` is touched
- [ ] No `SKILL.md` file is modified
- [ ] `jq` invocation syntax, field order, and `--arg`/`--argjson` ordering are byte-equal to the inline blocks in `retrospective/SKILL.md`

### Task 002-test: observations.sh helper test (Red)

Derived from `bdd-specs.md` §1.3, §2.1, §2.3, §2.4, §2.5, §5.3 Then-clauses.

- [ ] `superpowers/tests/test_observations_sh.py` exists with three TestCase classes: `ObservationsExecutedTests`, `ObservationsSourcedTests`, `ObservationsDegradationTests`
- [ ] Executed-mode test asserts `bash superpowers/lib/observations.sh <component> <outcome> <reason>` exits 0 and writes one NDJSON row to `docs/retros/harness-observations.jsonl`
- [ ] Executed-mode test asserts NDJSON keys match `{event, component, reason, repo_root, timestamp}` (terse-row schema)
- [ ] Executed-mode test asserts `event` value equals the `<outcome>` arg
- [ ] Executed-mode test asserts `timestamp` matches ISO-8601 UTC regex `^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$`
- [ ] Executed-mode test asserts appending to an existing file preserves the first row byte-for-byte
- [ ] Sourced-mode test confirms `set -euo pipefail` in the caller is not aborted (still-alive marker reaches stdout)
- [ ] Degradation TestCase contains four tests: `test_silent_skip_when_jq_missing`, `test_returns_zero_when_docs_retros_unwritable`, `test_returns_zero_when_repo_root_empty`, `test_returns_zero_when_date_fails`; each asserts exit 0 and no jsonl produced
- [ ] When run with no production file present, the test suite fails with file-not-found / function-not-defined errors (NOT Python `ImportError` from a test typo)
- [ ] No production code under `superpowers/lib/` is touched by this task

### Task 002-impl: observations.sh + retro-events.sh primitives impl (Green)

Derived from `bdd-specs.md` §1.3, §1.5, §2 (all), §5.3 Then-clauses.

- [ ] `superpowers/lib/retro-events.sh` exists with six primitive functions: `jq_or_skip`, `timestamp_or_skip`, `ensure_log_dir`, `repo_root_or_skip`, `write_jsonl`, `dedup_check`
- [ ] `retro-events.sh` uses the load-guard idiom `[[ -n "${_RETRO_EVENTS_LOADED:-}" ]] && return 0` and sets `_RETRO_EVENTS_LOADED=1` at end of file
- [ ] `retro-events.sh` sources `utils.sh` exactly once (via `source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"`)
- [ ] `retro-events.sh` contains no top-level `set -e`, `set -u`, or `set -o pipefail`
- [ ] `superpowers/lib/observations.sh` exists, sources `retro-events.sh`, defines `log_harness_observation <component> <outcome> <reason>`
- [ ] `observations.sh` has a dual-mode footer: `if [[ "${BASH_SOURCE[0]:-$0}" == "${0}" ]]; then log_harness_observation "$@"; fi`
- [ ] `log_harness_observation` returns 0 unconditionally — never propagates failure, never writes to stderr on error paths (silent degradation)
- [ ] All tests in `tests/test_observations_sh.py` pass (exit 0)
- [ ] Full unittest suite passes — no regressions in `test_bail_log_sh.py`, `test_post_plan_diff_sh.py`, `test_phase_integration.py`, etc.
- [ ] `shellcheck` is clean on both new shell files
- [ ] No top-level `set -` at column 0 in `lib/retro-events.sh` or `lib/observations.sh` (`grep -nE '^set -' …` returns empty)
- [ ] The NDJSON row written by `log_harness_observation` has the field set `{event, component, reason, repo_root, timestamp}` in that key order

## Red-Green Pairs

| Test Task | Impl Task | Expected Red State | Expected Green State |
|-----------|-----------|--------------------|----------------------|
| 002-test | 002-impl | `python3 -m unittest tests.test_observations_sh` fails because `superpowers/lib/observations.sh` does not exist; failure is file-not-found, not Python ImportError | All tests in `tests/test_observations_sh.py` pass; full unittest suite green |

Task 001 is foundation/setup — not part of a Red-Green pair. Its done criterion is "each fixture script runs and `jq -e .` returns 0".

## Evaluation Criteria Preview

The evaluator will apply the following checklist items to this batch:

| Item ID | Description |
|---------|-------------|
| CODE-VER-01 | Verification commands exit with code 0 |
| CODE-QUAL-01 | No TODO, FIXME, HACK, XXX, or stub patterns in produced files |
| CODE-QUAL-02 | No stub implementations (`NotImplementedError`, lone `pass`, lone `...`) in produced files |

## Sign-off

- **Generator:** executing-plans
- **Timestamp:** 2026-05-12T00:00:00Z
- **Status:** READY
