---
name: executing-plans
description: Executes written implementation plans efficiently using per-batch sub-agent coordinators. This skill should be used when the user has a completed plan.md, asks to "execute the plan", or is ready to run batches of independent tasks in parallel following BDD principles.
argument-hint: [plan-folder-path]
user-invocable: true
allowed-tools: ["TaskCreate", "TaskUpdate", "TaskList", "TaskGet", "Read", "Write", "Edit", "Glob", "Grep", "Agent", "Bash(git-agent:*)", "Bash(git:*)", "Bash(${CLAUDE_PLUGIN_ROOT}/scripts/setup-superpower-loop.sh:*)", "Bash(${CLAUDE_PLUGIN_ROOT}/lib/seed-checklists.sh:*)"]
---

# Executing Plans

Execute written implementation plans efficiently using Superpower Loop for continuous iteration through all phases.

## Resumed loop (iter >= 2)

Skip Bail-Out, First Action, Phase 1/2. Run `TaskList` → resume from the next incomplete task. **If the active batch has no spawned coordinator, your first tool call MUST be the Agent tool.**

## CRITICAL: Bail-Out Check (run first)

Read `_index.md`. If "Execution Plan" YAML lists < 5 tasks in a single batch, bail out: skip loop, coordinator, sprint contract; execute tasks inline and commit. `--force` token in `$ARGUMENTS` bypasses. See `./references/bail-out.md` for the response template.

## CRITICAL: First Action - Resolve Plan Path and Start Superpower Loop

**Resolve the plan path, then unconditionally start the loop — do NOT read task files or explore the codebase first.**

1. Resolve the plan path:
   - If `$ARGUMENTS` provides a path (e.g., `docs/plans/YYYY-MM-DD-topic-plan/`), use it
   - Otherwise, search `docs/plans/` for the most recent `*-plan/` folder matching `YYYY-MM-DD-*-plan/` and use it directly (no confirmation)
   - If no plan folder is found, abort with a clear error message naming the expected path pattern
2. **Start the loop** (no size gate — this skill's default user operates on large multi-batch plans):
   ```bash
   "${CLAUDE_PLUGIN_ROOT}/scripts/setup-superpower-loop.sh" "Execute the plan at <resolved-plan-path>. Continue progressing through the superpowers:executing-plans skill phases: Phase 1 (Plan Review) → Phase 2 (Task Creation) → Phase 3-4 loop (Batch Execution + Verification, repeat per batch) → Phase 5 (Git Commit) → Phase 6 (Completion). Emit <promise>EXECUTION_COMPLETE</promise> as your final line immediately after the Phase 5 commit succeeds — do not run an extra verification/polish pass." --completion-promise "EXECUTION_COMPLETE" --max-iterations 100
   ```
3. Only after the loop is running, proceed with Initialization below

## Initialization

(The Superpower Loop and plan path were resolved in the first action above — do NOT start the loop again)

1. **Plan Check**: Verify the folder contains `_index.md` with "Execution Plan" section.
2. **Context**: Read `_index.md` completely. This is the source of truth for your execution.

The loop will continue through all phases until `<promise>EXECUTION_COMPLETE</promise>` is output.

## Background Knowledge

**Core Principles**: Review before execution, batch verification, explicit blockers, evidence-driven approach.

**MANDATORY SKILL**: `superpowers:behavior-driven-development` must be loaded regardless of execution mode.

## Definition of Done

These rules are non-negotiable and override all other guidance.

**PROHIBITED outputs** — a task MUST NOT be marked `completed` if it produces any of the following:
- Stub files: files containing only function signatures, `pass`, or `...` with no logic
- Placeholder implementations: `TODO`, `FIXME`, `NotImplemented`, `raise NotImplementedError`, or equivalent in any language
- Empty function bodies: functions that return a hardcoded default or `None`/`null` without executing real logic
- Skeleton-only files: files with only imports, type declarations, or class definitions but no method bodies

**A task is "done" only when ALL of the following are true:**
1. Verification commands from the task file exit with code 0
2. Expected output matches actual output (no test failures, no assertion errors)
3. No prohibited patterns exist in any file written during the task
4. The batch coordinator's returned verdict is PASS (evaluator PASS on the batch containing this task)

Verification failure handling lives inside the batch coordinator (see `./references/batch-execution-playbook.md` — Verification Gate + Rework Loop). The main agent never retries verification in its own context; it receives a structured PASS / REWORK_ESCALATED / PIVOT result from the coordinator.

## Phase 1: Plan Review & Understanding

1. **Read Plan**: Read `_index.md` to understand scope, architecture decisions, and extract inline YAML task metadata from the "Execution Plan" section.
2. **Understand Project**: Explore codebase structure, key files, and patterns relevant to the plan.
3. **Check Blockers**: See `./references/blocker-and-escalation.md`.

## Phase 2: Task Creation (MANDATORY)

**CRITICAL**: You MUST use TaskCreate to create ALL tasks BEFORE executing any task. Task creation must complete before dependency analysis or execution begins.

1. **Extract Tasks from _index.md**: Read `_index.md` only. Parse the inline YAML metadata in the "Execution Plan" section to extract:
   - `id`: Task identifier (e.g., "001")
   - `subject`: Brief title in imperative form (e.g., "Implement login handler")
   - `slug`: Hyphenated slug for filename (e.g., "implement-login-handler")
   - `type`: Task type (test, impl, setup, config, refactor)
   - `depends-on`: Array of task IDs this task depends on (e.g., ["001"])

2. **Create Tasks First**: Use TaskCreate to register every task
   - Set `subject` from YAML `subject` field
   - Set `description` to: "See task file: ./task-{id}-{slug}-{type}.md for full details including BDD scenario and verification steps"
   - Set `activeForm` by converting subject to present continuous form (e.g., "Setting up project structure")
   - All tasks MUST be created before proceeding to the next phase
   - Do NOT read individual task files during this phase — they are read on-demand during execution

3. **Analyze Dependencies**: After all tasks are created, build the dependency graph
   - Compute dependency tiers: Tier 0 = no dependencies, Tier N = all depends-on tasks are in earlier tiers
   - Within each tier, group tasks by type to maximize parallelism (e.g., all "write test" tasks together, all "implement" tasks together)
   - **Identify Red-Green Pairs**: Scan all task filenames for matching NNN prefixes (e.g., `task-002-auth-test` + `task-002-auth-impl`). Mark each such pair as a **Red-Green pair** — these are always scheduled as a coordinated unit in the same batch. The test task retains its Tier 0 position; the impl task follows immediately after in the same batch execution (not a separate batch).
   - **Target**: Each batch should contain 3-6 tasks
   - **Rule**: Every batch must contain ≥2 tasks unless it is the sole remaining batch

4. **Setup Task Dependencies**: Use TaskUpdate to configure dependencies between tasks
   - `addBlockedBy`: Array of task IDs this task must wait for before starting
   - `addBlocks`: Array of task IDs that must wait for this task to complete
   - Example: `TaskUpdate({ taskId: "2", addBlockedBy: ["1"] })` means task #2 waits for task #1

## Phase 3: Batch Execution Loop (Context-Reset Architecture)

**CRITICAL — Context Reset Principle (Anthropic harness-design blog, principle 1)**: The main executing-plans agent does NOT execute batch tasks itself. Each batch runs inside a **fresh, isolated sub-agent context** spawned via the Agent tool (`subagent_type: "general-purpose"`). The main agent orchestrates only: it holds plan metadata, TaskList, and a rolling handoff state file — it never accumulates batch execution transcripts. This prevents context pollution as task count scales.

**What the main agent owns (kept across batches)**:
- `_index.md` (plan structure, read once in Phase 1)
- TaskList (authoritative task state)
- `handoff-state.md` in plan directory — cumulative snapshot, rewritten after each batch
- Git commit at the end

**What each spawned batch coordinator owns (discarded when batch returns)**:
- Reading task files, running verification, executing BDD/Red-Green/Parallel logic
- Spawning `superpowers:superpowers-evaluator` for the batch
- Rework loops inside the batch
- All per-task implementation transcripts

**For Each Batch**:

**ATOMIC**: Steps 0-2 in one response, Agent tool last. See `./references/batch-execution-playbook.md`.

0. **Sprint Contract** (main agent, before spawning coordinator):
   - Write `sprint-contract-batch-{N}.md` from `_index.md`, batch task files, BDD scenarios, latest `code-v{N}.md`
   - Acceptance criteria **auto-derived** from each task file's BDD Then-clauses — see `./references/sprint-contract-template.md` "Acceptance Criteria Derivation"; do NOT author new criteria
   - Contract is never skipped.
   - **Rewrite on scope change → archive, do NOT overwrite.** Move the existing `sprint-contract-batch-{N}.md` to `sprint-contract-batch-{N}.v{M}.md` (next sequential M), then write the new contract to the canonical path with `Revision: {M+1}` in the sign-off block. See `./references/sprint-contract-template.md` "Sign-off". Silent overwrite hides the rewrite from the post-plan audit trail — non-negotiable.

1. **Refresh Handoff State** (main agent):
   - Rewrite `handoff-state.md` in the plan directory with:
     - Completed task IDs (from TaskList)
     - Modified files accumulated from prior batches
     - Recurring Failure Patterns from prior evaluation reports (see `./references/intra-plan-learning.md`)
     - Key architectural decisions carried forward
   - This file is the ONLY cross-batch memory the spawned batch coordinator can rely on. If it is not written, the coordinator starts blind — do not skip.
   - See `./references/handoff-template.md` for format.

2. **Spawn Batch Coordinator** (main agent → fresh sub-agent via Agent tool):

   **HARD RULE**: Main agent MUST spawn a sub-agent for batch tasks. Direct `Edit`/`Write`/`MultiEdit` of source files violates the contract and trips stuck-detection. Allow-list: `./references/batch-execution-playbook.md`.

   - Use the Agent tool with `subagent_type: "general-purpose"` and `description: "Execute batch {N} of {plan-name}"`
   - The coordinator prompt MUST be fully self-contained (the coordinator has no memory of this conversation). Include:
     1. The plan directory absolute path
     2. The `sprint-contract-batch-{N}.md` path
     3. The `handoff-state.md` path
     4. The resolved code checklist path (`docs/retros/checklists/code-v{N}.md`)
     5. The full task ID list for this batch, with Red-Green pair annotations where applicable
     6. The batch's execution mode (Red-Green Pair / Parallel / Linear — see decision tree in `./references/batch-execution-playbook.md`)
     7. The full Agent Prompt Template (Quality Requirements + Verification blocks) from `./references/batch-execution-playbook.md`
     8. **Evaluator instruction:** "Spawn `superpowers:superpowers-evaluator` for batch evaluation after all tasks pass their Verification Gate"
     9. Max 2 evaluation-rework rounds before the coordinator escalates per `./references/blocker-and-escalation.md`
     10. Required structured return format (see step 3 below)

3. **Process Coordinator Result** (main agent):
   The batch coordinator returns a structured result. Main agent parses it:
   ```
   Verdict: PASS | REWORK_ESCALATED | PIVOT
   Completed task IDs: [001, 002, ...]
   Evidence blocks: [ {task_id, verification_command, status, last_20_lines_of_output} ]
   Modified files: [path/to/file1, ...]
   Evaluation report path: evaluation-round-{N}-batch-{M}.md
   Recurring patterns detected: [ {item_id, issue_summary} ]
   Pivot recommendation: <text or null>
   ```
   - On **PASS**: TaskUpdate each completed task ID to `completed` with a note referencing the verification commands that ran
   - On **PIVOT**: log the recommendation to the evaluation report, apply the recommended plan modifications to `_index.md` and remaining task files, then continue with the revised plan (do NOT ask the user)
   - On **REWORK_ESCALATED**: the coordinator exhausted 2 rework rounds. Escalate per `./references/blocker-and-escalation.md` — log HARD BLOCKER, abort batch, do NOT retry in the main agent's own context

4. **Batch Completion** (main agent): Append a batch handoff block to the conversation, update `handoff-state.md` with the new modified files + patterns, proceed to next batch. See Phase 4 for handoff format.

See `./references/batch-execution-playbook.md` for the coordinator's internal execution patterns (Red-Green pair, Parallel mode, Linear mode, verification gate, rework loop, evaluator invocation).

## Phase 4: Verification & Feedback

Close the loop with structured evidence and intra-plan learning. All of Phase 4 runs in the main agent's context — the batch coordinator returned evidence as a structured result; the main agent persists it without re-reading transcripts.

1. **Publish Evidence**: For each completed task in the batch (from the coordinator's structured result), output a compact evidence block:
   ```
   Task [ID]: [subject]
   Verification command: <command run>
   Output: <last 20 lines of coordinator-reported output>
   Status: PASS
   ```
   Evidence is drawn from the coordinator's return payload — do NOT re-run verification in the main context.

2. **Pattern Scan**: Read evaluation reports from the plan directory; identify checklist items that FAILed in 2+ distinct batches. Inject "Recurring Failure Patterns" into the next sprint contract preamble. See `./references/intra-plan-learning.md`.

3. **Persistent Patterns**: If a checklist item FAILed in 3+ batches, emit a `PERSISTENT PATTERN` warning in the batch handoff. Continue execution autonomously.

4. **Batch Handoff**: Emit a lightweight handoff block to context (progress, patterns, modified files, next batch scope). Also update `handoff-state.md` (written in Phase 3 step 1) with the new accumulated state — this is the cross-batch memory the next coordinator reads.

5. **Handoff Summary** (every batch boundary, no task-count gate): Produce `handoff-summary-{N}.md` after every completed batch. See `./references/handoff-template.md` for format. This file + `handoff-state.md` together constitute the persistent cross-batch memory; the main agent only retains structural metadata.

6. **Proceed**: Output the evidence summary, then move immediately to the next batch — no user confirmation.

7. **Loop**: Repeat Phase 3-4 until all batches complete.

8. **Checklist Evolution Candidates** (on plan completion): Scan for checklist items that FAILed in 3+ batches or required 3+ rework rounds. Emit evolution candidates and variety gap notes in the plan completion summary. See `./references/intra-plan-learning.md` for format.

## Phase 5: Git Commit

Commit the implementation changes using git-agent (with git fallback).

**Actions**:
1. Run: `git-agent commit --intent "<feature description>" --co-author "Claude <Model> <Version> <noreply@anthropic.com>"`
2. On auth error, retry with `--free` flag
3. **Fallback**: If git-agent is unavailable or fails, stage files with `git add` and use `git commit` with conventional format

See `../../skills/references/git-commit.md` for patterns, templates, and requirements. Commit only after all tasks are completed; use a meaningful feature scope.

## Phase 6: Completion

Verify all tasks are complete, log plan completion, then output the promise as the absolute last line.

1. **Final Task Audit**: Use TaskList to confirm every task has status `completed`. If any task is `in_progress` or `pending`, do NOT proceed — return to Phase 3 to finish remaining tasks.
2. **Log Plan Completion** (handled automatically by Stop hook): When you emit `<promise>EXECUTION_COMPLETE</promise>`, the loop hook (`lib/loop.sh:_loop_log_plan_completion_if_executing`) appends a `plan_completed` event to `docs/retros/plans-completed.jsonl` with fields `{plan, repo_root, task_count, batch_count, completion_commit, completion_modified_files, timestamp}`. The `completion_commit` is what `/superpowers:retrospective` Pre-Check A and Phase 1 feed to `post-plan-diff.sh` (the post-plan correction loop). No manual write needed; the hook is the canonical writer, and plan-level dedup makes re-running on a finished plan safe.
3. Summary message: "Plan execution complete. All [N] tasks verified and committed."
4. `<promise>EXECUTION_COMPLETE</promise>` — nothing after this

**PROHIBITED**: Do NOT output the promise tag if TaskList shows any non-completed tasks. Do NOT output any text after the promise tag.

## Exit Criteria

All tasks executed and verified, evidence captured, no blockers, final verification passes, git commit completed. This skill runs fully autonomously — no user approval step exists.

## References

- `./references/blocker-and-escalation.md` - Guide for identifying and handling blockers
- `./references/batch-execution-playbook.md` - Pattern for batch execution
- `../../skills/references/git-commit.md` - Git commit patterns and requirements (shared cross-skill resource)
- `../../skills/references/loop-patterns.md` - Completion promise design, prompt patterns, and safety nets
- `./references/evaluation-file-formats.md` - Evaluation file format definitions (sprint contract, evaluation report, handoff summary)
- `./references/sprint-contract-template.md` - Sprint contract template and negotiation protocol
- `./references/handoff-template.md` - Handoff summary template for long plans
- `./references/intra-plan-learning.md` - Pattern scan, batch handoff, and checklist evolution formats
