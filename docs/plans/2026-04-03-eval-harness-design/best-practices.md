# Best Practices

## Writing Effective Checklist Items

### The binary test

Every checklist item must pass a binary test: can you determine PASS or FAIL without a judgment call?

"Architecture is well-structured" — fails the binary test. "No import described from domain layer to infrastructure layer" — passes.

For each proposed item, ask: "If I give this checklist to a fresh evaluator with only the artifacts, will two independent evaluators always produce the same PASS/FAIL result?" If the answer is "it depends on interpretation," the item is too subjective. Rewrite it as a search pattern or a structural query.

### Evidence requirement

Every FAIL result must name file, location, and the exact text or pattern that violated the check. An evaluator that produces "FAIL — scenario not concrete enough" with no file and line reference has produced an unactionable rework item.

The checklist item itself should specify how to find evidence: "grep for 'some', 'valid input', 'appropriate', or 'relevant' in Given clauses" is specific. "Assess Given clause concreteness" is not.

### Item granularity

One item, one concern. "Scenarios are complete and concrete" covers two concerns. Split it:
- "All Given clauses use specific data values" (concreteness)
- "All error paths have at least one scenario" (completeness)

A single FAIL covering two concerns gives the generator ambiguous feedback. Two separate FAIL items give precise rework targets.

### Negative checks vs. positive checks

Negative checks ("no import from X to Y") are generally more reliable than positive checks ("all requirements have scenarios"). Negative checks find violations. Positive checks require comprehensiveness, which is harder to verify mechanically.

For comprehensiveness checks, use cross-referencing with counts: "every requirement ID in _index.md appears in at least one scenario" is checkable by comparing two explicit lists. "Scenarios are comprehensive" is not.

### Executable check specification

Each checklist item should include, in a comment or annotation, the grep pattern or structural query used to confirm it. This prevents two evaluators from applying the same item differently:

```
- [ ] SCEN-CONC-01: All Given clauses use specific data values
  # Check: grep for "some ", "valid ", "appropriate ", "relevant " in Given clauses of bdd-specs.md
  # Evidence format: file:line — quoted text
```

## Managing Checklist Evolution

### Add only from multi-plan evidence

A single failure is noise. Failures in 2+ distinct plans with the same root cause are signal. EVO-5 enforces this. Do not override it for a single dramatic failure — investigate whether the failing plan was anomalous.

The key question: "Would this item have caught a FAIL in at least 2 of my last 5 plans?" If yes, it belongs in the checklist. If uncertain, wait for one more plan.

### Remove conservatively

A never-failing item might reflect a failure mode that models now reliably avoid — which is success, not irrelevance. Or it might reflect a check that was always too easy to pass.

Before approving a REMOVE proposal:
1. Can you construct a concrete example where this item would fail?
2. If yes: has the check been too permissive in how it's applied? Consider MODIFY before REMOVE.
3. If no: the check is either solved or the item was never meaningful. Approve the removal.

Never-failing items after 10+ plans that you cannot construct a failing example for are clear removal candidates. Retain the removal event in the evolution log for future reference.

### Version files, do not mutate them

When any item is added, modified, or removed, create `design-v2.md` rather than overwriting `design-v1.md`. Evaluation reports already written reference the checklist version used. Mutating a versioned file makes historical reports uninterpretable.

File naming: always increment the numeric suffix. `design-v1.md → design-v2.md`, not `design-v1-updated.md` or `design-latest.md`.

### Cross-mode contamination

Code mode failures do not automatically justify design checklist changes. If code tasks repeatedly fail due to missing error handling, the root cause might be in the code, not the design.

However, if code failures consistently trace back to vague error scenarios in BDD specs (visible in design evaluation reports), that IS evidence for a design checklist addition — because the root cause is in the design documentation. The trace must be explicit in the retrospective analysis: the code failure → the design gap must be documented as the causal chain.

After amending a design checklist, check whether the same failure mode also appears in plan evaluation reports. Cross-mode patterns that share a single root cause should be addressed in both checklists in the same retrospective run.

## Retrospective Cadence

### When to run

Run retrospective after 3+ plans have been executed, not after every plan. Single-plan retros produce noise proposals from insufficient data.

Exception: if a plan has an unusually high failure rate (more than half of checklist items failing in the code evaluation), run retrospective immediately after that plan — it may indicate a systemic gap.

### Working with the rate limit

The rate limit (max 3 changes per mode per retrospective run, EVO-6) exists to prevent rapid oscillation. If analysis produces 7 valid proposals, the top 3 by failure frequency are surfaced; the rest are deferred.

Do not try to manually apply deferred proposals between retros. Wait for the next run — if the evidence base has grown, deferred proposals will reappear and may then be within the rate limit.

### Across-plan retrospective value

Single-plan: useful for identifying idiosyncratic failures from a specific domain or team pattern.
Multi-plan: necessary for reliable evolution proposals. Failure patterns visible across 3+ plans are the strongest signal for ADD proposals. Never-failing items visible across 4+ plans are the strongest signal for REMOVE proposals.

For your first retrospective run, use all available plans. Subsequent runs can use a rolling window of the 5 most recent plans.

## Code Mode Verification Ground Truth

### Command exit codes are the verdict

If verification commands pass, the task passes. If they fail, the task fails. Code quality reasoning does not override a passing exit code, and a visually "correct" implementation does not override a failing exit code.

The corollary: if verification commands are poorly designed (too permissive, testing the wrong behavior), the evaluation is compromised. Verification command quality is enforced by the plan checklist (TASK-COMP-02 and TASK-COMP-03), not by the code evaluator. The chain of quality is: plan checklist → good verification commands → reliable code evaluation.

### Independent execution is mandatory

The evaluator MUST run commands itself. A generator that claims "all tests pass" followed by the evaluator running tests and finding a failure should produce REWORK — and the rework item should note the discrepancy explicitly. This discrepancy is itself a signal: the generator may be misreporting results.

### No quality scoring in code mode

The evaluator no longer scores "Code Quality" or "Spec Compliance" on a 1-5 scale. If code passes tests, type checks, linter, and the prohibited patterns check, it passes. Code that passes tests but is aesthetically poor is a candidate for a refactor task — not for REWORK in the current evaluation.

The evaluation question is: does the code do what the sprint contract says? The verification commands answer that question. The evaluator does not supplement that answer with subjective assessment.

## Evolution Log Integrity

The `evolution-log.jsonl` file is append-only. Never remove or edit past entries — they are the audit trail for every checklist decision. If a change was a mistake, log a corrective event:

```json
{"timestamp":"2026-06-01T10:00:00Z","event":"item_removed","mode":"design","item_id":"SCEN-CONC-03","rationale":"Added prematurely — item ID was correct but check description was ambiguous; re-adding corrected version as SCEN-CONC-04"}
{"timestamp":"2026-06-01T10:01:00Z","event":"item_added","mode":"design","item_id":"SCEN-CONC-04","rationale":"Corrected version of SCEN-CONC-03: specifies HTTP status codes only, not all concrete values"}
```

The rationale field in each event must be understandable 6 months later without surrounding context. "Caught too many false positives" is insufficient. "Triggered on 'Given a valid session' — session validity is domain-appropriate specificity; check was too strict for authentication Given clauses" is sufficient.
