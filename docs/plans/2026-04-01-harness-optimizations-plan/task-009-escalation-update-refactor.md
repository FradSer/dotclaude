# Task 009: Update blocker-and-escalation with evaluator triggers

**depends-on**: task-004

## Description

Add evaluator-flagged rework as a new escalation trigger type in the blocker-and-escalation reference. When a task fails evaluation for 2 rounds, it should trigger escalation to the user alongside existing escalation triggers (repeated verification failure, missing dependency, unclear instruction).

## Execution Context

**Task Number**: 009 of 10
**Phase**: Integration (REQ-001, REQ-003)
**Prerequisites**: Task 004 (evaluator agent must be defined)

## BDD Scenario

```gherkin
Scenario: Evaluator rework after 2 rounds triggers escalation
  Given a task has been evaluated by the independent evaluator
  And the task has received REWORK or FAIL verdict in 2 consecutive rounds
  When the third evaluation round would begin
  Then escalation to the user is triggered instead
  And the escalation includes: evaluator scores from both rounds, rework items, and files reviewed
  And the user decides whether to accept as-is, provide guidance, or abort

Scenario: Evaluator escalation joins existing trigger types
  Given the blocker-and-escalation reference
  When the escalation triggers section is read
  Then "evaluator rework after 2 rounds" appears alongside existing triggers
  And it follows the same escalation format (trigger, evidence, user options)
```


## Files to Modify/Create

- Modify: `superpowers/skills/executing-plans/references/blocker-and-escalation.md`

## Steps

### Step 1: Read current blocker-and-escalation.md
- Understand the existing escalation trigger types and format

### Step 2: Add evaluator escalation trigger
- Add a new trigger type: "Evaluator rework after 2 rounds"
- Define the trigger condition: REWORK or FAIL verdict on same task/batch for 2 consecutive rounds
- Define the evidence to include: evaluation scores from both rounds, rework items, files reviewed, evaluation file paths
- Define user options: accept as-is, provide guidance for rework, abort task
- Follow the same format and style as existing triggers

### Step 3: Verify integration
- Confirm the new trigger fits the existing document structure
- Confirm it references evaluation report files for evidence

## Verification Commands

```bash
# File exists
test -f superpowers/skills/executing-plans/references/blocker-and-escalation.md && echo "PASS: file exists"

# Contains evaluator escalation trigger
grep -qi "evaluator" superpowers/skills/executing-plans/references/blocker-and-escalation.md && \
echo "PASS: evaluator trigger present"

# Contains 2-round escalation
grep -q "2" superpowers/skills/executing-plans/references/blocker-and-escalation.md && \
echo "PASS: round limit referenced"
```

## Success Criteria

- Evaluator rework escalation trigger added
- Trigger condition: 2 consecutive REWORK/FAIL rounds
- Evidence includes evaluation scores and rework items
- User options defined (accept, guide, abort)
- Consistent with existing escalation trigger format
