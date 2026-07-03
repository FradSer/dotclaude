---
name: writing-plans
description: Creates executable implementation plans that break down designs into detailed tasks. This skill should be used when the user has completed a brainstorming design and asks to "write an implementation plan" or "create step-by-step tasks" for execution.
argument-hint: [design-folder-path]
user-invocable: true
allowed-tools: ["Read", "Write", "Edit", "Glob", "Grep", "Agent", "Bash(git-agent:*)", "Bash(git:*)", "Bash(${CLAUDE_PLUGIN_ROOT}/lib/seed-checklists.sh:*)"]
---

# Writing Plans

Create executable implementation plans that reduce ambiguity for whoever executes them. This is substantial Phase 1 → Phase 6 work — **the recommended way to run it is wrapped in Claude Code's built-in `/goal`** (see below).

## Recommended: run wrapped in `/goal`

Writing a plan is multi-phase work. **Launch it under Claude Code's built-in `/goal`** (v2.1.139+) so the run continues to a committed plan instead of stopping mid-phase:

```
/goal "Claude has narrated a successful plan commit (with commit hash) and reported the Phase 4 reflection sub-agent verdicts inline" /superpowers:writing-plans <design-path>
```

`/goal` is a **user-typed outer wrapper** — it must prefix the invocation; a skill cannot enable it for itself mid-run. The evaluator judges only what Claude narrates in the transcript (it does NOT read files or run commands) — phrase the condition against narrated output (the commit hash, the literal Phase 4 reflection summary), never filesystem state, which is unverifiable and will time out. Full semantics, condition phrasing, and bail-out interaction: `../../skills/references/goal-wrapper.md`.

## CRITICAL: Bail-Out Check (run first)

**Read `bdd-specs.md` from the resolved design folder. Count `Scenario:` occurrences. Bail out — do NOT decompose tasks — when EITHER:**

- BDD scenarios in `bdd-specs.md` < 3, **OR**
- Total estimated task count < 5 (use `2× BDD scenarios + 1 setup task` as a rough estimate; if the design `_index.md` carries an explicit "Task Estimate" hint, prefer that)

The OR-gate (was AND prior to v2.8.0) catches the common "2 BDD + many setup tasks" shape where the AND-gate previously let thin designs through into the full 6-phase pipeline.

**Bail-out response (output verbatim):**

> Design too thin for full task-decomposition pipeline (BDD < 3 OR estimated tasks < 5). Drafting a one-page lightweight plan inline instead. To force the full pipeline, re-invoke as `/superpowers:writing-plans --force <design-path>`.

Then write a single `_index.md` (no per-task files, no Phase 4 reflection, no plan evaluator) and exit. The `--force` token (literal in `$ARGUMENTS`, case-sensitive, matched as a whole token — not a substring of other words) bypasses this check.

## CRITICAL: Justification Check (run after bail-out)

**Read `_index.md` from the resolved design folder. Bail out — do NOT decompose tasks — when grep matches any of:**

```bash
grep -nE "STATUS:.*NOT.JUSTIFIED|DESIGN-NOT-YET-JUSTIFIED|DESIGN-CONSIDERED-DEFERRED|DO NOT IMPLEMENT" "<resolved-design-folder>/_index.md"
```

This catches designs the maintainer or a prior brainstorming sub-agent has explicitly marked as "not approved to advance" (see `docs/retros/checklists/design-v1.md` JUST-01 for full semantics, and `docs/retros/2026-05-09-v3-considered-deferred.md` for the inciting case). The marker is dispositive — do not interpret it away.

**On match, refuse deterministically (the marker is dispositive — do not interpret it away)**:

1. Output a one-line note explaining the matched line + path: `Refusing: <design-path>/_index.md:{N} is marked NOT-JUSTIFIED — '{matched text}'. Re-invoke /superpowers:brainstorming to revise the design, or pass --justify-override to bypass this gate.`
2. Exit without proceeding.

**Override**: Pass `--justify-override` (literal token in `$ARGUMENTS`, case-sensitive, whole-token match) to bypass this refusal. When the override token is present, continue to First Action.

**PROHIBITED**: Do NOT conflate `--force` (which bypasses the bail-out size gate above) with `--justify-override` (which bypasses this justification gate). They are independent failure modes and need independent overrides — a user passing `--force` for a thin design should still be refused if the design is also NOT-JUSTIFIED.

## First Action — Resolve Design Path

1. Resolve the design path:
   - If `$ARGUMENTS` provides a path (e.g., `docs/plans/YYYY-MM-DD-topic-design/`), use it
   - Otherwise, pick the `*-design/` folder whose basename sorts last under `YYYY-MM-DD-*-design/` — i.e., the highest date prefix in the name, not filesystem mtime. Use `ls -1d docs/plans/*-design/ 2>/dev/null | sort | tail -1` (do NOT use `ls -t` / `ls -1dt` — directory mtimes get bumped when an older folder's files are edited, which makes it rank above a freshly-created folder). Use the result directly; do NOT pause to confirm.
   - If no `*-design/` folder exists in `docs/plans/`, refuse with: `Refusing: no design folder found under docs/plans/. Run /superpowers:brainstorming first, or pass the design folder path explicitly.` Then exit.
2. Proceed to Initialization in the same turn.

## Initialization

1. **Design Check**: Verify the folder contains `_index.md` and `bdd-specs.md`.
2. **Context**: Read `bdd-specs.md` completely. This is the source of truth for your tasks.

## Background Knowledge

**Core Concept**: Explicit over implicit, granular tasks, verification-driven, context independence.

- **MANDATORY**: Tasks driven by BDD scenarios (Given/When/Then); Test-First (Red→Green); one task per `.md` file; `_index.md` references all task files.
- **MANDATORY**: Unit-test tasks require external dependency isolation with test doubles (DB/network/third-party APIs).
- **PROHIBITED**: Implementation bodies in task files — no function logic, no algorithm code. Interface signatures belong in the task's `## Interfaces` block (Phase 2 step 6), not inline prose.

## Phase 1: Plan Structure

Define goal, architecture, constraints, and context.

1. **Read Specs**: Read `bdd-specs.md` from the design folder (generated by `superpowers:brainstorming`).
2. **Draft Structure**: Use `./references/structure-template.md` to outline the plan.
3. **Write Context Section**: Populate the `## Context` section in `_index.md`:
   - State why this work is needed (motivation, constraints, prior incidents).
   - If modifying existing code, add a current-state vs target-state comparison table covering key dimensions (module structure, API shape, behavior, etc.). Omit the table for greenfield work.
4. **Write Global Constraints Section**: Populate the `## Global Constraints` section in `_index.md` — the cross-task invariants (performance budgets, security baselines, compatibility targets, forbidden dependencies/patterns) every batch and every task must respect. These shared guardrails make parallel batches safe. One invariant per bullet, no prose; omit the section only when the design carries zero cross-cutting constraints (rare). Categories and examples: `./references/structure-template.md` §Global Constraints.

## Phase 2: Task Decomposition

Break into small tasks mapped to specific BDD scenarios.

**PROHIBITED**: Do not ask the user to choose task granularity, approve decomposition, or confirm the plan mid-process. Apply the rules in steps 1-7 below plus these additions automatically; the Phase 4 sub-agent reflection is the quality gate and the post-commit `git show` diff is the user's audit surface. There is no in-skill approval step.

- Foundation tasks (setup, shared schema, types, config, storage) take lower `NNN` before feature pairs
- Bundle all scenarios of a Feature into one test file; split only when the Feature crosses independent service boundaries (e.g., frontend vs backend)

1. **Reference Scenarios**: **CRITICAL**: Every task must explicitly include the full BDD Scenario content in the task file using Gherkin syntax. For example:

   ```gherkin
   ## BDD Scenario

   Scenario: [concise scenario title]
     Given [context or precondition]
     When [action or event occurs]
     Then [expected outcome]
     And [additional conditions or outcomes]
   ```

   The scenario content should be self-contained in the task file, not just a reference to `bdd-specs.md`. This allows the executor to see the complete scenario without switching files.
2. **Define Verification**: **CRITICAL**: Verification steps must run the BDD specs (e.g., `npm test tests/login.spec.ts`).
3. **Enforce Ordering**: For each feature NNN, the test task (`task-NNN-<feature>-test`) must precede its paired impl task (`task-NNN-<feature>-impl`) via `depends-on`.
4. **Declare Dependencies**: **MANDATORY**: Each task file must include a `**depends-on**` field listing only **true technical prerequisites** — tasks whose output is required before this task can start. Rules:
   - A test task (Red) for feature X has no dependency on test tasks for other features
   - An implementation task (Green) depends only on its paired test task (Red), not on other features' implementations
   - Tasks that touch different files and test different scenarios are independent by default
   - **PROHIBITED**: Do not chain tasks sequentially just to impose execution order — use `depends-on` only when there is a real technical reason (e.g., "implement auth middleware" must precede "implement protected route test")
5. **Create Task Files**: **MANDATORY**: Create one `.md` file per task. Filename pattern: `task-<NNN>-<feature>-<type>.md`.
   - Example: `task-001-setup.md`, `task-002-feature-test.md`, `task-002-feature-impl.md`
   - `<NNN>`: Sequential number (001, 002, ...)
   - `<feature>`: Feature identifier (e.g., auth-handler, user-profile)
   - `<type>`: Type (test, impl, config, refactor)
   - **Test and implementation tasks for the same feature share the same NN prefix**, e.g., `002-feature-test` and `002-feature-impl`
   - **Right-sizing**: Do NOT manufacture standalone setup/config/docs tasks when their only consumer is a single feature task — fold setup/config/docs into the task that needs them. A standalone `task-001-setup` is justified only when 2+ downstream tasks share its output. Pseudo-independent setup tasks create false parallelism and inflate batch counts.
6. **Declare Interfaces**: **MANDATORY**: Each task file includes a `## Interfaces` section (after `## BDD Scenario`) declaring the contracts this task exposes or consumes — function signatures, type definitions, API endpoints, event names, CLI flags. Tasks linked via `depends-on` connect through these Interfaces blocks, so parallel batches can verify interface compatibility before merge. This lifts the "ALLOWED interface signatures" rule from optional to required-in-this-block.
7. **Describe What, Not How**: **PROHIBITED**: Do not generate implementation bodies. Describe what to implement (e.g., "Create a function that validates user credentials"). **ALLOWED**: Interface signatures in the `## Interfaces` block define contracts (e.g., `def validate_credentials(username: str, password: str) -> bool: ...`), but never the body logic.

## Phase 3: Validation & Documentation

Verify completeness, save, advance to Phase 4 in the same iteration.

1. **Verify**: Check for valid commit boundaries and no vague tasks. If validation fails (vague tasks present, commit boundaries unclear), do NOT pause — re-enter Phase 2 in the same iteration to fix the offending tasks, then re-verify.
2. **Save**: Write to `docs/plans/YYYY-MM-DD-<topic>-plan/` folder.
   - **CRITICAL**: `_index.md` MUST include "Execution Plan" section with **inline YAML metadata** (see template in `./references/structure-template.md`)
   - **CRITICAL**: `_index.md` MUST include "Task File References" section with links to full task files for detailed BDD scenarios
   - **CRITICAL**: `_index.md` MUST include "BDD Coverage" section confirming all scenarios are covered
   - **CRITICAL**: `_index.md` MUST include "Dependency Chain" section with visual dependency graph (will be populated in Phase 4)
   - Example YAML metadata:
     ```yaml
     tasks:
       - id: "001"
         subject: "Setup project structure"
         slug: "setup-project-structure"
         type: "setup"
         depends-on: []
       - id: "002"
         subject: "Whale Discovery Test"
         slug: "whale-discovery-test"
         type: "test"
         depends-on: ["001"]
       - id: "003"
         subject: "Whale Discovery Impl"
         slug: "whale-discovery-impl"
         type: "impl"
         depends-on: ["002"]
     ```
   - Example file reference:
     `- [Task 002: Whale Discovery Test](./task-002-whale-discovery-test.md)`

## Phase 4: Plan Reflection

Before committing, verify plan quality with parallel fresh sub-agents. Each sub-agent runs in an isolated context (context reset — no pollution from the main planning session).

Launch these three sub-agents in parallel using the Agent tool with `subagent_type=general-purpose`:

**Sub-agent 1: BDD Coverage Review**
- Focus: Verify every BDD scenario from design has corresponding tasks
- Output: Coverage matrix, orphaned scenarios, extra tasks without scenarios

**Sub-agent 2: Dependency Graph Review**
- Focus: Verify depends-on fields are correct, check for cycles, identify missing dependencies
- Output: Dependency graph, cycle detection, incorrect dependencies

**Sub-agent 3: Task Completeness Review**
- Focus: Verify each task has required structure (BDD scenario, files, steps, verification)
- Output: Incomplete tasks list, missing sections by task

**Additional sub-agents (launch as needed)**: Red-Green Pairing Review, File Conflict Review.

**Integrate and Update**:
1. Collect all sub-agent findings
2. Prioritize issues by impact
3. Update plan files to fix issues
4. **MANDATORY**: Add dependency graph from Sub-agent 2 to `_index.md` in "Dependency Chain" section
5. Re-verify updated sections
6. **Record reflection summary inline** in your turn output (1-line per sub-agent verdict + what was changed). This summary is the audit trail the user reads post-commit via `git show`; do NOT pause for approval.

**Output**: Updated plan with issues resolved, dependency graph included in `_index.md`, reflection summary recorded inline, ready for Phase 5 commit.

**Mid-stream cancellation** (only possible when wrapped in `/goal`; on a re-prompt turn the user injects "abort", "cancel", "start over"):
- Stop with a one-line cancellation note. Do not commit; do not advance to Phase 5. The user re-invokes the skill with the new framing if they want to retry.

**Multi-turn resumption** (only applicable when wrapped in `/goal` and the prior turn was interrupted): on re-entry, **do not restart from Phase 1**. The filesystem already records prior progress:

1. `Glob "docs/plans/*-plan/_index.md"` to find the in-progress plan folder.
2. Read `_index.md` and list the task files alongside — that's the current Phase 2 output.
3. Decide the next phase from observed state:
   - Task files exist but `_index.md` lacks the YAML `tasks:` block or "Task File References" / "BDD Coverage" sections → Phase 3 (Validation), then proceed to Phase 4.
   - `_index.md` complete but no "Dependency Chain" graph → Phase 4 (reflection sub-agents).
   - Plan complete, no commit → Phase 5. Already committed → Phase 6 transition.

See `./references/reflection.md` for sub-agent prompts and integration workflow.

The sub-agents above are the sole reviewer for plan quality. There is no separate formal plan-mode evaluator — structural checks (BDD coverage, dependency graph, task completeness) are fully covered by sub-agent reflection, and the user reviews post-commit via `git show`. Sub-agents read `docs/retros/checklists/plan-v{N}.md` as their rubric; their findings are the verdict. If any sub-agent returns FAIL on a checklist item, fix the offending plan files in Phase 4 step 3 and rerun the affected sub-agent before advancing to Phase 5 — do NOT commit a plan with an unaddressed FAIL.

**Auto-seed checklist when missing**: before spawning the reflection sub-agents, if no `plan-v{N}.md` exists, run `bash "${CLAUDE_PLUGIN_ROOT}/lib/seed-checklists.sh" plan docs/retros/checklists/plan-v1.md`. Exit codes: 0 = seeded, 3 = already exists (proceed with existing file), 1/2 = abort. Then pass the resolved checklist path to each reflection sub-agent prompt — see `./references/reflection.md` for the prompt template.

**MUST: each reflection sub-agent prompt MUST include an instruction to read the resolved checklist file and apply each item as a binary PASS/FAIL rubric.** The prompt template in `references/reflection.md` carries this directive — do not strip it when adapting the prompts. A sub-agent that ignores the checklist produces an unanchored opinion, not an evaluator verdict.

## Phase 5: Git Commit

Commit the plan folder using git-agent (with git fallback).

**Actions**:
1. Stage and commit the entire folder in ONE chained command — a standalone `git add` is denied by the git plugin's hook: `git add docs/plans/YYYY-MM-DD-<topic>-plan/ && git-agent commit --no-stage --intent "add implementation plan for <topic>" --co-author "Claude <Model> <Version> <noreply@anthropic.com>"`
2. On auth error, retry with `--free` flag
3. **Fallback**: If git-agent is unavailable or fails, invoke the `/git:commit` skill via the Skill tool; full ladder in `../../skills/references/git-commit.md`

See `../../skills/references/git-commit.md` for detailed patterns.

## Phase 6: Transition to Execution

Output the transition message:

> Plan complete. To execute this plan, use `/superpowers:executing-plans`.

**PROHIBITED**: Do NOT offer to start implementation directly.

## Exit Criteria

Plan created with clear goal/constraints, decomposed tasks with file lists and verification, BDD steps, commit boundaries, no vague tasks, reflection completed, sub-agent FAILs all addressed, git commit landed.

## References

- `./references/structure-template.md` - Template for plan structure
- `./references/task-granularity-and-verification.md` - Guide for task breakdown and verification
- `./references/reflection.md` - Sub-agent prompts for plan reflection
- `../../skills/references/git-commit.md` - Git commit patterns and requirements
- `../../skills/references/goal-wrapper.md` - `/goal` wrapper semantics and condition phrasing (shared)
