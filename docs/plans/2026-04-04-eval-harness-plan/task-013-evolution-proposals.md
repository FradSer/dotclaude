# Task 013: Add evolution proposal and checklist update logic

**depends-on**: task-012

## Description

Add the evolution proposal generation, user approval flow, checklist version file creation, and evolution log appending logic to the retrospective skill. Each proposal is presented via AskUserQuestion with rationale and driving evidence. Approved proposals create a new checklist version file (never mutate existing versions). A pre-edit snapshot is written to the retrospective report before any file modification. Version counter increments once per retrospective run regardless of how many proposals are approved.

## Execution Context

**Task Number**: 013 of 015
**Phase**: Core Features
**Prerequisites**: Retrospective skill core exists (task-012)

## BDD Scenario

```gherkin
Feature: User-Gated Checklist Evolution with Version Tracking
  As the retrospective skill
  I want to present each evolution proposal for explicit user approval
  So that checklist changes are deliberately considered and auditable

  Background:
    Given retrospective skill has produced 2 evolution proposals
    And the current design checklist is docs/retros/checklists/design-v1.md

  Scenario: User approves ADD proposal -- new version file created and event logged
    Given proposal: ADD design/SCEN-CONC-03 "Error scenarios must name specific HTTP status codes"
    When the user approves the proposal
    Then docs/retros/checklists/design-v2.md is created with SCEN-CONC-03 appended
    And docs/retros/checklists/design-v1.md is preserved unchanged
    And an event is appended to evolution-log.jsonl:
      timestamp, event:"item_added", mode:"design", item_id:"SCEN-CONC-03", rationale, driving_plans
    And the retrospective report records "SCEN-CONC-03: APPROVED -- design-v2.md created"

  Scenario: User rejects REMOVE proposal -- checklist unchanged, rejection recorded
    Given proposal: REMOVE plan/PLAN-GRAN-01 "0 failures across 12 reports"
    When the user rejects the proposal
    Then plan-v1.md is unchanged
    And no evolution event is logged for PLAN-GRAN-01
    And the retrospective report records "PLAN-GRAN-01: REJECTED -- user declined removal"

  Scenario: Pre-edit snapshot written to report before any checklist file is modified
    Given any evolution proposal is about to be applied
    When the retrospective skill prepares to write the checklist update
    Then the current full content of the target checklist is written to the retrospective report under "pre-edit snapshot"
    And the snapshot precedes any file edit in the execution sequence
    And the retrospective report notes: "rollback: copy pre-edit snapshot content to design-v1.md"

  Scenario: Version counter increments once per retrospective run regardless of approval count
    Given 3 proposals are approved in a single retrospective run for design mode
    When all 3 are applied
    Then design-v2.md is created containing all 3 changes (not design-v4.md)
    And the evolution-log.jsonl records 3 item_added events each referencing design-v2.md
    And design-v1.md is preserved for audit purposes

  Scenario: Second retrospective run with prior evolution history proposes against new version
    Given design-v2.md exists with SCEN-CONC-03 added
    And a new retrospective run identifies SCEN-CONC-03 as a failure source in 2 more plans
    When retrospective skill runs
    Then the never-failing candidate analysis uses design-v2.md as the current checklist
    And SCEN-CONC-03 is not proposed for removal (it has failed, not passed in all reports)
    And any new proposals reference design-v2.md as the base for the next version
```

**Spec Source**: `../2026-04-03-eval-harness-design/bdd-specs.md` (Feature: Evolution Proposal Review)

## Files to Modify/Create

- Modify: `superpowers/skills/retrospective/SKILL.md` (add evolution sections)

## Steps

### Step 1: Add proposal generation logic

After the pattern analysis phase, formulate evolution proposals:

- **ADD**: failure source in 2+ distinct plans with no existing checklist item covering the pattern
- **REMOVE**: item with 0 failures across 10+ reports
- **MODIFY**: item producing false positives identifiable from rework analysis
- **PROMOTE**: capability item with pass rate improving across 3+ successive plans (>80% in latest plan) -- propose reclassifying to regression category
- Apply rate limit EVO-6: max 3 per mode per run; defer excess with evidence

### Step 2: Add user approval flow

For each proposal:
1. Present via AskUserQuestion with: proposal type, item ID, description, rationale, driving plan evidence
2. If approved: queue for checklist update
3. If rejected: record rejection in retrospective report; no file modification

### Step 3: Add pre-edit snapshot

Before any checklist file is modified:
1. Read current full content of the target checklist
2. Write the content to the retrospective report under "pre-edit snapshot"
3. Include rollback instructions

### Step 4: Add version file creation logic

Version management rules:
- Create new version file (e.g., `design-v2.md`) rather than mutating existing
- Version counter increments once per retrospective run (not per proposal)
- All approved proposals for a mode are applied to the same new version file
- Original version file preserved unchanged

### Step 5: Add evolution log appending

For each approved proposal, append a JSON object to `docs/retros/evolution-log.jsonl`:

```json
{"timestamp":"ISO-8601","event":"item_added","mode":"design","item_id":"SCEN-CONC-03","rationale":"...","driving_plans":["plan-1","plan-2"],"checklist_version":"design-v2.md"}
```

The file is append-only. Never remove or edit past entries.

### Step 6: Add report summary

End the retrospective report with: N proposals approved, M rejected, checklists updated to version X.

### Step 7: Verify evolution logic

Confirm proposal generation, approval flow, versioning, and logging are defined.

## Verification Commands

```bash
# Evolution proposal terms present
grep -c "ADD\|REMOVE\|MODIFY" superpowers/skills/retrospective/SKILL.md | xargs test 2 -le && echo "PASS: proposal types"

# AskUserQuestion approval flow
grep -c "AskUserQuestion\|approve\|reject" superpowers/skills/retrospective/SKILL.md | xargs test 0 -lt && echo "PASS: approval flow"

# Version file creation
grep -c "version.*file\|v{N}\|preserved\|unchanged" superpowers/skills/retrospective/SKILL.md | xargs test 0 -lt && echo "PASS: versioning"

# Evolution log
grep -c "evolution-log\|jsonl\|append" superpowers/skills/retrospective/SKILL.md | xargs test 0 -lt && echo "PASS: evolution log"

# Pre-edit snapshot
grep -c "snapshot\|pre-edit\|rollback" superpowers/skills/retrospective/SKILL.md | xargs test 0 -lt && echo "PASS: pre-edit snapshot"
```

## Success Criteria

- Proposal types defined: ADD, REMOVE, MODIFY, PROMOTE
- PROMOTE proposals reclassify capability items to regression when pass rate >80% across 3+ plans
- Each proposal presented via AskUserQuestion with evidence
- Approved proposals create new version file (never mutate existing)
- Version counter increments once per run (not per proposal)
- Pre-edit snapshot written to report before any file modification
- Evolution log is append-only JSONL with required fields
- Rejected proposals recorded in report with no file changes
