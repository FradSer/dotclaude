# Task 011: Writing-plans memory touchpoint — test (RED)

**depends-on**: task-008, task-009 (file-conflict guard — see Note below)

**Note on this dependency**: task-009 and this task both append new blocks to the same shared file, `superpowers/tests/test-skill-touchpoints.sh`; the two are serialized so at most one writes to it at a time (see plan reflection File Conflict Review). This does not affect task-012 (this task's own paired impl task) — task-012 still depends only on task-011 and edits a distinct file, `writing-plans/SKILL.md`, so it retains full parallelism with the other skills' impl tasks.

## Description

Extend `tests/test-skill-touchpoints.sh` with grep-based assertions proving `skills/writing-plans/SKILL.md` documents: (a) the memory read-before step appended to Initialization step 1 ("Design Check"), and (b) the conditional memory-write step (gated on the skill's *existing* Phase 4 reflection FAIL-requiring-rework language) appended to Phase 5 as new step 0.5. These assertions MUST fail against the current file.

## Execution Context

**Task Number**: 011 of 020
**Phase**: Skill Touchpoints
**Prerequisites**: task-008 merged; task-009 merged (avoids a concurrent-write race on the shared `test-skill-touchpoints.sh` file)

## BDD Scenario

```gherkin
Scenario: Memory read-before step surfaces a relevant active memory file and informs the skill's output
  When the writing-plans skill begins Phase 2 task decomposition for a new plan
  Then it invokes `lib/docs-index.sh list --kind memory --status active`

Scenario: writing-plans write-gate fires — a Phase 4 reflection sub-agent FAIL requiring rework
  When writing-plans fixes the offending task files and reruns the affected sub-agent
  Then writing-plans captures the false-positive cause as a memory file with `category=pitfall`
  And it invokes `lib/docs-index.sh upsert memory docs/memory/pitfall_<slug>.md --status active --summary "<one-line>"`
```

**Spec Source**: `../2026-07-04-superpowers-memory-layer-design/bdd-specs.md` Scenario 2, Scenario 5 (positive), Scenario 10 (negative); `architecture.md` §3 writing-plans touchpoint table

## Interfaces

**Exposes** (assertions added to `tests/test-skill-touchpoints.sh`, new `== Writing-Plans memory touchpoints ==` block):
- `"writing-plans Initialization consults list --kind memory"` — needle: `list --kind memory --status active`
- `"writing-plans Phase 5 has a conditional memory-write step gated on Phase 4 FAIL"` — needle: `upsert memory docs/memory/`
- `"writing-plans's memory-write step names the FAIL/rework gate"` — needle: a phrase confirming the gate condition co-located with the memory-write text (e.g. `FAIL` near `memory`)

**Consumes**: none

**Global Constraints respected**: memory write-gates are conditional only.

## Files to Modify/Create

- Modify: `superpowers/tests/test-skill-touchpoints.sh` — add the new block (3 `assert_grep` calls) after the existing `== Writing-Plans touchpoints ==` block.

## Steps

### Step 1: Verify Scenario
- Confirm Scenarios 2, 5, 10 exist in the design's `bdd-specs.md`.

### Step 2: Implement Test (Red)
- Add the 3 assertions.
- **Verification**: `bash superpowers/tests/test-skill-touchpoints.sh` — all 3 FAIL.

## Verification Commands

```bash
bash superpowers/tests/test-skill-touchpoints.sh
```

## Success Criteria

- 3 new assertions exist and FAIL for the documented reason
- Zero regressions among pre-existing assertions
