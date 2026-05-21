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

## Main Agent's Direct-Edit Allow-List (Phase 3 HARD RULE)

Files the main agent may write directly during Phase 3:

- `handoff-state.md` — step 1, cross-batch memory
- `sprint-contract-batch-{N}.md` — step 0
- `evaluation-round-{N}-batch-{M}.md` — post-coordinator processing
- `_index.md` — only on PIVOT

Anything else (source, tests, configs, `__init__.py`, `pyproject.toml`, etc.) MUST go through the spawned coordinator.

Stuck-detection signals (both scoped to executing-plans, iter >= 2):

- **Edits-stuck**: `track-changes.sh` bumps `state.edits_since_last_spawn` on every `Edit`/`Write`/`MultiEdit`; `track-spawns.sh` resets it on Agent PostToolUse. >5 edits without a spawn → STUCK pointing back here.
- **Read-stuck**: `track-reads.sh` bumps `state.reads_since_last_spawn` on every `Read`/`Glob`/`Grep`/`Bash`; same reset. >15 reads without a spawn → STUCK with a recovery message naming TaskList + Agent as the legitimate next actions (not "more exploration").

Edits-stuck takes precedence when both fire — direct-edit violations are the more severe contract breach. Both counters reset together on each Agent spawn so post-spawn state starts fresh.

## ATOMIC: Phase 3 Steps 0-2 in One Response

Steps 0 (sprint contract) → 1 (handoff state) → 2 (Agent spawn) MUST execute in a single main-agent response, with the Agent tool call as the response's terminal action. Splitting across Stops re-fires the loop hook mid-setup and empirically lets the agent drift into inline batch execution between steps.

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

1. **Launch**: Spawn one Task sub-agent per task via the Agent tool, up to a **concurrency cap of 4 sub-agents per spawn round**
   - If the batch has more than 4 independent tasks, split into back-to-back spawn rounds (4 → wait → next 4) rather than spawning all at once. The cap exists because (a) more parallel sub-agents inflate the per-iteration token bill linearly and (b) the main agent's wait turn cannot meaningfully attend to >4 concurrent transcripts when a sub-agent reports a blocker.
   - If sub-agents edit overlapping files, add `isolation: "worktree"` for isolation
2. **Assign**: Give each sub-agent its task with full context and file boundaries
3. **Wait**: Wait for all sub-agents in the current round to complete before launching the next round
4. **Verify**: Run verification commands for all tasks (after the final round)
5. **Evaluate**: Spawn superpowers-evaluator after all tasks pass verification
6. **Complete**: Use `TaskUpdate` to mark tasks completed only after evaluator verdict is PASS

The cap is advisory — the harness does not yet enforce it programmatically. The coordinator is the contract holder: exceed it only with an explicit one-line note in the spawn turn naming the reason (e.g., "5 trivial test-only tasks, sub-agent context per task <2k").

#### Linear Mode (Last Resort)

For single-task batches or unavoidable sequential dependencies:

1. Record the per-task plan inline (no user approval — this skill is fully autonomous)
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
