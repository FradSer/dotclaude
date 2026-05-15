---
name: writing-plans
description: Creates executable implementation plans that break down designs into detailed tasks. This skill should be used when the user has completed a brainstorming design and asks to "write an implementation plan" or "create step-by-step tasks" for execution.
argument-hint: [design-folder-path]
user-invocable: true
allowed-tools: ["Read", "Write", "Edit", "Glob", "Grep", "Agent", "AskUserQuestion", "Bash(git-agent:*)", "Bash(git:*)", "Bash(${CLAUDE_PLUGIN_ROOT}/scripts/setup-superpower-loop.sh:*)", "Bash(${CLAUDE_PLUGIN_ROOT}/lib/seed-checklists.sh:*)", "Bash(${CLAUDE_PLUGIN_ROOT}/lib/bail-log.sh:*)"]
---

# Writing Plans

Create executable implementation plans that reduce ambiguity for whoever executes them using Superpower Loop for continuous iteration.

## CRITICAL: Bail-Out Check (run first)

**Read `bdd-specs.md` from the resolved design folder. Count `Scenario:` occurrences. Bail out — do NOT start the loop, do NOT decompose tasks — when EITHER:**

- BDD scenarios in `bdd-specs.md` < 3, **OR**
- Total estimated task count < 5 (use `2× BDD scenarios + 1 setup task` as a rough estimate; if the design `_index.md` carries an explicit "Task Estimate" hint, prefer that)

The OR-gate (was AND prior to v2.8.0) catches the common "2 BDD + many setup tasks" shape where the AND-gate previously let thin designs through into the full 6-phase pipeline.

**Bail-out response (output verbatim):**

> Design too thin for full task-decomposition pipeline (BDD < 3 OR estimated tasks < 5). Drafting a one-page lightweight plan inline instead. To force the full pipeline, re-invoke as `/superpowers:writing-plans --force <design-path>`.

Then write a single `_index.md` (no per-task files, no Phase 4 reflection, no plan evaluator) and exit. The `--force` token (literal in `$ARGUMENTS`, case-sensitive, matched as a whole token — not a substring of other words) bypasses this check.

**Log the bail outcome** before exiting (and on `--force` override) so retrospective Phase 5a can spot frequent overrides:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/lib/bail-log.sh" writing-plans <event> "<short reason>" "$ARGUMENTS"
```

Where `<event>` is `bail_out` when the gate fires or `force_override` when `--force` bypasses it.

## CRITICAL: Justification Check (run after bail-out, before loop start)

**Read `_index.md` from the resolved design folder. Bail out — do NOT start the loop, do NOT decompose tasks — when grep matches any of:**

```bash
grep -nE "STATUS:.*NOT.JUSTIFIED|DESIGN-NOT-YET-JUSTIFIED|DESIGN-CONSIDERED-DEFERRED|DO NOT IMPLEMENT" "<resolved-design-folder>/_index.md"
```

This catches designs the maintainer or a prior brainstorming sub-agent has explicitly marked as "not approved to advance" (see `docs/retros/checklists/design-v1.md` JUST-01 for full semantics, and `docs/retros/2026-05-09-v3-considered-deferred.md` for the inciting case). The marker is dispositive — do not interpret it away.

**On match, use AskUserQuestion (NOT plain text) to surface the gate**:

- Question: "_index.md is marked NOT-JUSTIFIED at line {N}: '{matched text}'. The maintainer or a prior brainstorming sub-agent has signalled this design should not advance to plan-writing. How do you want to proceed?"
- Options:
  - **Refuse — return to brainstorming or activate gate (default)**: emit a one-line note explaining the matched line + path, log via `bail-log.sh` with reason `design_not_justified`, then exit without starting the loop:
    ```bash
    bash "${CLAUDE_PLUGIN_ROOT}/lib/bail-log.sh" writing-plans bail_out "design_not_justified: <matched marker>" "$ARGUMENTS"
    ```
  - **Override — proceed despite NOT-JUSTIFIED status**: log the override and continue to First Action below. Use `force_override` event:
    ```bash
    bash "${CLAUDE_PLUGIN_ROOT}/lib/bail-log.sh" writing-plans force_override "design_not_justified: <matched marker>" "$ARGUMENTS"
    ```

**PROHIBITED**: Do NOT silently skip the gate when `--force` is passed (the `--force` flag bypasses the bail-out size gate above, NOT this justification gate — they are independent failure modes). Do NOT prompt the user for an override default value other than "Refuse" — the default is intentionally conservative so a user pressing through without reading still gets blocked.

The gate is non-destructive: it surfaces the situation and lets the user choose. The "Override" path produces a `force_override` audit row so retrospective Phase 5a can spot designs that were advanced despite NOT-JUSTIFIED status.

## CRITICAL: First Action - Resolve Design Path and Start Superpower Loop

**Resolve the design path, then unconditionally start the loop — do NOT read design files fully or explore the codebase first.**

1. Resolve the design path:
   - If `$ARGUMENTS` provides a path (e.g., `docs/plans/YYYY-MM-DD-topic-design/`), use it
   - Otherwise, search `docs/plans/` for the most recent `*-design/` folder matching `YYYY-MM-DD-*-design/`
   - If found without explicit argument, confirm with user: "Use this design: [path]?"
   - If not found or user declines, ask the user for the design folder path
2. **Start the loop** (no size gate — this skill's default user plans large multi-scenario work):
   ```bash
   "${CLAUDE_PLUGIN_ROOT}/scripts/setup-superpower-loop.sh" "Write an implementation plan for: <resolved-design-path>. Continue progressing through the superpowers:writing-plans skill phases: Phase 1 (Plan Structure) → Phase 2 (Task Decomposition) → Phase 3 (Validation) → Phase 4 (Plan Reflection) → Phase 5 (Git Commit) → Phase 6 (Transition). Emit <promise>PLAN_COMPLETE</promise> as your final line immediately after the Phase 5 commit succeeds — do not run an extra validation/polish pass." --completion-promise "PLAN_COMPLETE" --max-iterations 50
   ```
3. Only after the loop is running, proceed with Initialization below

## Initialization

(The Superpower Loop and design path were resolved in the first action above — do NOT start the loop again)

1. **Design Check**: Verify the folder contains `_index.md` and `bdd-specs.md`.
2. **Context**: Read `bdd-specs.md` completely. This is the source of truth for your tasks.

The loop will continue through all phases until `<promise>PLAN_COMPLETE</promise>` is output.

## Background Knowledge

**Core Concept**: Explicit over implicit, granular tasks, verification-driven, context independence.

- **MANDATORY**: Tasks must be driven by BDD scenarios (Given/When/Then).
- **MANDATORY**: Test-First (Red-Green) workflow. Verification tasks must precede implementation tasks.
- **MANDATORY**: When plans include unit tests, require external dependency isolation with test doubles (DB/network/third-party APIs).
- **PROHIBITED**: Do not generate implementation bodies — no function logic, no algorithm code.
- **ALLOWED**: Interface signatures, type definitions, and function signatures that define the contract (e.g., `async function improve(params: ImproveParams): Promise<Result>`).
- **MANDATORY**: One task per file. Each task gets its own `.md` file.
- **MANDATORY**: _index.md contains overview and references to all task files.

## Phase 1: Plan Structure

Define goal, architecture, constraints, and context.

1. **Read Specs**: Read `bdd-specs.md` from the design folder (generated by `superpowers:brainstorming`).
2. **Draft Structure**: Use `./references/structure-template.md` to outline the plan.
3. **Write Context Section**: Populate the `## Context` section in `_index.md`:
   - State why this work is needed (motivation, constraints, prior incidents).
   - If modifying existing code, add a current-state vs target-state comparison table covering key dimensions (module structure, API shape, behavior, etc.). Omit the table for greenfield work.

## Phase 2: Task Decomposition

Break into small tasks mapped to specific BDD scenarios.

**PROHIBITED**: Do not ask the user to choose task granularity or approve decomposition mid-process. Apply the rules in steps 1-6 below plus these additions automatically; user approval comes on the completed plan (Phase 3) and after reflection (Phase 4).

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
6. **Describe What, Not How**: **PROHIBITED**: Do not generate implementation bodies. Describe what to implement (e.g., "Create a function that validates user credentials"). **ALLOWED**: Include interface signatures to define contracts (e.g., `def validate_credentials(username: str, password: str) -> bool: ...`), but never the body logic.

## Phase 3: Validation & Documentation

Verify completeness, confirm with user, and save.

1. **Verify**: Check for valid commit boundaries and no vague tasks.
2. **Confirm**: Use AskUserQuestion to get user approval on the plan. AskUserQuestion pauses within the turn, ensuring the user can respond before the loop re-injects.
3. **Save**: Write to `docs/plans/YYYY-MM-DD-<topic>-plan/` folder.
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
6. **Confirm with user**: Use AskUserQuestion to present the reflection summary and get approval before committing

**Output**: Updated plan with issues resolved, dependency graph included in `_index.md`, and user approval received.

**On user rejection in Phase 3 or Phase 4 AskUserQuestion**:
- Rejection in Phase 3 (`Confirm` step): user disagrees with task list. Re-enter Phase 2 — regenerate task decomposition with the user's objections as new constraints. Do not just re-run validation.
- Rejection in Phase 4 (`Confirm with user` step): user disagrees with reflection conclusions. Re-enter Phase 4 — relaunch the 3 sub-agents with the user's specific objections appended to each sub-agent prompt as additional review criteria.
- Cancellation ("abort", "cancel", "start over"): emit `<promise>PLAN_COMPLETE</promise>` after a one-line cancellation note. Do not commit; do not advance to Phase 5.
- The Stop hook will re-inject the original prompt; route the next iteration based on which phase the rejection targeted, not blindly re-run the full pipeline.

**Loop stall recovery**: when a re-injection arrives with no fresh artifact list and just the `Continue superpowers:writing-plans (iter X/Y). Re-check SKILL.md...` header, **do not restart from Phase 1**. The state file's `modified_files` and the actual filesystem already record prior progress:

1. `Glob "docs/plans/*-plan/_index.md"` to find the in-progress plan folder.
2. Read `_index.md` and list the task files alongside — that's the current Phase 2 output.
3. Decide the next phase from observed state:
   - Task files exist but `_index.md` lacks the YAML `tasks:` block or "Task File References" / "BDD Coverage" sections → Phase 3 (Validation), then AskUserQuestion confirm.
   - `_index.md` complete but no "Dependency Chain" graph → Phase 4 (reflection sub-agents).
   - Plan complete, no commit → Phase 5. Already committed → Phase 6 transition + `<promise>PLAN_COMPLETE</promise>`.

If the Stop hook **force-clears** the loop with a `Superpower Loop force-cleared: stalled N iterations...` systemMessage, treat that as a hard reset signal — the loop will not auto-restart. Either re-invoke `/superpowers:writing-plans <path>` explicitly, or finish the remaining phases inline without the loop.

See `./references/reflection.md` for sub-agent prompts and integration workflow.

The sub-agents above are the sole reviewer for plan quality. There is no separate formal plan-mode evaluator — structural checks (BDD coverage, dependency graph, task completeness) are fully covered by sub-agent reflection, and the user gates commit via the Phase 4 AskUserQuestion confirmation. Sub-agents read `docs/retros/checklists/plan-v{N}.md` as their rubric; their findings are the verdict.

**Auto-seed checklist when missing**: before spawning the reflection sub-agents, if no `plan-v{N}.md` exists, run `bash "${CLAUDE_PLUGIN_ROOT}/lib/seed-checklists.sh" plan docs/retros/checklists/plan-v1.md`. Exit codes: 0 = seeded, 3 = already exists (proceed with existing file), 1/2 = abort. Then pass the resolved checklist path to each reflection sub-agent prompt — see `./references/reflection.md` for the prompt template.

**MUST: each reflection sub-agent prompt MUST include an instruction to read the resolved checklist file and apply each item as a binary PASS/FAIL rubric.** The prompt template in `references/reflection.md` carries this directive — do not strip it when adapting the prompts. A sub-agent that ignores the checklist produces an unanchored opinion, not an evaluator verdict.

## Phase 5: Git Commit

Commit the plan folder using git-agent (with git fallback).

**Actions**:
1. Stage the entire folder: `git add docs/plans/YYYY-MM-DD-<topic>-plan/`
2. Run: `git-agent commit --no-stage --intent "add implementation plan for <topic>" --co-author "Claude <Model> <Version> <noreply@anthropic.com>"`
3. On auth error, retry with `--free` flag
4. **Fallback**: If git-agent is unavailable or fails, use `git commit -m "docs: add implementation plan for <topic> ..."` with conventional format

See `../../skills/references/git-commit.md` for detailed patterns.

## Phase 6: Transition to Execution

Prompt the user to use `superpowers:executing-plans`, then output the promise as the absolute last line.

Output in this exact order:
1. Transition message: "Plan complete. To execute this plan, use `/superpowers:executing-plans`."
2. `<promise>PLAN_COMPLETE</promise>` — nothing after this

**PROHIBITED**: Do NOT offer to start implementation directly. Do NOT output any text after the promise tag.

## Exit Criteria

Plan created with clear goal/constraints, decomposed tasks with file lists and verification, BDD steps, commit boundaries, no vague tasks, reflection completed, user approval.

## References

- `./references/structure-template.md` - Template for plan structure
- `./references/task-granularity-and-verification.md` - Guide for task breakdown and verification
- `./references/reflection.md` - Sub-agent prompts for plan reflection
- `../../skills/references/git-commit.md` - Git commit patterns and requirements
- `../../skills/references/loop-patterns.md` - Completion promise design, prompt patterns, and safety nets
