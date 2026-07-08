# Designing Loops — Implementation Plan (v2, reference-file shape)

> **For Claude:** REQUIRED SUB-SKILL: Load `superpowers:executing-plans` skill using the Skill tool to implement this plan task-by-task.

**Goal:** Add a single advisory reference file (`superpowers/skills/references/loop-types.md`) that classifies loop types (turn-based/goal-based/time-based/proactive) to primitives, plus a `goal-wrapper.md` Rule 3 (turn caps) and 7 pointer-sentence edits so the file is reachable from the skills loaded when the question arises.

**Architecture:** Plain markdown reference file with no frontmatter/registration/README entry — matching the sibling `references/*.md` convention. Integration is one-sentence pointers (not sections) from 7 existing files; one pointer back from `workflow-orchestration.md`. Content is citation-not-duplication: each concern points to its owner file by stable section name, never bare line number.

**Tech Stack:** Markdown only; verification via `grep`, the `plugin-optimizer` validator (token ceilings), and the existing `docs-index.sh` index.

**Design Support:**
- [BDD Specs](../2026-07-08-designing-loops-design/bdd-specs.md) — 20 scenarios across 5 Features, each tagged `(REQ-NNN)`
- [Architecture](../2026-07-08-designing-loops-design/architecture.md) — exact anchors for all 8 integration points, `loop-types.md` skeleton, verification commands
- [Best Practices](../2026-07-08-designing-loops-design/best-practices.md) — over/under-recommendation pitfalls, advisory-vs-mandatory L2/L3 boundary, citation-staleness discipline

## Context

Anthropic published "designing loops" guidance: four loop types distinguished by trigger, stop criteria, and primitive. The `superpowers` plugin already implements most of it under different names (`verification-before-completion`, `/goal` via `goal-wrapper.md`, `receiving-code-review` + the evaluator, retrospective's checklist evolution, the model-declaration and Bail-Out disciplines, `workflow-orchestration.md`). What is genuinely missing: nothing names the **time-based** type (`/loop`, `/schedule`) or connects "which loop type" to "which primitive" as a consultable decision aid, and `goal-wrapper.md` has no turn-cap guidance despite the blog calling it out.

An earlier round-1 design proposed a new auto-loading internal skill; an adversarial proportionality review returned RECONSIDER — the content (~5 paragraphs of novelty) did not warrant a separately-registered skill with an always-resident description whose trigger precision this repo cannot verify. The user confirmed the pivot on 2026-07-08: **reference file, not skill**. This plan implements the pivoted shape. Lesson recorded in persistent memory (`feedback_null_alternative_first`): before adding any new delivery surface, weigh the null alternative (existing references file + platform-native coverage).

This is greenfield-with-edits: one new file plus single-sentence edits to 7 existing files. No current-state/target-state table — the design's `_index.md` §Detailed Design and `architecture.md` already enumerate the exact before/after per file.

## Global Constraints

- **Compatibility**: `loop-types.md` is a plain markdown file with no YAML frontmatter, no `plugin.json` registration, no README entry — exactly matching `goal-wrapper.md`/`workflow-orchestration.md`'s shape (REQ-001). Violating this re-introduces the round-1 trigger-precision/lifecycle costs the pivot deleted.
- **Compatibility**: pointer sentences live OUTSIDE `using-superpowers`'s routing table — `hooks/session-start.sh:28` greps `^\| .*superpowers:` table rows into every session bootstrap; a table-row pointer would be scraped into every session (REQ-012).
- **Token budget**: edits to `retrospective/SKILL.md` (baseline 4671/5000) and `writing-plans/SKILL.md` (baseline 4778/5000) are single sentences only; `python3 plugin-optimizer/scripts/validate-plugin.py superpowers` must stay exit 0 after each such edit (REQ-016).
- **Forbidden**: the phrase "autonomous loop" must not appear in `loop-types.md` or any of the 8 touched files (REQ-015) — collides with Claude Code "auto mode" and `brainstorming`'s pre-existing generic "autonomous". Vocabulary: lowercase `turn-based loop`/`goal-based loop`/`time-based loop`/`proactive loop` in prose; backticked `/goal`/`/loop`/`/schedule`/`Workflow`.
- **Forbidden**: bare line-number citations anywhere in `loop-types.md` (REQ-009) — cite by file path + section/rule name so rename/renumber drift is detectable; verbatim quotes limited to the two Iron Law one-liners at most.
- **Forbidden**: no reproduction of goal-based mechanics, Workflow mechanics, verification discipline, or review discipline inside `loop-types.md` — each is cited to its owner file (REQ-006/REQ-004/REQ-007/REQ-008). Original content is limited to the time-based section and the two genuinely-new token items (interval matching; `/usage`//`/goal`//`/workflows` review).
- **Size**: `loop-types.md` targets 60-90 lines (REQ-017) — the 4-row table plus five short sections; L3 is unlimited but proportionality is checkable.

## Execution Plan

```yaml
tasks:
  - id: "001"
    subject: "Create loop-types.md reference + goal-wrapper Rule 3"
    slug: "loop-types-reference-and-rule-3"
    type: "impl"
    depends-on: []
  - id: "002"
    subject: "Five command skills pointer sentences + systematic-debugging second anchor"
    slug: "command-skills-pointers"
    type: "impl"
    depends-on: ["001"]
  - id: "003"
    subject: "using-superpowers pointer sentence outside the table"
    slug: "using-superpowers-pointer"
    type: "impl"
    depends-on: ["001"]
  - id: "004"
    subject: "workflow-orchestration See also pointer"
    slug: "workflow-orchestration-see-also"
    type: "impl"
    depends-on: ["001"]
  - id: "005"
    subject: "REQ-014/015/016 grep + validator verification"
    slug: "verification-grep-and-validator"
    type: "test"
    depends-on: ["001", "002", "003", "004"]
```

**Task File References (for detailed BDD scenarios):**
- [Task 001: loop-types.md reference + goal-wrapper Rule 3](./task-001-loop-types-reference-and-rule-3.md)
- [Task 002: Five command skills pointer sentences + systematic-debugging second anchor](./task-002-command-skills-pointers.md)
- [Task 003: using-superpowers pointer sentence outside the table](./task-003-using-superpowers-pointer.md)
- [Task 004: workflow-orchestration See also pointer](./task-004-workflow-orchestration-see-also.md)
- [Task 005: REQ-014/015/016 grep + validator verification](./task-005-verification-grep-and-validator.md)

## BDD Coverage

All 20 BDD scenarios from the design are covered. Tasks 001-004 each carry their covering scenarios inline; Task 005 is the cross-cutting verification that the union of all pointer/Rule-3/vocabulary requirements (REQ-014/REQ-015/REQ-016) holds across all 8 files. See individual task files for scenario mapping. Coverage matrix is validated by the Phase 4 BDD Coverage Review sub-agent.

## Dependency Chain

```
task-001 (loop-types.md + goal-wrapper Rule 3)
    │
    ├─→ task-002 (5 command-skill pointers + systematic-debugging 2nd anchor)
    │
    ├─→ task-003 (using-superpowers pointer, outside table)
    │
    ├─→ task-004 (workflow-orchestration See also)
    │
    └─→ task-005 (grep + validator verification)
            (also depends on 002, 003, 004)
```

**Analysis**:
- No circular dependencies.
- Logical flow: foundation (001 — the new file + the Rule 3 it cites) → three independent pointer-edit batches (002/003/004, runnable in parallel) → verification (005, gates all prior).
- Parallel paths: tasks 002, 003, 004 touch disjoint files and depend only on 001; a parallel executor may run them concurrently.

---

## Execution Handoff

**Plan complete and saved to `docs/plans/2026-07-08-designing-loops-plan/`. Load `superpowers:executing-plans` skill using the Skill tool — it orchestrates per-batch sub-agent coordinators through the full Phase 1-6 pipeline.**
