# Task 004-test: skill-events.sh helper test (Red)

**depends-on**: _(none — independent Red test)_

## Description

Write the failing test file `superpowers/tests/test_skill_events_sh.py` covering the public contract of `lib/skill-events.sh::log_skill_event`. Mirrors `test_bail_log_sh.py`'s three-mode shape (Executed / Sourced / Degradation) and adds a `TestSkillEventsArgsHash` TestCase covering the `args_hash` derivation (skill-events is the only wrapper that hashes args).

## Execution Context

**Task Number**: 004-test of 15
**Phase**: Core Features (Red)
**Prerequisites**: None.

## BDD Scenario

```gherkin
Scenario: log_skill_event writes a fix_completed event from systematic-debugging Phase 4
  Given a project directory with no docs/retros folder
  And jq and shasum are in PATH
  And skill-events.sh is sourced into the current shell
  When `log_skill_event systematic-debugging fix_completed '{root_cause: $rc, fix_paths: ($fp | split(","))}' --arg rc "race in cache" --arg fp "src/cache.ts,tests/cache_test.ts"` is called
  Then the helper returns 0
  And docs/retros/skill-events.jsonl exists with exactly one NDJSON line
  And that line parses as an object with fields event=fix_completed, skill=systematic-debugging, timestamp (ISO-8601 UTC), repo_root, args_hash (sha1[:12]), and a nested payload carrying root_cause and fix_paths
  And no top-level field name in the line collides with the payload keys

Scenario: helper invoked in Executed mode writes the same record as Sourced mode
  Given an empty project directory
  And lib/skill-events.sh is executable
  When the helper is invoked as `bash lib/skill-events.sh systematic-debugging fix_completed '{root_cause:$rc}' --arg rc "stale lock"`
  Then the helper returns 0
  And docs/retros/skill-events.jsonl contains one NDJSON line matching the Sourced-mode shape
  And the Executed-mode line differs from the Sourced-mode line only in timestamp

Scenario: jq is absent from PATH
Scenario: both shasum and sha1sum are absent
Scenario: docs/retros is on a read-only filesystem
Scenario: repo_root resolution fails
Scenario: date command fails to emit an ISO-8601 timestamp
  (degradation → helper returns 0, writes nothing or writes with empty args_hash per §2.2)
```

**Spec Source**: `../2026-05-12-unified-retro-events-design/bdd-specs.md` §1.1, §1.2, §2 (all).

## Files to Modify/Create

- Create: `superpowers/tests/test_skill_events_sh.py`

## Steps

### Step 1: Verify Scenario
- Confirm scenarios above appear in `bdd-specs.md`.
- Cross-reference `architecture.md` §`lib/skill-events.sh` for the envelope: `{event, skill, timestamp, repo_root, args_hash, payload: {...}}`.

### Step 2: Implement Test (Red)
- Four TestCases:
  - `class SkillEventsExecutedTests(unittest.TestCase)`:
    - `test_executed_writes_ndjson_with_required_fields` — invoke `bash lib/skill-events.sh systematic-debugging fix_completed '{root_cause:$rc}' --arg rc "race"`; assert all envelope fields present, `payload.root_cause == "race"`, `args_hash` matches `^[0-9a-f]{12}$`, `timestamp` matches ISO-8601 UTC regex.
    - `test_payload_keys_do_not_collide_with_envelope` — assert top-level keys ∩ payload keys is empty (the envelope's `event`, `skill`, `timestamp`, `repo_root`, `args_hash` must NEVER be shadowed by payload fields).
    - `test_appends_multiple_events` — call twice; assert two distinct lines, first row byte-unchanged.
    - `test_creates_docs_retros_when_missing` — pre-condition: no `docs/retros/` dir; assert it gets created.
  - `class SkillEventsSourcedTests(unittest.TestCase)`:
    - `test_sourced_then_called_writes_entry` — source the helper, call `log_skill_event` with concrete args, assert one row appended.
    - `test_sourcing_does_not_run_main` — source the helper with no following call; assert no jsonl file appears (the `BASH_SOURCE`-vs-`$0` guard works).
    - `test_sourcing_under_set_e_does_not_abort_caller` — source under `set -euo pipefail`, call with empty payload, follow with `echo still-alive`; assert "still-alive" in stdout.
    - `test_executed_equals_sourced_modulo_timestamp` — invoke both modes with identical args, strip timestamps, assert byte-equal under `jq -S 'del(.timestamp)'`.
  - `class SkillEventsDegradationTests(unittest.TestCase)`:
    - `test_silent_skip_when_jq_missing` — PATH without jq; assert exit 0 and either no file OR no append (matching `bail-log.sh` precedent).
    - `test_args_hash_empty_when_shasum_and_sha1sum_missing` — shim PATH to remove both binaries; assert exit 0, the emitted row has `args_hash == ""`, all other fields populated normally (§2.2).
    - `test_returns_zero_when_docs_retros_unwritable`
    - `test_returns_zero_when_repo_root_empty`
    - `test_returns_zero_when_date_fails`
  - `class SkillEventsArgsHashTests(unittest.TestCase)`:
    - `test_args_hash_stable_for_identical_args` — invoke twice with the same args; assert same `args_hash` on both rows.
    - `test_args_hash_differs_for_different_args` — invoke with two distinct payloads; assert different `args_hash`.
    - `test_args_hash_format` — assert `args_hash` is exactly 12 hex chars (`^[0-9a-f]{12}$`).
- Reuse `tests/conftest.py` fixtures.
- **PROHIBITED**: do not implement `superpowers/lib/skill-events.sh`.

### Step 3: Verify Test Fails (Red)
- Run `cd superpowers && python3 -m unittest tests.test_skill_events_sh -v`. Tests MUST FAIL with file-not-found-style errors.

## Verification Commands

```bash
cd /Users/FradSer/Developer/FradSer/dotclaude/superpowers
python3 -m unittest tests.test_skill_events_sh -v
echo "Expected non-zero exit code (Red): $?"
```

## Success Criteria

- `superpowers/tests/test_skill_events_sh.py` exists with four TestCases covering Executed, Sourced, Degradation, and ArgsHash.
- Tests fail loudly when run.
- No production code touched.
