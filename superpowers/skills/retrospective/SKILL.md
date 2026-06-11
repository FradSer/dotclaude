---
name: retrospective
description: This skill should be used when the user wants to analyze evaluation patterns across completed plans and evolve checklists. Triggered by asking to "run a retrospective", "analyze evaluation patterns", "evolve checklists", or "/superpowers:retrospective". For autonomous multi-turn runs, invoke wrapped in `/goal`.
argument-hint: <plan-path-1> [plan-path-2] [--across-all]
user-invocable: true
allowed-tools: ["Read", "Glob", "Grep", "Write", "Edit", "Bash(python3:*)", "Bash(git:*)", "Bash(${CLAUDE_PLUGIN_ROOT}/lib/seed-checklists.sh:*)", "Bash(${CLAUDE_PLUGIN_ROOT}/lib/post-plan-diff.sh:*)", "Bash(${CLAUDE_PLUGIN_ROOT}/lib/jsonl-emit.sh:*)"]
---

# Retrospective

Analyze evaluation patterns across completed plans, identify recurring failures, and auto-apply checklist evolution. The user reviews post-commit via `git show docs/retros/checklists/`.

**Chain position**: This skill is the downstream consumer of executing-plans Phase 4 "Checklist Evolution Candidates". It aggregates signals across plans and produces versioned checklist updates.

## Recommended: run wrapped in `/goal`

A retrospective aggregates signals across plans and can span multiple turns. **Launch it under Claude Code's built-in `/goal`** (v2.1.139+):

```
/goal "Claude has narrated a successful checklist-evolution commit (with commit hash) and stated the retrospective is complete" /superpowers:retrospective <plan-paths>
```

`/goal` is a **user-typed outer wrapper** — it must prefix the invocation; a skill cannot enable it for itself mid-run. The evaluator judges only what Claude narrates in the transcript (it does NOT read files or run commands) — phrase the condition against narrated output (the commit-hash line, an explicit completion statement), never filesystem state, which is unverifiable and will time out. Full semantics and condition phrasing: `../../skills/references/goal-wrapper.md`.

## Pre-Check (run first, in order)

### A. INSUFFICIENT-POST-PLAN advisory (informational)

Read the most recent `plan_completed` event from `docs/retros/plans-completed.jsonl`. If `hours_since_completion < 24h` AND `bash "${CLAUDE_PLUGIN_ROOT}/lib/post-plan-diff.sh" summary <completion_commit> <files...>` returns `total == 0`, output the INSUFFICIENT-POST-PLAN reminder verbatim (see `./references/post-plan-diff.md` §Pre-Check A) and proceed to Phase 0 — do NOT pause. Skip silently when `completion_commit` is missing.

### B. Recall persistent memory (calibration priors)

**CRITICAL — do this before Phase 0, do NOT skip it because it feels like setup.** A retrospective calibrates checklist evolution against prior decisions, and persistent memory holds the human judgments the evolution-log cannot capture (rejected directions, debt/gate trackers, harness-design stance, working-style feedback). Recall is a SECONDARY calibration signal — `docs/retros/evolution-log.jsonl` (Phase 1 step 5) stays authoritative; when memory and the log disagree, the log wins.

Claude Code injected the `MEMORY.md` index at session start, so its one-line hooks are ALREADY in your context — there is nothing to read from disk. Scan those hooks now as prior-decision evidence and select the ones bearing on this run:

- **Prior evolution / rejection decisions and debt trackers** — anti-add-bias / "rejected" / "gate" / "pending" notes. A memory-recorded rejection is the same evidence type as a Phase 1 step 5 `item_removed` log row.
- **Harness-design principles** — e.g. simplify-don't-add stance.
- **Working-style feedback** — e.g. "auto-produce, never pause", "L2 must carry CRITICAL".

Carry these forward as priors into Phase 1 step 5 (calibration history), Phase 3 (REMOVE-is-load-bearing suppression of weakly-justified ADDs), and Phase 4 (self-reject a proposal that contradicts a recalled prior, citing the memory entry). If no calibration-relevant hook exists, log `Pre-Check B: no calibration-relevant memory` and proceed. Never resolve a memory path, never read a topic file, never block, never ask, never read "to make sure" — the index hooks carry the signal on their own.

## Phase 0: Bootstrap (run only when no checklists exist)

Before Phase 1, check whether `docs/retros/checklists/` contains `{mode}-v1.md` for each mode (design / plan / code).

If all three modes already have a v1 file, log `Phase 0: all checklists present, skipping seed` and proceed to Phase 1.

Phase 0 runs per-mode independently — only modes missing a v{N} file are seeded. Do not skip the entire phase because one mode already has a checklist.

### Path A — Completed plans or evaluation reports exist

Seed the generic template and proceed to Phase 1:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/lib/seed-checklists.sh" <mode> docs/retros/checklists/<mode>-v1.md
```

Log `Seeded initial checklist: {mode}-v1.md`. Skip the Full History Analysis below — Phase 1 has real evaluation data to work with.

### Path B — Cold start (no completed plans, no evaluation reports)

When `docs/retros/plans-completed.jsonl` is absent or empty AND no `evaluation-round-*.md` files exist anywhere under `docs/plans/`, the retrospective has no evaluation data. Instead of producing a zero-signal run, perform a **Full History Bootstrap**: analyze the project's entire git history to extract project-specific failure patterns and augment the generic template with tailored checklist items.

**Step 1 — Seed the generic template** (same command as Path A):

```bash
bash "${CLAUDE_PLUGIN_ROOT}/lib/seed-checklists.sh" <mode> docs/retros/checklists/<mode>-v1.md
```

**Step 2 — Git history gate**: count commits via `git rev-list --count HEAD`. If < 50, log `Phase 0: insufficient git history ({N} commits, need 50+) for bootstrap analysis`, skip Step 3, and proceed to Phase 1 with the generic template only.

**Step 3 — Full History Analysis** (see `./references/analysis-patterns.md` §Bootstrap Analysis for the detailed methodology):

1. `git log --oneline --all` — collect all commits
2. Classify each commit by conventional-commit prefix into **feedback** (`fix:`, `refactor:`, `style:`, `perf:`) or **evolution** (`feat:`, `docs:`, `chore:`, `build:`, `ci:`, `test:`)
3. Group feedback commits by scope+type combination, rank by frequency
4. For the top clusters, `git show <sha>` the diffs and extract recurring failure patterns
5. Classify each pattern into a mode layer:
   - **code**: dead code, lint violations, i18n gaps, duplicate definitions, stub implementations
   - **design**: stale references, missing BDD scenarios, references to deleted features
   - **plan**: oversized tasks, missing cleanup tasks, batch ordering violations
6. Generate one checklist item per failure pattern using the `evolution-protocol.md` New Item Template format (ID + description + check method + evidence format + rework format)

**Step 4 — Append project-specific items**: for each mode that received items, insert a new `## Project-Specific Items (Bootstrap Analysis)` section into the seeded `{mode}-v1.md` immediately before the existing `## Evaluation Protocol` section. Each item gets a unique ID following `{MODE}-{CATEGORY}-{NN}` naming (e.g., `CODE-I18N-01`, `DESIGN-STALE-01`, `PLAN-SCOPE-01`).

**Step 5 — Report**: log the analysis statistics (total commits, feedback/evolution split, top clusters, items generated per mode) in the retrospective report.

**Exit code handling**: the seed script refuses to clobber an existing checklist (exit code 3) — treat that as "already seeded, proceed". Real failures (exit 1 = unknown mode, exit 2 = usage error) abort the phase. To genuinely reset an existing checklist (e.g., after a major harness change), append `--force` after the output path.

The canonical v1 template content lives in `lib/seed-checklists.sh`. To inspect or modify the seed bodies, edit that script — do NOT re-inline templates here.

## Phase 1: Data Collection

1. **Resolve inputs**: Parse `$ARGUMENTS` for plan paths. If `--across-all`, scan `docs/plans/` for all `*-plan/` directories with evaluation reports. If no argument is given, read `docs/retros/plans-completed.jsonl` and auto-scope to plans completed after the most recent `retrospective_run` event in `docs/retros/evolution-log.jsonl`.
2. **Resolve evals**: For each plan path, look for evaluation reports in the plan directory (`evaluation-round-*.md`, `evaluation-design-round-*.md`, `evaluation-plan-round-*.md`). If a sibling `*-evals/` directory exists, read from there instead.
3. **Read checklists**: Scan `docs/retros/checklists/` for latest versions of each mode (`{mode}-v{N}.md`, highest N).
4. **Read reports**: For each plan, read all evaluation report files. Extract per-item results (Item ID, Result, Evidence) and rework items.
5. **Read evolution history** (calibration input): Read `docs/retros/evolution-log.jsonl` if present. Build a history table keyed by `item_id` with: most recent event (`item_added|item_removed|item_modified|item_promoted`), timestamp, rationale. This history feeds Phase 3 — do NOT re-propose an `ADD` for an item `REMOVE`d in the most recent retrospective unless the new evidence is materially different from the original removal rationale. Cite the historical entry in any such proposal.
6. **Read post-plan diff**: For each plan with a `completion_commit` field, run `bash "${CLAUDE_PLUGIN_ROOT}/lib/post-plan-diff.sh" list <completion_commit> <completion_modified_files...>` and pass the classified commit list to Phase 5a. See `./references/post-plan-diff.md` for classification rules and skip conditions.

7. **Minimum data check**: If only 1 plan provided, warn that ADD proposals require 2+ plans (except the post-plan-diff 1-plan ADD override in Phase 5a). REMOVE proposals need 3+ reports with zero failures.

## Phase 2: Pattern Analysis

Aggregate data across all plans. See `./references/analysis-patterns.md` for detailed logic.

1. **Failure frequency**: Count distinct plans where each checklist item FAILed. Rank by frequency descending.
2. **Plateau tasks**: Identify tasks that were REWORK across 2+ consecutive evaluation rounds in any plan. Extract the root cause from rework items.
3. **Never-failing items**: Find items with 0 FAILs across 10+ evaluation reports. These are REMOVE candidates.
4. **Variety gaps**: From executing-plans completion summaries, find batches where all items PASS but 2+ rework rounds occurred -- the checklist missed the failure mode.

Output a structured analysis report with tables for each category.

## Phase 3: Evolution Proposals

Generate proposals from analysis results. See `./references/evolution-protocol.md` for thresholds and format.

| Type | Trigger | Threshold |
|------|---------|-----------|
| ADD | Failure pattern in 2+ plans with no covering item | 2+ distinct plans |
| REMOVE | 0 failures across enough reports | 3+ reports per item |
| MODIFY | Item produces false positives (FAIL overturned in rework) | 2+ false positives |
| PROMOTE | Capability item pass rate >80% across 3+ successive plans | 3+ plans trending |

**Rate limit (EVO-6)**: Max 3 proposals per mode per retrospective run. Defer excess with evidence for future runs.

**Counter monotonic growth (REMOVE is load-bearing)**: ADD is cheap to trigger (even a 1-plan post-plan-diff override) while REMOVE used to require 10+ reports/item — a volume real single-project usage never reaches, so checklists only ever grew. The 3+ reports/item REMOVE threshold above is deliberately reachable. Each run, actively scan for never-firing items and propose REMOVE; a checklist that only grows is a calibration failure, not success.

Each proposal includes: type, target checklist, item ID, description, rationale with plan evidence.

## Phase 4: Auto-Apply Proposals

Apply every Phase 3 proposal (ordered by priority: regression breaks first, then by frequency). No per-proposal approval gate — EVO-6 (max 3/mode/run) + Phase 3 thresholds + post-commit `git show docs/retros/checklists/` are the quality surface. `proposals_rejected` is reserved for self-rejection at apply time: when a proposal duplicates a recent removal (Phase 1 step 5 history) or contradicts a recalled memory prior (Pre-Check B) without materially new evidence, log to the report under "Self-Rejected Proposals" with the cited historical or memory entry, increment `proposals_rejected`, and skip the checklist row. All other proposals advance.

Apply steps:

1. **Pre-edit snapshot**: Write current checklist content to the retrospective report under "Pre-Edit Snapshot" with rollback instructions
2. **Create new version**: Write `{mode}-v{N+1}.md` with all applied changes. Version increments once per run (not per proposal). Original version preserved unchanged.
3. **Log evolution** — **CRITICAL: a proposal is NOT "applied" until its evolution-log row exists.** Immediately after writing the new version file, append one row to `docs/retros/evolution-log.jsonl` per applied proposal via `lib/jsonl-emit.sh` with `<channel>=evolution-log` — emit per-proposal here, do NOT defer to the end of the run. The event arg is one of `item_added | item_removed | item_modified | item_promoted`. The full canonical bash invocation (every required field and `--arg` pair) lives in `./references/evolution-protocol.md` §"Canonical Emit Invocations" — substitute the event arg per applied proposal. These rows feed Phase 1 step 5's re-proposal guard; a dropped `item_removed` row silently re-adds the just-removed item next run. The Stop hook (`hooks/stop-state-sync.sh`) backfills `item_added`/`item_removed` from the checklist version diff only when *every* row for this version is missing (all-or-nothing) and carries no rationale — so the in-skill emit is authoritative and must run.
4. **Verify the log** — **CRITICAL self-check, do NOT skip:** before leaving Phase 4, count evolution-log rows whose `checklist_version` equals the version(s) written this run and confirm the count equals `proposals_approved`. Emit any missing rows now. This is the guard against a *partial* drop the hook's all-or-nothing backfill will not catch.

## Phase 5: Harness Health (advisory)

Surface components that may no longer earn their cost and turn post-plan corrections into checklist proposals. Everything here is advisory: it feeds Phase 3 proposals and the Phase 6 report, and is reviewed by the user via the post-commit diff. Phase 5 never disables a component or mutates the harness.

> **Removed in v2.9.0 — the automated disable-test loop.** The one-at-a-time `harness-config.json` disable protocol and its `harness-observations.jsonl` telemetry were deleted. Empirical reason: across every real project those channels stayed empty, and the single disable test that ever ran (user-simulation, 2026-05-08, `recurring_failure_patterns`) was wrong and had to be reverted by hand the same day. Assumption-testing-by-auto-disable imported an industrial-harness pattern that never closed a cycle at single-project scale. Component changes now go through ordinary REMOVE/MODIFY proposals (Phase 3) with human review.

### 5a. Post-Plan Correction Mining (highest-value signal)

This is the load-bearing input — it produced the most valuable checklist evolution in practice. For each plan's post-plan-diff (Phase 1 step 6): when `feedback`-classified commits (refactor/fix/style/perf on plan-modified files) cluster around a pattern no batch evaluator flagged, that is a real evaluator coverage gap. Render the corrections table (`./references/post-plan-diff.md` §Phase 5a) and graduate each missed pattern to a **Phase 3 ADD proposal at 1-plan evidence**. This catches what grep-based checks cannot: consistency, API-contract, and coverage gaps. (This is exactly how user-simulation's CODE-CONTRACT/CONS/COV items were added.)

### 5b. Usage-Driven Recommendations (report notes only)

- If all tasks pass first round (no REWORK) across 3+ plans, note that per-batch evaluation may be reducible — a candidate for a future Phase 3 MODIFY/REMOVE, not an automatic change.
- If a mode's checklist has only regression items all passing across 3+ plans, recommend a spot-check cadence in the report.

These are report notes. Never disable a component from this phase. Never-failing items are handled by Phase 3 REMOVE proposals (3+ reports threshold) — do not duplicate.

## Phase 6: Output

Write the retrospective report to `docs/retros/retro-{date}-{topic}.md`:

1. Analysis tables (failure frequency, plateaus, never-failing, variety gaps)
2. Proposals with approval status
3. Checklist versions updated (if any)
4. Harness Health notes (5a post-plan corrections mined into ADD proposals; 5b informational recommendations)
5. Summary: N proposals approved, M rejected, checklists updated to version X

**Close the calibration loop** — **CRITICAL: do this before you stop, not after the report "feels done."** Append one `retrospective_run` row to `docs/retros/evolution-log.jsonl` via the canonical emit pattern in `./references/evolution-protocol.md` §"Canonical Emit Invocations", recording `proposals_approved` and `proposals_rejected`. This row is the closure marker the *next* run's auto-scope (Phase 1 step 1) reads to avoid re-analyzing these plans — skip it and the next retrospective silently re-analyzes already-analyzed plans, re-proposing the same changes. Do not skip it even when zero proposals were approved. The Stop hook (`hooks/stop-state-sync.sh`) backfills a minimal watermark from this run's `retro-*.md` report if you drop this, but only your emit carries `proposals_approved` / `proposals_rejected` / `plans_analyzed` — so write the rich row here.

## References

- `./references/analysis-patterns.md` - Failure frequency, plateau detection, never-failing analysis
- `./references/evolution-protocol.md` - Proposal types, thresholds, version management, evolution log schema, pre-edit snapshot
- `../../skills/references/goal-wrapper.md` - `/goal` wrapper semantics and condition phrasing (shared)
- `${CLAUDE_PLUGIN_ROOT}/lib/post-plan-diff.sh` - classifies post-plan commits as `feedback` (refactor/fix/style/perf — user correcting superpowers output) or `evolution` (feat/chore/docs/build/ci/test — user adding new requirements). Used by the Pre-Check and Phase 1 step 6 to mine the post-plan correction signal (Phase 5a)
