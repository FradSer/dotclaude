# Task 002: Create initial design checklist

**depends-on**: task-001

## Description

Create `docs/retros/checklists/design-v1.md` containing binary PASS/FAIL checklist items for evaluating design artifacts. Each item must pass the binary test: two independent evaluators given the same artifacts always produce the same PASS/FAIL result. Items must include executable check annotations (grep patterns or structural queries).

## Execution Context

**Task Number**: 002 of 013
**Phase**: Foundation
**Prerequisites**: docs/retros/checklists/ directory exists (task-001)

## BDD Scenario

```gherkin
Feature: Binary PASS/FAIL Checklist Evaluation for Design Artifacts

  Background:
    Given a design folder containing _index.md, bdd-specs.md, architecture.md, best-practices.md
    And the design checklist at docs/retros/checklists/design-v1.md is loaded from the spawn context path

  Scenario: All checklist items pass produces PASS verdict with no rework items
    Given all design artifacts satisfy every checklist item in design-v1.md
    When the evaluator applies the design checklist
    Then every row in the checklist results table shows PASS
    And the verdict is PASS
    And no rework items are produced
    And the report contains no numeric score fields

  Scenario: Vague Given clause triggers SCEN-CONC-01 FAIL with file and line evidence
    Given bdd-specs.md line 23 contains "Given some valid user data"
    And checklist item SCEN-CONC-01 requires all Given clauses to use specific data values
    When the evaluator applies SCEN-CONC-01
    Then SCEN-CONC-01 result is FAIL
    And the evidence field states: "bdd-specs.md:23 -- 'some valid user data' is a vague placeholder"
    And the rework item states: "bdd-specs.md line 23: replace 'some valid user data' with concrete field values"
    And the verdict is REWORK

  Scenario: Requirement with no mapped scenario triggers REQ-TRACE-01 FAIL
    Given _index.md Requirements section lists "REQ-005: Rate limiting on login attempts"
    And bdd-specs.md contains no scenario mentioning "rate limit" or "REQ-005"
    When the evaluator applies REQ-TRACE-01
    Then REQ-TRACE-01 result is FAIL
    And evidence states: "REQ-005 appears in _index.md but no scenario references it"

  Scenario: Inner-to-outer layer dependency described in architecture triggers ARCH-01 FAIL
    Given architecture.md line 47 states "domain service imports from ../../infra/database"
    And checklist item ARCH-01 requires no imports described from inner to outer layer
    When the evaluator applies ARCH-01
    Then ARCH-01 result is FAIL
    And evidence cites: "architecture.md:47 -- describes domain to infrastructure import"

  Scenario: Risk section with vague mitigations triggers RISK-02 FAIL
    Given _index.md contains risk entry "Risk: API downtime -- Mitigation: monitor closely"
    And checklist item RISK-02 requires each mitigation to be concrete
    When the evaluator applies RISK-02
    Then RISK-02 result is FAIL
    And evidence cites: "_index.md -- mitigation 'monitor closely' specifies no action"
```

**Spec Source**: `../2026-04-03-eval-harness-design/bdd-specs.md` (Feature: Binary Checklist Evaluation -- Design Mode)

## Files to Modify/Create

- Create: `docs/retros/checklists/design-v1.md`

## Steps

### Step 1: Define checklist items

Create `design-v1.md` with these minimum items derived from BDD scenarios.

Items:

- **SCEN-CONC-01**: All Given clauses use specific data values (no "some", "valid", "appropriate", "relevant")
  - Check: grep for vague placeholders in Given clauses of bdd-specs.md
  - Evidence format: file:line -- quoted text
  - `# Type: computational` -- grep pattern produces deterministic result
- **REQ-TRACE-01**: Every requirement ID in _index.md appears in at least one scenario in bdd-specs.md
  - Check: cross-reference requirement IDs between files
  - Evidence format: requirement ID + absence note
  - `# Type: inferential` -- "maps to" requires semantic understanding of whether a scenario covers a requirement
- **ARCH-01**: No imports or dependencies described from inner layer to outer layer
  - Check: scan architecture.md for dependency direction violations
  - Evidence format: file:line -- dependency description
  - `# Type: inferential` -- layer boundary identification requires architectural context understanding
- **RISK-02**: Each risk mitigation in _index.md specifies a concrete action
  - Check: scan risk/mitigation entries for vague verbs ("monitor", "handle", "manage")
  - Evidence format: file -- quoted mitigation text
  - `# Type: inferential` -- "concrete action" is a judgment call despite grep assistance

Each item must include an executable check annotation specifying the grep pattern or structural query. Each item must also include a `# Type: computational|inferential` annotation indicating whether the check produces a deterministic result (computational) or requires evaluator judgment (inferential). Inferential checks should minimize interpretive freedom by providing explicit grep patterns or structural queries as anchors.

### Step 2: Add file header and format

Include a header with version, mode, and creation date. Use a consistent checklist item format with ID, description, check method, and evidence format.

### Step 3: Verify checklist content

Confirm all required items exist and each has an executable check annotation.

## Verification Commands

```bash
# File exists
test -f docs/retros/checklists/design-v1.md && echo "PASS: design-v1.md exists"

# Contains required item IDs
grep -c "SCEN-CONC-01" docs/retros/checklists/design-v1.md && echo "PASS: SCEN-CONC-01 present"
grep -c "REQ-TRACE-01" docs/retros/checklists/design-v1.md && echo "PASS: REQ-TRACE-01 present"
grep -c "ARCH-01" docs/retros/checklists/design-v1.md && echo "PASS: ARCH-01 present"
grep -c "RISK-02" docs/retros/checklists/design-v1.md && echo "PASS: RISK-02 present"

# Contains no numeric scoring language
! grep -qi "score\|1-5\|rubric" docs/retros/checklists/design-v1.md && echo "PASS: no scoring language"
```

## Success Criteria

- `design-v1.md` exists with all 4+ checklist items
- Each item has ID, description, check method annotation, evidence format, and `# Type:` annotation
- Computational items have deterministic check methods (grep patterns, counts)
- Inferential items have explicit anchors that minimize interpretive freedom
- No numeric scoring or rubric language present
- File follows the binary test: two evaluators would produce the same result
