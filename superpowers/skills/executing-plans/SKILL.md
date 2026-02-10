---
name: executing-plans
description: This skill should be used when the user has a completed implementation plan (plan.md) and is ready to execute the tasks defined therein. Actively uses Agent Teams or subagents to execute batches of independent tasks in parallel, following BDD/TDD principles.
argument-hint: [plan-folder-path]
user-invocable: true
version: 1.5.0
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
3. **Mode Check**: Decide between Serial or Parallel execution based on task independence.

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

1. **Create Tasks**: **MANDATORY** - Use `TaskCreate` tool to create tasks from the plan. Each task in the plan must be created as a separate task with:
   - `subject`: Brief title in imperative form (e.g., "Implement login handler")
   - `description`: Detailed task description from plan, including files, verification steps, and BDD scenario reference
   - `activeForm`: Present continuous form for progress display (e.g., "Implementing login handler")
2. **Scope Batches**: **MANDATORY** - Identify batch boundaries and verify prerequisites.
   - Group independent tasks that can be executed in parallel
   - Identify task dependencies and blockers
   - Create batches: each batch should contain 3-6 independent tasks

## Phase 3: Batch Execution Loop

Execute tasks in batches. Actively use parallel execution for independent tasks.

**REQUIRED**: Load both skills before executing any batch:
- `superpowers:agent-team-driven-development` - Provides team coordination guidance
- `superpowers:behavior-driven-development` - Provides BDD/TDD workflow guidance

**For Each Batch**:

1. **Identify Execution Mode**:
   - **Parallel Batch**: Tasks are independent (no file conflicts, no dependencies) -> Use Agent Team
   - **Serial Batch**: Tasks have dependencies or file conflicts -> Execute one by one

2. **Parallel Execution (Preferred when possible)**:
   - Use `EnterPlanMode` to plan the batch execution strategy
   - Use `ExitPlanMode` to get approval on the batch plan
   - Create Agent Team with teammates for parallel execution
   - Assign tasks to teammates with clear file ownership boundaries
   - Wait for teammates to complete all tasks
   - Verify all tasks in the batch
   - Mark tasks complete

3. **Serial Execution (When necessary)**:
   - For each task in the batch:
     - Use `EnterPlanMode` to plan the implementation
     - Use `ExitPlanMode` to get approval on the task plan
     - Execute using subagent following `behavior-driven-development` principles
     - Verify the task
     - Mark task complete

4. **Between Batches**:
   - Report progress and verification results
   - Get user confirmation before proceeding to next batch

See `./references/batch-execution-playbook.md`.

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
