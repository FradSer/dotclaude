---
name: writing-plans
description: Creates executable implementation plans that break down designs into detailed tasks. This skill should be used when the user has completed a brainstorming design and asks to "write an implementation plan" or "create step-by-step tasks" for execution.
argument-hint: [design-folder-path]
user-invocable: true
allowed-tools: ["Read", "Write", "Edit", "Glob", "Grep", "Agent", "Bash(git-agent:*)", "Bash(git:*)", "Bash(${CLAUDE_PLUGIN_ROOT}/lib/seed-checklists.sh:*)", "Bash(${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh:*)"]
---

# Writing Plans

Create executable implementation plans that reduce ambiguity for whoever executes them — substantial Phase 1 → Phase 6 work, run wrapped in `/goal` (see below).

## Recommended: run wrapped in `/goal`

**Launch it under Claude Code's built-in `/goal`** (v2.1.139+) so the run continues to a committed plan instead of stopping mid-phase:

```
/goal "Claude has narrated a successful plan commit (with commit hash) and reported the Phase 4 reflection sub-agent verdicts inline" /superpowers:writing-plans <design-path>
```

`/goal` is a **user-typed outer wrapper** (a skill cannot enable it for itself mid-run), and its evaluator judges only what Claude narrates in the transcript — phrase the condition against narrated output (the commit hash, the literal Phase 4 reflection summary), never filesystem state. Full semantics and condition phrasing: `../../skills/references/goal-wrapper.md`.

## CRITICAL: Bail-Out Check (run first)

**Read `bdd-specs.md` from the resolved design folder. Count `Scenario:` occurrences. Bail out — do NOT decompose tasks — when EITHER:**

- BDD scenarios in `bdd-specs.md` < 3, **OR**
- Total estimated task count < 5 (estimate `2× BDD scenarios + 1 setup task`, or prefer an explicit "Task Estimate" hint in the design `_index.md`)

The OR-gate catches the "2 BDD + many setup tasks" shape an AND-gate lets through.

**Bail-out response (output verbatim):**

> Design too thin for full task-decomposition pipeline (BDD < 3 OR estimated tasks < 5). Drafting a one-page lightweight plan inline instead. To force the full pipeline, re-invoke as `/superpowers:writing-plans --force <design-path>`.

Then write a single `_index.md` (no per-task files, no Phase 4 reflection, no plan evaluator) and exit. The `--force` token (literal in `$ARGUMENTS`, case-sensitive, whole-token match) bypasses this check.

## CRITICAL: Justification Check (run after bail-out)

**Read `_index.md` from the resolved design folder. Bail out — do NOT decompose tasks — when grep matches any of:**

```bash
grep -nE "STATUS:.*NOT.JUSTIFIED|DESIGN-NOT-YET-JUSTIFIED|DESIGN-CONSIDERED-DEFERRED|DO NOT IMPLEMENT" "<resolved-design-folder>/_index.md"
```

This catches designs explicitly marked "not approved to advance" (full semantics: `docs/retros/checklists/design-v1.md` JUST-01; inciting case: `docs/retros/2026-05-09-v3-considered-deferred.md`).

**On match, refuse deterministically (the marker is dispositive — do not interpret it away)**:

1. Output a one-line note: `Refusing: <design-path>/_index.md:{N} is marked NOT-JUSTIFIED — '{matched text}'. Re-invoke /superpowers:brainstorming to revise the design, or pass --justify-override to bypass this gate.`
2. Exit without proceeding.

**Override**: Pass `--justify-override` (literal token in `$ARGUMENTS`, case-sensitive, whole-token match) to bypass this refusal and continue to First Action.

**PROHIBITED**: Do NOT conflate `--force` (bypasses the size gate only) with `--justify-override` (bypasses this justification gate only) — they are independent; `--force` on a thin design does not bypass a NOT-JUSTIFIED refusal.

## First Action — Resolve Design Path

1. Resolve the design path:
   - If `$ARGUMENTS` provides a path (e.g., `docs/plans/YYYY-MM-DD-topic-design/`), use it
   - Otherwise, pick the `*-design/` folder whose basename sorts last under `YYYY-MM-DD-*-design/` — highest date prefix in the name, not filesystem mtime: `ls -1d docs/plans/*-design/ 2>/dev/null | sort | tail -1` (NOT `ls -t` — edited old folders outrank fresh ones by mtime). Use the result directly; do NOT pause to confirm.
   - If no `*-design/` folder exists in `docs/plans/`, refuse with: `Refusing: no design folder found under docs/plans/. Run /superpowers:brainstorming first, or pass the design folder path explicitly.` Then exit.
2. Proceed to Initialization in the same turn.

## Initialization

1. **Design Check**: Verify the folder contains `_index.md` and `bdd-specs.md`. Consult the docs index before drafting: run `bash "${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh" show <design-path>`. If the status is `expired:`, REFUSE — output a one-line note citing the expired status and exit without creating a plan folder. Then consult memory: run `bash "${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh" list --kind memory --status active` and Read the top topically-relevant matches before Phase 1.
2. **Context**: Read `bdd-specs.md` completely. This is the source of truth for your tasks.

## Background Knowledge

**Core Concept**: Explicit over implicit, granular tasks, verification-driven, context independence.

**MANDATORY**: Unit-test tasks require external dependency isolation with test doubles (DB/network/third-party APIs). All other decomposition invariants are enforced by Phase 2 steps 1-7.

## Phase 1: Plan Structure

Define goal, architecture, constraints, and context.

1. **Read Specs**: Read `bdd-specs.md` from the design folder.
2. **Draft Structure**: Use `./references/structure-template.md` to outline the plan.
3. **Write Context Section**: Populate `## Context` in `_index.md`: why this work is needed (motivation, constraints, prior incidents); for existing-code changes add a current-state vs target-state comparison table (omit for greenfield work).
4. **Write Global Constraints Section**: Populate the `## Global Constraints` section in `_index.md` — the cross-task invariants every batch and every task must respect (these make parallel batches safe). One invariant per bullet, no prose; omit only when the design carries zero cross-cutting constraints (rare). Categories and examples: `./references/structure-template.md` §Global Constraints.

## Phase 2: Task Decomposition

Break into small tasks mapped to specific BDD scenarios.

**PROHIBITED**: Do not ask the user to choose granularity, approve decomposition, or confirm the plan mid-process — apply steps 1-7 plus these additions automatically; Phase 4 reflection is the quality gate and the post-commit `git show` diff is the audit surface.

- Foundation tasks (setup, shared schema, types, config, storage) take lower `NNN` before feature pairs
- Bundle all scenarios of a Feature into one test file; split only when the Feature crosses independent service boundaries (e.g., frontend vs backend)

1. **Reference Scenarios**: **CRITICAL**: Every task must explicitly include the full BDD Scenario content in the task file using Gherkin syntax — self-contained, not just a reference to `bdd-specs.md`, so the executor sees the complete scenario without switching files. Format: `./references/structure-template.md` §BDD Scenario.
2. **Define Verification**: **CRITICAL**: Verification steps must run the BDD specs (e.g., `npm test tests/login.spec.ts`).
3. **Enforce Ordering**: For each feature NNN, the test task (`task-NNN-<feature>-test`) must precede its paired impl task (`task-NNN-<feature>-impl`) via `depends-on`.
4. **Declare Dependencies**: **MANDATORY**: Each task file must include a `**depends-on**` field listing only **true technical prerequisites** — tasks whose output is required before this task can start. **PROHIBITED**: chaining tasks just to impose execution order. Independence rules and examples: `./references/task-granularity-and-verification.md` §Dependency Rules.
5. **Create Task Files**: **MANDATORY**: Create one `.md` file per task. Filename pattern: `task-<NNN>-<feature>-<type>.md` (e.g. `task-001-setup.md`, `task-002-feature-test.md` / `task-002-feature-impl.md` — test and impl for the same feature share the NNN prefix; types: test, impl, config, refactor; full template: `./references/structure-template.md` §Task Files).
   - **Right-sizing**: Do NOT manufacture standalone setup/config/docs tasks when their only consumer is a single feature task — fold them into the task that needs them. A standalone `task-001-setup` is justified only when 2+ downstream tasks share its output; pseudo-independent setup tasks create false parallelism and inflate batch counts.
6. **Declare Interfaces**: **MANDATORY**: Each task file includes a `## Interfaces` section (after `## BDD Scenario`) declaring the contracts this task exposes or consumes (function signatures, types, API endpoints, event names, CLI flags). `depends-on`-linked tasks connect through these blocks, so parallel batches can verify interface compatibility before merge.
7. **Describe What, Not How**: **PROHIBITED**: Do not generate implementation bodies. Describe what to implement; interface signatures in the `## Interfaces` block define contracts, but never the body logic.

## Phase 3: Validation & Documentation

Verify completeness, save, advance to Phase 4 in the same iteration.

1. **Verify**: Check for valid commit boundaries and no vague tasks. On failure do NOT pause — re-enter Phase 2 in the same iteration to fix the offending tasks, then re-verify.
2. **Save**: Write to `docs/plans/YYYY-MM-DD-<topic>-plan/` folder.
   - **CRITICAL**: `_index.md` MUST include "Execution Plan" section with **inline YAML metadata**
   - **CRITICAL**: `_index.md` MUST include "Task File References" section linking all task files
   - **CRITICAL**: `_index.md` MUST include "BDD Coverage" section confirming all scenarios are covered
   - **CRITICAL**: `_index.md` MUST include "Dependency Chain" section with visual dependency graph (will be populated in Phase 4)
   - YAML metadata and file-reference examples: `./references/structure-template.md` §Execution Plan

## Phase 4: Plan Reflection

Before committing, verify plan quality with parallel fresh sub-agents, each in an isolated context (no pollution from the main planning session).

Launch three sub-agents in parallel via the Agent tool, `subagent_type=general-purpose` (full prompt templates: `./references/reflection.md`):

1. **BDD Coverage Review** — every design scenario has corresponding tasks; outputs coverage matrix + orphaned scenarios + extra tasks
2. **Dependency Graph Review** — depends-on correctness, cycles, missing dependencies; outputs the dependency graph
3. **Task Completeness Review** — required structure per task (BDD scenario, files, steps, verification); outputs incomplete-task list

**Additional sub-agents (launch as needed)**: Red-Green Pairing Review, File Conflict Review.

**Integrate and Update**:
1. Collect all sub-agent findings and prioritize by impact
2. Update plan files to fix issues
3. **MANDATORY**: Add Sub-agent 2's dependency graph to `_index.md` "Dependency Chain"
4. Re-verify updated sections
5. **Record reflection summary inline** in your turn output (1 line per sub-agent verdict + what changed) — the audit trail the user reads post-commit via `git show`; do NOT pause for approval

**Output**: Updated plan, dependency graph in `_index.md`, reflection summary inline — ready for Phase 5.

**Mid-stream cancellation** (only under `/goal`; user injects "abort"/"cancel"/"start over"): stop with a one-line note — no commit, no Phase 5; the user re-invokes with the new framing if they want to retry.

**Multi-turn resumption** (only when wrapped in `/goal` after an interrupted turn): **do not restart from Phase 1** — `Glob "docs/plans/*-plan/_index.md"`, read the in-progress plan folder, and resume at the phase the filesystem indicates: task files exist but `_index.md` lacks the YAML `tasks:` block or References/Coverage sections → Phase 3; `_index.md` complete but no "Dependency Chain" graph → Phase 4; plan complete, no commit → Phase 5; already committed → Phase 6.

The sub-agents are the sole plan-quality reviewer (no separate plan-mode evaluator; the user reviews post-commit via `git show`). They read `docs/retros/checklists/plan-v{N}.md` as their rubric. On any checklist-item FAIL, fix the offending plan files and rerun that sub-agent — do NOT commit a plan with an unaddressed FAIL.

**Auto-seed checklist when missing**: before spawning the reflection sub-agents, if no `plan-v{N}.md` exists, run `bash "${CLAUDE_PLUGIN_ROOT}/lib/seed-checklists.sh" plan docs/retros/checklists/plan-v1.md` (exit 0 = seeded, 3 = already exists → proceed, 1/2 = abort), then pass the resolved checklist path to each sub-agent prompt.

**MUST: each reflection sub-agent prompt MUST include an instruction to read the resolved checklist file and apply each item as a binary PASS/FAIL rubric** (the template in `./references/reflection.md` §Checklist Binding carries this directive — do not strip it). A sub-agent without the checklist produces an unanchored opinion, not a verdict.

## Phase 5: Git Commit

Commit the plan folder using git-agent (with git fallback).

**Actions**:
0. **Upsert the plan into the docs index** (before `git add`): run `bash "${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh" upsert plan <new-plan-path> --status active --summary "<one-line>"`. CRITICAL do-not-defer — the index update lands in the same commit-group as the plan folder.
0.5. **CRITICAL do-not-defer**: Conditional memory-write step, gated on a Phase 4 sub-agent FAIL that required a fix-and-rerun (not a first-pass PASS) — if triggered, write `docs/memory/pitfall_<slug>.md` capturing the false-positive cause, then run `bash "${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh" upsert memory docs/memory/pitfall_<slug>.md --status active --summary "<one-line>" --category pitfall`. No-op if every sub-agent passed first try.
1. Stage and commit the entire folder in ONE chained command — a standalone `git add` is denied by the git plugin's hook: `git add docs/plans/YYYY-MM-DD-<topic>-plan/ && git-agent commit --no-stage --intent "add implementation plan for <topic>" --co-author "Claude <Model> <Version> <noreply@anthropic.com>"`
2. On auth error, retry with `--free` flag
3. **Fallback**: If git-agent is unavailable or fails, invoke the `/git:commit` skill via the Skill tool; full ladder in `../../skills/references/git-commit.md`

## Phase 6: Transition to Execution

Output:

> Plan complete. To execute this plan, use `/superpowers:executing-plans`.

**PROHIBITED**: Do NOT offer to start implementation directly.

## Exit Criteria

Clear goal/constraints, decomposed tasks with file lists and verification, BDD steps, commit boundaries, no vague tasks, reflection complete with all FAILs addressed, git commit landed.

## References

- `./references/structure-template.md` - Plan and task file templates
- `./references/task-granularity-and-verification.md` - Task breakdown, verification, dependency rules
- `./references/reflection.md` - Sub-agent prompts for plan reflection
- `../../skills/references/git-commit.md` - Git commit patterns
- `../../skills/references/goal-wrapper.md` - `/goal` semantics and condition phrasing (shared)
