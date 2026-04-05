# Task 005: Update evaluator design mode to binary checklist

**depends-on**: task-002

## Description

Replace the rubric-based scoring in the evaluator's design mode with binary checklist evaluation. The design mode must read a design checklist file (path from spawn context), apply each item as a binary check, and produce PASS/FAIL results with file:line evidence. Remove Steps 2-4 (Read Rubrics, Score Dimensions, Identify Issues) and replace with checklist execution steps.

## Execution Context

**Task Number**: 005 of 013
**Phase**: Core Features
**Prerequisites**: design-v1.md exists (task-002)

## BDD Scenario

```gherkin
Feature: Binary PASS/FAIL Checklist Evaluation for Design Artifacts
  As the superpowers-evaluator in design mode
  I want to apply binary PASS/FAIL checks against design artifacts
  So that evaluation results are concrete, actionable, and not subject to score drift

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
    And the rework item states: "bdd-specs.md line 23: replace 'some valid user data' with concrete field values (e.g., email='user@example.com', password='hunter2')"
    And the verdict is REWORK

  Scenario: Requirement with no mapped scenario triggers REQ-TRACE-01 FAIL
    Given _index.md Requirements section lists "REQ-005: Rate limiting on login attempts"
    And bdd-specs.md contains no scenario mentioning "rate limit" or "REQ-005"
    When the evaluator applies REQ-TRACE-01
    Then REQ-TRACE-01 result is FAIL
    And evidence states: "REQ-005 appears in _index.md but no scenario references it"
    And rework item directs: "add BDD scenario for REQ-005 rate limiting behavior"
    And no other checklist item fails because of this gap

  Scenario: Inner-to-outer layer dependency described in architecture triggers ARCH-01 FAIL
    Given architecture.md line 47 states "domain service imports from ../../infra/database"
    And checklist item ARCH-01 requires no imports described from inner to outer layer
    When the evaluator applies ARCH-01
    Then ARCH-01 result is FAIL
    And evidence cites: "architecture.md:47 -- describes domain to infrastructure import"
    And rework item states: "remove or invert the dependency described at architecture.md:47"

  Scenario: Risk section with vague mitigations triggers RISK-02 FAIL
    Given _index.md contains risk entry "Risk: API downtime -- Mitigation: monitor closely"
    And checklist item RISK-02 requires each mitigation to be concrete
    When the evaluator applies RISK-02
    Then RISK-02 result is FAIL
    And evidence cites: "_index.md -- mitigation 'monitor closely' specifies no action"
    And rework item directs: "replace 'monitor closely' with a concrete mitigation (e.g., circuit breaker with 30s timeout, fallback to cached data)"

  Scenario: Evaluator produces no numeric scores in any field
    Given any design artifact combination is evaluated
    When the evaluator produces the evaluation report
    Then the report contains no "score" column or score values (1-5 range)
    And every assessment is expressed as PASS or FAIL with a reason
    And the verdict line states "PASS" or "REWORK" with a count of FAIL items
```

**Spec Source**: `../2026-04-03-eval-harness-design/bdd-specs.md` (Feature: Binary Checklist Evaluation -- Design Mode)

## Files to Modify/Create

- Modify: `superpowers/agents/superpowers-evaluator.md` (Design Mode section, approximately lines 20-66)

## Steps

### Step 1: Replace design mode steps

Replace the current Steps 2-4 (Read Rubrics, Score Dimensions, Identify Issues) with checklist execution:

1. Read design artifacts (unchanged)
2. Read design checklist from path in spawn context
3. For each checklist item: determine check method, execute check, record PASS/FAIL with evidence
4. Produce rework items from all FAIL results
5. Verdict: PASS if all items PASS; REWORK if any item FAIL

### Step 2: Update design mode output

Replace the "Per-Dimension Scores table" with "Checklist Results" table format:
- Columns: Item ID, Check, Result, Evidence
- Rework Items table: Item ID, File, Location, Issue

### Step 3: Remove all scoring references in design mode

Remove 1-5 scale references, dimension scoring tables, and rubric file references from the design mode section.

### Step 4: Verify changes

Confirm the design mode section uses checklist terminology and no scoring language.

## Verification Commands

```bash
# Design mode section contains checklist references
grep -c "checklist" superpowers/agents/superpowers-evaluator.md | xargs test 1 -le && echo "PASS: checklist referenced"

# No rubric/score language in design mode section
! grep -i "rubric\|score.*dimension\|1-5 scale" superpowers/agents/superpowers-evaluator.md | grep -i "design mode" && echo "PASS: no scoring in design mode"

# Plugin validation
python3 plugin-optimizer/scripts/validate-plugin.py superpowers/ --check=frontmatter
```

## Success Criteria

- Design mode steps replaced with checklist execution process
- Output format uses Checklist Results table (Item ID, Check, Result, Evidence)
- No numeric scores, dimension tables, or rubric references in design mode
- Checklist path read from spawn context (not hardcoded)
- Evidence requirement: every FAIL includes file:line reference
