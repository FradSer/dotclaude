---
name: retrospective
description: Analyzes evaluation patterns across completed specs/tickets and evolves the superdev checklists accordingly. Use when the user asks to "run a retrospective", "evolve checklists", "analyze evaluation patterns", or after multiple /superdev:code-review runs have accumulated verdicts worth learning from.
argument-hint: "[spec-or-ticket-path-1] [...]"
disable-model-invocation: true
allowed-tools: ["Read", "Glob", "Grep", "Write", "Edit", "Bash(python3:*)", "Bash(git:*)", "Bash(${CLAUDE_PLUGIN_ROOT}/lib/seed-checklists.sh:*)"]
---

# Retrospective

Analyze evaluation patterns across completed specs/tickets, identify recurring failures, and auto-apply checklist evolution — the self-improvement subsystem that closes the loop on `/superdev:code-review` verdicts.

This is the superdev re-implementation of the superpowers retrospective, adapted to the mattpocock spec/ticket workflow (`design`→`spec`, `plan`→`tickets`, `code` kept).

**Outputs are flat state, not process files.** The only persistent artifacts are: the current checklists (`docs/retros/checklist-{mode}.md`), the single evolving report (`docs/retros/retrospective.md`), and the index (`docs/retros/README.md`). No evaluation files, no logs, no versioned checklists — git is the version layer and the audit trail. Every change below is committed (or staged for the user to review and commit).

## Phase 0: Bootstrap (run only when no checklists exist)

Check whether `docs/retros/checklist-{mode}.md` exists for each mode (spec / tickets / code). Seed only the modes missing a checklist — if all three exist, log `Phase 0: all checklists present, skipping seed` and proceed. Full procedure (Path A vs. Path B Full History Bootstrap, exit codes, `--force` reset): `./references/bootstrap.md`.

## Phase 1: Data Collection

1. **Resolve inputs**: Parse `$ARGUMENTS` for spec/ticket paths — each points at a completed spec or ticket set (its location per the issue tracker: `docs/specs/`, `docs/tickets/`, `.scratch/`, or a tracker). If no argument is given, ask which specs/tickets to analyze.
2. **Gather evaluation signal**: For each path, collect the evaluation results — the checklist PASS/FAIL outcomes from the `/superdev:code-review` runs and the self-evaluate steps of `/superdev:to-spec` / `/superdev:to-tickets` (from this conversation if the work happened here, or the committed artifacts alongside the work). No separate evaluation files exist; read the produced artifacts and the review outcomes directly.
3. **Read checklists**: Read `docs/retros/checklist-{mode}.md` for each mode in scope.
4. **Minimum data check**: With only 1 spec/ticket, warn that ADD proposals require 2+ (the single-spec post-correction override is documented in `./references/evolution-protocol.md`); REMOVE needs 3+ reports with zero failures.

## Phase 2: Pattern Analysis

Aggregate data across all specs/tickets (detailed logic: `./references/analysis-patterns.md`).

1. **Failure frequency**: Count distinct specs/tickets where each checklist item FAILed. Rank by frequency descending.
2. **Plateau tickets**: Identify tickets that were REWORK across 2+ consecutive evaluation rounds; extract the root cause.
3. **Never-failing items**: Items with 0 FAILs across 3+ evaluation reports are REMOVE candidates.
4. **Variety gaps**: Specs/tickets where all items PASS but 2+ rework rounds occurred — the checklist missed the failure mode.
5. **Post-correction mining (advisory)**: scan git history for commits correcting superdev output (`refactor:`/`fix:`/`style:`/`perf:` on spec/ticket-related files after the code-review verdict) and log them as ADD candidates — this is the strongest checklist-evolution signal available, mined from git.

Output a structured analysis report with tables for each category.

## Phase 3: Evolution Proposals

Generate proposals from analysis results (format details: `./references/evolution-protocol.md`).

| Type | Trigger and threshold |
|------|-----------------------|
| ADD | Failure pattern in 2+ distinct specs/tickets with no covering item |
| REMOVE | 0 failures across 3+ reports per item |
| MODIFY | 2+ false positives (FAIL overturned in rework) |
| PROMOTE | Capability item pass rate >80% across 3+ successive specs/tickets |

**Rate limit (EVO-6)**: Max 3 proposals per mode per run; defer excess with evidence.

**Counter monotonic growth (REMOVE is load-bearing)**: each run, actively scan for never-firing items and propose REMOVE — a checklist that only grows is a calibration failure, not success.

Each proposal includes: type, target checklist, item ID, description, rationale with spec/ticket evidence.

## Phase 4: Auto-Apply Proposals

Apply every Phase 3 proposal (regression breaks first, then by frequency). No per-proposal approval gate — EVO-6 + thresholds are the quality surface; the user reviews the diff post-run.

Apply steps:

1. **Edit in place**: Apply all proposals to the current `docs/retros/checklist-{mode}.md` — rewrite the file with the applied changes. The prior content is recoverable from git (`git diff`), so no snapshot is kept in the report. For each applied ADD, include the `**Origin:**` line (New Item Template in `./references/evolution-protocol.md`) citing the triggering spec/ticket or commit. In the same pass, update the file header's `- **Last evolution:**` line with a one-line summary of this run's changes (e.g. `add SPEC-CONC-03; remove SPEC-DEAD-01`).
2. **Draft memory files**: for each applied ADD or MODIFY, draft one `docs/memory/<category>_<slug>.md` (`convention` for a structural rule, `pitfall` for a recurring failure mode, `decision` for a rejected-vs-chosen call), using the proposal's description and rationale as content and `source:` citing the item's Origin evidence (spec/ticket path or `commit:<sha>`), falling back to this run's report. Additionally, for each Phase 2 plateau (2+ consecutive REWORK, same cause) or variety gap (all PASS, 2+ rework rounds) root cause with no Phase 3 proposal covering it (applied or deferred) — the failure is in how the work was done, not in what the checklist checks — draft one `docs/memory/pitfall_<slug>.md` from the root-cause analysis (same 2+ thresholds as Phase 2, no new ones). A root cause covered by an ADD/MODIFY proposal is NOT drafted here — that proposal's memory file covers it. REMOVE and PROMOTE proposals do NOT trigger this step. Follow the memory file format (`docs/memory-layer-status.md`).
3. **Commit the evolution**: `git add docs/retros/checklist-{mode}.md` (and any drafted memory files) and commit with a message naming the item changes, e.g. `retro(spec): add SPEC-CONC-03, remove SPEC-DEAD-01`. **REMOVE items must carry their rationale in the message body** — after the overwrite, a removed item exists nowhere else (not the checklist, not the overwritten report), so the commit message is its only persistent "why": one bullet per removed item citing its zero-failure evidence count, e.g. `retro(code): remove CODE-DEAD-01 — 8 reports, 0 FAILs`. This commit IS the audit trail — checklist evolution is `git log` on the file.

## Phase 5: Output

Write the retrospective report to `docs/retros/retrospective.md` — the single evolving report, overwritten by this run (prior content stays in git history):

1. Analysis tables (failure frequency, plateaus, never-failing, variety gaps, post-correction candidates)
2. Proposals with approval status
3. Checklist changes applied (item IDs, before/after summaries)
4. Summary: N proposals approved, M rejected, checklists updated

Then update `docs/retros/README.md` — the index — reflecting the current state: each checklist row mirrors that checklist's `- **Last evolution:**` header line (the checklist header is the single source of truth; the index cites it, never re-derives it) plus the report's updated date. Commit the report and index with the checklist changes or in the same commit.

## References

- `./references/bootstrap.md` - Phase 0 procedure: Path A/B, exit codes, `--force` reset
- `./references/analysis-patterns.md` - Failure frequency, plateau detection, never-failing analysis
- `./references/evolution-protocol.md` - Proposal types, thresholds, item templates, git-as-audit-trail
