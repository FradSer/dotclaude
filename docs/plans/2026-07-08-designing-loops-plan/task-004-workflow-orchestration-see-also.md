# Task 004: workflow-orchestration See also pointer

**depends-on**: task-001 (the `loop-types.md` file must exist before the pointer can target it)

## Description

Append a `## See also` section to `superpowers/skills/references/workflow-orchestration.md` pointing to `./loop-types.md`. This is the reciprocal pointer: `loop-types.md`'s proactive section cites `workflow-orchestration.md`'s opt-in rules (Rule 2) and >4-task threshold (Rule 3); this pointer closes the loop from the file whose Rule 3 threshold `loop-types.md` cites.

## Execution Context

**Task Number**: 004 of 005
**Phase**: Integration
**Prerequisites**: `superpowers/skills/references/loop-types.md` exists (task 001).

## BDD Scenario

This task's behavioral effect is reachability (structural REQ-013, verified by REQ-014's grep set in task 005). The proactive-composition scenarios that exercise the *content* reached via this reciprocal pointer are carried by task 001 (the `Workflow` opt-in and chain-as-partial-example scenarios).

**Spec Source**: `../2026-07-08-designing-loops-design/bdd-specs.md` (for reference; REQ-013 in Traceability Notes)

## Interfaces

**Exposes** (interfaces this task produces):
- File edit: `superpowers/skills/references/workflow-orchestration.md` — append a `## See also` section after the current EOF (~line 52). Content (exact text in `architecture.md` §3.4): "`./loop-types.md` — `Workflow` composition is the proactive arm of the four loop types; the other three (turn-based, goal-based/`/goal`, time-based/`/loop` `/schedule`) live there."

**Consumes** (interfaces from `depends-on` tasks this task relies on):
- `superpowers/skills/references/loop-types.md` (from task 001) — the pointer target; its proactive section is the reciprocal of this pointer.

**Global Constraints respected**: REQ-013 (final `## See also` section), REQ-015 (no "autonomous loop").

## Files to Modify/Create

- Modify: `superpowers/skills/references/workflow-orchestration.md` — append `## See also` section after ~line 52 (current EOF); exact text in `architecture.md` §3.4

## Steps

### Step 1: Append the See also section
- Append the `## See also` block per `architecture.md` §3.4 (exact text provided there).

## Verification Commands

```bash
# Pointer present (REQ-014, partial)
grep -q "loop-types" superpowers/skills/references/workflow-orchestration.md && echo POINTER-OK
# See also section present
grep -q "## See also" superpowers/skills/references/workflow-orchestration.md && echo SEE-ALSO-OK
# Vocabulary (REQ-015)
! grep -ri "autonomous loop" superpowers/skills/references/workflow-orchestration.md && echo VOCAB-OK
```

## Success Criteria

- `## See also` section appended, pointing to `./loop-types.md` (REQ-013).
- No "autonomous loop" introduced (REQ-015).
