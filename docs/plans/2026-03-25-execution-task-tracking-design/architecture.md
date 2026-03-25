# Architecture

## Component Interaction

```mermaid
sequenceDiagram
    participant C as Claude
    participant S as SKILL.md
    participant M as manage-execution-tasks.sh
    participant SF as superpowers.json
    participant SH as stop-hook.sh

    Note over S: Phase 2: Task Creation
    C->>M: init '[{id,subject,file}]'
    M->>SF: Write execution_tasks array

    Note over S: Phase 3: Batch Execution
    loop For each task
        C->>M: start "001"
        M->>SF: status = "in_progress"
        C->>C: Execute task + verification
        C->>M: complete "001"
        M->>SF: status = "completed", completed_at = now
    end

    Note over SH: Stop hook fires
    SH->>SF: Read execution_tasks
    alt Promise found
        alt All tasks completed
            SH->>SH: Clear loop fields, fall through to vet
        else Incomplete tasks
            SH->>C: BLOCK - list incomplete tasks
        end
    else No promise
        SH->>C: Continue loop (show progress in system message)
    end
```

## Files Modified

| File | Change |
|------|--------|
| `scripts/manage-execution-tasks.sh` | New script |
| `hooks/stop-hook.sh` | Add execution_tasks progress + completion gate |
| `skills/executing-plans/SKILL.md` | Add script calls in Phase 2 and Phase 3 |
| `lib/utils.sh` | No changes needed (existing functions sufficient) |

## State File Schema

```
superpowers.json
├── session_id          (shared)
├── created_at          (shared)
├── updated_at          (shared)
├── active              (loop)
├── iteration           (loop)
├── max_iterations      (loop)
├── completion_promise  (loop)
├── prompt              (loop)
├── started_at          (loop)
├── skill_name          (loop)
├── task                (vet)
├── pending_prompt      (vet)
├── modified_files      (vet)
├── skip_turn           (vet)
└── execution_tasks     (NEW - execution tracking)
    └── [{id, subject, file, status, completed_at}]
```

## Script Interface

```bash
# Initialize with task list (Phase 2)
manage-execution-tasks.sh init '<json-array>'

# Mark task in progress (Phase 3, step 2a)
manage-execution-tasks.sh start <task-id>

# Mark task completed (Phase 3, step 2e)
manage-execution-tasks.sh complete <task-id>

# Show progress summary
manage-execution-tasks.sh status
```

## stop-hook Integration Points

Two integration points in stop-hook.sh Phase 1 (loop check):

1. **System message enhancement** (line ~151): When building system message for loop continuation, read `execution_tasks` and append progress count.

2. **Promise verification gate** (line ~116-122): When `COMPLETION_PROMISE == "EXECUTION_COMPLETE"` and promise IS found, additionally check `execution_tasks`. If any task is not `completed`, treat as promise NOT found (continue loop with error message).
