# Docs Index Convention Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Load `superpowers:executing-plans` skill using the Skill tool to implement this plan task-by-task.

**Goal:** Implement a shared `lib/docs-index.sh` leaf script that maintains a top-level `docs/README.md` pipe-delimited index, plus inject consult-before / upsert-after (and, for retrospective, invalidate-after) touchpoints into the four in-scope superpowers skills.

**Architecture:** A single executed-only bash leaf script (`lib/docs-index.sh`, `set -euo pipefail`, sourcing `lib/utils.sh` for `repo_root`) writes a single markdown table at `docs/README.md`. Five subcommands (`list`, `show`, `upsert`, `set-status`, `rebuild`) enforce a controlled vocabulary for `kind` and `status`. Atomic writes via temp-file + `mv`. Four skills gain two standard touchpoints each (consult-before in Initialization, upsert-after in the commit phase); retrospective gains a third (invalidate-after in Phase 6). No hooks, no JSON, no per-skill duplication.

**Tech Stack:** Bash (leaf script, `set -euo pipefail`), `awk`/`grep` for parsing (no `jq` dependency), markdown pipe-table output. Tests via `bats` (bash testing) OR a plain bash test runner — see task-001 for the harness decision.

**Design Support:**
- [BDD Specs](../2026-07-04-docs-index-design/bdd-specs.md)
- [Architecture](../2026-07-04-docs-index-design/architecture.md)
- [Best Practices](../2026-07-04-docs-index-design/best-practices.md)

## Context

The superpowers plugin (v3.5.0) has four skills that write into `docs/` — `brainstorming`, `writing-plans`, `executing-plans`, `retrospective` — with no top-level map of what design/plan/retro artifacts exist or which are still authoritative. A skill starting work on a topic has no way to discover that a prior design was already invalidated by a retrospective, so it may re-extend stale conclusions. The design (commit `c848b9e`, evaluator PASS) specifies a shared `lib/docs-index.sh` + a `docs/README.md` pipe table + a controlled-vocabulary status taxonomy (`wip`, `active`, `implemented:<sha>`, `superseded-by:<path>`, `expired:<reason>`, `reference`) + an explicit `invalidates: <path>` trigger boundary for retrospective expiry.

This is greenfield work — `docs/README.md` does not exist yet, and `lib/docs-index.sh` does not exist yet. The only existing infrastructure is `lib/utils.sh::repo_root` (resolution order: `CLAUDE_PROJECT_DIR` → `git rev-parse --show-toplevel` → `$PWD`), which the new script will source.

| Aspect | Current State | Target State |
|--------|--------------|--------------|
| Docs map | None — `docs/` has only `docs/writing-skills/` | `docs/README.md` pipe table, one row per folder, ≤60 lines |
| Index script | None | `lib/docs-index.sh` with 5 subcommands, exit codes `0/1/2/3` |
| Skill consult-before | Skills read only `CLAUDE.md`/`README.md` | Each of 4 skills runs `docs-index.sh list`/`show` in Initialization |
| Skill upsert-after | Skills commit artifacts only | Each of 4 skills upserts/sets-status in the commit phase, same turn |
| Retro invalidation | Retro evolves checklists only | Retro reads `invalidates:` lines from its own report and flips prior entries to `expired:<reason>` |
| Status vocabulary | None | 6 controlled values, transition matrix enforced by `set-status` |

## Global Constraints

- **Bash version**: POSIX-compatible bash 3.2+ (macOS default). No bash 4+ associative arrays. Use `awk` for table parsing.
- **No `jq` dependency**: the script parses pipe-delimited markdown with `awk`/`grep` only. The plugin degrades gracefully when `jq` is absent; the index must not reintroduce a hard `jq` dependency.
- **No network**: `lib/docs-index.sh` reads/writes only within `${repo_root}/docs/`. No `curl`/`wget`. Safe under the plugin's Bash() scoped-tool model.
- **Atomic writes**: all writes go to `docs/README.md.tmp.$$` then `mv` over the target. A crash mid-write leaves either the old or the new file, never a torn half-table.
- **Path validation**: `<path>` args are repo-relative, must not start with `/` and must not contain `..` (no traversal outside `docs/`).
- **Controlled vocabulary**: `kind ∈ {design, plan, retro}`; `status ∈ {wip, active, implemented:<7-hex>, superseded-by:<path>, expired:<reason>, reference}`. Unknown values exit 2, write nothing.
- **Exit code convention** (mirrors `lib/seed-checklists.sh`): `0` success / `1` internal failure / `2` usage error / `3` "not in index — caller treats as success".
- **No `--amend`**: executing-plans' `set-status implemented:<sha>` uses a dedicated tiny index commit, never `--amend` (which would confuse the Stop hook's `completion_commit` detection).
- **No emojis**: per user global CLAUDE.md — no emojis in script output, error messages, or docs.
- **2-space indentation**: per Biome/project style for any non-bash files touched (the skill `.md` edits).

## Execution Plan

```yaml
tasks:
  - id: "001"
    subject: "Setup: script skeleton, test harness, repo_root sourcing"
    slug: "setup-skeleton"
    type: "setup"
    depends-on: []
  - id: "002"
    subject: "list subcommand test"
    slug: "list-test"
    type: "test"
    depends-on: ["001"]
  - id: "003"
    subject: "list subcommand impl"
    slug: "list-impl"
    type: "impl"
    depends-on: ["002"]
  - id: "004"
    subject: "show subcommand test"
    slug: "show-test"
    type: "test"
    depends-on: ["001"]
  - id: "005"
    subject: "show subcommand impl"
    slug: "show-impl"
    type: "impl"
    depends-on: ["004"]
  - id: "006"
    subject: "upsert subcommand test (cold start, idempotent, vocab)"
    slug: "upsert-test"
    type: "test"
    depends-on: ["001"]
  - id: "007"
    subject: "upsert subcommand impl"
    slug: "upsert-impl"
    type: "impl"
    depends-on: ["006"]
  - id: "008"
    subject: "set-status subcommand test (transition matrix, rework)"
    slug: "set-status-test"
    type: "test"
    depends-on: ["007"]
  - id: "009"
    subject: "set-status subcommand impl"
    slug: "set-status-impl"
    type: "impl"
    depends-on: ["008"]
  - id: "010"
    subject: "rebuild subcommand test (collapse rule, reference seed)"
    slug: "rebuild-test"
    type: "test"
    depends-on: ["007"]
  - id: "011"
    subject: "rebuild subcommand impl"
    slug: "rebuild-impl"
    type: "impl"
    depends-on: ["010"]
  - id: "012"
    subject: "malformed-index + path-validation test"
    slug: "edge-cases-test"
    type: "test"
    depends-on: ["007"]
  - id: "013"
    subject: "malformed-index + path-validation impl"
    slug: "edge-cases-impl"
    type: "impl"
    depends-on: ["012"]
  - id: "014"
    subject: "brainstorming touchpoints test"
    slug: "brainstorming-touchpoints-test"
    type: "test"
    depends-on: ["007"]
  - id: "015"
    subject: "brainstorming touchpoints impl"
    slug: "brainstorming-touchpoints-impl"
    type: "impl"
    depends-on: ["014"]
  - id: "016"
    subject: "writing-plans touchpoints test"
    slug: "writing-plans-touchpoints-test"
    type: "test"
    depends-on: ["007"]
  - id: "017"
    subject: "writing-plans touchpoints impl"
    slug: "writing-plans-touchpoints-impl"
    type: "impl"
    depends-on: ["016"]
  - id: "018"
    subject: "executing-plans touchpoints test (implemented:<sha> flip)"
    slug: "executing-plans-touchpoints-test"
    type: "test"
    depends-on: ["009"]
  - id: "019"
    subject: "executing-plans touchpoints impl"
    slug: "executing-plans-touchpoints-impl"
    type: "impl"
    depends-on: ["018"]
  - id: "020"
    subject: "retrospective touchpoints test (invalidates: boundary)"
    slug: "retrospective-touchpoints-test"
    type: "test"
    depends-on: ["009"]
  - id: "021"
    subject: "retrospective touchpoints impl"
    slug: "retrospective-touchpoints-impl"
    type: "impl"
    depends-on: ["020"]
  - id: "022"
    subject: "docs/README.md seed + docs/writing-skills reference entry"
    slug: "seed-index"
    type: "impl"
    depends-on: ["011"]
```

**Task File References (for detailed BDD scenarios):**
- [Task 001: Setup skeleton](./task-001-setup-skeleton.md)
- [Task 002: list subcommand test](./task-002-list-test.md)
- [Task 003: list subcommand impl](./task-003-list-impl.md)
- [Task 004: show subcommand test](./task-004-show-test.md)
- [Task 005: show subcommand impl](./task-005-show-impl.md)
- [Task 006: upsert subcommand test](./task-006-upsert-test.md)
- [Task 007: upsert subcommand impl](./task-007-upsert-impl.md)
- [Task 008: set-status subcommand test](./task-008-set-status-test.md)
- [Task 009: set-status subcommand impl](./task-009-set-status-impl.md)
- [Task 010: rebuild subcommand test](./task-010-rebuild-test.md)
- [Task 011: rebuild subcommand impl](./task-011-rebuild-impl.md)
- [Task 012: edge cases test](./task-012-edge-cases-test.md)
- [Task 013: edge cases impl](./task-013-edge-cases-impl.md)
- [Task 014: brainstorming touchpoints test](./task-014-brainstorming-touchpoints-test.md)
- [Task 015: brainstorming touchpoints impl](./task-015-brainstorming-touchpoints-impl.md)
- [Task 016: writing-plans touchpoints test](./task-016-writing-plans-touchpoints-test.md)
- [Task 017: writing-plans touchpoints impl](./task-017-writing-plans-touchpoints-impl.md)
- [Task 018: executing-plans touchpoints test](./task-018-executing-plans-touchpoints-test.md)
- [Task 019: executing-plans touchpoints impl](./task-019-executing-plans-touchpoints-impl.md)
- [Task 020: retrospective touchpoints test](./task-020-retrospective-touchpoints-test.md)
- [Task 021: retrospective touchpoints impl](./task-021-retrospective-touchpoints-impl.md)
- [Task 022: seed docs/README.md + reference entry](./task-022-seed-index.md)

## BDD Coverage

All 22 BDD scenarios from `../2026-07-04-docs-index-design/bdd-specs.md` are covered. Scenario-to-task mapping:

| BDD Scenario | Task(s) |
|---|---|
| 1. Cold start — first design creates the index | 006, 007 (upsert creates `docs/README.md`) |
| 2. Consult-before — prior active design superseded | 014, 015 (brainstorming touchpoints) |
| 3. Consult-before — prior expired not trusted | 014, 015 |
| 4. Upsert-after — writing-plans records a plan | 016, 017 |
| 5. writing-plans refuses an expired design | 016, 017 |
| 6. executing-plans marks plan implemented | 018, 019 |
| 7. Retrospective invalidates a design + records report | 020, 021 |
| 8. Retrospective preserves implemented plan history | 020, 021 |
| 9. Index stays compact — one row per folder | 010, 011 (rebuild collapse rule) |
| 10. Reference entry never expires | 010, 011 (reference stickiness); 022 (seed) |
| 11. Idempotent upsert | 006, 007 |
| 12. Unknown status rejected (Scenario Outline) | 006, 007 |
| 13. Unknown kind rejected (Scenario Outline) | 006, 007 |
| 14. Malformed index degrades gracefully | 012, 013 |
| 15. Same-day folder-name collision | 014, 015 (brainstorming disambiguation) |
| 16. Rework after ship (implemented → wip) | 018, 019 |
| 17. Not-in-index exits 3 (recoverable) | 004, 005 (show); 008, 009 (set-status) |
| 18. Every mutating skill consults before mutating | 014-021 (all touchpoint tasks) |
| 19. Allowed status transitions (Scenario Outline) | 008, 009 |
| 20. Rejected transition exits non-zero | 008, 009 |
| 21. REMOVE proposal does not invalidate | 020, 021 (invalidation boundary) |
| 22. Invalidation requires tracked path | 020, 021 |

## Dependency Chain

```
task-001 (setup skeleton + test harness)
    │
    ├─→ task-002 (list test) ─→ task-003 (list impl)
    │
    ├─→ task-004 (show test) ─→ task-005 (show impl)
    │
    ├─→ task-006 (upsert test) ─→ task-007 (upsert impl)
    │                              │
    │                              ├─→ task-008 (set-status test) ─→ task-009 (set-status impl)
    │                              │
    │                              ├─→ task-010 (rebuild test) ─→ task-011 (rebuild impl) ─→ task-022 (seed)
    │                              │
    │                              ├─→ task-012 (edge cases test) ─→ task-013 (edge cases impl)
    │                              │
    │                              ├─→ task-014 (brainstorming test) ─→ task-015 (brainstorming impl)
    │                              │
    │                              ├─→ task-016 (writing-plans test) ─→ task-017 (writing-plans impl)
    │                              │
    │                              └─→ (task-018 depends on 009)
    │
    └─→ task-018 (executing-plans test, depends on 009) ─→ task-019 (executing-plans impl)
    └─→ task-020 (retrospective test, depends on 009) ─→ task-021 (retrospective impl)
```

**Analysis**:
- No circular dependencies (foundation → subcommands → touchpoints; touchpoints depend on subcommand impls, never reverse).
- Logical dependency flow: setup skeleton → 5 subcommands (parallelizable after 007) → 4 skill touchpoints (parallelizable) → seed.
- Parallel paths: after task-007 (upsert impl) lands, tasks 008/010/012/014/016 can proceed in parallel; tasks 018/020 proceed after 009 lands. task-022 proceeds after 011.
- Test-before-impl (RED→GREEN) enforced per pair via `depends-on`.

---

## Execution Handoff

**Plan complete and saved to `docs/plans/2026-07-04-docs-index-plan/`. Load `superpowers:executing-plans` skill using the Skill tool — it orchestrates per-batch sub-agent coordinators through the full Phase 1-6 pipeline.**
