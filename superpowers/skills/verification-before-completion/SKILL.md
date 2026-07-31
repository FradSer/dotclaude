---
name: verification-before-completion
description: Use when about to claim work is complete, fixed, or passing, before committing, before reporting a task done, or before telling the evaluator the batch is ready. Requires running the verification command and reading its output in this turn before any success claim; evidence before assertions always.
user-invocable: false
---

# Verification Before Completion

## The Iron Law

```
NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE
```

If you have not run the verification command in **this turn**, you cannot claim it passes. The superpowers-evaluator reads narration and runs commands independently — your unverified "done" can be waved through unless it self-evidences.

**Violating the letter of this rule is violating the spirit of this rule.**

## The Gate Function

Run this before claiming any status, expressing satisfaction, or returning a PASS-shaped verdict to the coordinator:

1. **IDENTIFY** — What command proves this claim? (the task file's `## Verification Commands`)
2. **RUN** — Execute the FULL command, fresh, in this turn. Not a previous run, not "should pass".
3. **READ** — Full output, check exit code, count failures. Last 20-30 lines pasted into your return.
4. **VERIFY** — Does the output confirm the claim?
   - NO → state the actual status with evidence (exit code, failure count)
   - YES → state the claim WITH evidence (exit 0, N/N pass)
5. **ONLY THEN** make the claim.

Skipping any step is lying, not verifying.

## Common Failures

| Claim | Requires | Not Sufficient |
|-------|----------|----------------|
| Tests pass | Test command output: 0 failures | Previous run, "should pass" |
| Linter clean | Linter output: 0 errors | Partial check, extrapolation |
| Build succeeds | Build command: exit 0 | Linter passing, logs look good |
| Bug fixed | Original-symptom test passes | Code changed, assumed fixed |
| Regression test works | Red-green cycle verified | Test passes once |
| Sub-agent completed | VCS diff shows changes + your re-run | Sub-agent reports "success" |
| Requirements met | Line-by-line checklist vs spec | Tests passing alone |

## Red Flags — STOP

- Using "should", "probably", "seems to"
- Expressing satisfaction before verification ("Done!", "Great!", "Perfect!")
- About to commit, push, or return a PASS verdict without verification
- Trusting a sub-agent's success report without re-running verification yourself
- Relying on partial verification (only one of several test files)
- Thinking "just this once"
- **ANY wording implying success without having run verification this turn**

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "Should work now" | RUN the verification |
| "I'm confident" | Confidence is not evidence |
| "Just this once" | No exceptions |
| "Linter passed" | Linter is not the test runner |
| "The sub-agent said success" | Verify independently — sub-agents hallucinate done |
| "Partial check is enough" | Partial proves nothing |
| "Different words so the rule doesn't apply" | Spirit over letter |
| "The evaluator will catch it anyway" | The evaluator reads narration; an unverified "done" can slip past. Self-verify first. |

## Relationship to the superpowers-evaluator

This skill is the **implementer-side** pre-gate. The superpowers-evaluator is the independent read-only post-gate that re-runs verification commands itself. They do not overlap:

- You (implementer) self-prove with this skill **before** returning a done verdict to the coordinator.
- The evaluator independently re-verifies **after** the batch passes the Verification Gate.

An unverified "done" from you can be waved through by the evaluator (it reads narration, not always files). Self-evidence closes that gap. Do not lean on the evaluator as a safety net — produce the evidence yourself first.

## The Bottom Line

Run the command. Read the output. Paste the evidence. THEN claim the result.

This is non-negotiable.
