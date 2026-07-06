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
- Commit range for the batch (`<BASE_SHA>..<HEAD>`, the same range passed to `review-package.sh`)
- Evaluation report path, recurring patterns, pivot recommendation (if any)

**Core principle:** Parallel execution for independent tasks, serial for dependent tasks. Red-Green pairs are non-negotiable.

## Main Agent's Direct-Edit Allow-List (Phase 3 HARD RULE)

Files the main agent may write directly during Phase 3:

- `handoff-state.md` — step 1, cross-batch memory
- `sprint-contract-batch-{N}.md` — step 0
- `evaluation-round-{N}-batch-{M}.md` — post-coordinator processing
- `_index.md` — only on PIVOT

Anything else (source, tests, configs, `__init__.py`, `pyproject.toml`, etc.) MUST go through the spawned coordinator.

**Self-discipline reminders** (no longer hook-enforced — the main agent owns these):

- If you find yourself editing source/test/config files inline rather than spawning a coordinator, stop: that is a direct-edit contract breach. Spawn the coordinator instead.
- If you find yourself doing extended exploration (many reads/greps) without spawning a coordinator, stop: the legitimate next actions are TaskList review and an Agent spawn, not "more exploration".

Direct-edit discipline matters most — it is the more severe contract breach. The per-batch evaluator (Phase 4) will catch any inline-edit violation in code review.

## ATOMIC: Phase 3 Steps 0-2 in One Response

Steps 0 (sprint contract) → 1 (handoff state) → 2 (Agent spawn) SHOULD execute in a single main-agent response, with the Agent tool call as the response's terminal action. Splitting setup across responses empirically lets the agent drift into inline batch execution between steps.

## The Coordinator Process

### Step 1: Load Context

1. Read `handoff-state.md` to learn prior batches' modified files, decisions, recurring patterns
2. Read `sprint-contract-batch-{N}.md` for this batch's scope, acceptance criteria, and Evaluation Criteria Preview
3. Read every task file for the batch (the coordinator, not the main agent, owns this reading)
4. Load `superpowers:behavior-driven-development` skill
5. **Check the durable task ledger before dispatching each task**: run `bash "${CLAUDE_PLUGIN_ROOT}/lib/task-ledger.sh" check <plan-dir> <task-id>` for every task ID in this batch. A task with an existing PASS entry was already completed and verified by a prior coordinator instance for this batch (e.g. this coordinator is a resumed continuation after context loss mid-batch) — skip re-dispatching it and fold its already-recorded evidence into this run's result instead.

### Step 2: Execute the Batch

#### Execution Mode Decision Tree

```
Is this a Red-Green pair (test + impl, same NNN prefix)?
  YES → Red-Green Pair mode
  NO  → Does the batch have 2+ tasks?
          YES → Are the tasks genuinely independent? (not interrelated failures,
                not exploratory/root-cause-unknown, no shared-file edits —
                see ../../references/workflow-orchestration.md Rule 1)
                  YES → Parallel mode (spawn one Task sub-agent per task)
                  NO  → Linear mode (run serially even though there are 2+ tasks)
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

1. **Record BASE_SHA, then launch**: Before spawning any sub-agent this batch, run `BASE_SHA=$(git rev-parse HEAD)` and hold that value for step 6. Never derive BASE from `HEAD~1` computed after the sub-agents finish — an implementer that lands multiple commits for one task would then lose the earlier commits' diff from the review package. Then spawn one Task sub-agent per task via the Agent tool, up to a **concurrency cap of 4 sub-agents per spawn round**
   - If the batch has more than 4 independent tasks, split into back-to-back spawn rounds (4 → wait → next 4) rather than spawning all at once. The cap exists because (a) more parallel sub-agents inflate the per-iteration token bill linearly and (b) the main agent's wait turn cannot meaningfully attend to >4 concurrent transcripts when a sub-agent reports a blocker.
   - **Large-batch escalation**: when the batch has many independent tasks (>4) AND the user has opted into multi-agent orchestration, delegate the whole fan-out to Claude Code's native `Workflow` tool instead of hand-rolling spawn rounds — it schedules concurrency automatically (`min(16, cores-2)`) and keeps every sub-agent transcript out of context. Do NOT self-enable it silently under `/goal`; gate on the opt-in signal. See `../../references/workflow-orchestration.md` for the opt-in rules and the task→`agent()` mapping.
   - If sub-agents edit overlapping files, add `isolation: "worktree"` for isolation
2. **Brief each task (diff/task-text-as-files)**: For each task in the batch, run `bash "${CLAUDE_PLUGIN_ROOT}/lib/task-brief.sh" <plan-dir>/task-<NNN>-<feature>-<type>.md <NNN>` against the task's own file (NOT `_index.md` — `_index.md` lists tasks as YAML + links, not as `## Task NNN:` headings, so the extractor would find nothing). The script writes `<plan-dir>/_briefs/task-<NNN>-brief.md`. The sub-agent prompt's `## Task Assignment` section then points to this brief file ("Read `<brief-path>` for your task assignment") instead of pasting the full task text inline — keeping task text out of the coordinator's context. See `lib/task-brief.sh`.
3. **Assign**: Give each sub-agent its brief file path with full context and file boundaries (per the Agent Prompt Template below)
4. **Wait**: Wait for all sub-agents in the current round to complete before launching the next round
5. **Verify**: Run verification commands for all tasks (after the final round)
6. **Package the diff for the evaluator**: After all tasks pass verification, run `bash "${CLAUDE_PLUGIN_ROOT}/lib/review-package.sh" <BASE_SHA> <HEAD> <plan-dir>` where `<BASE_SHA>` is the exact value recorded in step 1 (not recomputed as `HEAD~1` here) and HEAD is the current commit. The script writes `<plan-dir>/_reviews/review-<base7>..<head7>.diff`. Pass this file's path to the superpowers-evaluator so it reads the net diff from disk instead of the coordinator pasting it.
7. **Evaluate**: Spawn superpowers-evaluator after all tasks pass verification, pointing it at the review package + produced artifacts
8. **Complete**: Use `TaskUpdate` to mark tasks completed only after evaluator verdict is PASS

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

The coordinator does NOT emit prose completion messages. It returns a structured result to the main agent containing verdict, completed task IDs, evidence blocks, modified files list, commit range (`<BASE_SHA>..<HEAD>` from step 1 of Parallel Mode), evaluation report path, and any pivot recommendation. The main agent is responsible for user-facing progress output and for appending the durable task ledger (see `./phase-3-orchestration.md` step 3).

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
| 1 | **Load `superpowers:receiving-code-review` skill** → handle each rework item per its Response Pattern (READ → UNDERSTAND → VERIFY → EVALUATE → RESPOND → IMPLEMENT), re-verify per `verification-before-completion`, re-evaluate |
| 2 | Same protocol; fix remaining items with verification, re-evaluate |
| 3+ | Log a HARD BLOCKER entry per `blocker-and-escalation.md` and abort this batch (do NOT prompt the user) |

Maximum 2 evaluation-rework rounds before escalation. The superpowers-evaluator assesses independently each round -- it does not inherit previous round results. The receiving-code-review skill constrains the **implementer side** (how rework items are triaged and fixed); the evaluator remains the independent red-team reviewer on the other side.

**One fixer, full list:** When re-dispatching a sub-agent to address a REWORK verdict, spawn a single fix sub-agent carrying the complete Rework Items list for that round — never spawn one sub-agent per finding. Fragmenting fixes across sub-agents loses cross-item context (two findings can share a root cause) and risks one fixer's change contradicting another's.

See `evaluation-file-formats.md` for report format details.

## Agent Prompt Template

Every sub-agent prompt MUST include all five sections:

```
## Task Assignment

Read <task-brief-path> for your full task assignment.  <!-- generated by lib/task-brief.sh; do NOT paste task text inline -->

## Quality Requirements (MANDATORY)

You MUST produce complete, working implementation code — not stubs, skeletons, or placeholders.
Every function body must contain real logic, not `pass`, `...`, `TODO`, or a hardcoded stub return.
If you cannot implement something completely, stop and report a blocker; do NOT write a stub.

## Verification (MANDATORY BEFORE REPORTING DONE)

**Load `superpowers:verification-before-completion` skill using the Skill tool before reporting any task done.**

After implementation, run the following verification commands and confirm they all pass (exit code 0, no test failures):

[Verification commands from task file]

Report the actual command output (command + exit code + last 20-30 lines). Do not report completion until all verification commands pass THIS TURN. "Should pass" is not evidence — the Iron Law is no completion claims without fresh verification evidence.

## Completion Report (MANDATORY — report exactly one state)

Your final message MUST open with exactly one of these four states:

- **DONE** — verification passed this turn, no open questions. Include the evidence block.
- **DONE_WITH_CONCERNS** — verification passed, but you made a judgment call the coordinator should independently check (e.g. simplified scope, deviated from the brief in a specific way). State the concern in one line; the concern is a pointer for the reviewer to verify, not pre-cleared justification for a PASS.
- **NEEDS_CONTEXT** — you cannot proceed without specific missing information (name exactly what is missing).
- **BLOCKED** — you attempted the task and cannot complete it (name the specific obstacle: failing dependency, ambiguous spec, environment error).
```

Omitting any section is a protocol violation.

### Handling Sub-Agent Report States

The coordinator triages each returned state before touching TaskList:

| State | Coordinator action |
|-------|--------------------|
| DONE | Proceed to review-package + evaluator as normal. |
| DONE_WITH_CONCERNS | Read the concern before doing anything else. If it touches correctness, scope, or a shared interface, resolve it (re-dispatch with a narrower brief, or fix directly) before packaging for the evaluator — do NOT wave it through on the sub-agent's own say-so. The evaluator receives the produced files and verdicts independently; it does not get to treat the concern text as evidence toward PASS (see `../../../agents/superpowers-evaluator.md` Standards). |
| NEEDS_CONTEXT | Re-dispatch a fresh sub-agent with the missing information filled in. This is not a retry of the same prompt — the brief must materially change. |
| BLOCKED | Triage before re-dispatching: (1) missing context → supply it and re-dispatch (same as NEEDS_CONTEXT); (2) task exceeds the model tier's capability → re-dispatch to a stronger model tier; (3) task is too large/coupled → split it into smaller sub-tasks and re-dispatch each; (4) none of the above resolves it → log a HARD BLOCKER per `./blocker-and-escalation.md` and escalate. **Never re-dispatch the identical prompt to the identical model expecting a different result** — an unchanged retry burns a full sub-agent turn for the same failure. |

Bad work reported honestly (DONE_WITH_CONCERNS / NEEDS_CONTEXT / BLOCKED) is always preferable to a false DONE — the coordinator does not penalize a sub-agent for surfacing the true state.

## When to Abort a Batch

**Abort the current batch (HARD BLOCKER, do NOT prompt the user) when:**
- Blocker mid-batch (missing dependency, repeated test failure, unclear instruction)
- Plan has critical gaps
- Verification fails repeatedly (past the 2-retry cap)

Log a HARD BLOCKER entry per `blocker-and-escalation.md`, mark affected tasks `blocked` via TaskUpdate, and continue with unblocked batches. This skill is fully autonomous — never pause for user clarification. For ambiguous task wording, apply the Autonomous Resolution Protocol in `sprint-contract-template.md` (pick the most concrete interpretation, mark `[AUTO-RESOLVED]`, log the applied interpretation).
