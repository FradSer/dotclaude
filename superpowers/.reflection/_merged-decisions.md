# GAN-Merged Decisions

Referee verdict aggregating the 8 evaluator reports (`0{1..8}-*.md`), the
counter-reflection generator (`00-devils-advocate.md`), and the main-line
meta-reflection (E9 / E10 root question). Documents what got executed in
this fix-all batch, what was deferred, and what was rejected.

Pipeline that produced this:

1. 8 evaluator agents fanned out per-dimension against the Anthropic
   harness-design blog as the reference frame.
2. Main-line meta-reflection identified 7 structural flaws in the
   evaluator pipeline (anchoring, homogeneous consensus, missing
   generator half, static-only evidence, etc.).
3. One devils-advocate generator agent defended the status quo with hard
   constraint "no blog citations allowed" and returned
   HOLD: 3 / SOFTEN: 6 / CONCEDE: 0 across 10 items.
4. Referee merge (this file) reconciled the two sides into 5 concrete
   actions, 1 followup, and 3 outright rejections.

## Decision Matrix

| Item | Evaluator stance | Devils-advocate | Referee verdict | Implementation |
|------|------------------|-----------------|-----------------|----------------|
| E1 — harness-observations telemetry at batch boundaries | high P | SOFTEN (optional) | **EXECUTE — narrowed** | Edited `hooks/track-spawns.sh` to emit one rich row per spawn boundary when `active==true && (edits|reads)>0`. Schema: `{event:"batch_spawn", skill_name, session_id, edits_in_batch, reads_in_batch, ...}`. Reuses existing counters; no new file, no new state. |
| E2 — evaluator few-shot calibration | medium | **HOLD** (reject) | **REJECT** | `lib/seed-checklists.sh` already provides `Check method: grep -nE …` per item, which is more machine-executable than free-form few-shot prose. Adding prose calibration would loosen the grader, not tighten it. |
| E3 — sprint-contract rewrite archival `v{M}` | P0 | **HOLD** (reject) | **REJECT** | `lib/bail-log.sh` + `lib/observations.sh` + git log already form an event/audit layer for contract changes. No new mechanism needed. |
| E4 — retire `build-like-iphone-team` | recommended | SOFTEN | **DEFER + instrument** | Edited `skills/brainstorming/SKILL.md:97` to emit `{event:"sub_skill_loaded", skill:"build-like-iphone-team", payload:{trigger:"brainstorming-open-ended"}}` to `docs/retros/skill-events.jsonl` before loading. Re-evaluate retire/keep after 6–8 weeks of empirical trigger data. |
| E5 — merge 4 lib helpers into `jsonl-emit.sh` | P2 | SOFTEN | **DEFER** | Devils-advocate showed 250-line code reduction would cost ≥1500 lines of test rewrites + ≥6 mo schema-migration tail. Postpone until a separate lib-consolidation cycle; the helpers ship distinct envelope shapes (nest vs merge) that current consumers depend on. |
| E6 — true parallel batches + worktree + plan-mode evaluator | big | SOFTEN | **EXECUTE — narrowed** | Edited `skills/executing-plans/references/batch-execution-playbook.md` to document a `concurrency cap = 4 sub-agents per spawn round` with split-into-rounds protocol. Advisory, not yet hook-enforced. Worktree per sub-agent and a dedicated plan-mode evaluator are deferred until at least one real fan-out exceeds the cap. |
| E7 — orphan-active state scan in `task-start.sh` (P0 critical) | **P0 critical** | SOFTEN (downgrade) | **EXECUTE — different shape** | Devils-advocate's data: 887 state files globally, 9 (=1%) `active:true` orphans, all `session_id="default"` legacy schema, newest is 19 days old. Zero-code one-shot cleanup is the better fix. Created `scripts/cleanup-legacy-state.sh` with `--days N`, `--include-legacy-default`, and default dry-run. Run with `--force` after reviewing dry-run output. If new `default`-session orphans accumulate after this cleanup, then promote to a `task-start.sh` scanner. |
| E8 — add PreToolUse hook | high | SOFTEN (partial) | **DEFER → followup** | Devils-advocate flagged that `acquire_state_lock`'s drop-on-contention strategy works for PostToolUse async hooks but breaks Pre-hook semantics (a dropped lock = a missed intercept). The hook itself is sound, but it must be preceded by a poll-on-contention lock redesign. Tracked as task #14. Devils-advocate's second sub-clause — "spawn evaluator on every Stop" — is rejected outright (token-cost explosion, no demonstrated need). |
| E9 — disable `track-reads.sh` for a week | meta-reflection probe | SOFTEN | **FOLD INTO E1** | The harness-observations stream now produced by track-spawns (E1) is the empirical instrument that would tell us whether track-reads is load-bearing. Re-evaluate after one month of telemetry rather than running a blind disable. |
| E10 — superpowers as a whole still load-bearing in Opus 4.7 | meta-reflection root question | **HOLD** | **REJECT** | Devils-advocate evidence: `executing-plans/SKILL.md:142` HARD RULE + `lib/loop.sh:493-498` STUCK thresholds + `hooks/track-spawns.sh:41-42` counter resets form a three-layer cross-session contract that no single prompt can replicate. Load-bearing comes from cross-session discipline + multi-agent isolation, not from compensating for model weaknesses. Model upgrades do not invalidate it. |

Tally: **EXECUTE 3 (E1/E4/E6/E7 — narrowed/instrumented) + DEFER 3 (E5/E8/E9) + REJECT 3 (E2/E3/E10) = 10 items handled.**

## Anti-Add-Bias Note

This fix-all session added approximately:

- `scripts/cleanup-legacy-state.sh` — 1 new file (~140 lines, but the script is a one-shot utility, not in the hot path)
- `hooks/track-spawns.sh` — +25 lines (telemetry guard + emit, no new state)
- `skills/brainstorming/SKILL.md` — +8 lines (one bash block for the emit instruction)
- `skills/executing-plans/references/batch-execution-playbook.md` — +5 lines (concurrency cap doc)
- `superpowers/.reflection/` — 10 reflection reports + this merge doc

Net add is roughly +180 lines of code/docs across the harness; we did
NOT execute the proposed merges that would have netted code reductions
(E5 alone could have been -250 net, but the test-rewrite tail made it
negative-ROI today). The reflection process itself is therefore **still
add-biased** even after the counter-reflection — we acknowledged it
without fully escaping it. Next reflection cycle should weight a
concrete deletion as a first-class deliverable, not an optional outcome.

## Followups (open work this session does NOT close)

1. **Task #14 — PreToolUse hook** (E8). Needs `acquire_state_lock`
   redesigned from drop-on-contention to poll-on-contention first.
   Until then, the existing STUCK detection in `lib/loop.sh` runs at
   Stop-time, one turn late.
2. **E4 retire decision** — collect `sub_skill_loaded` rows for
   `build-like-iphone-team` for 6-8 weeks, then re-evaluate against
   actual trigger frequency rather than priors.
3. **E5 helper consolidation** — schedule for the next lib-touching
   refactor cycle; not a fix-now item.
4. **E1 + E9 follow-through** — after one month of harness-observations
   telemetry, run a real retrospective using the data to validate (or
   falsify) the reset-vs-compaction hypothesis.
5. **Methodology fix for the next reflection cycle** — start the
   generator (devils-advocate) and evaluator agents in parallel rather
   than sequentially, to remove the anchoring effect identified in the
   meta-reflection.

## Verification

- `python -m pytest tests/` — 203 passed, 25 subtests passed (no
  regressions from the track-spawns or scripts changes).
- `bash scripts/cleanup-legacy-state.sh --days 7 --include-legacy-default`
  — dry-run reports 739 candidate files globally (across 887 total),
  including all 9 legacy-default orphans.
- `bash scripts/cleanup-legacy-state.sh --days 30` — dry-run reports
  428 conservative candidates (active:true preserved without
  `--include-legacy-default`).
- `hooks/track-spawns.sh` smoke test — active+nonzero batch emits one
  rich row; idle batch (active:false) emits nothing. State counter
  reset still happens unconditionally.
- `lib/skill-events.sh` invocation pattern documented in
  `skills/brainstorming/SKILL.md:97` produces the expected envelope
  shape (smoke-tested in /tmp).
