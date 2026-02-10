---
name: executing-plans
description: This skill should be used when the user has a completed implementation plan (plan.md) and is ready to execute the tasks defined therein. Supports both serial and parallel (Agent Team) execution.
argument-hint: [plan-folder-path]
user-invocable: true
version: 1.1.0
---

# Executing Plans

Execute written implementation plans in predictable batches. Supports **Serial Execution** (single subagent) or **Parallel Execution** (Agent Teams).

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

## Phase 1: Plan Review

Read plan, identify ambiguities, clarify before proceeding.

1. **Validate**: Use the Plan agent (EnterPlanMode) to validate the plan and execution strategy before creating any tasks.
2. **Check Blockers**: See `./references/blocker-and-escalation.md`.

## Phase 2: Task Setup

Prepare the task tracking system.

1. **Create Tasks**: Use `TaskCreate` tool to create tasks from the plan.
2. **Scope Batches**: Identify batch boundaries and verify prerequisites.

## Phase 3: Batch Execution

Execute the defined scope.

- **Serial**: Standard BDD loop.
- **Parallel**: Create Agent Team using Skill tool load `superpowers:agent-team-driven-development` skill, assign tasks, wait for completion.

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
