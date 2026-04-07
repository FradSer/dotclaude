# Batch 2 Sprint Contract

## Tasks

| ID | Subject | Type |
|----|---------|------|
| 005 | Update evaluator design mode to binary checklist | impl |
| 006 | Update evaluator plan mode to binary checklist | impl |
| 007 | Update evaluator code mode to binary checklist | impl |

**Execution order:** Tasks 005, 006, 007 MUST execute serially (not in parallel). All three modify `superpowers/agents/superpowers-evaluator.md` in different sections. Concurrent edits to the same file are fragile and risk merge conflicts.

## Acceptance Criteria

### Task 005: Update evaluator design mode to binary checklist

**Target file:** `superpowers/agents/superpowers-evaluator.md` (Design Mode section)

- [ ] Step 2 "Read Design Rubrics" is removed and replaced with "Read design checklist from path in spawn context"
- [ ] Step 3 "Score Design Dimensions" (1-5 scale, 5-dimension table) is removed entirely
- [ ] Step 4 "Identify Issues" (score-below-5 gap documentation) is removed entirely
- [ ] New checklist execution step exists: for each checklist item, determine check method, execute check, record PASS/FAIL with evidence
- [ ] New rework production step exists: produce rework items from all FAIL results
- [ ] Verdict rule states: PASS if all items PASS; REWORK if any item FAIL
- [ ] Design mode output format specifies "Checklist Results" table with columns: Item ID, Check, Result, Evidence
- [ ] Design mode output format specifies "Rework Items" table with columns: Item ID, File, Location, Issue
- [ ] No "score" column, no score values (1-5 range), no "Per-Dimension Scores table" in design mode section
- [ ] No "rubric" references remain in design mode section
- [ ] Checklist path is read from spawn context (not hardcoded to a specific file path)
- [ ] Every FAIL result requires file:line evidence (stated in the instructions)
- [ ] Design mode Step 1 "Read Design Artifacts" remains unchanged
- [ ] Verification: `grep -c "checklist" superpowers/agents/superpowers-evaluator.md` returns >= 1
- [ ] Verification: design mode section contains no "rubric", "score.*dimension", or "1-5 scale" language
- [ ] Verification: `python3 plugin-optimizer/scripts/validate-plugin.py superpowers/ --check=frontmatter` exits 0

### Task 006: Update evaluator plan mode to binary checklist

**Target file:** `superpowers/agents/superpowers-evaluator.md` (Plan Mode section)

- [ ] Step 2 "Read Plan Rubrics" is removed and replaced with "Read plan checklist from path in spawn context"
- [ ] Step 3 "Score Plan Dimensions" (1-5 scale, 5-dimension table) is removed entirely
- [ ] Step 4 "Check Structural Integrity" as a separate section is removed (checks absorbed into checklist)
- [ ] New checklist execution step exists: for each checklist item, execute check method (dependency graph walk, task field presence, command syntax scan), record PASS/FAIL with evidence
- [ ] Checklist items cover cycle detection (DEP-01), ID resolution (DEP-02), unmapped scenario detection (PLAN-COV-01), and test task pairing (TEST-01)
- [ ] New rework production step exists: produce rework items from all FAIL results
- [ ] Verdict rule states: PASS if all items PASS; REWORK if any item FAIL
- [ ] Plan mode output format specifies "Checklist Results" table (same format as design mode)
- [ ] No "score" column, no score values (1-5 range), no "Per-Dimension Scores table" in plan mode section
- [ ] No "rubric" references remain in plan mode section
- [ ] No separate "Structural Integrity" section heading or standalone structural sweep exists
- [ ] Plan mode Step 1 "Read Plan Artifacts" remains unchanged
- [ ] Checklist path is read from spawn context (not hardcoded)
- [ ] Verification: `grep -c "checklist" superpowers/agents/superpowers-evaluator.md` returns >= 2 (design + plan modes)
- [ ] Verification: no "structural integrity" phrase remains in the file
- [ ] Verification: `python3 plugin-optimizer/scripts/validate-plugin.py superpowers/ --check=frontmatter` exits 0

### Task 007: Update evaluator code mode to binary checklist

**Target file:** `superpowers/agents/superpowers-evaluator.md` (Code Mode section)

- [ ] Step 4 "Score Against Rubrics" (5-dimension scoring, type-aware weighting table) is removed entirely
- [ ] New checklist execution step exists: read code checklist from spawn context, apply prohibited pattern checks against produced files
- [ ] Verification commands remain the primary verdict basis: exit code 0 = PASS, non-zero = REWORK
- [ ] Independent re-run is explicitly required: evaluator must re-run commands independently and must not trust generator-reported verification output
- [ ] When generator claims success but independent run fails, rework item explicitly notes the discrepancy
- [ ] Evidence block for verification records: command, exit code, last 10 lines of output (last 30 lines for failures)
- [ ] CODE-VER-01 (verification command check) and CODE-QUAL-01 (prohibited pattern check) are referenced or described
- [ ] Rework items reference command output, not subjective quality assessments
- [ ] Pivot flag logic updated: trigger is same task with REWORK verdict (same CODE-VER-01 FAIL, same error) in 2 consecutive rounds
- [ ] Pivot flag logic no longer uses score-based thresholds (no "dimensions <= 2 across rounds")
- [ ] Pivot rationale must reference the specific error pattern when set to true
- [ ] No 5-dimension scoring table (Correctness/Completeness/Code Quality/Test Coverage/Spec Compliance) in code mode section
- [ ] No "rubric" references remain in code mode section
- [ ] No type-aware weighting table remains in code mode section
- [ ] Code mode Step 1 "Read Sprint Contract", Step 2 "Read Produced Artifacts", and Step 3 "Run Verification Commands" remain functionally intact
- [ ] Verification: `grep -c "independent" superpowers/agents/superpowers-evaluator.md` returns >= 1
- [ ] Verification: no "Correctness.*Completeness.*Code Quality" combined phrase remains in the file
- [ ] Verification: `grep -c "pivot" superpowers/agents/superpowers-evaluator.md` returns >= 1
- [ ] Verification: `python3 plugin-optimizer/scripts/validate-plugin.py superpowers/ --check=frontmatter` exits 0

## Red-Green Pairs

None. All three tasks are impl tasks modifying the same markdown file (different sections). No test+impl pairs exist in this batch.

Tasks not part of a Red-Green pair have no Red state expectation.

## Sign-off

- **Evaluator:** superpowers-evaluator
- **Timestamp:** 2026-04-06T12:00:00Z
- **Status:** APPROVED
