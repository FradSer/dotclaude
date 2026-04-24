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

Before launching any agent or starting linear execution, write the sprint contract file for the batch using the plan tasks, task files, and relevant BDD scenarios. Execution starts only after the contract file exists.

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

- Report progress and verification results to conversation context
- Proceed directly to the next batch (no user confirmation — this skill is fully autonomous)

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

## Evaluation Mode

When the evaluator is enabled, an independent assessment step runs after each batch passes the Verification Gate.

### Evaluator Invocation

The superpowers-evaluator is a **sub-agent** (not a teammate). Spawn it via the Agent tool after batch verification completes:

1. Pass context to the superpowers-evaluator:
   - Sprint contract file path: `sprint-contract-batch-{N}.md`
   - List of modified/created files from the batch
   - Plan directory path
2. The superpowers-evaluator reads the sprint contract, inspects artifacts, runs verification commands, and scores against rubrics
3. The superpowers-evaluator returns report content; the executing-plans skill writes `evaluation-round-{N}-batch-{M}.md` in the plan directory

**Independence**: The superpowers-evaluator runs as a sub-agent regardless of the execution mode used for the batch (Parallel, Linear, Red-Green). It is never added as a teammate to an Agent Team.

### Reading Evaluation Results

After the superpowers-evaluator completes:

1. Read the evaluation report from the plan directory
2. Check the per-task verdicts:
   - **PASS**: All tasks accepted. Proceed to mark tasks complete and move to Phase 4 evidence.
   - **REWORK**: Read rework items (file:line references + issue descriptions). Fix the identified issues, re-run verification, then re-spawn superpowers-evaluator for another round.
   - **FAIL / Pivot**: Log the superpowers-evaluator's pivot recommendation to the evaluation report and apply it directly (do NOT prompt the user). If the recommendation is ambiguous, fall back to the rework loop.

### Rework Loop

| Round | Action |
|-------|--------|
| 1 | Fix rework items, re-verify, re-evaluate |
| 2 | Fix remaining items, re-verify, re-evaluate |
| 3+ | Log a HARD BLOCKER entry per `blocker-and-escalation.md` and abort this batch (do NOT prompt the user) |

Maximum 2 evaluation-rework rounds before escalation. The superpowers-evaluator assesses independently each round -- it does not inherit previous round results.

See `evaluation-file-formats.md` for report format details.

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
