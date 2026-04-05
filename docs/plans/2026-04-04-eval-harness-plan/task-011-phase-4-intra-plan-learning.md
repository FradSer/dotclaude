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
