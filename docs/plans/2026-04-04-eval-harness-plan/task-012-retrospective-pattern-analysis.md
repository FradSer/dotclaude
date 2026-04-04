# Task 012: Create retrospective skill pattern analysis

**depends-on**: task-002, task-003, task-004

## Description

Create the retrospective skill as a new user-invocable command. The skill reads evaluation reports from multiple completed plans, computes per-item failure frequency across plans, identifies plateau tasks (REWORK across 2+ consecutive rounds), and identifies never-failing items. It enforces minimum data thresholds: ADD proposals require failures in 2+ distinct plans; REMOVE proposals require 10+ evaluation reports per item.

## Execution Context

**Task Number**: 012 of 015
**Phase**: Core Features
**Prerequisites**: All three checklists exist (tasks 002, 003, 004)

## BDD Scenario

```gherkin
Feature: Retrospective Analysis of Failure Patterns Across Plans
  As the retrospective skill
  I want to identify recurring checklist failures and never-failing items across plans
  So that the checklist evolves toward items that reliably detect real problems

  Background:
    Given retrospective skill is invoked with 3 plan directories
    And each plan has 3+ evaluation reports (design + plan + at least 1 code batch)

  Scenario: Item failing in 2+ plans generates ADD proposal for missing coverage
    Given SCEN-CONC-01 failed in plan-1 (tasks 002, 005) and plan-2 (task 007)
    And the failing evidence consistently shows vague HTTP error conditions in Given clauses
    And no checklist item currently targets HTTP status code specificity
    When retrospective skill aggregates failure patterns
    Then SCEN-CONC-01 appears in the failure frequency table with count 2 (2 distinct plans)
    And the analyzer proposes: ADD design/SCEN-CONC-03 "Error scenarios must name specific HTTP status codes"
    And the proposal rationale cites: "plan-1 tasks 002, 005 -- plan-2 task 007 -- all missing concrete status codes"

  Scenario: Item with 0 failures across 10+ reports generates REMOVE candidate proposal
    Given PLAN-GRAN-01 has PASS in 12 evaluation reports across 4 plans
    When retrospective skill aggregates the data
    Then PLAN-GRAN-01 appears in the never-failing items section with count 12
    And the analyzer proposes: REMOVE plan/PLAN-GRAN-01
    And the rationale states: "0 failures across 12 reports in 4 plans; check may not be detecting genuine issues"
    And the proposal notes: "user should confirm this pattern is no longer a real failure mode before removing"

  Scenario: Plateau task reveals gap in existing checklist coverage
    Given task-004 in plan-2 was REWORK in docs/plans/2026-04-01-auth-evals/evaluation-round-1-batch-2.md
    And task-004 was REWORK in docs/plans/2026-04-01-auth-evals/evaluation-round-2-batch-2.md
    And both rework items cite: "verification command is descriptive, not executable"
    And no checklist item currently checks for executable command syntax
    When retrospective skill identifies plateau tasks
    Then task-004 appears in the plateau task analysis with 2 consecutive REWORK rounds
    And root cause is stated: "verification command syntax not enforced by any checklist item"
    And the analyzer proposes: ADD plan/TASK-COMP-04 "Verification commands must begin with an executable binary name, not a description verb"

  Scenario: Retrospective with only 1 plan produces no ADD proposals
    Given only 1 plan directory is provided
    And it contains 3 evaluation reports
    When retrospective skill runs
    Then the retrospective report states: "ADD proposals require failures in 2+ distinct plans; only 1 plan provided"
    And no ADD evolution proposals are generated
    And the report recommends: "provide 2+ plan directories to enable ADD proposal analysis"

  Scenario: Retrospective with fewer than 10 reports per item produces no REMOVE proposals
    Given 2 plan directories are provided
    And the item with the most evaluation reports across both plans has fewer than 10 reports
    When retrospective skill runs
    Then the retrospective report states: "REMOVE proposals require 10+ evaluation reports per item; current maximum is N reports"
    And no REMOVE evolution proposals are generated
    And the report recommends: "run retrospective again after additional plan executions reach the 10-report threshold per item"

  Scenario: Retrospective enforces evolution rate limit per mode
    Given pattern analysis produces 5 valid ADD proposals for design mode
    When the retrospective report is finalized
    Then only 3 proposals are surfaced for design mode (rate limit: EVO-6)
    And the report notes: "2 proposals deferred -- rerun retrospective after applying current approvals"
    And the deferred proposals are listed with their evidence for future reference
```

**Spec Source**: `../2026-04-03-eval-harness-design/bdd-specs.md` (Feature: Retrospective Failure Pattern Analysis)

## Files to Modify/Create

- Create: `superpowers/skills/retrospective/SKILL.md`

## Steps

### Step 1: Create skill directory and SKILL.md

Create `superpowers/skills/retrospective/SKILL.md` with proper frontmatter:

```yaml
---
name: retrospective
description: This skill should be used when the user wants to analyze evaluation patterns across completed plans and evolve checklists. Triggered by "/superpowers:retrospective" with plan paths as arguments.
argument-hint: <plan-path-1> [plan-path-2] [--across-all]
user-invocable: true
allowed-tools: ["Read", "Glob", "Grep", "Write", "Edit", "AskUserQuestion"]
---
```

### Step 2: Define the core process

The skill body must include:

1. **Resolve evals folders**: For each plan path, derive `YYYY-MM-DD-{topic}-evals/` from `YYYY-MM-DD-{topic}-plan/`; abort if evals folder missing
2. **Read current checklists**: Scan `docs/retros/checklists/` for latest versions
3. **Read evaluation reports**: For each evals folder, read all `evaluation-round-{N}-batch-{M}.md` files
4. **Extract per-report data**: checklist item results (PASS/FAIL), rework items, pivot flags
5. **Aggregate across plans**:
   - Failure frequency per item (count of distinct plans where item FAILed)
   - Plateau tasks (REWORK across 2+ consecutive rounds in any plan)
   - Never-failing items (0 failures across 10+ reports)

### Step 3: Define threshold enforcement

- ADD proposals: require failures in 2+ distinct plans (1 plan = no proposals)
- REMOVE proposals: require 10+ evaluation reports per item (fewer = no proposals)
- Rate limit EVO-6: max 3 proposals per mode per retrospective run
- Deferred proposals listed with evidence for future reference

### Step 4: Define best practices document output

The skill writes `docs/retros/{topic}.md`:
- Topic derived from dominant failure pattern
- Includes: pattern description, evidence from plans, checklist items affected, actionable guidance

### Step 5: Verify skill structure

Confirm SKILL.md has proper frontmatter, process steps, and threshold rules.

## Verification Commands

```bash
# Skill file exists
test -f superpowers/skills/retrospective/SKILL.md && echo "PASS: SKILL.md exists"

# Frontmatter present
grep -c "name: retrospective" superpowers/skills/retrospective/SKILL.md | xargs test 0 -lt && echo "PASS: frontmatter"

# Core analysis terms present
grep -c "failure frequency\|plateau\|never-failing" superpowers/skills/retrospective/SKILL.md | xargs test 0 -lt && echo "PASS: analysis terms"

# Threshold enforcement
grep -c "2.*plan\|10.*report\|EVO-6\|rate limit" superpowers/skills/retrospective/SKILL.md | xargs test 0 -lt && echo "PASS: thresholds"
```

## Success Criteria

- `retrospective/SKILL.md` exists with valid frontmatter
- Evals folder resolution from plan path documented
- Failure frequency, plateau task, and never-failing item analysis defined
- ADD proposal threshold: 2+ distinct plans
- REMOVE proposal threshold: 10+ reports
- Rate limit: max 3 per mode (EVO-6)
- Best practices document output to `docs/retros/{topic}.md`
