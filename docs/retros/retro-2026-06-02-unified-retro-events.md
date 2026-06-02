# Retrospective: Unified Retro Events & Harness-Evidence Channel

**Date**: 2026-06-02
**Plans analyzed**:
- `docs/plans/2026-04-04-eval-harness-plan/` (plan-v1, code-v1)
- `docs/plans/2026-05-09-harness-evidence-channel-design/` (design-v1 → design-v2)
- `docs/plans/2026-05-12-unified-retro-events-design/` (design-v2)
- `docs/plans/2026-05-12-unified-retro-events-plan/` (code-v1)

**Reports read**: 9 (4 code batches unified-retro, 1 code batch eval-harness, 3 design evaluations)

**Evolution history**: `docs/retros/evolution-log.jsonl` absent — first retrospective invocation on this project.

**Persistent memory priors** (Pre-Check B):
- `feedback_skill_no_user_asks` — skill must not ask for flow choices mid-execution (cited by Phase 5a)
- `feedback_skill_level_enforcement` — L2 SKILL.md must carry CRITICAL markers
- `feedback_skill_invocation_bypass` — slash command does not inject generic system message
- `project_v3_debt_tracker` — anti-add-bias regime active; JUST-01/vocabulary gates in effect
- `project_active_design_work` — eval harness v2 checklist work completed

---

## Pre-Check A: INSUFFICIENT-POST-PLAN Advisory

`docs/retros/plans-completed.jsonl` absent — skip silently (pre-v2.8.1 log).

However, the unified-retro-events plan has an identifiable completion commit (`069f16b`, 2026-05-13) and a rich post-plan diff window of **480h+** (20 days to this run). The post-plan-diff data below is fully populated.

---

## Phase 0: Checklist State

All three modes have v1+ checklists present:

| Mode | Latest version | Created | Items |
|------|---------------|---------|-------|
| code | code-v1.md | 2026-04-04 | 3 (CODE-VER-01, CODE-QUAL-01, CODE-QUAL-02) |
| plan | plan-v1.md | 2026-04-04 | 5 (PLAN-COV-01, TASK-COMP-03, DEP-01, DEP-02, TEST-01) |
| design | design-v2.md | 2026-05-10 | 10 (5 v1 + 5 v2 additions) |

Phase 0: all checklists present, skipping seed.

---

## Phase 1: Data Collection

### Evaluation Report Summary

| Plan | Report | Items Checked | FAILs | Rework Rounds |
|------|--------|--------------|-------|---------------|
| 2026-04-04-eval-harness-plan | round-1-batch-1 | 3 code items | 0 | 0 |
| 2026-05-12-unified-retro-events-plan | round-1-batch-1 | 3 code items | 0 | 0 |
| 2026-05-12-unified-retro-events-plan | round-1-batch-2 | 3 code items | 0 | 0 |
| 2026-05-12-unified-retro-events-plan | round-1-batch-3 | 3 code items | 0 | 0 |
| 2026-05-12-unified-retro-events-plan | round-1-batch-4 | 3 code items | 0 | 0 |
| 2026-05-09-harness-evidence-channel-design | design-round-1 (v1) | 5 design items | 0 | 0 |
| 2026-05-09-harness-evidence-channel-design | design-round-2 (v2) | 10 design items | 0 | 0 |
| 2026-05-12-unified-retro-events-design | design-round-1 (v2) | 10 design items | 0 | 0 |

**Total FAILs across all reports: 0.** Every checklist item passed first-round across all 9 reports.

### Post-Plan Diff (Phase 1 step 6)

Completion commit: `069f16b` (2026-05-13, "feat(sp): unify retro ndjson channels")

| Metric | Value |
|--------|-------|
| Window | ~480h (20 days) |
| Total commits | 9 |
| Feedback (refactor/fix/style/perf) | 3 |
| Evolution (feat/chore/docs/test) | 6 |

### Feedback-classified commits (user corrections to plan output)

| Commit | Type | Subject | Key Pattern |
|--------|------|---------|-------------|
| `18aedda` | refactor | complete v3.0.0 migration | **Architecture removal** — plan delivered into a Superpower Loop runtime that the user later tore down entirely (4,796 deletions). Plan had no awareness that the runtime was slated for removal. |
| `c3db9c0` | refactor | remove interactive approval gates | **Mid-stream prompt removal** — `AskUserQuestion` calls stripped from 5 SKILL.md files; replaced with autonomous execution + post-commit review. Aligns with `feedback_skill_no_user_asks` memory. |
| `7f8e8a0` | refactor | simplify phase 4 emission tests | **Test sandbox hygiene** — extracted constants, cached bash block via `lru_cache`, and critically: stripped parent `CLAUDE_*` environment variables to prevent shell state leaking into hermetic tests. |

### Minimum Data Check

- 9 evaluation reports available (sufficient for all proposal types)
- Code mode: 5 code reports (sufficient for ADD/REMOVE)
- Design mode: 3 design reports (sufficient for ADD/REMOVE)
- Plan mode: 1 plan report only (insufficient for ADD proposals; REMOVE requires 3+)

---

## Phase 2: Pattern Analysis

### 2.1 Failure Frequency

| Item ID | Mode | Plans with FAIL | Reports with FAIL |
|---------|------|----------------|-------------------|
| (none) | — | 0 | 0 |

**Zero FAILs across all 9 reports.** No item has ever failed.

### 2.2 Plateau Tasks

None. All tasks passed first-round with zero REWORK rounds across all batches.

### 2.3 Never-Failing Items (REMOVE candidates)

Items with 0 FAILs across all available reports:

| Item ID | Mode | Reports checked | Notes |
|---------|------|----------------|-------|
| CODE-VER-01 | code | 5 | PASS across all code batches. shellcheck consistently skipped (host dep) with substitute grep passing. |
| CODE-QUAL-01 | code | 5 | PASS across all code batches. Mid-flight fixes (Batch 1 `"stub reason"` rename) resolved before gate. |
| CODE-QUAL-02 | code | 5 | PASS across all code batches. Mid-flight fixes (Batch 1 `except OSError: pass`) resolved before gate. |
| JUST-01 | design | 3 | PASS — no design ever self-declared NOT-JUSTIFIED. |
| SCEN-CONC-01 | design | 3 | PASS — all Given clauses used concrete values. |
| REQ-TRACE-01 | design | 3 | PASS — all REQ IDs traced to BDD scenarios. |
| ARCH-01 | design | 3 | PASS — no inner-to-outer dependencies. |
| RISK-02 | design | 3 | PASS — all mitigations concrete. |
| PERF-01 | design | 2 | PASS — no synchronous LLM on hot paths. |
| DECOUPLE-01 | design | 2 | PASS — all env vars single-purpose. |
| AUDIT-RUN-01 | design | 2 | PASS — no retract triggers declared (vacuously satisfied). |
| N0-NFR-01 | design | 2 | PASS — no un-anchored numeric thresholds. |
| SCOPE-CREEP-01 | design | 2 | PASS — no bundled unrelated fixes. |
| PLAN-COV-01 | plan | 1 | PASS — insufficient data for REMOVE. |
| TASK-COMP-03 | plan | 1 | PASS — insufficient data for REMOVE. |
| DEP-01 | plan | 1 | PASS — insufficient data for REMOVE. |
| DEP-02 | plan | 1 | PASS — insufficient data for REMOVE. |
| TEST-01 | plan | 1 | PASS — insufficient data for REMOVE. |

**Code items meet the 3+ report REMOVE threshold. Design items meet the 3+ report REMOVE threshold (v1 items only; v2 items at 2 reports, below threshold).**

### 2.4 Variety Gaps (Phase 5a: Post-Plan Corrections)

Three `feedback`-classified commits surfaced patterns the batch evaluator could not catch:

1. **CODE-ENV-ISO-01 — Test sandbox leaks parent shell state** (`7f8e8a0`)
   - The evaluator's test harness ran with the developer's `CLAUDE_*` environment variables present
   - User refactored to strip all `CLAUDE_`-prefixed vars before test execution
   - No batch evaluator flagged this — tests passed despite the leak
   - Pattern: hermetic test isolation requires explicit environment sanitization

2. **CODE-ARCH-01 — Plan unaware of imminent architecture removal** (`18aedda`)
   - The unified-retro-events plan shipped helpers into a Superpower Loop runtime that was removed 14 days later (v3.0.0 migration: 4,796 deletions)
   - The plan's architecture.md described hook-chain ordering, `_loop_emit_block` integration, etc. — all deleted
   - This is a design/planning awareness gap, not a code quality gap — the code was correct at time of writing
   - Not suitable for a code-checklist item (would require predicting future architecture decisions)

3. **CODE-INTERACTIVE-01 — Mid-stream AskUserQuestion calls removed** (`c3db9c0`)
   - Five SKILL.md files had `AskUserQuestion` calls that the user later removed in favor of autonomous execution
   - Aligns with `feedback_skill_no_user_asks` memory prior — the user has consistently rejected interactive mid-stream prompts
   - The batch evaluator had no way to know this preference was load-bearing at evaluation time
   - Already captured in persistent memory — no checklist item needed

### 2.5 Analysis Summary

| Category | Findings |
|----------|----------|
| Failure frequency | Zero across all items and reports |
| Plateau tasks | None |
| Never-failing (REMOVE eligible) | 3 code items (5 reports), 5 design-v1 items (3 reports), 5 design-v2 items (2 reports — below threshold) |
| Variety gaps | 1 code pattern (env isolation), 1 design awareness (architecture removal), 1 preference (already in memory) |

---

## Phase 3: Evolution Proposals

### Proposal 1: ADD code/CODE-ENV-ISO-01

**Type**: ADD
**Target**: code-v2.md (new version)
**Item ID**: CODE-ENV-ISO-01

**Description**: Test files that invoke bash helpers via `subprocess` must explicitly strip parent shell environment variables (particularly `CLAUDE_*` prefixes) to prevent developer shell state from leaking into hermetic test sandboxes.

**Rationale**: Post-plan commit `7f8e8a0` ("simplify phase 4 emission tests") revealed that the batch-produced test suite ran with the developer's full `CLAUDE_*` environment present. The user refactored to add `env = {k: v for k, v in os.environ.items() if not k.startswith("CLAUDE_")}` before test execution. No batch evaluator flagged the leak — tests passed despite it. This is a genuine evaluator coverage gap: grep-based checks cannot detect environment variable leakage because the tests produce correct output either way. The pattern is concrete, reproducible, and specific to the helper-layer test style this project uses.

**Evidence**: `7f8e8a0` diff — `test_systematic_debugging_phase4_emission.py` lines adding `env = {k: v for k, v in os.environ.items() if not k.startswith("CLAUDE_")}` and `env["CLAUDE_PLUGIN_ROOT"] = str(SUPERPOWERS_DIR)`. No evaluator flagged the pre-refactor state.

**1-plan ADD override**: This is the Phase 5a post-plan-correction signal — concrete code diff evidence from a single plan, no batch evaluator flagged it. Graduates to ADD at 1-plan evidence per `post-plan-diff.md` §"1-plan ADD evidence override".

**Check method**:
```bash
# For each test file that imports subprocess and invokes bash helpers:
grep -l "subprocess" <produced-test-files> | while read -r f; do
  # Check if the file constructs an env dict for subprocess calls
  if grep -q "subprocess.*env=" "$f"; then
    # Verify it strips parent CLAUDE_ vars or constructs a fresh env
    grep -qE "CLAUDE_|environ\.items|environ\.copy" "$f" || echo "FAIL: $f uses subprocess with env= but no CLAUDE_ sanitization"
  else
    # subprocess without explicit env — inherits parent shell
    echo "FAIL: $f uses subprocess without explicit env parameter"
  fi
done
```

**Evidence format**: `{file} -- subprocess call without CLAUDE_ environment sanitization`

**Rework format**: "Add `env = {k: v for k, v in os.environ.items() if not k.startswith('CLAUDE_')}` before subprocess calls in {file}, then set only required vars (e.g., `CLAUDE_PLUGIN_ROOT`)."

---

### Proposal 2: REMOVE code/CODE-QUAL-01

**Type**: REMOVE
**Target**: code-v2.md (removing from current v1)
**Item ID**: CODE-QUAL-01

**Description**: No TODO/FIXME/HACK/XXX/STUB markers in produced files.

**Rationale**: 0 FAILs across 5 code evaluation reports (Batches 1-4 of unified-retro-events + Batch 1 of eval-harness-plan). The mid-flight fixes in Batch 1 (`"stub reason"` renamed to `"smoke reason"` before gate) were caught during authoring, not by the evaluation gate. Every subsequent batch preemptively avoided the pattern. The check is low-signal at evaluation time because: (a) Claude-authored code in this project consistently avoids these markers without being prompted, (b) the one near-miss was caught by the author before evaluation, (c) the pattern is better enforced at authoring time (by the model's own training) than at evaluation time.

**Counter-argument (self-rejection consideration)**: The check is cheap (one grep command), deterministic, and serves as a safety net. Removing it saves ~30 seconds per evaluation but eliminates a defense layer. The 3+ report REMOVE threshold is met (5 reports), but the item's cost is near-zero and its value as a regression guard is non-trivial even if it has never fired.

**Decision**: **Self-rejected.** The item's cost is negligible (one grep), its removal would contradict the "REMOVE is load-bearing" principle by removing a cheap safety net for zero benefit. The 0-FAIL record reflects good authoring discipline, not item redundancy. Keeping.

---

### Proposal 3: REMOVE design/DESIGN-AUDIT-RUN-01

**Type**: REMOVE
**Target**: design-v3.md (removing from current v2)
**Item ID**: AUDIT-RUN-01

**Rationale**: 0 FAILs across 2 design reports. Both designs passed vacuously — neither declared retract triggers, so the entry-point requirement never applied. The item adds evaluation overhead (evaluator must search for trigger declarations, then verify they have independent entry points) for a pattern that has never appeared in this project's designs.

**Decision**: **Self-rejected.** Only 2 reports available — below the 3+ report REMOVE threshold. The item was added specifically to prevent the circular-dependency failure mode documented in `design-v2.md` origin table. Removing it after 2 vacuous passes would be premature. Defer to a future retrospective when 3+ reports are available.

---

### Proposal 4: MODIFY design/DECOUPLE-01 (deferred)

**Type**: MODIFY
**Target**: design-v3.md
**Item ID**: DECOUPLE-01

**Rationale**: Both designs passed, but the `harness-evidence-channel` design's round-2 evaluation noted that `SUPERPOWERS_SUBSESSION` (umbrella) and `SUPERPOWERS_MERGE_SESSION` (per-purpose, legacy compat) coexist with documented roles. The v3.0.0 migration (commit `18aedda`) subsequently removed the Superpower Loop entirely, making both flags dead code. The checklist item should acknowledge that documented deprecation windows are acceptable even when the flags overlap.

**Decision**: **Deferred.** The v3.0.0 migration occurred after the evaluations — this is post-hoc context, not an evaluation false positive. No evaluator incorrectly flagged DECOUPLE-01; the designs were correct at evaluation time. A future retrospective with post-v3.0.0 designs may surface a genuine MODIFY need. Listed as a deferred proposal for the record.

---

### EVO-6 Rate Limit Check

| Mode | Proposals generated | Proposals applied | Deferred |
|------|--------------------|--------------------|---------|
| code | 1 (ADD) + 1 self-rejected (REMOVE) | 1 | 0 |
| design | 0 applied + 1 self-rejected (REMOVE) + 1 deferred (MODIFY) | 0 | 2 |
| plan | 0 (insufficient data) | 0 | 0 |

All modes under the 3-per-mode limit.

---

## Phase 4: Auto-Apply Proposals

### Pre-Edit Snapshot: code-v1.md

The full content of `docs/retros/checklists/code-v1.md` is preserved at its current location (unchanged). The new `code-v2.md` extends it with one new item.

**Rollback**: no rollback needed — `code-v1.md` is preserved as-is.

### Applied: ADD code/CODE-ENV-ISO-01

Writing `docs/retros/checklists/code-v2.md` with the new item appended.

### Evolution Log

Appending `item_added` event to `docs/retros/evolution-log.jsonl` via `lib/jsonl-emit.sh`.

---

## Phase 5: Harness Health

### 5a. Post-Plan Corrections Mined

| Pattern | Source commit | Graduated to proposal? |
|---------|--------------|----------------------|
| Test env isolation (CLAUDE_ leak) | `7f8e8a0` | **Yes** → CODE-ENV-ISO-01 |
| Architecture removal awareness | `18aedda` | No — design/planning gap, not code-checklist-applicable |
| Interactive prompt removal | `c3db9c0` | No — already captured in persistent memory (`feedback_skill_no_user_asks`) |

### 5b. Usage-Driven Recommendations

1. **All tasks pass first round across all 5 code reports** — zero REWORK rounds. Per-batch evaluation may be reducible for this project's code mode. The code checklist's 3 items (VER-01, QUAL-01, QUAL-02) are all passing without rework, suggesting the authoring quality is consistently high enough that evaluation is confirming rather than catching. A future retrospective with more plans may support converting code evaluation to spot-check cadence.

2. **All design-v1 items pass across 3 reports** — the 5 original design items (JUST-01, SCEN-CONC-01, REQ-TRACE-01, ARCH-01, RISK-02) have never failed. The 5 v2 additions (PERF-01, DECOUPLE-01, AUDIT-RUN-01, N0-NFR-01, SCOPE-CREEP-01) were added specifically because v1 missed concerns in the harness-evidence-channel design. The v2 additions have 2 reports each (both passing) — too early to assess their hit rate.

3. **Plan mode has only 1 report** — insufficient for any evolutionary signal. Plan checklist items remain unvalidated.

---

## Phase 6: Summary

| Metric | Value |
|--------|-------|
| Proposals approved | 1 (ADD CODE-ENV-ISO-01) |
| Proposals self-rejected | 2 (REMOVE CODE-QUAL-01, REMOVE AUDIT-RUN-01) |
| Proposals deferred | 1 (MODIFY DECOUPLE-01) |
| Checklists updated | code-v1.md → code-v2.md |
| Plans analyzed | 4 |
| Reports read | 9 |
| Post-plan feedback commits | 3 (of 9 total) |

### Key Findings

1. **Zero FAILs across 9 reports** — the checklists are either well-calibrated to this project's authoring quality, or the project's authoring quality consistently exceeds the checklist bar. Both are true.

2. **Post-plan diff is the only signal source** — with zero evaluation FAILs, the only actionable data came from user `refactor:` commits after plan completion. This validates the Phase 5a protocol's design intent: post-plan corrections catch what grep-based checks cannot (environment isolation, architecture awareness).

3. **ADD CODE-ENV-ISO-01 is the sole evolution** — a concrete, reproducible test-sandbox hygiene check that catches parent shell state leaking into subprocess-based tests. Low cost, high specificity, grounded in a real user correction.

4. **REMOVE is correctly suppressed** — despite 8 items meeting the never-failing criterion, both REMOVE proposals were self-rejected: one for negligible cost (CODE-QUAL-01), one for insufficient report count (AUDIT-RUN-01). The "counter monotonic growth" principle is working as designed — it scans for candidates but does not force removal when the cost/benefit doesn't support it.

---

## Pre-Edit Snapshot: code-v1.md

Full content preserved at `docs/retros/checklists/code-v1.md` (103 lines, 3 items). No modifications to v1 — `code-v2.md` extends with one new item.

**Rollback**: `code-v1.md` remains unchanged. If `code-v2.md` is unwanted, delete it and the evolution log entry.
