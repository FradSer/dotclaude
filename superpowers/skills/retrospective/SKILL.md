---
name: retrospective
description: This skill should be used when the user wants to analyze evaluation patterns across completed plans and evolve checklists. Triggered by asking to "run a retrospective", "analyze evaluation patterns", "evolve checklists", or "/superpowers:retrospective". For autonomous multi-turn runs, invoke wrapped in `/goal`.
argument-hint: <plan-path-1> [plan-path-2] [--across-all]
user-invocable: true
allowed-tools: ["Read", "Glob", "Grep", "Write", "Edit", "Bash(python3:*)", "Bash(git:*)", "Bash(${CLAUDE_PLUGIN_ROOT}/lib/seed-checklists.sh:*)", "Bash(${CLAUDE_PLUGIN_ROOT}/lib/post-plan-diff.sh:*)", "Bash(${CLAUDE_PLUGIN_ROOT}/lib/jsonl-emit.sh:*)", "Bash(${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh:*)"]
---

# Retrospective

Analyze evaluation patterns across completed plans, identify recurring failures, and auto-apply checklist evolution — the downstream consumer of executing-plans Phase 4 "Checklist Evolution Candidates". The user reviews post-commit via `git show docs/retros/checklists/`.

## Recommended: run wrapped in `/goal`

**Launch it under Claude Code's built-in `/goal`** (v2.1.139+) — a retrospective can span multiple turns:

```
/goal "Claude has narrated a successful checklist-evolution commit (with commit hash) and stated the retrospective is complete" /superpowers:retrospective <plan-paths>
```

`/goal` is a **user-typed outer wrapper** (a skill cannot enable it for itself mid-run), and its evaluator judges only what Claude narrates in the transcript — phrase the condition against narrated output (the commit-hash line, an explicit completion statement), never filesystem state. Full semantics and condition phrasing: `../../skills/references/goal-wrapper.md`.

## Pre-Check (run first, in order)

### A. INSUFFICIENT-POST-PLAN advisory (informational)

Read the most recent `plan_completed` event from `docs/retros/plans-completed.jsonl`. If `hours_since_completion < 24h` AND `bash "${CLAUDE_PLUGIN_ROOT}/lib/post-plan-diff.sh" summary <completion_commit> <files...>` returns `total == 0`, output the INSUFFICIENT-POST-PLAN reminder verbatim (see `./references/post-plan-diff.md` §Pre-Check A) and proceed to Phase 0 — do NOT pause. Skip silently when `completion_commit` is missing.

### B. Recall persistent memory (calibration priors)

**CRITICAL — do this before Phase 0, do NOT skip it as setup.** Persistent memory holds the human judgments the evolution-log cannot capture. Recall is a SECONDARY calibration signal — `docs/retros/evolution-log.jsonl` (Phase 1 step 5) stays authoritative; when they disagree, the log wins.

The `MEMORY.md` index hooks are ALREADY in your context (injected at session start) — read nothing from disk. Scan them now and select the ones bearing on this run: prior evolution/rejection decisions and debt trackers, harness-design principles, and working-style feedback. Carry them forward as priors into Phase 1 step 5 (calibration history), Phase 3 (suppression of weakly-justified ADDs), and Phase 4 (self-reject a proposal that contradicts a recalled prior, citing the memory entry). If no calibration-relevant hook exists, log `Pre-Check B: no calibration-relevant memory` and proceed. Never resolve a memory path, read a topic file, block, or ask — the index hooks carry the signal on their own.

When a recalled hook cited as evidence for an approved Phase 3 proposal proves project-specific and durable, the Phase 4 step 3.5 draft records `Promoted from private assistant memory hook: <hook-name>, <date>` in its `## Why` section — cross-project harness-design stances are NOT promoted, and the private hook is never deleted or modified.

## Phase 0: Bootstrap (run only when no checklists exist)

Before Phase 1, check whether `docs/retros/checklists/` contains `{mode}-v1.md` for each mode (design / plan / code). Phase 0 runs per-mode independently — seed only the modes missing a v{N} file; if all three are present, log `Phase 0: all checklists present, skipping seed` and proceed. Full procedure (Path A vs. Path B Full History Bootstrap, exit codes, `--force` reset): `./references/bootstrap.md`.

## Phase 1: Data Collection

1. **Resolve inputs**: Parse `$ARGUMENTS` for plan paths. If `--across-all`, scan `docs/plans/` for all `*-plan/` directories with evaluation reports. If no argument is given, read `docs/retros/plans-completed.jsonl` and auto-scope to plans completed after the most recent `retrospective_run` event in `docs/retros/evolution-log.jsonl`. Complement the log via the docs index: `bash "${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh" list --kind plan --status implemented` scopes shipped plans; `bash "${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh" list --status expired` surfaces prior expirations as calibration input (read an expired plan's retro report before re-proposing anything that touches it). Also consult memory: `bash "${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh" list --kind memory --status active`; fold matches into Phase 2 analysis as calibration input.
2. **Resolve evals**: For each plan path, read evaluation reports (`evaluation-round-*.md`, `evaluation-design-round-*.md`, `evaluation-plan-round-*.md`) from the plan directory, or from a sibling `*-evals/` directory when one exists.
3. **Read checklists**: Scan `docs/retros/checklists/` for each mode's latest `{mode}-v{N}.md` (highest N).
4. **Read reports**: Read each plan's evaluation reports; extract per-item results (Item ID, Result, Evidence) and rework items.
5. **Read evolution history** (calibration input): Read `docs/retros/evolution-log.jsonl` if present; build a history table keyed by `item_id` (most recent event, timestamp, rationale). This feeds Phase 3 — do NOT re-propose an `ADD` for an item `REMOVE`d in the most recent retrospective unless the new evidence is materially different; cite the historical entry in any such proposal.
6. **Read post-plan diff**: For each plan with a `completion_commit` field, run `bash "${CLAUDE_PLUGIN_ROOT}/lib/post-plan-diff.sh" list <completion_commit> <completion_modified_files...>` and pass the classified commit list to Phase 5a (classification rules and skip conditions: `./references/post-plan-diff.md`).

7. **Minimum data check**: With only 1 plan, warn that ADD proposals require 2+ plans (except the Phase 5a post-plan-diff 1-plan override); REMOVE needs 3+ reports with zero failures.

## Phase 2: Pattern Analysis

Aggregate data across all plans (detailed logic: `./references/analysis-patterns.md`).

1. **Failure frequency**: Count distinct plans where each checklist item FAILed. Rank by frequency descending.
2. **Plateau tasks**: Identify tasks that were REWORK across 2+ consecutive evaluation rounds in any plan; extract the root cause from rework items.
3. **Never-failing items**: Items with 0 FAILs across 10+ evaluation reports are REMOVE candidates.
4. **Variety gaps**: From executing-plans completion summaries, find batches where all items PASS but 2+ rework rounds occurred -- the checklist missed the failure mode.

Output a structured analysis report with tables for each category.

## Phase 3: Evolution Proposals

Generate proposals from analysis results (format details: `./references/evolution-protocol.md`).

| Type | Trigger and threshold |
|------|-----------------------|
| ADD | Failure pattern in 2+ distinct plans with no covering item |
| REMOVE | 0 failures across 3+ reports per item |
| MODIFY | 2+ false positives (FAIL overturned in rework) |
| PROMOTE | Capability item pass rate >80% across 3+ successive plans |

**Rate limit (EVO-6)**: Max 3 proposals per mode per run; defer excess with evidence.

**Counter monotonic growth (REMOVE is load-bearing)**: each run, actively scan for never-firing items and propose REMOVE — a checklist that only grows is a calibration failure, not success. The 3+ reports/item threshold is deliberately reachable (rationale and history: `./references/evolution-protocol.md` §History).

**Memory-file consolidation (reuses the MODIFY threshold, 2+ instances)**: when Phase 2 surfaces 2+ active `kind=memory` files covering the same concept, propose a MODIFY merging them into one surviving file. When applied in Phase 4, fold the absorbed file's content into the survivor, then run `bash "${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh" set-status <absorbed-path> "expired:superseded-by-consolidation:<survivor-path>"` — the collapse rule then drops the row.

Each proposal includes: type, target checklist, item ID, description, rationale with plan evidence.

## Phase 4: Auto-Apply Proposals

Apply every Phase 3 proposal (regression breaks first, then by frequency). No per-proposal approval gate — EVO-6 + thresholds + post-commit `git show docs/retros/checklists/` are the quality surface. `proposals_rejected` is reserved for self-rejection at apply time: a proposal duplicating a recent removal (Phase 1 step 5) or contradicting a recalled memory prior (Pre-Check B) without materially new evidence is logged under "Self-Rejected Proposals" with the cited entry, increments `proposals_rejected`, and skips the checklist row. All others advance.

Apply steps:

1. **Pre-edit snapshot**: Write current checklist content to the retrospective report under "Pre-Edit Snapshot" with rollback instructions
2. **Create new version**: Write `{mode}-v{N+1}.md` with all applied changes. Version increments once per run (not per proposal). Original version preserved unchanged.
3. **Log evolution** — **CRITICAL: a proposal is NOT "applied" until its evolution-log row exists.** Immediately after writing the new version file, append one row per applied proposal to `docs/retros/evolution-log.jsonl` via `lib/jsonl-emit.sh` with `<channel>=evolution-log` and event `item_added | item_removed | item_modified | item_promoted` — emit per-proposal, do NOT defer to the end of the run (canonical invocation: `./references/evolution-protocol.md` §"Canonical Emit Invocations"). These rows feed Phase 1 step 5's re-proposal guard — a dropped `item_removed` row silently re-adds the just-removed item next run. The Stop hook backfill is all-or-nothing and carries no rationale; the in-skill emit is authoritative and must run.
3.5. **Draft memory files for applied ADD/MODIFY proposals**: for each ADD or MODIFY applied this run (post-self-rejection), draft one `docs/memory/<category>_<slug>.md` (`convention` for a structural rule, `pitfall` for a recurring failure mode, `decision` for a rejected-vs-chosen call), using the proposal's description and rationale as `Fact`/`Why` content and `source:` citing this run's retro report path. REMOVE and PROMOTE proposals, even if applied, do NOT trigger this step.
4. **Verify the log** — **CRITICAL self-check, do NOT skip:** before leaving Phase 4, count evolution-log rows whose `checklist_version` equals this run's version(s) and confirm the count equals `proposals_approved`; emit any missing rows now. This guards against a *partial* drop the hook's all-or-nothing backfill cannot catch.

## Phase 5: Harness Health (advisory)

Surface components that may no longer earn their cost and turn post-plan corrections into checklist proposals. Everything here is advisory — it feeds Phase 3 proposals and the Phase 6 report, reviewed via the post-commit diff. Phase 5 never disables a component or mutates the harness (the automated disable-test loop was removed in v2.9.0; history: `./references/evolution-protocol.md` §History).

### 5a. Post-Plan Correction Mining (highest-value signal)

This is the load-bearing input (provenance: `./references/evolution-protocol.md` §History). For each plan's post-plan-diff (Phase 1 step 6): when `feedback`-classified commits (refactor/fix/style/perf on plan-modified files) cluster around a pattern no batch evaluator flagged, that is a real evaluator coverage gap. Render the corrections table (`./references/post-plan-diff.md` §Phase 5a) and graduate each missed pattern to a **Phase 3 ADD proposal at 1-plan evidence**. This catches what grep-based checks cannot: consistency, API-contract, and coverage gaps.

### 5b. Usage-Driven Recommendations (report notes only)

- All tasks passing first round (no REWORK) across 3+ plans → note that per-batch evaluation may be reducible (a future Phase 3 MODIFY/REMOVE candidate, not an automatic change).
- A mode's checklist all-regression and all-passing across 3+ plans → recommend a spot-check cadence.

Report notes only — never disable a component here; never-failing items belong to Phase 3 REMOVE proposals (do not duplicate).

## Phase 6: Output

Write the retrospective report to `docs/retros/retro-{date}-{topic}.md`:

1. Analysis tables (failure frequency, plateaus, never-failing, variety gaps)
2. Proposals with approval status
3. Checklist versions updated (if any)
4. Harness Health notes (5a corrections mined into ADD proposals; 5b recommendations)
5. Summary: N proposals approved, M rejected, checklists updated to version X
6. **Upsert retro report into the docs index**: `bash "${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh" upsert retro <retro-report-path> --status active --summary "<one-line>"` (same string as the report's summary line).
7. **CRITICAL — invalidate-after (do-not-defer, retrospective-only).** For each `invalidates: <path>` line in the just-written retro report, run `bash "${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh" set-status <path> "expired:retro-<date>:<reason>"`. If `set-status` returns exit 3 (path not tracked), log a warning and skip — do NOT upsert speculative entries just to mark them expired. **CRITICAL boundary — a checklist-item REMOVE does NOT invalidate a design**: a Phase 3 REMOVE evolves the checklist, not the design folder; only an explicit `invalidates: <path>` line triggers `set-status expired:` — separate channels. Expiry is retrospective-only — the other writer skills may NOT set `expired:`; only this step does.
8. **Upsert drafted memory files**: for each memory file drafted in Phase 4 step 3.5, run `bash "${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh" upsert memory docs/memory/<path> --status active --summary "<one-line>" --category <category>`.

**Close the calibration loop** — **CRITICAL: do this before you stop, even when zero proposals were approved.** Append one `retrospective_run` row to `docs/retros/evolution-log.jsonl` via the canonical emit pattern (`./references/evolution-protocol.md` §"Canonical Emit Invocations"), recording `proposals_approved` and `proposals_rejected`. This row is the closure marker the *next* run's auto-scope reads — skip it and the next retrospective silently re-analyzes these plans. The Stop hook backfills a minimal watermark if you drop this, but only your emit carries `proposals_approved` / `proposals_rejected` / `plans_analyzed` — write the rich row here.

## References

- `./references/bootstrap.md` - Phase 0 procedure: Path A/B, exit codes, `--force` reset
- `./references/analysis-patterns.md` - Failure frequency, plateau detection, never-failing analysis
- `./references/evolution-protocol.md` - Proposal types, thresholds, log schema, canonical emits, history
- `../../skills/references/goal-wrapper.md` - `/goal` wrapper semantics and condition phrasing (shared)
- `${CLAUDE_PLUGIN_ROOT}/lib/post-plan-diff.sh` - classifies post-plan commits as `feedback` (user correcting superpowers output) or `evolution` (user adding new requirements); feeds Pre-Check A, Phase 1 step 6, and Phase 5a
