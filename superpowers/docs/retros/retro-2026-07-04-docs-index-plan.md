# Retrospective — 2026-07-04 — docs-index-plan

**Plan analyzed:** `docs/plans/2026-07-04-docs-index-plan/` (commit `cc340be`, executed in commit `e4bbd2b`)
**Mode:** plan + code (single-plan scope)
**Date:** 2026-07-04
**Plans in scope:** 1 (docs-index-plan)

## Pre-Check Results

- **Pre-Check A (INSUFFICIENT-POST-PLAN advisory):** `docs/retros/plans-completed.jsonl` absent → no `completion_commit` → skip silently. (The Stop hook did not yet backfill a `plan_completed` event for this plan at retro time.)
- **Pre-Check B (memory calibration priors):** Three relevant hooks recalled:
  - `feedback_skill_level_enforcement` — L2 SKILL.md must carry CRITICAL markers. Verified: all 4 skills' upsert-after steps marked CRITICAL. No drift.
  - `feedback_verification` / `feedback_self_audit_caught_my_bugs` — verify before reporting. Verified: every batch coordinator pasted fresh verification evidence (test tallies) in its return.
  - `reference_anthropic_harness_blog` / `project_superpowers_upstream_lessons` — simplify-don't-add, anti-add-bias stance. Applied: suppressed two weak ADD proposals below (1-plan evidence, design deferred to existing `repo_root` resolution).

## Phase 0 — Bootstrap

- `design-v1.md` and `plan-v1.md` already present (seeded during brainstorming/writing-plans).
- `code-v1.md` was missing → seeded this run via `lib/seed-checklists.sh code docs/retros/checklists/code-v1.md` (exit 0).

## Phase 1 — Data Collection

- **Plans in scope:** 1 (`docs/plans/2026-07-04-docs-index-plan/`).
- **Evaluation reports found:** 1 design-mode report (`docs/plans/2026-07-04-docs-index-design/evaluation-design-round-1.md`, verdict PASS, 0 rework). No plan-mode or code-mode evaluation reports — executing-plans used inline batch coordinator sub-agents (not formal sprint contracts + per-batch evaluator files), which the skill permits via its bail-out check.
- **Evolution history:** `docs/retros/evolution-log.jsonl` absent → empty history table. No re-proposal guard needed.
- **Post-plan diff (Phase 1 step 6):** completion commit `e4bbd2b` is HEAD; no `fix:`/`refactor:`/`style:`/`perf:` commits after it. No feedback cluster to mine.

## Phase 2 — Pattern Analysis

### Failure frequency (across 1 plan)

No checklist item produced a committed FAIL. Two items produced **pre-commit false-positive FAILs that were manually resolved before the plan committed** — these are the load-bearing signal of this run:

| Checklist item | Pre-commit FAIL | Resolution | Recurrence risk |
|---|---|---|---|
| PLAN-COV-01 (plan-v1) | Reflection sub-agent flagged 19/22 scenarios "UNCOVERED" via literal `grep -lq "$title"` — task files *rewrote* scenario titles instead of copying them verbatim. | Main agent added `**Covers design scenarios (verbatim titles):**` blocks with exact titles to every task file; corrected 2 paraphrased titles. | HIGH — the skill instructions say "matched by scenario title **or** a BDD Scenario section," which is ambiguous; executors lean toward rewriting. Every future plan will hit this unless the check method or the instructions change. |
| TEST-01 (plan-v1) | Reflection sub-agent's literal bash `${impl%-impl.md}-test.md` substitution reported all 10 impl files "unpaired" — because the plan uses **ID-adjacent pairs** (002-test / 003-impl), not same-ID pairs. | Manually verified semantic pairing via depends-on; accepted as PASS. | MEDIUM — the structure-template.md example *itself* uses ID-adjacent pairs (002-impl depends on 003-test), so the checklist's bash proxy contradicts the documented pattern. |

### Plateau tasks
None. No task went through 2+ consecutive REWORK rounds. All batches went RED→GREEN in one coordinator dispatch each.

### Never-failing items
Insufficient data (1 plan, no code-mode evaluation reports). Cannot identify REMOVE candidates — need 3+ reports per item per the threshold.

### Variety gaps
The one variety gap: executing-plans produced **no code-mode evaluation artifacts** (no sprint contracts, no per-batch evaluator reports). The skill permits this for small plans (bail-out < 5 tasks/batch), but it means code-v1 checklist items (CODE-VER-01, CODE-QUAL-01, CODE-QUAL-02, CODE-TEST-LIVE-01) were never formally evaluated for this plan — verification happened inline in coordinator returns, not against the code checklist. This is a coverage gap for the retro to mine, not a defect.

## Phase 3 — Evolution Proposals

### Self-Rejected Proposals (anti-add-bias, 1-plan evidence)

| # | Proposed type | Target | Item | Rejection rationale |
|---|---|---|---|---|
| 1 | ADD | plan-v1 | A new item capturing "task files must copy design scenario titles verbatim" | **Self-rejected**: 1-plan evidence (ADD requires 2+ distinct plans). Also contradicts the simplify-don't-add memory prior — the friction is better fixed by MODIFY-ing PLAN-COV-01's check method (signal #1 below) than by adding a redundant item. |
| 2 | ADD | code-v1 | A new item capturing "repo_root() fallback to parent git repo must be documented" | **Self-rejected**: 1-plan evidence. The design explicitly deferred to `repo_root`'s existing resolution; all tests pass. Adding a checklist item for an undocumented edge case is a weak ADD that the anti-add-bias prior suppresses. |

### Deferred Proposals (recorded for future runs, evidence insufficient this run)

| # | Proposed type | Target | Signal | Defer rationale | Re-surface trigger |
|---|---|---|---|---|---|
| 1 | MODIFY | plan-v1 / PLAN-COV-01 | The checklist's bash check method (`grep -lq "$title"`) contradicts the skill instruction's "title **or** BDD Scenario section" allowance — executors rewrite titles, producing false-positive FAILs. MODIFY the check method to also accept an explicit `**Covers design scenarios:**` annotation block (which this plan added as a workaround). | MODIFY requires 2+ false positives. This run produced 1 (manually resolved pre-commit, so not in the committed plan's history). | Recur on the next plan — if the next plan's reflection sub-agent raises the same PLAN-COV-01 false-positive, that's the 2nd instance → promote to a real MODIFY proposal. |
| 2 | MODIFY | plan-v1 / TEST-01 | The checklist's bash proxy (`${impl%-impl.md}-test.md`) assumes same-ID test/impl pairs, but the structure-template.md example uses ID-adjacent pairs (002-test / 003-impl). MODIFY the check method to pair by slug, not by filename substitution. | MODIFY requires 2+ false positives. 1 instance this run. | Same — recur on the next plan. |

**Zero proposals approved this run.** All 4 candidate signals either self-rejected (anti-add-bias, 1-plan) or deferred (1 false-positive, need 2). This is the correct outcome under the "REMOVE is load-bearing / counter monotonic growth" principle: a checklist that only grows is a calibration failure, and a single-plan retro does not have the cross-plan evidence to justify growth.

## Phase 4 — Auto-Apply

No proposals approved → no new checklist version files written this run. `design-v1.md`, `plan-v1.md`, `code-v1.md` remain at v1.

**Evolution-log emit:** no `item_added`/`item_removed`/`item_modified`/`item_promoted` rows to emit (zero approved proposals). Only the `retrospective_run` closure row (Phase 6) is emitted.

## Phase 5 — Harness Health (advisory)

### 5a. Post-Plan Correction Mining
**No feedback cluster.** Completion commit `e4bbd2b` is HEAD; no `fix:`/`refactor:`/`style:`/`perf:` commits followed it. The implementation landed in a single commit with all tests GREEN (101/101 docs-index + 24/24 touchpoints). No evaluator coverage gap surfaced via post-plan corrections.

### 5b. Usage-Driven Recommendations (report notes only)

- **All batches passed first round (no REWORK) across this plan.** 1 plan — not enough for the 3-plan "per-batch evaluation may be reducible" recommendation, but noted as a positive signal.
- **Code-mode checklist was not formally exercised this run** (executing-plans used inline coordinators, not sprint contracts). If 3+ successive plans follow the same inline-coordinator shape, consider a MODIFY proposal to align code-v1's evaluation surface with the inline-coordinator pattern (or document that code-v1 is only evaluated when sprint contracts are produced). Re-surface trigger: 3+ plans with no code-mode eval reports.
- **`repo_root()` parent-repo fallback (informational):** Batch 6 coordinator had to set `CLAUDE_PROJECT_DIR` explicitly to seed `docs/README.md` at the plugin's own `docs/` rather than the parent `dotclaude/docs/`. This is **correct runtime behavior** (the index should write to the user's project `docs/`, not the plugin's — `CLAUDE_PROJECT_DIR` points at the user's project at runtime). But it's a developer-experience papercut when running `rebuild` by hand on the plugin itself. Not a defect; documented here so future maintainers know to set `CLAUDE_PROJECT_DIR` when seeding the plugin's own index. No checklist change.

## Phase 6 — Output

### Summary

- **Proposals approved:** 0
- **Proposals self-rejected:** 2 (anti-add-bias, 1-plan evidence)
- **Proposals deferred:** 2 (MODIFY PLAN-COV-01, MODIFY TEST-01 — need a 2nd false-positive to promote)
- **Checklists updated:** none (all remain at v1)
- **Code-v1 seeded:** yes (was missing; seeded this run)

### Re-surface triggers for the next retrospective

1. If the next plan's writing-plans reflection raises a **PLAN-COV-01 false-positive** on rewritten scenario titles → promote the MODIFY proposal (signal #1, deferred).
2. If the next plan's reflection raises a **TEST-01 false-positive** on ID-adjacent pairing → promote the MODIFY proposal (signal #2, deferred).
3. If 3+ successive plans use inline coordinators (no code-mode eval reports) → consider a MODIFY aligning code-v1's evaluation surface.

### Closure

Calibration loop closed via `retrospective_run` evolution-log row (emitted next, via `lib/jsonl-emit.sh`).
