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
| 3 | (process note, not a checklist item) | — | **Touchpoints were written into all 4 SKILL.md files, but this very execution bypassed them.** The main agent drove executing-plans via inline batch coordinator sub-agents (not the skill's own Phase 5 `set-status implemented:<sha>` step) and drove the retrospective inline (not retro's Phase 6 `upsert retro` step). Result: the index stayed `wip` and the retro report wasn't logged until the user asked and the gap was caught. The touchpoints are calibrated for *future user-invoked skill runs*, not for the agent that *installs* them. | Not a proposal — a process observation. No checklist item captures "did the running agent actually invoke the touchpoints it just wrote?" because that's a meta-execution concern, not a property of produced artifacts. | Re-surface if a future retro notices the same pattern: index out-of-date after a skill-implementation run because the implementing agent didn't dogfood its own touchpoints. Possible mitigations to discuss in a future retro: a SessionStart/Stop hook that runs `docs-index.sh rebuild` as a safety net, or an explicit "dogfood" step in executing-plans Phase 6. |

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
- **`repo_root()` parent-repo fallback (informational, but caused real silent wrong-location writes in this run):** `repo_root()` (in `lib/utils.sh`) resolves `${CLAUDE_PROJECT_DIR}` → `git rev-parse --show-toplevel` → `${PWD}`. At skill runtime, `CLAUDE_PROJECT_DIR` points at the user's project, so the index correctly lands at the user's `docs/README.md`. But when developing the plugin itself (running `lib/docs-index.sh` by hand from within `superpowers/`), `CLAUDE_PROJECT_DIR` is typically unset and `git rev-parse --show-toplevel` resolves to the parent `dotclaude/` repo — so a bare `bash lib/docs-index.sh rebuild` writes to `dotclaude/docs/README.md`, NOT `superpowers/docs/README.md`.

  **Impact in this run (not just theoretical):** After Batch 6 committed, the main agent ran `set-status`/`upsert` to refresh the index (design→active, plan→implemented, retro report→active). Because `CLAUDE_PROJECT_DIR` was unset, every call silently targeted `dotclaude/docs/README.md` (which was empty/absent), so: (a) `set-status` returned exit 3 ("not in index") on paths that were clearly in `superpowers/docs/README.md`, and (b) the retro `upsert` wrote a single-row index to `dotclaude/docs/README.md`, appearing to "lose" the 3 existing rows — they were never read because the wrong file was opened. The user caught this when asking "did you update docs/README.md?" and the index still showed `wip` everywhere.

  **Root cause:** Not a code bug in `cmd_upsert`/`cmd_show` — those correctly preserve/append rows. The bug is that `repo_root`'s fallback silently targets the wrong project when the plugin is a subdirectory of a larger git repo and `CLAUDE_PROJECT_DIR` is unset. The design (requirement #7) says "MUST survive the absence of git/jq" but did not document this fallback's behavior.

  **Fix applied this run (post-retro):** (1) Documented the behavior in `lib/docs-index.sh` header (a "Root resolution" comment block explaining the resolution order and the `CLAUDE_PROJECT_DIR=...` override for plugin-self-development). (2) Re-ran the index updates with `CLAUDE_PROJECT_DIR` set to the superpowers dir; index now correctly shows `design=active`, `plan=implemented:e4bbd2b`, retro report `active`, `writing-skills=reference`. Committed in `7ab43e0`. No checklist change — this is a documentation/UX gap, not a checklist-enforceable defect.

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
4. **Historical items all `wip` after first rebuild (signal #4, deferred):** When `docs-index.sh rebuild` runs for the first time against an existing `docs/` tree (this run: 8 plans + 4 retros already on disk), every row gets the default `wip`/`active` status because there's no prior index to inherit statuses from. The 2026-04/05 plans/designs are in fact implemented or superseded, but the index cannot infer that from the filesystem alone. A future retro should walk these historical rows and set `implemented:<sha>` / `superseded-by:` / `expired:` per the actual project history (git log + prior retro reports). Re-surface trigger: any future retro touching a plan whose index row is still the first-rebuild default `wip` despite clear historical completion evidence.
5. **Plugin operates on `../docs/`, not its own `docs/` (architectural clarification, committed `d6b8d49`):** The superpowers plugin is a generic, reusable artifact. Its `docs-index.sh` resolves `repo_root` to the *user's project* top-level, so it operates on `<user-project>/docs/` — which, from the plugin's perspective, is `../docs/`. All this session's artifacts (design, plan, retro, code-v1 checklist) were initially written to `superpowers/docs/` (the plugin's own dir) by mistake; they have been relocated to `docs/` (the project's dir) via `git mv` in commit `d6b8d49`. The wrongly-seeded `superpowers/docs/retros/checklists/{design,plan,code}-v1.md` were deleted (the project already had its own evolved versions at `docs/retros/checklists/`, up to design-v2/code-v3). The `docs/writing-skills/` reference stays in `superpowers/docs/` — it is the plugin's bundled reference material, not project documentation.

### Closure

Calibration loop closed via `retrospective_run` evolution-log row (emitted next, via `lib/jsonl-emit.sh`).
