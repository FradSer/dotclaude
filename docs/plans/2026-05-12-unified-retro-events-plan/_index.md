# Unified Retrospective Event Helpers — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Load `superpowers:executing-plans` skill using the Skill tool to implement this plan task-by-task.

**Goal:** Ship `lib/retro-events.sh` shared core + three wrapper `helper`s (`lib/observations.sh`, `lib/evolution-log.sh`, `lib/skill-events.sh`), migrate the two manual-write `channel`s (`harness-observations.jsonl`, `evolution-log.jsonl`) off inline `jq -nc` blocks in `retrospective/SKILL.md`, and add one new `emission point` in `systematic-debugging` Phase 4 step 3 success branch that writes `fix_completed` to the new `skill-events.jsonl` `channel`. All four `helper`s mirror `lib/bail-log.sh`'s shipped contract (sourceable + executable, best-effort throughout, no top-level `set -e`).

**Architecture:** Symmetry with `bail-log.sh` is the load-bearing property. The wrapper `helper`s each source `retro-events.sh` (which sources `utils.sh` exactly once via `_SUPERPOWERS_DEPS_CHECKED`). The shared core exposes six primitives (`jq_or_skip`, `timestamp_or_skip`, `ensure_log_dir`, `repo_root_or_skip`, `write_jsonl`, `dedup_check`); each wrapper composes its `event_type` envelope with the caller's payload filter using jq's `+` operator (preserves declaration-order serialization → byte-parity with the legacy inline blocks under deterministic timestamp substitution).

**Tech Stack:** bash 3.x+, `jq`, `date -u`, optionally `shasum`/`sha1sum`; Python 3 + `unittest` + `pytest` for tests (mirror of `tests/test_bail_log_sh.py` structure).

**Design Support:**
- [BDD Specs](../2026-05-12-unified-retro-events-design/bdd-specs.md)
- [Architecture](../2026-05-12-unified-retro-events-design/architecture.md)
- [Best Practices](../2026-05-12-unified-retro-events-design/best-practices.md)
- [Design Index](../2026-05-12-unified-retro-events-design/_index.md)

## Context

Two retrospective `channel`s (`harness-observations.jsonl`, `evolution-log.jsonl`) are currently written by Claude-instructed inline `jq -nc … >> file` `bash` blocks inside `skills/retrospective/SKILL.md`. The other two (`plans-completed.jsonl`, `bail-out-events.jsonl`) already route through shipped `helper` functions with parity tests. `superpowers/TODO-v3.md` T-002 declared the fix-now bar as "a third manual-write channel is proposed". The new `systematic-debugging` `fix_completed` `emission point` is that third channel. Shipping the three together (one shared core + three thin wrappers) discharges T-002 and stops the boilerplate from being replicated a fourth time.

This plan is BDD-driven: every test/impl pair maps to one or more Gherkin scenarios from `bdd-specs.md`. Test-first (Red) tasks precede every implementation (Green) task via `depends-on`.

### Current State vs Target State

| Aspect | Current State | Target State |
|---|---|---|
| `harness-observations.jsonl` write path | Claude-instructed inline `jq -nc … >> docs/retros/harness-observations.jsonl` block in `retrospective/SKILL.md` Phase 5c | `bash "${CLAUDE_PLUGIN_ROOT}/lib/observations.sh" <event> <payload_filter> [args]` |
| `evolution-log.jsonl` Phase 4 item events | Inline `jq -nc … >> docs/retros/evolution-log.jsonl` block per approved proposal | `bash "${CLAUDE_PLUGIN_ROOT}/lib/evolution-log.sh" item_<add\|remove\|modify\|promote> '<filter>' [args]` |
| `evolution-log.jsonl` Phase 6 `retrospective_run` + `component_reinstated` | Inline `jq -nc … >> docs/retros/evolution-log.jsonl` blocks at the closure step | `bash "${CLAUDE_PLUGIN_ROOT}/lib/evolution-log.sh" retrospective_run '<filter>' [args]` (with conditional `post_plan_diff` filter) |
| `systematic-debugging` Phase 4 success outcome visibility | No `event` emitted; only the `bail_out` event from the top-of-skill gate is captured (inverse of success rate) | `bash "${CLAUDE_PLUGIN_ROOT}/lib/skill-events.sh" "$SKILL_NAME" fix_completed '<filter>' [args]` from Phase 4 step 3 success branch |
| `retrospective` Phase 1 visibility into skill-events | None — no awareness of `skill-events.jsonl` | New surface-only sub-step aggregates `(skill, event)` counts, renders in Phase 6 report under "Skill Event Activity"; does NOT enter DUE or EVO thresholds |
| `allowed-tools` arrays | `retrospective/SKILL.md`: no observations/evolution-log entries. `systematic-debugging/SKILL.md`: no skill-events entry. | Each migrated/new invocation has an explicit `Bash(${CLAUDE_PLUGIN_ROOT}/lib/<helper>.sh:*)` entry |
| `superpowers` plugin version | `v2.8.0` (current) | `v2.9.0` (this PR's release) |

### Known Design Conflict (To Resolve Before Implementation)

`architecture.md` §"Integration Points → systematic-debugging SKILL.md Phase 4" includes the sentence:

> The bail-out path MUST emit `fix_completed` with `investigation_phase_count = 1` — this is the only way the calibration loop sees whether bail-outs are landing successful fixes.

`bdd-specs.md` §4 Scenario "Bail-out path does not emit a fix_completed event" says the **opposite** — the bail-out path must NOT emit.

**Resolution path adopted by this plan**: per the writing-plans skill mandate ("Tasks must be driven by BDD scenarios"), this plan FOLLOWS BDD: **the bail-out path does NOT emit `fix_completed`**. Task 009 encodes that contract. The maintainer should re-open the design folder before this plan executes (a brainstorming follow-up) and either reconcile architecture.md to BDD or update BDD to match architecture's design intent. If reconciliation produces a different decision, Task 009 needs amending before it ships.

## Execution Plan

<!-- Inline task metadata for efficient execution by executing-plans skill -->
```yaml
tasks:
  - id: "001"
    subject: "Setup test fixtures and scaffolding"
    slug: "setup-fixtures"
    type: "setup"
    depends-on: []
  - id: "002-test"
    subject: "retro-events.sh shared core — tests"
    slug: "retro-events-test"
    type: "test"
    depends-on: ["001"]
  - id: "002-impl"
    subject: "retro-events.sh shared core — implementation"
    slug: "retro-events-impl"
    type: "impl"
    depends-on: ["002-test"]
  - id: "003-test"
    subject: "skill-events.sh wrapper — tests"
    slug: "skill-events-test"
    type: "test"
    depends-on: ["002-impl"]
  - id: "003-impl"
    subject: "skill-events.sh wrapper — implementation"
    slug: "skill-events-impl"
    type: "impl"
    depends-on: ["003-test"]
  - id: "004-test"
    subject: "observations.sh wrapper — tests"
    slug: "observations-test"
    type: "test"
    depends-on: ["002-impl", "001"]
  - id: "004-impl"
    subject: "observations.sh wrapper — implementation"
    slug: "observations-impl"
    type: "impl"
    depends-on: ["004-test"]
  - id: "005-test"
    subject: "evolution-log.sh wrapper — tests"
    slug: "evolution-log-test"
    type: "test"
    depends-on: ["002-impl", "001"]
  - id: "005-impl"
    subject: "evolution-log.sh wrapper — implementation"
    slug: "evolution-log-impl"
    type: "impl"
    depends-on: ["005-test"]
  - id: "006-test"
    subject: "Migrate retrospective Phase 5c — tests"
    slug: "migrate-phase5c-test"
    type: "test"
    depends-on: ["004-impl"]
  - id: "006-impl"
    subject: "Migrate retrospective Phase 5c — implementation"
    slug: "migrate-phase5c-impl"
    type: "impl"
    depends-on: ["006-test"]
  - id: "007-test"
    subject: "Migrate retrospective Phase 4 item events — tests"
    slug: "migrate-phase4-items-test"
    type: "test"
    depends-on: ["005-impl", "006-impl"]
  - id: "007-impl"
    subject: "Migrate retrospective Phase 4 item events — implementation"
    slug: "migrate-phase4-items-impl"
    type: "impl"
    depends-on: ["007-test"]
  - id: "008-test"
    subject: "Migrate retrospective Phase 6 closure — tests"
    slug: "migrate-phase6-closure-test"
    type: "test"
    depends-on: ["007-impl"]
  - id: "008-impl"
    subject: "Migrate retrospective Phase 6 closure — implementation"
    slug: "migrate-phase6-closure-impl"
    type: "impl"
    depends-on: ["008-test"]
  - id: "009-test"
    subject: "systematic-debugging Phase 4 fix_completed emission — tests"
    slug: "systematic-debugging-emission-test"
    type: "test"
    depends-on: ["003-impl"]
  - id: "009-impl"
    subject: "systematic-debugging Phase 4 fix_completed emission — implementation"
    slug: "systematic-debugging-emission-impl"
    type: "impl"
    depends-on: ["009-test"]
  - id: "010-test"
    subject: "retrospective Phase 1 skill-events reader — tests"
    slug: "phase1-reader-test"
    type: "test"
    depends-on: ["003-impl", "008-impl"]
  - id: "010-impl"
    subject: "retrospective Phase 1 skill-events reader — implementation"
    slug: "phase1-reader-impl"
    type: "impl"
    depends-on: ["010-test"]
  - id: "011"
    subject: "Update allowed-tools frontmatter in both SKILL.md files"
    slug: "allowed-tools-config"
    type: "config"
    depends-on: ["006-impl", "007-impl", "008-impl", "009-impl", "010-impl"]
  - id: "012"
    subject: "Discharge T-002, update README, bump version to v2.9.0"
    slug: "discharge-and-readme"
    type: "config"
    depends-on: ["011"]
```

**Task File References (for detailed BDD scenarios):**
- [Task 001: Setup test fixtures and scaffolding](./task-001-setup-fixtures.md)
- [Task 002-test: retro-events.sh shared core — tests](./task-002-retro-events-test.md)
- [Task 002-impl: retro-events.sh shared core — implementation](./task-002-retro-events-impl.md)
- [Task 003-test: skill-events.sh wrapper — tests](./task-003-skill-events-test.md)
- [Task 003-impl: skill-events.sh wrapper — implementation](./task-003-skill-events-impl.md)
- [Task 004-test: observations.sh wrapper — tests](./task-004-observations-test.md)
- [Task 004-impl: observations.sh wrapper — implementation](./task-004-observations-impl.md)
- [Task 005-test: evolution-log.sh wrapper — tests](./task-005-evolution-log-test.md)
- [Task 005-impl: evolution-log.sh wrapper — implementation](./task-005-evolution-log-impl.md)
- [Task 006-test: Migrate retrospective Phase 5c — tests](./task-006-migrate-phase5c-test.md)
- [Task 006-impl: Migrate retrospective Phase 5c — implementation](./task-006-migrate-phase5c-impl.md)
- [Task 007-test: Migrate retrospective Phase 4 item events — tests](./task-007-migrate-phase4-items-test.md)
- [Task 007-impl: Migrate retrospective Phase 4 item events — implementation](./task-007-migrate-phase4-items-impl.md)
- [Task 008-test: Migrate retrospective Phase 6 closure — tests](./task-008-migrate-phase6-closure-test.md)
- [Task 008-impl: Migrate retrospective Phase 6 closure — implementation](./task-008-migrate-phase6-closure-impl.md)
- [Task 009-test: systematic-debugging Phase 4 emission — tests](./task-009-systematic-debugging-emission-test.md)
- [Task 009-impl: systematic-debugging Phase 4 emission — implementation](./task-009-systematic-debugging-emission-impl.md)
- [Task 010-test: retrospective Phase 1 skill-events reader — tests](./task-010-phase1-reader-test.md)
- [Task 010-impl: retrospective Phase 1 skill-events reader — implementation](./task-010-phase1-reader-impl.md)
- [Task 011: Update allowed-tools frontmatter](./task-011-allowed-tools-config.md)
- [Task 012: Discharge T-002, update README, bump version](./task-012-discharge-and-readme.md)

## BDD Coverage

All 23 Gherkin scenarios from `bdd-specs.md` are covered by these tasks. Mapping:

| BDD Section | Scenario | Covering Task(s) |
|---|---|---|
| §1.1 | log_skill_event writes fix_completed | 003-test, 003-impl |
| §1.2 | Executed vs Sourced mode parity | 003-test, 003-impl |
| §1.3 | log_harness_observation parity with Phase 5c legacy bash | 004-test, 004-impl |
| §1.4 | log_evolution_event mirrors retrospective_run schema | 005-test, 005-impl |
| §1.5 | Three wrappers source retro-events.sh + utils.sh exactly once | 002-test, 002-impl |
| §2.1 | jq absent from PATH | 002-test (primitive), 003-test (wrapper) |
| §2.2 | shasum + sha1sum both absent | 003-test (skill-events is the only wrapper with args_hash) |
| §2.3 | docs/retros read-only filesystem | 002-test, 003-test, 004-test, 005-test |
| §2.4 | repo_root resolution fails | 002-test, 003-test, 004-test, 005-test |
| §2.5 | date command fails | 002-test, 003-test, 004-test, 005-test |
| §3.11 | Phase 5c legacy vs log_harness_observation parity | 001 (fixture), 004-test, 004-impl |
| §3.12 | Phase 6 closure legacy vs log_evolution_event parity | 001 (fixture), 005-test, 005-impl |
| §3.13 | Phase 1 consumer parses mixed stream identically | 005-test (EvolutionLogConsumerParityTests) |
| §4.1 | Phase 4 emits fix_completed on success | 009-test, 009-impl |
| §4.2 | Bail-out path does NOT emit fix_completed | 009-test, 009-impl |
| §4.3 | skill_name read from session state file | 009-test, 009-impl |
| §4.4 | Architecture-questioning branch does NOT emit | 009-test, 009-impl |
| §5.18 | plans-completed.jsonl rows not rewritten | 002-test (xfail), 003-test (re-verify) |
| §5.19 | harness-observations.jsonl rows not rewritten | 004-test, 006-test |
| §5.20 | evolution-log.jsonl rows not rewritten | 005-test, 007-test, 008-test |
| §5.21 | Phase 1 step 2 evaluation glob unchanged | 010-test |
| §6.22 | Single-session dedup of fix_completed | 003-test, 003-impl |
| §6.23 | Cross-session dedup intentionally absent | 003-test |

## Dependency Chain

```
                          task-001 (setup-fixtures)
                            │
                            ▼
                       task-002-test ──→ task-002-impl
                                              │
                ┌─────────────────────────────┼─────────────────────────────┐
                ▼                             ▼                             ▼
          task-003-test                task-004-test*               task-005-test*
                │                             │                             │
                ▼                             ▼                             ▼
          task-003-impl                task-004-impl                task-005-impl
                │                             │                             │
                │                             ▼                             │
                │                       task-006-test                       │
                │                             │                             │
                │                             ▼                             │
                │                       task-006-impl ◀───────────────────┐ │
                │                             │                           │ │
                │                             ▼                           │ │
                │                       task-007-test ◀───────────────────┼─┘
                │                             │                           │
                │                             ▼                           │
                │                       task-007-impl                     │
                │                             │                           │
                │                             ▼                           │
                │                       task-008-test                     │
                │                             │                           │
                │                             ▼                           │
                │                       task-008-impl                     │
                │                             │                           │
                ├─────────────────────────────┤                           │
                ▼                             ▼                           │
          task-009-test               task-010-test (needs 003-impl + 008-impl)
                │                             │                           │
                ▼                             ▼                           │
          task-009-impl               task-010-impl                       │
                │                             │                           │
                └──────────────┬──────────────┴───────────────────────────┘
                               ▼
                         task-011 (allowed-tools)
                               │
                               ▼
                         task-012 (discharge + README + version bump)

*task-004-test and task-005-test depend on task-001 directly (fixture consumers).
```

**Analysis**:
- **No circular dependencies** — verified visually + by walking the YAML.
- **Foundation → wrappers (parallel) → migrations (serial on retrospective/SKILL.md) → emission + reader (parallel) → config → docs**.
- **Parallel paths**:
  - After 002-impl: tasks 003-test/4-test/5-test (and their impls) work on **different files** in `lib/` and `tests/` — true parallelism available.
  - Tasks 006/7/8 all modify `retrospective/SKILL.md`; serialized to avoid edit conflicts.
  - Tasks 009 and 010 modify **different SKILL.md files** (systematic-debugging vs retrospective); can be parallel after their prerequisites are met.
- **Serial chokepoint**: tasks 006 → 007 → 008 form a serial chain because they all edit the same file. The dependency on Task 008 before Task 010 is also same-file (retrospective/SKILL.md edits should not pile up; sequential is safer).
- **Test-first**: every test task precedes its impl via `depends-on`, satisfying TDD.

## Reflection Summary (Phase 4)

Three parallel sub-agents reviewed this plan against `docs/retros/checklists/plan-v1.md`. All five rubric items returned PASS:

| Checklist item | Verdict | Evidence |
|---|---|---|
| PLAN-COV-01 (BDD scenario coverage) | PASS | 23/23 scenarios mapped; one plan-layer scenario in task-010-test is now explicitly annotated as plan-derived. |
| DEP-01 (No circular dependencies) | PASS | Topological sort succeeds for all 21 tasks. |
| DEP-02 (All dependency references resolve) | PASS | 20 edges, 21 nodes, 0 dangling references. |
| TEST-01 (Impl tasks have corresponding test tasks) | PASS | Every NNN-impl pairs to NNN-test for 002–010; 001/011/012 are non-impl. |
| TASK-COMP-03 (Verification commands are executable) | PASS | No "verify that"/"check that"/"ensure that"/"manually" prefixes found. |

**Out-of-rubric fixes applied** based on sub-agent advisory findings:
- **Prohibited implementation bodies removed** from impl tasks 002, 003, 004, 005, 008, 009. Bodies were replaced with contract descriptions + cross-references to `lib/bail-log.sh` precedent (file:line pointers, not code).
- **ASCII Dependency Chain** corrected so the 009 branch aligns with the YAML's actual `depends-on` (009 depends on 003-impl only, not on 008-impl).
- **task-009 impl Step 2** rewritten to present a single BDD-aligned variant (state-resolved skill name, skip on empty — no fallback to literal); the prior self-correcting prose is gone.
- **task-010 plan-derived Gherkin** now carries an explicit `[Note: plan-derived, not present verbatim in bdd-specs.md]` annotation.

Out-of-rubric findings that remain advisory and were NOT fixed in this round (each one would change semantics beyond reflection cleanup):
- Task numbering: "Task NNN of 21" appears on both impl and test files sharing a prefix. Renumbering would touch every file; defer to executing-plans phase if it causes confusion.
- Cross-task xfail coordination (task-002 test's `BackwardCompatTests` xfails clear when Tasks 003–005 land): noted in task-002 test's success criteria; no new rubric item added.

## Execution Handoff

**"Plan complete and saved to `docs/plans/2026-05-12-unified-retro-events-plan/`. Load `superpowers:executing-plans` skill using the Skill tool — it orchestrates per-batch sub-agent coordinators through the full Phase 1-6 pipeline."**
