# Unified Retro Events Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Load `superpowers:executing-plans` skill using the Skill tool to implement this plan task-by-task.

**Goal:** Promote three retro NDJSON channels (`harness-observations.jsonl`, `evolution-log.jsonl`, `skill-events.jsonl`) into one shared helper layer mirroring `lib/bail-log.sh`, migrate the two existing inline-bash emission points in `retrospective` SKILL.md, and add the one new emission point in `systematic-debugging` Phase 4 — all byte-equivalent to today's on-disk output.

**Architecture:** Four new `superpowers/lib/*.sh` files behind one shared core (`retro-events.sh`) sourced by three wrappers (`observations.sh`, `evolution-log.sh`, `skill-events.sh`). Each wrapper is sourceable and executable, mirrors `bail-log.sh`'s best-effort contract, and produces NDJSON rows that the unchanged `retrospective` Phase 1 readers parse identically to the legacy inline `bash` blocks. SKILL.md emission points swap one-by-one with a migration-parity test as the gate.

**Tech Stack:** bash 3.2+, `jq`, `date -u`, `shasum`/`sha1sum` (optional), Python 3 + `unittest` for test harness, `tempfile.TemporaryDirectory` for hermetic project roots.

**Design Support:**
- [BDD Specs](../2026-05-12-unified-retro-events-design/bdd-specs.md)
- [Architecture](../2026-05-12-unified-retro-events-design/architecture.md)
- [Best Practices](../2026-05-12-unified-retro-events-design/best-practices.md)

## Context

The superpowers plugin writes four NDJSON `channel`s under `docs/retros/`. Two of the four (`harness-observations.jsonl`, `evolution-log.jsonl`) are still written by Claude-instructed inline `bash` blocks in `retrospective/SKILL.md` — boilerplate that has independently drifted in `jq` argument ordering and `mkdir -p` guards. `superpowers/TODO-v3.md` §T-002 declared the fix-now bar as "a third manual-write channel proposed"; this plan discharges that bar by adding `systematic-debugging` Phase 4's `fix_completed` `emission point` (the third channel) and promoting all three to a single `helper` layer in the same PR.

Separately, `systematic-debugging` is the only user-invocable `skill` producing no `retrospective`-visible signal of a successful fix outcome; the `retrospective` Phase 5a calibration loop currently sees only the bail rate, which by construction is the inverse of the success rate it should be measuring. The new `skill-events.jsonl` `channel` plus the Phase 4 `emission point` close that gap.

The `channel` files on disk are NOT unified — `retrospective` Phase 1 walks each `channel` with `channel`-specific aggregation logic, and merging would force a parallel rewrite of every reader for zero functional gain. The unification is strictly at the **write API layer**: one shared core with three thin wrappers, each producing the existing on-disk schema byte-for-byte.

| Aspect | Current State | Target State |
|--------|---------------|--------------|
| Write surface for `harness-observations.jsonl` | Claude-instructed inline `bash` in `retrospective/SKILL.md` Phase 5c | `bash "${CLAUDE_PLUGIN_ROOT}/lib/observations.sh" …` |
| Write surface for `evolution-log.jsonl` (`item_*` + `retrospective_run`) | Claude-instructed inline `bash` in `retrospective/SKILL.md` Phase 4 + Phase 6 | `bash "${CLAUDE_PLUGIN_ROOT}/lib/evolution-log.sh" …` |
| `systematic-debugging` Phase 4 success signal | None — only `bail_out` events visible | `bash "${CLAUDE_PLUGIN_ROOT}/lib/skill-events.sh" systematic-debugging fix_completed …` |
| `lib/` `helper` count for `channel` emission | 1 (`bail-log.sh`) + scattered inline blocks | 1 (`bail-log.sh`, unchanged) + 4 new files sharing `retro-events.sh` |
| `docs/retros/skill-events.jsonl` | Does not exist | Append-only NDJSON `channel`; one initial `(skill, event)` pair: `(systematic-debugging, fix_completed)` |
| Migration safety | Per-`emission point` schema is implicit in SKILL.md prose | Per-`emission point` migration parity test gates each SKILL.md swap |
| `retrospective` Phase 1 awareness of `skill-events.jsonl` | None | **(Deferred — see Known Gap below)** |

### Scope Discipline

This plan implements the **helper layer + the two SKILL.md migrations + the one new emission point**. It does NOT:

- Retrofit `lib/bail-log.sh` to source `retro-events.sh` (out of scope per design §"Out of Scope").
- Promote the rich-row producers in `executing-plans` Phase 3/4 and `brainstorming` Phase 2 (out of scope).
- Add a `cleared` marker row when Phase 5c closes a disable test (out of scope).
- Touch `lib/loop.sh` or `docs/retros/plans-completed.jsonl` (BC3 prohibits).

### Known Gap: F6 (retrospective Phase 1 surface of `skill-events.jsonl`)

The design's _index.md §F6 promises that `retrospective` Phase 1 will read `docs/retros/skill-events.jsonl` and surface aggregated counts in the Phase 6 report. **`bdd-specs.md` carries no matching scenario** — the file covers helper behavior, degradation, migration parity, Phase 4 emission, BC, and dedup, but not Phase 1 surface aggregation.

This plan declines to fabricate a scenario and **defers F6 to a follow-up plan**. The four new helpers + one new `(skill, event)` pair ship in this PR with the channel populated; the Phase 1 reader change is documented as a known follow-up. The reflection sub-agents should flag this as a coverage gap to surface to the user — the user can either accept the gap (defer F6) or reject the plan to send the design back for a BDD addition.

## Execution Plan

<!-- Inline task metadata for efficient execution by executing-plans skill -->
<!-- Format: YAML for easy parsing -->
<!-- slug: lowercase hyphenated version of subject, used for filename derivation -->
<!-- NN prefix is shared between paired test/impl tasks per writing-plans/SKILL.md -->

```yaml
tasks:
  - id: "001"
    subject: "Test fixtures and scaffolding"
    slug: "test-fixtures-scaffolding"
    type: "setup"
    depends-on: []
  - id: "002-test"
    subject: "observations.sh helper test (Red)"
    slug: "observations-test"
    type: "test"
    depends-on: []
  - id: "002-impl"
    subject: "observations.sh + retro-events.sh primitives impl (Green)"
    slug: "observations-impl"
    type: "impl"
    depends-on: ["002-test"]
  - id: "003-test"
    subject: "evolution-log.sh helper test (Red)"
    slug: "evolution-log-test"
    type: "test"
    depends-on: []
  - id: "003-impl"
    subject: "evolution-log.sh helper impl (Green)"
    slug: "evolution-log-impl"
    type: "impl"
    depends-on: ["003-test", "002-impl"]
  - id: "004-test"
    subject: "skill-events.sh helper test (Red)"
    slug: "skill-events-test"
    type: "test"
    depends-on: []
  - id: "004-impl"
    subject: "skill-events.sh helper impl (Green)"
    slug: "skill-events-impl"
    type: "impl"
    depends-on: ["004-test", "002-impl"]
  - id: "005-test"
    subject: "shared-core single-source test (Red)"
    slug: "shared-core-single-source-test"
    type: "test"
    depends-on: ["002-impl", "003-impl", "004-impl"]
  - id: "005-impl"
    subject: "shared-core single-source impl (Green)"
    slug: "shared-core-single-source-impl"
    type: "impl"
    depends-on: ["005-test"]
  - id: "006-test"
    subject: "Migration parity test (Red)"
    slug: "migration-parity-test"
    type: "test"
    depends-on: ["001", "002-impl", "003-impl"]
  - id: "006-impl"
    subject: "Migration parity impl (Green)"
    slug: "migration-parity-impl"
    type: "impl"
    depends-on: ["006-test"]
  - id: "007"
    subject: "Phase 5c SKILL.md migration to observations.sh"
    slug: "phase-5c-skill-md-migration"
    type: "refactor"
    depends-on: ["006-impl"]
  - id: "008"
    subject: "Phase 4 + Phase 6 SKILL.md migration to evolution-log.sh"
    slug: "phase-4-6-skill-md-migration"
    type: "refactor"
    depends-on: ["006-impl"]
  - id: "009-test"
    subject: "systematic-debugging Phase 4 emission test (Red)"
    slug: "phase-4-emission-test"
    type: "test"
    depends-on: ["004-impl"]
  - id: "009-impl"
    subject: "systematic-debugging Phase 4 emission impl (Green)"
    slug: "phase-4-emission-impl"
    type: "impl"
    depends-on: ["009-test"]
```

**Task File References (for detailed BDD scenarios):**

- [Task 001: Test fixtures and scaffolding](./task-001-test-fixtures-scaffolding.md)
- [Task 002-test: observations.sh helper test](./task-002-observations-test.md)
- [Task 002-impl: observations.sh + retro-events.sh primitives impl](./task-002-observations-impl.md)
- [Task 003-test: evolution-log.sh helper test](./task-003-evolution-log-test.md)
- [Task 003-impl: evolution-log.sh helper impl](./task-003-evolution-log-impl.md)
- [Task 004-test: skill-events.sh helper test](./task-004-skill-events-test.md)
- [Task 004-impl: skill-events.sh helper impl](./task-004-skill-events-impl.md)
- [Task 005-test: shared-core single-source test](./task-005-shared-core-single-source-test.md)
- [Task 005-impl: shared-core single-source impl](./task-005-shared-core-single-source-impl.md)
- [Task 006-test: Migration parity test](./task-006-migration-parity-test.md)
- [Task 006-impl: Migration parity impl](./task-006-migration-parity-impl.md)
- [Task 007: Phase 5c SKILL.md migration to observations.sh](./task-007-phase-5c-skill-md-migration.md)
- [Task 008: Phase 4 + Phase 6 SKILL.md migration to evolution-log.sh](./task-008-phase-4-6-skill-md-migration.md)
- [Task 009-test: systematic-debugging Phase 4 emission test](./task-009-phase-4-emission-test.md)
- [Task 009-impl: systematic-debugging Phase 4 emission impl](./task-009-phase-4-emission-impl.md)

## BDD Coverage

`bdd-specs.md` carries 23 `Scenario:` headings across §1–§6. Coverage matrix:

| `bdd-specs.md` scenario | Covered by task |
|---|---|
| §1.1 — `log_skill_event` writes `fix_completed` from systematic-debugging Phase 4 (helper-level) | 004-test / 004-impl |
| §1.2 — helper invoked in Executed mode writes the same record as Sourced mode | 004-test / 004-impl (and mirrored in 002-test, 003-test for the other wrappers) |
| §1.3 — `log_harness_observation` matches legacy Phase 5c bash block | 002-test / 002-impl |
| §1.4 — `log_evolution_event` mirrors legacy `retrospective_run` schema verbatim | 003-test / 003-impl |
| §1.5 — three channel helpers source `retro-events.sh` which sources `utils.sh` exactly once | 005-test / 005-impl |
| §2.1 — `jq` absent from PATH | 002-test, 003-test, 004-test (Degradation TestCase per wrapper) |
| §2.2 — both `shasum` and `sha1sum` absent | 004-test (only skill-events.sh hashes args; observations/evolution do not) |
| §2.3 — `docs/retros` read-only | 002-test, 003-test, 004-test |
| §2.4 — `repo_root` resolution fails | 002-test, 003-test, 004-test |
| §2.5 — `date` command fails | 002-test, 003-test, 004-test |
| §3.1 — Phase 5c legacy bash vs `log_harness_observation` produce identical rows | 006-test / 006-impl |
| §3.2 — Phase 6 closure legacy bash vs `log_evolution_event` produce identical rows | 006-test / 006-impl |
| §3.3 — retrospective Phase 1 consumer parses old and new rows identically | 006-test / 006-impl |
| §4.1 — Phase 4 emits `fix_completed` after root cause confirmed and regression test passes | 009-test / 009-impl |
| §4.2 — Bail-out path does not emit `fix_completed` event | 009-test / 009-impl |
| §4.3 — `skill_name` is read from session state file, not hardcoded | 009-test / 009-impl |
| §4.4 — Architecture-questioning branch (≥3 failed fixes) does not emit `fix_completed` | 009-test / 009-impl |
| §5.1 — existing `plans-completed.jsonl` rows are not rewritten | 006-test / 006-impl (cross-cutting assertion in parity test) |
| §5.2 — existing `harness-observations.jsonl` rows are not rewritten | 002-test / 002-impl |
| §5.3 — existing `evolution-log.jsonl` rows are not rewritten | 003-test / 003-impl |
| §5.4 — retrospective Phase 1 step 2 evaluation glob behavior is unchanged | 007 / 008 (verified via existing `tests/test_phase_integration.py`) |
| §6.1 — a single systematic-debugging invocation emits `fix_completed` only once | 009-test / 009-impl |
| §6.2 — cross-session dedup is intentionally absent | 009-test / 009-impl |

**Coverage: 23 / 23 scenarios mapped to tasks.**

**Known gap not covered by `bdd-specs.md`:** F6 (retrospective Phase 1 surface of `skill-events.jsonl`). See "Known Gap" subsection above. No task in this plan implements F6; if the user wants F6 in this PR, the plan must be rejected and a BDD scenario added to `bdd-specs.md` first.

## Dependency Chain

Verified by Phase 4 reflection sub-agent 2 (general-purpose). The graph is **acyclic**; all 15 nodes admit a valid topological order; all `depends-on` references resolve to existing task files.

```
001 (foundation: test fixtures + scaffolding)
 │
 ├─→ 006-test ──→ 006-impl ──┬─→ 007  (Phase 5c SKILL.md refactor)
 │                            └─→ 008  (Phase 4+6 SKILL.md refactor)
 │
 │
002-test ──→ 002-impl ──┬─→ 003-impl
 │            (lands     │
 │           retro-      ├─→ 004-impl
 │           events.sh)  │
 │                       ├─→ 005-test (also needs 003-impl, 004-impl)
 │                       │
 │                       └─→ 006-test (also needs 001, 003-impl)
 │
003-test ──→ 003-impl ──┬─→ 005-test
                         └─→ 006-test
 │
004-test ──→ 004-impl ──┬─→ 005-test
                         └─→ 009-test ──→ 009-impl
 │
005-test ──→ 005-impl
```

**Adjacency table (task → prerequisites):**

| Task | depends-on |
|---|---|
| 001 | _(none — foundation)_ |
| 002-test | _(none)_ |
| 002-impl | 002-test |
| 003-test | _(none)_ |
| 003-impl | 003-test, 002-impl |
| 004-test | _(none)_ |
| 004-impl | 004-test, 002-impl |
| 005-test | 002-impl, 003-impl, 004-impl |
| 005-impl | 005-test |
| 006-test | 001, 002-impl, 003-impl |
| 006-impl | 006-test |
| 007 | 006-impl |
| 008 | 006-impl |
| 009-test | 004-impl |
| 009-impl | 009-test |

**Analysis (verified by reflection):**
- **No circular dependencies** — DFS over the 15-node graph completed cleanly; valid topological order found.
- **No unresolved references** — every `depends-on` ID maps to an existing `task-*.md` file.
- **Red-Green pairing intact**: every `impl` task depends on its paired `test` task (002, 003, 004, 005, 006, 009).
- **Foundation (001)** is consumed only by 006-test; the wrapper feature pairs (002, 003, 004) are independent of 001.
- **The three wrapper feature pairs (002, 003, 004) are independent at the test layer.** The impl layer has a fan-in: 003-impl and 004-impl depend on 002-impl because 002-impl is what lands `retro-events.sh` (the shared core).
- **005 (shared-core single-source)** depends on all three wrapper impls because the test sources all three to verify single-source semantics (§1.5).
- **006 (migration parity)** is the gate for 007 and 008 (SKILL.md refactors) — those refactors are forbidden until parity is green. The 007/008 tasks carry explicit "test covered by task-006" justifications (satisfying TEST-01).
- **009 (Phase 4 emission)** needs only 004-impl (skill-events.sh) and is independent of the migrations (007/008). It can execute in parallel with the 007/008 critical path.
- **Parallel opportunities**: 001, 002-test, 003-test, 004-test all start at depth 0 with no dependencies — four parallel entry points. After 002-impl lands, 003-impl/004-impl/006-test fan out in parallel.

---

## Execution Handoff

**"Plan complete and saved to `docs/plans/2026-05-12-unified-retro-events-plan/`. Load `superpowers:executing-plans` skill using the Skill tool — it orchestrates per-batch sub-agent coordinators through the full Phase 1-6 pipeline."**
