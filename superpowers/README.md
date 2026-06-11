# Superpowers Plugin

Advanced development workflow orchestration with BDD support and self-improving skills.

**Version**: 3.3.0
**Requires**: Claude Code v2.1.139+ (for native `/goal` continuation)
**Runtime** (state-sync hook): `git` and `jq` on `PATH` — without them the single Stop hook exits silently and neither `docs/retros/plans-completed.jsonl` nor the evolution-log backfill is written

## Installation

```bash
claude plugin install superpowers@frad-dotclaude
```

## Overview

The superpowers plugin provides a comprehensive framework for collaborative software development, enabling teams to move from rough ideas through structured planning to coordinated execution. It combines strategic planning tools with behavior-driven development practices.

Each skill is a plain phase-based pipeline. These are substantial multi-turn tasks, so **the recommended way to run any of them is wrapped in Claude Code's native `/goal`** ("keep working until condition X holds" — autonomous multi-turn continuation); the plugin no longer ships its own continuation loop.

## When NOT to use superpowers

The full pipeline (brainstorming → writing-plans → executing-plans + per-batch evaluator + retrospective) is calibrated for **open-ended multi-component problems**: design decisions that benefit from structured research, plans with 5+ tasks across 2+ batches, and work where first-pass quality is load-bearing.

Using the full pipeline for smaller work is **net negative** — the overhead (sprint contracts, per-batch evaluator, checklist resolution, retrospective logs) exceeds the value delivered.

**Each user-invocable skill enforces this at its entry via a CRITICAL Bail-Out Check** (see SKILL.md):

| Skill | Bail-out trigger | Override |
|---|---|---|
| `/superpowers:brainstorming` | Trivial-scope signals in `$ARGUMENTS` (single-file change, mechanical refactor, named root cause, one-shot script, "just patch") | `/superpowers:brainstorming --force "<task>"` |
| `/superpowers:writing-plans` | `bdd-specs.md` has < 3 scenarios OR < 5 estimated tasks | `/superpowers:writing-plans --force <design-path>` |
| `/superpowers:executing-plans` | `_index.md` lists < 5 tasks in a single batch | `/superpowers:executing-plans --force <plan-path>` |
| `/superpowers:systematic-debugging` | Named root cause + named fix in `$ARGUMENTS` (apply fix + write regression test directly, skip the 4-phase pipeline) | `/superpowers:systematic-debugging --force "<symptom>"` |

**For incident response and root-cause work, use `/superpowers:systematic-debugging` directly** — the design pipeline is the wrong shape for unknown-root-cause bugs.

**Recommended invocation — wrap in `/goal`.** These skills do substantial multi-turn work, so launch them under Claude Code's native `/goal` (v2.1.139+). It is a user-typed outer wrapper — a skill cannot enable it for itself mid-run. Example:

```
/goal "Claude has narrated a successful design commit (with commit hash) and the evaluator's verdict is PASS" /superpowers:brainstorming "<problem>"
```

`/goal` provides session-scoped Stop-hook-based continuation with a fresh model evaluating your condition after each turn — same role the plugin's removed v2.x runtime used to play, but from the platform rather than from hand-rolled bash. **Phrase conditions against transcript content** (commit-hash narration, literal evaluator verdict lines, explicit "Phase N complete" statements) — the evaluator does NOT read files or run commands ([upstream docs](https://code.claude.com/docs/en/goal)), so filesystem-state conditions like `_index.md exists` or `git commit clean` are unverifiable and will time out.

Examples that ALWAYS bail out:

| Signal | Example | Recommended path |
|--------|---------|----|
| Single-file edit with obvious outcome | Rename a variable, fix a typo, adjust a log level | Direct edit, no skill needed |
| Mechanical refactor with tests already in place | Extract a helper, reorder imports, update a deprecated API call | Direct edit, no skill needed |
| Bug fix traceable to a specific line | Off-by-one in a loop, null-check missing on a known field | `/superpowers:systematic-debugging` |
| Unknown bug | "Tests pass locally but fail in CI" | `/superpowers:systematic-debugging` |
| Exploratory one-shot script | Throwaway data migration, one-off CLI check | Direct edit, no skill needed |

If a task turns out to be larger than it first appeared, start superpowers at the level that matches — e.g. jump directly to `/superpowers:writing-plans` when you already have a clear design in your head, or `/superpowers:executing-plans` when a plan folder already exists from a prior session. You do not have to run every upstream skill.

For harness components that start feeling like pure overhead on a project (e.g. per-batch evaluator never raises issues), `/superpowers:retrospective` Phase 5 surfaces them as REMOVE/MODIFY candidates — component changes go through ordinary checklist proposals with human review of the post-commit diff, not an automated disable switch.

## User-Invocable Skills

### `/superpowers:brainstorming`

Turn rough ideas into implementation-ready designs through autonomous, codebase-grounded research. Runs to completion without pausing for mid-design questions; you review the committed design after.

- Resolves ambiguous requirements from codebase evidence (no mid-design questions — assumptions are documented in the design for review)
- Explores design alternatives grounded in codebase reality
- Produces design documents with BDD specifications (Given-When-Then)
- Prepares the project for planning and implementation

**Workflow:** Phase 1 (Scope Alignment) → Phase 2 (Design with QA) → Phase 3 (Wrap-up)

**Output:** Design folder with `_index.md` and `bdd-specs.md` ready for planning

### `/superpowers:writing-plans [design-folder-path]`

Create executable implementation plans that reduce ambiguity for execution.

- Decomposes designs into granular, testable tasks
- Maps each task to specific BDD scenarios
- Enforces Test-First (Red-Green) ordering
- Ensures compatibility with behavior-driven development practices

**Prerequisites:** Output from `superpowers:brainstorming` skill (design folder with `bdd-specs.md`)

**Output:** Plan folder with `_index.md` and task files ready for execution

### `/superpowers:executing-plans [plan-folder-path]`

Execute written implementation plans in predictable batches.

- Validates plans before execution begins
- Spawns a fresh sub-agent coordinator per batch (context-reset architecture)
- Tracks task completion and captures evidence
- Runs a per-batch evaluator against the sprint contract
- Orients each turn via `scripts/batch-progress.sh` (filesystem-derived batch state, formerly part of the v2.x continuation runtime — Removed in v3.0.0 as a plugin-level hook, kept as a skill-local helper)

**Prerequisites:** Output from `superpowers:writing-plans` skill (plan folder with `_index.md`)

**Output:** Executed tasks with verification evidence, per-batch evaluation reports, and completion confirmation

### `/superpowers:retrospective [plan-path-1] [plan-path-2] [--across-all]`

Analyze evaluation patterns across completed plans and evolve checklists.

- Aggregates evaluation reports across plans to find failure patterns, plateau tasks, and never-failing items
- Proposes versioned checklist changes (ADD / REMOVE / MODIFY / PROMOTE); Phase 4 auto-applies approved proposals (review post-commit via `git show docs/retros/checklists/`)
- Audits harness health (Phase 5, advisory): mines post-plan correction commits into ADD proposals and surfaces never-firing items as REMOVE candidates
- Closes the calibration loop by appending to `docs/retros/evolution-log.jsonl`

**Prerequisites:** Plans completed via `superpowers:executing-plans` with evaluation reports in the plan directory. Invoke with explicit plan paths (or `--across-all` to scope every plan with evaluation reports). When the plugin's single Stop hook (`hooks/stop-state-sync.sh`) can run (`git` + `jq` present, plan artifacts complete), `docs/retros/plans-completed.jsonl` is **appended automatically** on first completion and drives auto-scope plus post-plan-diff pre-check. The same hook also backfills the evolution-log's `retrospective_run` watermark and `item_added`/`item_removed` deltas from durable state if the retrospective skipped them. The log may be absent for plans finished outside `executing-plans`, bail-out inline runs, or hosts missing `jq`/`git` — retrospective still works with explicit plan paths but skips auto-scope.

**Output:** Retrospective report and updated `{mode}-v{N+1}.md` checklists (if any proposals approved)

### `/superpowers:systematic-debugging "<bug description>"`

Root-cause analysis for bugs, test failures, and incidents — no design pipeline.

- 4-phase process: Root Cause Investigation → Pattern Analysis → Hypothesis & Testing → Implementation
- Captures `$ARGUMENTS` as the symptom statement and starts at Phase 1 immediately
- Deliverable is `the fix + a test that catches the regression`, not design folders
- Refuses to propose fixes before completing Phase 1 (Iron Law: NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST)

**When to use**: bug reports, test failures, unexpected behavior, performance issues, build failures. Especially valuable when time pressure tempts you to guess.

**Output**: root cause one-liner + fix diff summary + regression test path

## Internal Skills (Loaded Automatically)

### Using Superpowers (the 1% Rule dispatcher)

Reintroduced in v3.0.0. The keystone that makes the rest of the library actually fire. If there is even a 1% chance one of the user-invocable skills is the right tool, this dispatcher routes you to it explicitly via the Skill tool rather than letting you improvise past it. Its concrete trigger phrases ride in the always-resident description; `user-invocable: false` hides it from the `/` menu while the full routing table loads with the skill body.

### Behavior-Driven Development

Loaded when implementing features or bugfixes during execution. Enforces the Red-Green-Refactor cycle driven by BDD scenarios in Gherkin format (Given-When-Then).

(The `systematic-debugging` skill was promoted to user-invocable in 2.4.0 — see `/superpowers:systematic-debugging` above.)

## End-to-End Workflow

```
1. User has an idea or feature request
   ↓
2. /superpowers:brainstorming
   Clarify requirements, explore options, design solution
   Output: Design folder with BDD specs
   ↓
3. /superpowers:writing-plans [design-folder]
   Break design into testable tasks, map to BDD scenarios
   Output: Plan folder with task definitions
   ↓
4. /superpowers:executing-plans [plan-folder]
   Execute tasks using behavior-driven development
   - Per-batch: fresh sub-agent coordinator + evaluator
   Output: Implemented, tested, verified code
   ↓
5. Code is merged and shipped
   ↓
6. /superpowers:retrospective (every 3+ completed plans)
   Aggregate evaluation patterns, evolve checklists, audit harness health
   Output: retro-{date}-{topic}.md report + versioned checklists
```

## Core Principles

- **Test-First:** Every implementation starts with a failing test
- **Explicit over Implicit:** Tasks are detailed and context-independent
- **Collaborative:** Built on structured dialogue and user approval
- **Incremental:** Validate each phase before proceeding
- **Verification-Driven:** Every task includes verification steps
- **BDD-Centric:** All specifications use Given-When-Then format
- **Context-Reset:** Each batch runs in a fresh sub-agent, keeping the main agent's context compact as task count scales
- **Methodology, not machinery:** Continuation is the platform's job (`/goal`); the plugin's value is the methodology (BDD + Red-Green + checklist evolution + independent evaluator)

## File Structure

```
superpowers/
├── .claude-plugin/
│   └── plugin.json              # Plugin manifest with skill registration
├── hooks/
│   └── stop-state-sync.sh      # The single Stop hook: state-based writer for plans-completed.jsonl + evolution-log backfill (v3.2+)
├── agents/
│   └── superpowers-evaluator.md # Independent read-only evaluator (design / code modes)
├── lib/
│   ├── utils.sh                 # repo_root helper (single source of truth, ~35 lines)
│   ├── seed-checklists.sh       # Seeds design/plan/code v1 checklists on demand
│   ├── post-plan-diff.sh        # Classifies post-plan commits (feedback vs evolution) for retrospective
│   └── jsonl-emit.sh            # Shared JSONL emitter for the evolution-log channel
├── skills/
│   ├── brainstorming/           # Idea → design with BDD specs (user-invocable)
│   │   └── references/
│   │       ├── design-and-qa.md
│   │       ├── evaluation-checklist-reference.md
│   │       └── scope-alignment.md
│   ├── writing-plans/           # Design → task files (user-invocable)
│   │   └── references/
│   │       ├── reflection.md
│   │       ├── structure-template.md
│   │       └── task-granularity-and-verification.md
│   ├── executing-plans/         # Plan → verified code via per-batch coordinator (user-invocable)
│   │   ├── references/
│   │   │   ├── bail-out.md
│   │   │   ├── batch-execution-playbook.md
│   │   │   ├── blocker-and-escalation.md
│   │   │   ├── evaluation-file-formats.md
│   │   │   ├── handoff-template.md
│   │   │   ├── intra-plan-learning.md
│   │   │   └── sprint-contract-template.md
│   │   └── scripts/
│   │       └── batch-progress.sh # Filesystem-derived batch state (Step 1 of every turn)
│   ├── retrospective/           # Evolve checklists + audit harness health (user-invocable)
│   │   └── references/
│   │       ├── analysis-patterns.md
│   │       ├── evolution-protocol.md
│   │       └── post-plan-diff.md
│   ├── systematic-debugging/    # 4-phase root cause analysis (user-invocable, 2.4.0+)
│   │   ├── find-polluter.sh     # Test pollution detection helper
│   │   └── references/
│   │       ├── condition-based-waiting.md
│   │       ├── condition-based-waiting-example.ts
│   │       ├── defense-in-depth.md
│   │       └── root-cause-tracing.md
│   ├── using-superpowers/       # 1% Rule dispatcher (internal, 3.0.0+)
│   ├── behavior-driven-development/  # BDD cycle (internal)
│   └── references/
│       └── git-commit.md        # Shared git commit patterns
├── tests/
│   ├── conftest.py              # Shared test fixtures
│   ├── test_jsonl_emit_sh.py    # jsonl-emit.sh unit tests
│   ├── test_post_plan_diff_sh.py # post-plan-diff.sh unit tests
│   ├── test_superpowers_regressions.py # Regression tests
│   └── test_stop_state_sync_sh.py  # stop-state-sync Stop hook contract
├── LICENSE
└── README.md
```

## Integration with Claude Code

- **Skill Tool:** Load skills dynamically during workflows
- **Agent Tool:** Spawn fresh sub-agent coordinators (per batch) and the read-only `superpowers-evaluator` (design / code modes — plan-mode review is handled inline by `writing-plans` Phase 4)
- **Task Management:** Create and track tasks during execution
- **Native `/goal` Continuation:** The recommended way to run any superpowers skill — wrap the invocation in Claude Code's built-in `/goal` (v2.1.139+) — the plugin ships no *continuation* hooks of its own (its single `Stop` hook only mechanically syncs durable retro state — plan completion + evolution-log backfill; see below)
- **Git Integration:** Automatic commit messages via `git-agent` with fallback to conventional-format `git commit`

## Harness Calibration

The plugin exposes a lightweight feedback loop so checklists improve as models improve:

| Mechanism | What it verifies | Ground truth |
|-----------|------------------|--------------|
| `/goal` (recommended) | Multi-turn continuation stop rule | Transcript only — phrase conditions as narrated commit hash + Phase 6 summary |
| `superpowers-evaluator` (per batch) | Artifacts, commands, checklists | Filesystem + shell |
| `hooks/stop-state-sync.sh` (Stop) | `plan_completed` row for Phase 5a + evolution-log backfill (`retrospective_run` watermark, `item_*` deltas) | Plan artifacts + git + `docs/retros/` reports & checklist versions |
| `/superpowers:retrospective` | Cross-plan patterns → checklist versions | Evaluation reports + post-plan-diff + evolution-log |

- Run `/superpowers:retrospective` with explicit plan paths (or `--across-all`). When `plans-completed.jsonl` exists, auto-scope and post-plan-diff pre-check use `completion_commit` from that log.
- `/superpowers:retrospective` reads evaluation reports plus post-plan commits (`refactor:`/`fix:`/`style:`/`perf:` on plan-modified files) and applies versioned checklist changes to `{mode}-v{N+1}.md`, logged in `docs/retros/evolution-log.jsonl`.
- Phase 5 is **advisory only** — it mines post-plan corrections into ADD proposals and flags never-firing items as REMOVE candidates.

> **Removed in v3.0.0.** The hand-rolled continuation runtime was torn out in favor of Claude Code's native `/goal`. Deleted: the Stop-hook continuation loop (formerly `lib/loop.sh`), the `UserPromptSubmit` / `PostToolUse` / `Stop` hook registrations and their scripts, `scripts/setup-superpower-loop.sh`, and the per-session JSON state file. Autonomous multi-turn continuation now uses native `/goal`; per-batch context reset still uses the native Agent/Task tools, and `lib/utils.sh` is slimmed to the `repo_root` helper.
>
> **Partially revised in v3.1.x.** Demoting the `plan_completed` write to a Claude-instructed Phase 6 step (rather than hook-written) was a mistake: empirical audit showed the manual write is silently dropped, starving the retrospective Phase 5a signal that reads `completion_commit` from it. v3.1 reintroduces a single minimal `Stop` hook whose job is that mechanical write. Detection is **state-based** — every batch handed off plus a git commit touching the `handoff-state.md` modified-files set — not keyed off any sentence the model emits. Per-plan dedup is cheap (anchored substring checks); the hook still runs on every Stop but exits quickly when C1–C4 fail. It carries none of the deleted continuation/stall/telemetry runtime. **v3.1.1** removes the `find -newer` global gate that could skip backlog plans in multi-plan repos, tightens evolution-log guards, and aligns docs/evaluator defaults with `code-v{N}` checklists.
>
> **Generalized in v3.2.0.** The same silent-drop failure was found in the retrospective's own evolution-log writes (the `retrospective_run` closure watermark and per-proposal `item_*` rows), both still Claude-instructed steps. Rather than add a second hook, the single Stop hook was renamed `hooks/plan-completed.sh` → `hooks/stop-state-sync.sh` and given a second, equally state-based responsibility: backfill the `retrospective_run` watermark from a `retro-*.md` report lacking one, and backfill `item_added`/`item_removed` by diffing the latest checklist version against its predecessor when no log row carries that version. Both backfills dedup so the richer in-skill emit (now marked CRITICAL, with a Phase 4 count self-check for partial drops) stays authoritative. Superpowers still ships exactly one hook.

> **Removed in v2.9.0.** The automated assumption-test layer — `harness-config.json` one-at-a-time component disabling, the `harness-observations.jsonl` / `bail-out-events.jsonl` / `skill-events.jsonl` telemetry channels, and the `RETROSPECTIVE DUE` auto-reminder — was deleted. An audit of 6 real projects showed those channels stayed empty everywhere and the single disable test that ever ran had to be reverted by hand; the value came entirely from the evaluator + manually-invoked retrospective + post-plan-diff. The REMOVE threshold was also lowered (10+ → 3+ reports/item) so the loop can shrink checklists, not only grow them.

## Author

Frad LEE (fradser@gmail.com)

## License

MIT. Based on [obra/superpowers](https://github.com/obra/superpowers) by Jesse Vincent (MIT, Copyright (c) 2025). See `LICENSE` for full notices.
