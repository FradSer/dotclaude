---
name: executing-plans
description: Executes written implementation plans efficiently using per-batch sub-agent coordinators. This skill should be used when the user has a completed plan.md, asks to "execute the plan", or is ready to run batches of independent tasks in parallel following BDD principles.
argument-hint: [plan-folder-path]
user-invocable: true
allowed-tools: ["TaskCreate", "TaskUpdate", "TaskList", "TaskGet", "Read", "Write", "Edit", "Glob", "Grep", "Agent", "Bash(git-agent:*)", "Bash(git:*)", "Bash(${CLAUDE_PLUGIN_ROOT}/skills/executing-plans/scripts/batch-progress.sh:*)", "Bash(${CLAUDE_PLUGIN_ROOT}/lib/seed-checklists.sh:*)", "Bash(${CLAUDE_PLUGIN_ROOT}/lib/jsonl-emit.sh:*)"]
---

# Executing Plans

Execute written implementation plans through phase-based orchestration: Plan Review → Task Creation → per-batch coordinator dispatch + verification → Git Commit → Completion. Each batch runs in a fresh sub-agent (Agent tool) so the main agent's context never accumulates batch execution transcripts. Execution spans multiple batches across turns — **the recommended way to run it is wrapped in Claude Code's built-in `/goal`** (see below).

## Recommended: run wrapped in `/goal`

**Launch it under Claude Code's built-in `/goal`** (v2.1.139+) so the run continues to completion instead of stopping after a batch:

```
/goal "Claude has emitted the Phase 6 completion message 'Plan execution complete. All N tasks verified and committed' AND has reported the final commit hash from Phase 5 in the transcript" /superpowers:executing-plans <plan>
```

`/goal` is a **user-typed outer wrapper** (it must prefix the invocation; a skill cannot enable it for itself mid-run) — it provides the multi-turn continuation that the plugin's v2.x runtime used to provide (Removed in v3.0.0). A fresh fast model checks the condition against the conversation transcript after each turn and re-prompts until satisfied. **The evaluator does NOT read files or run commands** ([upstream docs](https://code.claude.com/docs/en/goal)) — phrase the condition as something Claude's own narration will demonstrate (the literal Phase 6 completion-message string, the single final commit-hash narration from `git-agent commit` at Phase 5). Conditions written against filesystem state (`_index.md status=completed`, `evaluator PASS report` files, `git commit clean`) are unverifiable from the transcript and will time out. **Note**: executing-plans commits **once** at Phase 5 after all batches finish, not once per batch — do NOT phrase the condition around "per-batch commit hash" or it will never match. Per-batch evaluator verdicts ARE narrated inline during Phase 4 of each batch, but those are progress signals, not completion signals. The skill body itself is single-turn-driven and orients via `scripts/batch-progress.sh` at the top of every turn (see Step 1 below).

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

1. **Plan Check**: Verify the folder contains `_index.md` with "Execution Plan" section.
2. **Context**: Read `_index.md` completely. This is the source of truth for your execution.

## Background Knowledge

**Core Principles**: Review before execution, batch verification, explicit blockers, evidence-driven approach.

**MANDATORY SKILL**: `superpowers:behavior-driven-development` must be loaded regardless of execution mode.

## Definition of Done

See `./references/definition-of-done.md` (non-negotiable; overrides all other guidance).

## Phase 1: Plan Review & Understanding

1. **Read Plan**: Read `_index.md` to understand scope, architecture decisions, and extract inline YAML task metadata from the "Execution Plan" section.
2. **Understand Project**: Explore codebase structure, key files, and patterns relevant to the plan.
3. **Check Blockers**: See `./references/blocker-and-escalation.md`.

## Phase 2: Task Creation (MANDATORY)

See `./references/phase-2-task-creation.md`.

## Phase 3: Batch Execution Loop (Context-Reset Architecture)

See `./references/phase-3-orchestration.md` and `./references/batch-execution-playbook.md`.

## Phase 4: Verification & Feedback

See `./references/phase-4-verification.md`.

## Phase 5: Git Commit

Commit the implementation changes using git-agent (with git fallback).

**Actions**:
1. Run: `git-agent commit --intent "<feature description>" --co-author "Claude <Model> <Version> <noreply@anthropic.com>"`
2. On auth error, retry with `--free` flag
3. **Fallback**: If git-agent is unavailable or fails, stage files with `git add` and use `git commit` with conventional format

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
- `./references/batch-execution-playbook.md` - Pattern for batch execution
- `./references/definition-of-done.md` - Non-negotiable completion rules
- `./references/phase-2-task-creation.md` - TaskCreate / dependency tier workflow
- `./references/phase-3-orchestration.md` - Main-agent batch loop and coordinator spawn
- `./references/phase-4-verification.md` - Evidence, handoff, and intra-plan learning
- `../../skills/references/git-commit.md` - Git commit patterns and requirements (shared cross-skill resource)
- `./references/evaluation-file-formats.md` - Evaluation file format definitions (sprint contract, evaluation report, handoff summary)
- `./references/sprint-contract-template.md` - Sprint contract template and negotiation protocol
- `./references/handoff-template.md` - Handoff summary template for long plans
- `./references/intra-plan-learning.md` - Pattern scan, batch handoff, and checklist evolution formats
- `./scripts/batch-progress.sh` - Filesystem-derived batch progress orientation (run as Step 1 of every iteration)
