# Task 001: loop-types.md reference + goal-wrapper Rule 3

**depends-on**: (none — foundation task)

## Description

Create the new advisory reference file `superpowers/skills/references/loop-types.md` (plain markdown, no frontmatter/registration/README entry), and add `## Rule 3 — pair the condition with an explicit turn cap for open-ended work` to `superpowers/skills/references/goal-wrapper.md` between Rule 2's table and `## Recommended conditions per skill`. The Rule 3 insertion closes with a pointer to `./loop-types.md`, which doubles as `goal-wrapper.md`'s REQ-014 grep witness. This is the foundation task — every pointer-sentence task (002-004) depends on the file existing to point at.

## Execution Context

**Task Number**: 001 of 005
**Phase**: Foundation
**Prerequisites**: None.

## BDD Scenario

This task carries all 20 content scenarios from Features 1-5 inline — they exercise the *content* of `loop-types.md` itself (its sections, citations, and the classification table) plus the turn-cap scenario that exercises Rule 3. Tasks 002-004 carry the structural reachability REQs (REQ-011/REQ-012/REQ-013) whose behavioral effect is exercised by these same 20 scenarios; task 005 is the cross-cutting verification harness for REQ-014/REQ-015/REQ-016/REQ-017.

```gherkin
Feature: Loop-types reference — turn-based classification and quality gates

  Scenario: Trivial one-off request stays turn-based, no primitive recommended (REQ-005)
    Given a user asks Claude to rename the variable "tmp" to "retryCount" in auth.ts
    And the request names a single file and a single mechanical change
    When Claude consults the loop-types reference
    Then Claude classifies the request as turn-based
    And Claude does not recommend /goal, /loop, or /schedule
    And Claude proceeds directly with the edit, per the reference's own
      stay-out-of-the-way rule mirroring the plugin-wide Bail-Out philosophy

  Scenario: Open-ended single-session question stays turn-based (REQ-002, REQ-005)
    Given a user asks "what's the tradeoff between REST and GraphQL for our
      internal admin dashboard?"
    And the request has no multi-step deliverable and no completion condition
    When Claude consults the loop-types reference
    Then Claude classifies the request as turn-based (exactly one of the four types)
    And Claude judges for itself when the answer is complete
    And Claude does not introduce /goal machinery

  Scenario: Self-check before claiming done on non-trivial turn-based work (REQ-005, REQ-007)
    Given a user asks Claude to fix the null-pointer crash in PaymentProcessor.charge()
    And Claude has written a change spanning two files
    When Claude is about to report the fix complete
    Then the loop-types reference's turn-based section directs Claude to the
      verification-before-completion skill's Iron Law gate (cited by skill
      name and section, not restated)
    And Claude pastes fresh verification output (exit code, test result)
      before stating the fix works

  Scenario: Second-agent review routed via existing skills (REQ-005, REQ-007)
    Given a user asks Claude to review a 3-file business-logic diff for
      correctness before merging
    When Claude consults the loop-types reference for the quality mechanism
    Then Claude cites the receiving-code-review skill's rigor-over-agreement
      discipline and the superpowers-evaluator agent as the independent
      second reviewer (inside the superpowers pipeline)
    And outside that pipeline, Claude states a genuinely independent second
      opinion requires a separate agent or session
```

```gherkin
Feature: Loop-types reference — goal-based classification (/goal)

  Scenario: Multi-step task with clear success criterion is goal-based (REQ-002, REQ-006)
    Given a user asks Claude to migrate the users table's email column to
      case-insensitive-unique, update the ORM model, and confirm the signup
      tests still pass
    When Claude consults the loop-types reference
    Then Claude classifies the request as goal-based
    And Claude names /goal "<condition>" <task> as the primitive
    And Claude phrases the condition against narrated transcript content
      ("the signup test suite printed 0 failures"), per the goal-wrapper
      reference's Rule 2, cited not restated

  Scenario: Vague completion condition is concretized before /goal (REQ-002, REQ-006)
    Given a user asks Claude to keep improving the onboarding flow until it
      feels good
    When Claude consults the loop-types reference
    Then Claude does not pass the vague phrase verbatim as the condition
    And Claude proposes a narratable substitute ("onboarding completion rate
      reaches 90% across 3 consecutive dry runs, narrated per run") and asks
      the user to confirm before /goal is invoked
```

```gherkin
Feature: Loop-types reference — time-based classification (/loop)

  Scenario: Recurring maintenance task is time-based and names /loop (REQ-002, REQ-003)
    Given a user asks Claude to check PR #482 every 5 minutes and report
      when CI goes green
    When Claude consults the loop-types reference
    Then Claude classifies the request as time-based
    And Claude names the concrete command /loop 5m "check PR #482 CI status
      and report when it's green"
    And Claude does not recommend /goal or /schedule for this session-scoped
      polling request

  Scenario: Flaky-test reproduction is a time-based loop, the fix is systematic-debugging (REQ-003, REQ-011)
    Given a user asks Claude to fix a CI test that fails intermittently, by
      first re-running it until the failure is captured
    When Claude consults the loop-types reference
    Then Claude classifies the reproduction phase as time-based and names
      /loop "re-run test_checkout_retry until it fails, then capture the
      failure output"
    And Claude routes the follow-on root-cause fix to
      /superpowers:systematic-debugging once a failure is captured, matching
      the pointer that skill's "When Process Reveals No Root Cause" section
      carries back to this reference

  Scenario: Native /loop is never conflated with the deleted v2.x runtime (REQ-003)
    Given a user or future maintainer asks what "the loop" in superpowers refers to
    When the loop-types reference's time-based section is consulted
    Then Claude states the native /loop command (session-level, still active)
      is unrelated to the plugin's deleted lib/loop.sh Stop-hook continuation
      runtime (removed in v3.0.0, replaced by native /goal)
    And Claude names either "native /loop" or "the removed v2.x continuation
      runtime" explicitly, never the bare ambiguous word

  Scenario: Polling interval matches actual change frequency (REQ-008)
    Given a user asks Claude to watch a nightly batch job log that runs once
      every 24 hours and alert on failure
    When Claude consults the loop-types reference for a /loop recommendation
    Then Claude does not default to a short interval such as 5m
    And Claude sizes the interval to the job's run window (e.g. /loop 30m
      scoped around the known window), per the reference's interval-matching
      guidance
```

```gherkin
Feature: Loop-types reference — proactive classification (/schedule + /goal + Workflow + auto mode)

  Scenario: Unattended recurring pipeline is proactive and names the composition (REQ-002, REQ-004)
    Given a user asks Claude to triage every bug report in the #feedback
      channel hourly — categorize, file new GitHub issues, never ask approval
    When Claude consults the loop-types reference
    Then Claude classifies the request as proactive
    And Claude names /schedule for the hourly trigger, /goal "this hour's
      triage pass is complete and new issues are filed" per invocation, and
      auto mode for unattended permissions
    And Claude states each invocation exits when its own goal is met while
      the schedule keeps firing until the user disables it

  Scenario: The superpowers chain is cited as a partial worked example (REQ-004)
    Given Claude is explaining what a proactive setup looks like inside this plugin
    When the loop-types reference's proactive section is consulted
    Then Claude cites the brainstorming to writing-plans to executing-plans
      to retrospective chain, each stage individually /goal-wrapped, as the
      closest existing partial example
    And Claude notes the chain is not itself proactive today — each stage
      still needs a user-typed /goal wrapper per invocation

  Scenario: Workflow is only composed in with explicit opt-in (REQ-004, REQ-008)
    Given a proactive routine's hourly pass would benefit from fanning out
      30 independent triage sub-tasks
    When Claude consults the loop-types reference before recommending Workflow
    Then Claude follows the citation to workflow-orchestration.md Rule 2 —
      user must opt in — before adding Workflow to the composition
    And Claude surfaces the opt-in requirement as an explicit line rather
      than silently folding Workflow into the /schedule + /goal recommendation

  Scenario: Each proactive task exits on its goal; the routine outlives it (REQ-002)
    Given an active hourly /schedule + /goal triage routine
    When one hour's invocation finishes triaging that hour's messages
    Then that invocation's /goal condition is satisfied and it exits
    And the /schedule trigger stays active for the next hour until the user
      explicitly disables it
```

```gherkin
Feature: Loop-types reference — quality and token discipline when recommending a loop

  Scenario: Cheapest sufficient primitive and model tier despite unconstrained budget (REQ-008)
    Given a user says budget is no constraint and asks for a batch-job
      monitor doing mechanical log-grepping every 15 minutes
    When Claude consults the loop-types reference
    Then Claude still recommends native /loop 15m, not /schedule + /goal +
      Workflow, for work with no multi-step completion criterion
    And any sub-agent dispatch declares an explicit cheap model tier (e.g.
      haiku for a mechanical sweep), following the reference's citation of
      executing-plans' model-declaration CRITICAL discipline

  Scenario: Existing skills and scripts are cited, not re-derived (REQ-007, REQ-008, REQ-009)
    Given Claude is drafting loop guidance touching verification, review,
      and checklist-evolution concerns
    When the loop-types reference's citation map is consulted
    Then Claude cites verification-before-completion, receiving-code-review
      plus the superpowers-evaluator agent, and retrospective's checklist
      evolution — each by skill/agent name and section, never by line number
    And for deterministic work inside a loop, Claude cites the plugin's
      lib scripts (task-ledger.sh, docs-index.sh, seed-checklists.sh) as the
      script-over-re-derived-reasoning pattern

  Scenario: Pilot before a large proactive batch (REQ-008)
    Given a user asks for a proactive routine reprocessing all 40 open
      support tickets nightly
    When Claude consults the loop-types reference for rollout staging
    Then Claude recommends piloting on 3-5 tickets first, citing
      workflow-orchestration.md Rule 3's >4-independent-task threshold as
      where unpiloted fan-out risk becomes material
    And only after the pilot does Claude enable the full nightly schedule

  Scenario: Periodic usage review for an active routine (REQ-008)
    Given a user has just enabled an unattended /schedule + /goal routine
    When Claude consults the loop-types reference for ongoing maintenance
    Then Claude recommends periodically checking /usage, /goal with no
      arguments, and /workflows as the native monitoring commands
    And Claude presents this as a user recommendation, since the reference
      file has no standing mechanism to run anything itself
```

The turn-cap scenario from Feature 2 exercises the Rule 3 addition (carried here because Rule 3 is part of this task):

```gherkin
  Scenario: Explicit turn cap accompanies the condition for open-ended work (REQ-006, REQ-010)
    Given a user asks Claude to get the flaky test_checkout_retry test passing
    And the underlying cause is not yet known
    When Claude consults the loop-types reference for a goal-based recommendation
    Then Claude recommends /goal "the regression test for test_checkout_retry
      has passed 5 consecutive runs" (stop after 5 tries)
      /superpowers:systematic-debugging "test_checkout_retry is flaky"
    And Claude cites goal-wrapper.md Rule 3 for the turn-cap mechanics
      rather than restating them

  Scenario: Filesystem-state conditions are rewritten as narration (REQ-006)
    Given Claude is drafting a /goal condition for a multi-step refactor
    When the loop-types reference points Claude at goal-wrapper.md Rule 2's
      verifiable/unverifiable table
    Then Claude rejects "_index.md exists" and "status=completed" as
      unverifiable filesystem state
    And Claude rewrites the condition as a narrated equivalent ("Claude has
      stated the refactor is complete and printed the final diff summary")
```

**Spec Source**: `../2026-07-08-designing-loops-design/bdd-specs.md` (for reference)

## Interfaces

**Exposes** (interfaces this task produces):
- File: `superpowers/skills/references/loop-types.md` — plain markdown, no frontmatter. Section anchors (cited by pointer-sentence tasks 002-004 by relative path, not by line number): `# Turn-based`, `# Goal-based`, `# Time-based`, `# Proactive`, `# Quality and token discipline in loops`. Contains the 4-row classification table (REQ-002) as its first content block after the intro sentence.
- File edit: `superpowers/skills/references/goal-wrapper.md` gains `## Rule 3 — pair the condition with an explicit turn cap for open-ended work` between Rule 2's table and `## Recommended conditions per skill`; the Rule 3 block closes with a pointer `./loop-types.md` (REQ-010, and REQ-014 grep witness for this file).

**Consumes** (interfaces from `depends-on` tasks this task relies on):
- None (foundation task). References sibling files by relative path: `./goal-wrapper.md` (Rules 2 and now 3), `./workflow-orchestration.md` (Rules 2 and 3), and the cited skills/agents by name.

**Global Constraints respected**: REQ-001 (plain file shape), REQ-009 (stable-anchor citations, no bare line numbers), REQ-015 (no "autonomous loop"), REQ-017 (60-90 lines), REQ-016 (this task does NOT touch `retrospective`/`writing-plans` SKILL.md — those are task 002).

## Files to Modify/Create

- Create: `superpowers/skills/references/loop-types.md` (~60-90 lines; skeleton in `architecture.md` §1)
- Modify: `superpowers/skills/references/goal-wrapper.md` — insert Rule 3 block between Rule 2's table (ends ~line 28) and `## Recommended conditions per skill` (~line 30); exact text in `architecture.md` §2

## Steps

### Step 1: Create loop-types.md
- Create `superpowers/skills/references/loop-types.md` following the skeleton in `architecture.md` §1: intro sentence (incl. stay-out-of-the-way rule for trivial work), the 4-row classification table, then the five `##` sections.
- Turn-based section (REQ-005): cite `verification-before-completion` (self-judged stopping, Iron Law gate) and `receiving-code-review` + the `superpowers-evaluator` agent (second-agent review) by skill/agent name and section; state trivial single-turn work needs no classification.
- Goal-based section (REQ-006): cite `./goal-wrapper.md` including Rule 3; zero original goal-based content.
- Time-based section (REQ-003, REQ-008): ORIGINAL content — native `/loop` and `/schedule` as Claude Code commands not shipped by this plugin; explicit disambiguation from the deleted v2.x `lib/loop.sh` runtime (removed v3.0.0, replaced by native `/goal`); interval-matching guidance (size to actual change frequency, do not default to 5m).
- Proactive section (REQ-004): cite `./workflow-orchestration.md` Rule 2 (opt-in) and Rule 3 (>4-task threshold); cite the brainstorming→writing-plans→executing-plans→retrospective chain as a partial worked example (each stage `/goal`-wrapped today, not yet composed under an outer `/schedule`); do not reproduce Workflow mechanics.
- Quality and token discipline section (REQ-007, REQ-008): citation map — `verification-before-completion`, `receiving-code-review` + evaluator, BDD Iron Law, retrospective Phase 3 checklist evolution, model-declaration CRITICAL (`executing-plans`), Bail-Out Check, `workflow-orchestration.md` >4-task threshold, `lib/*.sh` script-over-reasoning pattern; plus the two genuinely-new items (interval matching; periodic `/usage`//`/goal`//`/workflows` review).

### Step 2: Add Rule 3 to goal-wrapper.md
- Insert the `## Rule 3` block between Rule 2's table and `## Recommended conditions per skill` per `architecture.md` §2 (exact text provided there).
- Ensure the block closes with a pointer to `./loop-types.md` — this is this file's REQ-014 grep witness.

### Step 3: Self-verify content constraints
- Confirm no bare line-number citations (REQ-009): `grep -nE ':[0-9]+' superpowers/skills/references/loop-types.md` should return nothing (citations use section/rule names).
- Confirm no "autonomous loop" (REQ-015): `grep -ri "autonomous loop" superpowers/skills/references/loop-types.md superpowers/skills/references/goal-wrapper.md` returns nothing.
- Confirm Rule 3 present: `grep -q "Rule 3" superpowers/skills/references/goal-wrapper.md && echo RULE3-OK`.
- Confirm line count in target range (REQ-017): `wc -l superpowers/skills/references/loop-types.md` (target 60-90; treat as soft target — do not pad or trim solely to hit a number).

## Verification Commands

```bash
# Rule 3 content present (REQ-010)
grep -q "Rule 3" superpowers/skills/references/goal-wrapper.md && echo RULE3-OK
# No bare line-number citations (REQ-009)
! grep -nE 'line [0-9]+|:[0-9]+' superpowers/skills/references/loop-types.md && echo NO-BARE-LINES
# Vocabulary gate on the two files this task touches (REQ-015)
! grep -ri "autonomous loop" superpowers/skills/references/loop-types.md superpowers/skills/references/goal-wrapper.md && echo VOCAB-OK
# Size target (REQ-017)
wc -l superpowers/skills/references/loop-types.md
# Validator still exit 0 (this task touches no SKILL.md, so ceiling unaffected — sanity only)
python3 plugin-optimizer/scripts/validate-plugin.py superpowers
```

## Success Criteria

- `loop-types.md` exists with no frontmatter, no `plugin.json` registration, no README entry (REQ-001).
- The 4-row table and five sections present (REQ-002 through REQ-008).
- `goal-wrapper.md` Rule 3 block present and closes with a `./loop-types.md` pointer (REQ-010, REQ-014 witness).
- No bare line-number citations; no "autonomous loop"; validator exit 0.
