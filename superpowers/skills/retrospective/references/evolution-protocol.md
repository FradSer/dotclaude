# Evolution Protocol Reference

Checklist evolution rules: proposal types, thresholds, versioning, and audit trail.

## Proposal Types

| Type | Description | Threshold | Priority |
|------|-------------|-----------|----------|
| ADD | New checklist item for uncovered failure pattern | FAILs in 2+ distinct plans | HIGH |
| REMOVE | Remove item that never detects issues | 0 FAILs across 10+ reports | LOW |
| MODIFY | Tighten or relax an existing item's check method | 2+ false positives (FAIL overturned in rework) | MEDIUM |
| PROMOTE | Reclassify capability item to regression | Pass rate >80% across 3+ successive plans | LOW |

## Rate Limit (EVO-6)

Maximum 3 proposals per mode per retrospective run. If analysis produces more:
- Surface the top 3 by priority (ADD > MODIFY > PROMOTE > REMOVE)
- List deferred proposals with full evidence in the report
- Note: "N proposals deferred -- rerun retrospective after applying current approvals"

## Proposal Presentation

Each proposal presented via AskUserQuestion:

```
Proposal: [ADD/REMOVE/MODIFY/PROMOTE] [mode]/[Item ID]
Description: [what the item checks]
Rationale: [why this change is needed]
Evidence: [plan-1 tasks X, Y -- plan-2 task Z -- specific failure pattern]
```

Options: "Approve", "Reject", "Defer to next run"

## Pre-Edit Snapshot

Before writing any checklist modification:

1. Read the full content of the target checklist file
2. Write it to the retrospective report under:
   ```markdown
   ## Pre-Edit Snapshot: {mode}-v{N}.md

   <full file content>

   Rollback: copy the above content to docs/retros/checklists/{mode}-v{N}.md
   ```
3. Only after the snapshot is written, proceed with file creation

## Version Management

Rules:
- **Never mutate** existing checklist files -- always create a new version
- Version counter increments **once per retrospective run** (not per proposal)
- All approved proposals for a mode are applied to the same new version
- File naming: `{mode}-v{N+1}.md` where N is the current highest version
- The original `{mode}-v{N}.md` is preserved unchanged for audit

Example: 3 approved proposals for design mode → `design-v2.md` created (not `design-v4.md`)

## New Item Template

When creating an ADD item for the new version file:

```markdown
### {ITEM-ID}: {description}

**Description:** {what this check verifies}

**Check method:**
```bash
{executable check command}
```

**Evidence format:** {how to report findings}

**Rework format:** {corrective instruction template}
```

## Evolution Log Schema

Append to `docs/retros/evolution-log.jsonl` (one JSON object per line, append-only):

**Proposal events** — one per approved ADD/REMOVE/MODIFY/PROMOTE:

```json
{
  "timestamp": "2026-04-07T14:30:00Z",
  "event": "item_added|item_removed|item_modified|item_promoted",
  "mode": "design|plan|code",
  "item_id": "SCEN-CONC-03",
  "description": "Error scenarios must name specific HTTP status codes",
  "rationale": "Failed in 3 plans -- vague error descriptions consistently missed",
  "driving_plans": ["2026-04-01-auth-plan", "2026-04-03-api-plan"],
  "checklist_version": "design-v2.md",
  "retrospective_report": "docs/retros/retro-2026-04-07-error-specificity.md"
}
```

**Retrospective-run event** — one per retrospective invocation, written by Phase 6 closure:

```json
{
  "event": "retrospective_run",
  "timestamp": "2026-04-07T14:30:00Z",
  "plans_analyzed": ["docs/plans/2026-04-01-auth-plan/", "docs/plans/2026-04-03-api-plan/"],
  "report": "docs/retros/retro-2026-04-07-error-specificity.md",
  "proposals_approved": 2,
  "proposals_rejected": 1,
  "disable_test": "Superpower Loop in executing-plans"
}
```

Never edit or remove past entries. The log is the audit trail for all checklist evolution **and** the closure marker for the calibration loop.

## Log Reader Protocol (Calibration Loop)

The evolution log has two consumers:

### Reader 1: retrospective Phase 1 (proposal history)

Scan for `item_*` events to build an item-history table. In Phase 3, **suppress re-proposing an `ADD` for an item whose most recent event is `item_removed`** unless the new evidence is materially different from the removal rationale. Cite the prior entry in any such proposal (e.g., "Re-adding SCEN-CONC-03: prior REMOVE on 2025-12-01 was based on N=8 zero-failure reports; new evidence is FAIL in 4 plans since 2026-02-01.").

### Reader 2: executing-plans Phase 6 (retrospective-due reminder)

Find the most recent `retrospective_run.timestamp`. Count `plan_completed` entries in `docs/retros/plans-completed.jsonl` whose timestamp is later. If `>= 3`, emit a **RETROSPECTIVE DUE** reminder. This closes the calibration loop — plans that complete without being retrospected become a visible pressure signal, preventing the retrospective skill from being a user-only trigger.

## Plan Completion Log Schema

Append to `docs/retros/plans-completed.jsonl` (one JSON object per line, append-only). Written by executing-plans Phase 6:

```json
{
  "event": "plan_completed",
  "plan": "docs/plans/2026-04-07-example-plan/",
  "task_count": 14,
  "batch_count": 4,
  "timestamp": "2026-04-07T09:12:00Z"
}
```

This log exists solely to compute Reader 2's "plans since last retrospective" delta. It is append-only and never edited.

## Retrospective Report Template

Output file: `docs/retros/retro-{date}-{topic}.md`

```markdown
# Retrospective: {topic}

**Date**: {date}
**Plans analyzed**: {list}
**Reports read**: {count}

## Failure Frequency
{table}

## Plateau Tasks
{table}

## Never-Failing Items
{table}

## Variety Gaps
{table}

## Evolution Proposals

| # | Type | Mode | Item ID | Status |
|---|------|------|---------|--------|
| 1 | ADD | design | SCEN-CONC-03 | APPROVED |
| 2 | REMOVE | plan | PLAN-GRAN-01 | REJECTED |

## Pre-Edit Snapshot
{if any proposals approved}

## Harness Health
{recommendations}

## Summary
- Proposals: N approved, M rejected, K deferred
- Checklists updated: {mode}-v{N+1}.md
- Next action: run retrospective again after 2+ more plan executions
```
