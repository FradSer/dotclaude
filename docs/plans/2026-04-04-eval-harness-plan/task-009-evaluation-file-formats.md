# Task 009: Update evaluation file formats to checklist format

**depends-on**: task-008

## Description

Update `evaluation-file-formats.md` to replace the scores-based evaluation report format with the binary checklist results format. The sprint contract format is unchanged. The evaluation report format must use Checklist Results table instead of Per-Task Scores table. Remove scoring scale legend, type-aware weighting table, and numeric score columns. Add the new evaluation report location convention (`*-evals/` directory).

## Execution Context

**Task Number**: 009 of 015
**Phase**: Integration
**Prerequisites**: Evaluator fully updated with checklist approach (task-008)

## BDD Scenario

```gherkin
Scenario: Evaluation report uses checklist format with no numeric scores
  Given the evaluator has completed evaluation of a batch
  When the evaluation report is written
  Then the report file uses the format defined in evaluation-file-formats.md
  And the report contains a "Checklist Results" section (not "Per-Task Scores")
  And columns are: Item ID, Check, Result, Evidence
  And no "score" column or numeric values (1-5) appear
  And the Rework Items table uses: Item ID, File, Location, Issue
  And the Verdict line states "PASS" or "REWORK" with count of FAIL items
```

**Spec Source**: `../2026-04-03-eval-harness-design/architecture.md` (Updated output format section)

## Files to Modify/Create

- Modify: `superpowers/skills/executing-plans/references/evaluation-file-formats.md`

## Steps

### Step 1: Update Evaluation Report format

Replace the Per-Task Scores table example with the Checklist Results format from the architecture:

```markdown
## Checklist Results

| Item ID       | Check                                   | Type          | Category   | Result | Evidence                                        |
|---------------|-----------------------------------------|---------------|------------|--------|-------------------------------------------------|
| REQ-TRACE-01  | All requirements map to >=1 scenario    | computational | regression | PASS   | 7/7 requirements traced                         |
| SCEN-CONC-01  | Given clauses use specific data         | computational | regression | FAIL   | bdd-specs.md:23 -- "some valid user data"       |
| RISK-02       | Mitigations specify concrete actions    | inferential   | capability | PASS   | 3 trials: PASS, PASS, FAIL -> majority PASS     |

## Rework Items

| Item ID      | File         | Location | Issue                                                                 |
|--------------|--------------|----------|-----------------------------------------------------------------------|
| SCEN-CONC-01 | bdd-specs.md | line 23  | [REGRESSION] Replace "some valid user data" with concrete values (email, password) |

## Verdict: REWORK
1 item FAIL (1 regression, 0 capability): SCEN-CONC-01
```

### Step 2: Remove scoring artifacts

Remove from the evaluation report section:
- Scoring Scale legend (1-5 definitions)
- Task Type Weighting table
- Per-Task Scores table with Correctness/Completeness/etc. columns
- Severity levels in Rework Items (replaced by checklist item reference)

### Step 3: Update evaluation report field definitions

Update the field definitions table:
- "Per-Task Scores" becomes "Checklist Results"
- "Rework Items" keeps its section but changes columns
- "Recommendations" section kept as-is
- "Pivot Flag" section kept as-is (code mode only)

### Step 4: Add evals directory convention

Add a note that evaluation artifacts are stored in `docs/plans/YYYY-MM-DD-{topic}-evals/` (derived from the plan path by replacing `-plan/` with `-evals/`).

### Step 5: Update sprint contract format

The sprint contract format remains largely unchanged. Ensure the Red-Green Pairs section references PASS/FAIL instead of score expectations.

### Step 6: Verify format consistency

Confirm the updated file contains no scoring language and matches the architecture specification.

## Verification Commands

```bash
# File contains checklist results format
grep -c "Checklist Results" superpowers/skills/executing-plans/references/evaluation-file-formats.md | xargs test 0 -lt && echo "PASS: checklist format"

# No Per-Task Scores table
! grep -i "Per-Task Scores" superpowers/skills/executing-plans/references/evaluation-file-formats.md && echo "PASS: no scores table"

# No scoring scale
! grep -i "Scoring Scale" superpowers/skills/executing-plans/references/evaluation-file-formats.md && echo "PASS: no scoring scale"

# Evals directory convention mentioned
grep -c "evals" superpowers/skills/executing-plans/references/evaluation-file-formats.md | xargs test 0 -lt && echo "PASS: evals directory"
```

## Success Criteria

- Evaluation report format uses Checklist Results table with Type and Category columns
- No Per-Task Scores table, scoring scale, or type-aware weighting
- Rework Items table uses Item ID, File, Location, Issue columns; regression FAILs prefixed with [REGRESSION]
- Verdict line format: "PASS" or "REWORK" with FAIL count and regression/capability distribution
- Inferential items show trial results in evidence (e.g., "3 trials: PASS, PASS, FAIL -> majority PASS")
- Sprint contract format includes "Evaluation Criteria Preview" section (feedforward from task-010)
- Evals directory convention documented
