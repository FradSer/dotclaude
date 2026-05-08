# Superpowers Plugin

Advanced development superpowers for orchestrating complex workflows from idea to execution.

**Version**: 2.8.2

## Installation

```bash
claude plugin install superpowers@frad-dotclaude
```

## Overview

The superpowers plugin provides a comprehensive framework for collaborative software development, enabling teams to move from rough ideas through structured planning to coordinated execution. It combines strategic planning tools with behavior-driven development practices.

## When NOT to use superpowers

The full pipeline (brainstorming → writing-plans → executing-plans + per-batch evaluator + retrospective) is calibrated for **open-ended multi-component problems**: design decisions that benefit from structured research, plans with 5+ tasks across 2+ batches, and work where first-pass quality is load-bearing.

Using the full pipeline for smaller work is **net negative** — the overhead (sprint contracts, per-batch evaluator, checklist resolution, retrospective logs) exceeds the value delivered.

**Each user-invocable skill enforces this at its entry via a CRITICAL Bail-Out Check** (see SKILL.md):

| Skill | Bail-out trigger | Override |
|---|---|---|
| `/superpowers:brainstorming` | Trivial-scope signals in `$ARGUMENTS` (single-file change, mechanical refactor, named root cause, one-shot script, "just patch") | `/superpowers:brainstorming --force "<task>"` |
| `/superpowers:writing-plans` | `bdd-specs.md` has < 3 scenarios AND < 5 estimated tasks | `/superpowers:writing-plans --force <design-path>` |
| `/superpowers:executing-plans` | `_index.md` lists < 5 tasks in a single batch | `/superpowers:executing-plans --force <plan-path>` |
| `/superpowers:systematic-debugging` | Named root cause + named fix in `$ARGUMENTS` (apply fix + write regression test directly, skip the 4-phase pipeline) | `/superpowers:systematic-debugging --force "<symptom>"` |

**For incident response and root-cause work, use `/superpowers:systematic-debugging` directly** — the design pipeline is the wrong shape for unknown-root-cause bugs.

Examples that ALWAYS bail out:

| Signal | Example | Recommended path |
|--------|---------|----|
| Single-file edit with obvious outcome | Rename a variable, fix a typo, adjust a log level | Direct edit, no skill needed |
| Mechanical refactor with tests already in place | Extract a helper, reorder imports, update a deprecated API call | Direct edit, no skill needed |
| Bug fix traceable to a specific line | Off-by-one in a loop, null-check missing on a known field | `/superpowers:systematic-debugging` |
| Unknown bug | "Tests pass locally but fail in CI" | `/superpowers:systematic-debugging` |
| Exploratory one-shot script | Throwaway data migration, one-off CLI check | Direct edit, no skill needed |

If a task turns out to be larger than it first appeared, start superpowers at the level that matches — e.g. jump directly to `/superpowers:writing-plans` when you already have a clear design in your head, or `/superpowers:executing-plans` when a plan folder already exists from a prior session. You do not have to run every upstream skill.

For harness components that start feeling like pure overhead on a project (e.g. per-batch evaluator never raises issues), `/superpowers:retrospective` Phase 5 writes `docs/retros/harness-config.json` to disable one component at a time for the next plan run — use it instead of hand-editing skills.

## User-Invocable Skills

### `/superpowers:brainstorming`

Turn rough ideas into implementation-ready designs through structured collaborative dialogue.

- Clarifies ambiguous requirements through focused questioning
- Explores design alternatives grounded in codebase reality
- Produces design documents with BDD specifications (Given-When-Then)
- Prepares the project for planning and implementation

**Workflow:** Phase 1 (Scope Alignment) → Phase 1.5 (Harness Config Check) → Phase 2 (Design with QA) → Phase 3 (Wrap-up)

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
- Runs a per-batch evaluator against the sprint contract by default (overridable only via retrospective-approved `docs/retros/harness-config.json` — see `/superpowers:retrospective` Phase 5)

**Prerequisites:** Output from `superpowers:writing-plans` skill (plan folder with `_index.md`)

**Output:** Executed tasks with verification evidence, per-batch evaluation reports, and completion confirmation

### `/superpowers:retrospective [plan-path-1] [plan-path-2] [--across-all]`

Analyze evaluation patterns across completed plans and evolve checklists.

- Aggregates evaluation reports across plans to find failure patterns, plateau tasks, and never-failing items
- Proposes versioned checklist changes (ADD / REMOVE / MODIFY / PROMOTE) via `AskUserQuestion`
- Audits harness health (Phase 5): writes `docs/retros/harness-config.json` to disable one component at a time for the next plan run as a live assumption test
- Closes the calibration loop by appending to `docs/retros/evolution-log.jsonl`

**Prerequisites:** Plans completed via `superpowers:executing-plans` with evaluation reports in the plan directory (or no arguments — auto-scopes via `docs/retros/plans-completed.jsonl`)

**Output:** Retrospective report, updated `{mode}-v{N+1}.md` checklists (if any proposals approved), and optionally an updated `harness-config.json`

### `/superpowers:systematic-debugging "<bug description>"`

Root-cause analysis for bugs, test failures, and incidents — no design pipeline, no Superpower Loop.

- 4-phase process: Root Cause Investigation → Pattern Analysis → Hypothesis & Testing → Implementation
- Captures `$ARGUMENTS` as the symptom statement and starts at Phase 1 immediately
- Deliverable is `the fix + a test that catches the regression`, not design folders
- Refuses to propose fixes before completing Phase 1 (Iron Law: NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST)

**When to use**: bug reports, test failures, unexpected behavior, performance issues, build failures. Especially valuable when time pressure tempts you to guess.

**Output**: root cause one-liner + fix diff summary + regression test path

### `/superpowers:need-vet`

Opt-in work verification for the current task.

- Sets a `need_vet` flag on the session state file
- The Stop hook (`hooks/stop-hook.sh`) blocks session exit until Claude emits `<verified>Fully Vetted.</verified>` as the final standalone line after actually running the code / opening the UI / testing edge cases
- Workflow skills (brainstorming / writing-plans / executing-plans / retrospective) have their own phase verification and bypass this check automatically

**Output:** A Verification Checkpoint system message that lists the current task, modified files, and required verification steps

## Internal Skills (Loaded Automatically)

### Behavior-Driven Development

Loaded when implementing features or bugfixes during execution. Enforces the Red-Green-Refactor cycle driven by BDD scenarios in Gherkin format (Given-When-Then).

### Build Like iPhone Team

Loaded when the user wants to challenge industry conventions or approach open-ended problems requiring disruptive thinking. Applies Apple's Project Purple design philosophy for radical innovation, including first-principles thinking, internal competition, and breakthrough research techniques. The `superpowers:brainstorming` skill loads this automatically for problems that benefit from unconventional approaches.

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
   - Per-batch: fresh sub-agent coordinator + evaluator (default on,
     overridable via docs/retros/harness-config.json)
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

## File Structure

```
superpowers/
├── .claude-plugin/
│   └── plugin.json              # Plugin manifest with skill and hook registration
├── agents/
│   └── superpowers-evaluator.md # Independent read-only evaluator (design / code modes)
├── hooks/
│   ├── task-start.sh            # UserPromptSubmit — persists state + detects slash commands
│   ├── track-changes.sh         # PostToolUse (Edit/Write/MultiEdit) — tracks modified files
│   └── stop-hook.sh             # Stop — thin dispatcher calling loop.sh + vet.sh
├── lib/
│   ├── utils.sh                 # Shared helpers (state I/O, Haiku merge, tag extraction)
│   ├── loop.sh                  # Stop hook Phase 1 — Superpower Loop iteration
│   └── vet.sh                   # Stop hook Phase 2 — need-vet verification
├── scripts/
│   └── setup-superpower-loop.sh # Entry point skills call to enter the loop
├── skills/
│   ├── brainstorming/           # Idea → design with BDD specs (user-invocable)
│   ├── writing-plans/           # Design → task files (user-invocable)
│   ├── executing-plans/         # Plan → verified code via per-batch coordinator (user-invocable)
│   ├── retrospective/           # Evolve checklists + audit harness health (user-invocable)
│   ├── systematic-debugging/    # 4-phase root cause analysis (user-invocable, 2.4.0+)
│   ├── need-vet/                # Opt-in work verification (user-invocable)
│   ├── behavior-driven-development/  # BDD cycle (internal)
│   ├── build-like-iphone-team/  # Project Purple design philosophy (internal)
│   └── references/
│       ├── git-commit.md        # Shared git commit patterns
│       └── loop-patterns.md     # Shared Superpower Loop patterns
├── LICENSE
└── README.md
```

## Integration with Claude Code

- **Skill Tool:** Load skills dynamically during workflows
- **Agent Tool:** Spawn fresh sub-agent coordinators (per batch) and the read-only `superpowers-evaluator` (design / code modes — plan-mode review is handled inline by `writing-plans` Phase 4)
- **Task Management:** Create and track tasks during execution
- **Hook Pipeline:** Three coordinated hooks share a per-session state file at `~/.claude/projects/<project-key>/<session_id>.superpowers.json`
  - `UserPromptSubmit` → `hooks/task-start.sh` persists task + detects slash commands
  - `PostToolUse` (Edit/Write/MultiEdit) → `hooks/track-changes.sh` accumulates modified files
  - `Stop` → `hooks/stop-hook.sh` dispatches to Superpower Loop iteration (Phase 1) and work verification (Phase 2)
- **Git Integration:** Automatic commit messages via `git-agent` with fallback to conventional-format `git commit`

## Harness Calibration

The plugin exposes a feedback loop so harness components earn their cost as models improve:

- Every plan completion appends to `docs/retros/plans-completed.jsonl`
- At 3+ plans since the last retrospective, `executing-plans` emits a `RETROSPECTIVE DUE` reminder
- `/superpowers:retrospective` Phase 5 can write `docs/retros/harness-config.json` to disable one component for the next plan run as a live assumption test. Supported identifiers (each with a real consumer-side check):
  - `evaluator_per_batch` — `executing-plans` skips per-batch evaluator
  - `design_evaluator` — `brainstorming` skips design-mode evaluator
  - `sprint_contract_preview` — `executing-plans` omits Evaluation Criteria Preview from sprint contracts
  - `recurring_failure_patterns` — `executing-plans` skips pattern-scan injection
- Disabled runs append to `docs/retros/harness-observations.jsonl`; the next retrospective reads those observations and decides promote / reinstate / extend
- Retrospective Phase 5c **refuses** these removed/deferred identifiers (logs `component_unsupported`, rewrites the file with an empty `disabled_components[]`):
  - `context_reset_coordinator` — deferred in 2.4.0; the "main agent runs batches directly" alt-path was too large to land safely
  - `plan_evaluator` — permanently removed in 2.6.0; `writing-plans` Phase 4 sub-agent reflection covers the same checks

See `skills/retrospective/references/harness-config.md` for schema and lifecycle.

## Author

Frad LEE (fradser@gmail.com)

## License

MIT
