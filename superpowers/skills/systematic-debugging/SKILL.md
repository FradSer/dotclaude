---
name: systematic-debugging
description: This skill should be used when the user reports a bug, error, test failure, or unexpected behavior, or invokes /superpowers:systematic-debugging. Provides a 4-phase root cause analysis process, ensuring thorough investigation precedes any code changes.
argument-hint: "<bug description or symptom>"
user-invocable: true
allowed-tools: ["Read", "Grep", "Glob", "Edit", "Write", "Agent", "Bash(git:*)", "Bash(npm:*)", "Bash(pnpm:*)", "Bash(uv:*)", "Bash(pip:*)", "Bash(pytest:*)", "Bash(python:*)", "Bash(python3:*)", "Bash(go:*)", "Bash(cargo:*)", "Bash(mvn:*)", "Bash(gradle:*)", "Bash(rspec:*)", "Bash(bundle:*)", "Bash(test:*)", "Bash(${CLAUDE_PLUGIN_ROOT}/skills/systematic-debugging/find-polluter.sh:*)", "Bash(${CLAUDE_PLUGIN_ROOT}/lib/bail-log.sh:*)", "Bash(${CLAUDE_PLUGIN_ROOT}/lib/jsonl-emit.sh:*)"]
---

# Systematic Debugging

## Slash-command Usage

Invoked via `/superpowers:systematic-debugging "<symptom>"` or auto-loaded by other skills (BDD, brainstorming) when bug-fix language is detected.

**When invoked as a slash command**: capture `$ARGUMENTS` as the symptom statement, then start at Phase 1 (Root Cause Investigation) immediately. Do NOT spawn the Superpower Loop — debugging is iterative within a single session, not phase-driven. Do NOT write design documents or task files; the deliverable is `the fix + a test that catches the regression`, not a docs/plans/ folder.

**Output discipline**: Report findings inline as you complete each phase. End with: (a) root cause one-liner, (b) fix diff summary, (c) regression test path. No `<promise>` tag (no loop to exit).

## CRITICAL: Bail-Out Check (run before Phase 1)

**Inspect `$ARGUMENTS` for "named root cause + named fix" signals. Bail out — skip the 4-phase pipeline, apply the fix and write a regression test directly — when ALL of these match:**

- `$ARGUMENTS` names a specific root cause (file:line, config key, or specific value), AND
- `$ARGUMENTS` names a specific corrective change ("change X to Y", "add the missing flag", "fix the typo"), AND
- The fix is localized to a single file or a single string substitution

Examples that bail out:

- "cookie domain is `.foo.com`, should be `foo.com` — fix it"
- "missing `await` at api.ts:42, add it"
- "wrong env var name `DB_HOST` should be `DATABASE_HOST` in deploy.yaml"

Examples that DO NOT bail out (proceed to Phase 1):

- "tests fail in CI but pass locally" (symptom only, no root cause)
- "this is slow" (no hypothesis)
- "I think it's the cache, can you check?" (hypothesis without confirmed root cause)

**Bail-out response (output verbatim, then proceed with direct edit + write a regression test that catches the bug):**

> Detected named root cause and named fix. Skipping the 4-phase pipeline (calibrated for unknown root causes). Applying the fix and writing a regression test directly. To force the full pipeline, re-invoke as `/superpowers:systematic-debugging --force "<symptom>"`.

When the user passes `--force` (literal token in `$ARGUMENTS`), skip this bail-out and proceed to Phase 1 unconditionally.

**Calibration log** (regardless of branch — bail or `--force`):

```bash
bash "${CLAUDE_PLUGIN_ROOT}/lib/bail-log.sh" systematic-debugging <event> "<short reason>" "$ARGUMENTS"
```

`<event>` is `bail_out` when the named-root-cause+named-fix gate fires (and the direct-edit-plus-regression-test path is taken), or `force_override` when `--force` bypasses the gate into Phase 1. The log feeds retrospective Phase 5a — repeated `force_override` on inputs that look bail-eligible suggests the third gate condition (single-file-or-string-substitution) is too restrictive.

**Iron Law remains** for non-bail-out paths: NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST. The bail-out only fires when the user has *already done* the root cause work and is handing the conclusion to Claude.

## Overview

Random fixes waste time and create new bugs. Quick patches mask underlying issues.

**Core principle:** Root cause investigation must precede any fix attempt. Symptom fixes represent process failure.

**Violating the letter of this process is violating the spirit of debugging.**

## CRITICAL: The Iron Law

```
NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST
```

Fixes cannot be proposed without completing Phase 1. Each phase MUST finish before the next begins. Violating this rule produces fix-attempts that mask root causes — the failure mode this skill exists to prevent. If at any point you find yourself proposing a fix without completed Phase 1 evidence, stop and return to Phase 1.

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

   On success — and ONLY on success, never on the bail-out branch (§4.2) or the architecture-questioning branch (§4.4) — emit one `fix_completed` event. Read `skill_name` from the session state file via `state_read` (same pattern as `loop.sh::_loop_log_plan_completion_if_executing`); do NOT hardcode `"systematic-debugging"` as the helper's $1. Silently skip when the state file is missing or `skill_name` is empty. Dedup-check the last 200 lines of `skill-events.jsonl` for the matching `args_hash` before emitting. Payload carries `root_cause`, `regression_test_path`, `investigation_phase_count` — and NEVER `test_stdout`, `test_stderr`, or `fix_diff` (per `best-practices.md` "No transcript content").

   ```bash
   source "${CLAUDE_PLUGIN_ROOT}/lib/utils.sh"
   source "${CLAUDE_PLUGIN_ROOT}/lib/jsonl-emit.sh"

   state_file=$(find_state_file "${CLAUDE_SESSION_ID:-}")
   skill_name=""
   if [[ -n "$state_file" && -f "$state_file" ]]; then
     skill_name=$(state_read "$state_file" '.skill_name // ""')
   fi
   if [[ -n "$skill_name" ]]; then
     ROOT_CAUSE="<one-line root cause>"
     REGRESSION_TEST_PATH="<tests/path::case>"
     PHASE_COUNT=4

     args_hash=$(compute_args_hash "$ROOT_CAUSE" "$REGRESSION_TEST_PATH" "$PHASE_COUNT")

     log="$(repo_root)/docs/retros/skill-events.jsonl"
     if [[ -n "$args_hash" ]] && dedup_check "$log" "\"args_hash\":\"$args_hash\""; then
       :
     else
       bash "${CLAUDE_PLUGIN_ROOT}/lib/jsonl-emit.sh" skill-events \
         '{event:$event, skill:$skill, timestamp:$timestamp, repo_root:$repo_root, args_hash:$args_hash, payload:{root_cause:$rc, regression_test_path:$rt, investigation_phase_count:$count}}' \
         --arg event "fix_completed" \
         --arg skill "$skill_name" \
         --arg args_hash "$args_hash" \
         --arg rc "$ROOT_CAUSE" \
         --arg rt "$REGRESSION_TEST_PATH" \
         --argjson count "$PHASE_COUNT"
     fi
   fi
   ```

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

## Complex Bugs: Inline Plan Summary (no file written)

**For complex bugs, record a compact plan inline before any code change.** This section is consistent with the Slash-command Usage rule at the top of this skill: do NOT create `docs/plans/` folders or `BUGFIX_PLAN.md` files — the deliverable is still `the fix + a regression test`, never a planning document. The inline plan is the contract the skill holds itself to during Phase 2-4 and the audit surface the user reviews post-fix.

### When the Inline Plan Is Required

A bug requires the inline-plan step before edits when ANY of these apply:

- **Multi-component involvement** - Issue spans multiple files, modules, or subsystems
- **Architecture implications** - Fix may affect system design, contracts, or interfaces
- **Multiple potential approaches** - Several valid implementation paths exist
- **Side-effect risk** - Change could impact unrelated functionality
- **Requires refactoring** - Fix needs structural changes beyond minimal patch
- **Not fully understood** - After Phase 1 investigation, root cause is still unclear

### Inline Plan Format

After Phase 1 (Root Cause Investigation), record the plan **inline in your turn output** (not in a file) using this six-line shape, then proceed directly to Phase 2 with this plan as the contract:

```
ROOT CAUSE: <one-line summary from Phase 1 evidence>
FIX STRATEGY: <what change resolves the cause, in one sentence>
FILES: <comma-separated paths that will be modified>
TESTS: <regression test path(s) + scenario name>
RISKS: <one line — side effects, blast radius, or "low: localized to <subsystem>">
ALTERNATIVES: <one line — rejected approaches + why>
```

Do NOT pause for approval. The plan stays the contract through Phase 2-4; deviation requires re-running Phase 1 and re-recording a new six-line shape (do not silently mutate the fix mid-stream). If Phase 1 evidence is too thin to fill any of the six lines confidently, loop back to Phase 1 step 4 (Multi-component layered tracing) before recording the plan — never paper over weak evidence by writing a vague line.

### Why Inline (not BUGFIX_PLAN.md)

- The deliverable contract is "fix + regression test", not a planning artifact — a saved plan file would survive the bug fix in the repo as orphan documentation
- An inline summary keeps the contract visible in the same turn that applies it, so the executor (this skill) can re-check the six lines against the diff before committing
- Removes the wording conflict with the top-of-file rule "Do NOT write design documents or task files"

**For simple bugs:** Continue with Phase 2-4 directly — no inline plan needed.

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

## References

- `./references/root-cause-tracing.md` - Trace bugs backward through call stack to find original trigger
- `./references/defense-in-depth.md` - Add validation at multiple layers after finding root cause
- `./references/condition-based-waiting.md` - Replace arbitrary timeouts with condition polling
- `./references/condition-based-waiting-example.ts` - Example implementation of condition-based waiting
- `./find-polluter.sh` - Bisect test suite to identify which test pollutes shared state

**Related skills:**
- `superpowers:behavior-driven-development` - BDD principles including Gherkin scenarios for test design

## Real-World Impact

From debugging sessions:
- Systematic approach: 15-30 minutes to fix
- Random fixes approach: 2-3 hours of thrashing
- First-time fix rate: 95% vs 40%
- New bugs introduced: Near zero vs common