# Best Practices

## Anti-Lying Enforcement

### The Problem

Claude can output `<promise>EXECUTION_COMPLETE</promise>` at any time to exit the loop, even if tasks are not genuinely complete. Internal task tracking (TaskUpdate) is invisible to hooks.

### The Solution: External Verification

`manage-execution-tasks.sh` creates an external record of task completion in `.claude/.execution-state.json`. `stop-hook.sh` independently reads this file and blocks exit if the promise does not reflect reality.

### Enforcement Layers

| Layer | Mechanism | What it prevents |
|-------|-----------|-----------------|
| 1. SKILL.md instructions | "Do NOT output promise until all tasks marked complete via script" | Accidental premature promise |
| 2. Script gate | `complete` requires task to be `in_progress` first | Skipping execution entirely |
| 3. stop-hook gate | Blocks exit if any task in `.execution-state.json` is not `completed` | Lying about completion |

### Integrity Rules in SKILL.md

1. **MUST call `start` before `complete`** — prevents marking tasks done without executing them
2. **MUST run verification commands before calling `complete`** — ensures quality
3. **MUST NOT output promise with incomplete tasks** — stop-hook will block anyway
4. **The stop-hook is the final arbiter** — even if Claude believes work is done, the hook checks the file

## Task File Path Requirements

Every task in `.execution-state.json` MUST include the `file` field with relative path to the task markdown file. This enables:
- Verification that the task file was actually read
- Traceability from execution state back to plan artifacts
- Future enhancement: stop-hook could verify file existence

## Progress Visibility

The stop-hook's system message includes task progress during loop iterations:
```
Superpower loop iteration 5 | Progress: 3/8 tasks completed | To stop: output <promise>...
```

This serves dual purpose:
1. **Awareness**: Claude sees remaining work count each iteration
2. **Accountability**: Progress is externally tracked, not self-reported

## Execution State File Lifecycle

`.claude/.execution-state.json` is a runtime artifact:

| Event | Action |
|-------|--------|
| Phase 2 start | `manage-execution-tasks.sh init` creates the file |
| Phase 3 task start | `manage-execution-tasks.sh start` updates status |
| Phase 3 task done | `manage-execution-tasks.sh complete` updates status + timestamp |
| Completion verified | `stop-hook.sh` deletes the file |
| Interrupted/failed run | File remains — stop future runs from falsely passing the task gate |

**Stale file handling**: If a previous run was interrupted and `.execution-state.json` still exists from a prior session, the next execution will see incomplete tasks and be blocked. The user must manually delete `.claude/.execution-state.json` to reset.

Add `.claude/.execution-state.json` to `.gitignore` — it is a local runtime artifact, not a project artifact.

## No-Vet Bypass for Workflow Skills

### Why These Skills Skip Vet

`brainstorming`, `writing-plans`, and `executing-plans` are multi-phase workflow skills. Each phase has explicit completion criteria:

| Skill | Completion mechanism |
|-------|---------------------|
| `brainstorming` | Phase 4 (Reflection) + Phase 5 (Git Commit) + Phase 6 (Transition) |
| `writing-plans` | Phase 4 (Plan Review) + Phase 5 (Git Commit) + Phase 6 (Transition) |
| `executing-plans` | Task gate (`.execution-state.json`) + Phase 4 (Verification) + Phase 5 (Git Commit) + Phase 6 (Completion) |

The generic vet checkpoint exists to catch cases where Claude exits without genuinely finishing work. These skills already provide stronger, domain-specific verification. Running vet after them is redundant.

### Implementation

The no-vet bypass is implemented in `stop-hook.sh` after loop fields are cleared. It matches `skill_name` using trailing-glob patterns:

```bash
# skill_name set from <command-name> tag: e.g., "/superpowers:brainstorming"
# Trailing glob (*) matches regardless of plugin namespace or leading slash
case "$SKILL_NAME" in
  *brainstorming|*writing-plans|*executing-plans)
    exit 0  # Built-in phase verification — skip vet
    ;;
esac
# Other skills fall through to vet
```

### skill_name Format Warning

`task-start.sh` stores the full command path from the `<command-name>` tag (e.g., `/superpowers:brainstorming`). Always use trailing-glob patterns in `case` statements — never plain short names. Plain short names silently fail: the no-vet logic exists in code but never activates, and all three workflow skills fall through to unnecessary vet verification.

### Other Skills

Skills NOT in the bypass list fall through to the standard vet verification checkpoint. This is correct for general-purpose loops that lack built-in phase verification.
