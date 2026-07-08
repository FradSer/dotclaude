# Designing Loops — BDD Specifications

Canonical vocabulary used throughout: **turn-based loop, goal-based loop, time-based loop, proactive loop** (lowercase in prose, Title Case only in `Feature:` titles — mirroring the blog's own header/body casing split); **primitive** (the set: plain turn, `/goal`, `/loop`, `/schedule`, `Workflow`); **proactive loop**, never "autonomous loop" (rejected — collides with Claude Code's unrelated "auto mode" and this repo's own pre-existing generic use of "autonomous"). See `_index.md` Glossary for full rationale, including the requirement-ID-format reconciliation this file's tags were retargeted against.

## Traceability Notes (structural/non-functional requirements not expressed as Given/When/Then)

The requirements below are architecture decisions or blanket non-functional constraints, not runtime behaviors a Gherkin scenario observes — each is fully specified in `_index.md`/`architecture.md` and cross-referenced here rather than re-stated as a scenario:

- **REQ-001** (register `designing-loops` under `plugin.json`'s `"skills"` array, `user-invocable: false`) and **REQ-002** (description carries concrete trigger phrases) — the registration/frontmatter shape itself; exercised indirectly by every scenario below, each of which opens with "When Claude consults designing-loops" — the skill loading at all in response to loop-shaped language is REQ-002's own trigger mechanism in action. See `architecture.md` §2.
- **REQ-013** (`using-superpowers/SKILL.md` gets a "which skill vs. how to run it" section, not a routing-table row) — a structural edit to a different skill's file, verified by the absence of `designing-loops` in the routing table itself and its presence in the new section. See `architecture.md` §3.1.
- **REQ-014** (five user-invocable skills' `/goal` sections each get one added cross-link sentence) — a structural edit, not a behavior this file's scenarios exercise directly; each target skill's own existing BDD/behavior surface is unchanged by the addition of a pointer sentence. See `architecture.md` §3.2.
- **REQ-015** (retrospective's time-based/proactive note, merged into the REQ-014 edit for that file) — same structural class as REQ-014. See `architecture.md` §3.2.
- **REQ-017** (`workflow-orchestration.md` gets one "See also" line) and **REQ-018** (`README.md` gets a new `### Designing Loops` subsection plus backfill of two pre-existing undocumented entries) — both are static file-content additions with no runtime behavior to assert. See `architecture.md` §3.4-3.5.
- **REQ-019** (all 7 cross-link points are independently grep-verifiable) — a verification-method requirement, not a behavior; its own check method (`grep -l designing-loops <file>` per target) is the assertion. See `architecture.md` §5.
- **REQ-012** (every load-bearing classification rule carries an explicit `CRITICAL:` block in the L2 `SKILL.md` body, never left to L3-only or soft wording) — a documentation-authoring constraint on how the skill's own content is written, not a runtime behavior a conversation exercises; checked by reading the finished `SKILL.md` for `CRITICAL:` blocks around the four-way classification, the trivial-work bail-out (REQ-008), and the citation-not-duplication constraint (REQ-009/REQ-010), per the precedent already set by every other skill's own Bail-Out Check / Iron Law blocks.
- **REQ-020** (SKILL.md L2 body stays under ~5k tokens) and **REQ-021** (naming/directory convention compliance) — static shape constraints, checked by `plugin-optimizer/scripts/validate-plugin.py` and directory-listing inspection respectively, not by a conversational Given/When/Then.
- **REQ-022** (Glossary term fidelity, "autonomous loop" never introduced) — a lexical constraint over the finished skill content, checked by `grep -ri "autonomous loop" superpowers/skills/designing-loops/` returning zero matches (see `_index.md` Risks), not a runtime behavior.

---

```gherkin
Feature: Designing-loops — turn-based loop classification and quality gates
  As a Claude Code skill classifying an incoming task
  I want to recognize turn-based work and stay out of the way for trivial cases,
    while applying the existing self-check and second-agent-review gates for
    non-trivial turn-based work
  So that trivial requests stay fast and non-trivial turn-based work still gets
    verified before Claude calls it done

  Scenario: Trivial one-off request stays turn-based and no loop primitive is recommended (REQ-008)
    Given a user asks Claude to rename the variable "tmp" to "retryCount" in
      auth.ts
    And the request names a single file and a single mechanical change
    When Claude consults designing-loops before responding
    Then Claude classifies the request as turn-based
    And Claude does not recommend /goal, /loop, or /schedule
    And Claude proceeds directly with the edit, mirroring the Bail-Out Check
      pattern already used by superpowers/skills/brainstorming/SKILL.md
      ("## CRITICAL: Bail-Out Check (run before Initialization)") and
      superpowers/skills/systematic-debugging/SKILL.md ("## CRITICAL:
      Bail-Out Check (run before Phase 1)")

  Scenario: Open-ended single-session question stays turn-based with no loop primitive named (REQ-003, REQ-008)
    Given a user asks "what's the tradeoff between REST and GraphQL for our
      internal admin dashboard?"
    And the request has no multi-step deliverable and no explicit completion
      condition
    When Claude consults designing-loops
    Then Claude classifies the request as turn-based
    And Claude judges for itself when the answer is complete, per the "Claude
      judges when it's done" definition of turn-based loops
    And Claude does not introduce /goal's completion-condition machinery for
      a request with no multi-step deliverable to gate

  Scenario: Claude self-checks a non-trivial turn-based code change before claiming done (REQ-004, REQ-009)
    Given a user asks Claude to fix the null-pointer crash in
      PaymentProcessor.charge()
    And Claude has written a code change spanning two files
    When Claude is about to report the fix as complete
    Then designing-loops directs Claude to the Iron Law gate in
      superpowers/skills/verification-before-completion/SKILL.md ("NO
      COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE") before the
      completion claim
    And Claude pastes the fresh verification command output (exit code, test
      result) into its response before stating the fix works

  Scenario: Claude routes to second-agent review for non-trivial turn-based code review requests (REQ-004, REQ-009)
    Given a user asks Claude to review a diff touching business logic across
      3 files for correctness before merging
    When Claude consults designing-loops for the applicable quality mechanism
    Then Claude cites superpowers/skills/receiving-code-review/SKILL.md's
      technical-rigor-over-agreement discipline for handling any review
      findings
    And, inside the superpowers design/plan pipeline, Claude cites
      superpowers/agents/superpowers-evaluator.md as the independent,
      read-only second-agent reviewer rather than inventing an ad hoc review
      checklist
    And outside that pipeline, Claude states plainly that a genuinely
      independent second opinion requires a separate agent or session, not a
      self-review inside the same turn
```

```gherkin
Feature: Designing-loops — goal-based loop classification (/goal)
  As a Claude Code skill classifying an incoming task
  I want to recognize multi-step work with explicit or derivable completion
    criteria and recommend /goal with a concrete, transcript-verifiable
    condition and an explicit turn cap
  So that multi-turn work converges instead of running open-ended or
    stalling on an unverifiable condition

  Scenario: Multi-step task with a clear success criterion classifies as goal-based (REQ-003, REQ-005)
    Given a user asks Claude to migrate the users table's email column to be
      case-insensitive-unique, update the ORM model, and confirm the
      existing signup tests still pass
    And the request has 3 sequential steps and one final acceptance check
    When Claude consults designing-loops
    Then Claude classifies the request as goal-based
    And Claude names the primitive as /goal "<condition>" <task>
    And Claude phrases <condition> against something Claude will narrate in
      the transcript ("the migration ran, the model was updated, and the
      signup test suite printed 0 failures"), not a filesystem check

  Scenario: Task lacking an explicit completion condition — Claude derives one before recommending /goal (REQ-003, REQ-005)
    Given a user asks Claude to keep improving the onboarding flow until it
      feels good
    And the request has no explicit, checkable success criterion
    When Claude consults designing-loops
    Then Claude does not recommend /goal with the user's phrase used
      verbatim as the condition
    And Claude proposes a concrete, narratable substitute condition (e.g.
      "onboarding completion rate in the test harness reaches 90% across 3
      consecutive dry runs, narrated per run") and asks the user to confirm
      it before /goal is invoked

  Scenario: Claude names an explicit turn cap alongside the completion condition (REQ-023)
    Given a user asks Claude to get the flaky test_checkout_retry test
      passing
    And the underlying cause is not yet known
    When Claude consults designing-loops for a goal-based recommendation
    Then Claude recommends /goal "the regression test for
      test_checkout_retry has passed 5 consecutive runs" (stop after 5
      tries) /superpowers:systematic-debugging "test_checkout_retry is
      flaky"
    And Claude names an explicit turn cap in addition to the completion
      condition
    And Claude notes this turn-cap phrasing is original content because
      superpowers/skills/references/goal-wrapper.md documents only condition
      phrasing (its Rule 2 table) — flagged as a gap for goal-wrapper.md to
      close later, not silently reinvented per-skill

  Scenario: Goal-based recommendation always phrases the condition for narration, never filesystem state (REQ-005)
    Given Claude is drafting a /goal condition for a multi-step refactor task
    When designing-loops checks the drafted condition against
      superpowers/skills/references/goal-wrapper.md's Rule 2
      verifiable/unverifiable table
    Then Claude rejects a condition phrased as "_index.md exists" or
      "status=completed" as unverifiable filesystem state
    And Claude rewrites it as a narrated equivalent ("Claude has stated the
      refactor is complete and printed the final diff summary")
```

```gherkin
Feature: Designing-loops — time-based loop classification (/loop)
  As a Claude Code skill classifying an incoming task
  I want to recognize recurring, interval-driven polling or maintenance work
    and recommend the native /loop command with a concrete example and an
    interval matched to real change frequency
  So that recurring checks run on a sane cadence without conflating /loop
    with the plugin's own deleted v2.x continuation runtime

  Scenario: Recurring maintenance task classifies as time-based and names /loop (REQ-003, REQ-006)
    Given a user asks Claude to check PR #482 every 5 minutes and report when
      CI goes green
    When Claude consults designing-loops
    Then Claude classifies the request as time-based
    And Claude names the concrete command /loop 5m "check PR #482 CI status
      and report when it's green"
    And Claude does not recommend /goal or /schedule for this session-scoped,
      interval-driven polling request

  Scenario: Flaky, intermittently-failing CI test classifies as time-based with a concrete example command (REQ-006, REQ-016)
    Given a user asks Claude to fix a CI test that fails intermittently
      across runs, by first re-running it until it fails so the failure can
      be captured
    When Claude consults designing-loops
    Then Claude classifies the reproduction phase as a time-based loop
      candidate
    And Claude names the concrete example /loop "re-run test_checkout_retry
      until it fails, then capture the failure output"
    And Claude routes the follow-on root-cause fix, once a failure is
      captured, to /superpowers:systematic-debugging separately from the
      reproduction-phase time-based loop

  Scenario: Time-based classification never conflates native /loop with the deleted v2.x loop.sh runtime (REQ-006)
    Given a user or a future skill maintainer asks what "the loop" in
      superpowers refers to
    When designing-loops is consulted to explain time-based primitives
    Then Claude states that the native /loop command (session-level,
      recurring-interval, still active) is unrelated to the plugin's own
      deleted lib/loop.sh Stop-hook continuation runtime (removed in v3.0.0
      per README.md's "Removed in v3.0.0" note, replaced by native /goal for
      multi-turn continuation within a single skill run)
    And Claude never uses the word "loop" ambiguously between the two when
      discussing time-based classification — it names either "native /loop"
      or "the removed v2.x continuation runtime" explicitly

  Scenario: Polling interval is matched to actual change frequency, not a default cadence (REQ-011)
    Given a user asks Claude to watch the nightly batch job log and alert on
      failure, where the job runs once every 24 hours
    When Claude consults designing-loops for a /loop recommendation
    Then Claude does not default to a short interval such as 5m
    And Claude recommends an interval sized to the job's actual run window
      (e.g. /loop 30m "check whether tonight's batch job log shows a
      failure"), citing this as original guidance with no existing in-repo
      mechanism to defer to
```

```gherkin
Feature: Designing-loops — proactive loop classification (/schedule + /goal + Workflow + auto mode)
  As a Claude Code skill classifying an incoming task
  I want to recognize genuinely unattended, recurring, no-human-in-the-loop
    work and recommend the composed primitive set, with each task exiting on
    its own goal while the routine itself runs until turned off
  So that fully autonomous recurring pipelines are set up correctly instead
    of being under-served by a single primitive

  Scenario: Unattended recurring pipeline classifies as proactive and names the composed primitive set (REQ-003, REQ-007)
    Given a user asks Claude to triage every bug report in the #feedback
      channel hourly — categorize it, file a GitHub issue if it's new, and
      never ask for approval
    When Claude consults designing-loops
    Then Claude classifies the request as proactive
    And Claude names the composed setup: /schedule for the hourly cron
      trigger, /goal "the triage pass for this hour's messages is complete
      and any new issues are filed" wrapping each hourly invocation, and
      auto mode so no approval prompt blocks the unattended run
    And Claude states each hourly invocation exits when its own goal is met,
      while the schedule itself keeps firing until the user turns it off

  Scenario: Proactive composition cites the existing brainstorming-to-retrospective chain as a worked example (REQ-007)
    Given Claude is explaining what a fully proactive setup looks like
      inside this plugin
    When designing-loops is consulted for a concrete precedent
    Then Claude cites the superpowers brainstorming to writing-plans to
      executing-plans to retrospective chain, each individually
      /goal-wrapped per skill, as a partial worked example of composed
      goal-based stages
    And Claude notes this chain is not itself proactive today — each stage
      still needs a user-typed /goal wrapper per invocation — citing it as
      the closest existing partial example, not a fully unattended routine

  Scenario: Proactive recommendation respects Workflow's opt-in-only rule (REQ-007, REQ-010)
    Given a proactive routine's per-invocation work would benefit from
      fanning out many independent sub-tasks, such as triaging 30 feedback
      messages in one hourly pass
    When Claude consults designing-loops before recommending the native
      Workflow tool as part of the composition
    Then Claude checks superpowers/skills/references/workflow-orchestration.md
      Rule 2 before recommending Workflow: it may be used only when the user
      has explicitly opted into multi-agent orchestration
    And Claude does not fold Workflow into a proactive /schedule + /goal
      recommendation without surfacing the opt-in requirement as an explicit
      line in its response

  Scenario: Each task in a proactive routine exits on its own goal; the routine runs until turned off (REQ-003)
    Given a user has an active hourly /schedule + /goal-wrapped triage
      routine running
    When one hour's invocation finishes triaging that hour's messages
    Then that invocation's /goal condition is satisfied and the invocation
      exits — it does not keep running past its own completion
    And the /schedule cron trigger remains active and fires the next
      invocation at the next scheduled hour, continuing until the user
      explicitly disables the schedule
```

```gherkin
Feature: Designing-loops — quality and token-budget discipline when recommending a loop
  As a Claude Code skill recommending a loop primitive
  I want to always recommend the cheapest sufficient primitive and model
    tier, cite existing skills instead of duplicating their content, pilot
    before a large proactive run, and point to native usage-review commands
  So that loop recommendations don't independently re-derive quality/token
    guidance the plugin has already solved elsewhere

  Scenario: Cheapest sufficient primitive and model tier is named regardless of unconstrained token budget (REQ-010)
    Given a user says budget is not a constraint and asks Claude to get a
      batch job monitor running for mechanical log-grepping every 15 minutes
    When Claude consults designing-loops for a recommendation
    Then Claude still recommends the cheapest sufficient primitive — native
      /loop 15m — rather than escalating to /schedule + /goal + Workflow for
      work with no multi-step completion criterion
    And if any sub-agent dispatch is involved, Claude declares an explicit
      cheap model tier (e.g. haiku for a mechanical grep sweep), per the
      CRITICAL block in superpowers/skills/executing-plans/SKILL.md:81
      ("declare a model on every sub-agent dispatch ... Pick the cheapest
      tier the work allows; never let it default")

  Scenario: Claude cites existing skills and scripts instead of re-deriving their logic inline (REQ-009, REQ-010)
    Given Claude is drafting loop-selection guidance touching verification,
      code review, and checklist-evolution concerns
    When designing-loops is consulted for how to phrase this guidance
    Then Claude cites superpowers/skills/verification-before-completion/SKILL.md
      for self-verification, superpowers/skills/receiving-code-review/SKILL.md
      plus superpowers/agents/superpowers-evaluator.md for second-agent
      review, and superpowers/skills/retrospective/SKILL.md Phase 3/4 for
      turning individual lessons into systemic checklist fixes
    And for deterministic work inside a loop, Claude cites
      superpowers/lib/task-ledger.sh, superpowers/lib/docs-index.sh, and
      superpowers/lib/seed-checklists.sh as the existing "script not
      re-derived reasoning" pattern, rather than writing new inline logic
      for the same concerns

  Scenario: Claude recommends a pilot run before escalating to a large proactive batch (REQ-010)
    Given a user asks Claude to set up a proactive routine that reprocesses
      all 40 open support tickets every night
    When Claude consults designing-loops for how to stage the rollout
    Then Claude recommends piloting on a small subset first, citing
      superpowers/skills/references/workflow-orchestration.md Rule 3's
      >4-independent-task threshold as the point past which unpiloted
      fan-out risk becomes material
    And Claude proposes running the routine once, unattended, against 3-5
      tickets before enabling the full nightly schedule against all 40

  Scenario: Claude recommends periodic usage review for an active proactive routine (REQ-011)
    Given a user has just enabled a proactive /schedule + /goal routine that
      will run unattended going forward
    When Claude consults designing-loops for ongoing-maintenance guidance
    Then Claude recommends the user periodically check /usage (token/cost
      consumption), /goal invoked with no arguments (current goal-loop
      status), and /workflows (active workflow runs) as native Claude Code
      commands for monitoring an unattended routine
    And Claude presents this as a recommendation to the user, not as an
      automatic check the skill performs on its own, since designing-loops
      has no standing mechanism to run periodically itself
```
