# Task 009-test: systematic-debugging Phase 4 emission test (Red)

**depends-on**: task-004-impl

## Description

Write `superpowers/tests/test_systematic_debugging_phase4_emission.py` (or extend the existing `test_skill_events_sh.py` with a new TestCase per architecture preference — see Step 2). Covers the four §4 scenarios (Phase 4 emits `fix_completed`, bail-out does NOT emit, `skill_name` from state file, architecture-questioning branch does NOT emit) plus the two §6 dedup scenarios (single emission per session, no cross-session dedup).

Because `systematic-debugging` Phase 4 is a SKILL.md prose section (Claude follows the instruction), the test simulates the emission contract: it constructs a small bash harness that imitates Phase 4's terminal step, calling `log_skill_event` with representative args, and verifies the resulting jsonl row + dedup behavior.

## Execution Context

**Task Number**: 009-test of 15
**Phase**: Emission Point (Red)
**Prerequisites**: 004-impl shipped `skill-events.sh`.

## BDD Scenario

```gherkin
Scenario: Phase 4 emits fix_completed after root cause is confirmed, fix applied, and regression test passes
  Given systematic-debugging has completed Phases 1–3
  And Phase 4 has confirmed a single failing-test reproduction
  And Phase 4 has applied a single localized fix
  And the regression test now passes on the local working tree
  When Phase 4 reaches its terminal step (end of "Verify Fix")
  Then `log_skill_event systematic-debugging fix_completed` is invoked exactly once
  And the emitted line carries skill=systematic-debugging, event=fix_completed
  And the payload sub-object includes the root cause one-liner and the regression test path
  And the payload does not include test stdout, test stderr, or the fix diff text

Scenario: Bail-out path does not emit a fix_completed event
  Given systematic-debugging detected "named root cause + named fix" at the top-of-skill bail-out check
  And bail-log.sh has already emitted a bail_out event into bail-out-events.jsonl
  When the direct-edit-plus-regression-test path completes
  Then no fix_completed event is appended to skill-events.jsonl
  And the bail-out channel and the skill-events channel each carry exactly one row for this invocation

Scenario: skill_name is read from the session state file, not hardcoded
  Given the running session's state file has skill_name = "systematic-debugging"
  When Phase 4 emission fires
  Then the helper receives "systematic-debugging" as its first positional argument
  And the value is sourced through the same state_read path used by _loop_log_plan_completion_if_executing
  And if the state file is missing or skill_name is empty, the emission silently skips and returns 0

Scenario: Architecture-questioning branch (≥3 failed fixes) does not emit fix_completed
  Given Phase 4 has cycled three times without a passing regression test
  When the skill transitions to "question the architecture" and hands control back to the user
  Then no fix_completed event is appended (the fix is not complete)
  And no replacement event such as fix_abandoned is appended in this iteration (out of scope for this design)

Scenario: a single systematic-debugging invocation emits fix_completed only once
  Given systematic-debugging Phase 4 has executed its terminal "Verify Fix" step
  And the helper has already appended one fix_completed row for this invocation
  When the same Phase 4 block is re-entered within the same session
  Then a second fix_completed row is NOT appended
  And the dedup decision is made by tail-scanning the last 200 lines of skill-events.jsonl

Scenario: cross-session dedup is intentionally absent
  Given two separate Claude sessions debug the same symptom on the same repo on different days
  When both reach Phase 4 and call log_skill_event systematic-debugging fix_completed
  Then both invocations append a row
  And the two rows differ by timestamp and likely by args_hash
  And no helper attempts to suppress the second row
```

**Spec Source**: `../2026-05-12-unified-retro-events-design/bdd-specs.md` §4 (all), §6 (all).

## Files to Modify/Create

- Create: `superpowers/tests/test_systematic_debugging_phase4_emission.py`

## Steps

### Step 1: Verify Scenario
- Confirm all six scenarios above appear verbatim in `bdd-specs.md`.
- Cross-reference `best-practices.md` §"Do not hardcode skill_name in the systematic-debugging emission" and §"Do not duplicate the bail-out event in skill-events.jsonl".

### Step 2: Implement Test (Red)
- Create the test file (separate from `test_skill_events_sh.py` because the unit-under-test is the **SKILL.md emission contract**, not the helper itself).
- TestCases:
  - `class Phase4SuccessEmissionTests(unittest.TestCase)`:
    - `test_phase_4_terminal_emits_fix_completed_once` — drive a minimal harness script that imitates Phase 4 terminal step: source `lib/skill-events.sh`, call `log_skill_event systematic-debugging fix_completed '<payload filter>' --arg ... ...`. Assert exactly one row in `docs/retros/skill-events.jsonl`, with `skill=systematic-debugging` and `event=fix_completed`.
    - `test_payload_carries_root_cause_and_regression_test_path` — assert `payload.root_cause` and `payload.regression_test_path` are present and non-empty after the harness runs.
    - `test_payload_does_not_include_test_stdout_stderr_or_diff` — assert the payload JSON does NOT contain keys like `test_stdout`, `test_stderr`, `fix_diff`.
  - `class Phase4BailOutNonEmissionTests(unittest.TestCase)`:
    - `test_bail_out_path_does_not_emit_fix_completed` — drive a harness that calls `bash lib/bail-log.sh systematic-debugging bail_out '<args>'` (the existing bail path) and verifies `docs/retros/bail-out-events.jsonl` has one row and `docs/retros/skill-events.jsonl` has zero rows.
  - `class Phase4SkillNameSourcingTests(unittest.TestCase)`:
    - `test_skill_name_sourced_from_state_file` — prepare a fake session state file with `skill_name=systematic-debugging`, drive a harness that mirrors `_loop_log_plan_completion_if_executing`'s `state_read` to fetch `skill_name`, pass it to `log_skill_event` as `$1`. Assert the emitted row has `skill=systematic-debugging` (not literal "unknown").
    - `test_emission_skips_when_state_file_missing` — drive the harness with no state file in place; assert no row appended and exit 0.
    - `test_emission_skips_when_skill_name_empty` — state file present but `skill_name=""`; assert no row appended.
  - `class Phase4ArchitectureQuestioningTests(unittest.TestCase)`:
    - `test_no_emission_when_architecture_questioning_branch_taken` — drive a harness that imitates the ≥3 failed-fix path: invoke nothing (Phase 4 fails three times and hands off). Assert `skill-events.jsonl` does not exist OR has zero `fix_completed` rows.
    - `test_no_fix_abandoned_event_emitted` — assert no row with `event=fix_abandoned` appears (out of scope for this design — explicitly negative).
  - `class Phase4DedupTests(unittest.TestCase)`:
    - `test_same_invocation_dedupes_within_session` — drive the harness twice in the same bash invocation with identical args (same `args_hash`). Assert only one `fix_completed` row appears in the file.
    - `test_dedup_uses_tail_200_scan` — pre-seed `skill-events.jsonl` with 250 noise rows + one matching `(skill, event, args_hash)` triple at position ≤200 from the end. Invoke the emission. Assert no new row appended. Then re-seed with the triple at position >200 from the end. Invoke again. Assert a new row IS appended (the tail-200 boundary works).
  - `class Phase4CrossSessionTests(unittest.TestCase)`:
    - `test_cross_session_dedup_is_intentionally_absent` — drive the harness twice in separate bash invocations (separate `subprocess.run` calls, simulating separate Claude sessions) with the same args. Assert both rows are appended (no cross-session suppression).
    - `test_different_args_get_different_args_hash` — drive twice with different args; assert both rows appear, and `args_hash` values differ.
- **PROHIBITED**: do not modify `systematic-debugging/SKILL.md` in this task. Do not modify `lib/skill-events.sh`.

### Step 3: Verify Test Fails (Red)
- Run `cd superpowers && python3 -m unittest tests.test_systematic_debugging_phase4_emission -v`.
- **Expected failure modes**:
  - The Phase 4 emission test fails because no harness has yet been wired to call `log_skill_event` at the right point (009-impl adds this).
  - The dedup test fails because `skill-events.sh` does NOT currently dedup (per `architecture.md`, dedup is the CALLER's responsibility — the SKILL.md emission point implements the tail-200 scan, NOT the helper).
  - The skill-name-sourcing test fails because the state-read pattern is not yet implemented.

## Verification Commands

```bash
cd /Users/FradSer/Developer/FradSer/dotclaude/superpowers
python3 -m unittest tests.test_systematic_debugging_phase4_emission -v
echo "Expected non-zero exit code (Red): $?"
```

## Success Criteria

- `superpowers/tests/test_systematic_debugging_phase4_emission.py` exists with five TestCases covering all six §4 + §6 scenarios.
- Tests fail with meaningful assertion errors (the emission point and dedup logic are not yet implemented in SKILL.md).
- No production code touched.
