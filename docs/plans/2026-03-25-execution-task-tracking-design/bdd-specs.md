# BDD Specifications

## Feature: Execution Task Tracking

### Scenario: Initialize task tracking

```gherkin
Given executing-plans is in Phase 2 (Task Creation)
And all tasks have been created via TaskCreate
When Claude calls manage-execution-tasks.sh init with task JSON array
Then the state file should contain execution_tasks array
And each task should have status "pending"
And each task should have a file path
And completed_at should be null for all tasks
```

### Scenario: Mark task in progress

```gherkin
Given execution_tasks exist in state file
And task "001" has status "pending"
When Claude calls manage-execution-tasks.sh start "001"
Then task "001" status should be "in_progress"
And other tasks should remain unchanged
```

### Scenario: Mark task completed

```gherkin
Given execution_tasks exist in state file
And task "001" has status "in_progress"
When Claude calls manage-execution-tasks.sh complete "001"
Then task "001" status should be "completed"
And task "001" completed_at should be set to current UTC timestamp
```

### Scenario: Reject completing a pending task

```gherkin
Given execution_tasks exist in state file
And task "001" has status "pending"
When Claude calls manage-execution-tasks.sh complete "001"
Then the script should exit with error
And output "Error: task 001 is still pending, must be in_progress first"
And task "001" status should remain "pending"
```

### Scenario: Reject completing a non-existent task

```gherkin
Given execution_tasks exist in state file
And no task with id "999" exists
When Claude calls manage-execution-tasks.sh complete "999"
Then the script should exit with error
And output "Error: task 999 not found"
```

### Scenario: Show progress

```gherkin
Given execution_tasks has 8 tasks total
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
And execution_tasks has 3/8 completed
When the stop hook fires (promise not found)
Then system message should include "Progress: 3/8 tasks completed"
And the loop should continue normally
```

### Scenario: Promise detected with all tasks complete

```gherkin
Given superpower loop is active for executing-plans
And execution_tasks has 8/8 completed
And last assistant message contains <promise>EXECUTION_COMPLETE</promise>
When the stop hook fires
Then the loop should exit normally
And loop fields should be cleared
And fall through to vet verification
```

### Scenario: Promise detected with incomplete tasks

```gherkin
Given superpower loop is active for executing-plans
And execution_tasks has 6/8 completed
And last assistant message contains <promise>EXECUTION_COMPLETE</promise>
When the stop hook fires
Then the loop should NOT exit
And system message should contain "EXECUTION BLOCKED"
And system message should list the 2 incomplete tasks
And the loop should continue
```

### Scenario: Non-executing-plans loop (no execution_tasks)

```gherkin
Given superpower loop is active for brainstorming
And state file has no execution_tasks field
And last assistant message contains <promise>BRAINSTORMING_COMPLETE</promise>
When the stop hook fires
Then the loop should exit normally (no task verification)
```
