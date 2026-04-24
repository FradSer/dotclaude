---
name: retrospective
description: This skill should be used when the user wants to analyze evaluation patterns across completed plans and evolve checklists. Triggered by asking to "run a retrospective", "analyze evaluation patterns", "evolve checklists", or "/superpowers:retrospective".
argument-hint: <plan-path-1> [plan-path-2] [--across-all]
user-invocable: true
allowed-tools: ["Read", "Glob", "Grep", "Write", "Edit", "AskUserQuestion", "Bash(python3:*)"]
---

# Retrospective

Analyze evaluation patterns across completed plans, identify recurring failures, and propose checklist evolution with user approval.

**Chain position**: This skill is the downstream consumer of executing-plans Phase 4 "Checklist Evolution Candidates". It aggregates signals across plans and produces versioned checklist updates.

## Phase 1: Data Collection

1. **Resolve inputs**: Parse `$ARGUMENTS` for plan paths. If `--across-all`, scan `docs/plans/` for all `*-plan/` directories with evaluation reports.
2. **Resolve evals**: For each plan path, look for evaluation reports in the plan directory (`evaluation-round-*.md`). If a sibling `*-evals/` directory exists, read from there instead.
3. **Read checklists**: Scan `docs/retros/checklists/` for latest versions of each mode (`{mode}-v{N}.md`, highest N).
4. **Read reports**: For each plan, read all evaluation report files. Extract per-item results (Item ID, Result, Evidence) and rework items.
5. **Minimum data check**: If only 1 plan provided, warn that ADD proposals require 2+ plans. If fewer than 10 reports per item, warn that REMOVE proposals require 10+ reports.

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

## Phase 4: User Approval and Apply

For each proposal (ordered by priority: regression breaks first, then by frequency):

1. Present via AskUserQuestion with: proposal type, item ID, description, rationale, driving plan evidence
2. **Approved**: Queue for checklist update
3. **Rejected**: Record rejection in retrospective report; no file change

After all proposals reviewed:

1. **Pre-edit snapshot**: Write current checklist content to the retrospective report under "Pre-Edit Snapshot" with rollback instructions
2. **Create new version**: Write `{mode}-v{N+1}.md` with all approved changes applied. Version increments once per run (not per proposal). Original version preserved unchanged.
3. **Log evolution**: Append one JSON object per approved proposal to `docs/retros/evolution-log.jsonl`. See `./references/evolution-protocol.md` for schema.

## Phase 5: Harness Health and Load-Bearing Audit

Assess whether each harness component still earns its cost as models improve. Every harness piece encodes an assumption about model limitations; as those limitations change, some components become pure overhead (see Anthropic harness-design blog: "assumption testing"). All output in this phase is advisory — **never auto-remove components**. The retrospective report (Phase 6) surfaces candidates; the user approves changes in Phase 4 of the *next* retrospective run, not this one.

### 5a. Usage-Driven Recommendations

See `./references/analysis-patterns.md` for criteria.

- If all tasks in recent plans pass on first round (no REWORK), recommend reducing evaluation frequency
- If "Recurring Failure Patterns" injections never improve outcomes, recommend revising intra-plan learning
- If a mode's checklist has only regression items all passing consistently, recommend spot-check mode (every 3rd batch)

### 5b. Load-Bearing Candidate Identification

Flag a component as a **removal candidate** when it satisfies any of the following across **≥3 consecutive plans**:

| Component | Removal-candidate trigger | Signal source |
|-----------|---------------------------|---------------|
| Evaluator at current intensity | Zero rework items produced | evaluation reports in plan dirs |
| Superpower Loop | Loop iterated ≤2 times (retry unused) | state file `iteration` field or plan handoff |
| Sprint contract Evaluation Criteria Preview | First-pass output PASSes every preview item | per-batch evaluation reports |
| Per-batch "Recurring Failure Patterns" injection | Empty across all batches | sprint contract preambles |
| Auto-downgrade to `light` intensity | Triggered for ≥3 consecutive plans | executing-plans handoff log |

Checklist items with zero failures are covered by Phase 3 REMOVE proposals — cross-reference here, do not duplicate.

### 5c. One-At-A-Time Disable Protocol

Select **at most one** candidate from 5b for the next plan run as a live assumption test. Disabling multiple components at once confounds cause-and-effect. Record in the retrospective report:

- Which component will be disabled
- Plan context (mode, expected task count, complexity)
- Quality delta thresholds: what outcome proves the component stays (e.g., ≥2 rework items evaluator would have caught) vs. what proves it can be permanently removed (zero missed issues across ≥3 follow-up plans)

The next retrospective reads this record in Phase 1 data collection and judges whether to promote the disable into a permanent config change (via standard ADD/REMOVE/MODIFY proposals in Phase 3).

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

## References

- `./references/analysis-patterns.md` - Failure frequency, plateau detection, never-failing analysis, harness health criteria
- `./references/evolution-protocol.md` - Proposal types, thresholds, version management, evolution log schema, pre-edit snapshot
