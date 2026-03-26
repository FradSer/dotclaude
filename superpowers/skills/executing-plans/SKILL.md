---
name: executing-plans
description: Executes written implementation plans efficiently using agent teams or subagents. This skill should be used when the user has a completed plan.md, asks to "execute the plan", or is ready to run batches of independent tasks in parallel following BDD principles.
argument-hint: [plan-folder-path]
user-invocable: true
allowed-tools: ["TaskCreate", "TaskUpdate", "TaskList", "TaskGet", "Read", "Glob", "Grep", "Agent", "Bash(git-agent:*)", "Bash(git:*)", "Bash(${CLAUDE_PLUGIN_ROOT}/scripts/setup-superpower-loop.sh:*)"]
---

# Executing Plans

Execute written implementation plans efficiently using Superpower Loop for continuous iteration through all phases.

## CRITICAL: First Action - Start Superpower Loop NOW

**Resolve the plan path and start the loop immediately — do NOT read plan files, explore the codebase, or do anything else first.**

1. Resolve the plan path:
   - If `$ARGUMENTS` provides a path (e.g., `docs/plans/YYYY-MM-DD-topic-plan/`), use it
   - Otherwise, search `docs/plans/` for the most recent `*-plan/` folder matching `YYYY-MM-DD-*-plan/`
   - If found without explicit argument, confirm with user: "Execute this plan: [path]?"
   - If not found or user declines, ask the user for the plan folder path
2. Immediately run:
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/setup-superpower-loop.sh" "Execute the plan at <resolved-plan-path>. Continue progressing through the superpowers:executing-plans skill phases: Phase 1 (Plan Review) → Phase 2 (Task Creation) → Phase 3-4 loop (Batch Execution + Verification, repeat per batch) → Phase 5 (Git Commit) → Phase 6 (Completion)." --completion-promise "EXECUTION_COMPLETE" --max-iterations 100
```
3. Only after the loop is running, proceed with Initialization below

**The loop enables self-referential iteration throughout the execution process.**

## Superpower Loop Integration

This skill uses Superpower Loop to enable self-referential iteration throughout the execution process.

**CRITICAL**: Throughout the process, you MUST output `<promise>EXECUTION_COMPLETE</promise>` only when:
- Phase 1-5 (Plan Review, Task Creation, Batch Execution, Verification, Git Commit) are all complete
- All tasks executed and verified
- All tasks marked `completed` (verified via TaskList — zero tasks with `in_progress` or `pending` status)
- User approval received in Phase 4
- Git commit completed

Do NOT output the promise until ALL conditions are genuinely TRUE.

**ABSOLUTE LAST OUTPUT RULE**: The promise tag MUST be the very last text you output. Output any transition messages or instructions to the user BEFORE the promise tag. Nothing may follow `<promise>EXECUTION_COMPLETE</promise>`.

## Initialization

(The Superpower Loop and plan path were resolved in the first action above — do NOT start the loop again)

1. **Plan Check**: Verify the folder contains `_index.md` with "Execution Plan" section.
2. **Context**: Read `_index.md` completely. This is the source of truth for your execution.

The loop will continue through all phases until `<promise>EXECUTION_COMPLETE</promise>` is output.

## Background Knowledge

**Core Principles**: Review before execution, batch verification, explicit blockers, evidence-driven approach.

**MANDATORY SKILLS**: Both `superpowers:agent-team-driven-development` and `superpowers:behavior-driven-development` must be loaded regardless of execution mode.

## Definition of Done

These rules are non-negotiable and override all other guidance.

**PROHIBITED outputs** — a task MUST NOT be marked `completed` if it produces any of the following:
- Stub files: files containing only function signatures, `pass`, or `...` with no logic
- Placeholder implementations: `TODO`, `FIXME`, `NotImplemented`, `raise NotImplementedError`, or equivalent in any language
- Empty function bodies: functions that return a hardcoded default or `None`/`null` without executing real logic
- Skeleton-only files: files with only imports, type declarations, or class definitions but no method bodies

**A task is "done" only when ALL of the following are true:**
1. Verification commands from the task file exit with code 0
2. Expected output matches actual output (no test failures, no assertion errors)
3. No prohibited patterns exist in any file written during the task

**On verification failure:**
- The task MUST remain `in_progress`
- Fix the issue and re-run verification
- If blocked after two retries, escalate per `./references/blocker-and-escalation.md`
- NEVER mark a task `completed` after a failed verification

## Phase 1: Plan Review & Understanding

1. **Read Plan**: Read `_index.md` to understand scope, architecture decisions, and extract inline YAML task metadata from the "Execution Plan" section.
2. **Understand Project**: Explore codebase structure, key files, and patterns relevant to the plan.
3. **Check Blockers**: See `./references/blocker-and-escalation.md`.

## Phase 2: Task Creation (MANDATORY)

**CRITICAL**: You MUST use TaskCreate to create ALL tasks BEFORE executing any task. Task creation must complete before dependency analysis or execution begins.

1. **Extract Tasks from _index.md**: Read `_index.md` only. Parse the inline YAML metadata in the "Execution Plan" section to extract:
   - `id`: Task identifier (e.g., "001")
   - `subject`: Brief title in imperative form (e.g., "Implement login handler")
   - `slug`: Hyphenated slug for filename (e.g., "implement-login-handler")
   - `type`: Task type (test, impl, setup, config, refactor)
   - `depends-on`: Array of task IDs this task depends on (e.g., ["001"])

2. **Create Tasks First**: Use TaskCreate to register every task
   - Set `subject` from YAML `subject` field
   - Set `description` to: "See task file: ./task-{id}-{slug}-{type}.md for full details including BDD scenario and verification steps"
   - Set `activeForm` by converting subject to present continuous form (e.g., "Setting up project structure")
   - All tasks MUST be created before proceeding to the next phase
   - Do NOT read individual task files during this phase — they are read on-demand during execution

3. **Analyze Dependencies**: After all tasks are created, build the dependency graph
   - Compute dependency tiers: Tier 0 = no dependencies, Tier N = all depends-on tasks are in earlier tiers
   - Within each tier, group tasks by type to maximize parallelism (e.g., all "write test" tasks together, all "implement" tasks together)
   - **Identify Red-Green Pairs**: Scan all task filenames for matching NNN prefixes (e.g., `task-002-auth-test` + `task-002-auth-impl`). Mark each such pair as a **Red-Green pair** — these are always scheduled as a coordinated unit in the same batch. The test task retains its Tier 0 position; the impl task follows immediately after in the same batch execution (not a separate batch).
   - **Target**: Each batch should contain 3-6 tasks
   - **Rule**: Every batch must contain ≥2 tasks unless it is the sole remaining batch

4. **Setup Task Dependencies**: Use TaskUpdate to configure dependencies between tasks
   - `addBlockedBy`: Array of task IDs this task must wait for before starting
   - `addBlocks`: Array of task IDs that must wait for this task to complete
   - Example: `TaskUpdate({ taskId: "2", addBlockedBy: ["1"] })` means task #2 waits for task #1

## Phase 3: Batch Execution Loop

Execute tasks in batches using Agent Teams or subagents for parallel execution.

**For Each Batch**:

1. **Choose Execution Mode** (decision tree):
   - **Red-Green Pair**: If the batch contains a Red-Green pair (same NNN prefix, one `test` + one `impl`), assign exactly two dedicated agents — one per task. The test agent runs first and confirms Red state; then the impl agent starts. Multiple pairs run in parallel. Non-negotiable for any test+impl pair.
   - **Parallel** (default for all other multi-task batches): Use Agent Team for 3+ tasks, or plain subagents for exactly 2 tasks. If agents edit overlapping files, use worktree isolation (`isolation: "worktree"`) as an option within this mode — not a separate mode. File conflicts within a batch should be resolved by splitting the batch further when possible.
   - **Linear** (last resort): Only when the batch has a single task or unavoidable sequential dependencies that cannot be split. State the reason explicitly.

2. **For Each Task in Batch**:

   a. **Mark Task In Progress**: Use TaskUpdate to set status to `in_progress`

   b. **Read Task Context**: Read the task file to get full context (subject, description, BDD scenario, verification steps)

   c. **Execute Task**: Based on execution mode:

      **Mandatory prompt content** — regardless of execution mode, every agent/teammate prompt MUST include:
      1. Full task file content (subject, description, BDD scenario, verification commands)
      2. The Quality Requirements block: "You MUST produce complete, working implementation code — not stubs, skeletons, or placeholders. Every function body must contain real logic. If you cannot implement something completely, stop and report a blocker."
      3. The Verification block: "After implementation, run the verification commands below and confirm they all pass (exit code 0, no test failures). Report the actual command output. Do NOT report completion until all verification commands pass."

      See `./references/batch-execution-playbook.md` — "Agent Prompt Template" section — for the full required template.

      **For Agent Team / Worktree mode**:
      - Create team if not already created
      - Assign task to available teammate using the mandatory prompt template above
      - Wait for teammate to complete and report verification output

      **For Subagent mode**:
      - Launch subagent using the mandatory prompt template above
      - Wait for subagent to complete and report verification output

      **For Linear mode**:
      - Execute task directly in current session
      - Follow BDD scenario and verification steps
      - Run verification commands and capture output

   d. **Verification Gate**: Run all verification commands from the task file. Capture the actual output.
      - For test tasks: Confirm test fails for the right reason (Red state confirmed)
      - For impl tasks: Confirm all tests pass (Green state confirmed, exit code 0)
      - For other tasks: Confirm verification command exits 0 and output matches expected

      **HARD GATE**: If ANY verification step fails (non-zero exit, test failure, unexpected output):
      - The task MUST remain `in_progress`
      - Fix the issue and re-run verification (up to two retries)
      - If still failing after two retries, escalate per `./references/blocker-and-escalation.md`
      - NEVER proceed to step 2e while any verification is failing

   e. **Mark Task Complete**: Only after ALL verification steps in 2d pass, use TaskUpdate to set status to `completed`. Include in the update: which verification commands ran and that they passed.

3. **Batch Completion**: After all tasks in batch complete, report progress and proceed to next batch

See `./references/batch-execution-playbook.md` for detailed execution patterns.

## Phase 4: Verification & Feedback

Close the loop with structured evidence.

1. **Publish Evidence**: For each completed task in the batch, output a structured evidence block:
   ```
   Task [ID]: [subject]
   Verification command: <command run>
   Output: <actual output, truncated to last 20 lines if long>
   Status: PASS / FAIL
   ```
   Any task without a PASS evidence block is NOT verified. Do not proceed to confirmation until all tasks have PASS status.

2. **Confirm**: Use AskUserQuestion to present the evidence summary and ask: "All tasks in this batch verified. Proceed to the next batch?" AskUserQuestion pauses within the turn, ensuring the user can respond before the loop re-injects. Get explicit confirmation before continuing.

3. **Loop**: Repeat Phase 3-4 until all batches complete.

## Phase 5: Git Commit

Commit the implementation changes using git-agent (with git fallback).

**Actions**:
1. Run: `git-agent commit --intent "<feature description>" --co-author "Claude <Model> <Version> <noreply@anthropic.com>"`
2. On auth error, retry with `--free` flag
3. **Fallback**: If git-agent is unavailable or fails, stage files with `git add` and use `git commit` with conventional format

See `../../skills/references/git-commit.md` for detailed patterns, commit message templates, and requirements.

**Critical requirements**:
- Commit only after Phase 4 user confirmation
- Commit should reflect the completed feature, not individual tasks
- Use meaningful scope (e.g., `feat(auth):`, `feat(ui):`, `feat(db):`)

## Phase 6: Completion

Verify all tasks are complete, then output the promise as the absolute last line.

1. **Final Task Audit**: Use TaskList to confirm every task has status `completed`. If any task is `in_progress` or `pending`, do NOT proceed — return to Phase 3 to finish remaining tasks.
2. Summary message: "Plan execution complete. All [N] tasks verified and committed."
3. `<promise>EXECUTION_COMPLETE</promise>` — nothing after this

**PROHIBITED**: Do NOT output the promise tag if TaskList shows any non-completed tasks. Do NOT output any text after the promise tag.

## Exit Criteria

All tasks executed and verified, evidence captured, no blockers, user approval received, final verification passes, git commit completed.

## References

- `./references/blocker-and-escalation.md` - Guide for identifying and handling blockers
- `./references/batch-execution-playbook.md` - Pattern for batch execution
- `../../skills/references/git-commit.md` - Git commit patterns and requirements (shared cross-skill resource)
- `../../skills/references/loop-patterns.md` - Completion promise design, prompt patterns, and safety nets
