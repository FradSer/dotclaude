# Task 017: Retrospective memory touchpoint — test (RED)

**depends-on**: task-008, task-015 (file-conflict guard — see Note below)

**Note on this dependency**: task-015 and this task both append new blocks to the same shared file, `superpowers/tests/test-skill-touchpoints.sh`; the two are serialized so at most one writes to it at a time (see plan reflection File Conflict Review). This does not affect task-018 (this task's own paired impl task) — task-018 still depends only on task-017 and edits a distinct file, `retrospective/SKILL.md`, so it retains full parallelism with the other skills' impl tasks.

## Description

Extend `tests/test-skill-touchpoints.sh` with grep-based assertions proving `skills/retrospective/SKILL.md` documents: (a) the memory read-before step appended to Phase 1 Data Collection step 1, (b) the two-stage conditional memory-write (Phase 4 step 3.5 drafts the file for every applied ADD/MODIFY proposal, Phase 6 step 8 upserts the index row), explicitly excluding REMOVE/PROMOTE proposals, and (c) the Pre-Check-B promotion bridge — a distinct mechanism from the ordinary ADD/MODIFY write, promoting a recalled private-memory prior into a project-local memory file with a provenance line. These assertions MUST fail against the current file.

## Execution Context

**Task Number**: 017 of 020
**Phase**: Skill Touchpoints
**Prerequisites**: task-008 merged; task-015 merged (avoids a concurrent-write race on the shared `test-skill-touchpoints.sh` file)

## BDD Scenario

```gherkin
Scenario: retrospective's memory read-before step folds relevant memory into Phase 1 Data Collection
  When retrospective's Phase 1 "Data Collection" step 1 runs
  Then it also invokes `lib/docs-index.sh list --kind memory --status active`

Scenario: retrospective write-gate fires — a Phase 3 proposal reaches the ADD or MODIFY threshold
  When retrospective's Phase 4 Auto-Apply processes that qualifying proposal
  Then retrospective promotes the qualifying finding into a memory file
  And it invokes `lib/docs-index.sh upsert memory docs/memory/<category>_<slug>.md --status active --summary "<one-line>"`
  But a Phase 3 REMOVE or PROMOTE proposal, even if applied, does NOT trigger a memory write

Scenario: retrospective promotes a recalled global-memory prior into a project-local memory file
  When retrospective's Phase 3 "Evolution Proposals" step processes the approved MODIFY proposal
  Then retrospective writes a `docs/memory/convention_<slug>.md` file for the promoted prior
  And that file's `## Why` section records exactly:
    `Promoted from private assistant memory hook: feedback_skill_level_enforcement, <date>`
```

**Spec Source**: `../2026-07-04-superpowers-memory-layer-design/bdd-specs.md` Scenario 3c, Scenario 8, Scenario 8a, Scenario 14; `architecture.md` §3 retrospective touchpoint table + §4; `best-practices.md` §Anti-Bloat Rules (h)

## Interfaces

**Exposes** (assertions added to `tests/test-skill-touchpoints.sh`, new `== Retrospective memory touchpoints ==` block):
- `"retrospective Phase 1 consults list --kind memory"` — needle: `list --kind memory --status active`
- `"retrospective Phase 4 drafts a memory file for applied ADD/MODIFY proposals"` — needle: `upsert memory docs/memory/`
- `"retrospective explicitly excludes REMOVE/PROMOTE from the memory write-gate"` — needle: `REMOVE` co-located with `PROMOTE` and a phrase confirming exclusion (e.g. `does NOT trigger`)
- `"retrospective documents the Pre-Check-B promotion bridge"` — needle: `Promoted from private assistant memory hook`
- `"retrospective documents memory-file consolidation via set-status expired:superseded-by-consolidation"` — needle: `expired:superseded-by-consolidation`

**Consumes**: none

**Global Constraints respected**: memory write-gate reuses the existing ADD (2+ plans) / MODIFY (2+ false positives) thresholds verbatim; REMOVE/PROMOTE never trigger a write; Pre-Check B's existing private/advisory-only behavior stays unchanged (the test should also re-assert the pre-existing Pre-Check B text is unchanged — regression guard).

## Files to Modify/Create

- Modify: `superpowers/tests/test-skill-touchpoints.sh` — add the new block (5 `assert_grep` calls) after the existing `== Retrospective touchpoints ==` block.

## Steps

### Step 1: Verify Scenario
- Confirm Scenarios 3c, 8, 8a, 14 exist in the design's `bdd-specs.md`.

### Step 2: Implement Test (Red)
- Add the 5 assertions.
- **Verification**: `bash superpowers/tests/test-skill-touchpoints.sh` — all 5 FAIL.

## Verification Commands

```bash
bash superpowers/tests/test-skill-touchpoints.sh
```

## Success Criteria

- 5 new assertions exist and FAIL for the documented reason
- Zero regressions among pre-existing assertions (including the existing Pre-Check B assertions, if any — this task adds none, task-018 must not alter that text)
