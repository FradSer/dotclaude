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

The batch handoff serves as a compressed checkpoint that the next batch coordinator can reference, reducing the need to retain full details of prior batches.

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

This signal feeds into the retrospective skill (`/superpowers:retrospective`) for cross-plan analysis and auto-applied checklist evolution. This skill does not modify checklists in-process — evolution happens only via the retrospective flow, where the post-commit `git show docs/retros/checklists/` diff is the user's audit surface.

## Escalation for Persistent Patterns

If a checklist item has FAILed in 3+ batches:
- Emit a prominent `PERSISTENT PATTERN` warning block at the top of the next batch handoff
- Include explicit recommendation to review the task specification during retrospective
- Execution continues autonomously — this skill does NOT prompt the user or pause
