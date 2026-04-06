# Task 008: Update evaluator shared standards and output format

**depends-on**: task-005, task-006, task-007

## Description

Update the evaluator's shared standards section (Shared Standards, Verdict Rules, Output Format) to align with the binary checklist approach. Remove all references to 1-5 scoring, dimension tables, and configurable thresholds. Update verdict rules to binary: PASS if all checklist items PASS, REWORK if any item FAIL. Define the universal checklist results table format used by all three modes.

## Execution Context

**Task Number**: 008 of 013
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

Add new standard:
- **Check type awareness**: Each checklist item is annotated as `computational` (deterministic -- grep, exit code, graph walk) or `inferential` (requires evaluator judgment -- semantic mapping, architectural context). For inferential checks, the evaluator must anchor its judgment to the explicit check method in the item annotation and note when a result is borderline (e.g., "PASS -- borderline: scenario references the requirement implicitly via feature name, not by ID"). Borderline notes are informational and do not affect the PASS/FAIL result, but they surface for checklist evolution review.

### Step 3a: Add evaluator output responsibility protocol

Add a "Output Responsibility" subsection to Shared Standards that resolves the read-only vs file-write contradiction:

- The evaluator agent remains **read-only** — it does not have Write or Edit tools
- The evaluator produces report content as structured text in its response
- The **parent agent** (executing-plans, brainstorming, or writing-plans) is responsible for writing the evaluator's output to disk as the evaluation report file
- Sprint contracts follow the same protocol: evaluator outputs contract content, parent agent writes the file
- This separation ensures the evaluator cannot accidentally modify artifacts it is evaluating

Add to the evaluator definition:
```
**Output protocol**: This agent outputs report content as text. The spawning agent writes the content to the evaluation report file. This agent never writes files directly.
```

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

## Success Criteria

- Verdict rules use binary PASS/FAIL (not score thresholds)
- Output format defines Checklist Results table (Item ID, Check, Result, Evidence)
- No 1-5 scoring scale, dimension tables, or configurable thresholds
- Shared standards retain skeptical-by-default and read-only enforcement
- All three modes reference the same output format
- Output responsibility protocol: evaluator outputs text, parent agent writes files
- No Write/Edit tools in evaluator -- read-only enforcement preserved
- Check type awareness standard: evaluator anchors inferential checks to explicit check methods and notes borderline results
