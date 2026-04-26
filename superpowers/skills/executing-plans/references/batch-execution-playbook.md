# Batch Execution Playbook

## Overview

This playbook defines the per-batch coordinator's internal process. It is invoked by the main executing-plans orchestrator via the Agent tool (see Phase 3 of `../SKILL.md`). The coordinator runs in a fresh isolated context and receives a self-contained prompt — the coordinator has no memory of prior conversation, only the handoff files named in its prompt.

**Coordinator inputs (from spawn prompt):**
- Plan directory path
- `sprint-contract-batch-{N}.md` path
- `handoff-state.md` path (cross-batch memory)
- Resolved `code-v{N}.md` checklist path
- Batch task ID list + execution mode + Red-Green pair annotations

**Coordinator output (structured return to main agent):**
- Verdict: PASS | REWORK_ESCALATED | PIVOT
- Completed task IDs, evidence blocks, modified files
- Evaluation report path, recurring patterns, pivot recommendation (if any)

**Core principle:** Parallel execution for independent tasks, serial for dependent tasks. Red-Green pairs are non-negotiable.

## The Coordinator Process

### Step 1: Load Context

1. Read `handoff-state.md` to learn prior batches' modified files, decisions, recurring patterns
2. Read `sprint-contract-batch-{N}.md` for this batch's scope, acceptance criteria, and Evaluation Criteria Preview
3. Read every task file for the batch (the coordinator, not the main agent, owns this reading)
4. Load `superpowers:behavior-driven-development` skill

### Step 2: Execute the Batch

#### Execution Mode Decision Tree

```
Is this a Red-Green pair (test + impl, same NNN prefix)?
  YES → Red-Green Pair mode
  NO  → Does the batch have 2+ tasks?
          YES → Parallel mode (spawn one Task sub-agent per task)
          NO  → Linear mode
```

#### Red-Green Pair Mode

For test+impl pairs sharing the same NNN prefix:

1. Assign test task to first sub-agent — writes failing test, confirms Red state
2. Once Red confirmed, assign impl task to second sub-agent — implements to pass
3. Multiple pairs across batches run in parallel
4. Non-negotiable: overrides all other mode selection for that pair

#### Parallel Mode (Default)

For independent multi-task batches:

1. **Launch**: Spawn one Task sub-agent per task via the Agent tool
   - If sub-agents edit overlapping files, add `isolation: "worktree"` for isolation
2. **Assign**: Give each sub-agent its task with full context and file boundaries
3. **Wait**: Wait for all sub-agents to complete
4. **Verify**: Run verification commands for all tasks
5. **Evaluate**: Spawn superpowers-evaluator after all tasks pass verification
6. **Complete**: Use `TaskUpdate` to mark tasks completed only after evaluator verdict is PASS

#### Linear Mode (Last Resort)

For single-task batches or unavoidable sequential dependencies:

1. Plan and get approval
2. Execute task directly or via single subagent following BDD principles
3. Verify and mark complete

#### Between Batches

- Report progress and verification results to conversation context
- Proceed directly to the next batch (no user confirmation — this skill is fully autonomous)

### Step 4: Return Structured Result

The coordinator does NOT emit prose completion messages. It returns a structured result to the main agent containing verdict, completed task IDs, evidence blocks, modified files list, evaluation report path, and any pivot recommendation. The main agent is responsible for user-facing progress output.

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

The superpowers-evaluator is a dedicated read-only sub-agent. Spawn it via the Agent tool after batch verification completes:

1. Pass context to the superpowers-evaluator:
   - Sprint contract file path: `sprint-contract-batch-{N}.md`
   - List of modified/created files from the batch
   - Plan directory path
2. The superpowers-evaluator reads the sprint contract, inspects artifacts, runs verification commands, and applies the resolved code checklist
3. The superpowers-evaluator returns report content; the executing-plans skill writes `evaluation-round-{N}-batch-{M}.md` in the plan directory

**Independence**: The superpowers-evaluator runs as its own sub-agent regardless of the execution mode used for the batch (Parallel, Linear, Red-Green). It is never fused with an implementation sub-agent.

### Reading Evaluation Results

After the superpowers-evaluator completes:

1. Read the evaluation report from the plan directory
2. Check the evaluator verdict:
   - **PASS**: All tasks accepted. Proceed to mark tasks complete and move to Phase 4 evidence.
   - **REWORK**: Read rework items (file:line references + issue descriptions). Fix the identified issues, re-run verification, then re-spawn superpowers-evaluator for another round.
   - **PIVOT**: Log the superpowers-evaluator's pivot recommendation to the evaluation report and apply it directly (do NOT prompt the user). If the recommendation is ambiguous, fall back to the rework loop.

### Rework Loop

| Round | Action |
|-------|--------|
| 1 | Fix rework items, re-verify, re-evaluate |
| 2 | Fix remaining items, re-verify, re-evaluate |
| 3+ | Log a HARD BLOCKER entry per `blocker-and-escalation.md` and abort this batch (do NOT prompt the user) |

Maximum 2 evaluation-rework rounds before escalation. The superpowers-evaluator assesses independently each round -- it does not inherit previous round results.

See `evaluation-file-formats.md` for report format details.

## Agent Prompt Template

Every sub-agent prompt MUST include all three sections:

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
