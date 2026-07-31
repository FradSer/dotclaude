# Post-Plan Diff Reference (v2.8.1)

The most direct measurement available of "what superpowers got wrong":
between plan completion and retrospective, users typically produce
`refactor:` / `fix:` / `style:` commits on plan-modified files. Those
commits directly indicate patterns the evaluator missed — the strongest
ADD-checklist signal available. Empirically demonstrated in the
user-simulation project (2026-05-08): the user produced 5 refactor
commits 12–13h after plan completion, each touching a pattern the
grep-based checks could not see; mining them produced the CODE-CONTRACT /
CONS / COV checklist additions.

This reference defines:

1. The decision matrix the Pre-Check applies before any phase runs
2. The Phase 1 step 6 data-collection contract
3. The Phase 5a recurring-pattern surfacing protocol (mine missed patterns into ADD proposals)

## Pre-Check — Decision Matrix

Run first. Read the most recent
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
> will likely miss the recurring-pattern ADD signal that surfaces as
> user `refactor:` commits 12–72h after completion. Proceeding anyway —
> the `retrospective_run` event will record
> `post_plan_diff.window_hours_at_run` so the next retrospective can
> flag this as a known weak-evidence run.

After surfacing the reminder, proceed to Phase 0 without pausing.
Record `post_plan_diff.window_hours_at_run: {hours_since_completion}` in
the Phase 6 `retrospective_run` event so future retrospectives can
weight this run's proposals as weak-evidence. If the plan is greenfield
with no expected follow-up (no `feedback`-classified commits ever
expected on these files), also record
`post_plan_diff.greenfield_no_followup: true` based on the file list
(e.g., one-off migration scripts) — emit this self-classification
without asking the user.

## Phase 1 step 6 — Data Collection Contract

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

Pass the classified list to Phase 5a (recurring-pattern surfacing).

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
