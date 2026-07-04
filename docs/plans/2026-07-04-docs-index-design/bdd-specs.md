# BDD Specs — Docs Index Convention

Full Gherkin scenarios. Follows the conventions in `skills/behavior-driven-development/references/gherkin-guide.md`: declarative Given/When/Then, one When per scenario (with `And` chaining actions of the same kind), Background for shared context, Scenario Outline for data variants, business language over tool jargon.

```gherkin
Feature: Docs Index Convention (docs/README.md)

  As a superpowers contributor
  I want a shared docs index maintained by a single lib/docs-index.sh script
  So that brainstorming, writing-plans, executing-plans, and retrospective
  can consult a consistent, compact record of every design, plan, and retro
  artifact without re-scanning the docs/ tree each time, and so that a prior
  doc invalidated by a retrospective is visibly stale to the next skill.

  Background:
    Given the superpowers plugin is installed at a known root
    And a shared script `lib/docs-index.sh` exists with subcommands:
      | subcommand | purpose                                              |
      | list       | print index rows matching a filter                   |
      | show       | print the single row for a path                       |
      | upsert     | insert or update a single entry by path              |
      | set-status | flip an existing entry's status to a new value        |
      | rebuild    | regenerate the index from filesystem truth            |
    And the index lives at `docs/README.md` as a pipe-delimited table
    And the table has exactly these columns, in order:
      | path | kind | status | summary | updated |
    And the controlled vocabulary for `kind` is exactly:
      | value   | meaning                       |
      | design  | a design folder under docs/plans/*-design/ |
      | plan    | a plan folder under docs/plans/*-plan/     |
      | retro   | a retrospective report under docs/retros/  |
    And the controlled vocabulary for `status` is exactly:
      | value               | meaning                                       |
      | wip                 | draft, not yet ready for consultation         |
      | active              | in flight, conclusions current                |
      | implemented:<sha>   | plan landed at commit <sha> (short 7-char SHA)|
      | superseded-by:<path>| replaced by the entry at <path>               |
      | expired:<reason>    | conclusions no longer valid; <reason> cites a retro report |
      | reference           | evergreen reference doc, never expires        |
    And any `kind` or `status` value outside the controlled vocabulary is rejected

  # --- Scenario 1: Cold start ---

  Scenario: Cold start — first design creates the index
    Given the file `docs/README.md` does not exist
    And no `docs/plans/` folders exist
    When the brainstorming skill completes its first design
      And commits the design to `docs/plans/2026-07-04-feature-X-design/`
    Then the skill invokes `lib/docs-index.sh upsert design docs/plans/2026-07-04-feature-X-design/ --status active --summary "<one-line>"`
    And the file `docs/README.md` is created with a header preamble and a table header row
    And the table contains exactly one data row for the new design
    And that row's `kind` column equals `design`
    And that row's `status` column equals `active`
    And that row's `updated` column equals today's ISO date

  # --- Scenario 2: Consult-before with an active prior design ---

  Scenario: Consult-before — prior active design on the same topic is superseded
    Given the index contains one active design entry:
      | path   | docs/plans/2026-07-01-feature-X-design/ |
      | kind   | design                                  |
      | status | active                                  |
    When the brainstorming skill begins a new design for the same topic
    Then brainstorming invokes `lib/docs-index.sh list --kind design --status active`
    And the list result includes the prior active design entry
    And brainstorming decides to supersede the prior design
    When brainstorming commits the new design to `docs/plans/2026-07-04-feature-X-design/`
      And upserts the new entry with `status=active`
      And invokes `lib/docs-index.sh set-status docs/plans/2026-07-01-feature-X-design/ "superseded-by:docs/plans/2026-07-04-feature-X-design/"`
    Then the index contains exactly two design rows
    And the prior row's `status` column equals `superseded-by:docs/plans/2026-07-04-feature-X-design/`
    And the new row's `status` column equals `active`

  # --- Scenario 3: Consult-before with an expired prior ---

  Scenario: Consult-before — prior design already expired is not trusted
    Given the index contains one design entry:
      | path   | docs/plans/2026-06-10-feature-X-design/ |
      | kind   | design                                  |
      | status | expired:retro-2026-07-01:wrong-abstraction |
    When the brainstorming skill begins a new design for the same topic
    Then brainstorming invokes `lib/docs-index.sh list --status expired`
    And the list result returns the prior entry with its `expired:` status
    And brainstorming treats the prior entry's conclusions as non-authoritative
    And brainstorming creates a fresh design rather than extending the expired one
    When brainstorming commits the fresh design and upserts it with `status=active`
    Then the prior row remains unchanged with `status=expired:retro-2026-07-01:wrong-abstraction`
    And the new row's `status` column equals `active`
    And the new row's `path` column differs from the prior row's `path` column

  # --- Scenario 4: writing-plans upserts a plan entry ---

  Scenario: Upsert-after — writing-plans records a new plan
    Given the index contains one active design entry for the same topic
    And the writing-plans skill has produced a plan folder
    When writing-plans creates `docs/plans/2026-07-04-feature-X-plan/`
      And invokes `lib/docs-index.sh upsert plan docs/plans/2026-07-04-feature-X-plan/ --status active --summary "<one-line>"`
    Then the index contains a new row for the plan folder
    And that row's `kind` column equals `plan`
    And that row's `status` column equals `active`
    And the design row from the prior step is unchanged

  # --- Scenario 5: writing-plans refuses to plan an expired design ---

  Scenario: writing-plans consult-before refuses an expired design
    Given the index contains one design entry:
      | path   | docs/plans/2026-06-10-feature-X-design/ |
      | kind   | design                                  |
      | status | expired:retro-2026-07-01:wrong-abstraction |
    When the writing-plans skill begins planning from that design path
    Then writing-plans invokes `lib/docs-index.sh show docs/plans/2026-06-10-feature-X-design/`
    And the show result returns the row with `status=expired:retro-2026-07-01:wrong-abstraction`
    And writing-plans refuses to proceed, citing the expired status
    And writing-plans does not create a plan folder
    And writing-plans does not invoke `upsert`

  # --- Scenario 6: executing-plans flips plan to implemented ---

  Scenario: executing-plans marks the plan implemented at Phase 5 commit
    Given the index contains one active plan entry:
      | path   | docs/plans/2026-07-04-feature-X-plan/ |
      | kind   | plan                                   |
      | status | active                                 |
    When executing-plans completes Phase 5 and creates a git commit
    Then the commit produces a short SHA of length 7
    When executing-plans invokes `lib/docs-index.sh set-status docs/plans/2026-07-04-feature-X-plan/ "implemented:<short-sha>"`
    Then the plan row's `status` column matches the regex `^implemented:[0-9a-f]{7}$`
    And the plan row's `updated` column equals today's ISO date
    And no other rows are modified
    And the `set-status` call and the implementation commit land in the same turn

  # --- Scenario 7: Retrospective invalidation ---

  Scenario: Retrospective invalidates a design and records its own report
    Given the index contains two entries:
      | path   | docs/plans/2026-07-04-feature-X-design/ | docs/plans/2026-07-04-feature-X-plan/ |
      | kind   | design                                  | plan                                  |
      | status | active                                  | implemented:abc1234                   |
    And the retrospective skill has just written its report to `docs/retros/retro-2026-07-04-feature-X.md`
    And the report contains the line `invalidates: docs/plans/2026-07-04-feature-X-design/`
    When the retrospective skill runs its Phase 6 invalidate-after step
    Then it invokes `lib/docs-index.sh set-status docs/plans/2026-07-04-feature-X-design/ "expired:retro-2026-07-04:wrong-abstraction"`
    And it invokes `lib/docs-index.sh upsert retro docs/retros/retro-2026-07-04-feature-X.md --status active --summary "<one-line>"`
    And the design row's `status` column equals `expired:retro-2026-07-04:wrong-abstraction`
    And the index contains a new row of `kind=retro` with `status=active`
    And the plan row is not flipped to `expired:` by the design invalidation

  # --- Scenario 8: Retrospective preserves the historical record of an implemented plan ---

  Scenario: Retrospective does not expire an already-implemented plan
    Given the index contains a plan entry with `status=implemented:abc1234`
    When a retrospective concludes the design behind that plan was wrong
      And marks the design entry as `expired:retro-2026-07-04:wrong-abstraction`
    Then the plan row's `status` column remains `implemented:abc1234`
    And the plan row is not flipped to `expired:`
    But a new `kind=retro` row is upserted explaining the invalidation
    And the `invalidates:` line in the retro report names only the design path, not the plan path

  # --- Scenario 9: Compactness ---

  Scenario: Index stays compact — one row per folder, no per-file enumeration
    Given 20 distinct design and plan folders exist under `docs/plans/`
    And each folder was upserted exactly once
    When `lib/docs-index.sh list` is invoked with no filter
    Then the returned table contains exactly 20 data rows
    And each row corresponds to exactly one folder `path`
    And no row enumerates individual files inside any folder
    And the index file size is bounded by a linear function of folder count, not file count

  # --- Scenario 10: Reference entries never expire ---

  Scenario: Reference entry is never flipped to expired
    Given the index contains one entry:
      | path   | docs/writing-skills/ |
      | kind   | retro                |
      | status | reference            |
    When a retrospective concludes that some design approach was wrong
      And marks the design entry as `expired:retro-2026-07-04:reason`
    Then the reference row's `status` column still equals `reference`
    And the reference row is never eligible for `set-status` to `expired:` or `superseded-by:`
    And a consult for the writing-skills topic still returns the reference row as authoritative

  # --- Scenario 11: Idempotent upsert ---

  Scenario: Upserting the same path twice updates the row, never duplicates
    Given the index contains one entry:
      | path   | docs/plans/2026-07-04-feature-X-design/ |
      | kind   | design                                  |
      | status | active                                  |
    When `lib/docs-index.sh upsert design docs/plans/2026-07-04-feature-X-design/ --status wip --summary "revised"` is invoked twice in succession
    Then the index still contains exactly one row for that `path`
    And that row's `status` column equals `wip`
    And that row's `summary` column equals `revised`
    And the row's `updated` column reflects the second invocation's date
    And no duplicate rows are appended

  # --- Scenario 12: Controlled vocabulary enforcement ---

  Scenario Outline: Unknown status value is rejected with exit code 2
    Given the index exists with at least one entry
    When `lib/docs-index.sh upsert design docs/plans/x-design/ --status=<bad_status>` is invoked
    Then the script exits with code 2
    And the script writes a diagnostic message naming the allowed vocabulary
    And the index file is not modified
    And no partial row is appended

    Examples:
      | bad_status          |
      | done                |
      | complete            |
      | archived            |
      | obsolete            |
      | implemented-abc1234 |   # wrong separator — must be a colon
      | superseded abc      |   # wrong format — must be `superseded-by:<path>`
      | draft               |   # rejected variant — canonical is `wip`

  Scenario Outline: Unknown kind value is rejected with exit code 2
    Given the index exists with at least one entry
    When `lib/docs-index.sh upsert <bad_kind> docs/plans/x-design/ --status active` is invoked
    Then the script exits with code 2
    And the script writes a diagnostic message naming the allowed kinds
    And the index file is not modified

    Examples:
      | bad_kind |
      | feature  |
      | spec     |
      | document |
      | type     |   # rejected variant — canonical is `kind`

  # --- Scenario 13: Malformed index file ---

  Scenario: Consult degrades gracefully when the index is not a table
    Given the file `docs/README.md` exists
    And its content is free-form prose, not a pipe-delimited table
    When any skill invokes `lib/docs-index.sh list`
    Then the script exits with code 2
    And the diagnostic message states `docs/README.md is not a valid index table`
    And the calling skill surfaces the error rather than silently improvising
    And no upsert or set-status is attempted against the malformed file
    And the skill suggests running `lib/docs-index.sh rebuild` to recover

  # --- Scenario 14: Same-day same-topic folder name collision ---

  Scenario: Two designs on the same day and same topic get distinct folder names
    Given the brainstorming skill has already committed a design today for topic "feature-X"
      And that design lives at `docs/plans/2026-07-04-feature-X-design/`
    When brainstorming commits a second, distinct design for the same topic on the same day
    Then the second design's folder name is disambiguated by a numeric suffix
      And the folder path matches the pattern `docs/plans/2026-07-04-feature-X-design-2/`
    And `lib/docs-index.sh upsert` records the second path as a distinct row
    And the two rows are distinguishable by `path` alone
    And the first row is marked `superseded-by:` the second row's path when supersession is intended

  # --- Scenario 15: Rework after ship ---

  Scenario: executing-plans rework flips implemented back to wip
    Given the index contains a plan entry with `status=implemented:abc1234`
    When executing-plans is re-invoked on that plan folder for a rework
    Then executing-plans invokes `lib/docs-index.sh show <plan-path>` in its consult-before step
    And the show result returns `status=implemented:abc1234`
    And executing-plans invokes `lib/docs-index.sh set-status <plan-path> "wip"` before spawning batch 1
    And on re-completion the plan row's `status` column is set to `implemented:<new-sha>`
    And the old SHA `abc1234` is recoverable via git history, not from the index

  # --- Scenario 16: Not-in-index is a recoverable 3, not a failure ---

  Scenario: show on an absent path exits 3 and the caller upserts first
    Given the index exists with one entry
    When a skill invokes `lib/docs-index.sh show docs/plans/never-seen-design/`
    Then the script exits with code 3
    And no diagnostic error is written to stderr
    And the calling skill treats exit 3 as "not tracked yet, proceed"
    And the calling skill upserts the path before any further set-status call

  # --- Cross-cutting: consult ordering ---

  Scenario: Every mutating skill consults before it mutates
    Given the index contains at least one entry
    When any of brainstorming, writing-plans, executing-plans, or retrospective begins its mutation phase
    Then that skill invokes `lib/docs-index.sh list` or `show` before any `upsert` or `set-status`
    And the consult result is read in this turn before the mutation is issued
    And the mutation reflects the consult result rather than a stale assumption

  # --- Cross-cutting: status transition rules ---

  Scenario Outline: Allowed status transitions
    Given an entry exists with `status=<from>`
    When `lib/docs-index.sh set-status <path> "<to>"` is invoked
    Then the transition is <outcome>

    Examples:
      | from                 | to                                  | outcome  |
      | wip                  | active                              | allowed  |
      | active               | implemented:abc1234                 | allowed  |
      | active               | superseded-by:docs/plans/x-design/  | allowed  |
      | active               | expired:retro-2026-07-04:reason     | allowed  |
      | active               | wip                                 | allowed  |
      | wip                  | expired:retro-2026-07-04:reason     | allowed  |
      | implemented:abc1234  | wip                                 | allowed  |   # rework after ship
      | implemented:abc1234  | expired:retro-2026-07-04:reason     | rejected |
      | implemented:abc1234  | superseded-by:docs/plans/x-design/  | rejected |
      | expired:x            | active                              | rejected |   # no resurrection without retro revalidation
      | expired:x            | superseded-by:docs/plans/y-design/  | rejected |
      | reference            | expired:x                           | rejected |
      | reference            | superseded-by:docs/plans/y-design/  | rejected |
      | superseded-by:y      | active                              | rejected |

  Scenario: Rejected transition exits non-zero without modifying the index
    Given an entry with `status=implemented:abc1234`
    When `lib/docs-index.sh set-status <path> "expired:retro-2026-07-04:reason"` is invoked
    Then the script exits with code 2
    And the diagnostic message states the transition is not allowed
    And the entry's `status` column still equals `implemented:abc1234`
    And the `summary` column is unchanged

  # --- Cross-cutting: invalidation boundary ---

  Scenario: A retrospective REMOVE proposal does not invalidate a design
    Given the index contains one active design entry
    And a retrospective produces a Phase 3 REMOVE proposal on a checklist item
    But the retro report does NOT contain an `invalidates: <design-path>` line
    When the retrospective skill runs its Phase 6 invalidate-after step
    Then it does NOT invoke `set-status` on the design entry
    And the design row's `status` column remains `active`
    And only the checklist version file is updated by the retro

  Scenario: Invalidation requires the path to already be tracked
    Given the index contains one active design entry at `docs/plans/2026-07-04-X-design/`
    And a retro report contains the line `invalidates: docs/plans/never-tracked-design/`
    When the retrospective skill runs its Phase 6 invalidate-after step
    Then it invokes `set-status docs/plans/never-tracked-design/ "expired:..."` 
    But the script exits with code 3 (not in index)
    And the skill logs a warning that the path is not tracked
    And the skill skips the expiry for that path
    And the index is unchanged
```

## Notes on conventions applied

- One `When` per scenario, with `And` chaining additional actions of the same kind — matches the gherkin-guide "single When" tip.
- `Background` carries the shared table schema, controlled vocabularies, and script subcommand table so each scenario stays declarative and short.
- `Scenario Outline` with `Examples:` tables is used for the controlled-vocabulary rejection matrix, the kind-rejection matrix, and the status-transition rules — these are genuinely data-driven, not cosmetic.
- Business language throughout: rows, entries, folders, statuses. No `grep`, `awk`, JSON, or implementation jargon leaks into the scenarios; the script name `lib/docs-index.sh` is named only because it is the system under test.
- The "rejected transition" rule formalizes the design intent for `implemented:` and `reference` rows as historical/evergreen records — they are not eligible for `expired:` or `superseded-by:`, which keeps the audit trail honest (Scenario 8 — keep `implemented:`, emit a separate `retro` row rather than rewriting history).
- The same-day collision scenario encodes the disambiguation policy (`-2` suffix) as an explicit assertion, so a future implementation can't silently overwrite the first folder.
- Scenario 15 (rework after ship) makes the `implemented → wip` transition explicit — rework is a real state, not an error, mirroring the plugin's state-based detection philosophy.
- The invalidation-boundary scenarios (last two) make the `invalidates:` line both necessary AND sufficient: necessary (a REMOVE without `invalidates:` does nothing to the design) and the path must already be tracked (no speculative expiry).
