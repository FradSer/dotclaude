# Task 002-impl: observations.sh + retro-events.sh primitives impl (Green)

**depends-on**: task-002-test

## Description

Implement `superpowers/lib/retro-events.sh` (shared core, six primitives) and `superpowers/lib/observations.sh` (first thin wrapper). The wrapper exposes `log_harness_observation <component> <outcome> <reason>`, sources `retro-events.sh`, and produces the terse-row NDJSON schema defined in `architecture.md`. Goal: turn the Red test from task 002-test into Green.

**Critical**: this is the task that lands `retro-events.sh`. Tasks 003-impl and 004-impl depend on it.

## Execution Context

**Task Number**: 002-impl of 15
**Phase**: Core Features (Green)
**Prerequisites**: 002-test exists and fails (Red).

## BDD Scenario

Same Gherkin scenarios as task 002-test (the Green pair):

```gherkin
Scenario: log_harness_observation produces a row indistinguishable from the legacy Phase 5c bash block
  Given a retrospective run in Phase 5c that previously emitted the inline bash block
  When the same retrospective is run with the new helper as `log_harness_observation <component> <outcome> <reason>`
  Then the new line parses to the same JSON object shape as the legacy line
  And the field set is identical: {event, component, timestamp, reason, repo_root}
  And both lines pass `jq -e '.event and .component and .timestamp'` validation

Scenario: jq is absent from PATH
  Given a shell with PATH stripped of jq
  When the helper is invoked
  Then it returns 0 with no jsonl created and no stderr noise

Scenario: docs/retros is on a read-only filesystem
Scenario: repo_root resolution fails
Scenario: date command fails to emit an ISO-8601 timestamp
  (all → helper returns 0, writes nothing, no stderr noise)

Scenario: existing harness-observations.jsonl rows are not rewritten
  Given legacy rows in the file
  When log_harness_observation appends a new row
  Then prior rows are byte-unchanged and the file remains a valid NDJSON stream
```

**Spec Source**: `../2026-05-12-unified-retro-events-design/bdd-specs.md` §1.3, §2 (all), §5.3.

## Files to Modify/Create

- Create: `superpowers/lib/retro-events.sh` — shared core, six primitives per `architecture.md` §`lib/retro-events.sh`:
  - `jq_or_skip` — `command -v jq >/dev/null 2>&1 || return 0`
  - `timestamp_or_skip` — prints ISO-8601 UTC; returns 1 if `date` fails or empty
  - `ensure_log_dir <abs_path>` — `mkdir -p`, returns 0/1
  - `repo_root_or_skip` — wraps `utils.sh::repo_root`, returns 1 if empty
  - `write_jsonl <log_file> <jq_program> [jq_args...]` — `jq -nc … >> $log_file`, all failures swallowed, returns 0 unconditionally
  - `dedup_check <log_file> <substring>` — `tail -n 200 | grep -qF`, returns 0 if substring found
- Create: `superpowers/lib/observations.sh` — sources `retro-events.sh`, defines `log_harness_observation <component> <outcome> <reason>`, ends with dual-mode footer.

## Steps

### Step 1: Confirm Red
- Run `cd superpowers && python3 -m unittest tests.test_observations_sh -v`. Confirm tests fail (file-not-found).

### Step 2: Implement retro-events.sh
- Function signatures only — DO NOT write the function bodies in this task file.
- Required signatures (from `architecture.md`):
  - `jq_or_skip() { … }` — returns 0/1
  - `timestamp_or_skip() { … }` — prints timestamp to stdout
  - `ensure_log_dir() { … }` — `$1` is the abs path
  - `repo_root_or_skip() { … }` — prints repo root to stdout
  - `write_jsonl() { … }` — `$1` is log file, `$2` is jq program, `$3...` are jq args
  - `dedup_check() { … }` — `$1` is log file, `$2` is substring
- Module loader idiom (mirror `bail-log.sh`):
  - `[[ -n "${_RETRO_EVENTS_LOADED:-}" ]] && return 0`
  - `source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"` (single source; `utils.sh` self-guards with `_SUPERPOWERS_DEPS_CHECKED`)
  - `_RETRO_EVENTS_LOADED=1` at end of file
- **No top-level `set -e`, `set -u`, or `set -o pipefail`** (NF3).

### Step 3: Implement observations.sh
- File header: source `retro-events.sh` via `source "$(dirname "${BASH_SOURCE[0]}")/retro-events.sh"`.
- Function signature: `log_harness_observation() { local component=$1 outcome=$2 reason=$3; … }` (interface only — body is the implementer's work).
- The function must:
  - Call `jq_or_skip || return 0`
  - Resolve `repo_root` via `repo_root_or_skip` or `return 0`
  - Resolve timestamp via `timestamp_or_skip` or `return 0`
  - `ensure_log_dir "$repo_root/docs/retros" || return 0`
  - Call `write_jsonl "$repo_root/docs/retros/harness-observations.jsonl" '<jq filter for terse row>' --arg event "$outcome" --arg component "$component" --arg reason "$reason" --arg repo_root "$repo_root" --arg timestamp "$timestamp"`
- Dual-mode footer (verbatim from `bail-log.sh` pattern): `if [[ "${BASH_SOURCE[0]:-$0}" == "${0}" ]]; then log_harness_observation "$@"; fi`
- **PROHIBITED**: do NOT write the full jq filter logic body or the full body of any primitive — leave those as the implementer's contract-driven implementation. This task file declares the signatures and the contract; the implementer fills the bodies under the Green test.

### Step 4: Verify Test Passes (Green)
- Run `cd superpowers && python3 -m unittest tests.test_observations_sh -v`.
- **Verification**: all tests MUST PASS.
- Run the full suite: `cd superpowers && python3 -m unittest discover -s tests -v`. No regressions.

### Step 5: Refactor
- If any production code repeats a primitive, hoist it into `retro-events.sh`.
- Confirm no `set -` line at column 0 in either file (`grep -nE '^set -' superpowers/lib/retro-events.sh superpowers/lib/observations.sh` must be empty).
- Confirm `shellcheck` is clean: `shellcheck superpowers/lib/retro-events.sh superpowers/lib/observations.sh`.

## Verification Commands

```bash
cd /Users/FradSer/Developer/FradSer/dotclaude/superpowers

# Targeted test
python3 -m unittest tests.test_observations_sh -v

# Full suite — no regressions
python3 -m unittest discover -s tests -v

# Lint
shellcheck lib/retro-events.sh lib/observations.sh

# Style asserts
grep -nE '^set -' lib/retro-events.sh lib/observations.sh && echo "FAIL: top-level set found" || echo "OK: no top-level set"
```

## Success Criteria

- `superpowers/lib/retro-events.sh` exists with six primitives matching `architecture.md` signatures.
- `superpowers/lib/observations.sh` exists with `log_harness_observation` and dual-mode footer.
- All tests in `tests/test_observations_sh.py` pass.
- Full unittest suite passes (no regressions in `test_bail_log_sh.py`, `test_post_plan_diff_sh.py`, etc.).
- `shellcheck` clean on both new files.
- No top-level `set -` in either file.
