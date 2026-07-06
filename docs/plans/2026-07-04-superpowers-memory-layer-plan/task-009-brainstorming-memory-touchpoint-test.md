# Task 009: Brainstorming memory touchpoint — test (RED)

**depends-on**: task-008

## Description

Extend `tests/test-skill-touchpoints.sh` with grep-based assertions proving `skills/brainstorming/SKILL.md` documents: (a) the memory read-before step appended to Initialization step 2, and (b) the conditional memory-write step (gated on the skill's *existing* "REWORK 2+ rounds" trigger) appended to Phase 3 Wrap-up as step 0.5. These assertions MUST fail against the current file (no memory-related text exists in it yet).

## Execution Context

**Task Number**: 009 of 020
**Phase**: Skill Touchpoints
**Prerequisites**: task-008 merged (the memory kind is fully functional)

## BDD Scenario

```gherkin
Scenario: Memory read-before step finds no relevant memory and the skill proceeds normally
  When the brainstorming skill begins a new design
  Then it invokes `lib/docs-index.sh list --kind memory --status active`
  And brainstorming proceeds with its normal Phase 1 research

Scenario: brainstorming write-gate fires — 2+ evaluator REWORK rounds on a design
  When brainstorming reaches its existing "REWORK 2+ rounds" trigger
  Then, in addition to its normal design commit and `kind=design` upsert,
    brainstorming captures the recurring rework cause as a memory file
  And it invokes `lib/docs-index.sh upsert memory docs/memory/<category>_<slug>.md --status active --summary "<one-line>"`
```

**Spec Source**: `../2026-07-04-superpowers-memory-layer-design/bdd-specs.md` Scenario 3, Scenario 4 (positive) and Scenario 9 (negative); `architecture.md` §3 brainstorming touchpoint table

## Interfaces

**Exposes** (assertions added to `tests/test-skill-touchpoints.sh`, in a new `== Brainstorming memory touchpoints ==` block, following the file's existing `assert_grep` helper pattern):
- `"brainstorming Initialization consults list --kind memory"` — needle: `list --kind memory --status active`
- `"brainstorming Phase 3 has a conditional memory-write step gated on REWORK 2+ rounds"` — needle: a distinguishing phrase from the new step, e.g. `upsert memory docs/memory/`
- `"brainstorming's memory-write step is explicitly conditional, not unconditional"` — needle: a phrase confirming the gate language is present near the upsert call, e.g. `REWORK 2+ rounds` co-located with `memory`

**Consumes**: none (pure grep against a markdown file)

**Global Constraints respected**: memory write-gates are conditional only — the test must fail if the write step is documented as unconditional.

## Files to Modify/Create

- Modify: `superpowers/tests/test-skill-touchpoints.sh` — add the new `== Brainstorming memory touchpoints ==` block (3 `assert_grep` calls) after the existing `== Brainstorming touchpoints ==` block.

## Steps

### Step 1: Verify Scenario
- Confirm Scenarios 3, 4, and 9 exist in the design's `bdd-specs.md`.

### Step 2: Implement Test (Red)
- Add the 3 `assert_grep` calls using the file's existing helper and style.
- **Verification**: `bash superpowers/tests/test-skill-touchpoints.sh` — the 3 new assertions FAIL (brainstorming's `SKILL.md` has no memory-related text).

## Verification Commands

```bash
bash superpowers/tests/test-skill-touchpoints.sh
```

## Success Criteria

- 3 new assertions exist and FAIL for the documented reason
- Zero regressions among the file's pre-existing assertions
