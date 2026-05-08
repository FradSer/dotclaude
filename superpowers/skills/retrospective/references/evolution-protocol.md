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
  "disable_test": "evaluator_per_batch",
  "self_value": {
    "proposals_total": 3,
    "disable_test_set": true,
    "consecutive_zero_change": 0
  },
  "post_plan_diff": {
    "window_hours_at_run": 48,
    "total": 9,
    "feedback": 5,
    "evolution": 4,
    "unknown": 0,
    "vetoed_disables": ["recurring_failure_patterns"],
    "greenfield_no_followup": false
  }
}
```

**`post_plan_diff` sub-object (v2.8.1):** per-plan summary of post-plan git activity, written by Phase 6 closure when `lib/post-plan-diff.sh` ran successfully against the analyzed plans:

- `window_hours_at_run` — `(retrospective_timestamp - max(plans_analyzed.completion_timestamp)) / 3600`. Records when this run looked at post-plan activity; lets future retrospectives weight signal strength (a 4h window is much weaker than a 72h window).
- `total` / `feedback` / `evolution` / `unknown` — commit counts from `lib/post-plan-diff.sh summary` aggregated across all `plans_analyzed`. `feedback` includes `refactor:` / `fix:` / `style:` / `perf:`; `evolution` includes `feat:` / `chore:` / `docs:` / `build:` / `ci:` / `test:` / `revert:`.
- `vetoed_disables` — array of `harness-config.json` identifiers that Phase 5b's removal-candidate gate **vetoed** because post-plan diff showed real feedback signal in the component's defensive scope. These are the `component_reinstated` triggers; absence here means no disables were vetoed in this run.
- `greenfield_no_followup` — set to `true` only if Pre-Check A asked the user and they answered "Greenfield with no follow-up". Future retrospectives reading this should not penalize the absence of post-plan signal.

Omit `post_plan_diff` entirely when no plan in `plans_analyzed` carries a `completion_commit` (pre-v2.8.1 logs) — its absence means the calibration loop ran in v2.7.0-equivalent blind mode and downstream consumers should treat any disable test from this run as weak evidence.

`disable_test` MUST be either `null` (no component disabled this run) or one of the supported `harness-config.json` identifiers listed in `harness-config.md`. **Do not** write a free-text component name (e.g., "Superpower Loop in executing-plans") — those are unsupported and will fail the calibration-loop self-check. See SKILL.md Phase 5c refusal gate.

`self_value` records this run's own productivity for the next retrospective's LOW-YIELD self-check:

- `proposals_total`: `proposals_approved + proposals_rejected`
- `disable_test_set`: `true` when `disable_test` is non-null (a real assumption test was launched)
- `consecutive_zero_change`: count of consecutive prior `retrospective_run` events with `proposals_approved == 0 AND disable_test_set == false`, plus 1 if this run is also zero-change (else reset to 0). Computed at write time by reading the previous `retrospective_run` event in this log.

When `consecutive_zero_change >= 2`, `retrospective` Phase 0 and `executing-plans` Phase 6 should surface a "RETROSPECTIVE LOW-YIELD" hint instead of the standard RETROSPECTIVE DUE reminder.

**Component-reinstated event** (v2.8.1) — one per Phase 5b post-plan-diff veto OR per manual correction of a prior weak-evidence disable:

```json
{
  "event": "component_reinstated",
  "timestamp": "2026-05-09T08:30:00Z",
  "component": "recurring_failure_patterns",
  "previously_disabled_in": "docs/retros/retro-2026-05-08-user-simulation.md",
  "reinstatement_method": "post_plan_diff_veto | manual_correction",
  "evidence": {
    "feedback_commit_count": 5,
    "feedback_commit_shas": ["a7a62a6", "4891b49", "4d6c636", "2a9bd93", "d05394a"],
    "missed_patterns": [
      "disfluency handling inconsistency across 2 modules",
      "OpenAI client model parameter handling",
      "PII patterns missing +86 prefix coverage"
    ]
  },
  "rationale": "Original disable based on 'injection block empty in 6 batches' (Phase 5a/5b in-plan signal). Post-plan diff shows 5 refactor commits in the 12-13h window after plan completion, all on plan-modified files, all touching recurring patterns the evaluator's grep-based checks could not see. The component's zero-injection signal reflected evaluator coverage gap, not component redundancy.",
  "follow_up": "Phase 3 ADD proposals queued for the 3 missed patterns above (graduates 1-plan ADD evidence per v2.8.1 Phase 5a post-plan-diff override)."
}
```

When `reinstatement_method == "post_plan_diff_veto"`, the event is auto-emitted by Phase 5b's veto gate (Phase 6 closure writes it alongside the standard `retrospective_run`). When `reinstatement_method == "manual_correction"`, the event is emitted out-of-band by `/superpowers:retrospective` invoked specifically to correct a prior weak-evidence disable (no full Phase 1-6 cycle; the run writes only this event + the `harness-config.json` clear).

The downstream effect of either method: the next `executing-plans` Phase 1 step 4 reads `harness-config.json` and the component is no longer disabled, so the next plan run resumes its full pipeline. Reader 1 (Phase 1 step 5 of the next retrospective) sees the `component_reinstated` event and **suppresses re-proposing the same disable** unless the new evidence is materially different — same protection as the existing `item_added → item_removed → item_added` ping-pong suppression.

Never edit or remove past entries. The log is the audit trail for all checklist evolution **and** the closure marker for the calibration loop.

## Log Reader Protocol (Calibration Loop)

The evolution log has two consumers:

### Reader 1: retrospective Phase 1 (proposal history)

Scan for `item_*` events to build an item-history table. In Phase 3, **suppress re-proposing an `ADD` for an item whose most recent event is `item_removed`** unless the new evidence is materially different from the removal rationale. Cite the prior entry in any such proposal (e.g., "Re-adding SCEN-CONC-03: prior REMOVE on 2025-12-01 was based on N=8 zero-failure reports; new evidence is FAIL in 4 plans since 2026-02-01.").

### Reader 2: executing-plans Phase 6 (retrospective-due reminder)

Find the most recent `retrospective_run.timestamp`. Count `plan_completed` entries in `docs/retros/plans-completed.jsonl` whose timestamp is later. If `>= 3`, emit a **RETROSPECTIVE DUE** reminder. This closes the calibration loop — plans that complete without being retrospected become a visible pressure signal, preventing the retrospective skill from being a user-only trigger.

## Plan Completion Log Schema

Append to `docs/retros/plans-completed.jsonl` (one JSON object per line, append-only). Written mechanically by `lib/loop.sh:_loop_log_plan_completion_if_executing` when an `executing-plans` promise fires:

```json
{
  "event": "plan_completed",
  "plan": "docs/plans/2026-04-07-example-plan",
  "repo_root": "/Users/alice/Code/myproject",
  "task_count": 14,
  "batch_count": 4,
  "completion_commit": "a1b2c3d4e5f6789",
  "completion_modified_files": [
    "src/auth.py",
    "tests/test_auth.py"
  ],
  "timestamp": "2026-04-07T09:12:00Z"
}
```

**Field semantics (v2.8.2):**

- `plan` — **repo-relative** path with NO trailing slash. Cross-worktree (macOS `/var` ↔ `/private/var`), cross-clone, and cross-machine stable. Used as the dedup key — entries with identical `plan` collapse to the first occurrence.
- `repo_root` — absolute path to the git toplevel resolved via `git rev-parse --show-toplevel`, fallback to `$PWD` when not in a git repo. Audit/debug only; not a dedup key.
- `task_count` / `batch_count` — best-effort enrichment from `_index.md` YAML and `sprint-contract-batch-*.md` file count (v2.8.0). Default 0 when source files missing.
- `completion_commit` — short SHA of `HEAD` at plan completion (v2.8.1). Empty string when not in a git repo. Drives retrospective Phase 1 step 8 post-plan-diff loop.
- `completion_modified_files` — repo-relative paths every executing-plans batch touched (v2.8.1, sourced from state's `modified_files` accumulator). Defaults to `[]`. Restricts post-plan-diff scope to plan-related files.
- `timestamp` — UTC ISO 8601 first-completion time.

**Dedup semantics (v2.8.2):** plans-completed.jsonl is "first completion per plan". Multiple promise fires on the same plan (re-entry, amendment, partial rerun) skip the write — re-running `superpowers:executing-plans` on a finished plan does NOT inflate RETROSPECTIVE DUE counts nor re-trigger retrospective auto-scope. The dedup gate uses jq with `try/catch` so a single corrupt prior line does not disable the gate. To force a fresh entry (e.g., after wiping the log to retroactively migrate pre-v2.8.2 absolute-path entries), the user removes the matching line manually — there is no `--force-relog` flag by design (relogging same-plan plays badly with calibration loop assumptions).

**Backward compatibility:** pre-v2.8.2 entries have `plan` written as absolute path and lack `repo_root` / `completion_commit` / `completion_modified_files`. They coexist with new entries — dedup matches on the new repo-relative form, so stale absolute-path entries naturally age out without explicit migration. Retrospective Phase 1 step 8 silently skips entries lacking `completion_commit`.

This log drives:

1. Reader 2's "plans since last retrospective" delta (executing-plans Phase 6 RETROSPECTIVE DUE / LOW-YIELD reminder)
2. retrospective Phase 1 auto-scope (the `--across-all` flag and the no-arg invocation)
3. retrospective Phase 1 step 8 post-plan-diff loop (v2.8.1)
4. retrospective Pre-Check A INSUFFICIENT-POST-PLAN gate (v2.8.1)

It is append-only and never edited by the harness. Manual edits are user-territory; the hook's dedup logic survives most mishaps but trusts whatever ends up on disk.

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
