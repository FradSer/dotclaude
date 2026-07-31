# Evolution Protocol Reference

Checklist evolution rules: proposal types, thresholds, versioning, and audit trail. Adapted from superpowers' evolution-protocol for the superdev spec/ticket workflow (`design`→`spec`, `plan`→`tickets`, `code` kept; `plans_analyzed`→`specs_analyzed`).

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

Each proposal is recorded inline in the retrospective report (Phase 5) using this shape, then auto-applied in Phase 4 — there is no per-proposal approval gate. The post-commit `git show docs/retros/checklists/` diff is the audit surface.

```
Proposal: [ADD/REMOVE/MODIFY/PROMOTE] [mode]/[Item ID]
Description: [what the item checks]
Rationale: [why this change is needed]
Evidence: [spec-1 tickets X, Y -- spec-2 ticket Z -- specific failure pattern]
Outcome: applied | self-rejected: <reason citing Phase 1 step 5 history>
```

`Outcome` is set by Phase 4: `applied` for proposals that became checklist edits, `self-rejected` only when the proposal duplicates a recent removal (Phase 1 step 5) without materially new evidence. EVO-6 (max 3 per mode per run) and the threshold gates in this file are the upstream rate limits.

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

Example: 3 approved proposals for spec mode → `spec-v2.md` created (not `spec-v4.md`)

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

Append to `docs/retros/evolution-log.jsonl` (one JSON object per line, append-only). Written via `lib/jsonl-emit.sh` executed mode (auto-injects `$timestamp` and `$repo_root`).

**Proposal events** — one per approved ADD/REMOVE/MODIFY/PROMOTE:

```json
{
  "timestamp": "2026-04-07T14:30:00Z",
  "event": "item_added|item_removed|item_modified|item_promoted",
  "provenance": "retrospective",
  "mode": "spec|tickets|code",
  "item_id": "SPEC-CONC-03",
  "description": "Error scenarios must name specific HTTP status codes",
  "rationale": "Failed in 3 specs -- vague error descriptions consistently missed",
  "driving_specs": ["2026-04-01-auth-spec", "2026-04-03-api-spec"],
  "checklist_version": "spec-v2.md",
  "retrospective_report": "docs/retros/retro-2026-04-07-error-specificity.md"
```

**Retrospective-run event** — one per retrospective invocation, written by Phase 5 closure:

```json
{
  "event": "retrospective_run",
  "timestamp": "2026-04-07T14:30:00Z",
  "specs_analyzed": ["docs/specs/2026-04-01-auth-spec/", "docs/specs/2026-04-03-api-spec/"],
  "report": "docs/retros/retro-2026-04-07-error-specificity.md",
  "proposals_approved": 2,
  "proposals_rejected": 1
}
```

Never edit or remove past entries. The log is the audit trail for all checklist evolution **and** the closure marker for the calibration loop.

## Canonical Emit Invocations

Both event families route through `lib/jsonl-emit.sh` with `<channel>=evolution-log`. The emitter auto-injects `$timestamp` and `$repo_root`; the caller composes every other field.

**Proposal events** (`item_added` / `item_removed` / `item_modified` / `item_promoted`) — invoked from retrospective Phase 4 step 3 once per applied proposal:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/lib/jsonl-emit.sh" evolution-log \
  '{timestamp: $timestamp, event: $event, mode: $mode, item_id: $item_id, description: $description, rationale: $rationale, driving_specs: ($driving_specs | split(",")), checklist_version: $checklist_version, retrospective_report: $retrospective_report}' \
  --arg event "item_added" \
  --arg mode "<spec|tickets|code>" --arg item_id "<ITEM-ID>" \
  --arg description "<...>" --arg rationale "<...>" \
  --arg driving_specs "<spec1,spec2>" \
  --arg checklist_version "<{mode}-v{N+1}.md>" \
  --arg retrospective_report "<docs/retros/retro-{date}-{topic}.md>"
```

Substitute `item_removed | item_modified | item_promoted` for the `event` arg as appropriate.

**Provenance** (optional, recommended): `"retrospective"` (Phase 4 ADD with driving_specs), `"post_correction_override"` (single-spec/ticket post-correction ADD), `"maintainer_baseline"` (seed promotion with empty `driving_specs`). Phase 1 readers use this to avoid treating maintainer baselines as retrospective-backed evidence.

**Retrospective-run event** — invoked from Phase 5 closure exactly once per retrospective:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/lib/jsonl-emit.sh" evolution-log \
  '{event: $event, timestamp: $timestamp, specs_analyzed: ($specs | split(",")), report: $report, proposals_approved: $approved, proposals_rejected: $rejected}' \
  --arg event "retrospective_run" \
  --arg specs "<spec1,spec2>" --arg report "<retro-md>" \
  --argjson approved <N> --argjson rejected <M>
```

**Note:** superpowers had a Stop hook (`stop-state-sync.sh`) that backfilled dropped rows; superdev drops that hook. The in-skill Phase 4 step 5 self-check (count rows vs. `proposals_approved`) is the sole guard against a dropped emit — run it before leaving Phase 4.

## Log Reader Protocol

The evolution log's consumer is retrospective Phase 1 (proposal history):

Scan for `item_*` events to build an item-history table. In Phase 3, **suppress re-proposing an `ADD` for an item whose most recent event is `item_removed`** unless the new evidence is materially different from the removal rationale. Cite the prior entry in any such proposal (e.g., "Re-adding SPEC-CONC-03: prior REMOVE on 2025-12-01 was based on N=8 zero-failure reports; new evidence is FAIL in 4 specs since 2026-02-01.").

## Retrospective Report Template

Output file: `docs/retros/retro-{date}-{topic}.md`

```markdown
# Retrospective: {topic}

**Date**: {date}
**Specs/tickets analyzed**: {list}
**Reports read**: {count}

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
| 1 | ADD | spec | SPEC-CONC-03 | APPROVED |
| 2 | REMOVE | tickets | TICKETS-GRAN-01 | REJECTED |

## Pre-Edit Snapshot
{if any proposals approved}

## Summary
- Proposals: N approved, M rejected, K deferred
- Checklists updated: {mode}-v{N+1}.md
- Next action: run retrospective again after 2+ more spec/ticket executions
```

## History: Removed Mechanisms and Threshold Calibration

**Removed in superdev — the Stop hook and post-plan-diff lib.** superpowers ran a `hooks/stop-state-sync.sh` hook that mechanically backfilled dropped `evolution-log` rows, and a `lib/post-plan-diff.sh` that mined post-plan commits. superdev drops both (mattpocock minimalist principle): the in-skill Phase 4 step 5 self-check replaces the hook backfill, and the post-correction signal is folded into Phase 2 prose advisory (mined from git inline, no dedicated lib). If empirical audit shows dropped emits recurring, re-add a Stop hook then.

**Why the REMOVE threshold is 3+ reports/item (was 10+).** ADD is cheap to trigger while REMOVE used to require 10+ reports/item — a volume real single-project usage never reaches, so checklists only ever grew. The 3+ threshold is deliberately reachable so the loop can shrink checklists, not only grow them.
