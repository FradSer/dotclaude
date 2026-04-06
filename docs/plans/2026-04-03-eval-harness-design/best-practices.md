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

## Computational vs Inferential Checks

### The distinction

Each checklist item falls into one of two types based on whether its result is deterministic:

- **Computational**: The check produces the same PASS/FAIL result regardless of who (or what) runs it. Examples: `grep "TODO"` (pattern match), `tsc --noEmit` (exit code), cycle detection in a dependency graph (algorithm). These checks have zero observer variability.

- **Inferential**: The check requires judgment to apply, even with an explicit check method. Examples: "every requirement maps to at least one scenario" (what counts as "maps to"?), "no inner-to-outer layer imports" (which layer is which?). These checks have non-zero observer variability, reduced but not eliminated by the check method annotation.

### Why annotate

The evaluator is an LLM evaluating LLM output — in cybernetic terms, the observer is part of the system (second-order cybernetics). For computational checks, this is irrelevant: the result is deterministic. For inferential checks, evaluator bias (sycophancy, anchoring, context-dependent interpretation) can produce different results on the same artifact.

Annotating `# Type: inferential` makes the noise budget visible. It does not change the PASS/FAIL behavior in v1, but it:

1. Signals to the evaluator to anchor judgment explicitly to the check method
2. Surfaces borderline results (informational notes that do not affect verdict) for checklist evolution review
3. Prepares for v2's multi-trial protocol: run inferential checks multiple times and flag disagreements

### Writing good inferential checks

Minimize interpretive freedom by providing concrete anchors:

- **Weak**: "Every requirement maps to at least one scenario" — "maps to" is vague
- **Better**: "Every requirement ID from _index.md Requirements section appears as text in at least one scenario in bdd-specs.md" — check method is grep for exact ID string
- **Best**: Same as above, plus: "If a scenario covers a requirement semantically but does not cite the ID, result is PASS with borderline note citing the implicit coverage"

The goal is not to eliminate judgment — some checks inherently require it. The goal is to constrain the judgment space so two evaluators reach the same conclusion in >90% of cases.

## Detecting Checklist Gaps (Variety Amplification)

### The problem

Ashby's Law of Requisite Variety states that a controller must have at least as much variety as the system it controls. Checklists are manually authored — their variety is limited by human observation and experience. If the generator produces a novel failure mode not covered by any checklist item, the evaluator is blind to it.

The checklist evolution process (add/modify/remove items after multi-plan review) is a variety attenuator: it removes items that never fail. But there is no corresponding variety amplifier: no mechanism to detect items that should exist but do not.

### Signals for potential gaps

Two observable signals suggest a checklist gap:

1. **Rework-despite-PASS**: A batch where all checklist items PASS but the batch required 2+ rework rounds before passing. The initial evaluation missed something the generator struggled with — the checklist may need a new item.

2. **Persistent rework on inferential items**: An inferential check that produces PASS on first evaluation but FAIL on re-evaluation after rework (or vice versa) suggests the check method is too ambiguous — the item may need to be split or its check method refined.

These signals are surfaced in the plan completion summary as "Potential Checklist Gaps" alongside evolution candidates. They do not trigger automatic changes.

### When to act on gap signals

A single rework-despite-PASS event is noise — the rework may have been caused by a generator error unrelated to checklist coverage. Rework-despite-PASS events in 2+ distinct plans with similar root causes are signal. Apply the same multi-plan evidence threshold as checklist item additions (see "Add only from multi-plan evidence" below).

## Managing Checklist Evolution

Checklists are manually evolved via git. The practices below guide when and how to add, modify, or remove items.

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

However, if code failures consistently trace back to vague error scenarios in BDD specs (visible in design evaluation reports), that IS evidence for a design checklist addition — because the root cause is in the design documentation. The trace must be explicit: the code failure -> the design gap must be documented as the causal chain.

After amending a design checklist, check whether the same failure mode also appears in plan evaluation reports. Cross-mode patterns that share a single root cause should be addressed in both checklists.

## Review Cadence

### When to review checklists

Review checklists after 3+ plans have been executed, not after every plan. Single-plan reviews produce noisy conclusions from insufficient data.

**Explicit triggers for immediate review** (do not wait for 3-plan cadence):
- A plan's completion summary lists 2+ evolution candidates (items FAILing 3+ batches or requiring 3+ rework rounds)
- A plan's completion summary lists 2+ potential checklist gaps (batches with all-PASS but 2+ rework rounds)
- More than half of checklist items failing in the code evaluation of a single plan (systemic gap)

These triggers bridge the gap between intra-plan learning and checklist evolution — the ultra-stability transition in the control hierarchy.

### Rate of change

Limit to max 3 item changes per mode per review session to prevent rapid oscillation. If you identify 7 valid changes, apply the top 3 by failure frequency; defer the rest until the next review cycle.

### Across-plan review value

Single-plan: useful for identifying idiosyncratic failures from a specific domain or team pattern.
Multi-plan: necessary for reliable evolution decisions. Failure patterns visible across 3+ plans are the strongest signal for adding items. Never-failing items visible across 4+ plans are the strongest signal for removal.

For your first review, examine all available plan evaluation reports. Subsequent reviews can use a rolling window of the 5 most recent plans.

## Context Management at Batch Boundaries

### Why batch handoffs matter

Anthropic's harness design article finds that "context resets outperform context compaction" for long-running tasks. The Superpower Loop architecture is context compaction — the same session accumulates context across all batches. For plans with 5+ batches, this creates two risks:

1. **Context anxiety**: The model perceives context limits approaching and rushes to complete, producing lower-quality output in later batches.
2. **Detail loss**: Earlier batch details become less accessible as newer information fills the context window, leading to repeated mistakes or inconsistent decisions.

### Batch handoff as pragmatic middle ground

A full context reset would require breaking out of the Superpower Loop and starting a new session per batch — a significant architectural change. Batch handoffs are the simpler alternative: emit a structured summary at each batch boundary that serves as a compressed checkpoint.

The key principle: the handoff must contain enough information for the model to continue effectively even if it "forgets" the details of prior batches. This means: completed task list, cumulative progress, active failure patterns, modified files, and next batch scope.

### What NOT to include in batch handoffs

- Full task file content (the model can re-read task files on demand)
- Evaluation report content (reference the file path instead)
- Implementation details from completed tasks (the code is in the files)

The handoff is a navigation aid, not a context dump. Keep it under 30 lines.

## Cost Awareness and Harness ROI

### When the evaluator is overhead vs essential

Anthropic's article observes that the evaluator is "essential when task exceeds model baseline capability, overhead otherwise." The shift from Opus 4.5 to 4.6 changed what the evaluator caught: fewer basic issues, more subtle interaction bugs.

Without cost data, you cannot make this judgment. The "Run Metrics" section in each evaluation report captures: evaluation duration, checklist version, and token counts (best-effort -- may not be available in all Claude Code spawning contexts). Over 3+ plans, these metrics answer:

- What is the average token cost per evaluation round?
- Does the evaluator cost scale linearly with task count, or is there a fixed overhead?
- At what plan size does the evaluator ROI become positive (evaluation cost < rework cost avoided)?

### Adjusting evaluator activation

The current auto mode threshold (5+ tasks or 3+ BDD scenarios) is a starting estimate. After running 3+ plans with cost tracking:

- If evaluator-on plans have similar rework rates to evaluator-off plans, raise the threshold
- If evaluator catches failures that would have cost more to fix post-hoc, lower the threshold
- If a specific mode (design/plan/code) rarely produces FAIL results, reduce that mode to spot-check frequency

These adjustments are manual and informed by the cost data — not automated. Per Anthropic's principle: "re-examine harnesses when new models release."

## Code Mode Verification Ground Truth

### Command exit codes are the verdict

If verification commands pass, the task passes. If they fail, the task fails. Code quality reasoning does not override a passing exit code, and a visually "correct" implementation does not override a failing exit code.

The corollary: if verification commands are poorly designed (too permissive, testing the wrong behavior), the evaluation is compromised. Verification command quality is enforced by the plan checklist (TASK-COMP-02 and TASK-COMP-03), not by the code evaluator. The chain of quality is: plan checklist → good verification commands → reliable code evaluation.

### Independent execution is mandatory

The evaluator MUST run commands itself. A generator that claims "all tests pass" followed by the evaluator running tests and finding a failure should produce REWORK — and the rework item should note the discrepancy explicitly. This discrepancy is itself a signal: the generator may be misreporting results.

### No quality scoring in code mode

The evaluator no longer scores "Code Quality" or "Spec Compliance" on a 1-5 scale. If code passes tests, type checks, linter, and the prohibited patterns check, it passes. Code that passes tests but is aesthetically poor is a candidate for a refactor task — not for REWORK in the current evaluation.

The evaluation question is: does the code do what the sprint contract says? The verification commands answer that question. The evaluator does not supplement that answer with subjective assessment.

## Checklist Evolution Audit Trail

Checklist evolution is tracked via git history (version files, commit messages). No separate evolution log file is maintained in v1 -- git provides the audit trail.

When evolving checklists, write commit messages that would be understandable 6 months later: "Caught too many false positives" is insufficient. "Remove SCEN-CONC-03: triggered on 'Given a valid session' -- session validity is domain-appropriate specificity; check was too strict for authentication Given clauses" is sufficient.

If a future version needs a structured evolution log (e.g., for automated analysis of checklist drift), introduce `evolution-log.jsonl` as an append-only file at that point.
