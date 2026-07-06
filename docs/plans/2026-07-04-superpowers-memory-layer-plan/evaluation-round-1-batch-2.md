# Evaluation Round 1 — Batch 2 (superpowers-memory-layer-plan)

**Scope verified:** Tasks 005–008 only (`docs-index.sh` memory scan/rebuild, collapse grouping by category, archive-on-drop). Sprint contract: `docs/plans/2026-07-04-superpowers-memory-layer-plan/sprint-contract-batch-2.md`. Batch 1 (tasks 001–004, kind vocabulary + status restriction/`--category`) is out of scope per `evaluation-round-1-batch-1.md` (already PASSed) and was not re-reviewed.

**Verification commands (run independently, fresh shell):**

| Command | Exit Code | Output |
|---|---|---|
| `bash superpowers/tests/run-docs-index-tests.sh` | 0 | 156 passed, 0 failed |
| `bash superpowers/tests/test-skill-touchpoints.sh` | 0 | 24 passed, 0 failed |

Regression math: batch 1 ended at 130 passed. Batch 2 adds task-005 (4 tests / 11 assertions) + task-007 (5 tests / 15 assertions) = 26 new assertions. 156 − 130 = 26, exact match — zero double-counting, zero silent regressions.

**Independent RED-state reconstruction** (files copied to scratch, hunks reverted, suite re-run against the reconstructed pre-impl state):
- Pre-task-006: all 4 task-005 tests fail for the documented reason.
- Pre-task-008: 4 of the 5 task-007 tests fail for the documented reason. `test_rebuild_does_not_archive_kept_rows` passes vacuously at this checkpoint (no archive mechanism yet exists to over-fire) — a minor, non-blocking RED-state accuracy gap, noted but not driving the verdict.

**Task-006 manual acceptance check** (independently reproduced): seeding `docs/memory/pitfall_x.md` with `summary: hello world` and running `rebuild` produces a row reading `hello world` — matches the stated manual check exactly.

**Correctness defect found via direct behavioral verification (not caught by the produced test suite):** reproducing the exact fixture from `test_collapse_groups_three_expired_memory_rows_by_category` (58 boilerplate rows + 3 `expired` `category=pitfall` memory rows, 61 total) and inspecting the filesystem after `rebuild` shows all 3 backing memory files get moved into `docs/memory/archive/` even though they were merely **stage-1 collapsed into one summary line**, not stage-2 dropped. `superpowers/lib/docs-index.sh:814-841`'s archive pass treats "any path present in `merged` but absent from `collapsed`" as archive-eligible — but stage-1 grouping also removes a row's individual path from `collapsed` (replaced by the synthetic summary row), which the design's own `bdd-specs.md` does not intend: Scenario 17 (stage-1 grouping) makes no mention of archiving; Scenario 15 scopes archiving specifically to the stage-2 drop rule. The flaw originated in task-008's spec (which specifies the same over-broad diff condition) and was faithfully implemented. None of task 007's 5 new tests assert on filesystem state for the 3-row-collapse scenario, so this defect went undetected by the batch's own verification commands.

## Checklist Results

| Task ID | Item ID | Result | Evidence |
|---|---|---|---|
| 005 | CODE-VER-01 | PASS | `run-docs-index-tests.sh` exit 0 (156/0); RED reconstruction confirms all 4 task-005 tests fail pre-task-006 for the documented reason |
| 005 | CODE-QUAL-01 | PASS | Added-lines grep for `TODO\|FIXME\|HACK\|XXX\|STUB\|stub\b`: 0 matches |
| 005 | CODE-QUAL-02 | PASS | Added-lines grep for `NotImplementedError`, lone-`pass`, lone-`...`: 0 matches |
| 005 | CODE-ENV-ISO-01 | PASS (N/A) | Plain-bash test file, no child-process construct in scope |
| 005 | CODE-TEST-LIVE-01 | PASS | Anchor grep: 0 hits; all 4 test bodies contain real assertions |
| 006 | CODE-VER-01 | PASS | Both verification commands exit 0; manual acceptance check independently reproduced |
| 006 | CODE-QUAL-01 | PASS | 0 matches |
| 006 | CODE-QUAL-02 | PASS | 0 matches; `scan_folders()` loop and `cmd_rebuild()` summary-fallback are full implementations |
| 006 | CODE-ENV-ISO-01 | PASS (N/A) | Not a test file |
| 006 | CODE-TEST-LIVE-01 | N/A | Item scoped to test files; task 006 produces no test file |
| 007 | CODE-VER-01 | PASS | Both verification commands exit 0; RED reconstruction confirms 4/5 tests fail pre-task-008 for the documented reason (1 test passes vacuously at that checkpoint, non-blocking) |
| 007 | CODE-QUAL-01 | PASS | 0 matches |
| 007 | CODE-QUAL-02 | PASS | 0 matches |
| 007 | CODE-ENV-ISO-01 | PASS (N/A) | No subprocess construct |
| 007 | CODE-TEST-LIVE-01 | PASS | Anchor grep: 0 hits; all 5 new test bodies inspected — real assertions |
| 008 | CODE-VER-01 | PASS | Both verification commands exit 0; all 5 task-007 tests pass; non-memory collapse/drop behavior confirmed byte-for-byte unchanged; `collapse_rows()` confirmed to remain a pure stdin→stdout filter |
| 008 | CODE-QUAL-01 | PASS | 0 matches |
| 008 | CODE-QUAL-02 | PASS | 0 matches |
| 008 | CODE-ENV-ISO-01 | PASS (N/A) | Not a test file |
| 008 | CODE-TEST-LIVE-01 | N/A | Item scoped to test files; task 008 produces no test file |
| 008 | CORRECTNESS-01 (custom, surfaced per evidence-based/no-suppression standard) | FAIL | `superpowers/lib/docs-index.sh:814-841` archives any `kind=memory`/`status=expired` row absent from `collapsed`, which includes rows merely stage-1-collapsed into a summary line, not just stage-2-dropped rows. Reproduced directly: 58 design + 3 expired `pitfall` memory rows → after `rebuild`, all 3 backing files moved into `docs/memory/archive/` even though `docs/README.md` still shows the aggregate summary row. Contradicts `bdd-specs.md` Scenario 17 (stage-1 grouping, no archiving mentioned) vs. Scenario 15 (archiving scoped to the stage-2 "second-line-defense drop" rule) |

## Rework Items

| Item ID | File | Location | Issue |
|---|---|---|---|
| CORRECTNESS-01 | `superpowers/lib/docs-index.sh` | lines 814-841 (`cmd_rebuild()` archive-on-drop pass) | The archive pass conflates "row absent from `collapsed`" with "row dropped by stage 2." A row can also be absent from `collapsed` because it was folded into a stage-1 group summary, which per `bdd-specs.md` Scenario 17 must NOT trigger archiving — only Scenario 15's stage-2 "drop entirely" rule should. Fix: distinguish the two cases in `cmd_rebuild()` (recompute which paths were absorbed into a stage-1 summary group — those whose `(topic, cat)` key reached the >=3 threshold — and exclude them from the archive-diff set; only archive paths whose absence is due to the stage-2 drop, not stage-1 grouping). Companion gap: `run-docs-index-tests.sh`'s `test_collapse_groups_three_expired_memory_rows_by_category` (task 007) never asserts on `docs/memory/` filesystem state — add an assertion there (or a new test) that stage-1-collapsed memory files remain at their original path, not in `archive/`. |
| (observation, non-blocking) | `docs/plans/2026-07-04-superpowers-memory-layer-plan/sprint-contract-batch-2.md` | Task 007 acceptance criteria | "Running the suite shows all 5 new tests FAIL for the documented reason" is not fully accurate: `test_rebuild_does_not_archive_kept_rows` passes vacuously pre-task-008 (no archive mechanism yet exists to over-fire). Documentation-accuracy note only, not a functional defect — does not block the verdict. |

## Pivot Flag

- **Pivot:** false
- **Rationale:** The correctness defect (CORRECTNESS-01) is confined to files already in this batch and to a single task's archive-diff logic; it does not require cancelling or re-scoping tasks 009-018, does not repeat a same-item-same-error pattern across rounds (round 1), and traces to one specific over-broad diff condition. A targeted fix within task 008's scope (plus a companion assertion in task 007) resolves it.

## Run Metrics

| Metric | Value |
|---|---|
| Evaluator input tokens | N/A |
| Evaluator output tokens | N/A |
| Evaluation duration | N/A |
| Checklist version | code-v3 |

## Verdict: REWORK
1 item FAIL: CORRECTNESS-01 (all 5 formal code-v3 items PASS across all 4 tasks; the FAIL is a correctness defect surfaced by direct behavioral verification beyond the 5 named checklist items, per the no-suppression evidence-based standard)
