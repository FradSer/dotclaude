---
name: executing-plans
description: This skill should be used when the user has a completed implementation plan (plan.md) and is ready to execute the tasks defined therein. Actively uses Agent Teams or subagents to execute batches of independent tasks in parallel, following BDD/TDD principles.
argument-hint: [plan-folder-path]
user-invocable: true
allowed-tools: ["TaskCreate", "TaskUpdate", "TaskList", "TaskGet"]
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

## Phase 2: Task Setup (MANDATORY)

**REQUIRED**: Create task tracking system before any execution begins.

1. **Scope Batches**: Build a dependency graph from `depends-on` fields, then **actively restructure** tasks into parallel batches.
   - Compute dependency tiers: Tier 0 = no dependencies, Tier N = all `depends-on` tasks are in earlier tiers
   - Within each tier, group tasks by type to maximize parallelism (e.g., all "write test" tasks in one batch, all "implement" tasks in the next)
   - **MANDATORY**: Every batch must contain ≥2 tasks. If a tier has only 1 task, combine it with adjacent tier tasks that have no file conflicts
   - A single-task batch is only acceptable if it is the sole remaining task in the entire plan
   - Each batch should contain 3-6 tasks
2. **Create Tasks**: Use `TaskCreate` tool to register each task, in batch order. Each task must include:
   - `subject`: Brief title in imperative form (e.g., "Implement login handler")
   - `description`: Detailed task description from plan, including files, verification steps, and BDD scenario reference
   - `activeForm`: Present continuous form for progress display (e.g., "Implementing login handler")

## Phase 3: Batch Execution Loop

Execute tasks in batches. Actively use parallel execution for independent tasks.

**For Each Batch**:

1. **Choose Execution Mode** (strict priority — justify any downgrade explicitly):
   - **Agent Team** (default): Use unless a specific technical reason prevents it. File conflicts or sequential `depends-on` within a batch are NOT valid reasons to downgrade — resolve by splitting the batch further.
   - **Subagent Parallel** (downgrade only if): Agent Team overhead is disproportionate (e.g., batch has exactly 2 small tasks). State the reason explicitly.
   - **Linear** (last resort only if): Tasks within the batch have unavoidable file conflicts that cannot be split, or the batch genuinely contains only 1 task. State the reason explicitly.

2. **Agent Team Execution**:
   - Create Agent Team with teammates for parallel execution
   - Assign tasks to teammates with clear file ownership boundaries
   - Wait for teammates to complete all tasks
   - Verify all tasks in the batch
   - Mark tasks complete

3. **Subagent Parallel Execution**:
   - Spawn subagents concurrently for each independent task
   - Each subagent loads the `superpowers:behavior-driven-development` skill
   - Verify all tasks in the batch
   - Mark tasks complete

4. **Linear Execution**:
   - For each task in the batch:
     - Execute using subagent loading the `superpowers:behavior-driven-development` skill
     - Verify the task
     - Mark task complete

5. **Between Batches**:
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
3. **Update Tracker**: Mark tasks complete.
4. **Loop**: Repeat Phase 3-4 until complete.

## Exit Criteria

All tasks executed and verified, evidence captured, no blockers, user approval received, final verification passes.

## References

- `./references/blocker-and-escalation.md` - Guide for identifying and handling blockers
- `./references/batch-execution-playbook.md` - Pattern for batch execution
- `../../skills/references/git-commit.md` - Git commit patterns and requirements
