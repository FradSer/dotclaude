# Task 010: Brainstorming memory touchpoint — impl (GREEN)

**depends-on**: task-009

## Description

Edit `skills/brainstorming/SKILL.md` to add the memory read-before step and the conditional memory-write step, exactly as specified in the design's `architecture.md` §3 brainstorming touchpoint table.

## Execution Context

**Task Number**: 010 of 020
**Phase**: Skill Touchpoints
**Prerequisites**: task-009's assertions exist and FAIL

## BDD Scenario

```gherkin
Scenario: Memory read-before step finds no relevant memory and the skill proceeds normally
  When the brainstorming skill begins a new design
  Then it invokes `lib/docs-index.sh list --kind memory --status active`

Scenario: brainstorming write-gate fires — 2+ evaluator REWORK rounds on a design
  When brainstorming reaches its existing "REWORK 2+ rounds" trigger
  Then brainstorming captures the recurring rework cause as a memory file
  And it invokes `lib/docs-index.sh upsert memory docs/memory/<category>_<slug>.md --status active --summary "<one-line>"`

Scenario: brainstorming write-gate does NOT fire — first-pass evaluator PASS
  When brainstorming completes and commits the design
  Then it does NOT invoke a memory-write step
```

**Spec Source**: `../2026-07-04-superpowers-memory-layer-design/bdd-specs.md` Scenarios 3, 4, 9; `architecture.md` §3

## Interfaces

**Exposes** (edits to `skills/brainstorming/SKILL.md`):
- Initialization, step 2 ("Read project context") — append, after the existing two design `list` calls: run `bash "${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh" list --kind memory --status active`; Read the 3-5 topically-relevant rows' files before Phase 1 exploration.
- Phase 3 Wrap-up — new step 0.5 (CRITICAL — do not defer, same marker style as the existing step 0), inserted between the existing step 0 (design upsert) and step 1 (`git add`): **conditional on the existing "REWORK 2+ rounds" trigger from Phase 2** — if 2+ REWORK rounds occurred, write `docs/memory/<category>_<slug>.md` (`category: decision` for a scope reversal, `category: pitfall` for a recurring evaluator-caught mistake) then run `bash "${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh" upsert memory docs/memory/<path> --status active --summary "<one-line>" --category <category>`. If fewer than 2 REWORK rounds occurred, this step is a no-op.

**Consumes**: `lib/docs-index.sh list`/`upsert` (both fully implemented as of task-008)

**Global Constraints respected**: the write step is explicitly conditional in the prose (never fires on first-pass PASS).

## Files to Modify/Create

- Modify: `superpowers/skills/brainstorming/SKILL.md:55` (Initialization step 2 — extend)
- Modify: `superpowers/skills/brainstorming/SKILL.md:149` (Phase 3 Wrap-up — insert new step 0.5 after the existing step 0)

## Steps

### Step 1: Verify Scenario
- Re-confirm Scenarios 3, 4, 9 against current (pre-edit) `SKILL.md` text.

### Step 2: Implement Logic (Green)
- Apply both edits exactly as specified in Interfaces.

### Step 3: Verify & Refactor
- Run `bash superpowers/tests/test-skill-touchpoints.sh`; all 3 task-009 assertions PASS; zero regressions among pre-existing assertions in the file.

## Verification Commands

```bash
bash superpowers/tests/test-skill-touchpoints.sh
```

## Success Criteria

- All 3 task-009 assertions PASS
- Zero regressions among pre-existing `test-skill-touchpoints.sh` assertions
