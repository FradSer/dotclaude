# Execution Task Tracking & No-Vet Design

## Context

Two related stop-hook behaviors need explicit design documentation:

1. **External task tracking** for `executing-plans`: Claude's internal `TaskUpdate` is invisible to hooks. This design adds an external tracking file and a completion gate so `stop-hook.sh` can independently verify all tasks are done before allowing `EXECUTION_COMPLETE` to exit the loop. Task state lives in `.claude/.execution-state.json` — separate from session state, persistent within the plan, and deleted on verified completion.

2. **No-vet for workflow skills**: `brainstorming`, `writing-plans`, and `executing-plans` each have built-in phase verification. The generic vet checkpoint is redundant for these skills. When their completion promise is detected and all preconditions pass, `stop-hook.sh` MUST exit cleanly (`exit 0`) without triggering vet.

Both behaviors are implemented as part of the **loop completion path** in `stop-hook.sh`.

## Requirements

### Functional Requirements

| ID | Requirement | Priority |
|----|-------------|----------|
| F1 | `executing-plans` MUST write all tasks to `.claude/.execution-state.json` at Phase 2 start | MUST |
| F2 | `manage-execution-tasks.sh` MUST manage task lifecycle (`init`, `start`, `complete`, `status`) in `.claude/.execution-state.json` | MUST |
| F3 | `executing-plans` SKILL.md MUST call `start` before each task and `complete` after verification passes | MUST |
| F4 | `stop-hook.sh` SHOULD include task progress in the loop continuation system message | SHOULD |
| F5 | `stop-hook.sh` MUST block loop exit when `.claude/.execution-state.json` exists and any task is not `completed` | MUST |
| F6 | `stop-hook.sh` MUST delete `.claude/.execution-state.json` after all tasks complete and promise is verified | MUST |
| F7 | `brainstorming`, `writing-plans`, and `executing-plans` MUST skip vet phase when their completion promise is verified | MUST |
| F8 | `stop-hook.sh` MUST use glob trailing-match patterns for `skill_name` comparison | MUST |

### Non-Functional Requirements

| ID | Requirement | Priority |
|----|-------------|----------|
| NF1 | `.claude/.execution-state.json` MUST use a generic `tasks` schema usable by any skill, not tied to `executing-plans` | MUST |
| NF2 | Task state MUST NOT be stored in `superpowers.json` — separation of session state and plan execution state | MUST |
| NF3 | `.claude/.execution-state.json` SHOULD be gitignored — it is a runtime artifact | SHOULD |

## Rationale

- **Separate file over state file**: `superpowers.json` is session state; task execution progress is plan state. Keeping them separate avoids bloating session state and allows plan execution data to outlive session scope.
- **Deletion on completion**: `.claude/.execution-state.json` is a temporary artifact. Leaving it behind would cause false blocking on the next execution run.
- **Generic schema** (`tasks` not `execution_tasks`): Any skill that uses task tracking can reuse this file and the `manage-execution-tasks.sh` script without schema changes.
- **External enforcement** over internal claims: Claude's `TaskUpdate` is invisible to hooks; the script writes to `.execution-state.json` which hooks CAN read.
- **No-vet for workflow skills**: These skills end with explicit phase sign-off (commit + transition). The generic vet loop is unnecessary — each skill's phase structure IS the verification.
- **Glob-pattern matching**: `skill_name` is set to the full command name by `task-start.sh` (e.g., `/superpowers:brainstorming`). Exact-match patterns silently fail; trailing-glob patterns (e.g., `*brainstorming`) handle any prefix.

## Detailed Design

### Execution State File: `.claude/.execution-state.json`

Created by `manage-execution-tasks.sh init`. Deleted by `stop-hook.sh` on verified completion.

```json
{
  "session_id": "abc123",
  "skill": "executing-plans",
  "plan_path": "docs/plans/2026-03-25-my-plan/",
  "tasks": [
    {
      "id": "001",
      "subject": "Setup project structure",
      "file": "docs/plans/2026-03-25-my-plan/task-001-setup-project.md",
      "status": "pending",
      "completed_at": null
    },
    {
      "id": "002",
      "subject": "Implement auth handler",
      "file": "docs/plans/2026-03-25-my-plan/task-002-auth-handler.md",
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
| `init` | `manage-execution-tasks.sh init '<skill>' '<plan-path>' '<json-array>'` | Create `.claude/.execution-state.json` with task list |
| `start` | `manage-execution-tasks.sh start <task-id>` | Mark task as `in_progress` |
| `complete` | `manage-execution-tasks.sh complete <task-id>` | Mark task as `completed` with timestamp |
| `status` | `manage-execution-tasks.sh status` | Print progress summary |

**`init` invocation example:**
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/manage-execution-tasks.sh" init \
  "executing-plans" \
  "docs/plans/2026-03-25-my-plan/" \
  '[{"id":"001","subject":"Setup project","file":"./task-001-setup-project.md"}]'
```

The script:
- Writes to `.claude/.execution-state.json` relative to `${PWD}`
- Validates task ID exists before `start`/`complete`
- Refuses to `complete` a task still in `pending` state (must be `in_progress` first)

### stop-hook.sh: Loop Completion Path

When `LOOP_COMPLETE=true`, the stop-hook executes this sequence:

**Step 1 — Task gate** (only when `.claude/.execution-state.json` exists):
1. Read `tasks` from `.claude/.execution-state.json`
2. If any task is NOT `completed`: block exit, show error with incomplete list, continue loop
3. If all tasks completed (or file absent): proceed to Step 2

```
EXECUTION BLOCKED: 2/8 tasks not completed.
Incomplete tasks:
  - 005: Implement payment gateway (in_progress)
  - 007: Integration tests (pending)
Do NOT output <promise>EXECUTION_COMPLETE</promise> until all tasks are genuinely complete.
```

**Step 2 — Clear loop fields** from `superpowers.json`.

**Step 3 — Delete execution state** (if `.claude/.execution-state.json` exists):
```bash
rm -f ".claude/.execution-state.json"
```

**Step 4 — No-vet bypass** (skill-name check):
```bash
# skill_name set by task-start.sh from <command-name> tag: e.g., "/superpowers:brainstorming"
# Trailing-glob matches regardless of plugin prefix or leading slash
SKILL_NAME=$(state_read "$SUPERPOWER_STATE_FILE" '.skill_name // ""')
case "$SKILL_NAME" in
  *brainstorming|*writing-plans|*executing-plans)
    exit 0  # Built-in phase verification — skip vet
    ;;
esac
# Other skills fall through to vet
```

**During loop iteration** (system message — before Step 1):
When building the continuation system message, include task progress if the file exists:
```
Superpower loop iteration 5 | Progress: 3/8 tasks completed | To stop: output <promise>...
```

### executing-plans SKILL.md Changes

**Phase 2 addition** — after TaskCreate, create execution state file:
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/manage-execution-tasks.sh" init \
  "executing-plans" \
  "<plan-path>" \
  '[{"id":"001","subject":"Setup project","file":"./task-001-setup-project.md"},...]'
```

**Phase 3 addition** — for each task:
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/manage-execution-tasks.sh" start "001"
# ... execute task ...
"${CLAUDE_PLUGIN_ROOT}/scripts/manage-execution-tasks.sh" complete "001"
```

**Global anti-lying requirement** added to SKILL.md preamble:
> The stop-hook independently verifies task completion status via `.claude/.execution-state.json`. Do NOT output `<promise>EXECUTION_COMPLETE</promise>` unless all tasks are genuinely completed and marked via the tracking script. The hook will block exit if any task remains incomplete.

## Design Documents

- [BDD Specifications](./bdd-specs.md) - Behavior scenarios and testing strategy
- [Architecture](./architecture.md) - System architecture and component details
- [Best Practices](./best-practices.md) - Anti-lying enforcement and integrity guidelines
