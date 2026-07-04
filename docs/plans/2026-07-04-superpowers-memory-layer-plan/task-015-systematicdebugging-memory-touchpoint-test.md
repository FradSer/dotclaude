# Task 015: Systematic-debugging memory touchpoint — test (RED)

**depends-on**: task-008, task-013 (file-conflict guard — see Note below)

**Note on this dependency**: task-013 and this task both append new blocks to the same shared file, `superpowers/tests/test-skill-touchpoints.sh`; the two are serialized so at most one writes to it at a time (see plan reflection File Conflict Review). This does not affect task-016 (this task's own paired impl task) — task-016 still depends only on task-015 and edits a distinct file, `systematic-debugging/SKILL.md`, so it retains full parallelism with the other skills' impl tasks.

## Description

Add a brand-new `== Systematic-Debugging touchpoints ==` block to `tests/test-skill-touchpoints.sh` — this skill has zero docs-index assertions today (it has zero `docs/` touchpoints of any kind before this design). Assert: (a) `allowed-tools` frontmatter gains the `docs-index.sh` scope string, (b) a new step 0 prepended to Phase 1 runs the memory read-before call (only on the non-bail-out path), and (c) a new step 6 appended after the existing "3+ Failed Fixes" step is the skill's ONLY conditional memory-write step — gated on that existing 3-strikes trigger OR an explicit cross-cutting gotcha. These assertions MUST fail against the current file.

## Execution Context

**Task Number**: 015 of 020
**Phase**: Skill Touchpoints
**Prerequisites**: task-008 merged; task-013 merged (avoids a concurrent-write race on the shared `test-skill-touchpoints.sh` file)

## BDD Scenario

```gherkin
Scenario: systematic-debugging's memory read-before step surfaces a relevant active memory file
  Given the bail-out check does NOT fire (no named root cause + named fix in the symptom)
  When systematic-debugging begins its new step 0, prepended to Phase 1 "Root Cause Investigation"
  Then it invokes `lib/docs-index.sh list --kind memory --status active`
  And systematic-debugging Reads the matching file before step 1 "Read Error Messages Carefully"

Scenario: systematic-debugging's memory read-before step is skipped on the bail-out path
  When systematic-debugging's Bail-Out Check fires and skips the 4-phase pipeline
  Then it does NOT invoke `lib/docs-index.sh list --kind memory`

Scenario: systematic-debugging write-gate fires — its existing 3+ failed fixes trigger
  When systematic-debugging reaches its existing "3+ failed fixes → question architecture" trigger
  Then it captures the underlying architectural insight as a memory file
  And it invokes `lib/docs-index.sh upsert memory docs/memory/decision_<slug>.md --status active --summary "<one-line>"`
  And this is the first `docs/` touchpoint systematic-debugging has ever had

Scenario: systematic-debugging's fix-and-regression-test contract is unchanged even when memory is written
  Then it narrates exactly the same three-part completion output as always
  And no additional phase, commit, or user-facing deliverable is introduced by the memory write
```

**Spec Source**: `../2026-07-04-superpowers-memory-layer-design/bdd-specs.md` Scenario 3a, its bail-out counterpart, Scenario 7, Scenario 12, Scenario 18; `architecture.md` §3 systematic-debugging touchpoint table

## Interfaces

**Exposes** (new assertions added to `tests/test-skill-touchpoints.sh`, new `== Systematic-Debugging touchpoints ==` block):
- `"systematic-debugging allowed-tools includes docs-index.sh scope"` — needle: `Bash(${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh:*)`
- `"systematic-debugging new step 0 consults list --kind memory before Phase 1"` — needle: `list --kind memory --status active`
- `"systematic-debugging's memory read is skipped on the bail-out path"` — needle: a phrase co-locating the bail-out check with the memory-read skip (e.g. `bail-out` near `memory`)
- `"systematic-debugging's memory-write step reuses the existing 3+ failed-fixes trigger"` — needle: `3+ failed fixes` co-located with `upsert memory`
- `"systematic-debugging's memory-write is its ONLY docs/ touchpoint, not a new phase"` — needle: a phrase confirming no new phase/commit is introduced (e.g. `not a new phase`)

**Consumes**: none

**Global Constraints respected**: memory write-gates conditional only; this skill's deliverable contract ("fix + regression test, never a planning artifact") must remain textually intact — the test should also assert the skill's existing "Slash-command Usage" deliverable-discipline sentence is still present unchanged (regression guard).

## Files to Modify/Create

- Modify: `superpowers/tests/test-skill-touchpoints.sh` — add the new `== Systematic-Debugging touchpoints ==` block (5 `assert_grep` calls) as a new top-level section (mirror the existing section style, e.g. placed after the `== Retrospective touchpoints ==` block).

## Steps

### Step 1: Verify Scenario
- Confirm the relevant scenarios exist in the design's `bdd-specs.md`.

### Step 2: Implement Test (Red)
- Add the 5 assertions.
- **Verification**: `bash superpowers/tests/test-skill-touchpoints.sh` — all 5 FAIL (the skill's `SKILL.md` has no memory text and no `docs-index.sh` scope in `allowed-tools` yet).

## Verification Commands

```bash
bash superpowers/tests/test-skill-touchpoints.sh
```

## Success Criteria

- 5 new assertions exist and FAIL for the documented reason
- Zero regressions among pre-existing assertions in the file
