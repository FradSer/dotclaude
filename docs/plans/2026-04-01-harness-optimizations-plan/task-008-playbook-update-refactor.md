# Task 008: Update batch-execution-playbook with evaluation mode

**depends-on**: task-004

## Description

Add an "Evaluation Mode" section to the batch-execution-playbook reference documenting how to spawn the evaluator sub-agent after batch completion. This section provides the concrete invocation pattern that the executing-plans skill references during Phase 3.

## Execution Context

**Task Number**: 008 of 10
**Phase**: Integration (REQ-001)
**Prerequisites**: Task 004 (evaluator agent must be defined)

## BDD Scenario

```gherkin
Scenario: Evaluation Mode section documents evaluator invocation pattern
  Given the batch-execution-playbook.md reference
  When the "Evaluation Mode" section is read
  Then it documents how to spawn the evaluator as a sub-agent (not teammate) after batch completion
  And it shows the Agent tool invocation pattern with evaluator agent type
  And it specifies what context to pass: sprint contract path, artifact paths, plan directory
  And it documents how to read the evaluation report after evaluator completes

Scenario: Evaluation mode integrates with existing execution modes
  Given a batch using Parallel mode with Agent Teams
  When the batch completes and evaluation is enabled
  Then the evaluator is spawned AFTER the team completes -- not as a teammate
  And evaluation is independent of the execution mode used for the batch
```

**Spec Source**: `../2026-03-31-harness-optimizations-design/harness-optimizations-requirements.md` (REQ-001, Section 6 Integration Points)

## Files to Modify/Create

- Modify: `superpowers/skills/executing-plans/references/batch-execution-playbook.md`

## Steps

### Step 1: Read current batch-execution-playbook.md
- Understand the existing structure (Steps 1-5, execution modes, verification gate)

### Step 2: Add "Evaluation Mode" section
- Add after the "Verification Gate" section (natural placement after verification)
- Document:
  - Evaluator is a sub-agent, spawned via Agent tool after batch verification
  - Not a teammate -- preserves independence regardless of execution mode
  - Context to pass: sprint contract file path, list of modified files, plan directory path
  - How to read evaluation report after evaluator completes
  - Rework loop: if verdict is REWORK/FAIL, re-execute affected tasks and re-evaluate (max 2 rounds)
- Keep the section concise -- reference `evaluation-file-formats.md` and `evaluation-rubrics.md` for details

### Step 3: Verify integration
- Confirm the new section fits naturally in the existing document flow
- Confirm it references the evaluator agent by path (`superpowers/agents/evaluator.md`)
- Confirm it does not contradict existing execution mode documentation

## Verification Commands

```bash
# File exists
test -f superpowers/skills/executing-plans/references/batch-execution-playbook.md && echo "PASS: file exists"

# Contains evaluation mode section
grep -qi "evaluation mode" superpowers/skills/executing-plans/references/batch-execution-playbook.md && \
echo "PASS: evaluation mode section present"

# Contains sub-agent invocation pattern
grep -q "sub-agent" superpowers/skills/executing-plans/references/batch-execution-playbook.md && \
echo "PASS: sub-agent pattern documented"

# References evaluator agent
grep -q "evaluator" superpowers/skills/executing-plans/references/batch-execution-playbook.md && \
echo "PASS: evaluator referenced"
```

## Success Criteria

- "Evaluation Mode" section added to batch-execution-playbook.md
- Evaluator invocation pattern documented (sub-agent, not teammate)
- Context passing documented (contract path, artifacts, plan directory)
- Rework loop documented (max 2 rounds)
- Integrates naturally without contradicting existing content
