# Evolution Protocol Reference

Checklist evolution rules: proposal types, thresholds, versioning, and audit trail.

## Proposal Types

| Type | Description | Threshold | Priority |
|------|-------------|-----------|----------|
| ADD | New checklist item for uncovered failure pattern | FAILs in 2+ distinct plans | HIGH |
| REMOVE | Remove item that never detects issues | 0 FAILs across 3+ reports | LOW |
| MODIFY | Tighten or relax an existing item's check method | 2+ false positives (FAIL overturned in rework) | MEDIUM |
| PROMOTE | Reclassify capability item to regression | Pass rate >80% across 3+ successive plans | LOW |

## Rate Limit (EVO-6)

Maximum 3 proposals per mode per retrospective run. If analysis produces more:
- Surface the top 3 by priority (ADD > MODIFY > PROMOTE > REMOVE)
- List deferred proposals with full evidence in the report
- Note: "N proposals deferred -- rerun retrospective after applying current approvals"

## Proposal Presentation

Each proposal is recorded inline in the retrospective report (Phase 6) using this shape, then auto-applied in Phase 4 — there is no per-proposal approval gate. The post-commit `git show docs/retros/checklists/` diff is the audit surface.

```
Proposal: [ADD/REMOVE/MODIFY/PROMOTE] [mode]/[Item ID]
Description: [what the item checks]
Rationale: [why this change is needed]
Evidence: [plan-1 tasks X, Y -- plan-2 task Z -- specific failure pattern]
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
  "provenance": "retrospective",
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
  "post_plan_diff": {
    "window_hours_at_run": 48,
    "total": 9,
    "feedback": 5,
    "evolution": 4,
    "unknown": 0,
    "greenfield_no_followup": false
  }
}
```

**`post_plan_diff` sub-object:** per-plan summary of post-plan git activity, written by Phase 6 closure when `lib/post-plan-diff.sh` ran successfully against the analyzed plans:

- `window_hours_at_run` — `(retrospective_timestamp - max(plans_analyzed.completion_timestamp)) / 3600`. Records when this run looked at post-plan activity; lets future retrospectives weight signal strength (a 4h window is much weaker than a 72h window).
- `total` / `feedback` / `evolution` / `unknown` — commit counts from `lib/post-plan-diff.sh summary` aggregated across all `plans_analyzed`. `feedback` includes `refactor:` / `fix:` / `style:` / `perf:`; `evolution` includes `feat:` / `chore:` / `docs:` / `build:` / `ci:` / `test:` / `revert:`.
- `greenfield_no_followup` — set to `true` only if the Pre-Check asked the user and they answered "Greenfield with no follow-up". Future retrospectives reading this should not penalize the absence of post-plan signal.

Omit `post_plan_diff` entirely when no plan in `plans_analyzed` carries a `completion_commit`.

Never edit or remove past entries. The log is the audit trail for all checklist evolution **and** the closure marker for the calibration loop.

## Canonical Emit Invocations

Both event families route through `lib/jsonl-emit.sh` with `<channel>=evolution-log`. The emitter auto-injects `$timestamp` and `$repo_root`; the caller composes every other field.

**Proposal events** (`item_added` / `item_removed` / `item_modified` / `item_promoted`) — invoked from retrospective Phase 4 step 3 once per applied proposal:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/lib/jsonl-emit.sh" evolution-log \
  '{timestamp: $timestamp, event: $event, mode: $mode, item_id: $item_id, description: $description, rationale: $rationale, driving_plans: ($driving_plans | split(",")), checklist_version: $checklist_version, retrospective_report: $retrospective_report}' \
  --arg event "item_added" \
  --arg mode "<design|plan|code>" --arg item_id "<ITEM-ID>" \
  --arg description "<...>" --arg rationale "<...>" \
  --arg driving_plans "<plan1,plan2>" \
  --arg checklist_version "<{mode}-v{N+1}.md>" \
  --arg retrospective_report "<docs/retros/retro-{date}-{topic}.md>"
```

Substitute `item_removed | item_modified | item_promoted` for the `event` arg as appropriate.

**Provenance** (optional, recommended): `"retrospective"` (Phase 4 ADD with driving_plans), `"phase_5a_override"` (single-plan post-plan-diff ADD), or `"maintainer_baseline"` (seed promotion with empty `driving_plans`). Phase 1 readers use this to avoid treating maintainer baselines as retrospective-backed evidence.

**Retrospective-run event** — invoked from Phase 6 closure exactly once per retrospective:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/lib/jsonl-emit.sh" evolution-log \
  '{event: $event, timestamp: $timestamp, plans_analyzed: ($plans | split(",")), report: $report, proposals_approved: $approved, proposals_rejected: $rejected}' \
  --arg event "retrospective_run" \
  --arg plans "<plan1,plan2>" --arg report "<retro-md>" \
  --argjson approved <N> --argjson rejected <M>
```

## Log Reader Protocol

The evolution log's consumer is retrospective Phase 1 (proposal history):

Scan for `item_*` events to build an item-history table. In Phase 3, **suppress re-proposing an `ADD` for an item whose most recent event is `item_removed`** unless the new evidence is materially different from the removal rationale. Cite the prior entry in any such proposal (e.g., "Re-adding SCEN-CONC-03: prior REMOVE on 2025-12-01 was based on N=8 zero-failure reports; new evidence is FAIL in 4 plans since 2026-02-01.").

## Plan Completion Log Schema

Log at `docs/retros/plans-completed.jsonl` (one JSON object per line, append-only). Written deterministically by the `Stop` hook `hooks/plan-completed.sh`, which detects completion from durable plan artifacts — every batch handed off (`handoff-summary-*` count ≥ `sprint-contract-batch-*` count) plus a git commit touching the `handoff-state.md` modified-files set — and appends one row per plan on first completion. Detection is state-based, not keyed off any model utterance, so it is immune to a paraphrased or skipped completion summary. (The v3.0.0 teardown removed the old continuation-loop Stop hook and briefly demoted this write to a Claude-instructed Phase 6 step, which empirical audit showed was silently dropped; the minimal single-purpose hook restores the mechanical write without the loop runtime.) May be absent for plans completed outside `executing-plans` or on a host without `jq`/`git`. Each entry follows this shape:

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

**Canonical emit (`hooks/plan-completed.sh`, first completion only):** the hook composes the row below and writes it via `lib/jsonl-emit.sh` executed mode:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/lib/jsonl-emit.sh" plans-completed \
  '{event:"plan_completed",plan:$plan,repo_root:$repo_root,task_count:($tc|tonumber),batch_count:($bc|tonumber),completion_commit:$cc,completion_modified_files:$files,timestamp:$timestamp}' \
  --arg plan "docs/plans/<name>-plan" \
  --arg tc <task count> --arg bc <batch count> \
  --arg cc "$(git log -1 --format=%h -- <modified files>)" \
  --argjson files '["src/a.py","tests/test_a.py"]'
```

The emitter auto-injects `$timestamp` and `$repo_root`. The hook derives `$files` (backtick items under `## Modified Files (cumulative)`) first, then `$cc` as the most recent commit touching that set (`git log -1 --format=%h -- <files>`) — this both confirms Phase 5 committed and yields the completion anchor rather than a bare `HEAD` guess. `$plan` is the repo-relative plan path, `$tc` the bullets under `## Completed Task IDs`, `$bc` the active `sprint-contract-batch-*.md` count (archived `*.vN.md` excluded). First-completion-only dedup uses `lib/jsonl-emit.sh` `dedup_check` with anchored substring `,"plan":"<path>"` on the log tail (same spirit as the deleted `loop.sh` writer).

**Field semantics (v3.1):**

- `plan` — **repo-relative** path with NO trailing slash. Cross-worktree (macOS `/var` ↔ `/private/var`), cross-clone, and cross-machine stable. Used as the dedup key — entries with identical `plan` collapse to the first occurrence.
- `repo_root` — absolute path to the git toplevel resolved via `git rev-parse --show-toplevel`, fallback to `$PWD` when not in a git repo. Audit/debug only; not a dedup key.
- `task_count` / `batch_count` — enrichment from `handoff-state.md` (`## Completed Task IDs` bullets) and active `sprint-contract-batch-*.md` count. Default 0 when unparseable.
- `completion_commit` — short SHA of the **most recent commit touching `completion_modified_files`** at first log time (`git log -1 --format=%h -- <files>`). Not necessarily current `HEAD` if later work touches the same paths. Drives retrospective Phase 1 step 6 post-plan-diff loop. Empty when C3 cannot resolve a commit.
- `completion_modified_files` — repo-relative paths from `handoff-state.md` `` `backtick` `` items under `## Modified Files (cumulative)`. Defaults to `[]`. Restricts post-plan-diff scope to plan-related files.
- `timestamp` — UTC ISO 8601 first-completion time (auto-injected by `jsonl-emit.sh`).

**Dedup semantics (v3.1):** plans-completed.jsonl is "first completion per plan". Re-running `superpowers:executing-plans` on a finished plan does NOT double-log nor re-trigger retrospective auto-scope. The hook skips when `dedup_check` finds anchored `,"plan":"<path>"` in the log tail-200, or when the same anchor appears in `evolution-log.jsonl` (plan already analyzed). To force a fresh entry, remove the matching line manually — there is no `--force-relog` flag by design.

**`/goal` vs hook:** `/goal` success (transcript condition met) does **not** imply a `plan_completed` row exists. The hook requires filesystem C1–C4; missing `jq`/`git` or incomplete handoff artifacts → silent no-op while `/goal` may still stop.

**Backward compatibility:** pre-v2.8.2 entries have `plan` written as absolute path and lack `repo_root` / `completion_commit` / `completion_modified_files`. They coexist with new entries — dedup matches on the new repo-relative form, so stale absolute-path entries naturally age out without explicit migration. Retrospective Phase 1 step 8 silently skips entries lacking `completion_commit`.

This log drives:

1. retrospective Phase 1 auto-scope (the `--across-all` flag and the no-arg invocation)
2. retrospective Phase 1 step 6 post-plan-diff loop
3. retrospective Pre-Check INSUFFICIENT-POST-PLAN gate

It is append-only. Manual edits are user-territory; readers trust whatever ends up on disk.

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
