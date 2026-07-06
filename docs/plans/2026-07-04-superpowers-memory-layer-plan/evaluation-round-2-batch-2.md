# Evaluation Round 2 — Batch 2 (superpowers-memory-layer-plan)

**Scope verified:** Tasks 005–008 only, re-evaluating the round-1 CORRECTNESS-01 rework fix and its companion test gap. Sprint contract: `docs/plans/2026-07-04-superpowers-memory-layer-plan/sprint-contract-batch-2.md`. Batch 1 remains out of scope per `evaluation-round-1-batch-1.md`.

**Verification commands (run independently, fresh shell):**

| Command | Exit Code | Output |
|---|---|---|
| `bash superpowers/tests/run-docs-index-tests.sh` | 0 | 158 passed, 0 failed |
| `bash superpowers/tests/test-skill-touchpoints.sh` | 0 | 24 passed, 0 failed |

Regression math: round 1 ended at 156 passed. This round's fix added exactly 2 new assertions to the existing `test_collapse_groups_three_expired_memory_rows_by_category` (no new named tests). 158 − 156 = 2, exact match.

**Independent reproduction of CORRECTNESS-01 fix (reproduced directly against a scratch repo):**
1. **Stage-1-only fixture** (58 boilerplate design rows + 3 `expired`/`category=pitfall` memory rows): after `rebuild`, the 3 backing files remain at their original path; no `docs/memory/archive/` directory is created. Confirms the stage-1 fold no longer triggers archiving.
2. **Stage-2-drop fixture** (60 active design rows + 1 lone `expired` memory row): after `rebuild`, the file is moved to `docs/memory/archive/`. Confirms a genuine stage-2 drop still archives correctly.

The fix at `superpowers/lib/docs-index.sh:820-859` checks, for each `kind=memory`/`status=expired` row absent from `collapsed`, whether that row's own `(topic, cat)` synthetic summary row exists in `collapsed` before archiving — only archiving when it does not (genuine stage-2 drop). Field-exact tab-delimited match prevents partial-topic false positives; gated to `kind == memory` only, so non-memory rows are unaffected.

**Companion test gap resolved:** `test_collapse_groups_three_expired_memory_rows_by_category` now asserts `files_at_original == 3` and `files_archived == 0` after a stage-1-only collapse — a real, non-vacuous assertion (round 1's own reproduction proves a pre-fix implementation would have failed it).

## Checklist Results

| Task ID | Item ID | Result | Evidence |
|---|---|---|---|
| 005 | CODE-VER-01 | PASS | `run-docs-index-tests.sh` exit 0 (158/0) |
| 005 | CODE-QUAL-01 | PASS | 0 matches in added lines |
| 005 | CODE-QUAL-02 | PASS | 0 matches |
| 005 | CODE-ENV-ISO-01 | PASS (N/A) | Plain-bash test file, no subprocess construct |
| 005 | CODE-TEST-LIVE-01 | PASS | Anchor grep: 0 hits; real, non-vacuous assertions |
| 006 | CODE-VER-01 | PASS | Both verification commands exit 0 |
| 006 | CODE-QUAL-01 | PASS | 0 matches |
| 006 | CODE-QUAL-02 | PASS | 0 matches |
| 006 | CODE-ENV-ISO-01 | PASS (N/A) | Not a test file |
| 006 | CODE-TEST-LIVE-01 | N/A | Item scoped to test files |
| 007 | CODE-VER-01 | PASS | Both verification commands exit 0; all 5 task-007 tests pass including strengthened collapse test |
| 007 | CODE-QUAL-01 | PASS | 0 matches |
| 007 | CODE-QUAL-02 | PASS | 0 matches |
| 007 | CODE-ENV-ISO-01 | PASS (N/A) | No subprocess construct |
| 007 | CODE-TEST-LIVE-01 | PASS | Anchor grep: 0 hits; new filesystem assertions independently confirmed to have caught the round-1 defect |
| 008 | CODE-VER-01 | PASS | Both verification commands exit 0; non-memory collapse/drop behavior unchanged; `collapse_rows()` confirmed to remain a pure stdin→stdout filter |
| 008 | CODE-QUAL-01 | PASS | 0 matches |
| 008 | CODE-QUAL-02 | PASS | 0 matches |
| 008 | CODE-ENV-ISO-01 | PASS (N/A) | Not a test file |
| 008 | CODE-TEST-LIVE-01 | N/A | Item scoped to test files |
| 008 | CORRECTNESS-01 (carried from round 1) | PASS | Independently reproduced both fixtures: stage-1-folded rows are NOT archived; a genuinely stage-2-dropped row IS archived. Fix at `docs-index.sh:820-859` resolves the round-1 defect |

## Rework Items

| Item ID | File | Location | Issue |
|---|---|---|---|
| (none) | — | — | — |

(observation, non-blocking, carried from round 1: sprint contract's Task 007 "all 5 new tests FAIL" claim remains slightly inaccurate for `test_rebuild_does_not_archive_kept_rows`, which passes vacuously pre-task-008. Documentation-accuracy note only.)

## Pivot Flag

- **Pivot:** false
- **Rationale:** The round-1 correctness defect is resolved and independently reproduced/confirmed. Fix confined to `cmd_rebuild()`'s archive-diff logic plus a companion test-assertion strengthening; zero regressions (158/158, exact assertion-count match against round 1's 156).

## Run Metrics

| Metric | Value |
|---|---|
| Evaluator input tokens | N/A |
| Evaluator output tokens | N/A |
| Evaluation duration | N/A |
| Checklist version | code-v3 |

## Verdict: PASS
