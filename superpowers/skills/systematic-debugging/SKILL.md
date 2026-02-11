---
name: systematic-debugging
description: Provides systematic debugging methodology with 4-phase process (root cause investigation, pattern analysis, hypothesis testing, implementation). Use when encountering any bug, test failure, or unexpected behavior, before proposing fixes
user-invocable: false
---

# Systematic Debugging

## Overview

Random fixes waste time and create new bugs. Quick patches mask underlying issues.

**Core principle:** Root cause investigation must precede any fix attempt. Symptom fixes represent process failure.

**Violating the letter of this process is violating the spirit of debugging.**

## The Iron Law

```
NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST
```

Fixes cannot be proposed without completing Phase 1.

## When to Apply

Systematic debugging applies to ANY technical issue:
- Test failures
- Bugs in production
- Unexpected behavior
- Performance problems
- Build failures
- Integration issues

**Especially valuable when:**
- Time pressure creates temptation to guess
- "Quick fix" seems obvious
- Multiple fixes have already been attempted
- Previous fixes failed
- Issue is not fully understood

**Process should not be skipped even when:**
- Issue appears simple (simple bugs have root causes too)
- Time is tight (systematic approach is faster than thrashing)
- Urgency exists (investigation is faster than rework)

## The Four Phases

Each phase must be completed before proceeding to the next.

### Phase 1: Root Cause Investigation

**Before attempting any fix:**

1. **Read Error Messages Carefully**
   - Error messages and warnings often contain solutions
   - Read stack traces completely
   - Note line numbers, file paths, error codes

2. **Reproduce Consistently**
   - Determine if the issue triggers reliably
   - Identify exact steps
   - Confirm reproducibility
   - If not reproducible, gather more data instead of guessing

3. **Check Recent Changes**
   - Git diff and recent commits
   - New dependencies, config changes
   - Environmental differences

4. **Gather Evidence in Multi-Component Systems**

   **For systems with multiple components (CI -> build -> signing, API -> service -> database):**

   Diagnostic instrumentation should be added before proposing fixes:
   ```
   For EACH component boundary:
     - Log what data enters component
     - Log what data exits component
     - Verify environment/config propagation
     - Check state at each layer

   Run once to gather evidence showing WHERE it breaks
   THEN analyze evidence to identify failing component
   THEN investigate that specific component
   ```

   **Multi-layer system example:**
   ```bash
   # Layer 1: Workflow
   echo "=== Secrets available in workflow: ==="
   echo "IDENTITY: ${IDENTITY:+SET}${IDENTITY:-UNSET}"

   # Layer 2: Build script
   echo "=== Env vars in build script: ==="
   env | grep IDENTITY || echo "IDENTITY not in environment"

   # Layer 3: Signing script
   echo "=== Keychain state: ==="
   security list-keychains
   security find-identity -v

   # Layer 4: Actual signing
   codesign --sign "$IDENTITY" --verbose=4 "$APP"
   ```

   This reveals which layer fails.

5. **Trace Data Flow**

   **When error is deep in call stack:**

   See `./references/root-cause-tracing.md` for the complete backward tracing technique.

   **Quick approach:**
   - Identify where bad value originates
   - Determine what called this with bad value
   - Continue tracing up until source is found
   - Fix at source, not at symptom

### Phase 2: Pattern Analysis

**Pattern identification should precede any fix:**

1. **Find Working Examples**
   - Locate similar working code in same codebase
   - Identify working code similar to what's broken

2. **Compare Against References**
   - If implementing a pattern, read reference implementation completely
   - Read every line, do not skim
   - Understand pattern fully before applying

3. **Identify Differences**
   - List every difference between working and broken code
   - Do not dismiss small differences as irrelevant

4. **Understand Dependencies**
   - Other components required by this operation
   - Settings, config, environment needed
   - Assumptions made by the pattern

### Phase 3: Hypothesis and Testing

**Scientific method application:**

1. **Form Single Hypothesis**
   - State clearly: "X is the root cause because Y"
   - Be specific, not vague

2. **Test Minimally**
   - Make smallest possible change to test hypothesis
   - One variable at a time
   - Do not fix multiple things simultaneously

3. **Verify Before Continuing**
   - If hypothesis confirmed: proceed to Phase 4
   - If not confirmed: form new hypothesis
   - Do not add more fixes on top

4. **When Understanding is Missing**
   - Acknowledge lack of understanding
   - Ask for help
   - Research more

### Phase 4: Implementation

**Fix the root cause, not the symptom:**

1. **Create Failing Test Case**
   - Simplest possible reproduction
   - Automated test if possible
   - One-off test script if no framework
   - Test must exist before fixing

2. **Implement Single Fix**
   - Address the identified root cause
   - One change at a time
   - No "while I'm here" improvements
   - No bundled refactoring

3. **Verify Fix**
   - Test now passes?
   - No other tests broken?
   - Issue actually resolved?

4. **If Fix Doesn't Work**
   - Stop
   - Count attempted fixes
   - If < 3: Return to Phase 1, re-analyze with new information
   - If >= 3: Question architecture

5. **Architecture Questioning After 3+ Failed Fixes**

   **Patterns indicating architectural problem:**
   - Each fix reveals new shared state/coupling/problem in different place
   - Fixes require "massive refactoring"
   - Each fix creates new symptoms elsewhere

   **Stop and question fundamentals:**
   - Is pattern fundamentally sound?
   - Is approach continuing through inertia?
   - Should architecture be refactored vs. fixing symptoms?

   **Discuss with human partner before attempting more fixes**

   This is not a failed hypothesis - this is wrong architecture.

## Red Flags

These mental patterns indicate process violation and require returning to Phase 1:
- "Quick fix for now, investigate later"
- "Just try changing X and see if it works"
- "Add multiple changes, run tests"
- "Skip the test, I'll manually verify"
- "It's probably X, let me fix that"
- "I don't fully understand but this might work"
- "Pattern says X but I'll adapt it differently"
- Proposing solutions before tracing data flow
- **"One more fix attempt" (when already tried 2+)**
- **Each fix reveals new problem in different place**

**If 3+ fixes failed:** Question the architecture.

## Human Partner Signals

**Watch for these redirections:**
- "Is that not happening?" - Indicates assumption without verification
- "Will it show us...?" - Indicates missing evidence gathering
- "Stop guessing" - Indicates proposing fixes without understanding
- "Ultrathink this" - Indicates need to question fundamentals, not just symptoms
- "We're stuck?" (frustrated) - Indicates current approach isn't working

**When encountering these signals:** Return to Phase 1.

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

## Quick Reference

| Phase | Key Activities | Success Criteria |
|-------|---------------|------------------|
| **1. Root Cause** | Read errors, reproduce, check changes, gather evidence | Understand WHAT and WHY |
| **2. Pattern** | Find working examples, compare | Identify differences |
| **3. Hypothesis** | Form theory, test minimally | Confirmed or new hypothesis |
| **4. Implementation** | Create test, fix, verify | Bug resolved, tests pass |

## When Process Reveals No Root Cause

If systematic investigation reveals issue is environmental, timing-dependent, or external:

1. Process has been completed
2. Document what was investigated
3. Implement appropriate handling (retry, timeout, error message)
4. Add monitoring/logging for future investigation

**Note:** 95% of "no root cause" cases represent incomplete investigation.

## Supporting Techniques

These techniques are part of systematic debugging:

- **`./references/root-cause-tracing.md`** - Trace bugs backward through call stack to find original trigger
- **`./references/defense-in-depth.md`** - Add validation at multiple layers after finding root cause
- **`./references/condition-based-waiting.md`** - Replace arbitrary timeouts with condition polling
- **`./references/condition-based-waiting-example.ts`** - Example implementation of condition-based waiting

**Related skills:**
- **superpowers:behavior-driven-development** - BDD principles including Gherkin scenarios for test design

## Real-World Impact

From debugging sessions:
- Systematic approach: 15-30 minutes to fix
- Random fixes approach: 2-3 hours of thrashing
- First-time fix rate: 95% vs 40%
- New bugs introduced: Near zero vs common