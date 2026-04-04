# Task 008: Update evaluator shared standards and output format

**depends-on**: task-005, task-006, task-007

## Description

Update the evaluator's shared standards section (Shared Standards, Verdict Rules, Output Format) to align with the binary checklist approach. Remove all references to 1-5 scoring, dimension tables, and configurable thresholds. Update verdict rules to binary: PASS if all checklist items PASS, REWORK if any item FAIL. Define the universal checklist results table format used by all three modes.

## Execution Context

**Task Number**: 008 of 015
**Phase**: Core Features
**Prerequisites**: All three mode sections updated (tasks 005, 006, 007)

## BDD Scenario

```gherkin
Scenario: Evaluator produces no numeric scores in any field
  Given any design artifact combination is evaluated
  When the evaluator produces the evaluation report
  Then the report contains no "score" column or score values (1-5 range)
  And every assessment is expressed as PASS or FAIL with a reason
  And the verdict line states "PASS" or "REWORK" with a count of FAIL items
```

**Spec Source**: `../2026-04-03-eval-harness-design/bdd-specs.md` (Feature: Binary Checklist Evaluation -- Design Mode, Scenario 6)

## Files to Modify/Create

- Modify: `superpowers/agents/superpowers-evaluator.md` (Shared Standards, Verdict Rules, Output Format sections, approximately lines 206-234)

## Steps

### Step 1: Update Verdict Rules section

Replace the current verdict rules:
- Current: "PASS: All applicable dimensions >= 3 AND no dimension == 1" / "REWORK: Any applicable dimension < 3 OR any dimension == 1"
- New: "PASS: All checklist items show PASS" / "REWORK: Any checklist item shows FAIL"
- For code mode: pivot flag escalates to PIVOT (unchanged concept, new trigger)

### Step 2: Update Output Format section

Define the universal output format for all modes:

```markdown
## Checklist Results

| Item ID | Check | Result | Evidence |
|---------|-------|--------|----------|
| ... | ... | PASS/FAIL | ... |

## Rework Items

| Item ID | File | Location | Issue |
|---------|------|----------|-------|
| ... | ... | ... | ... |

## Verdict: PASS/REWORK
N items FAIL: [list of failing item IDs]
```

### Step 3: Update Shared Standards

Remove references to:
- "Evidence-based scoring" (replace with "Evidence-based assessment")
- Dimension scoring
- Score traceability
- Configurable thresholds

Keep references to:
- Skeptical by default
- Read-only enforcement
- Independent judgment
- Precision over speed
- Progressive disclosure

### Step 3b: Add multi-trial protocol for inferential checks

Add a "Check Execution Protocol" subsection to Shared Standards:

- **Computational checks** (check-type: computational): execute once, result is deterministic
- **Inferential checks** (check-type: inferential): execute 3 trials, majority result wins (2/3 PASS = PASS, 2/3 FAIL = FAIL)
- For inferential checks, the evaluator must read the item's calibration examples before each trial to anchor judgment
- Record trial-level results in evidence: "3 trials: PASS, FAIL, PASS -> majority PASS"
- If all 3 trials disagree (impossible with binary, but edge: 2 FAIL + 1 PASS with low confidence), note "borderline" in evidence

### Step 3c: Add category-aware verdict signaling

Add to verdict rules:
- **Regression items** (category: regression) that FAIL produce a stronger signal -- the rework item is prefixed with "[REGRESSION]" to indicate this was a previously-stable check
- **Capability items** (category: capability) that FAIL are expected during early adoption -- no special prefix
- Verdict remains binary (PASS/REWORK) regardless of category, but the evidence section notes the regression/capability distribution: "N regression FAIL, M capability FAIL"

### Step 3d: Add evaluator calibration protocol

Add a "Calibration" subsection:
- Before evaluating any inferential checklist item, the evaluator must read the item's calibration examples
- Calibration examples are embedded in the checklist file under each inferential item
- The evaluator must explicitly reference the calibration example when making a PASS/FAIL judgment on an inferential item
- Format: "Per calibration: [item matches PASS/FAIL example because...]"

### Step 4: Remove scoring scale and type-aware weighting

Remove the "Scoring Scale" legend (1-5 definitions) and "Task Type Weighting" table from the file.

### Step 5: Verify coherence

Read the entire evaluator file to confirm no scoring language remains anywhere.

## Verification Commands

```bash
# No scoring scale remains
! grep -i "1.*excellent\|2.*below\|3.*acceptable\|4.*good\|5.*excellent" superpowers/agents/superpowers-evaluator.md && echo "PASS: no scoring scale"

# No "score" in verdict rules
! grep -i "score" superpowers/agents/superpowers-evaluator.md | grep -iv "no.*score\|not.*score\|without.*score" | grep -c "." | xargs test 0 -eq && echo "PASS: no scoring references"

# Verdict uses PASS/REWORK terminology
grep -c "PASS.*REWORK\|REWORK.*PASS" superpowers/agents/superpowers-evaluator.md | xargs test 0 -lt && echo "PASS: verdict terms present"

# Plugin validation
python3 plugin-optimizer/scripts/validate-plugin.py superpowers/ --check=frontmatter
```

## Verification Commands

```bash
# Multi-trial protocol present
grep -c "inferential\|multi-trial\|3 trials\|majority" superpowers/agents/superpowers-evaluator.md | xargs test 0 -lt && echo "PASS: multi-trial protocol"

# Category-aware signaling present
grep -c "regression.*FAIL\|capability.*FAIL\|\[REGRESSION\]" superpowers/agents/superpowers-evaluator.md | xargs test 0 -lt && echo "PASS: category signaling"

# Calibration protocol present
grep -c "calibration" superpowers/agents/superpowers-evaluator.md | xargs test 0 -lt && echo "PASS: calibration protocol"
```

## Success Criteria

- Verdict rules use binary PASS/FAIL (not score thresholds)
- Output format defines Checklist Results table (Item ID, Check, Result, Evidence)
- No 1-5 scoring scale, dimension tables, or configurable thresholds
- Shared standards retain skeptical-by-default and read-only enforcement
- All three modes reference the same output format
- Multi-trial protocol defined for inferential checks (3 trials, majority wins)
- Category-aware verdict signaling: regression FAIL marked as [REGRESSION]
- Evaluator calibration protocol: must read and reference calibration examples for inferential items
