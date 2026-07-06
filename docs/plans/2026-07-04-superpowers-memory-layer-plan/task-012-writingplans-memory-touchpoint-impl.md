# Task 012: Writing-plans memory touchpoint — impl (GREEN)

**depends-on**: task-011

## Description

Edit `skills/writing-plans/SKILL.md` to add the memory read-before step and the conditional memory-write step, per `architecture.md` §3 writing-plans touchpoint table.

## Execution Context

**Task Number**: 012 of 020
**Phase**: Skill Touchpoints
**Prerequisites**: task-011's assertions exist and FAIL

## BDD Scenario

```gherkin
Scenario: writing-plans write-gate fires — a Phase 4 reflection sub-agent FAIL requiring rework
  Then writing-plans captures the false-positive cause as a memory file with `category=pitfall`
  And it invokes `lib/docs-index.sh upsert memory docs/memory/pitfall_<slug>.md --status active --summary "<one-line>"`

Scenario: writing-plans write-gate does NOT fire — every Phase 4 reflection sub-agent passes first try
  Then it does NOT invoke a memory-write step
```

**Spec Source**: `../2026-07-04-superpowers-memory-layer-design/bdd-specs.md` Scenarios 2, 5, 10; `architecture.md` §3

## Interfaces

**Exposes** (edits to `skills/writing-plans/SKILL.md`):
- Initialization, step 1 ("Design Check") — append, after the existing `docs-index.sh show <design-path>` call: run `bash "${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh" list --kind memory --status active`; Read the top matches before Phase 1 "Read Specs."
- Phase 5 "Git Commit" — new step 0.5, inserted between the existing step 0 (plan upsert) and step 1 (`git add`): **conditional on a Phase 4 sub-agent FAIL that required a fix-and-rerun (reuses the existing FAIL/rework sentence, not a first-pass PASS)** — if triggered, write `docs/memory/pitfall_<slug>.md` (typically `category: pitfall`) then run `bash "${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh" upsert memory docs/memory/<path> --status active --summary "<one-line>" --category pitfall`. No-op if every sub-agent passed first try.

**Consumes**: `lib/docs-index.sh list`/`upsert`

**Global Constraints respected**: write step explicitly conditional.

## Files to Modify/Create

- Modify: `superpowers/skills/writing-plans/SKILL.md:67` (Initialization step 1 — extend)
- Modify: `superpowers/skills/writing-plans/SKILL.md:215` (Phase 5 — insert new step 0.5 after the existing step 0)

## Steps

### Step 1: Verify Scenario
- Re-confirm Scenarios 2, 5, 10 against current `SKILL.md` text.

### Step 2: Implement Logic (Green)
- Apply both edits.

### Step 3: Verify & Refactor
- Run `bash superpowers/tests/test-skill-touchpoints.sh`; all 3 task-011 assertions PASS; zero regressions.

## Verification Commands

```bash
bash superpowers/tests/test-skill-touchpoints.sh
```

## Success Criteria

- All 3 task-011 assertions PASS
- Zero regressions
