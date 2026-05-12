# Task 008: Migrate retrospective Phase 6 (retrospective_run + component_reinstated) — Tests (Red)

**depends-on**: task-007-migrate-phase4-items-impl

## Description

Write failing textual-contract tests for the migration of `retrospective` Phase 6 closure — the section that emits the `retrospective_run` event (and the `component_reinstated` event when applicable) at the end of a retrospective run. The migration replaces the inline `jq -nc ... >> docs/retros/evolution-log.jsonl` blocks with `bash "${CLAUDE_PLUGIN_ROOT}/lib/evolution-log.sh" retrospective_run ...` and `... component_reinstated ...` invocations.

Sequenced AFTER Task 007 impl because both target the same file. After this task, SKILL.md should have **zero** occurrences of the legacy `>> docs/retros/evolution-log.jsonl` pattern.

This task also adds a behavioral assertion: the `consecutive_zero_change` computation (read-previous-event, compute, pass-as-`--argjson`) stays in SKILL.md — that logic is calibration-loop business, not transport, and the helper does not own it.

## Execution Context

**Task Number**: 008 of 21
**Phase**: Migration of retrospective SKILL.md
**Prerequisites**: Tasks 005 impl (helper exists), 007 impl (Phase 4 migration landed first).

## BDD Scenario

```gherkin
Scenario: Phase 6 closure legacy bash vs log_evolution_event produce identical retrospective_run rows
  Given a fixture tests/fixtures/legacy-retrospective-run.jsonl from the pre-migration Phase 6 closure
  When the same closure is re-emitted via log_evolution_event retrospective_run ...
  Then top-level keys match in order and nested sub-objects (self_value, post_plan_diff when present) match in key order
  And disable_test stays null or a supported identifier — never a free-text component name
```

**Spec Source**: `../2026-05-12-unified-retro-events-design/bdd-specs.md` §3.12; `_index.md` Migration order step 6 (closure portion).

## Files to Modify/Create

- Modify: `superpowers/tests/test_migration_parity.py` (extend with new TestCase).

## Steps

### Step 1: TestCase — `RetrospectiveMigrationPhase6ClosureTests`
- `test_phase_6_invokes_evolution_log_helper_for_retrospective_run` — scope to Phase 6 section; assert `bash "${CLAUDE_PLUGIN_ROOT}/lib/evolution-log.sh"` AND the string `retrospective_run` (as a positional arg, not just prose) appear together.
- `test_phase_6_invokes_evolution_log_helper_for_component_reinstated` — same scope; assert the `component_reinstated` invocation appears (this fires when Phase 6 vetoes a prior disable test).
- `test_no_inline_jq_to_evolution_log_anywhere` — after Task 008 impl, NO occurrence of `>> docs/retros/evolution-log.jsonl` should remain anywhere in SKILL.md. This is the strongest single-line proof the migration is complete.
- `test_phase_6_preserves_consecutive_zero_change_computation` — assert the SKILL.md prose for Phase 6 still describes computing `consecutive_zero_change` from the previous `retrospective_run` row. The computation is calibration logic that MUST stay in the skill; the helper transports it via `--argjson sv "$SELF_VALUE_JSON"`. Anchor: the variable name `consecutive_zero_change` or the prose "Pre-Check B reads consecutive_zero_change" should appear in Phase 6 text.
- `test_phase_6_retrospective_run_payload_includes_required_fields` — assert the helper invocation in Phase 6 includes `--argjson sv` (or equivalent for `self_value`) and `--arg report`, `--arg disable_test`. Required-field coverage proxy.
- `test_phase_6_post_plan_diff_is_conditionally_included` — per BDD §1.4 "post_plan_diff is omitted (not nullified)", assert Phase 6's helper invocation uses a conditional-filter expression for `post_plan_diff` (e.g., `if $has_ppd then {post_plan_diff: $ppd} else {} end` or equivalent prose like "include only when ..."). Anchor on either the conditional jq expression or the documented prose; the test accepts both forms.

### Step 2: Confirm RED
- All six tests fail until SKILL.md is migrated.

## Verification Commands

```bash
cd /Users/FradSer/Developer/FradSer/dotclaude
python3 -m pytest superpowers/tests/test_migration_parity.py::RetrospectiveMigrationPhase6ClosureTests -v 2>&1 | tail -30
# Expect: all FAIL
```

## Success Criteria

- ≥ 6 failing tests in `RetrospectiveMigrationPhase6ClosureTests`.
- The strongest signal (`>> docs/retros/evolution-log.jsonl` absent EVERYWHERE) is one of the tests.
- The `consecutive_zero_change` computation remains in SKILL.md (test asserts presence).
