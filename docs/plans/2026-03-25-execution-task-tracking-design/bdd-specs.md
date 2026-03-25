# BDD Specifications

## Feature: Execution State File Management

### Scenario: Initialize execution state

```gherkin
Given executing-plans is in Phase 2 (Task Creation)
And all tasks have been created via TaskCreate
When Claude calls manage-execution-tasks.sh init with skill, plan-path, and task JSON array
Then .claude/.execution-state.json should be created
And the file should contain session_id, skill, plan_path, and tasks array
And each task should have status "pending"
And each task should have a file path
And completed_at should be null for all tasks
```

### Scenario: Mark task in progress

```gherkin
Given .claude/.execution-state.json exists
And task "001" has status "pending"
When Claude calls manage-execution-tasks.sh start "001"
Then task "001" status should be "in_progress"
And other tasks should remain unchanged
```

### Scenario: Mark task completed

```gherkin
Given .claude/.execution-state.json exists
And task "001" has status "in_progress"
When Claude calls manage-execution-tasks.sh complete "001"
Then task "001" status should be "completed"
And task "001" completed_at should be set to current UTC timestamp
```

### Scenario: Reject completing a pending task

```gherkin
Given .claude/.execution-state.json exists
And task "001" has status "pending"
When Claude calls manage-execution-tasks.sh complete "001"
Then the script should exit with error
And output "Error: task 001 is still pending, must be in_progress first"
And task "001" status should remain "pending"
```

### Scenario: Reject completing a non-existent task

```gherkin
Given .claude/.execution-state.json exists
And no task with id "999" exists
When Claude calls manage-execution-tasks.sh complete "999"
Then the script should exit with error
And output "Error: task 999 not found"
```

### Scenario: Show progress

```gherkin
Given .claude/.execution-state.json has 8 tasks total
And 3 tasks have status "completed"
And 2 tasks have status "in_progress"
And 3 tasks have status "pending"
When Claude calls manage-execution-tasks.sh status
Then output should show "Progress: 3/8 tasks completed"
And list each task with its status
```

## Feature: Stop Hook Task Verification

### Scenario: Loop iteration with task progress

```gherkin
Given superpower loop is active for executing-plans
And .claude/.execution-state.json has 3/8 tasks completed
When the stop hook fires (promise not found)
Then system message should include "Progress: 3/8 tasks completed"
And the loop should continue normally
```

### Scenario: Promise detected with all tasks complete

```gherkin
Given superpower loop is active for executing-plans
And .claude/.execution-state.json has 8/8 tasks completed
And skill_name in superpowers.json is "/superpowers:executing-plans"
And last assistant message contains <promise>EXECUTION_COMPLETE</promise>
When the stop hook fires
Then the task gate passes (all tasks completed)
And .claude/.execution-state.json is deleted
And loop fields are cleared from superpowers.json
And skill_name matches *executing-plans glob pattern
And stop hook exits with code 0 (vet skipped)
```

### Scenario: Promise detected with incomplete tasks

```gherkin
Given superpower loop is active for executing-plans
And .claude/.execution-state.json has 6/8 tasks completed
And last assistant message contains <promise>EXECUTION_COMPLETE</promise>
When the stop hook fires
Then the loop should NOT exit
And system message should contain "EXECUTION BLOCKED"
And system message should list the 2 incomplete tasks
And .claude/.execution-state.json should NOT be deleted
And the loop should continue
```

### Scenario: No .execution-state.json present (non-executing-plans)

```gherkin
Given superpower loop is active for brainstorming
And .claude/.execution-state.json does not exist
And last assistant message contains <promise>BRAINSTORMING_COMPLETE</promise>
When the stop hook fires
Then the task gate is skipped (file absent)
And loop fields are cleared from superpowers.json
And skill_name "/superpowers:brainstorming" matches *brainstorming glob pattern
And stop hook exits with code 0 (vet skipped)
```

### Scenario: Execution state file deleted on verified completion

```gherkin
Given .claude/.execution-state.json exists with 8/8 tasks completed
And last assistant message contains <promise>EXECUTION_COMPLETE</promise>
When the stop hook fires and task gate passes
Then stop hook deletes .claude/.execution-state.json
And the file no longer exists after hook completes
And the next execution run starts clean (no stale state)
```

## Feature: Stop Hook No-Vet Bypass

### Scenario: brainstorming skips vet on completion

```gherkin
Given superpower loop is active for brainstorming
And skill_name in superpowers.json is "/superpowers:brainstorming"
And .claude/.execution-state.json does not exist
And last assistant message contains <promise>BRAINSTORMING_COMPLETE</promise>
When the stop hook fires
Then loop fields are cleared
And skill_name matches the *brainstorming glob pattern
And stop hook exits with code 0
And vet verification phase is not triggered
```

### Scenario: writing-plans skips vet on completion

```gherkin
Given superpower loop is active for writing-plans
And skill_name in superpowers.json is "/superpowers:writing-plans"
And .claude/.execution-state.json does not exist
And last assistant message contains <promise>PLAN_COMPLETE</promise>
When the stop hook fires
Then loop fields are cleared
And skill_name matches the *writing-plans glob pattern
And stop hook exits with code 0
And vet verification phase is not triggered
```

### Scenario: executing-plans skips vet on completion (all tasks done)

```gherkin
Given superpower loop is active for executing-plans
And skill_name in superpowers.json is "/superpowers:executing-plans"
And .claude/.execution-state.json has all tasks with status "completed"
And last assistant message contains <promise>EXECUTION_COMPLETE</promise>
When the stop hook fires
Then task gate passes
And .claude/.execution-state.json is deleted
And loop fields are cleared
And skill_name matches the *executing-plans glob pattern
And stop hook exits with code 0
And vet verification phase is not triggered
```

### Scenario: Exact match pattern fails for prefixed skill_name

```gherkin
Given superpower loop is active for brainstorming
And skill_name in superpowers.json is "/superpowers:brainstorming"
And stop-hook case statement uses exact pattern "brainstorming" (no glob)
And last assistant message contains <promise>BRAINSTORMING_COMPLETE</promise>
When the stop hook fires
Then loop fields are cleared
And skill_name "/superpowers:brainstorming" does NOT match exact pattern "brainstorming"
And stop hook falls through to Phase 2 (vet verification)
And vet verification incorrectly blocks exit
```

Note: This scenario documents the silent failure mode. Always use trailing-glob patterns (`*brainstorming`) not exact patterns (`brainstorming`). The `*` glob in bash `case` matches zero or more characters, so `*brainstorming` matches both `/superpowers:brainstorming` and plain `brainstorming`.

### Scenario: Unknown skill falls through to vet

```gherkin
Given superpower loop is active for a non-superpowers skill
And skill_name in superpowers.json is "other-skill"
And last assistant message contains the loop completion promise
When the stop hook fires
Then loop fields are cleared
And skill_name does not match any no-vet glob pattern
And stop hook falls through to Phase 2 (vet verification)
And verification system message is shown to Claude
```

## Feature: Enforcement Integrity

### Scenario: Claude outputs promise without marking tasks complete

```gherkin
Given .claude/.execution-state.json exists
And task "001" has status "in_progress" (start was called, complete was not)
And task "002" has status "pending"
And Claude outputs <promise>EXECUTION_COMPLETE</promise>
When the stop hook fires
Then the task gate reads .execution-state.json
And tasks "001" and "002" are not "completed"
And stop hook blocks exit with "EXECUTION BLOCKED: 2 tasks not completed"
And .claude/.execution-state.json is NOT deleted
And the loop continues
```
