# Retrospective — 2026-07-09 — memory-layer + agentbook designs

**Invocation:** `/superpowers:retrospective` (no argument → auto-scope after last `retrospective_run`)
**Date:** 2026-07-09
**Plans / designs in scope:** 3 with evaluation data post-watermark
- `docs/plans/2026-07-04-superpowers-memory-layer-design/` (design, 4 rounds → PASS)
- `docs/plans/2026-07-04-superpowers-memory-layer-plan/` (plan, implemented at `57d3738`, 5 batches + 1 rework round)
- `docs/plans/2026-07-06-agentbook-memory-design/` (design, 6 rounds → PASS; plan not yet written)
**Also consulted (no formal code/plan evals, status only):**
- `docs/plans/2026-07-08-designing-loops-design/` (design, 2 rounds → PASS; plan `active` not implemented)
- `docs/plans/2026-07-08-designing-loops-plan/` (plan `active`, not in implemented set)
**Mode:** design + code (memory-layer plan used code-v3 via sprint contracts)
**Outcome:** 1 proposal approved (MODIFY design/REQ-TRACE-01 → `design-v3.md`), 3 self-rejected, 4 deferred.

---

## Pre-Check Results

### Pre-Check A — INSUFFICIENT-POST-PLAN advisory

`docs/retros/plans-completed.jsonl` is absent → no `completion_commit` field available via the formal channel. Fallback: docs-index row for memory-layer plan carries `implemented:57d3738`. Hours since that commit ≈ 70h (> 24h). Scoped `post-plan-diff.sh summary 57d3738 <memory-layer files>` returns `total=5` (feedback=4, evolution=1) → **not** the empty-window advisory. Skip the verbatim INSUFFICIENT-POST-PLAN reminder; proceed.

### Pre-Check B — Persistent memory calibration priors

Selected from the session-injected `MEMORY.md` index (hooks only; topic files not re-read):

| Hook | Signal carried into this run |
|---|---|
| `reference_anthropic_harness_blog` / simplify-don't-add | Suppress weakly-justified ADDs; REMOVE is load-bearing. Applied: self-rejected CODE-CORRECTNESS ADD (1-plan evidence, already covered by evaluator no-suppression standard) and suppressed bulk REMOVE of load-bearing v2 items. |
| `feedback_skill_level_enforcement` | L2 must carry CRITICAL. Not directly actionable on checklist content; noted. |
| `feedback_self_audit_caught_my_bugs` / `feedback_verification` | Verify before reporting. Applied: every FAIL count below was re-derived from the evaluation report files this run, not trusted from prior retros. |
| `feedback_null_alternative_first` | Before adding delivery surfaces, argue the null alternative. Applied as anti-ADD prior. |
| `project_active_design_work` | Checklist version map (design-v1/v2, plan-v1, code-v1/v2/v3) — matches on-disk pre-edit state. |
| `project_superpowers_upstream_lessons` | Upstream v6 constraints already absorbed; no re-proposal of those shapes. |
| `project_agentbook_commons_bridge` | agentbook design is active and already PASS round 6 — in scope as a design-eval source, not as a plan to re-implement. |
| `docs/memory/pitfall_bdd-specs-explicit-req-tracing` (project memory, active) | Directly predicts the REQ-TRACE thrash — the authoring-side workaround already exists. This retro elevates the same signal into the checklist so the *evaluator* enforces what authors already know. |

No recalled prior is contradicted by the approved proposal below.

---

## Phase 0 — Bootstrap

All three modes have v1+ present:

| Mode | Latest pre-edit | Items |
|---|---|---|
| design | design-v2.md | 10 (5 v1 + 5 v2) |
| plan | plan-v1.md | 5 |
| code | code-v3.md | 5 |

**Phase 0: all checklists present, skipping seed.**

---

## Phase 1 — Data Collection

### 1. Scope resolution

Most recent `retrospective_run` watermark: **2026-07-04T11:13:30Z** (`docs/retros/retro-2026-07-04-docs-index-plan.md`, plans_analyzed = docs-index-plan only).

Plans completed / designs evaluated after that watermark:

| Path | Kind | Status | Eval reports |
|---|---|---|---|
| `docs/plans/2026-07-04-superpowers-memory-layer-design/` | design | active (design PASS round 4) | 4 (`evaluation-design-round-{1..4}.md`) |
| `docs/plans/2026-07-04-superpowers-memory-layer-plan/` | plan | `implemented:57d3738` | 6 code-mode (`evaluation-round-1-batch-{1..5}.md` + `evaluation-round-2-batch-2.md`) |
| `docs/plans/2026-07-06-agentbook-memory-design/` | design | active (design PASS round 6) | 6 (`evaluation-design-round-{1..6}.md`) |
| `docs/plans/2026-07-08-designing-loops-design/` | design | active (PASS round 2) | 2 (all PASS; used as calibration, not a failure source) |
| `docs/plans/2026-07-08-designing-loops-plan/` | plan | active (not implemented) | 0 formal eval reports |

`docs-index.sh list --status expired` → one row: `2026-05-01-notification-system-design` (expired by retro-2026-05-09; already known; not re-proposed).

`docs-index.sh list --kind memory --status active` → 2 rows (both pitfalls; folded into Phase 2 / Phase 5 notes).

### 2. Latest checklists

- design: `design-v2.md`
- plan: `plan-v1.md`
- code: `code-v3.md`

### 3. Evolution history (calibration input)

| item_id | most recent event | when | provenance / notes |
|---|---|---|---|
| CODE-ENV-ISO-01 | item_added | 2026-06-02 | phase_5a post-plan override |
| CODE-TEST-LIVE-01 | item_added | 2026-06-02 | maintainer_baseline (`driving_plans:[]`) |
| AUDIT-RUN-01, DECOUPLE-01, N0-NFR-01, PERF-01, SCOPE-CREEP-01 | item_added | 2026-06-08 | hook_backfill from design-v2 diff (rationale empty) |
| TEST-001 / event=test | pollution | 2026-06-02 | prior retro already flagged; still present |
| (no item_removed ever) | — | — | REMOVE channel has never fired in this project |

No re-proposal guard is armed against the MODIFY below (REQ-TRACE-01 has never been removed or modified in the log).

### 4. Post-plan diff (memory-layer plan @ `57d3738`)

Scoped to the plan's modified-files set:

| sha | subject | class |
|---|---|---|
| 255df5c | fix(sp): narrow brainstorming trigger scope | feedback |
| 06c97b0 | fix(refactor): align config & docs to plugin spec | feedback (README only in this file set) |
| a41cd9a | feat(sp): implement 8 upstream superpowers lessons | evolution |
| a0a8e01 | fix: env-backend validation and pipe-escaping bugs | feedback |
| 214edb5 | refactor(sp): move bootstrap logic to reference | feedback |

Summary: `{total:5, feedback:4, evolution:1, unknown:0}`. Window ≈ 70h.

Classified feedback themes:
1. **Trigger-scope precision** (`255df5c`) — brainstorming description over-fired / under-fired on hardware vs software axis. Outside checklist surface (skill description, not design/plan/code artifact).
2. **Pipe-escaping in docs-index summaries** (`a0a8e01`) — data-dependent edge case in `docs-index.sh`; regression tests added. Evaluator coverage gap for "summary may contain `|`" — candidate for future CODE ADD if it recurs on another plan.
3. **Token-budget overflow on retrospective SKILL.md** (`214edb5`) — moved Phase 0 prose to `references/bootstrap.md`. Process/hygiene, not a checklist item.
4. **README drift** (`06c97b0`) — marketplace/README sync; already covered by project convention (`project_readme_sync_manual`), not a checklist gap.

No feedback cluster graduates to a Phase 3 ADD under the 1-plan override this run — each theme is either out-of-surface, already-conventioned, or single-instance.

### 5. Minimum-data note

2 distinct design plans with multi-round FAILs → ADD threshold (2+ plans) is reachable for design-mode patterns. Code-mode has only 1 implemented plan with formal sprint-contract evals (memory-layer) → code ADD requires the Phase 5a 1-plan override, applied only when a post-plan feedback cluster is evaluator-missed; none of the four feedback commits meet that bar cleanly. Plan-mode: no formal plan-mode evaluation reports this window (memory-layer plan went straight to code-mode sprint contracts; designing-loops plan not yet executed).

---

## Phase 2 — Pattern Analysis

### Failure frequency (distinct plans)

| Item | FAIL plans | FAIL rows | PASS rows | Reports seen | Notes |
|---|---|---|---|---|---|
| **REQ-TRACE-01** | **2** | 4 (table rows; many more rework cycles under the same ID) | 2 (final PASS rounds) | 20+ | Dominant signal. memory-layer: rounds 1–3 REWORK; agentbook: rounds 1–5 REWORK. |
| SCEN-CONC-01 | 1 | 1 | 4 | 12 | Regression introduced by a round-1 REQ-TRACE fix on memory-layer; fixed round 2. |
| RISK-02 | 1 (agentbook round 5 only) | 1 | 7 | 15 | Late discovery: no consolidated `## Risks` section. Fixed round 6. |
| All other design items (JUST/ARCH/PERF/DECOUPLE/AUDIT/N0/SCOPE) | 0 | 0 | 4–7 each | 10–14 | Zero FAILs. |
| All code-v3 formal items | 0 | 0 | ~80 task-item rows | 6 reports | All PASS or N/A. |
| CORRECTNESS-01 (custom, not in checklist) | 1 batch | 1 | 1 (round 2) | 1 | Surfaced by evaluator's no-suppression standard beyond the 5 named items. |

### Plateau tasks / multi-round REWORK

| Plan | Item | Consecutive REWORK rounds | Root cause |
|---|---|---|---|
| memory-layer design | REQ-TRACE-01 | 3 (rounds 1→2→3; PASS on 4) | Round 1: req #20 covered for 2/5 skills. Round 2: req #23 (Pre-Check-B promotion) missing. Round 3: reqs #24/#28/#30 architecture-only, never in bdd-specs. Each round found a *new* gap the previous fix did not address — no full-set scan. |
| agentbook design | REQ-TRACE-01 | 5 (rounds 1→5; PASS on 6) | Round 1: #12/#15/#17. Round 2: #15 autoresearch sub-clause. Round 3: #16/#21. Round 4: dangling cross-ref. Round 5: 13 requirements lacked explicit `(Req #N)` tags (evaluator raised the standard from topical-match to explicit-ID). Same umbrella item, progressive stricter reading. |
| memory-layer plan batch 2 | CORRECTNESS-01 (custom) | 1 (round 1 REWORK → round 2 PASS) | Archive-on-drop conflated stage-1 collapse with stage-2 drop. Fixed + companion test. Not a checklist item. |

### Never-failing items (0 FAIL, ≥3 reports)

| Item | Reports | PASS rows | REMOVE? |
|---|---|---|---|
| JUST-01 | 14 | 5 | **No** — load-bearing meta-gate (NOT-JUSTIFIED status). Vacuous PASS is the success case. |
| ARCH-01 | 14 | 6 | **No** — layer-direction gate; most designs are leaf-script extensions with no layers to violate. |
| RISK-02 | 15 | 7 | **No** — agentbook round 5 *did* FAIL it once; the zero-FAIL table above under-counted because the FAIL was in a rework section more than the primary table. Keep. |
| PERF-01 | 12 | 5 | **Defer** — condition ("LLM on Stop/PostToolUse/UserPromptSubmit path") rarely present → vacuous PASS dominates. Origin case was real. Revisit when a design *with* a hot-path LLM call lands. |
| DECOUPLE-01 | 12 | 5 | **Defer** — same conditional shape (shared env-var guards). |
| AUDIT-RUN-01 | 12 | 5 | **Defer REMOVE candidate** — condition ("retract triggers declared") has not appeared in any design since the origin case. Closest to a true never-fire. Deferred under EVO-6 priority (MODIFY > REMOVE) and because the origin failure mode is still architecturally possible. |
| N0-NFR-01 | 12 | 5 | **Defer** — numeric-threshold condition. |
| SCOPE-CREEP-01 | 12 | 5 | **Defer** — bundled-fix condition. |
| CODE-VER/QUAL/ENV/TEST-LIVE | many | all | **No** — they fire as the definition of a green batch; zero FAIL is expected when the loop works. |

### Variety gaps

1. **REQ-TRACE thrash under one umbrella item.** Multiple rework rounds, all PASS on final, but the checklist never forced a full-set scan or an explicit citation form for numbered (non-`REQ-NNN`) requirements. This is the load-bearing variety gap of this run → MODIFY.
2. **Code-mode CORRECTNESS beyond the 5 named items.** Batch-2's archive-on-drop bug was caught only because the evaluator applied the no-suppression evidence-based standard. The 5 formal items all PASS'd while the shipped behavior was wrong. Candidate CODE-CORRECTNESS ADD — self-rejected this run (1 plan; see Phase 3).
3. **Plan-mode checklist not exercised.** memory-layer plan and designing-loops plan produced no `evaluation-plan-round-*.md`. The 2026-07-04 retro's deferred PLAN-COV-01 / TEST-01 MODIFYs therefore still have only 1 false-positive instance each — threshold not met.
4. **designing-loops first-round PASS.** 2 rounds, 10/10, no REWORK. Positive signal; not yet the 3-plan "per-batch evaluation may be reducible" threshold.

---

## Phase 3 — Evolution Proposals

### Approved (auto-applied in Phase 4)

#### Proposal 1 — MODIFY design / REQ-TRACE-01

```
Proposal: MODIFY design / REQ-TRACE-01
Description: Dual-format ID extraction (REQ-NNN + numbered list); require explicit
  citation form in bdd-specs.md ((Req #N) / Req #N / REQ-NNN); mandate full-set
  scan every evaluation round; reject topical-match-only coverage.
Rationale: Same umbrella item produced 3 consecutive REWORK rounds on
  memory-layer design and 5 on agentbook design. Root cause is the mechanical
  script grepping only REQ-NNN (vacuous PASS on numbered lists) plus the
  absence of a full-set scan rule, which let each round invent a stricter
  standard and find a new gap. The authoring-side pitfall memory
  (pitfall_bdd-specs-explicit-req-tracing) already records the workaround;
  elevating it into the checklist makes the evaluator enforce the same bar
  on round 1.
Evidence:
  - memory-layer design rounds 1-3 (REQ-TRACE-01 FAIL each; distinct missing
    IDs #20 → #23 → #24/#28/#30)
  - agentbook design rounds 1-5 (REQ-TRACE-01 FAIL each; progressive standard
    from topical-match to explicit (Req #N) tags, round 5 alone re-tagged 13
    requirements)
  - designing-loops design (PASS) used REQ-NNN from the start and avoided the
    thrash — positive control for the dual-format fix
Outcome: applied → design-v3.md
```

### Self-Rejected Proposals

| # | Type | Target | Item | Rejection rationale |
|---|---|---|---|---|
| 1 | ADD | code-v3 | CODE-CORRECTNESS-01 — "evaluator must reproduce at least one acceptance fixture beyond the produced test suite" | **Self-rejected.** 1-plan evidence (memory-layer batch 2 only). The evaluator's existing no-suppression / evidence-based standard already caught it; encoding that standard as a new named item is a weak ADD under the simplify-don't-add prior. Re-surface if a second plan's batch evaluator has to invent a custom CORRECTNESS-01 again. |
| 2 | ADD | design-v2 | DESIGN-REQ-FORMAT-01 — "requirements must use REQ-NNN" | **Self-rejected.** Redundant with the REQ-TRACE-01 MODIFY above (which accepts both formats). Forcing REQ-NNN would churn every existing design for no detection gain. |
| 3 | REMOVE | design-v2 | bulk REMOVE of PERF/DECOUPLE/AUDIT/N0/SCOPE (5 items) | **Self-rejected (partial — see Deferred).** All five are *conditionally* scoped; vacuous PASS when the condition is absent is correct behavior, not "never fires." Bulk-removing the v2 layer would re-open the exact blind spots that created them. AUDIT-RUN-01 is the closest true never-fire and is deferred (not rejected) below. Anti-add-bias prior also argues against a reverse-add-bias of bulk-deleting load-bearing conditional gates. |

### Deferred Proposals (evidence insufficient this run)

| # | Type | Target | Signal | Defer rationale | Re-surface trigger |
|---|---|---|---|---|---|
| 1 | MODIFY | plan-v1 / PLAN-COV-01 | Literal `grep -lq "$title"` false-positive when tasks rewrite scenario titles | Still 1 false-positive instance (docs-index plan, prior retro). Threshold = 2. | Next plan-mode evaluation that hits the same false-positive. |
| 2 | MODIFY | plan-v1 / TEST-01 | Same-ID pair assumption vs ID-adjacent pairs in structure-template | Still 1 instance. | Same. |
| 3 | REMOVE | design / AUDIT-RUN-01 | 0 FAIL across 12 reports; condition (retract triggers) has not appeared since origin | Origin failure mode still architecturally possible; EVO-6 prioritised the REQ-TRACE MODIFY. | One more retro window with 0 retract-trigger designs → promote to REMOVE. |
| 4 | ADD | code / CODE-SUMMARY-ESC-01 | `a0a8e01` pipe-escaping in docs-index summaries | 1-plan post-plan feedback; regression tests already land in-tree. | Recur on another plan that writes pipe-bearing summaries without escaping. |

**EVO-6 rate limit:** 1 approved of max 3 per mode this run (design mode). Code and plan modes: 0 approved.

---

## Phase 4 — Auto-Apply

### Pre-Edit Snapshot: design-v2.md

Full pre-edit content of `docs/retros/checklists/design-v2.md` is preserved on disk unchanged (versioned files are append-only; v2 is not mutated). Rollback for the v3 change:

```
# To roll back this run's design evolution:
rm docs/retros/checklists/design-v3.md
# design-v2.md remains the latest; no other files to restore.
```

(The full v2 content is not inlined here — it is byte-identical to the on-disk `design-v2.md` which this run does not touch. Prior retros that mutated in place needed a full paste; the version-increment protocol makes the prior file itself the snapshot.)

### New version written

- `docs/retros/checklists/design-v3.md` — self-contained; REQ-TRACE-01 restated with dual-format extraction + explicit citation + full-set scan rule; all other v1/v2 items retained inline.

### Evolution-log rows

Emitted via `lib/jsonl-emit.sh` (see Phase 6 closure for the `retrospective_run` row):

1. `item_modified` / REQ-TRACE-01 / `design-v3.md`

### Memory file drafted (Phase 4 step 3.5)

For the applied MODIFY:

- `docs/memory/convention_req-trace-explicit-citation.md` — elevates the evaluator-side rule that the existing authoring-side pitfall (`pitfall_bdd-specs-explicit-req-tracing`) already taught authors. Distinct files: one is "how to write bdd-specs so round 1 passes"; this one is "what design-v3's REQ-TRACE-01 now enforces." Not a consolidation (different audiences / different source events).

---

## Phase 5 — Harness Health (advisory)

### 5a. Post-Plan Correction Mining

Scoped feedback (4 commits) did **not** cluster around a pattern the batch evaluator missed:

| Commit | Theme | Evaluator coverage? | Graduate to ADD? |
|---|---|---|---|
| 255df5c trigger scope | skill description precision | Outside design/plan/code checklist surface | No |
| a0a8e01 pipe escape | summary field sanitisation | Missed by code-v3 (no "output encoding" item) | Deferred (1-plan) |
| 214edb5 bootstrap extract | token-budget hygiene on SKILL.md | Outside checklist (process) | No |
| 06c97b0 README | marketplace/README sync | Covered by project convention, not checklist | No |

No Phase 5a 1-plan ADD this run.

### 5b. Usage-Driven Recommendations

- **designing-loops design passed first/second round with 0 REWORK.** 1 data point toward "design evaluation may be reducible for reference-file-shaped designs"; need 3+ plans. Not acted on.
- **Plan-mode checklist is going unexercised.** Two recent plans (docs-index via inline coordinators; memory-layer via code-mode sprint contracts; designing-loops not yet run) produced zero plan-mode evaluation reports. The deferred PLAN-COV-01 / TEST-01 MODIFYs cannot graduate without plan-mode rounds. Recommendation (report note only): when writing-plans Phase 4 reflection runs, ensure it still emits `evaluation-plan-round-*.md` even for small plans — otherwise the plan checklist rots.
- **evolution-log still carries the 2026-06-02 test-pollution rows** (`TEST-001`, `event=test`). Prior retro flagged them; still present. Not a checklist item; a one-line manual cleanup remains available.
- **`plans-completed.jsonl` still absent.** The Stop hook that should write it either is not firing or the host lacks a prerequisite. Retrospective continues to fall back to docs-index `implemented:<sha>` rows. Report note only.

---

## Phase 6 — Summary

| Metric | Value |
|---|---|
| Plans / designs analyzed | 3 primary (+ 2 calibration) |
| Evaluation reports read | 18 (4 + 6 + 6 design/code; +2 designing-loops) |
| Proposals approved | **1** (MODIFY design/REQ-TRACE-01) |
| Proposals self-rejected | **3** |
| Proposals deferred | **4** |
| Checklists updated | design-v2 → **design-v3** |
| Memory files drafted | 1 (`convention_req-trace-explicit-citation.md`) |
| Designs invalidated | none (`invalidates:` none — a checklist MODIFY does not expire a design) |

**Close:** checklist evolution is the REQ-TRACE-01 MODIFY only. Authors already had the authoring-side pitfall memory; evaluators now share the same explicit-citation + full-set-scan bar on round 1. Review via `git show docs/retros/checklists/design-v3.md` (and the diff against design-v2).
