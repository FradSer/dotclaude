# Executing Plans Details (1/2)

# Detailed Guidance

This file preserves the previously detailed SKILL.md guidance for deeper reference.

# Executing Plans

## Overview

Load plan, review critically, execute tasks in batches, report for review between batches.

**Core principle:** Batch execution with checkpoints for architect review.

**Announce at start:** "I'm using the executing-plans skill to implement this plan."

## The Process

### Step 1: Load and Review Plan
1. Read plan file
2. Review critically - identify any questions or concerns about the plan
3. **REQUIRED**: Use the Plan agent (EnterPlanMode) to validate the plan and execution strategy.
4. If concerns: Raise them with your human partner before starting
5. If no concerns: Create TodoWrite and proceed

### Step 2: Configure Execution Mode

**Option A: Serial Mode (Single Task/Subagent)**
Use when: Tasks must be done in order or are highly coupled.
1. Mark as in_progress.
2. **REQUIRED:** Use Skill tool load `superpowers:behavior-driven-development` skill for implementation.
3. Verify and mark as completed.

**Option B: Parallel Mode (Agent Team)**
Use when: Tasks are independent (e.g., "Create 5 separate handlers").

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


### Step 3: Report
When batch complete:
- Show what was implemented
- Show verification output
- Say: "Ready for feedback."

### Step 4: Continue
Based on feedback:
- Apply changes if needed
- Execute next batch
- Repeat until complete

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
