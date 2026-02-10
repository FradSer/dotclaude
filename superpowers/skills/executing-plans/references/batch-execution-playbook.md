# Executing Plans Details (1/2)

# Detailed Guidance

This file preserves the previously detailed SKILL.md guidance for deeper reference.

# Executing Plans

## Overview

Load plan, review critically, execute tasks in batches, report for review between batches.

**Core principle:** Batch execution with checkpoints for architect review.

**Announce at start:** "I'm using the executing-plans skill to implement this plan."

## The Process

### Step 1: Load and Understand Plan
1. Read all plan files (`_index.md` and task files)
2. Understand the project scope, architecture, and dependencies
3. Review critically - identify any questions or concerns about the plan
4. Explore relevant codebase files to understand existing patterns

### Step 2: Create Tasks (MANDATORY)

**REQUIRED**: Before any execution begins, create task tracking system using `TaskCreate`.

1. **MANDATORY**: Use `TaskCreate` tool to create tasks from the plan
   - Each task in the plan becomes a separate task entry
   - Include: `subject` (imperative), `description` (from plan), `activeForm` (continuous)
2. **MANDATORY**: Load both skills before proceeding:
   - `superpowers:agent-team-driven-development` - Provides team coordination guidance
   - `superpowers:behavior-driven-development` - Provides BDD/TDD workflow guidance

**Per-Task Execution Pattern**:
For **each task** in the plan:

1. **Enter Plan Mode**: Use `EnterPlanMode` to plan the implementation of this specific task
2. **Execute**: After plan approval, execute using:

**Option A: Serial Mode (Single Task/Subagent)**
Use when: Task must be done individually or is part of a serial sequence.
1. Mark as in_progress.
2. **REQUIRED:** Follow `superpowers:behavior-driven-development` skill for implementation.
3. Verify and mark as completed.

**Option B: Parallel Mode (Agent Team)**
Use when: Multiple tasks can be done in parallel (e.g., "Create 5 separate handlers").

**1. Create Team:**
Use a prompt with **"agent team"** or **"teammates"** to initialize the team.

*Pattern:*
```
Create an agent team to [Goal].
```

*Examples:*
- "Create an agent team to refactor these modules in parallel."
- "Create an agent team with 3 teammates: one for frontend, one for backend, one for testing."

**2. Assign Tasks (Context Isolation):**
Assign tasks with clear boundaries. Ensure teammates work on different files or logical units to prevent conflicts.

*Pattern:*
```
Assign [Task ID] to [Teammate Name]. Context: [Specific File/Module]. Constraint: "Only edit [X], do not touch [Y]."
```

*Key Principle:* **Isolation**. Give each teammate only the context they need. Avoid overlapping file edits.

**3. Wait:**
```
Wait for your teammates to complete their tasks before proceeding.
```

**4. Verify:**
Run verification commands to confirm all teammates' work.


### Step 3: Per-Task Execution Loop

For each task in the task tracking system:
1. **Enter Plan Mode**: Use `EnterPlanMode` to plan the implementation of this specific task
2. **Exit Plan Mode**: Use `ExitPlanMode` to get user approval on the task plan
3. **Execute**: After plan approval, execute (Serial or Parallel as decided)
4. **Verify**: Run verification commands from the task definition
5. **Mark Complete**: Use `TaskUpdate` to mark task as completed, proceed to next task

### Step 4: Report
After completing a batch of tasks (or when user requests review):
- Show what was implemented
- Show verification output
- Say: "Ready for feedback."

### Step 5: Continue
Based on feedback:
- Apply changes if needed
- Continue to next task(s)
- Repeat until all tasks complete

### Step 5: Complete Development

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
