# Task 013: Executing-plans memory touchpoint — test (RED)

**depends-on**: task-008, task-011 (file-conflict guard — see Note below)

**Note on this dependency**: task-011 and this task both append new blocks to the same shared file, `superpowers/tests/test-skill-touchpoints.sh`; the two are serialized so at most one writes to it at a time (see plan reflection File Conflict Review). This does not affect task-014 (this task's own paired impl task) — task-014 still depends only on task-013 and edits a distinct file, `executing-plans/SKILL.md`, so it retains full parallelism with the other skills' impl tasks.

## Description

Extend `tests/test-skill-touchpoints.sh` with grep-based assertions proving `skills/executing-plans/SKILL.md` documents: (a) the memory read-before step appended to Initialization step 1 ("Plan Check"), and (b) the conditional memory-write step gated on the *existing* intra-plan-learning "variety gap" signal (`references/intra-plan-learning.md:54`) — explicitly NOT the separate `batch-execution-playbook.md:165` hard-abort cap — bundled into the existing Phase 5 CRITICAL post-commit index-flip block. These assertions MUST fail against the current file.

## Execution Context

**Task Number**: 013 of 020
**Phase**: Skill Touchpoints
**Prerequisites**: task-008 merged; task-011 merged (avoids a concurrent-write race on the shared `test-skill-touchpoints.sh` file)

## BDD Scenario

```gherkin
Scenario: executing-plans' memory read-before step surfaces a relevant active memory file
  When executing-plans' Initialization step 1 "Plan Check" runs
  Then it also invokes `lib/docs-index.sh list --kind memory --status active`

Scenario: executing-plans write-gate fires — the intra-plan "variety gap" signal (2+ rework rounds, batch eventually PASSes)
  When the coordinator's rework loop completes its 2nd round and the batch reaches PASS
    (the variety-gap signal from references/intra-plan-learning.md:54,
     NOT the separate batch-execution-playbook.md:165 hard-abort cap)
  Then the coordinator captures the recurring rework pattern as a memory file with `category=pitfall`
  And it invokes `lib/docs-index.sh upsert memory docs/memory/pitfall_<slug>.md --status active --summary "<one-line>"`
```

**Spec Source**: `../2026-07-04-superpowers-memory-layer-design/bdd-specs.md` Scenario "executing-plans' memory read-before step...", Scenario 6 (positive), Scenario 11 (negative); `architecture.md` §3 executing-plans touchpoint table

## Interfaces

**Exposes** (assertions added to `tests/test-skill-touchpoints.sh`, new `== Executing-Plans memory touchpoints ==` block):
- `"executing-plans Initialization consults list --kind memory"` — needle: `list --kind memory --status active`
- `"executing-plans Phase 5 has a conditional memory-write step gated on the variety-gap signal"` — needle: `intra-plan-learning.md`
- `"executing-plans distinguishes the variety-gap trigger from the batch-execution-playbook hard-abort cap"` — needle: `batch-execution-playbook.md` co-located with an explicit distinguishing phrase (e.g. `NOT`)

**Consumes**: none

**Global Constraints respected**: memory write-gates conditional only; the variety-gap signal (not the hard-abort cap) is the correct, precise trigger — the test must catch a future edit that conflates the two.

## Files to Modify/Create

- Modify: `superpowers/tests/test-skill-touchpoints.sh` — add the new block (3 `assert_grep` calls) after the existing `== Executing-Plans touchpoints ==` block.

## Steps

### Step 1: Verify Scenario
- Confirm the relevant scenarios exist in the design's `bdd-specs.md`.

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
