---
name: systematic-debugging
description: Diagnoses a reported bug, error, test failure, or unexpected behavior through a 4-phase root-cause analysis before any code changes.
argument-hint: "<bug description or symptom>"
user-invocable: true
disable-model-invocation: true
allowed-tools: ["Read", "Grep", "Glob", "Edit", "Write", "Agent", "Bash(git:*)", "Bash(npm:*)", "Bash(pnpm:*)", "Bash(uv:*)", "Bash(pip:*)", "Bash(pytest:*)", "Bash(python:*)", "Bash(python3:*)", "Bash(go:*)", "Bash(cargo:*)", "Bash(mvn:*)", "Bash(gradle:*)", "Bash(rspec:*)", "Bash(bundle:*)", "Bash(test:*)", "Bash(${CLAUDE_PLUGIN_ROOT}/skills/systematic-debugging/find-polluter.sh:*)", "Bash(${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh:*)"]
---

# Systematic Debugging

## Slash-command Usage

Invoked via `/superpowers:systematic-debugging "<symptom>"` or auto-loaded by other skills when bug-fix language is detected.

**When invoked as a slash command**: capture `$ARGUMENTS` as the symptom statement and start at Phase 1 immediately. Do NOT write design documents or task files; the deliverable is `the fix + a test that catches the regression`, not a docs/plans/ folder.

**Output discipline**: Report findings inline as you complete each phase. End with: (a) root cause one-liner, (b) fix diff summary, (c) regression test path.

## Recommended: run wrapped in `/goal`

**Launch it under Claude Code's built-in `/goal`** (v2.1.139+) so the multi-turn hypothesis → test → fix investigation continues until the regression is actually fixed:

```
/goal "Claude has narrated the three-part completion output (root-cause one-liner, fix diff summary, regression-test path) with the regression test passing" /superpowers:systematic-debugging "<symptom>"
```

`/goal` is a **user-typed outer wrapper** (a skill cannot enable it for itself mid-run), and its evaluator judges only what Claude narrates in the transcript — phrase the condition against narrated output (the printed test-run result, the three-part summary), never filesystem state. Full semantics and condition phrasing: `../../skills/references/goal-wrapper.md`.

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

**Bail-out response (output verbatim, then apply the fix + a regression test that catches the bug):**

> Detected named root cause and named fix. Skipping the 4-phase pipeline (calibrated for unknown root causes). Applying the fix and writing a regression test directly. To force the full pipeline, re-invoke as `/superpowers:systematic-debugging --force "<symptom>"`.

When the user passes `--force` (literal token in `$ARGUMENTS`), skip this bail-out and proceed to Phase 1 unconditionally.

**Iron Law remains** for non-bail-out paths — the bail-out only fires when the user has *already done* the root-cause work and is handing Claude the conclusion.

## Overview

**Core principle:** Root cause investigation must precede any fix attempt — random fixes waste time, mask underlying issues, and create new bugs. **Violating the letter of this process is violating the spirit of debugging.**

## CRITICAL: The Iron Law

```
NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST
```

Fixes cannot be proposed without completing Phase 1. Each phase MUST finish before the next begins. Violating this rule produces fix-attempts that mask root causes — the failure mode this skill exists to prevent. If at any point you find yourself proposing a fix without completed Phase 1 evidence, stop and return to Phase 1.

## When to Apply

Applies to ANY technical issue: test failures, production bugs, unexpected behavior, performance problems, build failures.

**Especially valuable when:** time pressure tempts guessing, a "quick fix" seems obvious, prior fixes failed, or the issue is not fully understood.

Do NOT skip the process because the issue appears simple, time is tight, or urgency exists — see `./references/rationalizations-and-guardrails.md` for why each of those is a trap.

## The Four Phases

### Phase 1: Root Cause Investigation

**Before attempting any fix:**

0. **Consult Memory** — this memory read-before step is skipped whenever the Bail-Out Check fires (symmetric with the bail-out skipping every other Phase-1-onward step): run `bash "${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh" list --kind memory --status active`, filter by symptom keywords, and Read the top 2-3 matches before step 1.

1. **Read Error Messages Carefully** — read stack traces completely; note line numbers, file paths, error codes. Messages and warnings often contain the solution.

2. **Reproduce Consistently** — identify exact steps and confirm the issue triggers reliably. If not reproducible, gather more data instead of guessing.

3. **Check Recent Changes** — git diff and recent commits, new dependencies, config changes, environmental differences.

4. **Gather Evidence in Multi-Component Systems** (CI -> build -> signing, API -> service -> database) — add diagnostic instrumentation before proposing fixes:
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

   Worked example (CI workflow → build → signing): `./references/root-cause-tracing.md` §Multi-Layer Instrumentation Example.

5. **Trace Data Flow** — when the error is deep in the call stack: identify where the bad value originates, determine what called it, keep tracing up until the source is found, fix at source not at symptom. Complete backward-tracing technique: `./references/root-cause-tracing.md`.

### Phase 2: Pattern Analysis

**Pattern identification should precede any fix:**

1. **Find Working Examples** — locate similar working code in the same codebase.
2. **Compare Against References** — if implementing a pattern, read the reference implementation completely (every line, do not skim) before applying it.
3. **Identify Differences** — list every difference between working and broken code; do not dismiss small differences as irrelevant.
4. **Understand Dependencies** — other components this operation requires; settings, config, environment; assumptions made by the pattern.

### Phase 3: Hypothesis and Testing

**Scientific method application:**

1. **Form Single Hypothesis** — state clearly and specifically: "X is the root cause because Y".
2. **Test Minimally** — smallest possible change, one variable at a time; do not fix multiple things simultaneously.
3. **Verify Before Continuing** — confirmed: proceed to Phase 4; not confirmed: form a new hypothesis. Do not add more fixes on top.
4. **When Understanding is Missing** — acknowledge it, research more, ask for help.

### Phase 4: Implementation

**Fix the root cause, not the symptom:**

1. **Create Failing Test Case** — simplest possible reproduction; automated test if possible, one-off script if no framework. The test must exist before fixing.
2. **Implement Single Fix** — address the identified root cause, one change at a time; no "while I'm here" improvements, no bundled refactoring.
3. **Verify Fix** — test now passes? No other tests broken? Issue actually resolved?
4. **If Fix Doesn't Work** — stop and count attempted fixes. If < 3: return to Phase 1 and re-analyze with the new information. If >= 3: question the architecture.
5. **Architecture Questioning After 3+ Failed Fixes** — when each fix reveals a new shared-state/coupling problem elsewhere, requires "massive refactoring", or creates new symptoms, stop and question fundamentals: is the pattern sound? Is the approach continuing through inertia? Should the architecture be refactored instead of fixing symptoms? **Discuss with your human partner before attempting more fixes** — this is not a failed hypothesis, this is wrong architecture.

6. **Capture Memory (conditional — this skill's only `docs/` touchpoint, not a new phase or commit)**

   This step reuses the existing 3+ failed fixes trigger as its primary gate: firing that trigger runs upsert memory in the same commit as the fix, OR it fires independently on an explicit cross-cutting gotcha regardless of fix-attempt count; otherwise it is a no-op.

   On fire: write `docs/memory/<category>_<slug>.md` (`category: pitfall` typically; `decision` if architecture questioning concluded a redesign), reusing the Inline Plan's six-line shape as `Fact`/`Why` material with `source: commit:<short-sha>`. Then run `bash "${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh" upsert memory docs/memory/<path> --status active --summary "<one-line>" --category <category>`, staged into the same commit as the fix + regression test — no separate commit, no extra deliverable.

## Complex Bugs: Inline Plan Summary (no file written)

**For complex bugs, record a compact plan inline before any code change** — never a `docs/plans/` folder or `BUGFIX_PLAN.md` file (rationale: `./references/rationalizations-and-guardrails.md` §Why the Complex-Bug Plan Is Inline). The inline plan is the contract the skill holds itself to during Phase 2-4 and the audit surface the user reviews post-fix.

### When the Inline Plan Is Required

A bug requires the inline-plan step before edits when ANY of these apply: multi-component involvement (multiple files/modules/subsystems), architecture implications (design, contracts, interfaces), multiple valid approaches, side-effect risk to unrelated functionality, refactoring beyond a minimal patch, or a root cause still unclear after Phase 1.

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

Do NOT pause for approval. The plan stays the contract through Phase 2-4; deviation requires re-running Phase 1 and recording a new six-line shape — do not silently mutate the fix mid-stream. If evidence is too thin to fill any line confidently, loop back to Phase 1 step 4 first; never paper over weak evidence with a vague line.

**For simple bugs:** Continue with Phase 2-4 directly — no inline plan needed.

## Red Flags

These mental patterns indicate process violation — return to Phase 1:
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

**When the human partner redirects you** ("Is that not happening?", "Stop guessing", "We're stuck?"): return to Phase 1. Full signal list, plus the excuse-vs-reality table for every rationalization above: `./references/rationalizations-and-guardrails.md`.

## Quick Reference

| Phase | Key Activities | Success Criteria |
|-------|---------------|------------------|
| **1. Root Cause** | Read errors, reproduce, check changes, gather evidence | Understand WHAT and WHY |
| **2. Pattern** | Find working examples, compare | Identify differences |
| **3. Hypothesis** | Form theory, test minimally | Confirmed or new hypothesis |
| **4. Implementation** | Create test, fix, verify | Bug resolved, tests pass |

## When Process Reveals No Root Cause

If systematic investigation reveals the issue is environmental, timing-dependent, or external: the process is complete — document what was investigated, implement appropriate handling (retry, timeout, error message), and add monitoring/logging for future investigation. **Note:** 95% of "no root cause" cases represent incomplete investigation.

## References

- `./references/root-cause-tracing.md` - Backward tracing, multi-layer instrumentation example
- `./references/rationalizations-and-guardrails.md` - Excuse table, partner signals, inline-plan rationale, impact numbers
- `./references/defense-in-depth.md` - Add validation at multiple layers after finding root cause
- `./references/condition-based-waiting.md` - Replace arbitrary timeouts with condition polling (example: `condition-based-waiting-example.ts`)
- `./find-polluter.sh` - Bisect test suite to identify which test pollutes shared state
- `../../skills/references/goal-wrapper.md` - `/goal` semantics and condition phrasing (shared)

**Related skills:**
- `superpowers:behavior-driven-development` - BDD principles including Gherkin scenarios for test design