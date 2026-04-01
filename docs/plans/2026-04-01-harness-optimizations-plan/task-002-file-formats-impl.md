# Task 002: Create evaluation file formats reference

**depends-on**: (none)

## Description

Create a Level 3 reference file that serves as the single source of truth for all evaluation-related file formats: sprint contract, evaluation report, and handoff summary. Both the evaluator agent prompt and the executing-plans skill will reference this file. This is the foundational artifact -- REQ-001, REQ-002, REQ-003, and REQ-004 all depend on these format definitions.

## Execution Context

**Task Number**: 002 of 10
**Phase**: Foundation (REQ-006)
**Prerequisites**: None

## BDD Scenario

```gherkin
Scenario: Sprint contract format defined with required sections
  Given the file evaluation-file-formats.md exists in executing-plans/references/
  When the sprint contract format section is read
  Then it defines a "Batch N Sprint Contract" heading
  And it includes a "Tasks" table with columns: ID, Subject, Type
  And it includes an "Acceptance Criteria" section with per-task testable checklist items
  And Red-Green pairs are annotated with expected state (Red = failing test, Green = passing test)
  And it includes a "Sign-off" section with evaluator timestamp

Scenario: Evaluation report format defined with structured scoring
  Given the file evaluation-file-formats.md exists in executing-plans/references/
  When the evaluation report format section is read
  Then it defines an "Evaluation Round N -- Batch M" heading
  And it includes a "Per-Task Scores" table with columns: Task ID, Correctness, Completeness, Code Quality, Test Coverage, Spec Compliance, Verdict
  And dimensions marked N/A per task type weighting are shown as "N/A"
  And it includes "Rework Items" with file path + line range, issue description, affected dimension, severity
  And it includes "Recommendations" for non-blocking observations
  And it includes "Pivot Flag" (true/false + rationale)

Scenario: Handoff summary format defined with structured data
  Given the file evaluation-file-formats.md exists in executing-plans/references/
  When the handoff summary format section is read
  Then it defines a "Handoff Summary N" heading
  And it includes "Completed Tasks" table: ID, Subject, Scores, Batch
  And it includes "Remaining Tasks" table: ID, Subject, Status, Dependencies
  And it includes "Key Decisions" list
  And it includes "File Ownership" table: File Path, Last Modified By Task
  And it includes "Blockers" list
```


## Files to Modify/Create

- Create: `superpowers/skills/executing-plans/references/evaluation-file-formats.md`

## Steps

### Step 1: Verify scenario alignment
- Read REQ-006 from requirements document (Section 1, REQ-006)
- Confirm the three format definitions match: Sprint Contract Format, Evaluation Report Format, Handoff Summary Format

### Step 2: Create evaluation-file-formats.md
- Create the reference file at the specified path
- Use imperative style consistent with existing references in `executing-plans/references/`
- Define each format with concrete section structures using markdown headings and tables
- Include the naming conventions: `sprint-contract-batch-{N}.md`, `evaluation-round-{N}-batch-{M}.md`, `handoff-summary-{N}.md`
- Document that files live in the plan directory alongside task files
- Document file lifecycle: written by evaluator, read by generator, NOT committed by default

### Step 3: Verify structure
- Confirm all three formats are defined
- Confirm rework items include file:line references
- Confirm Red-Green pair annotations in contract format

## Verification Commands

```bash
# File exists
test -f superpowers/skills/executing-plans/references/evaluation-file-formats.md && echo "PASS: file exists"

# Contains all three format sections
grep -q "Sprint Contract" superpowers/skills/executing-plans/references/evaluation-file-formats.md && \
grep -q "Evaluation Report" superpowers/skills/executing-plans/references/evaluation-file-formats.md && \
grep -q "Handoff Summary" superpowers/skills/executing-plans/references/evaluation-file-formats.md && \
echo "PASS: all formats defined"

# Contains naming conventions
grep -q "sprint-contract-batch" superpowers/skills/executing-plans/references/evaluation-file-formats.md && \
grep -q "evaluation-round" superpowers/skills/executing-plans/references/evaluation-file-formats.md && \
grep -q "handoff-summary" superpowers/skills/executing-plans/references/evaluation-file-formats.md && \
echo "PASS: naming conventions present"
```

## Success Criteria

- File created at correct path
- All three format definitions present with concrete section structures (tables and lists, not prose)
- Naming conventions documented
- File lifecycle documented (ephemeral by default, opt-in commit)
- Rework items specify file:line references and dimension scores
- Red-Green pair annotations included in contract format
