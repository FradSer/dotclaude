# Task 006-impl: Migration parity impl (Green)

**depends-on**: task-006-test

## Description

Adjust `superpowers/lib/observations.sh` and `superpowers/lib/evolution-log.sh` so each emitted NDJSON row is byte-for-byte equivalent (modulo timestamp) to the pre-migration inline `bash` block captured in task 001's fixture scripts. Likely tweaks: key order in the `jq` envelope, conditional inclusion of optional fields (`post_plan_diff`), avoidance of nulled-out fields. Goal: turn 006-test Red into Green without regressing 002/003/004/005.

## Execution Context

**Task Number**: 006-impl of 15
**Phase**: Migration Safety (Green)
**Prerequisites**: 006-test exists and fails (Red).

## BDD Scenario

```gherkin
Scenario: Phase 5c legacy bash vs log_harness_observation produce identical channel rows
Scenario: Phase 6 closure legacy bash vs log_evolution_event produce identical retrospective_run rows
Scenario: retrospective Phase 1 consumer parses old and new rows identically
Scenario: existing plans-completed.jsonl rows are not rewritten
```

**Spec Source**: `../2026-05-12-unified-retro-events-design/bdd-specs.md` §3 (all), §5.1.

## Files to Modify/Create

- Modify: `superpowers/lib/observations.sh` — adjust the envelope jq filter to match legacy key order.
- Modify: `superpowers/lib/evolution-log.sh` — adjust the merge-envelope jq filter to:
  - preserve top-level key order matching the legacy script's literal `jq -nc '{event: ..., timestamp: ..., ...}'` order
  - keep nested sub-object (`self_value`, `post_plan_diff`) key order
  - **omit** `post_plan_diff` when the caller passes no `--argjson post_plan_diff` (rather than emitting `"post_plan_diff": null`). The standard jq pattern here is `if $has_diff then {post_plan_diff: $pd} else {} end` merged into the envelope.

## Steps

### Step 1: Confirm Red
- Run `python3 -m unittest tests.test_migration_parity -v`. Confirm failure.

### Step 2: Diagnose the byte diff
- For each failing parity test, capture both lines (legacy vs helper output) into temp files.
- Run `diff <(jq -S 'del(.timestamp)' legacy.jsonl) <(jq -S 'del(.timestamp)' helper.jsonl)`.
- Identify whether the diff is:
  - Key order at top level (helper writes `{timestamp, event, ...}`, legacy writes `{event, timestamp, ...}`) — fix by reordering the jq object literal.
  - Nested key order in `self_value` or `post_plan_diff` — fix by reordering the nested object literal.
  - Presence of `post_plan_diff: null` vs absence — fix by adding the conditional-include pattern described above.
  - Type mismatch (string vs number for `consecutive_zero_change`) — fix by using `--argjson` instead of `--arg` for numeric fields in the legacy fixture (or update the helper's filter to coerce).

### Step 3: Patch the helpers
- Apply minimal changes to `lib/observations.sh` and `lib/evolution-log.sh` to close each diff. Each change is a jq filter edit; no new logic.
- **PROHIBITED**: do not change the function signatures. Do not change the test files. Do not change `retro-events.sh` primitives. The fix is strictly in the wrapper's jq envelope.

### Step 4: Verify Test Passes (Green)
- Run `python3 -m unittest tests.test_migration_parity -v`. MUST PASS.
- Run the full suite: `python3 -m unittest discover -s tests -v`. No regressions.

### Step 5: Refactor
- If the envelope jq filter in `evolution-log.sh` is now sprawling, consider hoisting the "merge + conditional include + key order" pattern into a comment block at the top of the function for the next reader.
- `shellcheck` clean.

## Verification Commands

```bash
cd /Users/FradSer/Developer/FradSer/dotclaude/superpowers
python3 -m unittest tests.test_migration_parity -v
python3 -m unittest discover -s tests -v
shellcheck lib/observations.sh lib/evolution-log.sh
```

## Success Criteria

- All four `tests/test_migration_parity.py` TestCases pass.
- Full suite green (no regressions in 002/003/004/005 tests).
- Helper output is byte-for-byte equivalent to legacy fixture output under `jq -S 'del(.timestamp)'`.
- `post_plan_diff` is omitted (not nullified) when absent.
- `plans-completed.jsonl` mtime is unchanged after all three helpers run.
