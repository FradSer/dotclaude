# Post-Plan Diff Reference (v2.8.1)

The most direct measurement available of "what superpowers got wrong":
between plan completion and retrospective, users typically produce
`refactor:` / `fix:` / `style:` commits on plan-modified files. Those
commits directly indicate patterns the evaluator missed. Without this
loop closed, retrospective makes systematically biased disable decisions
on defensive harness components — empirically demonstrated in the
user-simulation project (2026-05-08): plan completed 02:14, retrospective
ran 02:30, the user produced 5 refactor commits 12–13h later, and
`recurring_failure_patterns` was disabled based on blank-injection signal
alone.

This reference defines:

1. The decision matrix Pre-Check A applies before any phase runs
2. The Phase 1 step 8 data-collection contract
3. The Phase 5a recurring-pattern surfacing protocol
4. The Phase 5b veto gate (reinstates components that were
   removal-candidate by in-plan signal but load-bearing by post-plan signal)

## Pre-Check A — Decision Matrix

Run before Pre-Check B (LOW-YIELD self-test). Read the most recent
`plan_completed` event from `docs/retros/plans-completed.jsonl` (skip
silently if file or `completion_commit` field absent — pre-v2.8.1 logs).
Compute `hours_since_completion` and run a post-plan summary:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/lib/post-plan-diff.sh" summary "<completion_commit>" \
     <completion_modified_files...>
```

| `hours_since_completion` | post-plan `total` | Decision |
|---|---|---|
| < 24h | 0 | Output INSUFFICIENT-POST-PLAN reminder, then proceed |
| < 24h | ≥ 1 | Proceed; surface a brief warning |
| ≥ 24h | any | Proceed normally |

### INSUFFICIENT-POST-PLAN reminder (output verbatim)

> **RETROSPECTIVE INSUFFICIENT-POST-PLAN**: this plan completed
> {hours_since_completion}h ago with **zero** post-plan commits. The
> retrospective's blind spot in this window is the recurring-pattern
> signal — evaluator inline carve-outs and missed patterns surface as
> user `refactor:` commits typically 12–72h after completion. Running now
> will likely produce an over-aggressive disable test on a defensive
> harness component (e.g., `recurring_failure_patterns`) on weak evidence.
> Proceeding anyway — the `retrospective_run` event will record
> `post_plan_diff.window_hours_at_run` so the next retrospective can
> flag this as a known weak-evidence run.

After surfacing the reminder, proceed to Pre-Check B without pausing.
Record `post_plan_diff.window_hours_at_run: {hours_since_completion}` in
the Phase 6 `retrospective_run` event so future retrospectives can
weight this run's proposals as weak-evidence. If the plan is greenfield
with no expected follow-up (no `feedback`-classified commits ever
expected on these files), also record
`post_plan_diff.greenfield_no_followup: true` based on the file list
(e.g., one-off migration scripts) — emit this self-classification
without asking the user.

## Phase 1 step 8 — Data Collection Contract

For each plan with a `completion_commit` field, run:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/lib/post-plan-diff.sh" list <completion_commit> <files...>
```

Each commit auto-classified as one of:

- **`feedback`** — `refactor:` / `fix:` / `style:` / `perf:` (user
  correcting superpowers output — real signal)
- **`evolution`** — `feat:` / `chore:` / `docs:` / `build:` / `ci:` /
  `test:` / `revert:` (user adding new requirements — noise for
  retrospective)
- **`unknown`** — no conventional-commit prefix (LLM tiebreak optional)

Pass the classified list to Phase 5a (recurring-pattern surfacing) and
Phase 5b (defensive-component reinstate gate).

Skip silently when:

- `plan_completed` event lacks `completion_commit` (pre-v2.8.1 log)
- Plan completed < 24h ago (Pre-Check A already gated this)
- `git` not in PATH
- Repo no longer contains `completion_commit` (force-pushed / rebased)

## Phase 5a — Post-Plan Corrections Table

If `feedback`-classified commits ≥ 2 on plan-modified files, render in a
dedicated table grouped by file:

| Commit | Type | Subject | Files touched | Likely missed pattern |
|---|---|---|---|---|

For each `feedback` commit, **read the commit's diff** (`git show
<sha>`) and extract the corrected pattern as a one-line "Likely missed
pattern" — these are the strongest ADD-checklist candidates the evaluator
surface missed.

### 1-plan ADD evidence override

Cross-reference with batch evaluator reports: if no batch flagged the
pattern, the pattern is genuinely outside current checklist coverage and
**graduates to a Phase 3 ADD proposal even at 1-plan evidence** —
overrides the 2+ plan default. The evidence here is concrete code diff,
not statistical inference, so the threshold is relaxed.

## Phase 5b — Post-Plan Diff Veto Gate

Run BEFORE listing any candidate as a 5b removal candidate. For each
candidate component:

1. Look up Phase 5a results
2. If `feedback`-classified post-plan commits ≥ 2 on plan-modified files
   AND any "Likely missed pattern" maps to this component's defensive
   scope, **VETO the candidate**

A pattern "maps to this component's scope" when:

| Component | Scope match if missed pattern is... |
|---|---|
| `recurring_failure_patterns` | Same issue appears in 2+ files (recurrence is the definition) |
| `evaluator_per_batch` | A correctness or contract violation that exit-code-0 grep can't see |
| `sprint_contract_preview` | An item the user added to the contract themselves post-plan |
| `design_evaluator` | A design-level issue (architecture / boundary) the user re-cut |

### Veto note (Phase 6 closure writes this to the report and to evolution-log.jsonl as a `component_reinstated` event)

> Component `<id>` was a 5b removal candidate by in-plan signals
> (zero injections / catches across N batches), but post-plan diff shows
> {feedback_count} `refactor:`/`fix:` commits on plan files indicating
> the component's defensive scope was actually load-bearing — the
> in-plan zero-signal reflected evaluator coverage gap, not component
> redundancy. **Do NOT propose disable**; instead Phase 5a should
> propose ADD checklist items for the missed patterns so future runs let
> evaluator catch them.

This veto is the direct fix for the v2.7.0 systemic miscalibration.
Without it, calibration loop monotonically disables defensive components
on happy-path evidence until the next unhappy path arrives undefended.
