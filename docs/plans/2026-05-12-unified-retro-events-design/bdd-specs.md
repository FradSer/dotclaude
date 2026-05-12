# Unified Retro Events — BDD Specifications

Behavior contracts for the four new lib helpers (`retro-events.sh`,
`observations.sh`, `evolution-log.sh`, `skill-events.sh`) and the single
new emission point added to `systematic-debugging` Phase 4. Vocabulary
stays consistent with the architecture sub-agent: **helper**, **channel**,
**event**, **skill**, **emission point**.

The shared core `retro-events.sh` is sourced by the three channel helpers;
each owns one jsonl channel under `docs/retros/`. `skill-events.sh`
exposes `log_skill_event <skill> <event> <payload_jq_filter> [args]`. All
helpers mirror `bail-log.sh`: sourceable + executable dual mode,
best-effort throughout, never blocks the caller.

---

## 1. Helper Functional Behavior

### Scenario: log_skill_event writes a fix_completed event from systematic-debugging Phase 4

  Given a project directory with no `docs/retros/` folder
  And `jq` and `shasum` are in PATH
  And `skill-events.sh` is sourced into the current shell
  When `log_skill_event systematic-debugging fix_completed '{root_cause: $rc, fix_paths: ($fp | split(","))}' --arg rc "race in cache" --arg fp "src/cache.ts,tests/cache_test.ts"` is called
  Then the helper returns 0
  And `docs/retros/skill-events.jsonl` exists with exactly one NDJSON line
  And that line parses as an object with fields `event=fix_completed`, `skill=systematic-debugging`, `timestamp` (ISO-8601 UTC), `repo_root`, `args_hash` (sha1[:12]), and a nested `payload` carrying `root_cause` and `fix_paths`
  And no top-level field name in the line collides with the payload keys

### Scenario: helper invoked in Executed mode writes the same record as Sourced mode

  Given an empty project directory
  And the helper file `lib/skill-events.sh` is executable
  When the helper is invoked as `bash lib/skill-events.sh systematic-debugging fix_completed '{root_cause:$rc}' --arg rc "stale lock"`
  Then the helper returns 0
  And `docs/retros/skill-events.jsonl` contains one NDJSON line matching the Sourced-mode shape for the same arguments
  And the Executed-mode line differs from the Sourced-mode line only in `timestamp`

### Scenario: log_harness_observation produces a row indistinguishable from the legacy Phase 5c bash block

  Given a retrospective run in Phase 5c that previously emitted the inline bash:
  ```
  jq -nc --arg event "component_unsupported" --arg c "$id" --arg ts "$now" --arg retro "$report" \
    '{event:$event, component:$c, timestamp:$ts, retrospective_id:$retro}' \
    >> docs/retros/harness-observations.jsonl
  ```
  When the same retrospective is run with the new helper as `log_harness_observation component_unsupported '{component:$c, retrospective_id:$retro}' --arg c "<id>" --arg retro "<report>"`
  Then the new line parses to the same JSON object shape as the legacy line
  And the field set is identical: `{event, component, timestamp, retrospective_id}`
  And the field order in serialized form is identical
  And both lines pass `jq -e '.event and .component and .timestamp'` validation

### Scenario: log_evolution_event mirrors the legacy retrospective_run schema verbatim

  Given a retrospective Phase 6 closure that previously hand-built the `retrospective_run` JSON with `jq -nc` and `--argjson self_value`
  When the same closure is rewritten as `log_evolution_event retrospective_run '<filter>' --argjson sv "$self_value_json" ...`
  Then the produced line is byte-equivalent to the legacy line under deterministic timestamp substitution
  And nested sub-objects (`self_value`, optional `post_plan_diff`) preserve their key order and field types
  And `post_plan_diff` is omitted (not nullified) when no plan in `plans_analyzed` carries a `completion_commit`

### Scenario: the three channel helpers source retro-events.sh which sources utils.sh exactly once

  Given a shell with `BASH_SOURCE` tracking enabled
  When `observations.sh`, `evolution-log.sh`, and `skill-events.sh` are sourced in the same shell session in any order
  Then `utils.sh` is sourced exactly once
  And `_SUPERPOWERS_DEPS_CHECKED` is set to `1` after the first source and is not re-evaluated on the second or third
  And no duplicate warning lines about missing deps appear on stderr

---

## 2. Best-effort Degradation

These scenarios mirror the contract proven in `tests/test_bail_log_sh.py`:
under any environmental fault the helper returns 0, writes nothing, and
emits no stack trace.

### Scenario: jq is absent from PATH

  Given a shell with PATH stripped of `jq`
  When `log_skill_event systematic-debugging fix_completed '{x:1}'` is executed
  Then the helper returns 0
  And `docs/retros/skill-events.jsonl` is not created
  And `set -euo pipefail` in the calling shell does not abort

### Scenario: both shasum and sha1sum are absent

  Given a shell where neither `shasum` nor `sha1sum` is in PATH
  And `jq` is available
  When `log_skill_event systematic-debugging fix_completed '{x:1}' --arg foo "bar"` is executed
  Then the helper returns 0
  And the emitted NDJSON line has `args_hash` equal to the empty string
  And every other field (`event`, `skill`, `timestamp`, `repo_root`, `payload`) is populated normally

### Scenario: docs/retros is on a read-only filesystem

  Given a project directory where `mkdir -p docs/retros` fails (read-only mount or denied permission)
  When any helper in the family is invoked
  Then the helper returns 0
  And no error appears on the caller's stdout
  And the caller's exit status under `set -e` is unchanged

### Scenario: repo_root resolution fails

  Given an environment with `CLAUDE_PROJECT_DIR` unset, not inside a git work tree, and `PWD` unset
  When any helper in the family is invoked
  Then `repo_root` returns an empty string
  And the helper returns 0 before attempting any file operation
  And no NDJSON line is emitted anywhere

### Scenario: date command fails to emit an ISO-8601 timestamp

  Given a shell where `date -u +"%Y-%m-%dT%H:%M:%SZ"` errors out
  When any helper in the family is invoked
  Then the helper returns 0 without writing any NDJSON line
  And the caller is unaffected

---

## 3. Migration Parity

These are the load-bearing guarantees for the cut-over: existing
retrospective code paths must keep parsing the same on day one. The
golden test fixtures live alongside `tests/test_bail_log_sh.py`.

### Scenario: Phase 5c legacy bash vs log_harness_observation produce identical channel rows

  Given a fixture `tests/fixtures/legacy-harness-observation.jsonl` written by the pre-migration bash block
  When the same logical event is re-emitted via `log_harness_observation` with matching args
  Then both lines have field set `{event, component, timestamp, retrospective_id}` with identical key order and JSON types
  And `jq -S 'del(.timestamp)'` produces byte-equal output on both lines

### Scenario: Phase 6 closure legacy bash vs log_evolution_event produce identical retrospective_run rows

  Given a fixture `tests/fixtures/legacy-retrospective-run.jsonl` from the pre-migration Phase 6 closure
  When the same closure is re-emitted via `log_evolution_event retrospective_run ...`
  Then top-level keys match in order and nested sub-objects (`self_value`, `post_plan_diff` when present) match in key order
  And `disable_test` stays `null` or a supported identifier — never a free-text component name

### Scenario: retrospective Phase 1 consumer parses old and new rows identically

  Given `docs/retros/evolution-log.jsonl` contains a mix of legacy and helper-emitted lines
  When retrospective Phase 1 step 5 builds the per-`item_id` history table
  And Pre-Check B reads `consecutive_zero_change` from the most recent `retrospective_run`
  Then no parser branches on row origin and no "schema_version" field is consulted

---

## 4. systematic-debugging Phase 4 Emission

The Phase 4 emission is the only new emission point introduced by this
design. Phases 1, 2, and 3 do NOT emit. Bail-out events are already
covered by `bail-log.sh` and must not be duplicated here.

### Scenario: Phase 4 emits fix_completed after root cause is confirmed, fix applied, and regression test passes

  Given systematic-debugging has completed Phases 1–3
  And Phase 4 has confirmed a single failing-test reproduction
  And Phase 4 has applied a single localized fix
  And the regression test now passes on the local working tree
  When Phase 4 reaches its terminal step (end of "Verify Fix")
  Then `log_skill_event systematic-debugging fix_completed` is invoked exactly once
  And the emitted line carries `skill=systematic-debugging`, `event=fix_completed`
  And the `payload` sub-object includes the root cause one-liner and the regression test path
  And the `payload` does not include test stdout, test stderr, or the fix diff text

### Scenario: Bail-out path does not emit a fix_completed event

  Given systematic-debugging detected "named root cause + named fix" at the top-of-skill bail-out check
  And `bail-log.sh` has already emitted a `bail_out` event into `bail-out-events.jsonl`
  When the direct-edit-plus-regression-test path completes
  Then no `fix_completed` event is appended to `skill-events.jsonl`
  And the bail-out channel and the skill-events channel each carry exactly one row for this invocation

### Scenario: skill_name is read from the session state file, not hardcoded

  Given the running session's state file has `skill_name = "systematic-debugging"`
  When Phase 4 emission fires
  Then the helper receives `"systematic-debugging"` as its first positional argument
  And the value is sourced through the same `state_read` path used by `_loop_log_plan_completion_if_executing`
  And if the state file is missing or `skill_name` is empty, the emission silently skips and returns 0

### Scenario: Architecture-questioning branch (≥3 failed fixes) does not emit fix_completed

  Given Phase 4 has cycled three times without a passing regression test
  When the skill transitions to "question the architecture" and hands control back to the user
  Then no `fix_completed` event is appended (the fix is not complete)
  And no replacement event such as `fix_abandoned` is appended in this iteration (out of scope for this design)

---

## 5. Backward Compatibility

### Scenario: existing plans-completed.jsonl rows are not rewritten

  Given a project with a populated `docs/retros/plans-completed.jsonl` from `_loop_log_plan_completion_if_executing`
  When the migration is applied and any new helper runs
  Then `plans-completed.jsonl` is not opened for write by any of the four new helpers
  And the file's mtime is unchanged
  And `_loop_log_plan_completion_if_executing` continues to write to it through its existing path

### Scenario: existing harness-observations.jsonl rows are not rewritten

  Given a project with legacy rows in `docs/retros/harness-observations.jsonl`
  When `log_harness_observation` appends a new row
  Then the appended row is added at end-of-file
  And no in-place edit, no truncation, and no schema-rewrite pass touches prior rows
  And the file remains a valid NDJSON stream

### Scenario: existing evolution-log.jsonl rows are not rewritten

  Given a project with legacy `item_added` / `item_removed` / `retrospective_run` rows in `docs/retros/evolution-log.jsonl`
  When `log_evolution_event` appends a new row
  Then prior rows are byte-unchanged
  And the consumer in retrospective Phase 1 step 5 (per-`item_id` history table) reads the file as a single homogeneous stream

### Scenario: retrospective Phase 1 step 2 evaluation glob behavior is unchanged

  Given a plan directory with `evaluation-design-round-1.md`, `evaluation-plan-round-2.md`, and `evaluation-round-1.md`
  When retrospective Phase 1 step 2 enumerates evaluation reports
  Then the same three files are discovered as before the migration
  And no helper in the new family is invoked during the discovery phase

---

## 6. Dedup

### Scenario: a single systematic-debugging invocation emits fix_completed only once

  Given systematic-debugging Phase 4 has executed its terminal "Verify Fix" step
  And the helper has already appended one `fix_completed` row for this invocation
  When the same Phase 4 block is re-entered within the same session (e.g., user re-runs the verify step)
  Then a second `fix_completed` row is NOT appended
  And the dedup decision is made by tail-scanning the last 200 lines of `skill-events.jsonl` for a matching `(skill, event, args_hash)` triple within a bounded recent window

### Scenario: cross-session dedup is intentionally absent

  Given two separate Claude sessions debug the same symptom on the same repo on different days
  When both reach Phase 4 and call `log_skill_event systematic-debugging fix_completed`
  Then both invocations append a row
  And the two rows differ by `timestamp` and likely by `args_hash` (different `$ARGUMENTS` phrasing)
  And no helper attempts to suppress the second row — cross-session dedup is the responsibility of retrospective Phase 5a aggregation, not the emission helper

---

# Testing Strategy

The Python test module `tests/test_retro_events_sh.py` mirrors the
TestCase structure of `tests/test_bail_log_sh.py`. Each TestCase below
lists at least three `test_*` function names plus the assertions they
own. All tests use `tempfile.TemporaryDirectory` for the project root
and run helpers via `subprocess.run` to keep the Python-vs-bash boundary
honest.

## TestRetroEventsExecuted

Verifies the `bash lib/<helper>.sh args...` direct-execution path.

- `test_skill_events_executed_writes_ndjson_with_required_fields` —
  invoke `lib/skill-events.sh systematic-debugging fix_completed '{root_cause:$rc}' --arg rc "race"`;
  assert exit 0, `docs/retros/skill-events.jsonl` exists, line carries
  `event`, `skill`, `timestamp` (ISO-8601 regex), `repo_root` (resolves
  to tmpdir via `Path.resolve()` for the `/private/var` quirk), `args_hash`
  (sha1[:12] regex), and a non-empty `payload.root_cause`.
- `test_observations_executed_matches_legacy_field_set` —
  invoke `lib/observations.sh component_unsupported '{component:$c, retrospective_id:$r}' --arg c plan_evaluator --arg r docs/retros/x.md`;
  assert the emitted line's key set equals `{event, component, timestamp, retrospective_id}`
  with no extra keys.
- `test_evolution_log_executed_appends_to_existing_file` —
  pre-seed `docs/retros/evolution-log.jsonl` with one legacy line; invoke
  the helper twice; assert the file has 3 lines, the first is byte-equal
  to the seed, and lines 2 and 3 are valid JSON.

## TestRetroEventsSourced

Verifies the `source + call function` path under `set -euo pipefail`.

- `test_sourced_log_skill_event_writes_entry` —
  source `lib/skill-events.sh`; call `log_skill_event` with concrete args;
  assert exit 0 and the emitted row matches the Executed-mode row modulo
  timestamp.
- `test_sourcing_does_not_run_main_branch` —
  source the helper with no following call; assert no jsonl file is
  created (the BASH_SOURCE-vs-`$0` guard works).
- `test_sourcing_under_set_e_does_not_abort_caller` —
  source the helper, call `log_skill_event "" "" ""` with empty args,
  follow with `echo still alive`; assert "still alive" appears in stdout
  and exit code is 0.
- `test_three_helpers_share_utils_sh_single_source` —
  source all three channel helpers in sequence; assert
  `_SUPERPOWERS_DEPS_CHECKED=1` is set and stderr contains at most one
  deps-warning line.

## TestRetroEventsDegradation

All scenarios from §2 (Best-effort Degradation) above.

- `test_silent_skip_when_jq_missing` —
  run helper with `env={"PATH": "/usr/bin:/bin"}`; assert exit 0 and
  either no file written or (if jq exists in `/usr/bin` on Linux CI) the
  write succeeded — both are valid degradation outcomes per `bail-log.sh`
  precedent.
- `test_args_hash_empty_when_shasum_and_sha1sum_missing` —
  shim PATH to a sandbox without either binary; assert the emitted row
  has `args_hash=""` and all other fields are present.
- `test_returns_zero_when_docs_retros_unwritable` —
  `chmod -w` the project root; invoke helper; assert exit 0 and no jsonl
  file was created in a writable sibling directory either.
- `test_returns_zero_when_repo_root_empty` —
  invoke with `env={"CLAUDE_PROJECT_DIR": "", "PWD": ""}` outside a git
  repo; assert exit 0 and no jsonl appears anywhere.

## TestMigrationParity

The single most important TestCase — proves the migration is invisible.

- `test_harness_observation_parity_with_legacy_bash_block` —
  generate one row via the legacy inline bash (kept as a fixture in
  `tests/fixtures/legacy-harness-observation.sh`); generate one row via
  the new helper with matching args; assert
  `jq -S 'del(.timestamp)'` produces byte-equal output on both lines.
- `test_evolution_log_retrospective_run_parity` —
  same approach with the Phase 6 closure fixture; include nested
  `self_value` and an optional `post_plan_diff`; assert key order and
  type identity.
- `test_consumer_parses_mixed_stream_identically` —
  build `evolution-log.jsonl` with `[legacy_row, helper_row, legacy_row]`;
  run a minimal Python re-implementation of retrospective Phase 1 step 5
  (per-`item_id` history table); assert the resulting dict has no
  branching on row origin and all three rows contribute.

## TestSkillEventsSystematicDebugging

End-to-end Phase 4 emission contract.

- `test_phase_4_emits_fix_completed_once` —
  drive a minimal harness that simulates Phase 4 terminal step calling
  `log_skill_event systematic-debugging fix_completed ...`; assert
  exactly one row appears in `skill-events.jsonl`.
- `test_phase_4_dedup_within_session` —
  invoke the Phase 4 emission twice with identical args within the same
  bash session; assert the second call detects the prior row via the
  tail-200 scan and does not append a duplicate.
- `test_bail_out_path_does_not_emit_fix_completed` —
  simulate the top-of-skill bail-out branch firing; assert
  `bail-out-events.jsonl` has one row and `skill-events.jsonl` has zero.
- `test_skill_name_sourced_from_state_file` —
  prepare a state file with `skill_name=systematic-debugging`; invoke
  the helper indirectly through a shim that reads the state file;
  assert the emitted row carries `skill=systematic-debugging` and not
  the literal string `"unknown"` (the helper default).
