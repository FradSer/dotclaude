# Superpowers Memory Layer Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Load `superpowers:executing-plans` skill using the Skill tool to implement this plan task-by-task.

**Goal:** Extend the shipped docs-index convention (`lib/docs-index.sh` + `docs/README.md`) with a 4th `kind=memory` so all five superpowers skills gain a shared, git-tracked, anti-bloat memory layer of distilled facts/decisions/conventions/pitfalls.

**Architecture:** One-fact-per-file (`docs/memory/<category>_<slug>.md`) with only a one-line pointer row per file in the existing 5-column `docs/README.md` table — reusing the shipped 60-line ceiling, collapse rule, and atomic-write machinery verbatim. Every skill gains a read-before step at entry and a conditional write-after step gated on a threshold the skill already tracks internally (no new thresholds invented anywhere).

**Tech Stack:** Bash (`lib/docs-index.sh`, `set -euo pipefail`, `grep`/`awk`/`sed` only, no `jq`); plain-bash test harness (`tests/run-docs-index-tests.sh` + `tests/test_helpers.sh`, `bats` is not on PATH in this environment); grep-based skill-touchpoint assertions (`tests/test-skill-touchpoints.sh`); Markdown + YAML frontmatter for memory files; JSON plugin manifests (`plugin.json`, `marketplace.json`).

**Design Support:**
- [BDD Specs](../2026-07-04-superpowers-memory-layer-design/bdd-specs.md)
- [Architecture](../2026-07-04-superpowers-memory-layer-design/architecture.md)
- [Best Practices](../2026-07-04-superpowers-memory-layer-design/best-practices.md)

## Context

The design at `docs/plans/2026-07-04-superpowers-memory-layer-design/` (evaluator PASS, round 4) is approved and active in the docs index. It extends the already-shipped docs-index convention — today `kind ∈ {design, plan, retro}`, one shared leaf script, four skill touchpoints (brainstorming, writing-plans, executing-plans, retrospective) — with a fourth `kind=memory`, giving `docs/README.md` a genuine memory-layer role (distilled, reusable facts, not just artifact pointers) modeled structurally on Claude Code's own file-based memory system. Crucially, `systematic-debugging` gains its first-ever `docs/` touchpoint, and `docs/README.md`'s anti-bloat guarantees (60-line ceiling, two-stage collapse rule) extend to memory rows with zero new ceiling logic.

Direct inspection of `superpowers/lib/docs-index.sh` during plan-writing surfaced two implementation-level gaps the design's `architecture.md` sketched but did not fully resolve at the bash-mechanics level — both are nailed down precisely in this plan's task files rather than left for the executor to improvise:

1. `topic_of_path()`'s existing fallback (bare basename for any path not matching `docs/plans/YYYY-MM-DD-*`) would make every `docs/memory/<category>_<slug>.md` path its own unique collapse-group of one — the design's "grouped by category" collapse claim requires a genuinely new branch in `topic_of_path()`, not an emergent property of the existing fallback (task 007/008).
2. The design's `bdd-specs.md` Scenario 16 tests a `--category` CLI flag on `upsert` that `architecture.md`'s diff-table never explicitly names as a new flag. This plan treats `bdd-specs.md` (the evaluator-approved, more granular artifact) as authoritative on this point and specifies the flag's exact parsing/validation/exclusion rules (task 003/004).

| Aspect | Current State | Target State |
|--------|--------------|--------------|
| `kind` controlled vocabulary | `design \| plan \| retro` | `design \| plan \| retro \| memory` |
| Status vocabulary for `memory` rows | n/a | `active \| expired:<reason>` only, script-enforced |
| `docs/memory/` directory | does not exist | one file per fact, `<category>_<slug>.md` naming |
| `systematic-debugging` `docs/` touchpoints | none (zero today) | read-before (non-bail-out path) + one conditional write-after step, no new phase |
| Collapse-grouping fallback (`topic_of_path()`) | bare basename (unique per file) | category-prefix extraction for `docs/memory/` paths |
| Expired-row physical archive | n/a (kind didn't exist) | `docs/memory/archive/` on drop, non-recursive glob keeps it invisible to `rebuild` |
| `superpowers` plugin version | `3.5.0` | `3.6.0` |
| `superpowers/README.md` | no memory-layer mention | one bullet per skill section |

## Global Constraints

- **No new test framework**: extend `tests/run-docs-index-tests.sh` (plain-bash `assert_*` helpers from `test_helpers.sh`) and `tests/test-skill-touchpoints.sh` (grep-based `assert_grep`) — never introduce `bats` or a Python test for these files.
- **No new index file/format**: `kind=memory` rows live in the existing `docs/README.md` 5-column table (`path | kind | status | summary | updated`); `category` is frontmatter-only inside the memory file, never a 6th row column.
- **Status vocabulary for `kind=memory` rows is restricted to `active | expired:<reason>`** — enforced by the script (`validate_status_for_kind`, task 004), not documentation-only convention.
- **Category enum is exactly `convention | pitfall | decision | preference`** — never `type`, `kind`, `status`, or `reference` (those are reserved words at other schema levels; see the design's Glossary).
- **No new script dependency**: `lib/docs-index.sh` stays `grep`/`awk`/`sed`/bash-only — no `jq`, no `python`, matching its existing "No jq dependency" guarantee.
- **Memory write-gates are conditional only** — every skill's write-gate reuses a threshold the skill already tracks (brainstorming's 2+ REWORK rounds, writing-plans' Phase 4 FAIL, executing-plans' variety-gap signal, systematic-debugging's 3+ failed-fixes trigger, retrospective's ADD/MODIFY thresholds). **No task may add a new, invented threshold.** This is the core anti-bloat property under test (Scenarios 9-13's negative-path assertions).
- **Zero behavior change for existing `kind ∈ {design, plan, retro}` rows** — every new branch in `lib/docs-index.sh` must be additive; re-running the full pre-existing test suite after every task must show zero regressions.
- **Plugin version bump (`3.5.0` → `3.6.0`) and `marketplace.json` sync happen only after all functional work lands** (task 019), never mid-implementation.
- **`retrospective`'s existing Pre-Check B (private/global/harness-injected memory recall) stays unchanged** beyond the one additive promotion-bridge sentence (task 018) — no rewording of its existing paragraph.

## Execution Plan

```yaml
tasks:
  - id: "001"
    subject: "Memory kind vocabulary — test"
    slug: "memory-kind-vocab-test"
    type: "test"
    depends-on: []
  - id: "002"
    subject: "Memory kind vocabulary — impl"
    slug: "memory-kind-vocab-impl"
    type: "impl"
    depends-on: ["001"]
  - id: "003"
    subject: "Memory status restriction + category flag — test"
    slug: "memory-status-category-restriction-test"
    type: "test"
    depends-on: ["002"]
  - id: "004"
    subject: "Memory status restriction + category flag — impl"
    slug: "memory-status-category-restriction-impl"
    type: "impl"
    depends-on: ["003"]
  - id: "005"
    subject: "Memory scan + rebuild — test"
    slug: "memory-scan-rebuild-test"
    type: "test"
    depends-on: ["002", "003"]  # file-conflict guard: shares run-docs-index-tests.sh with 003
  - id: "006"
    subject: "Memory scan + rebuild — impl"
    slug: "memory-scan-rebuild-impl"
    type: "impl"
    depends-on: ["005", "004"]  # file-conflict guard: shares docs-index.sh with 004
  - id: "007"
    subject: "Memory collapse grouping + archive-on-drop — test"
    slug: "memory-collapse-archive-test"
    type: "test"
    depends-on: ["004", "006"]
  - id: "008"
    subject: "Memory collapse grouping + archive-on-drop — impl"
    slug: "memory-collapse-archive-impl"
    type: "impl"
    depends-on: ["007"]
  - id: "009"
    subject: "Brainstorming memory touchpoint — test"
    slug: "brainstorming-memory-touchpoint-test"
    type: "test"
    depends-on: ["008"]
  - id: "010"
    subject: "Brainstorming memory touchpoint — impl"
    slug: "brainstorming-memory-touchpoint-impl"
    type: "impl"
    depends-on: ["009"]
  - id: "011"
    subject: "Writing-plans memory touchpoint — test"
    slug: "writingplans-memory-touchpoint-test"
    type: "test"
    depends-on: ["008", "009"]  # file-conflict guard: shares test-skill-touchpoints.sh with 009
  - id: "012"
    subject: "Writing-plans memory touchpoint — impl"
    slug: "writingplans-memory-touchpoint-impl"
    type: "impl"
    depends-on: ["011"]
  - id: "013"
    subject: "Executing-plans memory touchpoint — test"
    slug: "executingplans-memory-touchpoint-test"
    type: "test"
    depends-on: ["008", "011"]  # file-conflict guard: shares test-skill-touchpoints.sh with 011
  - id: "014"
    subject: "Executing-plans memory touchpoint — impl"
    slug: "executingplans-memory-touchpoint-impl"
    type: "impl"
    depends-on: ["013"]
  - id: "015"
    subject: "Systematic-debugging memory touchpoint — test"
    slug: "systematicdebugging-memory-touchpoint-test"
    type: "test"
    depends-on: ["008", "013"]  # file-conflict guard: shares test-skill-touchpoints.sh with 013
  - id: "016"
    subject: "Systematic-debugging memory touchpoint — impl"
    slug: "systematicdebugging-memory-touchpoint-impl"
    type: "impl"
    depends-on: ["015"]
  - id: "017"
    subject: "Retrospective memory touchpoint — test"
    slug: "retrospective-memory-touchpoint-test"
    type: "test"
    depends-on: ["008", "015"]  # file-conflict guard: shares test-skill-touchpoints.sh with 015
  - id: "018"
    subject: "Retrospective memory touchpoint — impl"
    slug: "retrospective-memory-touchpoint-impl"
    type: "impl"
    depends-on: ["017"]
  - id: "019"
    subject: "Plugin version bump + marketplace.json sync"
    slug: "plugin-version-marketplace-sync"
    type: "config"
    depends-on: ["010", "012", "014", "016", "018"]
  - id: "020"
    subject: "README memory-layer documentation"
    slug: "readme-memory-layer-docs"
    type: "docs"
    depends-on: ["019"]
```

**Task File References:**
- [Task 001: Memory kind vocabulary — test](./task-001-memory-kind-vocab-test.md)
- [Task 002: Memory kind vocabulary — impl](./task-002-memory-kind-vocab-impl.md)
- [Task 003: Memory status restriction + category flag — test](./task-003-memory-status-category-restriction-test.md)
- [Task 004: Memory status restriction + category flag — impl](./task-004-memory-status-category-restriction-impl.md)
- [Task 005: Memory scan + rebuild — test](./task-005-memory-scan-rebuild-test.md)
- [Task 006: Memory scan + rebuild — impl](./task-006-memory-scan-rebuild-impl.md)
- [Task 007: Memory collapse grouping + archive-on-drop — test](./task-007-memory-collapse-archive-test.md)
- [Task 008: Memory collapse grouping + archive-on-drop — impl](./task-008-memory-collapse-archive-impl.md)
- [Task 009: Brainstorming memory touchpoint — test](./task-009-brainstorming-memory-touchpoint-test.md)
- [Task 010: Brainstorming memory touchpoint — impl](./task-010-brainstorming-memory-touchpoint-impl.md)
- [Task 011: Writing-plans memory touchpoint — test](./task-011-writingplans-memory-touchpoint-test.md)
- [Task 012: Writing-plans memory touchpoint — impl](./task-012-writingplans-memory-touchpoint-impl.md)
- [Task 013: Executing-plans memory touchpoint — test](./task-013-executingplans-memory-touchpoint-test.md)
- [Task 014: Executing-plans memory touchpoint — impl](./task-014-executingplans-memory-touchpoint-impl.md)
- [Task 015: Systematic-debugging memory touchpoint — test](./task-015-systematicdebugging-memory-touchpoint-test.md)
- [Task 016: Systematic-debugging memory touchpoint — impl](./task-016-systematicdebugging-memory-touchpoint-impl.md)
- [Task 017: Retrospective memory touchpoint — test](./task-017-retrospective-memory-touchpoint-test.md)
- [Task 018: Retrospective memory touchpoint — impl](./task-018-retrospective-memory-touchpoint-impl.md)
- [Task 019: Plugin version bump + marketplace.json sync](./task-019-plugin-version-marketplace-sync.md)
- [Task 020: README memory-layer documentation](./task-020-readme-memory-layer-docs.md)

## BDD Coverage

All 27 scenarios in the design's `bdd-specs.md` are covered:

| Scenario | Covering task(s) |
|---|---|
| Cold start — first memory write creates docs/memory/ and the first kind=memory row | 001/002, 005/006 |
| Memory read-before step surfaces a relevant active memory file (writing-plans) | 011/012 |
| Memory read-before step finds no relevant memory (brainstorming) | 009/010 |
| systematic-debugging's memory read-before step surfaces a relevant active memory file | 015/016 |
| systematic-debugging's memory read-before step is skipped on the bail-out path | 015/016 |
| executing-plans' memory read-before step surfaces a relevant active memory file | 013/014 |
| retrospective's memory read-before step folds relevant memory into Phase 1 Data Collection | 017/018 |
| brainstorming write-gate fires — 2+ evaluator REWORK rounds | 009/010 |
| writing-plans write-gate fires — a Phase 4 reflection sub-agent FAIL requiring rework | 011/012 |
| executing-plans write-gate fires — the intra-plan "variety gap" signal | 013/014 |
| systematic-debugging write-gate fires — its existing 3+ failed fixes trigger | 015/016 |
| systematic-debugging write-gate fires — an explicit cross-cutting gotcha | 015/016 |
| retrospective write-gate fires — a Phase 3 proposal reaches the ADD or MODIFY threshold | 017/018 |
| retrospective promotes a recalled global-memory prior into a project-local memory file | 017/018 |
| brainstorming write-gate does NOT fire — first-pass evaluator PASS | 009/010 |
| writing-plans write-gate does NOT fire — every Phase 4 reflection sub-agent passes first try | 011/012 |
| executing-plans write-gate does NOT fire — a batch evaluator passes on round 1 | 013/014 |
| systematic-debugging write-gate does NOT fire — routine single-attempt fix | 015/016 |
| retrospective write-gate does NOT fire — no proposal meets the ADD/MODIFY threshold | 017/018 |
| Two memory files on the same concept are MODIFY-merged into one | 017/018 |
| An expired memory row's file is archived and dropped from the index | 007/008 (script mechanism) + retrospective's existing, unmodified invalidate-after step (kind-agnostic by construction once task 004 lands — no new SKILL.md edit needed for the expiry trigger itself) |
| Malformed or missing category is rejected with exit code 2, no write | 003/004 |
| The 60-line ceiling collapse rule applies to memory rows exactly like other kinds | 007/008 |
| systematic-debugging's fix-and-regression-test contract is unchanged even when memory is written | 015/016 |
| kind=memory rows are restricted to active and expired statuses, enforced by the script | 003/004 |

## Dependency Chain

```
task-001 (test: kind vocab)
    │
    └─→ task-002 (impl: kind vocab)
            │
            ├─→ task-003 (test: status+category) ────────────┐
            │       └─→ task-004 (impl: status+category) ──┐ │ (file-conflict
            │                                                │ │  guard edge)
            └─→ task-005 (test: scan+rebuild) ◄──────────────┘─┘
                    └─→ task-006 (impl: scan+rebuild) ◄── task-004 (file-conflict guard edge)
                            │
                            ▼
                (both 004 and 006 feed into)
                                                               ▼
                                                   task-007 (test: collapse+archive)
                                                               │
                                                               ▼
                                                   task-008 (impl: collapse+archive)
                                                               │
        ┌──────────────────────────────────────────────────────┴──────────────┐
        ▼                                                                     │
  task-009 (test, brainstorming) ──────────────────────────────────────┐      │
        │                                                              │      │
        ▼ (impl, independent file)          (file-conflict guard edge) ▼      │
  task-010 (impl)                     task-011 (test, writing-plans) ◄─┘      │
                                              │                                │
                                              ▼ (impl, independent file)      │
                                        task-012 (impl)                        │
                                              │ (file-conflict guard edge)    │
                                              ▼                               │
                                     task-013 (test, executing-plans)          │
                                              │                                │
                                              ▼ (impl, independent file)      │
                                        task-014 (impl)                        │
                                              │ (file-conflict guard edge)    │
                                              ▼                               │
                                     task-015 (test, sys-debugging)            │
                                              │                                │
                                              ▼ (impl, independent file)      │
                                        task-016 (impl)                        │
                                              │ (file-conflict guard edge)    │
                                              ▼                               │
                                     task-017 (test, retrospective)            │
                                              │                                │
                                              ▼ (impl, independent file)      │
                                        task-018 (impl)                        │
        └──────────────────────────────────────────────────────┬─────────────┘
                                                                 ▼
                                                task-019 (config: version bump + marketplace sync)
                                                                 │
                                                                 ▼
                                                task-020 (docs: README memory-layer bullets)
```

(The ASCII above prioritizes readability of the file-conflict guard edges over strict box-drawing precision; the authoritative edge list is the YAML `tasks:` block above, cross-verified by the plan's Dependency Graph reflection pass — see "Analysis" below.)

**Analysis**:
- No circular dependencies (verified by the Phase 4 Dependency Graph Review sub-agent's DFS over the real edge list).
- Foundation (001-008) is a linear+diamond chain with two **file-conflict guard edges** added during Phase 4 reflection: 005 additionally depends on 003 (both write to `tests/run-docs-index-tests.sh`), and 006 additionally depends on 004 (both write to `lib/docs-index.sh`). Without these edges, 003/005 and 004/006 would be schedulable in the same parallel batch and race on the same file. 007 still re-joins both forks (`depends-on: 004, 006`) before 008 completes the foundation.
- Once 008 lands, the 5 skill-touchpoint **impl** tasks (010, 012, 014, 016, 018) remain independent of each other — each edits a distinct `SKILL.md` file, confirmed safe for a wide parallel batch by the Phase 4 File Conflict Review.
- The 5 skill-touchpoint **test** tasks (009, 011, 013, 015, 017) are NOT independent of each other, despite all originally depending only on 008: all five append new blocks to the same shared file, `tests/test-skill-touchpoints.sh`. Phase 4 reflection added 4 file-conflict guard edges chaining them (011→009, 013→011, 015→013, 017→015) so at most one writer touches that file at a time. Each impl task still depends only on its own paired test task (010→009, 012→011, 014→013, 016→015, 018→017), so the impl side keeps its parallelism — the pipeline staggers (each impl becomes available as soon as its own test lands, not only after the full test chain completes), it does not fully serialize.
- 019 (version bump) is the single join point requiring all 5 touchpoint pairs complete — a version bump before any skill touchpoint lands would misrepresent the shipped feature set.
- 020 (README) is strictly last — it documents the version that 019 just set.

---

## Execution Handoff

**Plan complete and saved to `docs/plans/2026-07-04-superpowers-memory-layer-plan/`. Load `superpowers:executing-plans` skill using the Skill tool — it orchestrates per-batch sub-agent coordinators through the full Phase 1-6 pipeline.**
