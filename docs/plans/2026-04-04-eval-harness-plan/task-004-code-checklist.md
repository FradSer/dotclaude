# Task 004: Create initial code checklist

**depends-on**: task-001

## Description

Create `docs/retros/checklists/code-v1.md` containing binary PASS/FAIL checklist items for evaluating code artifacts produced during plan execution. The code checklist supplements verification command exit codes with prohibited pattern checks.

## Execution Context

**Task Number**: 004 of 013
**Phase**: Foundation
**Prerequisites**: docs/retros/checklists/ directory exists (task-001)

## BDD Scenario

```gherkin
Feature: Command Exit Code as the Sole Verdict Basis in Code Mode

  Background:
    Given docs/plans/2026-04-01-auth-evals/sprint-contract-batch-2.md lists tasks 003, 004, 005
    And the code checklist at docs/retros/checklists/code-v1.md is loaded

  Scenario: All verification commands pass and no prohibited patterns produce PASS verdict
    Given task 003 verification commands: "pnpm test auth.spec.ts" and "tsc --noEmit"
    And both commands exit with code 0
    And auth/handler.ts contains no TODO, FIXME, or stub patterns
    When the evaluator runs verification for task 003
    Then CODE-VER-01 result is PASS
    And the evidence block records: command, exit code 0, last 10 lines of output
    And task 003 verdict is PASS

  Scenario: TODO placeholder in produced file triggers CODE-QUAL-01 FAIL
    Given task 005 produced auth/handler.ts
    And auth/handler.ts line 28 contains "// TODO: implement rate limiting"
    And checklist item CODE-QUAL-01 prohibits TODO comments in produced files
    When the evaluator applies CODE-QUAL-01 to task 005 produced files
    Then CODE-QUAL-01 result is FAIL
    And evidence states: "auth/handler.ts:28 -- TODO comment present"
    And rework item states: "implement rate limiting at auth/handler.ts:28 or remove the placeholder"
```

**Spec Source**: `../2026-04-03-eval-harness-design/bdd-specs.md` (Feature: Command Exit Code -- Code Mode)

## Files to Modify/Create

- Create: `docs/retros/checklists/code-v1.md`

## Steps

### Step 1: Define checklist items

Create `code-v1.md` with these minimum items:

- **CODE-VER-01**: All verification commands from the task file exit with code 0
  - Check: run each verification command independently; record exit code
  - Evidence: command text, exit code, last 10 lines of output
  - `# Type: computational` -- exit code is deterministic ground truth
- **CODE-QUAL-01**: No TODO, FIXME, HACK, XXX, or stub patterns in produced files
  - Check: grep for prohibited patterns in all files created/modified by the task
  - Evidence: file:line -- pattern found
  - `# Type: computational` -- grep for exact strings produces deterministic result
- **CODE-QUAL-02**: No `NotImplementedError`, `pass` as sole function body, or `...` as implementation
  - Check: grep for stub implementation patterns
  - Evidence: file:line -- stub pattern found
  - `# Type: computational` -- grep for exact patterns produces deterministic result

### Step 2: Add file header and format

Include version, mode (code), creation date. Each item has ID, description, check method, evidence format.

### Step 3: Verify checklist content

Confirm items exist with grep-based check annotations.

## Verification Commands

```bash
# File exists
test -f docs/retros/checklists/code-v1.md && echo "PASS: code-v1.md exists"

# Contains required item IDs
grep -c "CODE-VER-01" docs/retros/checklists/code-v1.md && echo "PASS: CODE-VER-01 present"
grep -c "CODE-QUAL-01" docs/retros/checklists/code-v1.md && echo "PASS: CODE-QUAL-01 present"

# No scoring language
! grep -qi "score\|1-5\|rubric" docs/retros/checklists/code-v1.md && echo "PASS: no scoring language"
```

## Success Criteria

- `code-v1.md` exists with all 3+ checklist items
- Each item has ID, description, check method annotation, evidence format, and `# Type:` annotation
- All code checklist items are `# Type: computational` (exit codes, grep patterns)
- CODE-VER-01 specifies independent command execution (not trusting generator reports)
- CODE-QUAL-01 specifies concrete grep patterns for prohibited content
