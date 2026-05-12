# Task 003: skill-events.sh Wrapper — Tests (Red)

**depends-on**: task-002-retro-events-impl

## Description

Write failing tests for `lib/skill-events.sh`, the wrapper `helper` that exposes `log_skill_event <skill> <event> <payload_jq_filter> [args...]` and writes to `docs/retros/skill-events.jsonl` (a new `channel`). This task pins the functional contract for the `fix_completed` payload, the executed-vs-sourced parity, the bounded dedup window (same-session only), and the absence of cross-session dedup.

The envelope is `{event, skill, timestamp, repo_root, args_hash, payload}` — the `payload` sub-object is the caller's filter output, nested under the envelope so top-level field names cannot collide with caller-supplied keys (BDD §1.1: "no top-level field name in the line collides with the payload keys").

## Execution Context

**Task Number**: 003 of 21
**Phase**: Core lib helpers
**Prerequisites**: Task 002 impl shipped `lib/retro-events.sh`. The wrapper sources it.

## BDD Scenarios

```gherkin
Scenario: log_skill_event writes a fix_completed event from systematic-debugging Phase 4
  Given a project directory with no docs/retros/ folder
  And jq and shasum are in PATH
  And skill-events.sh is sourced into the current shell
  When log_skill_event systematic-debugging fix_completed '{root_cause: $rc, fix_paths: ($fp | split(","))}' --arg rc "race in cache" --arg fp "src/cache.ts,tests/cache_test.ts" is called
  Then the helper returns 0
  And docs/retros/skill-events.jsonl exists with exactly one NDJSON line
  And that line parses as an object with fields event=fix_completed, skill=systematic-debugging, timestamp (ISO-8601 UTC), repo_root, args_hash (sha1[:12]), and a nested payload carrying root_cause and fix_paths
  And no top-level field name in the line collides with the payload keys

Scenario: helper invoked in Executed mode writes the same record as Sourced mode
  Given an empty project directory
  And the helper file lib/skill-events.sh is executable
  When the helper is invoked as bash lib/skill-events.sh systematic-debugging fix_completed '{root_cause:$rc}' --arg rc "stale lock"
  Then the helper returns 0
  And docs/retros/skill-events.jsonl contains one NDJSON line matching the Sourced-mode shape for the same arguments
  And the Executed-mode line differs from the Sourced-mode line only in timestamp

Scenario: both shasum and sha1sum are absent
  Given a shell where neither shasum nor sha1sum is in PATH
  And jq is available
  When log_skill_event systematic-debugging fix_completed '{x:1}' --arg foo "bar" is executed
  Then the helper returns 0
  And the emitted NDJSON line has args_hash equal to the empty string
  And every other field (event, skill, timestamp, repo_root, payload) is populated normally

Scenario: a single systematic-debugging invocation emits fix_completed only once
  Given systematic-debugging Phase 4 has executed its terminal "Verify Fix" step
  And the helper has already appended one fix_completed row for this invocation
  When the same Phase 4 block is re-entered within the same session (e.g., user re-runs the verify step)
  Then a second fix_completed row is NOT appended
  And the dedup decision is made by tail-scanning the last 200 lines of skill-events.jsonl for a matching (skill, event, args_hash) triple within a bounded recent window

Scenario: cross-session dedup is intentionally absent
  Given two separate Claude sessions debug the same symptom on the same repo on different days
  When both reach Phase 4 and call log_skill_event systematic-debugging fix_completed
  Then both invocations append a row
  And the two rows differ by timestamp and likely by args_hash (different $ARGUMENTS phrasing)
  And no helper attempts to suppress the second row — cross-session dedup is the responsibility of retrospective Phase 5a aggregation, not the emission helper
```

**Spec Source**: `../2026-05-12-unified-retro-events-design/bdd-specs.md` §1.1, §1.2, §2.2, §6.22, §6.23

## Files to Modify/Create

- Modify: `superpowers/tests/test_skill_events_sh.py` (created empty in Task 001).

## Steps

### Step 1: Test Helpers
- Add module constant `SKILL_EVENTS_SH = SUPERPOWERS_DIR / "lib" / "skill-events.sh"`.
- Add `run_executed(cwd, *args, env=None)` and `run_sourced(cwd, body, env=None)` helpers mirroring `test_bail_log_sh.py:22-41`.

### Step 2: TestCase — `SkillEventsExecutedTests`
- `test_executed_writes_envelope_with_nested_payload` — invoke `log_skill_event systematic-debugging fix_completed '{root_cause:$rc, fix_paths:($fp|split(","))}' --arg rc "race in cache" --arg fp "src/cache.ts,tests/cache_test.ts"`; parse one-line jsonl; assert envelope = `{event, skill, timestamp, repo_root, args_hash, payload}`; assert `payload.root_cause == "race in cache"`; assert `payload.fix_paths == ["src/cache.ts", "tests/cache_test.ts"]`; assert `event == "fix_completed"` and `skill == "systematic-debugging"`. **Negative**: assert `"root_cause" not in entry` (payload-collision guard). (Scenario §1.1)
- `test_executed_timestamp_format` — regex `^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$`. (§1.1)
- `test_executed_repo_root_resolves` — `Path(entry["repo_root"]).resolve() == cwd.resolve()` (account for the macOS `/var → /private/var` quirk per `test_bail_log_sh.py:64-66`). (§1.1)
- `test_executed_args_hash_format` — regex `^[a-f0-9]{12}$` when shasum present. (§1.1)

### Step 3: TestCase — `SkillEventsSourcedTests`
- `test_sourced_writes_same_envelope` — body `source ${SKILL_EVENTS_SH}; log_skill_event systematic-debugging fix_completed '{root_cause:$rc}' --arg rc "stale lock"`; assert exit 0; assert one row; compare to executed-mode row (minus timestamp + args_hash if args differ). (§1.2)
- `test_sourcing_does_not_run_main_branch` — body `source ${SKILL_EVENTS_SH}` only, no call; assert no jsonl file created. (Helper file's executed-mode guard works.)
- `test_sourcing_under_set_e_does_not_abort` — body `source ${SKILL_EVENTS_SH}; log_skill_event "" "" "" ; echo still alive`; assert stdout contains "still alive"; exit 0.
- `test_sourced_and_executed_lines_differ_only_in_timestamp` — produce one of each with identical args; `jq -S 'del(.timestamp)'` on both; assert byte-equal. (§1.2)

### Step 4: TestCase — `SkillEventsDegradationTests`
- `test_returns_zero_when_jq_missing` — `env={"PATH": "/usr/bin:/bin"}` (sanitised so jq is absent on the dev host — adapt per the existing `test_bail_log_sh.py` precedent for CI; on Linux CI, jq may still be in `/usr/bin`. Mirror the precedent comment.). (§2.1)
- `test_args_hash_empty_when_shasum_and_sha1sum_missing` — shim PATH to a sandbox without either; assert `entry["args_hash"] == ""` and other fields populated. (§2.2)
- `test_returns_zero_when_docs_retros_unwritable` — `chmod 0500` cwd; assert exit 0 and no jsonl file appears in cwd or `/tmp`. (§2.3)
- `test_returns_zero_when_repo_root_empty` — `env={"CLAUDE_PROJECT_DIR": "", "PWD": ""}` outside a git work tree; assert exit 0 and no jsonl created. (§2.4)
- `test_returns_zero_when_date_fails` — shim PATH so `date` exits non-zero; assert exit 0 and no jsonl created. (§2.5)

### Step 5: TestCase — `SkillEventsDedupTests`
- `test_same_args_within_session_appends_only_once` — call `log_skill_event systematic-debugging fix_completed '{x:1}' --arg foo bar` twice within one `bash -c` body; assert the resulting jsonl has exactly **one** line and that line carries the expected envelope. (§6.22)
- `test_dedup_window_is_last_200_lines` — pre-seed jsonl with 199 unrelated rows, then a row matching `(skill, event, args_hash)`, then call once more with the same args; assert no new line appended (match found in tail-200). Then pre-seed 200 unrelated rows after the matching row + one trailing line and call again; assert the helper APPENDS (match outside the tail-200 window) — this proves the bound is the 200-line tail, not the full file. (§6.22 "bounded recent window")
- `test_different_args_within_session_appends_both` — same skill+event, different `--arg`; assert two distinct lines (different args_hash). (§6.22 inverse)
- `test_no_cross_session_dedup` — call once in one `bash -c` invocation, again in a separate `bash -c` invocation with identical args. Assert two rows appear: cross-process dedup is intentionally absent. (§6.23)

### Step 6: TestCase — `SkillEventsPlansCompletedIsolationTests`
- `test_helper_never_touches_plans_completed_jsonl` — pre-seed `docs/retros/plans-completed.jsonl` with a known row; record `(mtime, sha256)`; call `log_skill_event` 5 times; reassert `(mtime, sha256)` unchanged. (§5.18 — was xfailed in Task 002; this is the canonical re-verification once skill-events.sh exists.)

### Step 7: Confirm RED
- Run module; expect every test to FAIL (`lib/skill-events.sh` missing).

## Verification Commands

```bash
cd /Users/FradSer/Developer/FradSer/dotclaude
python3 -m pytest superpowers/tests/test_skill_events_sh.py -v 2>&1 | tail -40
# Expect: every test FAILS
```

## Success Criteria

- `test_skill_events_sh.py` ships ≥ 16 test methods across five TestCases.
- Each BDD scenario above maps to ≥ one named test.
- Every test fails RED.
- The envelope-vs-payload structure is the assertion centerpiece — payload key collision is checked negatively in `test_executed_writes_envelope_with_nested_payload`.
