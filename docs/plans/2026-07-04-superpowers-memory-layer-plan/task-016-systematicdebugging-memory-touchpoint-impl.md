# Task 016: Systematic-debugging memory touchpoint — impl (GREEN)

**depends-on**: task-015

## Description

Edit `skills/systematic-debugging/SKILL.md`: add the `docs-index.sh` scope to `allowed-tools`, prepend a new memory read-before step 0 to Phase 1 (skipped on the bail-out path), and append a new step 6 after the existing "Architecture Questioning After 3+ Failed Fixes" step — this skill's ONLY conditional memory-write step, folded into its existing completion turn (no new phase, no separate commit).

## Execution Context

**Task Number**: 016 of 020
**Phase**: Skill Touchpoints
**Prerequisites**: task-015's assertions exist and FAIL

## BDD Scenario

```gherkin
Scenario: systematic-debugging write-gate fires — its existing 3+ failed fixes trigger
  Then it captures the underlying architectural insight as a memory file with `category=decision` or `category=convention`
  And it invokes `lib/docs-index.sh upsert memory docs/memory/decision_<slug>.md --status active --summary "<one-line>"`

Scenario: systematic-debugging write-gate fires — an explicit cross-cutting gotcha, independent of the 3+ threshold
  Then it captures the gotcha as a memory file with `category=pitfall`, even though
    the 3+ failed-fixes threshold was never reached

Scenario: systematic-debugging write-gate does NOT fire — routine single-attempt fix
  Then it does NOT invoke a memory-write step

Scenario: systematic-debugging's fix-and-regression-test contract is unchanged even when memory is written
  Then it narrates exactly the same three-part completion output as always
  And no additional phase, commit, or user-facing deliverable is introduced by the memory write
```

**Spec Source**: `../2026-07-04-superpowers-memory-layer-design/bdd-specs.md` Scenario 3a + counterpart, Scenarios 7, 12, 18; `architecture.md` §3

## Interfaces

**Exposes** (edits to `skills/systematic-debugging/SKILL.md`):
- `allowed-tools` frontmatter (line 6) — add `"Bash(${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh:*)"`.
- New step 0, prepended to Phase 1 "Root Cause Investigation" (before the existing step 1 "Read Error Messages Carefully"), **only on the non-bail-out path**: run `bash "${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh" list --kind memory --status active`, filter by summary keywords matching the symptom, Read the top 2-3 matches. Explicitly note this step is skipped whenever the Bail-Out Check fires (symmetric with how the bail-out already skips every other Phase-1-onward step).
- New step 6, appended immediately after the existing "5. Architecture Questioning After 3+ Failed Fixes" step, inside Phase 4 "Implementation" — **the skill's only `docs/` touchpoint, a single conditional step, not a new phase**: fires when EITHER (a) the existing "3+ fixes → question architecture" trigger fires, OR (b) the investigation surfaced an explicit cross-cutting gotcha regardless of fix-attempt count. On fire: write `docs/memory/<category>_<slug>.md` (`category: pitfall` typically, `category: decision` if the architecture-questioning step concluded a redesign is warranted), using the existing Inline Plan's six-line shape as `Fact`/`Why` material when one was recorded, `source: commit:<short-sha>`. Then run `bash "${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh" upsert memory docs/memory/<path> --status active --summary "<one-line>" --category <category>`, staged into the same commit as the fix + regression test. If neither condition holds, this step is a no-op.

**Consumes**: `lib/docs-index.sh list`/`upsert`

**Global Constraints respected**: no new phase/commit machinery added to this skill; the "fix + regression test, never a planning artifact" deliverable sentence stays textually intact.

## Files to Modify/Create

- Modify: `superpowers/skills/systematic-debugging/SKILL.md:6` (`allowed-tools` frontmatter)
- Modify: `superpowers/skills/systematic-debugging/SKILL.md:99` (prepend new step 0 to Phase 1)
- Modify: `superpowers/skills/systematic-debugging/SKILL.md:241-255` (append new step 6 after the existing 3+-failed-fixes step)

## Steps

### Step 1: Verify Scenario
- Re-confirm the relevant scenarios against current `SKILL.md` text.

### Step 2: Implement Logic (Green)
- Apply the three edits.

### Step 3: Verify & Refactor
- Run `bash superpowers/tests/test-skill-touchpoints.sh`; all 5 task-015 assertions PASS; zero regressions.
- Manually re-read the skill's "Slash-command Usage" section to confirm the "fix + regression test, never a planning document" sentence is unchanged.

## Verification Commands

```bash
bash superpowers/tests/test-skill-touchpoints.sh
```

## Success Criteria

- All 5 task-015 assertions PASS
- Zero regressions
- The skill's deliverable-discipline sentence is unchanged
