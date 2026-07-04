# Task 014: Executing-plans memory touchpoint — impl (GREEN)

**depends-on**: task-013

## Description

Edit `skills/executing-plans/SKILL.md` to add the memory read-before step and the conditional memory-write step, per `architecture.md` §3 executing-plans touchpoint table.

## Execution Context

**Task Number**: 014 of 020
**Phase**: Skill Touchpoints
**Prerequisites**: task-013's assertions exist and FAIL

## BDD Scenario

```gherkin
Scenario: executing-plans write-gate fires — the intra-plan "variety gap" signal (2+ rework rounds, batch eventually PASSes)
  Then the coordinator captures the recurring rework pattern as a memory file with `category=pitfall`
  And it invokes `lib/docs-index.sh upsert memory docs/memory/pitfall_<slug>.md --status active --summary "<one-line>"`
  And the coordinator's returned verdict (PASS) is unaffected by the memory write

Scenario: executing-plans write-gate does NOT fire — a batch evaluator passes on round 1
  Then it does NOT invoke a memory-write step
```

**Spec Source**: `../2026-07-04-superpowers-memory-layer-design/bdd-specs.md` Scenarios 6, 11; `architecture.md` §3

## Interfaces

**Exposes** (edits to `skills/executing-plans/SKILL.md`):
- Initialization, step 1 ("Plan Check") — append, after the existing `docs-index.sh show <plan-path>` call: run `bash "${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh" list --kind memory --status active`; Read the top matches before Phase 1 "Plan Review."
- Phase 5 "Git Commit" — extend the existing CRITICAL post-commit index-flip block (the one that runs `set-status <plan-path> "implemented:<sha>"`): **conditional on the existing intra-plan-learning "variety gap" signal** (`references/intra-plan-learning.md:54` — "all checklist items PASS for a batch but the batch required 2+ rework rounds") — if any batch this run hit that signal, also write `docs/memory/pitfall_<slug>.md` and run `bash "${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh" upsert memory docs/memory/<path> --status active --summary "<one-line>" --category pitfall`, folded into the same dedicated follow-up commit the block already creates. Explicitly note in the prose: this is distinct from `references/batch-execution-playbook.md:165`'s separate "max 2 rounds before escalation" hard-abort cap, which is NOT a memory-write trigger.

**Consumes**: `lib/docs-index.sh list`/`upsert`

**Global Constraints respected**: write step explicitly conditional; correct signal (variety-gap, not hard-abort cap) is named precisely to avoid future conflation.

## Files to Modify/Create

- Modify: `superpowers/skills/executing-plans/SKILL.md:51` (Initialization step 1 — extend)
- Modify: `superpowers/skills/executing-plans/SKILL.md:97` (Phase 5 CRITICAL block — extend)

## Steps

### Step 1: Verify Scenario
- Re-confirm Scenarios 6, 11 against current `SKILL.md` text.

### Step 2: Implement Logic (Green)
- Apply both edits.

### Step 3: Verify & Refactor
- Run `bash superpowers/tests/test-skill-touchpoints.sh`; all 3 task-013 assertions PASS; zero regressions.

## Verification Commands

```bash
bash superpowers/tests/test-skill-touchpoints.sh
```

## Success Criteria

- All 3 task-013 assertions PASS
- Zero regressions
