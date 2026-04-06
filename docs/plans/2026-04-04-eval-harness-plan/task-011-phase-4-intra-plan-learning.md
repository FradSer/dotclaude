# Task 011: Implement executing-plans Phase 4 intra-plan learning

**depends-on**: task-010

## Description

Add intra-plan learning to executing-plans Phase 4 and batch-boundary context management. After the evaluator writes its report and before the user confirmation, the skill performs a pattern scan: reads all evaluation reports in the current evals directory, identifies checklist items that FAILed in 2+ distinct batches, and injects a "Recurring failures" context block into the next batch's sprint contract preamble. If a pattern persists across 3+ batches, it is elevated to a prominent position in the Phase 4 user confirmation prompt. Additionally, at each batch boundary, emit a structured handoff summary to reduce context pressure — per Anthropic's finding that context resets outperform context compaction for long-running tasks.

## Execution Context

**Task Number**: 011 of 013
**Phase**: Integration
**Prerequisites**: Phase 3f spawn context updated (task-010)

## BDD Scenario

```gherkin
Scenario: Recurring failure pattern detected across batches triggers context injection
  Given evaluation-round-1-batch-1.md shows SCEN-CONC-01 FAIL
  And evaluation-round-1-batch-2.md shows SCEN-CONC-01 FAIL
  When executing-plans performs the Phase 4 pattern scan
  Then a "Recurring Failure Patterns" table is injected into the next sprint contract preamble
  And the table lists SCEN-CONC-01 with batches 1 and 2
  And the generator note states: "tasks in this batch must address the above patterns proactively"

Scenario: Pattern persisting across 3+ batches elevates to prominent user notification
  Given SCEN-CONC-01 FAILed in batches 1, 2, and 3
  When executing-plans presents the Phase 4 evidence to the user
  Then the SCEN-CONC-01 pattern is the first item in the AskUserQuestion prompt
  And the prompt includes an explicit recommendation to pause and review the task specification
  And execution is not auto-blocked but the escalation is prominent

Scenario: Persistent unresolved pattern flagged as checklist evolution candidate
  Given SCEN-CONC-01 FAILed in batches 1, 2, and 3
  And the final batch evaluation still shows SCEN-CONC-01 FAIL or the pattern resolved only after 3+ rework rounds
  When the plan completes (all batches done)
  Then the plan summary includes a "Checklist Evolution Candidates" section
  And SCEN-CONC-01 is listed with batch count, resolution status, and root cause hypothesis
  And the section recommends manual checklist review targeting the identified pattern
```

**Spec Source**: `../2026-04-03-eval-harness-design/architecture.md` (Subsystem B: Intra-Plan Learning)

## Files to Modify/Create

- Modify: `superpowers/skills/executing-plans/SKILL.md` (Phase 4 section)

## Steps

### Step 1: Add pattern scan logic to Phase 4

After the evaluator writes its report and before the user confirmation AskUserQuestion, add:

1. Read all `evaluation-round-*-batch-*.md` files in the current `*-evals/` directory
2. Identify checklist items that FAILed in 2+ distinct batches within this plan
3. If patterns found: prepare context injection and pattern summary

### Step 2: Define context injection format

Add the "Recurring Failure Patterns" context block format to the skill:

```markdown
## Recurring Failure Patterns (from prior batches)

| Checklist Item | FAILed in batches | Issue seen |
|----------------|-------------------|------------|
| SCEN-CONC-01   | 1, 2              | Given clauses use vague placeholders |

Generator note: tasks in this batch must address the above patterns proactively.
```

This injection is additive -- it does not modify task acceptance criteria.

### Step 3: Add escalation for persistent patterns

If a pattern persists across 3+ batches for the same item:
- Elevate to the first item in the Phase 4 user confirmation AskUserQuestion
- Include explicit recommendation to pause execution and review the task specification
- Execution is not auto-blocked, but the prompt makes the escalation prominent

### Step 4: Add pattern summary to evidence block

Include a "Pattern detected" note in the Phase 4 evidence block presented to the user.

### Step 4b: Add checklist evolution candidate signal

When the plan completes (final batch done), perform a plan-level retrospective scan:

1. Identify checklist items that FAILed in 3+ batches OR required 3+ rework rounds before resolving
2. For each, record: item ID, batch count, resolution status (resolved/unresolved), root cause hypothesis
3. Emit a "Checklist Evolution Candidates" section in the plan completion summary:

```markdown
## Checklist Evolution Candidates

| Item ID | FAILed in batches | Resolved? | Root cause hypothesis |
|---------|-------------------|-----------|-----------------------|
| SCEN-CONC-01 | 1, 2, 3 | Yes (round 4) | Generator defaults to vague Given clauses for auth scenarios |

Recommendation: review `docs/retros/checklists/design-v1.md` for items above.
Consider whether the check method is too permissive (MODIFY) or a new item is needed (ADD).
```

This signal bridges the gap between intra-plan learning (immediate feedback) and checklist evolution (manual review). It does not auto-modify checklists -- it provides an explicit entry point for the human reviewer.

### Step 4c: Add variety gap detection

When all checklist items PASS for a batch but the batch required 2+ rework rounds before passing, note this in the batch handoff as a "potential checklist gap" -- the generator struggled with an issue the checklist did not catch on the first evaluation. This is informational only, surfaced in the plan completion summary alongside evolution candidates.

Format: `"Batch {N}: all items PASS after {M} rework rounds -- checklist may not cover the failure mode that caused initial rework"`

### Step 5: Add batch-boundary context management

Per Anthropic's finding that "context resets outperform context compaction" for long-running tasks, add a batch-boundary handoff mechanism to Phase 4:

1. **After each batch completes** (all tasks verified, before user confirmation), emit a structured "Batch Handoff" block summarizing:
   - Completed tasks in this batch (IDs, subjects, verdict)
   - Cumulative progress (N of M tasks complete)
   - Active failure patterns (from pattern scan above)
   - Files modified in this batch
   - Any outstanding rework items

2. **Lower the handoff summary threshold**: Current executing-plans only produces full handoff summaries for 16+ task plans every 3 batches. Change to: produce a lightweight batch handoff after every batch regardless of plan size. Full handoff summary (with file ownership, key decisions) remains at the existing threshold.

3. **Batch handoff format**:
```markdown
## Batch {N} Handoff

**Progress**: {completed}/{total} tasks complete
**This batch**: tasks {IDs} -- all PASS
**Recurring patterns**: {pattern list or "none detected"}
**Modified files**: {file list}
**Next batch**: tasks {IDs} -- {brief scope}
```

4. The batch handoff is written to the conversation context (not a file) to reduce the need for the model to retain full details of prior batches. It serves as a compressed checkpoint that the Superpower Loop's prompt injection can reference.

### Step 6: Verify Phase 4 changes

Confirm the pattern scan logic, context injection format, escalation rules, and batch handoff are in the skill.

## Verification Commands

```bash
# Pattern scan logic present
grep -c "Recurring Failure\|pattern scan\|intra-plan" superpowers/skills/executing-plans/SKILL.md | xargs test 0 -lt && echo "PASS: pattern scan"

# Context injection format present
grep -c "Generator note\|prior batches" superpowers/skills/executing-plans/SKILL.md | xargs test 0 -lt && echo "PASS: context injection"

# Escalation for 3+ batches
grep -c "3.*batch\|persist\|escalat" superpowers/skills/executing-plans/SKILL.md | xargs test 0 -lt && echo "PASS: escalation logic"
```

## Success Criteria

- Phase 4 reads all evaluation reports in current evals directory
- Identifies checklist items FAILing in 2+ distinct batches
- Injects "Recurring Failure Patterns" table into next sprint contract preamble
- Elevates patterns persisting 3+ batches to prominent user notification
- Context injection is additive (does not modify acceptance criteria)
- Pattern summary included in Phase 4 evidence block
- Batch handoff emitted after every batch (lightweight progress checkpoint)
- Full handoff summary threshold unchanged (16+ tasks, every 3 batches)
- Batch handoff serves as compressed context checkpoint for Superpower Loop continuations
- Plan completion summary includes "Checklist Evolution Candidates" section for items FAILing in 3+ batches or requiring 3+ rework rounds
- Evolution candidates provide explicit entry point for manual checklist review (does not auto-modify checklists)
- Variety gap detection: notes batches where all items PASS but required 2+ rework rounds (potential checklist blind spot)
