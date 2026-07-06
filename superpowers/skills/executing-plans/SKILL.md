---
name: executing-plans
description: Executes written implementation plans efficiently using per-batch sub-agent coordinators. This skill should be used when the user has a completed plan.md, asks to "execute the plan", or is ready to run batches of independent tasks in parallel following BDD principles.
argument-hint: [plan-folder-path]
user-invocable: true
allowed-tools: ["TaskCreate", "TaskUpdate", "TaskList", "TaskGet", "Read", "Write", "Edit", "Glob", "Grep", "Agent", "Workflow", "Bash(git-agent:*)", "Bash(git:*)", "Bash(${CLAUDE_PLUGIN_ROOT}/skills/executing-plans/scripts/batch-progress.sh:*)", "Bash(${CLAUDE_PLUGIN_ROOT}/lib/seed-checklists.sh:*)", "Bash(${CLAUDE_PLUGIN_ROOT}/lib/jsonl-emit.sh:*)", "Bash(${CLAUDE_PLUGIN_ROOT}/lib/task-brief.sh:*)", "Bash(${CLAUDE_PLUGIN_ROOT}/lib/review-package.sh:*)", "Bash(${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh:*)", "Bash(${CLAUDE_PLUGIN_ROOT}/lib/task-ledger.sh:*)"]
---

# Executing Plans

Execute written implementation plans through phase-based orchestration: Plan Review → Task Creation → per-batch coordinator dispatch + verification → Git Commit → Completion. Each batch runs in a fresh sub-agent (Agent tool) so the main agent's context never accumulates batch execution transcripts. Execution spans multiple batches across turns — **the recommended way to run it is wrapped in Claude Code's built-in `/goal`** (see below).

## Recommended: run wrapped in `/goal`

**Launch it under Claude Code's built-in `/goal`** (v2.1.139+) so the run continues to completion instead of stopping after a batch:

```
/goal "Claude has emitted the Phase 6 completion message 'Plan execution complete. All N tasks verified and committed' AND has reported the final commit hash from Phase 5 in the transcript" /superpowers:executing-plans <plan>
```

`/goal` is a **user-typed outer wrapper** — it must prefix the invocation; a skill cannot enable it for itself mid-run. The evaluator judges only what Claude narrates in the transcript (it does NOT read files or run commands) — phrase the condition against narrated output, never filesystem state. **Note**: executing-plans commits **once** at Phase 5 after all batches finish — do NOT phrase the condition around a "per-batch commit hash" or it will never match; per-batch evaluator verdicts are progress signals, not completion signals. Full semantics and condition phrasing: `../../skills/references/goal-wrapper.md`. The skill body itself is single-turn-driven and orients via `scripts/batch-progress.sh` at the top of every turn (see Step 1 below).

## Step 1 of every iteration — orient via batch-progress.sh

**Before doing anything else, run:**

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/executing-plans/scripts/batch-progress.sh" <plan-path>
```

The script reads the plan dir, counts `sprint-contract-batch-*.md` and `handoff-summary-*.md` files, and emits a precise next-action directive ("Batch 3 active — Agent next" / "Batch 2 closed — TaskList then commit-or-next-batch" / "Batch 4 not yet started — Phase 3 steps 0-1-2"). Read the output as your authoritative "where am I" signal and follow the directive. This replaces the old loop's per-iteration filesystem scan + injection — same data, scoped to this skill.

Skip this step on the very first invocation (no plan-path resolved yet) — fall through to "First Action" below.

## CRITICAL: Bail-Out Check (run first, on first invocation only)

Read `_index.md`. If "Execution Plan" YAML lists < 5 tasks in a single batch, bail out: skip coordinator + sprint contract; execute tasks inline and commit. `--force` token in `$ARGUMENTS` bypasses. See `./references/bail-out.md` for the response template. If that inline work needs a plain "keep going until condition X holds" loop, use `/goal` directly.

## First Action — Resolve Plan Path

**Resolve the plan path, then orient.**

1. Resolve the plan path:
   - If `$ARGUMENTS` provides a path (e.g., `docs/plans/YYYY-MM-DD-topic-plan/`), use it
   - Otherwise, pick the `*-plan/` folder whose basename sorts last under `YYYY-MM-DD-*-plan/` — i.e., the highest date prefix in the name, not filesystem mtime. Use `ls -1d docs/plans/*-plan/ 2>/dev/null | sort | tail -1` (do NOT use `ls -t` / `ls -1dt` — directory mtimes get bumped when an older folder's files are edited, which makes it rank above a freshly-created folder). Use the result directly (no confirmation).
   - If no plan folder is found, abort with a clear error message naming the expected path pattern
2. Run `scripts/batch-progress.sh <plan-path>` to print the current batch state. If batches already exist, follow the script's directive directly (skip Phase 1/2 — they ran on a prior turn). Otherwise proceed with Initialization.

## Initialization (first turn only)

1. **Plan Check**: Verify the folder contains `_index.md` with "Execution Plan" section. Consult the docs index before spawning any batch: `bash "${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh" show <plan-path>`. If the row's status is `expired:`, REFUSE — the plan has been invalidated by a retro and is no longer authoritative; tell the user which retro invalidated it and stop. If the status is `implemented:<old-sha>` (rework after ship), run `bash "${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh" set-status <plan-path> "wip"` BEFORE spawning batch 1 so the index reflects that the plan is being worked again. Then consult memory: run `bash "${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh" list --kind memory --status active` and Read the top topically-relevant matches before Phase 1 "Plan Review."
2. **Context**: Read `_index.md` completely. This is the source of truth for your execution.

## Background Knowledge

**Core Principles**: Review before execution, batch verification, explicit blockers, evidence-driven approach.

**MANDATORY SKILL**: `superpowers:behavior-driven-development` must be loaded regardless of execution mode.

> **CRITICAL — two internal gate skills are load-bearing, not optional.** Every implementer sub-agent prompt MUST instruct loading `superpowers:verification-before-completion` before reporting any task done (no completion claims without fresh verification evidence pasted in the return), and the batch coordinator MUST load `superpowers:receiving-code-review` before acting on an evaluator REWORK verdict (verify each rework item against the codebase; no blind implementation). Omitting either from a coordinator prompt is a protocol violation. Details: `./references/batch-execution-playbook.md` (Agent Prompt Template + Rework Loop).

## Definition of Done

See `./references/definition-of-done.md` (non-negotiable; overrides all other guidance).

## Phase 1: Plan Review & Understanding

1. **Read Plan**: Read `_index.md` to understand scope, architecture decisions, and extract inline YAML task metadata from the "Execution Plan" section.
2. **Understand Project**: Explore codebase structure, key files, and patterns relevant to the plan.
3. **Check Blockers**: See `./references/blocker-and-escalation.md`.
4. **Pre-Flight Conflict Scan** (once, before Phase 2): Check every task's explicit instructions against the resolved `code-v{N}.md` checklist for contradictions (e.g. a task mandating a stub or duplicated logic the checklist forbids). No-op if none found. See `./references/preflight-conflict-scan.md`.

## Phase 2: Task Creation (MANDATORY)

See `./references/phase-2-task-creation.md`.

## Phase 3: Batch Execution Loop (Context-Reset Architecture)

See `./references/phase-3-orchestration.md` and `./references/batch-execution-playbook.md`.

> **CRITICAL — declare a model on every sub-agent dispatch.** When you spawn a batch coordinator or any reviewer via the Agent tool, always pass an explicit `model` (`sonnet` for ordinary implementation/verification, `opus` only for hard reasoning or final whole-branch review, `haiku` for mechanical sweeps). An unspecified `model` silently inherits the session's most expensive tier — left to choose, dispatches drift to top-tier and burn the budget. Pick the cheapest tier the work allows; never let it default.

> **CRITICAL — the native `Workflow` tool is opt-in only.** Never call `Workflow` unless the user has explicitly opted into multi-agent orchestration (said "use a workflow" / equivalent, or ultracode is on). A run under `/goal` must NOT silently fan out background agents. Without opt-in, use the default bounded Agent-tool spawn rounds and surface the option in one line. Opt-in rules and task mapping: `../../skills/references/workflow-orchestration.md`.

## Phase 4: Verification & Feedback

See `./references/phase-4-verification.md`.

## Phase 5: Git Commit

Commit the implementation changes using git-agent (with git fallback).

**Actions**:
1. Run: `git-agent commit --intent "<feature description>" --co-author "Claude <Model> <Version> <noreply@anthropic.com>"`
2. On auth error, retry with `--free` flag
3. **Fallback**: If git-agent is unavailable or fails, invoke the `/git:commit` skill via the Skill tool; full ladder in `../../skills/references/git-commit.md`

**CRITICAL — flip the plan's docs-index row post-commit (do-not-defer).** After the implementation commit lands, flip the plan's index row to `implemented`: `bash "${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh" set-status <plan-path> "implemented:$(git rev-parse --short HEAD)"`. Then commit the index update as its own tiny commit: `git-agent commit --no-stage --intent "mark <plan> implemented in docs index"`. NEVER use `--amend` — it would rewrite history and confuse the Stop hook's `completion_commit` detection (the hook keys off the tip commit on the plan's modified-files set; an amended tip silently repoints it).

**CRITICAL — conditional memory-write step, folded into the same follow-up commit above (do-not-defer).** Gated on the existing intra-plan-learning variety-gap signal (`references/intra-plan-learning.md:54` — all checklist items PASS for a batch but the batch required 2+ rework rounds before reaching PASS). If any batch this run hit that signal, also write `docs/memory/pitfall_<slug>.md` capturing the recurring rework cause, then run `bash "${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh" upsert memory docs/memory/<path> --status active --summary "<one-line>" --category pitfall`, staged into the same dedicated follow-up commit created above — do not create a separate commit for it. This variety-gap trigger is explicitly distinct from the separate hard-abort cap at batch-execution-playbook.md:165 (max 2 rework rounds before escalation), which is NOT a memory-write trigger — that cap governs the rework loop's hard stop, not memory capture. If no batch hit the variety-gap signal, this step is a no-op.

See `../../skills/references/git-commit.md` for patterns, templates, and requirements. Commit only after all tasks are completed; use a meaningful feature scope.

## Phase 6: Completion

Verify all tasks are complete, then output the completion summary.

1. **Final Task Audit**: Use TaskList to confirm every task has status `completed`. If any task is `in_progress` or `pending`, do NOT proceed — return to Phase 3 to finish remaining tasks.
2. **Summary message**: "Plan execution complete. All [N] tasks verified and committed." (human-facing; not a machine trigger — see note below).

> **Completion log is automatic.** You do NOT write `docs/retros/plans-completed.jsonl` yourself. The plugin's single `Stop` hook (`hooks/stop-state-sync.sh`) detects plan completion from durable on-disk state — every batch handed off (`handoff-summary-*` count ≥ batch count) plus a git commit touching the `handoff-state.md` modified-files set — and appends the `plan_completed` event mechanically, first-completion-only. Detection is state-based, not keyed off any sentence you emit, so it survives paraphrasing or a skipped summary. That log is what `/superpowers:retrospective` Phase 5a reads `completion_commit` from. See `../retrospective/references/evolution-protocol.md` §Plan Completion Log Schema for the row shape.

## Exit Criteria

All tasks executed and verified, evidence captured, no blockers, final verification passes, git commit completed. This skill runs fully autonomously — no user approval step exists. For unattended multi-turn continuation, wrap in `/goal` (see top of file).

## References

- `./references/blocker-and-escalation.md` - Guide for identifying and handling blockers
- `./references/preflight-conflict-scan.md` - Phase 1 scan for task-vs-checklist contradictions before Phase 2
- `./references/batch-execution-playbook.md` - Pattern for batch execution
- `./references/definition-of-done.md` - Non-negotiable completion rules
- `./references/phase-2-task-creation.md` - TaskCreate / dependency tier workflow
- `./references/phase-3-orchestration.md` - Main-agent batch loop and coordinator spawn
- `./references/phase-4-verification.md` - Evidence, handoff, and intra-plan learning
- `../../skills/references/git-commit.md` - Git commit patterns and requirements (shared cross-skill resource)
- `../../skills/references/goal-wrapper.md` - `/goal` wrapper semantics and condition phrasing (shared cross-skill resource)
- `../../skills/references/workflow-orchestration.md` - native `Workflow` escalation for large parallel batches (opt-in rules + task mapping)
- `./references/evaluation-file-formats.md` - Evaluation file format definitions (sprint contract, evaluation report, handoff summary)
- `./references/sprint-contract-template.md` - Sprint contract template and negotiation protocol
- `./references/handoff-template.md` - Handoff summary template for long plans
- `./references/intra-plan-learning.md` - Pattern scan, batch handoff, and checklist evolution formats
- `./scripts/batch-progress.sh` - Filesystem-derived batch progress orientation (run as Step 1 of every iteration)
- `../../lib/task-brief.sh` - Extract one task's text to a file the implementer reads from disk (diff/task-text-as-files)
- `../../lib/review-package.sh` - Generate a net-diff review package file the evaluator reads from disk
- `../../lib/task-ledger.sh` - Durable per-task completion ledger; check before dispatch, append after PASS
