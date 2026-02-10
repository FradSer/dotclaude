# Executing Plans Details (1/2)

# Detailed Guidance

This file preserves the previously detailed SKILL.md guidance for deeper reference.

# Executing Plans

## Overview

Load plan, create task tracking system, identify batches, execute batches in parallel or serial as appropriate, report for review between batches.

**Core principle:** Active parallel execution for independent tasks, serial execution for dependent tasks.

**Announce at start:** "I'm using the executing-plans skill to implement this plan."

## The Process

### Step 1: Load and Understand Plan
1. Read all plan files (`_index.md` and task files)
2. Understand the project scope, architecture, and dependencies
3. Review critically - identify any questions or concerns about the plan
4. Explore relevant codebase files to understand existing patterns

### Step 2: Create Tasks and Scope Batches (MANDATORY)

**REQUIRED**: Before any execution begins, create task tracking system and identify batches using `TaskCreate`.

1. **MANDATORY**: Use `TaskCreate` tool to create tasks from the plan
   - Each task in the plan becomes a separate task entry
   - Include: `subject` (imperative), `description` (from plan), `activeForm` (continuous)
   - Set task dependencies using `addBlockedBy` for tasks that depend on others

2. **MANDATORY**: Load both skills before proceeding:
   - `superpowers:agent-team-driven-development` - Provides team coordination guidance
   - `superpowers:behavior-driven-development` - Provides BDD/TDD workflow guidance

3. **MANDATORY**: Identify execution batches
   - Group independent tasks (no file conflicts, no dependencies) into parallel batches
   - Keep each batch at 3-6 tasks for optimal parallelism
   - Sequential tasks (with dependencies) go into serial batches

**Batch Identification Criteria**:

| Criterion | Parallel Batch | Serial Batch |
|-----------|---------------|--------------|
| Task dependencies | None between tasks | Some tasks depend on others |
| File conflicts | No shared files | Some files modified by multiple tasks |
| Teammate count | 3-6 teammates | Single session/subagent |

### Step 3: Batch Execution Loop (MANDATORY)

**Execute batches one by one. Actively use parallel execution for independent tasks.**

#### For Each Parallel Batch (Preferred Mode):

1. **Enter Plan Mode**: Use `EnterPlanMode` to plan the batch execution strategy
   - Identify which tasks will be assigned to which teammates
   - Define file ownership boundaries to prevent conflicts

2. **Exit Plan Mode**: Use `ExitPlanMode` to get approval on the batch plan

3. **Create Agent Team**:
   Use a prompt with **"agent team"** or **"teammates"** to initialize the team.

   *Pattern:*
   ```
   Create an agent team to execute [batch description].
   ```

   *Example:*
   "Create an agent team with 4 teammates to implement independent test cases for different modules."

4. **Assign Tasks with Context Isolation**:
   Assign tasks with clear boundaries. Ensure teammates work on different files or logical units.

   *Pattern:*
   ```
   Assign [Task ID] to [Teammate Name]. Context: [Specific File/Module]. Constraint: "Only edit [X], do not touch [Y]."
   ```

   *Key Principle:* **Isolation**. Give each teammate only the context they need.

5. **Wait for Teammates**:
   Wait for your teammates to complete all tasks in the batch.

6. **Verify Batch**:
   Run verification commands for all tasks in the batch.

7. **Mark Tasks Complete**: Use `TaskUpdate` to mark all tasks in the batch as completed

#### For Each Serial Batch (When dependencies exist):

For each task in the serial batch:
1. **Enter Plan Mode**: Use `EnterPlanMode` to plan the implementation
2. **Exit Plan Mode**: Use `ExitPlanMode` to get approval on the task plan
3. **Execute**: Use subagent following `behavior-driven-development` principles
4. **Verify**: Run verification commands
5. **Mark Task Complete**: Use `TaskUpdate` to mark task as completed

#### Between Batches:

- Report progress and verification results
- Get user confirmation before proceeding to next batch

### Step 4: Report

After completing each batch:
- Show what was implemented
- Show verification output for all tasks
- Say: "Ready for feedback on batch [N]."

### Step 5: Continue

Based on feedback:
- Apply changes if needed
- Continue to next batch
- Repeat until all batches complete

### Step 6: Complete Development

After all tasks complete and verified:
- Verify all tasks are marked as completed
- Run full test suite to ensure no regressions
- Report completion and test results to the user

## When to Stop and Ask for Help

**STOP executing immediately when:**
- Hit a blocker mid-batch (missing dependency, test fails, instruction unclear)
- Plan has critical gaps preventing starting
- You don't understand an instruction
- Verification fails repeatedly

**Ask for clarification rather than guessing.**

## When to Revisit Earlier Steps

**Return to Review (Step 1) when:**
- Partner updates the plan based on your feedback
- Fundamental approach needs rethinking

**Don't force through blockers** - stop and ask.