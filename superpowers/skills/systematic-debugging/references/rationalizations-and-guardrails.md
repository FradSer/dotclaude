# Rationalizations & Guardrails

Companion to the SKILL.md Red Flags section: the extended excuse-vs-reality table, human partner redirection signals, and the rationale behind the inline-plan format. Consult when you catch yourself arguing against the process mid-debug.

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Issue is simple, don't need process" | Simple issues have root causes too. Process is fast for simple bugs. |
| "Emergency, no time for process" | Systematic debugging is FASTER than guess-and-check thrashing. |
| "Just try this first, then investigate" | First fix sets the pattern. Do it right from the start. |
| "I'll write test after confirming fix works" | Untested fixes don't stick. Test first proves it. |
| "Multiple fixes at once saves time" | Can't isolate what worked. Causes new bugs. |
| "Reference too long, I'll adapt the pattern" | Partial understanding guarantees bugs. Read it completely. |
| "I see the problem, let me fix it" | Seeing symptoms != understanding root cause. |
| "One more fix attempt" (after 2+ failures) | 3+ failures = architectural problem. Question pattern, don't fix again. |

The same rationalizations surface as reasons to skip the process entirely. The process should not be skipped even when:

- Issue appears simple (simple bugs have root causes too)
- Time is tight (systematic approach is faster than thrashing)
- Urgency exists (investigation is faster than rework)

## Human Partner Signals

**Watch for these redirections:**

- "Is that not happening?" - Indicates assumption without verification
- "Will it show us...?" - Indicates missing evidence gathering
- "Stop guessing" - Indicates proposing fixes without understanding
- "Ultrathink this" - Indicates need to question fundamentals, not just symptoms
- "We're stuck?" (frustrated) - Indicates current approach isn't working

**When encountering these signals:** Return to Phase 1.

## Why the Complex-Bug Plan Is Inline (not BUGFIX_PLAN.md)

- The deliverable contract is "fix + regression test", not a planning artifact — a saved plan file would survive the bug fix in the repo as orphan documentation
- An inline summary keeps the contract visible in the same turn that applies it, so the executor (this skill) can re-check the six lines against the diff before committing
- Removes the wording conflict with the skill's top-of-file rule "Do NOT write design documents or task files"

## Real-World Impact

From debugging sessions:

- Systematic approach: 15-30 minutes to fix
- Random fixes approach: 2-3 hours of thrashing
- First-time fix rate: 95% vs 40%
- New bugs introduced: Near zero vs common
