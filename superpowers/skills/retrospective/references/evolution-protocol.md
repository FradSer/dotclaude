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

`# Type: computational|inferential` -- {justification}
```

## Evolution Log Schema

Append to `docs/retros/evolution-log.jsonl` (one JSON object per line, append-only):

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

Never edit or remove past entries. The log is the audit trail for all checklist evolution.

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
