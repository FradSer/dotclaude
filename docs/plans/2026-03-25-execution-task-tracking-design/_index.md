# Execution Task Tracking Design

## Context

The `executing-plans` skill uses Claude's internal TaskCreate/TaskUpdate tools to track task progress. However, the stop-hook has no visibility into whether tasks are actually completed. Claude can claim all tasks are done and output `<promise>EXECUTION_COMPLETE</promise>` to exit the loop without genuine verification.

This design adds external task tracking in the superpowers state file, a script-based completion gate, and stop-hook enforcement to prevent premature loop exit.

## Requirements

1. **Task Registration**: When executing-plans starts Phase 2, write all tasks (with file paths) into `superpowers.json`
2. **Script-Based Completion**: Create `manage-execution-tasks.sh` to manage task status in state file
3. **SKILL.md Enforcement**: Require Claude to call the script after each task's verification passes
4. **Progress Display**: stop-hook shows task progress during loop iterations
5. **Completion Gate**: stop-hook blocks loop exit if `execution_tasks` has incomplete items
6. **Anti-Lying**: Global requirement - do not mark tasks complete to exit; the hook enforces truth

## Rationale

- **External enforcement** over internal claims: Claude's TaskUpdate is invisible to hooks; the script writes to state file which hooks CAN read
- **Explicit marking** over automatic detection: Claude must actively call the script, creating a deliberate checkpoint
- **Progress visibility** in stop-hook: shows completed/total in system message, giving Claude (and the loop) awareness of remaining work

## Detailed Design

### State File Schema Extension

```json
{
  "execution_tasks": [
    {
      "id": "001",
      "subject": "Setup project structure",
      "file": "docs/plans/2026-03-25-todo-plan/task-001-setup-project-setup.md",
      "status": "pending",
      "completed_at": null
    },
    {
      "id": "002",
      "subject": "Implement auth handler",
      "file": "docs/plans/2026-03-25-todo-plan/task-002-auth-handler-impl.md",
      "status": "completed",
      "completed_at": "2026-03-25T10:30:00Z"
    }
  ]
}
```

Status values: `pending` | `in_progress` | `completed`

### Script: `scripts/manage-execution-tasks.sh`

**Operations:**

| Command | Usage | Description |
|---------|-------|-------------|
| `init` | `manage-execution-tasks.sh init '<json-array>'` | Write initial task list to state file |
| `start` | `manage-execution-tasks.sh start <task-id>` | Mark task as `in_progress` |
| `complete` | `manage-execution-tasks.sh complete <task-id>` | Mark task as `completed` with timestamp |
| `status` | `manage-execution-tasks.sh status` | Print progress summary |

**`init` input format:**
```json
[
  {"id": "001", "subject": "Setup project", "file": "./task-001-setup-project-setup.md"},
  {"id": "002", "subject": "Auth handler", "file": "./task-002-auth-handler-impl.md"}
]
```

The script:
- Sources `lib/utils.sh` for `find_state_file`, `state_update`, `state_read`
- Uses `CLAUDE_CODE_SESSION_ID` or finds existing state file
- Validates task ID exists before `start`/`complete`
- Refuses to `complete` a task that is still `pending` (must be `in_progress` first)

### stop-hook.sh Changes

**During loop iteration** (system message enhancement):
```
Superpower loop iteration 5 | Progress: 3/8 tasks completed | To stop: output <promise>...
```

**When promise `EXECUTION_COMPLETE` detected:**
1. Read `execution_tasks` from state file
2. Check if ALL tasks have `status == "completed"`
3. If all completed: proceed normally (clear loop fields, fall through to vet)
4. If incomplete tasks exist: **block exit**, output error listing incomplete tasks, continue loop

```
EXECUTION BLOCKED: 2/8 tasks not completed.
Incomplete tasks:
  - 005: Implement payment gateway (in_progress)
  - 007: Integration tests (pending)
Do NOT output <promise>EXECUTION_COMPLETE</promise> until all tasks are genuinely complete.
```

**When skill is NOT executing-plans** (no `execution_tasks` in state): no change to behavior.

### executing-plans SKILL.md Changes

**Phase 2 addition** — after TaskCreate, register tasks in state file:
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/manage-execution-tasks.sh" init '[{"id":"001","subject":"Setup project","file":"./task-001-setup-project-setup.md"},...]'
```

**Phase 3 addition** — after each task's verification gate passes:
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/manage-execution-tasks.sh" start "001"
# ... execute task ...
"${CLAUDE_PLUGIN_ROOT}/scripts/manage-execution-tasks.sh" complete "001"
```

**Global anti-lying requirement** — added to SKILL.md preamble:
> The stop-hook independently verifies task completion status. Do NOT output `<promise>EXECUTION_COMPLETE</promise>` unless all tasks are genuinely completed and marked via the tracking script. The hook will block exit if any task remains incomplete.

## Design Documents

- [BDD Specifications](./bdd-specs.md) - Behavior scenarios and testing strategy
- [Architecture](./architecture.md) - System architecture and component details
- [Best Practices](./best-practices.md) - Anti-lying enforcement and integrity guidelines
