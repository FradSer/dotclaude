---
name: retrospective
description: This skill should be used when the user wants to analyze evaluation patterns across completed plans and evolve checklists. Triggered by asking to "run a retrospective", "analyze evaluation patterns", "evolve checklists", or "/superpowers:retrospective".
argument-hint: <plan-path-1> [plan-path-2] [--across-all]
user-invocable: true
allowed-tools: ["Read", "Glob", "Grep", "Write", "Edit", "Bash(python3:*)", "Bash(git:*)", "Bash(${CLAUDE_PLUGIN_ROOT}/lib/seed-checklists.sh:*)", "Bash(${CLAUDE_PLUGIN_ROOT}/lib/post-plan-diff.sh:*)", "Bash(${CLAUDE_PLUGIN_ROOT}/lib/observations.sh:*)", "Bash(${CLAUDE_PLUGIN_ROOT}/lib/evolution-log.sh:*)"]
---

# Retrospective

Analyze evaluation patterns across completed plans, identify recurring failures, and auto-apply checklist evolution. The user reviews post-commit via `git show docs/retros/checklists/`.

**Chain position**: This skill is the downstream consumer of executing-plans Phase 4 "Checklist Evolution Candidates". It aggregates signals across plans and produces versioned checklist updates.

## Pre-Check A: INSUFFICIENT-POST-PLAN advisory (informational, run first)

Read the most recent `plan_completed` event from `docs/retros/plans-completed.jsonl`. If `hours_since_completion < 24h` AND `bash "${CLAUDE_PLUGIN_ROOT}/lib/post-plan-diff.sh" summary <completion_commit> <files...>` returns `total == 0`, output the INSUFFICIENT-POST-PLAN reminder verbatim (see `./references/post-plan-diff.md` §Pre-Check A) and proceed to Pre-Check B — do NOT pause. The Phase 6 `retrospective_run` event records `consecutive_zero_change` so next-run LOW-YIELD self-corrects.

Skip silently when `completion_commit` is missing (pre-v2.8.1 logs). Always run Pre-Check B after.

## Pre-Check B: LOW-YIELD advisory (informational, run after Pre-Check A)

Read the most recent `retrospective_run` event from `docs/retros/evolution-log.jsonl`. If `.self_value.consecutive_zero_change >= 2`, surface this reminder verbatim, then proceed to Phase 0 — do NOT pause:

> **RETROSPECTIVE LOW-YIELD**: the last {N} consecutive runs produced zero approved proposals and no assumption test. Proceeding anyway — the next `retrospective_run` event captures whether this run breaks the streak.

If the file does not exist or the most recent event lacks `self_value`, treat as `consecutive_zero_change=0` and skip silently.

## Phase 0: Bootstrap (run only when no checklists exist)

Before Phase 1, check whether `docs/retros/checklists/` contains `{mode}-v1.md` for each mode (design / plan / code).

For each mode that lacks a v1 file, seed it via:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/lib/seed-checklists.sh" <mode> docs/retros/checklists/<mode>-v1.md
```

Log one line per mode seeded: `Seeded initial checklist: {mode}-v1.md`. If all three modes already have a v1 file, log `Phase 0: all checklists present, skipping seed`.

Phase 0 runs per mode independently — only the modes missing a v{N} file are seeded. Do not skip the entire phase because one mode already has a checklist.

**Exit code handling**: the seed script refuses to clobber an existing checklist (exit code 3) — treat that as "already seeded, proceed". Real failures (exit 1 = unknown mode, exit 2 = usage error) abort the phase. To genuinely reset an existing checklist (e.g., after a major harness change), append `--force` after the output path.

The canonical v1 template content lives in `lib/seed-checklists.sh`. To inspect or modify the seed bodies, edit that script — do NOT re-inline templates here.

## Phase 1: Data Collection

1. **Resolve inputs**: Parse `$ARGUMENTS` for plan paths. If `--across-all`, scan `docs/plans/` for all `*-plan/` directories with evaluation reports. If no argument is given, read `docs/retros/plans-completed.jsonl` and auto-scope to plans completed after the most recent `retrospective_run` event in `docs/retros/evolution-log.jsonl`.
2. **Resolve evals**: For each plan path, look for evaluation reports in the plan directory (`evaluation-round-*.md`, `evaluation-design-round-*.md`, `evaluation-plan-round-*.md`). If a sibling `*-evals/` directory exists, read from there instead.
3. **Read checklists**: Scan `docs/retros/checklists/` for latest versions of each mode (`{mode}-v{N}.md`, highest N).
4. **Read reports**: For each plan, read all evaluation report files. Extract per-item results (Item ID, Result, Evidence) and rework items.
5. **Read evolution history** (calibration input): Read `docs/retros/evolution-log.jsonl` if present. Build a history table keyed by `item_id` with: most recent event (`item_added|item_removed|item_modified|item_promoted`), timestamp, rationale. This history feeds Phase 3 — do NOT re-propose an `ADD` for an item `REMOVE`d in the most recent retrospective unless the new evidence is materially different from the original removal rationale. Cite the historical entry in any such proposal.
6. **Read harness config and observations** (Phase 5c feedback loop): If `docs/retros/harness-config.json` exists and contains a non-empty `disabled_components[]`, read the entry and read all matching rows from `docs/retros/harness-observations.jsonl`. Feed this into Phase 5 so the prior disable test can be judged (promote / reinstate / extend). See `./references/harness-config.md`.
7. **Read bail-out events** (calibration input for Phase 5a): If `docs/retros/bail-out-events.jsonl` exists, read every row and aggregate counts by `(skill, event)` plus distinct `args_hash` values per skill. Pass the aggregate to Phase 5a — frequent `force_override` against many distinct inputs surfaces a too-aggressive bail threshold; high `bail_out` counts on near-identical `args_hash` values flag user habits the skill could short-circuit earlier. Skip silently when the file does not exist (first-run state).
8. **Read post-plan diff** (v2.8.1): For each plan with a `completion_commit` field, run `bash "${CLAUDE_PLUGIN_ROOT}/lib/post-plan-diff.sh" list <completion_commit> <completion_modified_files...>` and pass the classified commit list to Phase 5a + 5b. See `./references/post-plan-diff.md` §"Phase 1 step 8" for classification rules and skip conditions.

9. **Minimum data check**: If only 1 plan provided, warn that ADD proposals require 2+ plans. If fewer than 10 reports per item, warn that REMOVE proposals require 10+ reports.

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
| REMOVE | 0 failures across sufficient reports | 10+ reports per item |
| MODIFY | Item produces false positives (FAIL overturned in rework) | 2+ false positives |
| PROMOTE | Capability item pass rate >80% across 3+ successive plans | 3+ plans trending |

**Rate limit (EVO-6)**: Max 3 proposals per mode per retrospective run. Defer excess with evidence for future runs.

Each proposal includes: type, target checklist, item ID, description, rationale with plan evidence.

## Phase 4: Auto-Apply Proposals

Apply every Phase 3 proposal (ordered by priority: regression breaks first, then by frequency). No per-proposal approval gate — EVO-6 (max 3/mode/run) + Phase 3 thresholds + post-commit `git show docs/retros/checklists/` are the quality surface. `proposals_rejected` is reserved for self-rejection at apply time: when a proposal duplicates a recent removal (Phase 1 step 5 history) without materially new evidence, log to the report under "Self-Rejected Proposals" with the cited historical entry, increment `proposals_rejected`, and skip the checklist row. All other proposals advance.

Apply steps:

1. **Pre-edit snapshot**: Write current checklist content to the retrospective report under "Pre-Edit Snapshot" with rollback instructions
2. **Create new version**: Write `{mode}-v{N+1}.md` with all applied changes. Version increments once per run (not per proposal). Original version preserved unchanged.
3. **Log evolution**: For each applied proposal, emit one row via the helper. The event_type is one of `item_added | item_removed | item_modified | item_promoted`. Payload-only filter omits `event` and `timestamp` — the envelope merges those (reference `$event`/`$timestamp` inside the filter to pin their row position per legacy parity).

   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/lib/evolution-log.sh" \
     item_added \
     '{timestamp: $timestamp, event: $event, mode: $mode, item_id: $item_id, description: $description, rationale: $rationale, driving_plans: ($driving_plans | split(",")), checklist_version: $checklist_version, retrospective_report: $retrospective_report}' \
     --arg mode "<design|plan|code>" --arg item_id "<ITEM-ID>" \
     --arg description "<...>" --arg rationale "<...>" \
     --arg driving_plans "<plan1,plan2>" \
     --arg checklist_version "<{mode}-v{N+1}.md>" \
     --arg retrospective_report "<docs/retros/retro-{date}-{topic}.md>"
   ```

   Substitute `item_removed | item_modified | item_promoted` for the event_type as appropriate. See `./references/evolution-protocol.md` for per-event-kind payload schemas.

## Phase 5: Harness Health and Load-Bearing Audit

Assess whether each harness component still earns its cost as models improve. Every harness piece encodes an assumption about model limitations; as those limitations change, some components become pure overhead (see Anthropic harness-design blog: "assumption testing"). All output in this phase is advisory — **never auto-remove components**. The retrospective report (Phase 6) surfaces candidates; the *next* retrospective run's Phase 3 turns them into REMOVE/MODIFY proposals that Phase 4 auto-applies. Phase 5 itself never mutates components — it only writes the assumption test via the 5c one-at-a-time disable protocol.

### 5a. Usage-Driven Recommendations

See `./references/analysis-patterns.md` for criteria.

- If all tasks in recent plans pass on first round (no REWORK), recommend reducing evaluation frequency
- If "Recurring Failure Patterns" injections never improve outcomes, recommend revising intra-plan learning
- If a mode's checklist has only regression items all passing consistently, recommend spot-check mode (every 3rd batch)
- If the Superpower Loop iterated ≤2 times across the analyzed plans (state file `iteration` field or plan handoff), the loop's retry budget is unused — surface as a note in the report. **Informational only**: there is no `harness-config.json` identifier for the loop; do not list it in 5b.
- If `bail-out-events.jsonl` shows `--force` overrides on ≥3 distinct trivial-scope inputs for a single skill, the bail-out threshold for that skill is too aggressive — surface as a MODIFY-bail-threshold candidate in the report (no automated config change).
- **Post-plan corrections** (from Phase 1 step 8 — v2.8.1): when `feedback`-classified commits ≥ 2 on plan-modified files, render the corrections table and surface "likely missed pattern" rows. **1-plan ADD evidence override**: if a missed pattern was not flagged by any batch evaluator, it graduates to a Phase 3 ADD proposal at 1-plan evidence. Table format, scope-match rules for the 5b veto, and veto-note template all live in `./references/post-plan-diff.md` §Phase 5a / §Phase 5b.

### 5b. Load-Bearing Candidate Identification

Flag a component as a **removal candidate** when it satisfies any of the following across **≥3 consecutive plans**:

| Component | Removal-candidate trigger | Signal source | harness-config identifier |
|-----------|---------------------------|---------------|----|
| Evaluator (per-batch, code mode) | Zero rework items produced | evaluation reports in plan dirs | `evaluator_per_batch` |
| Design evaluator | Zero design-mode rework items in 3+ designs | `evaluation-design-round-*.md` | `design_evaluator` |
| Sprint contract Evaluation Criteria Preview | First-pass output PASSes every preview item | per-batch evaluation reports | `sprint_contract_preview` |
| Per-batch "Recurring Failure Patterns" injection | Empty across all batches | sprint contract preambles | `recurring_failure_patterns` |

Every component listed in 5b MUST have a harness-config identifier — if it has no consumer-side disable, it belongs in 5a (informational) instead. The Superpower Loop is intentionally absent here for that reason.

**Post-plan diff veto** (v2.8.1) — run BEFORE listing any candidate as a removal candidate. For each candidate, check Phase 1 step 8 results: if `feedback`-classified post-plan commits ≥ 2 on plan-modified files AND the missed-pattern maps to this component's defensive scope, **VETO**. The veto emits a `component_reinstated` event (see `./references/evolution-protocol.md`) instead of a disable test. Scope-match table, exact veto-note template, and full rationale: `./references/post-plan-diff.md` §Phase 5b.

This veto is the direct fix for the v2.7.0 systemic miscalibration (user-simulation 2026-05-08 disabled `recurring_failure_patterns` on blank-injection signal alone; 5 post-plan refactor commits later showed the patterns existed and the evaluator missed them).

Checklist items with zero failures are covered by Phase 3 REMOVE proposals — cross-reference here, do not duplicate.

### 5c. One-At-A-Time Disable Protocol

Select **at most one** candidate from 5b for the next plan run as a live assumption test. Disabling multiple components at once confounds cause-and-effect.

**CRITICAL**: The disable must land in `docs/retros/harness-config.json` so the next plan run actually honors it. Writing only to the retrospective report is insufficient — consuming skills do not read reports. See `./references/harness-config.md` for schema, supported component identifiers, and lifecycle.

**CRITICAL refusal gate (do this BEFORE step 1 below)**: The identifiers `context_reset_coordinator` and `plan_evaluator` were removed and have no consumer. If the chosen identifier matches either, REFUSE the disable: (a) emit the observation, (b) write `{"version":1,"disabled_components":[]}` to `docs/retros/harness-config.json` inline (see "Writing the file" in `./references/harness-config.md`), (c) record the refusal under "Phase 5c Refusal" in the retrospective report, and (d) skip steps 1-4 below.

```bash
bash "${CLAUDE_PLUGIN_ROOT}/lib/observations.sh" \
  "<id>" component_unsupported "refused: <retro report path>"
```

Do NOT rely on the reference table alone — this gate is L2 enforcement. (See `./references/harness-config.md` for rationale.)

Actions (in order):

1. Read `./references/harness-config.md` to confirm the chosen component identifier is supported. Unsupported identifier → emit `component_unknown` via the helper, write the empty-disable JSON inline (same path as the refusal gate), and proceed with full pipeline next plan:

   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/lib/observations.sh" \
     "<id>" component_unknown "unknown: <retro report path>"
   ```
2. Read existing `docs/retros/harness-config.json` if present; include its current content in the retrospective report under "Previous Harness Config" for audit.
3. Write the new `docs/retros/harness-config.json` with exactly one entry (or an empty `disabled_components` array if the test is being closed — see 5d below). `mkdir -p docs/retros` first if needed.
4. Record in the retrospective report:
   - Which component will be disabled (the `component` identifier)
   - Plan context (expected task count, complexity)
   - Reinstate conditions (mirrors the `reinstate_conditions` field): what outcome rolls this back before next retrospective (e.g., ≥1 missed issue the evaluator would have caught)
   - Promotion conditions: what outcome proves the component can be permanently removed via a future REMOVE proposal (e.g., zero missed issues across ≥3 follow-up plans)

**If no candidate is selected this run**, still write `docs/retros/harness-config.json` with `{"version":1,"disabled_components":[]}` to clear any prior disable and return the harness to defaults. This is the closure path for a completed disable test.

The next retrospective reads `harness-observations.jsonl` (written by consuming skills) in Phase 1 and judges whether to promote the disable into a permanent config change (via standard ADD/REMOVE/MODIFY proposals in Phase 3) or to reinstate the component (by clearing the entry from harness-config.json in 5c of that run).

## Phase 6: Output

Write the retrospective report to `docs/retros/retro-{date}-{topic}.md`:

1. Analysis tables (failure frequency, plateaus, never-failing, variety gaps)
2. Proposals with approval status
3. Checklist versions updated (if any)
4. Harness Health section:
   - 5a usage-driven recommendations
   - 5b load-bearing candidates table
   - 5c selected one-at-a-time disable test (if any), with quality delta thresholds
5. Summary: N proposals approved, M rejected, checklists updated to version X, harness component disabled for next run (if any)

**Close the calibration loop** (mandatory): Emit one `retrospective_run` row via the helper. Payload-only filter omits `event`/`timestamp` (envelope sets them); reference `$event`/`$timestamp` inside the filter to pin row position.

Compute `consecutive_zero_change` (`C`) inline, BEFORE invoking the helper — this computation stays in SKILL.md, not in the helper:

1. Zero-change run iff `proposals_approved == 0 AND disable_test_set == false`
2. Read the previous `retrospective_run` event in `docs/retros/evolution-log.jsonl` (none on first run)
3. If zero-change: `C = (prior.self_value.consecutive_zero_change // 0) + 1`; else `C = 0`

Then:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/lib/evolution-log.sh" \
  retrospective_run \
  '{event: $event, timestamp: $timestamp, plans_analyzed: ($plans | split(",")), report: $report, proposals_approved: $approved, proposals_rejected: $rejected, disable_test: (if $disable_test == "" then null else $disable_test end), self_value: {proposals_total: ($approved + $rejected), disable_test_set: ($disable_test != ""), consecutive_zero_change: $C}}' \
  --arg plans "<plan1,plan2>" --arg report "<retro-md>" \
  --argjson approved <N> --argjson rejected <M> \
  --arg disable_test "<supported id or empty for null>" --argjson C <C>
```

`disable_test` MUST be either empty (rendered as `null`) or a supported `harness-config.json` identifier (`./references/harness-config.md`) — never free-text.

When this run is also a Phase 5b post-plan-diff veto, emit a `component_reinstated` row via the same helper (see `./references/evolution-protocol.md` for the full payload schema — fields `component`, `previously_disabled_in`, `reinstatement_method`, `evidence`, `rationale`, `follow_up`).

The `retrospective_run` entry is the closure marker — do not skip it even when zero proposals approved (the run is the signal that produced `consecutive_zero_change++`).

## References

- `./references/analysis-patterns.md` - Failure frequency, plateau detection, never-failing analysis, harness health criteria
- `./references/evolution-protocol.md` - Proposal types, thresholds, version management, evolution log schema, pre-edit snapshot, `component_reinstated` event schema
- `./references/harness-config.md` - `harness-config.json` schema and lifecycle for one-at-a-time component disable
- `${CLAUDE_PLUGIN_ROOT}/lib/post-plan-diff.sh` (v2.8.1) - classifies post-plan commits as `feedback` (refactor/fix/style/perf — user correcting superpowers output) or `evolution` (feat/chore/docs/build/ci/test — user adding new requirements). Used by Pre-Check A and Phase 1 step 8 to close the calibration loop's largest blind spot
