# Task 010: retrospective Phase 1 skill-events Reader — Implementation (Green)

**depends-on**: task-010-phase1-reader-test

## Description

Edit `retrospective/SKILL.md` to add a new Phase 1 sub-step that reads `docs/retros/skill-events.jsonl`, aggregates by `(skill, event)` since the most recent `retrospective_run` timestamp, and renders the aggregation in the Phase 6 report under a new "Skill Event Activity" subsection. Surface-only — no DUE / EVO impact.

The sub-step lands AFTER existing Phase 1 step 7 (which reads `bail-out-events.jsonl`) to preserve existing numbering and avoid breaking line-anchored references elsewhere in the file. Per architecture.md "the exact step position is decided in `./architecture.md`": numbering becomes step 8 (a new step appended after step 7).

## Execution Context

**Task Number**: 010 of 21
**Phase**: retrospective Phase 1 reader
**Prerequisites**: Task 010 test is RED; Task 008 impl already merged.

## BDD Scenario

See `task-010-phase1-reader-test.md`.

**Spec Source**: `../2026-05-12-unified-retro-events-design/_index.md` Detailed Design / Migration order step 8; `architecture.md` §"retrospective SKILL.md Phase 1 step 2 — new surface-only scan".

## Files to Modify/Create

- Modify: `superpowers/skills/retrospective/SKILL.md` Phase 1 section + Phase 6 report-rendering section.

## Steps

### Step 1: Locate Phase 1 Step 7 and the Phase 6 Report Section
- Phase 1 step 7 is the bail-out-events reader.
- Phase 6 report section is where the retrospective produces its final markdown output.

### Step 2: Add Phase 1 Step 8 — Skill Event Activity Reader
Append after step 7:

```markdown
### Step 8: Read skill-events.jsonl (surface-only)

Read `docs/retros/skill-events.jsonl` if present. Group rows by
`(skill, event)`. For each group, count rows whose timestamp is **after** the
most recent `retrospective_run` event in `docs/retros/evolution-log.jsonl`
(use the same `consecutive_zero_change` anchor logic Pre-Check B already
uses).

**Surface-only**: render the aggregation in the Phase 6 report under
"Skill Event Activity". Do NOT include these counts in RETROSPECTIVE DUE
thresholds — those remain owned by `plans-completed.jsonl`. Do NOT include
these counts in EVO proposal-threshold logic.

Skip silently when `docs/retros/skill-events.jsonl` does not exist
(first-run state), matching the missing-file handling of step 7.
```

### Step 3: Add Phase 6 "Skill Event Activity" Subsection
Append to the Phase 6 report-rendering section (after the existing proposal-summary section, before the `retrospective_run` event emission of Task 008):

```markdown
#### Skill Event Activity

| Skill | Event | Count since last retrospective |
|-------|-------|--------------------------------|
| <row populated from step 8 aggregation> | ... | ... |

This table is informational. The counts above do not gate retrospective
scheduling and do not trigger evolution-log proposals.
```

### Step 4: Verify Tests
- Run Task 010's test module; all textual tests pass.
- Run the FULL test suite; no regressions.
- Spot-check the rendered SKILL.md (markdown preview) to confirm prose flow.

### Step 5: Cross-Check Phase 1 Step 2 Glob Behavior
- Re-read Phase 1 step 2; confirm the glob (`evaluation-*.md`) is byte-identical to pre-migration. The new step 8 must not alter step 2's logic.

## Verification Commands

```bash
cd /Users/FradSer/Developer/FradSer/dotclaude
python3 -m pytest superpowers/tests/test_retrospective_phase1_reader.py -v 2>&1 | tail -40
python3 -m pytest superpowers/tests/ -q 2>&1 | tail -10
```

## Success Criteria

- All tests in `test_retrospective_phase1_reader.py` pass.
- Phase 1 has a new step 8 with explicit "surface-only" and "DUE-unaffected" prose.
- Phase 6 has a "Skill Event Activity" subsection.
- Phase 1 step 2 evaluation glob is unchanged.
- Full suite green.
