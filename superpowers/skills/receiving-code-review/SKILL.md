---
name: receiving-code-review
description: Use when the superpowers-evaluator returned REWORK on a batch, when fixing rework items from an evaluation report, or when receiving any code review feedback on superpowers output. Requires technical rigor and verification instead of performative agreement or blind implementation.
user-invocable: false
---

# Receiving Code Review (the evaluator REWORK loop)

The superpowers-evaluator returns REWORK with file:line evidence. Your job is to fix the right thing — not to please the evaluator.

**Core principle:** Verify before implementing. Ask before assuming. Technical correctness over social comfort. The evaluator is a red-team reviewer, not an order-giver.

## The Response Pattern

Run this for each rework item before changing code:

1. **READ** the full rework item (file:line + what failed + corrective action) without reacting.
2. **UNDERSTAND** restate the technical requirement in your own words (or ask the evaluator-equivalent: re-read the checklist item the rework cites).
3. **VERIFY** check the claim against codebase reality — does the cited file:line actually say what the evaluator says it says?
4. **EVALUATE** is the corrective action technically sound for THIS codebase? (see Push Back below)
5. **RESPOND** with a technical acknowledgment or a reasoned pushback — never performative agreement.
6. **IMPLEMENT** one item at a time, re-running verification after each, before re-spawning the evaluator.

## Forbidden Responses

**NEVER output, even when the evaluator is right:**
- "You're absolutely right!" / "Great point!" / "Excellent feedback!" / "Thanks for catching that"
- "Let me implement that now" before verification
- Any gratitude expression or performative agreement

**INSTEAD:**
- Restate the technical requirement
- Ask a clarifying question if the item is unclear
- Push back with technical reasoning if wrong
- Just fix it and show the diff — actions speak, the code shows you heard it

## Handling Unclear Items

If ANY rework item is unclear, do NOT implement the clear ones and defer the unclear ones. Items may be related — partial understanding produces wrong implementation.

```
Evaluator: 4 rework items. You understand items 1,2,4. Unclear on item 3.

WRONG:  implement 1,2,4 now, ask about 3 later
RIGHT:  re-read the cited checklist item for 3; if still unclear, note the
        ambiguity in your return and implement 1,2,4 only after 3 is resolved
        (or explicitly mark 3 as [AUTO-RESOLVED] per the sprint contract's
        Autonomous Resolution Protocol with the most concrete interpretation)
```

## When To Push Back

Push back (with technical reasoning, not defensiveness) when a rework item:
- Breaks existing functionality the evaluator didn't see
- Cites a checklist item that doesn't apply to this batch's scope
- Violates YAGNI (the "fix" adds a feature nothing uses)
- Is technically incorrect for this stack
- Conflicts with a prior architectural decision recorded in the plan's `## Global Constraints` block
- The evaluator misread the file (file:line doesn't say what the report claims)

**How to push back in your return:**
- Reference working tests / specific file:line that contradicts the finding
- State what you verified and what you couldn't
- If architectural, flag for the main agent's PIVOT consideration

If the evaluator was right and you were wrong: state the correction factually and move on. No long apology, no defending why you pushed back.

## Implementation Order for Multi-Item REWORK

1. Clarify all unclear items FIRST (re-read checklist items)
2. Then implement in this order:
   - Blocking issues (breaks tests, security, correctness)
   - Simple fixes (typos, imports, missing guards)
   - Complex fixes (refactoring, logic changes)
3. Re-run the task's verification command after EACH fix (per `verification-before-completion`)
4. Re-spawn the superpowers-evaluator for the next round only after all items are addressed and verification passes THIS TURN.

## The Bottom Line

Evaluator REWORK = findings to evaluate, not orders to follow. Verify each item against the codebase. Question the wrong ones. Implement the right ones one at a time with verification. No performative agreement, no blind batch implementation.
