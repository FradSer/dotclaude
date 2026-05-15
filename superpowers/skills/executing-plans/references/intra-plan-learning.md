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

This signal feeds into the retrospective skill (`/superpowers:retrospective`) for cross-plan analysis and auto-applied checklist evolution. This skill does not modify checklists in-process — evolution happens only via the retrospective flow, where the post-commit `git show docs/retros/checklists/` diff is the user's audit surface.

## Escalation for Persistent Patterns

If a checklist item has FAILed in 3+ batches:
- Emit a prominent `PERSISTENT PATTERN` warning block at the top of the next batch handoff
- Include explicit recommendation to review the task specification during retrospective
- Execution continues autonomously — this skill does NOT prompt the user or pause

## Harness Observations Log Schema

Write to: `docs/retros/harness-observations.jsonl` (one JSON object per line, append-only). Populated by the consuming skill (executing-plans Phase 3 / Phase 4) when a harness component listed in `docs/retros/harness-config.json` is honored.

See `../../retrospective/references/harness-config.md` for the disable protocol that produces these observations.

```json
{
  "event": "harness_observation",
  "timestamp": "2026-04-24T12:34:56Z",
  "component": "evaluator_per_batch",
  "retrospective_id": "docs/retros/retro-2026-04-24-evaluator-cost.md",
  "plan": "docs/plans/2026-04-24-auth-plan/",
  "batch": 2,
  "task_count_in_batch": 4,
  "rework_rounds_observed": 0,
  "persistent_patterns_detected": [],
  "notes": "Batch passed verification gate on first attempt; evaluator spawn skipped per harness-config"
}
```

### Field semantics

| Field | Type | Notes |
|-------|------|-------|
| `event` | string | Always `"harness_observation"`. |
| `timestamp` | ISO 8601 | When the observation was recorded. |
| `component` | string | Matches the component in harness-config.json. |
| `retrospective_id` | path | The retrospective that authorized the disable. |
| `plan` | path | The plan under execution. |
| `batch` | integer | Batch index within the plan (1-based). |
| `task_count_in_batch` | integer | Tasks executed in this batch. |
| `rework_rounds_observed` | integer | Verification-gate reruns inside the batch (not evaluator rounds, since evaluator may be disabled). |
| `persistent_patterns_detected` | array | `PERSISTENT PATTERN` item IDs raised for this batch (may be empty). |
| `notes` | string | One-sentence human-readable summary. Used by the next retrospective when judging promotion vs. reinstate. |

Plans that execute without any disabled component MUST NOT write to this file.

### Reader contract (retrospective Phase 1 step 6)

The next retrospective aggregates observations by `component + retrospective_id`, then in Phase 5 uses the aggregate to decide:

- **Promote (permanent remove)**: `persistent_patterns_detected` empty across ≥3 follow-up plans AND no user-reported regressions.
- **Reinstate**: any row shows patterns the disabled component would have caught, OR the reinstate condition recorded in Phase 5c fires.
- **Extend test**: fewer than 3 plans have elapsed since the disable began.
