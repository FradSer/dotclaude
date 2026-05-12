# Task 009: systematic-debugging Phase 4 fix_completed Emission — Tests (Red)

**depends-on**: task-003-skill-events-impl

## Description

Write failing tests that pin the **only new emission point** introduced by this design: the end of `systematic-debugging` Phase 4 step 3 ("Verify Fix") on the success branch. The emission calls `log_skill_event systematic-debugging fix_completed ...` with a payload containing `symptom`, `root_cause`, `regression_test_path`, `investigation_phase_count`, and optionally `fix_commit`. The bail-out branch and the architecture-questioning branch (Phase 4 cycled ≥3 times without a passing test) do **NOT** emit. The `skill_name` value is sourced from the session state file, not hardcoded.

> **Design conflict note**: `architecture.md` §"Integration Points → systematic-debugging SKILL.md Phase 4" includes the sentence "The bail-out path MUST emit `fix_completed` with `investigation_phase_count = 1`". `bdd-specs.md` §4 Scenario "Bail-out path does not emit a fix_completed event" says the opposite. Per the writing-plans skill mandate ("Tasks must be driven by BDD scenarios"), this plan FOLLOWS BDD: **bail-out does NOT emit `fix_completed`**. The test in this task encodes that BDD-aligned contract. This conflict must be reconciled in the design folder before Phase 6 (a follow-up brainstorming round) — `_index.md` records the conflict.

Tests target SKILL.md textual contract; behavioral checks (envelope shape, dedup) live on the helper's own test file (`test_skill_events_sh.py` from Task 003) and are not duplicated here.

## Execution Context

**Task Number**: 009 of 21
**Phase**: systematic-debugging emission point
**Prerequisites**: Task 003 impl (helper exists).

## BDD Scenarios

```gherkin
Scenario: Phase 4 emits fix_completed after root cause is confirmed, fix applied, and regression test passes
  Given systematic-debugging has completed Phases 1–3
  And Phase 4 has confirmed a single failing-test reproduction
  And Phase 4 has applied a single localized fix
  And the regression test now passes on the local working tree
  When Phase 4 reaches its terminal step (end of "Verify Fix")
  Then log_skill_event systematic-debugging fix_completed is invoked exactly once
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
```

**Spec Source**: `../2026-05-12-unified-retro-events-design/bdd-specs.md` §4.

## Files to Modify/Create

- Create: `superpowers/tests/test_systematic_debugging_emission.py`

## Steps

### Step 1: Test Helpers + Constants
```python
SYSTEMATIC_DEBUGGING_SKILL_MD = SUPERPOWERS_DIR / "skills" / "systematic-debugging" / "SKILL.md"
SKILL_EVENTS_SH = SUPERPOWERS_DIR / "lib" / "skill-events.sh"
```
Add a helper to read SKILL.md once per TestCase setup.

### Step 2: TestCase — `Phase4SuccessBranchEmitsTests`
- `test_phase_4_success_branch_invokes_skill_events_helper` — read SKILL.md; locate Phase 4 step 3 ("Verify Fix") success branch (anchor: the prose describing what to do after the test passes); assert `bash "${CLAUDE_PLUGIN_ROOT}/lib/skill-events.sh"` AND `fix_completed` AND `systematic-debugging` appear together in that branch.
- `test_payload_includes_required_fields` — assert the Phase 4 success-branch invocation includes `--arg`/`--argjson` for: `symptom`, `root_cause`, `regression_test_path`, `investigation_phase_count`. The `fix_commit` field is optional; the test asserts it MAY appear.
- `test_payload_excludes_test_stdout_stderr_diff` — assert NO `--arg` named `stdout`, `stderr`, `fix_diff`, `diff` exists in the Phase 4 success-branch invocation. This is the most important payload-hygiene check (BDD §4.1 "the payload does not include test stdout, test stderr, or the fix diff text"; `best-practices.md` security section reinforces).

### Step 3: TestCase — `Phase4BailOutBranchDoesNotEmitTests`
- `test_bail_out_branch_does_not_invoke_skill_events_helper` — locate the bail-out branch in SKILL.md (anchor: the prose introducing the top-of-skill bail-out check); assert the substring `lib/skill-events.sh` is ABSENT from this branch. The branch already calls `bail-log.sh` (existing behavior); the new helper must not be called here.
- `test_bail_out_path_still_invokes_bail_log` — sanity check: `lib/bail-log.sh` substring IS present in the bail-out branch (this is the existing behavior; the test guards against an accidental deletion during the migration).

### Step 4: TestCase — `Phase4ArchitectureQuestioningBranchDoesNotEmitTests`
- `test_phase_4_step_4_does_not_invoke_skill_events_helper` — locate the architecture-questioning branch in SKILL.md (anchor: prose like "If Fix Doesn't Work" or "≥3 failed fixes"); assert `lib/skill-events.sh` substring is ABSENT from this branch.
- `test_no_fix_abandoned_event_emitted` — assert the literal substring `fix_abandoned` does not appear anywhere in SKILL.md (BDD §4.4 "no replacement event such as fix_abandoned is appended in this iteration (out of scope for this design)").

### Step 5: TestCase — `Phase4SkillNameSourcedFromStateTests`
- `test_phase_4_invocation_uses_state_skill_name_not_literal` — assert the Phase 4 success-branch helper invocation passes the skill name via a shell variable (e.g., `"$SKILL_NAME"` or `"$(state_read skill_name)"`) and NOT the literal string `"systematic-debugging"` as the first positional arg. Test by regexing for a `bash "${CLAUDE_PLUGIN_ROOT}/lib/skill-events.sh"` line and asserting the FIRST arg after the script path is NOT the literal `systematic-debugging` quoted string.
- `test_state_read_skill_name_path_documented` — assert the SKILL.md prose around the emission references the state-read mechanism (substring `state_read` OR `_loop_log_plan_completion_if_executing` OR `state file` near the emission helper invocation).

### Step 6: TestCase — `Phase1Phase2Phase3DoNotEmitTests`
- `test_phases_1_2_3_have_no_skill_events_invocations` — scope SKILL.md to the Phases 1, 2, 3 sections (split on phase headings); assert `lib/skill-events.sh` substring is ABSENT from all three. Only Phase 4 emits. (Per `best-practices.md` "Do not emit from systematic-debugging Phases 1, 2, or 3".)

### Step 7: Confirm RED
- All tests fail until SKILL.md is edited.

## Verification Commands

```bash
cd /Users/FradSer/Developer/FradSer/dotclaude
python3 -m pytest superpowers/tests/test_systematic_debugging_emission.py -v 2>&1 | tail -50
# Expect: every test FAILS
```

## Success Criteria

- ≥ 9 failing tests across 5 TestCases.
- The bail-out / architecture-questioning / Phase-1/2/3 negative cases each have a dedicated test.
- The payload-hygiene test (no stdout/stderr/diff) is one of the failing tests.
- The state-sourced `skill_name` test is one of the failing tests.
