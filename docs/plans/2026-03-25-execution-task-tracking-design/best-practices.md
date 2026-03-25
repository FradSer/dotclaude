# Best Practices

## Anti-Lying Enforcement

### The Problem

Claude can output `<promise>EXECUTION_COMPLETE</promise>` at any time to exit the loop, even if tasks are not genuinely complete. Internal task tracking (TaskUpdate) is invisible to hooks.

### The Solution: External Verification

The `manage-execution-tasks.sh` script creates an external record of task completion in the state file. The stop-hook independently reads this record and blocks exit if it doesn't match the promise.

### Enforcement Layers

| Layer | Mechanism | What it prevents |
|-------|-----------|-----------------|
| 1. SKILL.md instructions | "Do NOT output promise until all tasks marked complete via script" | Accidental premature promise |
| 2. Script gate | `complete` requires task to be `in_progress` first | Skipping execution entirely |
| 3. stop-hook gate | Blocks exit if any task is not `completed` | Lying about completion |

### Integrity Rules in SKILL.md

1. **MUST call `start` before `complete`** - prevents marking tasks done without executing them
2. **MUST run verification commands before calling `complete`** - ensures quality
3. **MUST NOT output promise with incomplete tasks** - stop-hook will block anyway
4. **The stop-hook is the final arbiter** - even if Claude believes work is done, the hook checks state

## Task File Path Requirements

Every task in `execution_tasks` MUST include the `file` field with relative path to the task markdown file. This enables:
- Verification that the task file was actually read
- Traceability from state file back to plan artifacts
- Future enhancement: stop-hook could verify file existence

## Progress Visibility

The stop-hook's system message includes task progress during loop iterations:
```
Superpower loop iteration 5 | Progress: 3/8 tasks completed | To stop: output <promise>...
```

This serves dual purpose:
1. **Awareness**: Claude sees remaining work count each iteration
2. **Accountability**: Progress is externally tracked, not self-reported
