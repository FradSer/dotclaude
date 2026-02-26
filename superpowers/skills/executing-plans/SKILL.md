---
name: executing-plans
description: This skill should be used when the user has a completed implementation plan (plan.md) and is ready to execute the tasks defined therein. Actively uses Agent Teams or subagents to execute batches of independent tasks in parallel, following BDD/TDD principles.
argument-hint: [plan-folder-path]
user-invocable: true
allowed-tools: ["TaskCreate", "TaskUpdate", "TaskList", "TaskGet", "Read", "Glob", "Grep", "Task"]
---

# Executing Plans

Execute written implementation plans efficiently. Actively use Agent Teams or subagents to execute batches of independent tasks in parallel, following BDD/TDD principles.

## Initialization

1. **Resolve Plan Path**:
   - If `$ARGUMENTS` provides a path (e.g., `docs/plans/YYYY-MM-DD-topic-plan/`), look for `_index.md` or `plan.md` inside it.
   - If no argument is provided:
     - Search `docs/plans/` for the most recent `*-plan/` folder matching the pattern `YYYY-MM-DD-*-plan/`
     - If found, confirm with user: "Execute this plan: [path]?"
     - If not found or user declines, ask the user for the plan folder path.
2. **Plan Check**: Verify the plan file exists and contains actionable tasks.

## Background Knowledge

**Core Principles**: Review before execution, batch verification, explicit blockers, evidence-driven approach.

**MANDATORY SKILLS**: Both `superpowers:agent-team-driven-development` and `superpowers:behavior-driven-development` must be loaded regardless of execution mode.

## Phase 1: Plan Review & Understanding

Read plan, understand the project and requirements.

1. **Read Plan**: Read all plan files (`_index.md` and task files) to understand the scope, architecture, and dependencies.
2. **Understand Project**: Explore codebase structure, key files, and patterns relevant to the plan.
3. **Check Blockers**: See `./references/blocker-and-escalation.md`.

## Phase 2: Task Creation (MANDATORY)

**CRITICAL**: You MUST use TaskCreate to create ALL tasks BEFORE executing any task. Task creation must complete before dependency analysis or execution begins.

1. **Extract Tasks**: Extract all tasks from the plan file. Parse each task's:
   - `subject`: Brief title in imperative form (e.g., "Implement login handler")
   - `description`: Detailed description including files, verification steps, BDD scenario reference
   - `activeForm`: Present continuous form (e.g., "Implementing login handler")
   - `depends-on`: Dependencies (if any)

2. **Create Tasks First**: Use TaskCreate tool to register every task
   - All tasks MUST be created before proceeding to the next phase
   - Do NOT execute any tasks until all tasks are created

3. **Analyze Dependencies**: After all tasks are created, build the dependency graph
   - Compute dependency tiers: Tier 0 = no dependencies, Tier N = all depends-on tasks are in earlier tiers
   - Within each tier, group tasks by type to maximize parallelism (e.g., all "write test" tasks together, all "implement" tasks together)
   - **Target**: Each batch should contain 3-6 tasks
   - **Rule**: Every batch must contain ≥2 tasks unless it is the sole remaining batch

4. **Setup Task Dependencies**: Use TaskUpdate to configure dependencies between tasks
   - `addBlockedBy`: Array of task IDs this task must wait for before starting
   - `addBlocks`: Array of task IDs that must wait for this task to complete
   - Example: `TaskUpdate({ taskId: "2", addBlockedBy: ["1"] })` means task #2 waits for task #1

## Phase 3: Batch Execution Loop

Execute tasks in batches. Actively use Agent Teams for parallel execution (preferred), with subagents or linear execution as fallbacks.

**For Each Batch**:

1. **Choose Execution Mode** (strict priority — justify any downgrade explicitly):
   - **Agent Team** (default): Use unless a specific technical reason prevents it. File conflicts or sequential `depends-on` within a batch are NOT valid reasons to downgrade — resolve by splitting the batch further.
   - **Subagent Parallel** (downgrade only if): Agent Team overhead is disproportionate (e.g., batch has exactly 2 small tasks). State the reason explicitly.
   - **Linear** (last resort only if): Tasks within the batch have unavoidable file conflicts that cannot be split, or the batch genuinely contains only 1 task. State the reason explicitly.

2. **Update Task Status**: Before starting work on any task, use TaskUpdate to set status to `in_progress`
   - This shows a spinner in the task list and signals active work

3. **Agent Team Execution**:
   - Create Agent Team with teammates for parallel execution
   - Assign tasks to teammates with clear file ownership boundaries
   - Wait for teammates to complete all tasks
   - Verify all tasks in the batch

4. **Subagent Parallel Execution**:
   - Spawn subagents concurrently for each independent task
   - Each subagent loads the `superpowers:behavior-driven-development` skill
   - Verify all tasks in the batch

5. **Linear Execution**:
   - For each task in the batch:
     - Execute using subagent loading the `superpowers:behavior-driven-development` skill
     - Verify the task

6. **Mark Tasks Complete**: After verification, use TaskUpdate to set status to `completed`
   - Only mark as completed after full verification passes

7. **Between Batches**:
   - Report progress and verification results
   - Proceed to next batch automatically

See `./references/batch-execution-playbook.md`.

## Git Commit

Commit the implementation changes to git with proper message format.

See `../../skills/references/git-commit.md` for detailed patterns, commit message templates, and requirements.

**Critical requirements**:
- Commit the implementation changes after all tasks are completed
- Prefix: `feat(<scope>):` for implementation changes
- Subject: Under 50 characters, lowercase
- Footer: Co-Authored-By with model name

**Commit timing**:
- Commit implementation changes after all tasks in the plan are completed
- Commit should reflect the completed feature, not individual tasks
- Use meaningful scope (e.g., `feat(auth):`, `feat(ui):`, `feat(db):`)

## Phase 4: Verification & Feedback

Close the loop.

1. **Publish Evidence**: Log outputs and test results.
2. **Confirm**: Get user confirmation.
3. **Loop**: Repeat Phase 3-4 until complete.

## Exit Criteria

All tasks executed and verified, evidence captured, no blockers, user approval received, final verification passes.

## References

- `./references/blocker-and-escalation.md` - Guide for identifying and handling blockers
- `./references/batch-execution-playbook.md` - Pattern for batch execution
- `../../skills/references/git-commit.md` - Git commit patterns and requirements
