# Task 002-test: observations.sh helper test (Red)

**depends-on**: _(none — independent Red test)_

## Description

Write the failing test file `superpowers/tests/test_observations_sh.py` covering the public contract of `lib/observations.sh::log_harness_observation`. Mirror the three-mode structure of `tests/test_bail_log_sh.py`: an `Executed` TestCase, a `Sourced` TestCase, and a `Degradation` TestCase. The file must currently fail because `superpowers/lib/observations.sh` does not yet exist.

## Execution Context

**Task Number**: 002-test of 15
**Phase**: Core Features (Red)
**Prerequisites**: None. The test file stands on its own; it asserts file-not-found / function-not-defined as the Red failure mode.

## BDD Scenario

Bundles all `bdd-specs.md` scenarios that describe `log_harness_observation` behavior and `observations.sh` degradation:

```gherkin
Scenario: log_harness_observation produces a row indistinguishable from the legacy Phase 5c bash block
  Given a retrospective run in Phase 5c that previously emitted the inline bash block
  When the same retrospective is run with the new helper as `log_harness_observation <component> <outcome> <reason>`
  Then the new line parses to the same JSON object shape as the legacy line
  And the field set is identical: {event, component, timestamp, retrospective_id}
  And both lines pass `jq -e '.event and .component and .timestamp'` validation

Scenario: jq is absent from PATH
  Given a shell with PATH stripped of `jq`
  When `log_harness_observation <component> <outcome> <reason>` is executed
  Then the helper returns 0
  And `docs/retros/harness-observations.jsonl` is not created
  And `set -euo pipefail` in the calling shell does not abort

Scenario: docs/retros is on a read-only filesystem
  Given a project directory where `mkdir -p docs/retros` fails
  When the helper is invoked
  Then the helper returns 0 with no stderr noise

Scenario: repo_root resolution fails
  Given an environment with CLAUDE_PROJECT_DIR unset, not inside a git work tree, and PWD unset
  When the helper is invoked
  Then `repo_root` returns empty and the helper returns 0 before any file operation

Scenario: date command fails to emit an ISO-8601 timestamp
  Given a shell where `date -u +"%Y-%m-%dT%H:%M:%SZ"` errors out
  When the helper is invoked
  Then the helper returns 0 without writing any NDJSON line

Scenario: existing harness-observations.jsonl rows are not rewritten
  Given a project with legacy rows in `docs/retros/harness-observations.jsonl`
  When `log_harness_observation` appends a new row
  Then the appended row is added at end-of-file with no in-place edit, no truncation
```

**Spec Source**: `../2026-05-12-unified-retro-events-design/bdd-specs.md` §1.3, §2 (all), §5.3 (mapped to observations).

## Files to Modify/Create

- Create: `superpowers/tests/test_observations_sh.py`

## Steps

### Step 1: Verify Scenario
- Confirm `bdd-specs.md` carries the scenarios listed above.
- Confirm `tests/test_bail_log_sh.py` is the structural mirror (three TestCases: Executed / Sourced / Degradation).

### Step 2: Implement Test (Red)
- Create `superpowers/tests/test_observations_sh.py` with three TestCases:
  - `class ObservationsExecutedTests(unittest.TestCase)` — invokes `bash superpowers/lib/observations.sh <component> <outcome> <reason>` via `subprocess.run` inside a `tempfile.TemporaryDirectory` project root. Asserts:
    - exit 0
    - `docs/retros/harness-observations.jsonl` exists with exactly one NDJSON line
    - JSON keys match `{event, component, reason, repo_root, timestamp}` (terse-row schema per `architecture.md` §`lib/observations.sh`)
    - `event` value equals the `<outcome>` arg
    - `timestamp` matches the ISO-8601 UTC regex `^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$`
    - appending a row to an existing file preserves the first row byte-for-byte (covers §5.3 — no in-place rewrite)
  - `class ObservationsSourcedTests(unittest.TestCase)` — sources `lib/observations.sh` into a `bash -c 'set -euo pipefail; source …; log_harness_observation …; echo still-alive'` invocation. Asserts:
    - exit 0
    - `still-alive` appears in stdout (sourcing under `set -e` does not abort the caller)
    - resulting NDJSON row matches the Executed-mode shape modulo `timestamp`
  - `class ObservationsDegradationTests(unittest.TestCase)` — one test per §2 scenario:
    - `test_silent_skip_when_jq_missing` — PATH stripped of `jq`; assert exit 0 and no jsonl appears
    - `test_returns_zero_when_docs_retros_unwritable` — `chmod -w` the project root; assert exit 0 and no jsonl in any writable sibling
    - `test_returns_zero_when_repo_root_empty` — env without `CLAUDE_PROJECT_DIR`, not in git, no `PWD`; assert exit 0
    - `test_returns_zero_when_date_fails` — PATH stripped of `date` (or shimmed to fail); assert exit 0
- **Interface signatures only**: define the test class skeletons, helper subprocess functions, and `assert` statements. **PROHIBITED**: do NOT generate the production `observations.sh` code in this task.
- Reuse fixtures from `superpowers/tests/conftest.py` (tmpdir + isolated `CLAUDE_PROJECT_DIR`) where they match the pattern in `test_bail_log_sh.py`.

### Step 3: Verify Test Fails (Red)
- Run `cd superpowers && python3 -m unittest tests.test_observations_sh -v`.
- **Verification**: all tests MUST FAIL — most with a `FileNotFoundError` or non-zero exit because `superpowers/lib/observations.sh` does not exist yet.
- The failure must be meaningful (file-not-found / function-not-defined), not a Python `ImportError` from a typo in the test file.

## Verification Commands

```bash
cd /Users/FradSer/Developer/FradSer/dotclaude/superpowers

# Should fail loudly — observations.sh doesn't exist yet
python3 -m unittest tests.test_observations_sh -v
echo "Expected non-zero exit code (Red): $?"
```

## Success Criteria

- `superpowers/tests/test_observations_sh.py` exists with three TestCase classes.
- Tests fail when run, with file-not-found-style errors.
- Test class shape mirrors `tests/test_bail_log_sh.py`.
- No production code (`superpowers/lib/observations.sh`, `superpowers/lib/retro-events.sh`) is touched.
