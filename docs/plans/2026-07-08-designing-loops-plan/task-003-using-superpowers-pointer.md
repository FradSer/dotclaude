# Task 003: using-superpowers pointer sentence outside the table

**depends-on**: task-001 (the `loop-types.md` file must exist before the pointer can target it)

## Description

Add one pointer sentence to `superpowers/skills/using-superpowers/SKILL.md` between the routing table (ends ~line 27) and `## Lineage and rationale` (~line 29). The sentence MUST NOT be a table row — `hooks/session-start.sh:28` greps `^\| .*superpowers:` table rows into every session bootstrap, so a table-row pointer would be scraped into every session. This is the discoverability integration for the orthogonal "how should it run" question the routing table does not answer.

## Execution Context

**Task Number**: 003 of 005
**Phase**: Integration
**Prerequisites**: `superpowers/skills/references/loop-types.md` exists (task 001).

## BDD Scenario

This task's behavioral effect is reachability (structural REQ-012, verified by REQ-014's grep set in task 005). The scenarios that exercise the *content* reached via this pointer are the 16 carried by task 001. The routing-table-stays-untouched invariant is a structural constraint (REQ-012), not a Given/When/Then; `bdd-specs.md` Traceability Notes row for REQ-011/REQ-012/REQ-013 covers it.

**Spec Source**: `../2026-07-08-designing-loops-design/bdd-specs.md` (for reference; REQ-012 in Traceability Notes)

## Interfaces

**Exposes** (interfaces this task produces):
- File edit: `superpowers/skills/using-superpowers/SKILL.md` — one prose sentence between the routing table and `## Lineage and rationale` (exact anchor in `architecture.md` §3.3). Sentence: *"That table answers which skill; for the orthogonal question of how the chosen work should run (plain turn, `/goal`, `/loop`, `/schedule`), see `../references/loop-types.md`."*

**Consumes** (interfaces from `depends-on` tasks this task relies on):
- `superpowers/skills/references/loop-types.md` (from task 001) — the pointer target.

**Global Constraints respected**: REQ-012 (pointer is a sentence, NOT a table row; stays outside the `^\| .*superpowers:` rows that `hooks/session-start.sh:28` scrapes into every session), REQ-015 (no "autonomous loop").

## Files to Modify/Create

- Modify: `superpowers/skills/using-superpowers/SKILL.md` — insert the pointer sentence between the routing table (ends ~line 27) and `## Lineage and rationale` (~line 29); exact text in `architecture.md` §3.3

## Steps

### Step 1: Insert the pointer sentence outside the table
- Insert the sentence at the verified anchor (§3.3). Confirm it is prose, not a `| ... |` table row.

### Step 2: Confirm the routing-table rows are untouched
- `grep -cE '^\| .*superpowers:' superpowers/skills/using-superpowers/SKILL.md` should return the same count as before the edit (the pointer added no table row). Run `bash superpowers/hooks/session-start.sh` dry-check if available, or visually confirm no new `^\|` line was added.

## Verification Commands

```bash
# Pointer present (REQ-014, partial)
grep -q "loop-types" superpowers/skills/using-superpowers/SKILL.md && echo POINTER-OK
# No new table row scraped by session-start (REQ-012) — the pointer line is NOT a ^| row
! grep -E '^\| .*loop-types' superpowers/skills/using-superpowers/SKILL.md && echo NOT-A-TABLE-ROW
# Vocabulary (REQ-015)
! grep -ri "autonomous loop" superpowers/skills/using-superpowers/SKILL.md && echo VOCAB-OK
```

## Success Criteria

- Pointer sentence present between the routing table and `## Lineage and rationale` (REQ-012).
- Pointer is prose, not a `| ... |` table row — the `^\| .*superpowers:` set scraped by `hooks/session-start.sh:28` is unchanged (REQ-012).
- No "autonomous loop" introduced (REQ-015).
