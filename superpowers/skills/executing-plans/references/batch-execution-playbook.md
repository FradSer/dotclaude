# Batch Execution Playbook

## Overview

Load plan, create task tracking, identify batches, execute in parallel or serial, report between batches.

**Core principle:** Parallel execution for independent tasks, serial for dependent tasks.

## The Process

### Step 1: Load and Understand Plan
1. Read all plan files (`_index.md` and task files)
2. Understand scope, architecture, and dependencies
3. Explore relevant codebase files to understand existing patterns

### Step 2: Create Tasks and Scope Batches (MANDATORY)

**REQUIRED**: Create task tracking and identify batches using `TaskCreate` before any execution.

1. Use `TaskCreate` for each task in the plan
2. Load both `superpowers:agent-team-driven-development` and `superpowers:behavior-driven-development` skills
3. Group independent tasks into parallel batches (3-6 tasks per batch)

| Criterion | Parallel Batch | Serial Batch |
|-----------|---------------|--------------|
| Dependencies | None between tasks | Some tasks depend on others |
| File conflicts | No shared files | Shared files that cannot be split |

### Step 3: Batch Execution Loop (MANDATORY)

#### Execution Mode Decision Tree

```
Is this a Red-Green pair (test + impl, same NNN prefix)?
  YES → Red-Green Pair mode
  NO  → Does the batch have 2+ tasks?
          YES → Parallel mode (Agent Team for 3+, subagents for 2)
          NO  → Linear mode
```

#### Red-Green Pair Mode

For test+impl pairs sharing the same NNN prefix:

1. Assign test task to first agent — writes failing test, confirms Red state
2. Once Red confirmed, assign impl task to second agent — implements to pass
3. Multiple pairs across batches run in parallel
4. Non-negotiable: overrides all other mode selection for that pair

#### Parallel Mode (Default)

For independent multi-task batches:

1. **Plan**: Use `EnterPlanMode` to plan batch execution, define file ownership
2. **Approve**: Use `ExitPlanMode` to get approval
3. **Launch**: Create Agent Team (3+ tasks) or subagents (2 tasks)
   - If agents edit overlapping files, add `isolation: "worktree"` for isolation
4. **Assign**: Give each agent its task with full context and file boundaries
5. **Wait**: Wait for all agents to complete
6. **Verify**: Run verification commands for all tasks
7. **Complete**: Use `TaskUpdate` to mark tasks completed

#### Linear Mode (Last Resort)

For single-task batches or unavoidable sequential dependencies:

1. Plan and get approval
2. Execute task directly or via single subagent following BDD principles
3. Verify and mark complete

#### Between Batches

- Report progress and verification results
- Get user confirmation before next batch

### Step 4: Report and Continue

After each batch: show what was implemented, show verification output, get feedback, apply changes if needed, continue to next batch.

### Step 5: Complete Development

After all tasks verified: run full test suite, report completion and results.

## Verification Gate

Every task MUST pass before being marked `completed`.

| Check | How to Verify | On Failure |
|-------|--------------|------------|
| Exit code | Command exits 0 | Retry; escalate after 2 attempts |
| Test output | All assertions pass | Fix failing tests |
| No stubs | No TODO/FIXME/pass-only bodies | Complete implementation |

**Retry**: Fix and re-run immediately (max 2 retries, then escalate per `blocker-and-escalation.md`).

NEVER mark a task `completed` after a failed verification.

### Anti-Stub Checklist

Before calling any task done:
- [ ] File has more than import/type-declaration lines
- [ ] No function body is solely `pass`, `...`, `raise NotImplementedError`, or hardcoded default
- [ ] No `TODO`/`FIXME` comments as only block content
- [ ] Tests execute real logic (not just `assert True`)

## Agent Prompt Template

Every agent/teammate prompt MUST include all three sections:

```
## Task Assignment

[Full task file content]

## Quality Requirements (MANDATORY)

You MUST produce complete, working implementation code — not stubs, skeletons, or placeholders.
Every function body must contain real logic, not `pass`, `...`, `TODO`, or a hardcoded stub return.
If you cannot implement something completely, stop and report a blocker; do NOT write a stub.

## Verification (MANDATORY BEFORE REPORTING DONE)

After implementation, run the following verification commands and confirm they all pass (exit code 0, no test failures):

[Verification commands from task file]

Report the actual command output. Do not report completion until all verification commands pass.
```

Omitting any section is a protocol violation.

## When to Stop

**STOP immediately when:**
- Blocker mid-batch (missing dependency, repeated test failure, unclear instruction)
- Plan has critical gaps
- Verification fails repeatedly

**Ask for clarification rather than guessing.**
