# BDD Specs — Superpowers Memory Layer (`kind=memory`)

```gherkin
Feature: Memory Layer for Superpowers Skills (docs/README.md, kind=memory)

  As a superpowers contributor
  I want the shared docs index extended with a controlled-vocabulary kind=memory
  So that brainstorming, writing-plans, executing-plans, systematic-debugging, and
  retrospective can consult and grow a compact layer of distilled, reusable facts,
  decisions, conventions, and pitfalls — one per file at
  docs/memory/<category>_<slug>.md, one pointer row per file in the existing
  docs/README.md table — without turning every routine skill run into a write,
  and without letting the index bloat.

  Background:
    Given the docs-index convention from "Docs Index Convention (docs/README.md)" is shipped
    And the controlled vocabulary for `kind` is extended to exactly:
      | value   | meaning                                      |
      | design  | a design folder under docs/plans/*-design/   |
      | plan    | a plan folder under docs/plans/*-plan/        |
      | retro   | a retrospective report under docs/retros/     |
      | memory  | a distilled fact/decision/convention/pitfall file under docs/memory/ |
    And a memory artifact is exactly one file at `docs/memory/<category>_<slug>.md`
    And each memory file carries frontmatter fields `name`, `category`, `summary`, `source`, `created`, `updated`
    And the controlled vocabulary for `category` (a frontmatter field on the memory FILE,
      never a table column, and never reusing the reserved schema words `kind` or `type`) is exactly:
      | value      | meaning                                          |
      | convention | a project/plugin convention worth reapplying     |
      | pitfall    | a recurring mistake worth avoiding                |
      | decision   | a design decision and its rationale               |
      | preference | a standing user/project preference                |
    And the docs/README.md row for a memory file still uses exactly the same five columns:
      | path | kind | status | summary | updated |
    And a memory row's `path` column always points at `docs/memory/<category>_<slug>.md`
    And a memory row's `status` column is restricted, by the script, to exactly `active` or
      a parameterized `expired:<reason>` — never `wip`, `implemented:<sha>`,
      `superseded-by:<path>`, or `reference`
    And `docs/memory/archive/` is the physical resting place for expired memory files
      once their row is dropped from the index (never for active files)
    And each of the five superpowers skills — brainstorming, writing-plans, executing-plans,
      systematic-debugging, retrospective — gains a memory-READ step at its entry
      (`lib/docs-index.sh list --kind memory --status active`, then Read the topically
      relevant files) and a CONDITIONAL memory-WRITE step gated on that skill's own
      existing internal escalation threshold, never on routine/first-pass success

  # --- Scenario 1: Cold start for the memory kind ---

  Scenario: Cold start — first memory write creates docs/memory/ and the first kind=memory row
    Given the file `docs/README.md` does not exist
    And the directory `docs/memory/` does not exist
    When the systematic-debugging skill's write-gate fires for the first time in this project's history
      # picked deliberately: this skill currently has zero docs/ touchpoints before this design
    Then it creates `docs/memory/pitfall_<slug>.md` with valid `name`, `category`, `summary`, `source` frontmatter
    And it invokes `lib/docs-index.sh upsert memory docs/memory/pitfall_<slug>.md --status active --summary "<one-line>"`
    And the file `docs/README.md` is created with the header preamble and table header row
    And the table contains exactly one data row
    And that row's `kind` column equals `memory`
    And that row's `status` column equals `active`
    And that row's `updated` column equals today's ISO date
    And that row's `summary` column is <= 72 characters
      # requirement #28 — same single-physical-line, diff-friendly convention already
      # tested for design/plan/retro rows in the shipped base spec; no format exception for memory

  # --- Scenario 2: Read-before surfaces a relevant active memory file ---

  Scenario: Memory read-before step surfaces a relevant active memory file and informs the skill's output
    Given the index contains one active memory entry:
      | path   | docs/memory/pitfall_plan-cov-01-verbatim-titles.md |
      | kind   | memory                                              |
      | status | active                                              |
    And that file's body states: task files must copy design scenario titles verbatim,
      or the plan reflection sub-agent's literal-grep check produces a false-positive FAIL
    When the writing-plans skill begins Phase 2 task decomposition for a new plan
    Then it invokes `lib/docs-index.sh list --kind memory --status active`
    And the list result includes the plan-cov-01-verbatim-titles entry
    And writing-plans Reads `docs/memory/pitfall_plan-cov-01-verbatim-titles.md` for context
    And the produced task files copy design scenario titles verbatim rather than paraphrasing them
    And writing-plans' turn output cites the memory file as the reason for that choice

  # --- Scenario 3: Read-before finds no relevant memory ---

  Scenario: Memory read-before step finds no relevant memory and the skill proceeds normally
    Given the index contains zero memory entries
    When the brainstorming skill begins a new design
    Then it invokes `lib/docs-index.sh list --kind memory --status active`
    And the list result is empty
    And brainstorming proceeds with its normal Phase 1 research
    And no error, warning, or blocked state is raised by the empty result
    And the empty read leaves no trace in `docs/README.md`

  # --- Scenarios 3a-3c: read-before step for the three skills not covered by Scenarios 2/3 ---
  # (REQ-TRACE-01 rework: requirement #20 covers all five skills; Scenarios 2 and 3 exercised
  # only writing-plans and brainstorming — these three close the remaining gap)

  Scenario: systematic-debugging's memory read-before step surfaces a relevant active memory file
    Given the index contains one active memory entry:
      | path   | docs/memory/pitfall_repo-root-fallback-wrong-project.md |
      | kind   | memory                                                   |
      | status | active                                                   |
    And that file's body states: repo_root() silently targets the parent repo
      when CLAUDE_PROJECT_DIR is unset during plugin self-development
    And the symptom under investigation matches that file's summary keywords
    And the bail-out check does NOT fire (no named root cause + named fix in the symptom)
    When systematic-debugging begins its new step 0, prepended to Phase 1 "Root Cause Investigation"
    Then it invokes `lib/docs-index.sh list --kind memory --status active`
    And the list result includes the repo-root-fallback-wrong-project entry
    And systematic-debugging Reads `docs/memory/pitfall_repo-root-fallback-wrong-project.md` before step 1 "Read Error Messages Carefully"
    And its Phase 1 investigation is informed by that file's `Fact`/`How to Apply` content

  Scenario: systematic-debugging's memory read-before step is skipped on the bail-out path
    Given the index contains one active memory entry:
      | path   | docs/memory/pitfall_repo-root-fallback-wrong-project.md |
      | kind   | memory                                                   |
      | status | active                                                   |
    And `$ARGUMENTS` is `"cookie domain is .foo.com, should be foo.com — fix it"`
      (names a specific root cause and a specific corrective change —
      the bail-out check's own firing condition)
    When systematic-debugging's Bail-Out Check fires and skips the 4-phase pipeline
    Then it does NOT invoke `lib/docs-index.sh list --kind memory`
    And it proceeds directly to the fix + regression test, exactly as the bail-out already specifies
      (symmetric with how the bail-out already skips every other Phase-1-onward step)

  Scenario: executing-plans' memory read-before step surfaces a relevant active memory file
    Given the index contains one active memory entry:
      | path   | docs/memory/pitfall_plan-cov-01-false-positive.md |
      | kind   | memory                                             |
      | status | active                                             |
    And that file's summary topically overlaps the plan folder about to be executed
    When executing-plans' Initialization step 1 "Plan Check" runs
      (already invokes `docs-index.sh show <plan-path>`)
    Then it also invokes `lib/docs-index.sh list --kind memory --status active`
    And the list result includes the plan-cov-01-false-positive entry
    And executing-plans Reads that file before Phase 1 "Plan Review"
    And batch 1's coordinator prompt reflects the memory file's `How to Apply` guidance

  Scenario: retrospective's memory read-before step folds relevant memory into Phase 1 Data Collection
    Given the index contains one active memory entry:
      | path   | docs/memory/decision_dedicated-index-commit-not-amend.md |
      | kind   | memory                                                     |
      | status | active                                                     |
    And that file records why executing-plans uses a dedicated follow-up commit
      instead of `--amend` to flip a plan's status to `implemented:<sha>`
    When retrospective's Phase 1 "Data Collection" step 1 runs
      (already invokes `list --kind plan --status implemented` and `list --status expired`)
    Then it also invokes `lib/docs-index.sh list --kind memory --status active`
    And the list result includes the dedicated-index-commit-not-amend entry
    And retrospective folds that entry into its Phase 2 failure-frequency/plateau analysis
      alongside the existing plan/expired signals

  # --- Scenarios 4-8: each skill's write-gate FIRING, matching its own existing threshold ---

  Scenario: brainstorming write-gate fires — 2+ evaluator REWORK rounds on a design
    Given the design evaluator has returned REWORK on `evaluation-design-round-1.md`
      And REWORK again on `evaluation-design-round-2.md` for the same design
    When brainstorming reaches its existing "REWORK 2+ rounds" trigger
      and considers pivoting back to Phase 1 to realign the approach
    Then, in addition to its normal design commit and `kind=design` upsert,
      brainstorming captures the recurring rework cause as a memory file
      with `category=pitfall` (or `category=decision`, if the pivot itself is the reusable insight)
    And it invokes `lib/docs-index.sh upsert memory docs/memory/<category>_<slug>.md --status active --summary "<one-line>"`
    And the index contains a new `kind=memory` row alongside the design row

  Scenario: writing-plans write-gate fires — a Phase 4 reflection sub-agent FAIL requiring rework
    Given a Phase 4 reflection sub-agent has returned FAIL on checklist item `PLAN-COV-01`
      because task files paraphrased scenario titles instead of copying them verbatim
      # mirrors the real deferred MODIFY proposal in
      # docs/retros/retro-2026-07-04-docs-index-plan.md (signal #1)
    When writing-plans fixes the offending task files and reruns the affected sub-agent
    Then, because this was a FAIL-then-rework outcome and not a first-pass PASS,
      writing-plans captures the false-positive cause as a memory file with `category=pitfall`
    And it invokes `lib/docs-index.sh upsert memory docs/memory/pitfall_<slug>.md --status active --summary "<one-line>"`
    And the plan is still committed with its normal `kind=plan` upsert in the same turn

  Scenario: executing-plans write-gate fires — the intra-plan "variety gap" signal (2+ rework rounds, batch eventually PASSes)
    Given a batch's superpowers-evaluator returned REWORK on round 1
      And the coordinator's fix required a second REWORK round before reaching PASS
    When the coordinator's rework loop completes its 2nd round and the batch reaches PASS
      # this is the variety-gap signal from references/intra-plan-learning.md:54,
      # NOT the separate "max 2 rounds before escalation" hard-abort cap in
      # references/batch-execution-playbook.md:165 — that cap fires only when a batch
      # never reaches PASS and is a distinct, unrelated event
    Then, before returning its structured result to the main agent,
      the coordinator captures the recurring rework pattern as a memory file with `category=pitfall`
    And it invokes `lib/docs-index.sh upsert memory docs/memory/pitfall_<slug>.md --status active --summary "<one-line>"`
    And the coordinator's returned verdict (PASS) is unaffected by the memory write

  Scenario: systematic-debugging write-gate fires — its existing 3+ failed fixes trigger
    Given three consecutive fix attempts have failed to resolve the symptom
    When systematic-debugging reaches its existing "3+ failed fixes → question architecture" trigger
    Then, in addition to the architecture-questioning step, it captures the underlying
      architectural insight as a memory file with `category=decision` or `category=convention`
    And it invokes `lib/docs-index.sh upsert memory docs/memory/decision_<slug>.md --status active --summary "<one-line>"`
    And this is the first `docs/` touchpoint systematic-debugging has ever had

  Scenario: systematic-debugging write-gate fires — an explicit cross-cutting gotcha, independent of the 3+ threshold
    Given the first fix attempt succeeds
      But the root cause reveals a gotcha that spans multiple unrelated call sites in the codebase
    When systematic-debugging identifies this as an explicit cross-cutting gotcha
    Then it captures the gotcha as a memory file with `category=pitfall`, even though
      the 3+ failed-fixes threshold was never reached
    And it invokes `lib/docs-index.sh upsert memory docs/memory/pitfall_<slug>.md --status active --summary "<one-line>"`

  Scenario: retrospective write-gate fires — a Phase 3 proposal reaches the ADD or MODIFY threshold
    Given a Phase 3 proposal reaches the ADD threshold (a failure pattern in 2+ distinct plans)
      or the MODIFY threshold (an item producing 2+ false positives)
    When retrospective's Phase 4 Auto-Apply processes that qualifying proposal
    Then, in addition to writing the new checklist version file,
      retrospective promotes the qualifying finding into a memory file
    And it invokes `lib/docs-index.sh upsert memory docs/memory/<category>_<slug>.md --status active --summary "<one-line>"`
    And retrospective remains the primary, highest-volume memory writer of the five skills
    But a Phase 3 REMOVE or PROMOTE proposal, even if applied, does NOT trigger a memory write
      # REMOVE is a retraction (no positive fact to distill); PROMOTE is checklist-internal

  # --- Scenario 8a: the Pre-Check-B promotion bridge (requirement #23), distinct from Scenario 8 ---
  # Scenario 8 above promotes retrospective's OWN Phase 3 ADD/MODIFY findings into memory.
  # This scenario promotes a DIFFERENT source: a prior already recalled from the private,
  # harness-injected global memory (Pre-Check B), which is a disjoint mechanism per architecture.md §4.

  Scenario: retrospective promotes a recalled global-memory prior into a project-local memory file
    Given Pre-Check B has recalled a private-memory hook:
      | hook name | feedback_skill_level_enforcement |
      | claim     | L2 SKILL.md must carry a CRITICAL marker or its rule gets silently skipped |
    And that hook is cited as supporting evidence for an approved Phase 3 MODIFY proposal this run
    And the hook's claim proves project-specific and durable (not a cross-project harness-design stance)
    When retrospective's Phase 3 "Evolution Proposals" step processes the approved MODIFY proposal
    Then, in addition to the ordinary ADD/MODIFY memory write (Scenario 8),
      retrospective writes a `docs/memory/convention_<slug>.md` file for the promoted prior
    And that file's `## Why` section records exactly:
      `Promoted from private assistant memory hook: feedback_skill_level_enforcement, <date>`
    And it invokes `lib/docs-index.sh upsert memory docs/memory/convention_<slug>.md --status active --summary "<one-line>"`
    And the private hook itself is not deleted or modified — it remains available to future Pre-Check B recalls
    And a cross-project harness-design stance recalled by the same Pre-Check B (e.g. "simplify-don't-add")
      is NOT promoted, because it is not project-specific to this repo

  # --- Scenarios 9-13: each skill's write-gate NOT firing (anti-bloat negative path) ---

  Scenario: brainstorming write-gate does NOT fire — first-pass evaluator PASS
    Given the design evaluator returns PASS on `evaluation-design-round-1.md`
    When brainstorming completes and commits the design
    Then it invokes its normal `kind=design` upsert
    But it does NOT invoke a memory-write step
    And no file is created under `docs/memory/`
    And no `kind=memory` row is added to `docs/README.md`

  Scenario: writing-plans write-gate does NOT fire — every Phase 4 reflection sub-agent passes first try
    Given every Phase 4 reflection sub-agent returns PASS on its first pass
    When writing-plans commits the plan
    Then it invokes its normal `kind=plan` upsert
    But it does NOT invoke a memory-write step
    And no file is created under `docs/memory/`

  Scenario: executing-plans write-gate does NOT fire — a batch evaluator passes on round 1
    Given a batch's superpowers-evaluator returns PASS on round 1, with no rework needed
      (the variety-gap signal never fires because there was no rework at all)
    When the coordinator returns its structured PASS result
    Then it returns normally with completed task IDs and evidence blocks
    But it does NOT invoke a memory-write step
    And no file is created under `docs/memory/` for that batch

  Scenario: systematic-debugging write-gate does NOT fire — routine single-attempt fix
    Given the first fix attempt resolves the symptom
      And no cross-cutting gotcha is identified
    When systematic-debugging narrates its completion output
    Then it narrates exactly the three-part output (root-cause one-liner, fix diff summary, regression-test path)
    But it does NOT invoke a memory-write step
    And no file is created under `docs/memory/`

  Scenario: retrospective write-gate does NOT fire — no proposal meets the ADD/MODIFY threshold this run
    Given a retrospective run's Phase 3 analysis produces candidate signals with only 1-plan evidence
      # mirrors docs/retros/retro-2026-07-04-docs-index-plan.md, which self-rejected exactly
      # this shape: 2 ADD proposals rejected for 1-plan evidence, 2 MODIFY proposals deferred
      # pending a 2nd false-positive instance — "Zero proposals approved this run."
    When Phase 4 Auto-Apply runs
    Then no checklist version file is written
    And no memory file is created
    And no `kind=memory` row is added to `docs/README.md`
    And the report's "Self-Rejected Proposals" / "Deferred Proposals" sections name the
      insufficient-evidence rationale, exactly as the cited real report does

  # --- Scenario 14: Memory consolidation ---

  Scenario: Two memory files on the same concept are MODIFY-merged into one
    Given two active kind=memory rows/files exist addressing the same underlying concept:
      | path                                                | category |
      | docs/memory/pitfall_plan-cov-01-false-positive.md    | pitfall  |
      | docs/memory/pitfall_scenario-title-paraphrase-risk.md | pitfall |
    When retrospective's Phase 3 analysis identifies 2+ memory files on the same concept
      # mirrors the existing MODIFY threshold (2+ false positives), reapplied to memory files
    Then retrospective proposes a memory-consolidation MODIFY merging the two files into one
    When the proposal is applied
    Then a single canonical file remains at one surviving path
    And the absorbed file's content is folded into the survivor's body
    And the absorbed file's row is first flipped to `expired:superseded-by-consolidation:<survivor-path>`
      then dropped from the index in the same commit (mirrors the design/plan tombstone-then-drop pattern)
    And the surviving row's `summary` and `updated` fields are refreshed
    And the index contains exactly one `kind=memory` row for that concept afterward

  # --- Scenario 15: Memory expiry and archive ---

  Scenario: An expired memory row's file is archived and dropped from the index
    Given the index contains one `kind=memory` row with `status=expired:<reason>`
    When the shipped 60-line second-line-defense "drop expired rows" rule applies to that row
      # reuses the existing rule verbatim; for kind=memory it also relocates the file
    Then the underlying file `docs/memory/<category>_<slug>.md` is moved to
      `docs/memory/archive/<category>_<slug>.md`
    And the row is dropped entirely from `docs/README.md`
    And the file remains recoverable via `docs/memory/archive/` and git history
    And a subsequent `rebuild` does NOT re-add a row for the archived file
      (its non-recursive `docs/memory/*.md` glob does not descend into `archive/`)

  # --- Scenario 16: Malformed/missing category ---

  Scenario Outline: Malformed or missing category is rejected with exit code 2, no write
    Given the index exists with at least one entry
    When the memory-write step is invoked as
      `lib/docs-index.sh upsert memory docs/memory/x.md --status active --summary "..." --category=<bad_category>`
    Then the script exits with code 2
    And the script writes a diagnostic message naming the allowed category vocabulary
    And no file `docs/memory/x.md` is created
    And the `docs/README.md` index is not modified

    Examples:
      | bad_category |
      | type          |   # rejected — reserved by the row schema, not a category value
      | kind          |   # rejected — reserved by the row schema, not a category value
      | reference     |   # rejected — status=reference already exists at the row level; would collide
      | note          |
      | fact          |
      |               |   # missing entirely

  # --- Scenario 17: 60-line ceiling applies to memory rows ---

  Scenario: The 60-line ceiling collapse rule applies to memory rows exactly like other kinds
    Given the index already contains 58 rows across design/plan/retro/memory
    And 3 more `kind=memory` rows are upserted, each with `status=expired:<reason>` and `category=pitfall`
    When the total row count would reach 61
    Then the first-line collapse groups rows sharing `status=expired` and `category=pitfall`
      into a single summary line (grouped by `category`, since flat `docs/memory/<category>_<slug>.md`
      paths carry no date-prefixed topic the way `docs/plans/YYYY-MM-DD-*` folders do — this is
      `topic_of_path()`'s existing no-date-prefix fallback, exercised here for the first time
      beyond the single fixed `docs/writing-skills/` row)
    And the collapsed line reads "... and 3 prior expired pitfall memory entries — see git history"
    And the final index contains at most 60 rows
    And active `kind=memory` rows are never collapsed

  # --- Scenario 18: systematic-debugging's deliverable contract is preserved ---

  Scenario: systematic-debugging's fix-and-regression-test contract is unchanged even when memory is written
    Given systematic-debugging's 3+ failed-fixes trigger has fired
      And its memory-write step has captured a cross-cutting gotcha as a `kind=memory` row
    When systematic-debugging completes the underlying bug fix
    Then it narrates exactly the same three-part completion output as always:
      root-cause one-liner, fix diff summary, regression-test path
    And no additional phase, commit, or user-facing deliverable is introduced by the memory write
    And the memory-write step is folded into the existing completion turn, not a separate step
    And the regression test remains the sole verification gate for completion

  # --- Scenario 19: status-transition restriction for kind=memory ---

  Scenario Outline: kind=memory rows are restricted to active and expired statuses, enforced by the script
    Given a `kind=memory` row exists with `status=active`
    When `lib/docs-index.sh set-status <path> "<to>"` is invoked
    Then the transition is <outcome>

    Examples:
      | to                                     | outcome  |
      | expired:retro-2026-07-04:superseded     | allowed  |
      | wip                                     | rejected (exit 2) |   # memory writes are atomic single-turn artifacts, never partial
      | superseded-by:docs/memory/pitfall_other.md | rejected (exit 2) |   # consolidation drops the absorbed row outright instead of pointing at a replacement
      | reference                               | rejected (exit 2) |   # reference is reserved for evergreen bundles like docs/writing-skills/; memory is designed to expire
      | implemented:abc1234                     | rejected (exit 2) |   # memory facts are never "shipped" the way plans are
```

## Notes on conventions applied

- Extends, rather than replaces, the Background from the shipped `Feature: Docs Index Convention` — the row schema (`path | kind | status | summary | updated`) is untouched; `category` is deliberately kept out of the table (frontmatter-only).
- Scenarios 3a-3c close a requirement-traceability gap surfaced by evaluation round 1 (`REQ-TRACE-01`, see `evaluation-design-round-1.md`): requirement #20 covers the read-before step for all five skills, but Scenarios 2 and 3 alone only exercised writing-plans and brainstorming. 3a and its negative counterpart cover systematic-debugging (including the bail-out-skips-the-read-too symmetry); 3b covers executing-plans; 3c covers retrospective — closing the trace for the remaining three skills.
- Scenarios 4–8 and 9–13 are written as matched positive/negative pairs per skill so the anti-bloat property ("routine success never writes memory") is exercised as directly as the positive triggers.
- Scenario 6's executing-plans trigger is precisely the `intra-plan-learning.md:54` "variety gap" signal, explicitly distinguished in-scenario from `batch-execution-playbook.md:165`'s separate hard-abort cap — see `_index.md` Glossary for the reconciliation rationale.
- Scenario 13's negative case is phrased against the actual cited precedent (`docs/retros/retro-2026-07-04-docs-index-plan.md`) rather than a hypothetical.
- Scenario 14's consolidation now routes through `expired:superseded-by-consolidation:<path>` before drop, so the tombstone-then-drop discipline stays consistent with Scenario 15 and with the design/plan status-transition precedent, rather than deleting a row with no terminal-state record.
- Scenario 16 adds `reference` as an explicitly rejected category value (not just a hypothetical bad string), directly enforcing the Glossary decision that `reference` may never be a per-file category.
- Scenario 17 flags a genuine, previously-narrow collapse-grouping path: `topic_of_path()`'s no-date-prefix fallback was previously exercised only by the single `docs/writing-skills/` row; this scenario is its first real multi-row test.
- Scenario 19 operationalizes the status-restriction decision as a testable negative-transition matrix, matching the base spec's existing "Allowed status transitions" Scenario Outline style, and reflects that this restriction is script-enforced (exit 2), not merely documented convention.
- Scenario 8a closes a second requirement-traceability gap surfaced by evaluation round 2 (`REQ-TRACE-01`, see `evaluation-design-round-2.md`): requirement #23 (the Pre-Check-B-recall-to-memory promotion bridge) was previously documented only in `architecture.md` §4 prose, with Scenario 8 covering a disjoint mechanism (retrospective's own ADD/MODIFY findings). Scenario 8a gives #23 its own concrete Given/When/Then, including the negative case (a cross-project stance is not promoted).
- Requirement #28's ≤72-char summary convention is now asserted concretely in Scenario 1 (cold start), the row-lifecycle scenario every subsequent memory row shares the shape of — mirrors how the shipped base spec tests the same constraint for design/plan/retro rows, without repeating the assertion in every downstream scenario.
- Requirements #24 (no secrets/PII in git-tracked memory files) and #30 (grep/awk-parseable, no new tool/schema) are architectural/authorial-responsibility constraints, not independently observable Given/When/Then behaviors — evaluation round 3 (`REQ-TRACE-01`, see `evaluation-design-round-3.md`) confirmed neither has a Gherkin-scenario-shaped test to write. #24 is enforced by the writing skill at write time and specified in `best-practices.md` §Security (no script-level content filter is proposed, by design — see that section's rationale). #30 holds by construction throughout this entire feature file: every scenario's Then/And clauses reference only `docs-index.sh` subcommands already covered by the shipped script's `grep`/`awk`-only parsing, plain markdown frontmatter, and no JSON, database, or new CLI tool anywhere above.
