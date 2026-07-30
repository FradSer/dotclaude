---
name: retrospective
description: Analyzes evaluation patterns across completed specs/tickets and evolves the superdev checklists accordingly. Use when the user asks to "run a retrospective", "evolve checklists", "analyze evaluation patterns", or after multiple /superdev:code-review runs have accumulated verdicts worth learning from.
argument-hint: "[spec-or-ticket-path-1] [...] [--across-all]"
disable-model-invocation: true
allowed-tools: ["Read", "Glob", "Grep", "Write", "Edit", "Bash(python3:*)", "Bash(git:*)", "Bash(${CLAUDE_PLUGIN_ROOT}/lib/seed-checklists.sh:*)", "Bash(${CLAUDE_PLUGIN_ROOT}/lib/jsonl-emit.sh:*)"]
---

# Retrospective

Analyze evaluation patterns across completed specs/tickets, identify recurring failures, and auto-apply checklist evolution — the self-improvement subsystem that closes the loop on `/superdev:code-review` verdicts. The user reviews post-commit via `git show docs/retros/checklists/`.

This is the superdev re-implementation of the superpowers retrospective, adapted to the mattpocock spec/ticket workflow: `design`→`spec`, `plan`→`tickets`, `code` kept. The lib surface is trimmed to two scripts (`jsonl-emit.sh`, `seed-checklists.sh`); the post-plan-diff miner and docs-index are folded into prose or dropped.

## Phase 0: Bootstrap (run only when no checklists exist)

Before Phase 1, check whether `docs/retros/checklists/` contains `{mode}-v1.md` for each mode (spec / tickets / code). Phase 0 runs per-mode independently — seed only the modes missing a v{N} file; if all three are present, log `Phase 0: all checklists present, skipping seed` and proceed. Full procedure (Path A vs. Path B Full History Bootstrap, exit codes, `--force` reset): `./references/bootstrap.md`.

## Phase 1: Data Collection

1. **Resolve inputs**: Parse `$ARGUMENTS` for spec/ticket paths. If `--across-all`, scan `docs/specs/` and `docs/tickets/` for all artifacts with evaluation reports. If no argument is given and `docs/retros/evolution-log.jsonl` exists, auto-scope to specs/tickets completed after the most recent `retrospective_run` event.
2. **Resolve evals**: For each spec/ticket path, read evaluation reports produced by `/superdev:code-review` (saved wherever the issue tracker or repo puts them — look for `evaluation-round-*.md` or the code-review output committed alongside the work).
3. **Read checklists**: Scan `docs/retros/checklists/` for each mode's latest `{mode}-v{N}.md` (highest N).
4. **Read reports**: Read each spec/ticket's evaluation reports; extract per-item results (Item ID, Result, Evidence) and rework items.
5. **Read evolution history** (calibration input): Read `docs/retros/evolution-log.jsonl` if present; build a history table keyed by `item_id` (most recent event, timestamp, rationale). This feeds Phase 3 — do NOT re-propose an `ADD` for an item `REMOVE`d in the most recent retrospective unless the new evidence is materially different; cite the historical entry in any such proposal.
6. **Minimum data check**: With only 1 spec/ticket, warn that ADD proposals require 2+ (the single-spec post-correction override is documented in `./references/evolution-protocol.md`); REMOVE needs 3+ reports with zero failures.

## Phase 2: Pattern Analysis

Aggregate data across all specs/tickets (detailed logic: `./references/analysis-patterns.md`).

1. **Failure frequency**: Count distinct specs/tickets where each checklist item FAILed. Rank by frequency descending.
2. **Plateau tickets**: Identify tickets that were REWORK across 2+ consecutive evaluation rounds; extract the root cause.
3. **Never-failing items**: Items with 0 FAILs across 10+ evaluation reports are REMOVE candidates.
4. **Variety gaps**: Specs/tickets where all items PASS but 2+ rework rounds occurred — the checklist missed the failure mode.
5. **Post-correction mining (advisory)**: if you notice commits correcting superdev output (`refactor:`/`fix:`/`style:`/`perf:` on spec/ticket-related files after the code-review verdict), log them as ADD candidates — this is the strongest checklist-evolution signal available, mined from git rather than from any dropped lib script.

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

Apply every Phase 3 proposal (regression breaks first, then by frequency). No per-proposal approval gate — EVO-6 + thresholds + post-commit `git show docs/retros/checklists/` are the quality surface. `proposals_rejected` is reserved for self-rejection at apply time: a proposal duplicating a recent removal (Phase 1 step 5) without materially new evidence is logged under "Self-Rejected Proposals" with the cited entry, increments `proposals_rejected`, and skips the checklist row. All others advance.

Apply steps:

1. **Pre-edit snapshot**: Write current checklist content to the retrospective report under "Pre-Edit Snapshot" with rollback instructions.
2. **Create new version**: Write `{mode}-v{N+1}.md` with all applied changes. Version increments once per run (not per proposal). Original version preserved unchanged.
3. **Log evolution** — **CRITICAL: a proposal is NOT "applied" until its evolution-log row exists.** Immediately after writing the new version file, append one row per applied proposal to `docs/retros/evolution-log.jsonl` via `lib/jsonl-emit.sh` with `<channel>=evolution-log` and event `item_added | item_removed | item_modified | item_promoted` — emit per-proposal, do NOT defer to the end of the run (canonical invocation: `./references/evolution-protocol.md` §"Canonical Emit Invocations"). These rows feed Phase 1 step 5's re-proposal guard — a dropped `item_removed` row silently re-adds the just-removed item next run.
4. **Draft memory files for applied ADD/MODIFY proposals**: for each ADD or MODIFY applied this run (post-self-rejection), draft one `docs/memory/<category>_<slug>.md` (`convention` for a structural rule, `pitfall` for a recurring failure mode, `decision` for a rejected-vs-chosen call), using the proposal's description and rationale as content and `source:` citing this run's retro report path. REMOVE and PROMOTE proposals, even if applied, do NOT trigger this step.
5. **Verify the log** — **CRITICAL self-check, do NOT skip:** before leaving Phase 4, count evolution-log rows whose `checklist_version` equals this run's version(s) and confirm the count equals `proposals_approved`; emit any missing rows now.

## Phase 5: Output

Write the retrospective report to `docs/retros/retro-{date}-{topic}.md`:

1. Analysis tables (failure frequency, plateaus, never-failing, variety gaps, post-correction candidates)
2. Proposals with approval status
3. Checklist versions updated (if any)
4. Summary: N proposals approved, M rejected, checklists updated to version X

**Close the calibration loop** — **CRITICAL: do this before you stop, even when zero proposals were approved.** Append one `retrospective_run` row to `docs/retros/evolution-log.jsonl` via the canonical emit pattern (`./references/evolution-protocol.md` §"Canonical Emit Invocations"), recording `proposals_approved` and `proposals_rejected`. This row is the closure marker the *next* run's auto-scope reads — skip it and the next retrospective silently re-analyzes these specs/tickets.

## References

- `./references/bootstrap.md` - Phase 0 procedure: Path A/B, exit codes, `--force` reset
- `./references/analysis-patterns.md` - Failure frequency, plateau detection, never-failing analysis
- `./references/evolution-protocol.md` - Proposal types, thresholds, log schema, canonical emits, history
