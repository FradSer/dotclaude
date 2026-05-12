# Task 002: retro-events.sh Shared Core — Tests (Red)

**depends-on**: task-001

## Description

Write the failing tests for the shared-core `helper` library `lib/retro-events.sh` — the file every wrapper helper (`skill-events.sh`, `observations.sh`, `evolution-log.sh`) will source. The core itself exposes no public skill-facing function; it owns the primitives (`jq_or_skip`, `timestamp_or_skip`, `ensure_log_dir`, `repo_root_or_skip`, `write_jsonl`, `dedup_check`) plus the single-source guard for `utils.sh`. The tests must therefore source the file directly under `set -euo pipefail` and assert each primitive's contract independently — `bash lib/retro-events.sh` is **not** a supported invocation mode (no main function), so the Executed-mode TestCase mirrors `test_bail_log_sh.py` only structurally, not in primitive coverage.

This task covers the broad-spectrum degradation contract that applies family-wide (BDD §2). Wrapper-specific tests in Tasks 003–005 re-verify a subset against their own entry points.

## Execution Context

**Task Number**: 002 of 21
**Phase**: Core lib helpers
**Prerequisites**: Task 001 has shipped `tests/test_retro_events_sh.py` as an empty module shell.

## BDD Scenarios

```gherkin
Scenario: the three channel helpers source retro-events.sh which sources utils.sh exactly once
  Given a shell with BASH_SOURCE tracking enabled
  When observations.sh, evolution-log.sh, and skill-events.sh are sourced in the same shell session in any order
  Then utils.sh is sourced exactly once
  And _SUPERPOWERS_DEPS_CHECKED is set to 1 after the first source and is not re-evaluated on the second or third
  And no duplicate warning lines about missing deps appear on stderr

Scenario: jq is absent from PATH
  Given a shell with PATH stripped of jq
  When log_skill_event systematic-debugging fix_completed '{x:1}' is executed
  Then the helper returns 0
  And docs/retros/skill-events.jsonl is not created
  And set -euo pipefail in the calling shell does not abort

Scenario: docs/retros is on a read-only filesystem
  Given a project directory where mkdir -p docs/retros fails (read-only mount or denied permission)
  When any helper in the family is invoked
  Then the helper returns 0
  And no error appears on the caller's stdout
  And the caller's exit status under set -e is unchanged

Scenario: repo_root resolution fails
  Given an environment with CLAUDE_PROJECT_DIR unset, not inside a git work tree, and PWD unset
  When any helper in the family is invoked
  Then repo_root returns an empty string
  And the helper returns 0 before attempting any file operation
  And no NDJSON line is emitted anywhere

Scenario: date command fails to emit an ISO-8601 timestamp
  Given a shell where date -u +"%Y-%m-%dT%H:%M:%SZ" errors out
  When any helper in the family is invoked
  Then the helper returns 0 without writing any NDJSON line
  And the caller is unaffected

Scenario: existing plans-completed.jsonl rows are not rewritten
  Given a project with a populated docs/retros/plans-completed.jsonl from _loop_log_plan_completion_if_executing
  When the migration is applied and any new helper runs
  Then plans-completed.jsonl is not opened for write by any of the four new helpers
  And the file's mtime is unchanged
  And _loop_log_plan_completion_if_executing continues to write to it through its existing path
```

**Spec Source**: `../2026-05-12-unified-retro-events-design/bdd-specs.md` §1.5, §2.1, §2.3, §2.4, §2.5, §5.18

## Files to Modify/Create

- Modify: `superpowers/tests/test_retro_events_sh.py` (created empty in Task 001).

## Steps

### Step 1: Add Test Helpers
- Add module-level constants:
  ```python
  RETRO_EVENTS_SH = SUPERPOWERS_DIR / "lib" / "retro-events.sh"
  ```
- Add a `run_sourced(cwd, body, env=None)` helper mirroring the one in `test_bail_log_sh.py:32-41`, but sourcing `retro-events.sh` instead.
- Add a `run_sourced_three_wrappers(cwd, body, env=None)` helper that sources all three wrapper scripts in alphabetical order (`evolution-log.sh`, `observations.sh`, `skill-events.sh`); used by the sourcing-cardinality scenario.

### Step 2: TestCase — `RetroEventsPrimitivesTests`
Add tests that source `retro-events.sh` directly and call each primitive in isolation:

- `test_jq_or_skip_returns_zero_when_jq_present` — assert function exits 0 with `jq` in PATH.
- `test_jq_or_skip_returns_one_when_jq_missing` — sanitise PATH to a directory without `jq`; assert function returns 1.
- `test_timestamp_or_skip_emits_iso8601_utc` — capture stdout; match `^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$`.
- `test_ensure_log_dir_creates_nested_path` — call with `<tmp>/docs/retros`; assert directory exists.
- `test_ensure_log_dir_returns_one_on_unwritable_parent` — `chmod 0500` a parent dir; assert non-zero exit and no directory created.
- `test_repo_root_or_skip_returns_one_when_unresolvable` — invoke with `env={"CLAUDE_PROJECT_DIR": "", "PWD": ""}` outside a git work tree; assert function returns 1 and stdout empty.
- `test_write_jsonl_appends_line_and_returns_zero` — call `write_jsonl <log> '{event:"x"}'`; assert log file has one line equal to `{"event":"x"}`.
- `test_write_jsonl_returns_zero_on_jq_filter_error` — call with a malformed jq filter; assert exit 0 and file unchanged (best-effort).
- `test_dedup_check_returns_zero_when_substring_present_in_tail_200` — pre-seed a log with a known line; call `dedup_check`; assert exit 0.
- `test_dedup_check_returns_one_when_file_missing` — call with nonexistent log; assert exit 1.

### Step 3: TestCase — `RetroEventsSourcingCardinalityTests`
- `test_three_helpers_share_utils_sh_single_source` — body sources all three wrappers; assert `_SUPERPOWERS_DEPS_CHECKED` ends `=1` and stderr contains at most one `deps` warning. (Scenario §1.5)
- `test_re_sourcing_retro_events_is_idempotent` — source `retro-events.sh` twice in the same shell; assert no double-side-effect (e.g., `_RETRO_EVENTS_LOADED` exists, primitives still callable, no stderr noise).

### Step 4: TestCase — `RetroEventsDegradationTests`
Covers the family-wide degradation scenarios; tests are run via direct primitive calls (no wrapper yet exists):

- `test_returns_zero_when_jq_missing_via_write_jsonl` — sanitise PATH; call `write_jsonl <log> '{a:1}'`; assert exit 0 and no log file. (§2.1 family flavor)
- `test_returns_zero_when_docs_retros_unwritable` — `chmod 0500` the project root; call `ensure_log_dir`; assert exit 1, then assert wrappers that chain through it (future) would short-circuit. For this task: assert `ensure_log_dir` itself returns 1 and writes nothing in a writable sibling directory. (§2.3)
- `test_repo_root_or_skip_short_circuits_under_empty_env` — covers §2.4.
- `test_timestamp_or_skip_returns_one_when_date_errors` — shim PATH to a sandbox containing only a fake `date` that exits 1; assert function returns 1. (§2.5)

### Step 5: TestCase — `RetroEventsBackwardCompatTests`
- `test_plans_completed_jsonl_is_not_touched_by_family` — create a project with a pre-populated `docs/retros/plans-completed.jsonl`; record its mtime; source `retro-events.sh` and all three wrappers (after Task 003–005 the imports will resolve; for THIS task the test is initially xfailed pending those tasks); assert the file's mtime and contents unchanged after the sourcing block + a synthetic primitive call against a different log file. (§5.18). Mark `@unittest.expectedFailure` until Tasks 003–005 land the wrapper files; the executing-plans Phase 4 evaluator clears the xfail in Task 005's verification.

### Step 6: Confirm RED
- Run the test module. All tests in `RetroEventsPrimitivesTests`, `RetroEventsSourcingCardinalityTests`, `RetroEventsDegradationTests` MUST fail with `FileNotFoundError` or `ImportError` on `RETRO_EVENTS_SH` until Task 002 impl lands.
- Capture the failure mode (`bash: <path>: No such file or directory`) and confirm; if any test passes accidentally, fix the test before continuing.

## Verification Commands

```bash
cd /Users/FradSer/Developer/FradSer/dotclaude
python3 -m pytest superpowers/tests/test_retro_events_sh.py -v 2>&1 | tail -40
# Expect: every test FAILS (Red); the only passing tests should be the expected-failure ones (count of EXPECTED FAILURE matches xfail count).
```

## Success Criteria

- `test_retro_events_sh.py` contains four TestCases (`Primitives`, `SourcingCardinality`, `Degradation`, `BackwardCompat`) with ≥14 test methods.
- Each BDD scenario referenced above maps to at least one test method.
- `pytest` reports all non-xfail tests as FAILING (Red state achieved).
- No production code in `superpowers/lib/retro-events.sh` exists yet.
