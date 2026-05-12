# Batch 4 Sprint Contract

## Tasks

| ID | Subject | Type |
|----|---------|------|
| 007 | Phase 5c SKILL.md migration to observations.sh | refactor |
| 008 | Phase 4 + Phase 6 SKILL.md migration to evolution-log.sh | refactor |
| 009-test | systematic-debugging Phase 4 emission test (Red) | test |
| 009-impl | systematic-debugging Phase 4 emission impl (Green) | impl |

## Acceptance Criteria

### Task 007: Phase 5c SKILL.md migration to observations.sh

Derived from `bdd-specs.md` §5.4 Then-clauses + the gate guarantee from §3.

- [ ] `superpowers/skills/retrospective/SKILL.md` Phase 5c section no longer contains any inline `jq -nc … >> docs/retros/harness-observations.jsonl` invocations
- [ ] Both Phase 5c emission branches (`component_unsupported` and `component_unknown`) route through `bash "${CLAUDE_PLUGIN_ROOT}/lib/observations.sh" <component> <outcome> "<reason>"`
- [ ] The CRITICAL refusal-gate guidance + surrounding prose is preserved verbatim — only the NDJSON append line is migrated
- [ ] The non-NDJSON `harness-config.json` write path stays inline (only the `.jsonl` append migrates)
- [ ] YAML frontmatter `allowed-tools` array contains `"Bash(${CLAUDE_PLUGIN_ROOT}/lib/observations.sh:*)"`
- [ ] Existing `allowed-tools` entries are preserved unchanged
- [ ] `python3 -m unittest tests.test_phase_integration -v` passes (Phase 1 step 2 glob unchanged — §5.4)
- [ ] `python3 -m unittest tests.test_migration_parity -v` still passes (no drift from the SKILL.md edit; helper output unchanged)
- [ ] Full unittest suite passes — no regressions
- [ ] `python3 plugin-optimizer/scripts/validate-plugin.py superpowers` exits 0

### Task 008: Phase 4 + Phase 6 SKILL.md migration to evolution-log.sh

Derived from `bdd-specs.md` §3.2, §5.4 Then-clauses.

- [ ] `superpowers/skills/retrospective/SKILL.md` Phase 4 section no longer contains inline `jq -nc … >> docs/retros/evolution-log.jsonl` invocations for `item_added`, `item_removed`, `item_modified`, or `item_promoted`
- [ ] `superpowers/skills/retrospective/SKILL.md` Phase 6 section no longer contains inline `jq -nc … >> docs/retros/evolution-log.jsonl` invocations for `retrospective_run` or `component_reinstated`
- [ ] All six event kinds route through `bash "${CLAUDE_PLUGIN_ROOT}/lib/evolution-log.sh" <event_type> '<payload-only filter>' --arg ...`
- [ ] Payload-only filter passed to the helper does NOT include `event` or `timestamp` (the helper's envelope handles those)
- [ ] `consecutive_zero_change` computation and other Phase 6 calibration logic that lives OUTSIDE the `jq -nc` line stays inline in SKILL.md
- [ ] YAML frontmatter `allowed-tools` contains `"Bash(${CLAUDE_PLUGIN_ROOT}/lib/evolution-log.sh:*)"`
- [ ] Existing `allowed-tools` entries preserved
- [ ] `python3 -m unittest tests.test_migration_parity -v` passes
- [ ] `python3 -m unittest tests.test_phase_integration -v` passes (Phase 1 step 5 reader for `item_id` history table unchanged)
- [ ] Full unittest suite passes — no regressions
- [ ] `python3 plugin-optimizer/scripts/validate-plugin.py superpowers` exits 0

### Task 009-test: systematic-debugging Phase 4 emission test (Red)

Derived from `bdd-specs.md` §4 (all four), §6 (both) Then-clauses.

- [ ] `superpowers/tests/test_systematic_debugging_phase4_emission.py` exists with five TestCase classes: `Phase4SuccessEmissionTests`, `Phase4BailOutNonEmissionTests`, `Phase4SkillNameSourcingTests`, `Phase4ArchitectureQuestioningTests`, `Phase4DedupTests` + a `Phase4CrossSessionTests` class (six classes total per the task file)
- [ ] `Phase4SuccessEmissionTests` covers: `test_phase_4_terminal_emits_fix_completed_once`, `test_payload_carries_root_cause_and_regression_test_path`, `test_payload_does_not_include_test_stdout_stderr_or_diff`
- [ ] `Phase4BailOutNonEmissionTests.test_bail_out_path_does_not_emit_fix_completed` asserts bail-log invocation appends to `bail-out-events.jsonl` (one row) and `skill-events.jsonl` has zero rows
- [ ] `Phase4SkillNameSourcingTests` covers three tests: state-file present + non-empty, missing state file, empty skill_name
- [ ] `Phase4ArchitectureQuestioningTests` covers two tests: no emission on ≥3 failed fixes, no `fix_abandoned` event emitted
- [ ] `Phase4DedupTests` covers: `test_same_invocation_dedupes_within_session`, `test_dedup_uses_tail_200_scan` (tests the 200-line boundary both directions)
- [ ] `Phase4CrossSessionTests` covers: cross-session dedup intentionally absent, different args produce different `args_hash`
- [ ] Tests fail with meaningful assertion errors before 009-impl (no SKILL.md emission wired up yet, dedup not implemented)
- [ ] No production code (`systematic-debugging/SKILL.md`, `lib/skill-events.sh`) is touched

### Task 009-impl: systematic-debugging Phase 4 emission impl (Green)

Derived from `bdd-specs.md` §4 (all), §6 (both) Then-clauses.

- [ ] `superpowers/skills/systematic-debugging/SKILL.md` Phase 4 terminal step ("Verify Fix" success branch) calls `bash "${CLAUDE_PLUGIN_ROOT}/lib/skill-events.sh" "$skill_name" fix_completed '<payload filter>' --arg ...`
- [ ] `skill_name` is read from the session state file via the same `state_read` path used by `_loop_log_plan_completion_if_executing` — NOT hardcoded to the literal `"systematic-debugging"`
- [ ] Emission silently skips and returns 0 when state file is missing OR `skill_name` is empty
- [ ] Tail-200 dedup scan via `retro-events.sh::dedup_check` is in place before the helper invocation (§6.1)
- [ ] NO emission on the bail-out branch (§4.2) — bail-out continues to flow through `bail-log.sh` only
- [ ] NO emission on the architecture-questioning branch (≥3 failed fixes per §4.4)
- [ ] NO `fix_abandoned` event is added in this iteration (explicitly out of scope per §4.4)
- [ ] Payload carries `root_cause`, `regression_test_path`, `investigation_phase_count` — does NOT include `test_stdout`, `test_stderr`, or `fix_diff` text (per `best-practices.md` "No transcript content")
- [ ] YAML frontmatter `allowed-tools` contains `"Bash(${CLAUDE_PLUGIN_ROOT}/lib/skill-events.sh:*)"`
- [ ] Existing `Bash(${CLAUDE_PLUGIN_ROOT}/lib/bail-log.sh:*)` entry stays unchanged
- [ ] All tests in `test_systematic_debugging_phase4_emission.py` pass
- [ ] Full unittest suite passes — no regressions
- [ ] `python3 plugin-optimizer/scripts/validate-plugin.py superpowers` exits 0

## Red-Green Pairs

| Test Task | Impl Task | Expected Red State | Expected Green State |
|-----------|-----------|--------------------|----------------------|
| 009-test | 009-impl | Tests fail with assertion errors: no Phase 4 emission wired up, no dedup logic in SKILL.md; failures are NOT Python `ImportError` | All `test_systematic_debugging_phase4_emission.py` tests pass; full suite green; plugin validator passes |

Tasks 007 and 008 are refactor-only (no Red-Green pair). Their gate is the parity-test green state from 006-impl (already passing) plus the §5.4 evaluation-glob unchanged guarantee plus plugin-validator green.

## Execution Order (within the batch)

007, 008, 009-test can begin in parallel — they touch disjoint files (`retrospective/SKILL.md` vs `retrospective/SKILL.md` vs `tests/test_systematic_debugging_phase4_emission.py`).

**BUT**: 007 and 008 BOTH edit `superpowers/skills/retrospective/SKILL.md` (different sections — Phase 5c vs Phase 4+6). Serialize them to avoid clobbering: run 007 first, then 008 against the 007-edited file.

Recommended order:
1. **Phase A (parallel)**: 007 (`retrospective/SKILL.md` Phase 5c edit) AND 009-test (test file creation)
2. **Phase B (after 007 done)**: 008 (`retrospective/SKILL.md` Phase 4+6 edit, rebases on 007's allowed-tools array)
3. **Phase C (after 009-test Red verified)**: 009-impl (Phase 4 emission SKILL.md edit + state_read pattern)

## Evaluation Criteria Preview

The evaluator will apply the following checklist items to this batch:

| Item ID | Description |
|---------|-------------|
| CODE-VER-01 | Verification commands exit with code 0 |
| CODE-QUAL-01 | No TODO, FIXME, HACK, XXX, or stub patterns in produced files |
| CODE-QUAL-02 | No stub implementations (`NotImplementedError`, lone `pass`, lone `...`) in produced files |

## Sign-off

- **Generator:** executing-plans
- **Timestamp:** 2026-05-13T00:00:00Z
- **Status:** READY
