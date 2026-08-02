# Evolution Protocol Reference

Checklist evolution rules: proposal types, thresholds, application, and git-as-audit-trail. Adapted from superpowers' evolution-protocol for the superdev spec/ticket workflow (`design`→`spec`, `plan`→`tickets`, `code` kept).

## Proposal Types

| Type | Description | Threshold | Priority |
|------|-------------|-----------|----------|
| ADD | New checklist item for uncovered failure pattern | FAILs in 2+ distinct specs/tickets | HIGH |
| REMOVE | Remove item that never detects issues | 0 FAILs across 3+ reports | LOW |
| MODIFY | Tighten or relax an existing item's check method | 2+ false positives (FAIL overturned in rework) | MEDIUM |
| PROMOTE | Reclassify capability item to regression | Pass rate >80% across 3+ successive specs/tickets | LOW |

## Rate Limit (EVO-6)

Maximum 3 proposals per mode per retrospective run. If analysis produces more:
- Surface the top 3 by priority (ADD > MODIFY > PROMOTE > REMOVE)
- List deferred proposals with full evidence in the report
- Note: "N proposals deferred -- rerun retrospective after applying current approvals"

## Proposal Presentation

Each proposal is recorded inline in the retrospective report using this shape, then auto-applied in Phase 4 — there is no per-proposal approval gate. The post-run `git diff docs/retros/` is the review surface.

```
Proposal: [ADD/REMOVE/MODIFY/PROMOTE] [mode]/[Item ID]
Description: [what the item checks]
Rationale: [why this change is needed]
Evidence: [spec-1 tickets X, Y -- spec-2 ticket Z -- specific failure pattern]
Outcome: applied
```

## Version Management — git is the version layer

Checklists are flat, unversioned files (`docs/retros/checklist-{mode}.md`) that the retrospective edits **in place**. There are no `v{N}` files and no in-report snapshots:

- **Evolution** = a commit: Phase 4 edits the file, then `git add docs/retros/checklist-{mode}.md` + commit (`retro(<mode>): add X, remove Y`). **REMOVE rationale lives in the message body** (e.g. `retro(code): remove CODE-DEAD-01 — 8 reports, 0 FAILs`): the overwritten checklist and report no longer contain the removed item, so the message is the sole persistent record of why it died — and the Re-proposal Guard (below) reads it.
- **History and rollback** = `git log` / `git show <sha> -- docs/retros/checklist-{mode}.md` / `git revert`.
- **Never rewrite history**: an evolution commit stays as-is; correct a mistake with a follow-up commit, not an amend.

## New Item Template

When creating an ADD item, append to the checklist file:

```markdown
### {ITEM-ID}: {description}

**Description:** {what this check verifies}

**Origin:** {where this item came from — the triggering spec/ticket path(s) plus the item that failed to catch it, or `commit:<sha>` for a post-correction-mined ADD}

**Check method:**
```bash
{executable check command}
```

**Evidence format:** {how to report findings}

**Rework format:** {corrective instruction template}

`# Type: computational|inferential` -- {why this check is deterministic, or where judgment enters}
```

**Origin is provenance, written once.** The `**Origin:**` line records why the item exists, not what it checks. Phase 4 step 1 writes it at ADD time; MODIFYs rewrite the item body but never the Origin. It answers "why does this check exist" without git archaeology — full detail stays in the file's git history.

## Re-proposal Guard

When a proposal would re-add an item that a prior retrospective removed, check the file's git history (`git log -p -- docs/retros/checklist-{mode}.md`) for the removal commit and its rationale. Do not re-propose unless the new evidence is materially different from the removal rationale — cite the prior removal in any such proposal (e.g., "Re-adding SPEC-CONC-03: prior removal on 2025-12-01 was based on N=8 zero-failure reports; new evidence is FAIL in 4 specs since 2026-02-01.").

## Retrospective Report — the single evolving report

Output file: `docs/retros/retrospective.md` — one file, overwritten each run. Prior content survives in git history.

```markdown
# Retrospective: {topic}

**Date**: {date}
**Specs/tickets analyzed**: {list}

## Failure Frequency
{table}

## Plateau Tickets
{table}

## Never-Failing Items
{table}

## Variety Gaps
{table}

## Post-Correction Candidates
{table}

## Evolution Proposals

| # | Type | Mode | Item ID | Status |
|---|------|------|---------|--------|
| 1 | ADD | spec | SPEC-CONC-03 | APPLIED |

## Summary
- Proposals: N applied, M rejected, K deferred
- Checklists updated: checklist-spec.md, checklist-tickets.md
- Memory files drafted: docs/memory/...
- Next action: run retrospective again after 2+ more spec/ticket executions
```

## History: Removed Mechanisms and Threshold Calibration

**Removed in superdev — the process-file layer.** The superpowers design kept an append-only `evolution-log.jsonl` (watermark + audit), a Stop hook that backfilled dropped log rows, a `lib/post-plan-diff.sh` post-plan miner, per-mode versioned checklist files, and pre-edit snapshots in each report. superdev drops all of them (mattpocock minimalist principle): git commits are the audit trail and the version layer, the post-correction signal is mined from git inline (Phase 2 step 5, no dedicated lib), and the report is a single overwritten file. If empirical audit shows a need for cross-run statistics, re-add a structured log then.

**Why the REMOVE threshold is 3+ reports/item (was 10+).** ADD is cheap to trigger while REMOVE used to require 10+ reports/item — a volume real single-project usage never reaches, so checklists only ever grew. The 3+ threshold is deliberately reachable so the loop can shrink checklists, not only grow them.
