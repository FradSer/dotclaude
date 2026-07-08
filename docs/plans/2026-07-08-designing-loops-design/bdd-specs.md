# Designing Loops — BDD Specifications (v2, reference-file shape)

Canonical vocabulary: **turn-based loop, goal-based loop, time-based loop, proactive loop** (lowercase in prose); **primitive** (plain turn, `/goal`, `/loop`, `/schedule`, `Workflow`); never "autonomous loop". Requirement tags reference `_index.md`'s pivoted `REQ-NNN` set (round-1 numbering superseded). "Consults the loop-types reference" below means: Claude reads `superpowers/skills/references/loop-types.md`, having reached it via one of the pointer sentences (REQ-011–REQ-013) or a direct read.

## Traceability Notes (structural requirements not expressed as Given/When/Then)

- **REQ-001** (plain references file, no frontmatter/registration/README entry) — static shape; checked by `ls` + absence greps (`architecture.md` §1). Every scenario below exercises its content, not its loading mechanics — there are none, by design.
- **REQ-009** (stable-anchor citations, minimal verbatim quotes) — an authoring constraint over `loop-types.md`; checked by reading the finished file for line-number citations (must be zero). Its behavioral effect appears in the citation scenarios (Features 1, 4, 5), which all name sections, not line numbers.
- **REQ-010** (goal-wrapper Rule 3 exists) — structural: `grep -q "Rule 3" goal-wrapper.md`; behavioral effect exercised by the turn-cap scenario (Feature 2).
- **REQ-011/REQ-012/REQ-013** (7 pointer-sentence files) — static edits; `architecture.md` §3 anchors; verified by REQ-014's grep set.
- **REQ-014** (8-file grep verifiability), **REQ-015** (vocabulary gate), **REQ-016** (token-ceiling discipline on retrospective/writing-plans), **REQ-017** (~60-90 line size target) — verification-method and shape constraints; commands in `architecture.md` §4.

---

```gherkin
Feature: Loop-types reference — turn-based classification and quality gates
  So that trivial requests stay fast and non-trivial turn-based work is
  verified before Claude calls it done

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
  So that multi-turn work converges instead of running open-ended or
  stalling on an unverifiable condition

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

```gherkin
Feature: Loop-types reference — time-based classification (/loop)
  So that recurring checks run on a sane cadence without conflating native
  /loop with the plugin's deleted v2.x continuation runtime

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
  So that unattended recurring pipelines are composed correctly instead of
  being under-served by a single primitive

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
  So that loop recommendations reuse the plugin's existing quality/token
  mechanisms instead of re-deriving them

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
