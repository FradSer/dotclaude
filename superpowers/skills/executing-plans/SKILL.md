---
name: executing-plans
description: Executes written implementation plans efficiently using agent teams or subagents. This skill should be used when the user has a completed plan.md, asks to "execute the plan", or is ready to run batches of independent tasks in parallel following BDD principles.
argument-hint: [plan-folder-path]
user-invocable: true
allowed-tools: ["TaskCreate", "TaskUpdate", "TaskList", "TaskGet", "Read", "Write", "Edit", "Glob", "Grep", "Agent", "Bash(git-agent:*)", "Bash(git:*)", "Bash(${CLAUDE_PLUGIN_ROOT}/scripts/setup-superpower-loop.sh:*)"]
---

# Executing Plans

Execute written implementation plans efficiently using Superpower Loop for continuous iteration through all phases.

## CRITICAL: First Action - Size the Plan, Then Decide on Superpower Loop

**Resolve the plan path, peek at task count, then either start the loop or proceed single-session — do NOT read task files or explore the codebase first.**

1. Resolve the plan path:
   - If `$ARGUMENTS` provides a path (e.g., `docs/plans/YYYY-MM-DD-topic-plan/`), use it
   - Otherwise, search `docs/plans/` for the most recent `*-plan/` folder matching `YYYY-MM-DD-*-plan/` and use it directly (no confirmation)
   - If no plan folder is found, abort with a clear error message naming the expected path pattern
2. **Size the plan** (quick grep only — do NOT fully read files):
   ```bash
   task_count=$(grep -cE '^\s*-\s+id:' <plan-path>/_index.md)
   has_rg_pair=$(ls <plan-path>/task-*-test.md 2>/dev/null | wc -l)
   ```
   Also check whether `$ARGUMENTS` contains `--no-loop`.
3. **Loop decision**:
   - **Skip loop** (single-session mode) if any of: `$ARGUMENTS` contains `--no-loop`, OR `task_count ≤ 4`. Proceed directly to Initialization; do NOT run `setup-superpower-loop.sh`; omit the completion-promise tag at the end (it is a no-op without loop state).
   - **Start loop** otherwise. Run:
     ```bash
     "${CLAUDE_PLUGIN_ROOT}/scripts/setup-superpower-loop.sh" "Execute the plan at <resolved-plan-path>. Continue progressing through the superpowers:executing-plans skill phases: Phase 1 (Plan Review) → Phase 2 (Task Creation) → Phase 3-4 loop (Batch Execution + Verification, repeat per batch) → Phase 5 (Git Commit) → Phase 6 (Completion)." --completion-promise "EXECUTION_COMPLETE" --max-iterations 100
     ```
4. Only after the loop is running (or explicitly skipped), proceed with Initialization below

**Why the size gate?** For ≤4-task plans the loop adds turn overhead without benefit (see `./references/loop-patterns.md`). Record skip/start in the plan handoff for retrospective audit.

## Superpower Loop Integration

This skill uses Superpower Loop to enable self-referential iteration throughout the execution process.

**CRITICAL**: Throughout the process, you MUST output `<promise>EXECUTION_COMPLETE</promise>` only when:
- Phase 1-5 (Plan Review, Task Creation, Batch Execution, Verification, Git Commit) are all complete
- All tasks executed and verified
- All tasks marked `completed` (verified via TaskList — zero tasks with `in_progress` or `pending` status)
- Every Phase 4 verification gate has passed (no failing tasks)
- Git commit completed

Do NOT output the promise until ALL conditions are genuinely TRUE.

**ABSOLUTE LAST OUTPUT RULE**: The promise tag MUST be the very last text you output. Output any transition messages or instructions to the user BEFORE the promise tag. Nothing may follow `<promise>EXECUTION_COMPLETE</promise>`.

## Initialization

(The Superpower Loop and plan path were resolved in the first action above — do NOT start the loop again)

1. **Plan Check**: Verify the folder contains `_index.md` with "Execution Plan" section.
2. **Context**: Read `_index.md` completely. This is the source of truth for your execution.
3. **Evaluator Configuration** (mandatory): The evaluator is always enabled for every plan execution. If `_index.md` contains an `evaluator:` YAML block, only `intensity` is honored (`thorough` | `standard` | `light`, default: `standard`). Any `mode: off` or `mode: auto` value is rejected — every plan execution MUST produce evaluator output.
   - **Auto-downgrade for small plans**: If `task_count ≤ 5` AND no Red-Green pair exists, force `light` as the effective intensity (overrides declared `standard` / `thorough`). Rationale: small plans don't justify per-batch passes; one end-of-plan evaluation catches the same issues at lower cost. Record the downgrade in the plan handoff under "Auto-Downgrade" for retrospective audit.
   - **Checklist resolution**: Before spawning the evaluator, resolve the latest checklist version by scanning `docs/retros/checklists/` for files matching `{mode}-v{N}.md` and selecting the highest N. Pass the resolved path in the spawn context. If `code-v{N}.md` does not exist, abort with a clear error naming the expected path — seed it via `/superpowers:retrospective` before retrying.

The loop will continue through all phases until `<promise>EXECUTION_COMPLETE</promise>` is output.

## Background Knowledge

**Core Principles**: Review before execution, batch verification, explicit blockers, evidence-driven approach.

**MANDATORY SKILLS**: Both `superpowers:agent-team-driven-development` and `superpowers:behavior-driven-development` must be loaded regardless of execution mode.

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
4. Evaluator verdict for the batch is PASS (see Phase 3 step 2e)

See Phase 3 step 2d HARD GATE for verification failure handling.

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

## Phase 3: Batch Execution Loop

Execute tasks in batches using Agent Teams or subagents for parallel execution.

**For Each Batch**:

0. **Sprint Contract** (mandatory):
   - Resolve the latest checklist version: scan `docs/retros/checklists/` for `{mode}-v{N}.md`, select the highest N
   - Generate the sprint contract file in the plan directory before any task in the batch starts:
     - `standard` / `thorough`: write `sprint-contract-batch-{N}.md`
     - `light`: write `sprint-contract-summary.md` once for the full plan and reuse it across batches
   - Build the contract from `_index.md`, the batch's task files, the relevant BDD scenarios, the latest checklist items, and any "Recurring Failure Patterns" carried forward from earlier batches
   - Contract defines per-task acceptance criteria, Red-Green pair expectations, and an **Evaluation Criteria Preview** section listing the checklist items (ID + description) the evaluator will later apply -- this feedforward helps the generator produce better first-pass output
   - Execution MUST NOT start until the contract file exists
   - See `./references/sprint-contract-template.md` for format
   - The contract is never skipped. If the batch scope changes, rewrite the contract before resuming execution.
   - Checklist path table:

     | Mode   | Checklist path pattern             |
     |--------|------------------------------------|
     | design | `docs/retros/checklists/design-v{N}.md` |
     | plan   | `docs/retros/checklists/plan-v{N}.md`   |
     | code   | `docs/retros/checklists/code-v{N}.md`   |

1. **Choose Execution Mode** (decision tree):
   - **Red-Green Pair**: If the batch contains a Red-Green pair (same NNN prefix, one `test` + one `impl`), assign exactly two dedicated agents — one per task. The test agent runs first and confirms Red state; then the impl agent starts. Multiple pairs run in parallel. Non-negotiable for any test+impl pair.
   - **Parallel** (default for all other multi-task batches): Use Agent Team for 3+ tasks, or plain subagents for exactly 2 tasks. If agents edit overlapping files, use worktree isolation (`isolation: "worktree"`) as an option within this mode — not a separate mode. File conflicts within a batch should be resolved by splitting the batch further when possible.
   - **Linear** (last resort): Only when the batch has a single task or unavoidable sequential dependencies that cannot be split. State the reason explicitly.

2. **For Each Task in Batch**:

   a. **Mark Task In Progress**: Use TaskUpdate to set status to `in_progress`

   b. **Read Task Context**: Read the task file to get full context (subject, description, BDD scenario, verification steps)

   c. **Execute Task**: Based on execution mode:

      **Mandatory prompt content** — regardless of execution mode, every agent/teammate prompt MUST include:
      1. Full task file content (subject, description, BDD scenario, verification commands)
      2. The Quality Requirements block: "You MUST produce complete, working implementation code — not stubs, skeletons, or placeholders. Every function body must contain real logic. If you cannot implement something completely, stop and report a blocker."
      3. The Verification block: "After implementation, run the verification commands below and confirm they all pass (exit code 0, no test failures). Report the actual command output. Do NOT report completion until all verification commands pass."

      See `./references/batch-execution-playbook.md` — "Agent Prompt Template" section — for the full required template.

      **For Agent Team / Worktree mode**:
      - Create team if not already created
      - Assign task to available teammate using the mandatory prompt template above
      - Wait for teammate to complete and report verification output

      **For Subagent mode**:
      - Launch subagent using the mandatory prompt template above
      - Wait for subagent to complete and report verification output

      **For Linear mode**:
      - Execute task directly in current session
      - Follow BDD scenario and verification steps
      - Run verification commands and capture output

   d. **Verification Gate**: Run all verification commands from the task file. Capture the actual output.
      - For test tasks: Confirm test fails for the right reason (Red state confirmed)
      - For impl tasks: Confirm all tests pass (Green state confirmed, exit code 0)
      - For other tasks: Confirm verification command exits 0 and output matches expected

      **HARD GATE**: If ANY verification step fails (non-zero exit, test failure, unexpected output):
      - The task MUST remain `in_progress`
      - Fix the issue and re-run verification (up to two retries)
      - If still failing after two retries, escalate per `./references/blocker-and-escalation.md`
      - NEVER proceed to evaluator assessment (step 2e) while any task's verification is failing
      - Do NOT mark any task completed until evaluator verdict is PASS

   e. **Evaluator Assessment & Batch Completion Gate** (mandatory):
      - After ALL tasks in the batch have passed their Verification Gate (step 2d), spawn `superpowers:superpowers-evaluator` sub-agent with the resolved checklist path in spawn context
      - The superpowers-evaluator reads sprint contract + produced artifacts, applies binary checklist evaluation
      - Evaluator outputs report content as text; the executing-plans skill writes it to `evaluation-round-{N}-batch-{M}.md` in the plan directory
      - If verdict is **PASS**: mark ALL tasks in the batch completed — use TaskUpdate to set status to `completed` for each task, noting which verification commands ran and that they passed
      - If verdict is **REWORK**: generator reads rework items from the superpowers-evaluator, fixes issues, re-runs verification (max 2 evaluation-rework rounds, then escalate per `./references/blocker-and-escalation.md`). Do NOT mark any task completed until evaluator verdict is PASS
      - If **pivot flag** is set: log the superpowers-evaluator recommendation to the evaluation report and continue execution based on that recommendation (do NOT ask the user)
      - See `./references/evaluation-file-formats.md` for report format
      - **Intensity modifiers**: `thorough` = per-task evaluation; `standard` = per-batch (default); `light` = end-of-plan only

3. **Batch Completion**: After all tasks in batch complete, report progress and proceed to next batch

See `./references/batch-execution-playbook.md` for detailed execution patterns.

## Phase 4: Verification & Feedback

Close the loop with structured evidence and intra-plan learning.

1. **Publish Evidence**: For each completed task in the batch, output a structured evidence block:
   ```
   Task [ID]: [subject]
   Verification command: <command run>
   Output: <actual output, truncated to last 20 lines if long>
   Status: PASS / FAIL
   ```
   Any task without a PASS evidence block is NOT verified. Do not proceed to confirmation until all tasks have PASS status.

2. **Pattern Scan**: Scan evaluation reports for checklist items that FAILed in 2+ distinct batches; inject "Recurring Failure Patterns" into the next sprint contract preamble. See `./references/intra-plan-learning.md`.

3. **Persistent Patterns**: If a checklist item FAILed in 3+ batches, emit a `PERSISTENT PATTERN` warning in the batch handoff. Continue execution autonomously. See `./references/intra-plan-learning.md`.

4. **Batch Handoff**: Emit a lightweight handoff block to context (progress, patterns, modified files, next batch scope). See `./references/intra-plan-learning.md`.

5. **Proceed**: Output the evidence summary, then move immediately to the next batch — no user confirmation.

6. **Loop**: Repeat Phase 3-4 until all batches complete.

7. **Handoff Summary** (for plans with 16+ tasks): Produce `handoff-summary-{N}.md` at configured boundaries (default: every 3 batches). See `./references/handoff-template.md` for format. The lightweight batch handoff (step 4) is emitted for every batch regardless of plan size.

8. **Checklist Evolution Candidates** (on plan completion): Scan for checklist items that FAILed in 3+ batches or required 3+ rework rounds. Emit evolution candidates and variety gap notes in the plan completion summary. See `./references/intra-plan-learning.md` for format.

## Phase 5: Git Commit

Commit the implementation changes using git-agent (with git fallback).

**Actions**:
1. Run: `git-agent commit --intent "<feature description>" --co-author "Claude <Model> <Version> <noreply@anthropic.com>"`
2. On auth error, retry with `--free` flag
3. **Fallback**: If git-agent is unavailable or fails, stage files with `git add` and use `git commit` with conventional format

See `../../skills/references/git-commit.md` for patterns, templates, and requirements. Commit only after all tasks are completed; use a meaningful feature scope.

## Phase 6: Completion

Verify all tasks are complete, then output the promise as the absolute last line.

1. **Final Task Audit**: Use TaskList to confirm every task has status `completed`. If any task is `in_progress` or `pending`, do NOT proceed — return to Phase 3 to finish remaining tasks.
2. Summary message: "Plan execution complete. All [N] tasks verified and committed. To analyze patterns and evolve checklists, run `/superpowers:retrospective`."
3. `<promise>EXECUTION_COMPLETE</promise>` — nothing after this

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
