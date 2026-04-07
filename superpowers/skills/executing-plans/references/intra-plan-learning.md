# Intra-Plan Learning Reference

Detailed formats for Phase 4 intra-plan learning features: pattern scan, batch handoff, and checklist evolution signals.

## Recurring Failure Patterns Format

Injected into the next batch's sprint contract preamble when checklist items FAIL in 2+ distinct batches:

```markdown
## Recurring Failure Patterns (from prior batches)

| Checklist Item | FAILed in batches | Issue seen |
|----------------|-------------------|------------|
| SCEN-CONC-01   | 1, 2              | Given clauses use vague placeholders |

Generator note: tasks in this batch must address the above patterns proactively.
```

This injection is additive -- it does not modify task acceptance criteria.

## Batch Handoff Format

Emitted to conversation context after each batch completes (not written to a file):

```markdown
## Batch {N} Handoff

**Progress**: {completed}/{total} tasks complete
**This batch**: tasks {IDs} -- all PASS
**Recurring patterns**: {pattern list or "none detected"}
**Modified files**: {file list}
**Next batch**: tasks {IDs} -- {brief scope}
```

The batch handoff serves as a compressed checkpoint that the Superpower Loop's prompt injection can reference, reducing the need to retain full details of prior batches.

## Checklist Evolution Candidates Format

Emitted in the plan completion summary when all batches are done:

```markdown
## Checklist Evolution Candidates

| Item ID | FAILed in batches | Resolved? | Root cause hypothesis |
|---------|-------------------|-----------|-----------------------|
| SCEN-CONC-01 | 1, 2, 3 | Yes (round 4) | Generator defaults to vague Given clauses |

Recommendation: review the relevant checklist file for items above.
Consider whether the check method needs tightening (MODIFY) or a new item is needed (ADD).
```

**Trigger criteria**: Checklist items that FAILed in 3+ batches OR required 3+ rework rounds before resolving.

**Variety gap detection**: If all checklist items PASS for a batch but the batch required 2+ rework rounds, note: `"Batch {N}: all items PASS after {M} rework rounds -- checklist may not cover the failure mode that caused initial rework"`

This signal feeds into the retrospective skill (`/superpowers:retrospective`) for cross-plan analysis and user-approved checklist evolution. It does not auto-modify checklists -- evolution requires explicit user approval via the retrospective flow.

## Escalation for Persistent Patterns

If a checklist item has FAILed in 3+ batches:
- Elevate to the first item in the Phase 4 user confirmation AskUserQuestion
- Include explicit recommendation to pause execution and review the task specification
- Execution is not auto-blocked, but the prompt makes the escalation prominent
