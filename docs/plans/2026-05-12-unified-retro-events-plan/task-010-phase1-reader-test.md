# Task 010: retrospective Phase 1 skill-events Reader — Tests (Red)

**depends-on**: task-003-skill-events-impl, task-008-migrate-phase6-closure-impl

## Description

Write failing tests for the new `retrospective` Phase 1 sub-step that reads `docs/retros/skill-events.jsonl`, aggregates rows by `(skill, event)` since the most recent `retrospective_run` timestamp, and surfaces the aggregation in the Phase 6 report under a new "Skill Event Activity" subsection. The aggregation is **surface-only**: it does NOT enter the RETROSPECTIVE DUE counter (which remains driven by `plans-completed.jsonl`) and does NOT enter the EVO proposal-threshold logic.

Two assertion surfaces:
1. **SKILL.md textual contract**: the Phase 1 reader sub-step exists and explicitly states "surface-only / do NOT include in DUE thresholds".
2. **Behavioral isolation**: the Phase 1 step 2 evaluation-glob behavior is unchanged from pre-migration (BDD §5.21).

## Execution Context

**Task Number**: 010 of 21
**Phase**: retrospective Phase 1 reader
**Prerequisites**: Task 003 impl (helper writes to skill-events.jsonl); Task 008 impl (Phase 6 closure migrated — same SKILL.md target file, sequencing avoids edit conflicts).

## BDD Scenario

```gherkin
Scenario: retrospective Phase 1 step 2 evaluation glob behavior is unchanged
  Given a plan directory with evaluation-design-round-1.md, evaluation-plan-round-2.md, and evaluation-round-1.md
  When retrospective Phase 1 step 2 enumerates evaluation reports
  Then the same three files are discovered as before the migration
  And no helper in the new family is invoked during the discovery phase
```

Plus a plan-layer Gherkin spec derived from the design's "informational surface, no DUE impact" prose in `../2026-05-12-unified-retro-events-design/_index.md` §"One new retrospective Phase 1 reader step" (the design declares the property in prose; this plan task encodes it as Given/When/Then so it is executable-test-friendly):

```gherkin
Scenario: Phase 1 surfaces skill-events without affecting DUE
  [Note: plan-derived, not present verbatim in bdd-specs.md — anchored to design prose]
  Given docs/retros/skill-events.jsonl contains 5 fix_completed rows and 3 unrelated rows
  And Phase 1 step 2 evaluation glob has produced its normal list
  When the retrospective generates its Phase 6 report
  Then the report contains a "Skill Event Activity" subsection listing (skill, event) → count rows
  And the RETROSPECTIVE DUE threshold logic ignores skill-events.jsonl
  And the EVO proposal-threshold logic ignores skill-events.jsonl
```

**Spec Source**: `../2026-05-12-unified-retro-events-design/bdd-specs.md` §5.21; `_index.md` Detailed Design §"One new retrospective Phase 1 reader step"; `architecture.md` §"retrospective SKILL.md Phase 1 step 2 — new surface-only scan of skill-events.jsonl".

## Files to Modify/Create

- Modify: `superpowers/tests/test_migration_parity.py` (extend with a new TestCase) OR create `superpowers/tests/test_retrospective_phase1_reader.py`. **Choose** the new file — these tests target the Phase 1 reader specifically, not migration parity.

- Create: `superpowers/tests/test_retrospective_phase1_reader.py`

## Steps

### Step 1: Test Helpers + Constants
```python
RETROSPECTIVE_SKILL_MD = SUPERPOWERS_DIR / "skills" / "retrospective" / "SKILL.md"
```

### Step 2: TestCase — `Phase1SkillEventsReaderTextualTests`
- `test_phase_1_reads_skill_events_jsonl` — read SKILL.md; locate Phase 1 section; assert the substring `docs/retros/skill-events.jsonl` appears in Phase 1.
- `test_phase_1_aggregates_by_skill_event_pair` — assert the Phase 1 prose for the new sub-step describes the grouping key `(skill, event)` (substring search on `(skill, event)` OR `by skill and event` OR equivalent prose).
- `test_phase_1_reader_is_surface_only` — assert the Phase 1 sub-step prose contains an explicit "surface-only" marker (substring `surface-only` OR `informational` OR `Do NOT include`/`do not include` in `RETROSPECTIVE DUE` context).
- `test_phase_1_reader_does_not_modify_due_threshold` — assert the Phase 1 sub-step explicitly states DUE remains owned by `plans-completed.jsonl` (substring `plans-completed.jsonl` near the new sub-step's prose; OR assert the prose mentions "DUE counter unchanged" / equivalent).
- `test_phase_1_reader_skips_silently_on_missing_file` — assert the Phase 1 sub-step prose explicitly states "skip silently when the file does not exist" (substring `Skip silently` / `skip silently`, matching the existing Phase 1 step 7 phrasing for `bail-out-events.jsonl`).
- `test_phase_6_report_has_skill_event_activity_subsection` — locate the Phase 6 report-rendering section; assert a "Skill Event Activity" (or equivalent) subsection is added.

### Step 3: TestCase — `Phase1EvaluationGlobUnchangedTests`
- `test_phase_1_step_2_glob_pattern_unchanged` — read SKILL.md; locate Phase 1 step 2 (the evaluation enumeration); assert the existing glob pattern (`evaluation-*.md` or whatever it currently is — implementer reads it once and pins it here) is unchanged from pre-migration. Anchor on the prose around the glob and verify substrings match. (BDD §5.21)
- `test_phase_1_step_2_does_not_invoke_new_helpers` — scope the Phase 1 step 2 text only; assert NO `lib/observations.sh`, `lib/evolution-log.sh`, `lib/skill-events.sh`, or `lib/retro-events.sh` substring appears. (Phase 1 step 2 is discovery — it reads files, doesn't emit; the helpers are write-side only.)

### Step 4: TestCase — `Phase1ReaderRuntimeTests` (optional, behavioral)
This TestCase runs the actual reading logic in a sandbox. Because the reader is prose-only (Claude executes it at runtime), a true runtime test would require a harness that simulates the retrospective skill, which is out of scope. Skip this TestCase or mark it `@unittest.skipIf(True, "reader is prose-only; covered by integration test in test_phase_integration.py")`.

### Step 5: Confirm RED
- All textual tests fail until SKILL.md is edited in Task 010 impl.

## Verification Commands

```bash
cd /Users/FradSer/Developer/FradSer/dotclaude
python3 -m pytest superpowers/tests/test_retrospective_phase1_reader.py -v 2>&1 | tail -40
# Expect: every textual test FAILS
```

## Success Criteria

- ≥ 8 failing tests covering Phase 1 reader presence, surface-only constraint, DUE-isolation, missing-file handling, Phase 6 subsection, and the Phase 1 step 2 glob-stability check.
- Each BDD scenario above maps to at least one test.
