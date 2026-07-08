# Task 005: REQ-014/015/016 grep + validator verification

**depends-on**: task-001, task-002, task-003, task-004 (all integration edits must be in place before the cross-cutting verification can pass)

## Description

Run the cross-cutting verification that the union of all pointer/Rule-3/vocabulary/token-ceiling requirements holds across all 8 integration-point files. This is the binary post-implementation check defined in `architecture.md` §4: all 8 files match `grep -l "loop-types"`; `goal-wrapper.md` matches `grep -q "Rule 3"`; no touched file contains "autonomous loop"; the `plugin-optimizer` validator stays exit 0.

## Execution Context

**Task Number**: 005 of 005
**Phase**: Verification
**Prerequisites**: Tasks 001-004 complete — `loop-types.md` created, `goal-wrapper.md` Rule 3 added, 7 pointer-sentence edits in place.

## BDD Scenario

This task is the verification harness for the structural requirements (REQ-014 grep verifiability, REQ-015 vocabulary gate, REQ-016 token ceilings) that cut across all 8 files. These are verification-method constraints, not behavioral Given/When/Then; `bdd-specs.md` Traceability Notes row for REQ-014/REQ-015/REQ-016/REQ-017 covers them. The 20 behavioral scenarios are covered by the content tasks (001-004); this task asserts the structural shell that makes them all hold simultaneously.

**Spec Source**: `../2026-07-08-designing-loops-design/bdd-specs.md` (for reference; REQ-014/015/016/017 in Traceability Notes)

## Interfaces

**Exposes** (interfaces this task produces):
- Verification verdict: a pass/fail for the 8-file grep set (REQ-014), the Rule 3 content check (REQ-010/REQ-014), the vocabulary gate (REQ-015), and the token-ceiling validator (REQ-016). This task produces no file artifacts — it runs the verification commands and reports the result.

**Consumes** (interfaces from `depends-on` tasks this task relies on):
- `superpowers/skills/references/loop-types.md` + `goal-wrapper.md` Rule 3 (from task 001)
- 5 command-skill pointer sentences + systematic-debugging second anchor (from task 002)
- `using-superpowers` pointer sentence (from task 003)
- `workflow-orchestration.md` See also (from task 004)

**Global Constraints respected**: REQ-014 (8-file grep verifiability), REQ-015 (vocabulary gate), REQ-016 (token ceilings, validator exit 0), REQ-017 (size target, soft).

## Files to Modify/Create

- None (verification-only task).

## Steps

### Step 1: Run the 8-file pointer-existence grep (REQ-014)
- Run `grep -l "loop-types"` across all 8 integration-point files (5 command skills, `using-superpowers`, `workflow-orchestration.md`, `goal-wrapper.md`). All 8 must match.

### Step 2: Run the Rule 3 content check (REQ-010/REQ-014)
- `grep -q "Rule 3" superpowers/skills/references/goal-wrapper.md && echo RULE3-OK`.

### Step 3: Run the vocabulary gate (REQ-015)
- `grep -ri "autonomous loop"` over `superpowers/skills/` — must return zero matches across all touched files.

### Step 4: Run the token-ceiling validator (REQ-016)
- `python3 plugin-optimizer/scripts/validate-plugin.py superpowers` — must exit 0 (baseline: two pre-existing `should` warnings for retrospective 4671/5000 and writing-plans 4778/5000 are acceptable; exit 0 is the gate).

### Step 5: Size target sanity (REQ-017, soft)
- `wc -l superpowers/skills/references/loop-types.md` — target 60-90 lines. Soft target; do not pad or trim solely to hit a number.

## Verification Commands

```bash
# All 8 files must match (REQ-014)
grep -l "loop-types" \
  superpowers/skills/{brainstorming,writing-plans,executing-plans,retrospective,systematic-debugging,using-superpowers}/SKILL.md \
  superpowers/skills/references/{workflow-orchestration,goal-wrapper}.md
# Rule 3 content actually present (REQ-010/REQ-014)
grep -q "Rule 3" superpowers/skills/references/goal-wrapper.md && echo RULE3-OK
# Vocabulary gate — zero matches (REQ-015)
! grep -ri "autonomous loop" superpowers/skills/ && echo VOCAB-OK
# Token ceilings — exit 0 (REQ-016)
python3 plugin-optimizer/scripts/validate-plugin.py superpowers
# Size target, soft (REQ-017)
wc -l superpowers/skills/references/loop-types.md
```

## Success Criteria

- All 8 integration-point files match `grep -l "loop-types"` (REQ-014).
- `goal-wrapper.md` matches `grep -q "Rule 3"` (REQ-010/REQ-014).
- Zero "autonomous loop" matches across `superpowers/skills/` (REQ-015).
- `plugin-optimizer` validator exit 0 (REQ-016).
- `loop-types.md` in the 60-90 line range (REQ-017, soft).
