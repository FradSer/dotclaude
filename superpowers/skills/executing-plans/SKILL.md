---
name: executing-plans
description: This skill should be used when the user has a completed implementation plan (plan.md) and is ready to execute the tasks defined therein. For each task, enters Plan Mode, then executes using Agent Teams or subagents following BDD/TDD principles.
argument-hint: [plan-folder-path]
user-invocable: true
version: 1.4.0
---

# Executing Plans

Execute written implementation plans task by task. For each task, enters Plan Mode, then executes using Agent Teams or subagents following BDD/TDD principles.

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
2. **Scope Batches**: Identify batch boundaries and verify prerequisites.

## Phase 3: Task Execution Loop

Execute tasks one by one using Plan Mode for each.

**REQUIRED**: Load both skills before executing any task:
- `superpowers:agent-team-driven-development` - Provides team coordination guidance
- `superpowers:behavior-driven-development` - Provides BDD/TDD workflow guidance

**For Each Task**:
1. **Enter Plan Mode**: Use `EnterPlanMode` to plan the implementation of this specific task
2. **Exit Plan Mode**: Use `ExitPlanMode` to get user approval on the task plan
3. **Execute**: After plan approval, execute using:
   - **Serial**: Single session/subagent following `behavior-driven-development` principles
   - **Parallel**: Agent Team following `agent-team-driven-development` guidance
4. **Verify**: Run verification commands from the task definition
5. **Mark Complete**: Update task tracker and proceed to next task

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
