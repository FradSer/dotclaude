# Task 018: Retrospective memory touchpoint — impl (GREEN)

**depends-on**: task-017

## Description

Edit `skills/retrospective/SKILL.md` to add the memory read-before step, the two-stage conditional memory-write (Phase 4 draft + Phase 6 upsert), the explicit REMOVE/PROMOTE exclusion, and the Pre-Check-B promotion bridge — without altering the existing Pre-Check B prose (lines 31-41) in any other way.

## Execution Context

**Task Number**: 018 of 020
**Phase**: Skill Touchpoints
**Prerequisites**: task-017's assertions exist and FAIL

## BDD Scenario

```gherkin
Scenario: retrospective write-gate fires — a Phase 3 proposal reaches the ADD or MODIFY threshold
  Then, in addition to writing the new checklist version file,
    retrospective promotes the qualifying finding into a memory file
  And retrospective remains the primary, highest-volume memory writer of the five skills
  But a Phase 3 REMOVE or PROMOTE proposal, even if applied, does NOT trigger a memory write

Scenario: retrospective write-gate does NOT fire — no proposal meets the ADD/MODIFY threshold this run
  Then no memory file is created

Scenario: retrospective promotes a recalled global-memory prior into a project-local memory file
  Given Pre-Check B has recalled a private-memory hook
  And that hook is cited as supporting evidence for an approved Phase 3 MODIFY proposal this run
  Then retrospective writes a `docs/memory/convention_<slug>.md` file for the promoted prior
  And that file's `## Why` section records the provenance line
  And the private hook itself is not deleted or modified
  And a cross-project harness-design stance is NOT promoted

Scenario: Two memory files on the same concept are MODIFY-merged into one
  When retrospective's Phase 3 analysis identifies 2+ memory files on the same concept
    (reuses the existing MODIFY threshold — 2+ instances — reapplied to memory files)
  Then retrospective proposes a memory-consolidation MODIFY merging the two files into one
  When the proposal is applied
  Then the absorbed file's row is first flipped to `expired:superseded-by-consolidation:<survivor-path>`
    then dropped from the index in the same commit
```

**Spec Source**: `../2026-07-04-superpowers-memory-layer-design/bdd-specs.md` Scenarios 3c, 8, 8a, 13, 14; `architecture.md` §3, §4; `best-practices.md` §Anti-Bloat Rules (h)

## Interfaces

**Exposes** (edits to `skills/retrospective/SKILL.md`):
- Phase 1 "Data Collection," step 1 (line 95) — append, after the existing `list --kind plan --status implemented` / `list --status expired` calls: run `bash "${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh" list --kind memory --status active`; fold matches into the Phase 2 failure-frequency/plateau analysis.
- Phase 4 "Auto-Apply," new step 3.5 (after the existing step 3 "Log evolution", line ~140-141): for every ADD or MODIFY proposal actually applied this run (post-self-rejection), draft one `docs/memory/<category>_<slug>.md` file (`category: convention` for a generalized structural rule, `pitfall` for a recurring failure mode, `decision` for a rejected-vs-chosen call), using the proposal's own description+rationale as `Fact`/`Why` content, `source:` citing the retro report path. Explicitly state: REMOVE and PROMOTE proposals, even if applied, do NOT trigger this step.
- Phase 6 "Output," new step 8 (after the existing step 7 invalidate-after, before "Close the calibration loop"): run `bash "${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh" upsert memory docs/memory/<path> --status active --summary "<one-line>" --category <category>` for each memory file drafted in Phase 4 step 3.5.
- Pre-Check B (lines 31-41) — append (do not otherwise edit the existing paragraph): a new sentence describing the promotion bridge — when a recalled hook is cited as supporting evidence for an approved Phase 3 proposal AND proves project-specific and durable (not a cross-project harness-design stance), the Phase 4 step 3.5 draft additionally records, in its `## Why` section, `Promoted from private assistant memory hook: <hook-name>, <date>`. Cross-project stances (e.g. "simplify-don't-add") are explicitly NOT promoted. The private hook itself is never deleted or modified — it remains available to future Pre-Check B recalls.
- Phase 3 "Evolution Proposals" — extend the existing MODIFY-threshold scan (already reused for the ordinary ADD/MODIFY memory write above) to also flag 2+ active `kind=memory` files covering the same underlying concept as a memory-consolidation MODIFY candidate. When applied (Phase 4), retrospective folds the absorbed file's content into the surviving file's body, then runs `bash "${CLAUDE_PLUGIN_ROOT}/lib/docs-index.sh" set-status <absorbed-path> "expired:superseded-by-consolidation:<survivor-path>"` followed by the row-drop that the shipped collapse rule already performs on `expired` rows once triggered — no new subcommand needed, this reuses `set-status` verbatim.

**Consumes**: `lib/docs-index.sh list`/`upsert`/`set-status`

**Global Constraints respected**: reuses the existing ADD (2+ plans)/MODIFY (2+ false positives) thresholds verbatim, no new threshold; Pre-Check B's existing advisory-only/private/harness-injected behavior is unchanged beyond the one additive promotion-bridge sentence.

## Files to Modify/Create

- Modify: `superpowers/skills/retrospective/SKILL.md:95` (Phase 1 step 1 — extend)
- Modify: `superpowers/skills/retrospective/SKILL.md:140-141` (Phase 4 — insert new step 3.5 after existing step 3)
- Modify: `superpowers/skills/retrospective/SKILL.md:170-172` (Phase 6 — insert new step 8 after existing step 7)
- Modify: `superpowers/skills/retrospective/SKILL.md:41` (Pre-Check B — append the promotion-bridge sentence at the end of the existing paragraph, do not otherwise reword it)

## Steps

### Step 1: Verify Scenario
- Re-confirm Scenarios 3c, 8, 8a, 13 against current `SKILL.md` text.

### Step 2: Implement Logic (Green)
- Apply the four edits exactly as specified.

### Step 3: Verify & Refactor
- Run `bash superpowers/tests/test-skill-touchpoints.sh`; all 4 task-017 assertions PASS; zero regressions, including a diff-check that Pre-Check B's original paragraph (lines 31-40) is otherwise byte-identical (only the new trailing sentence added).

## Verification Commands

```bash
bash superpowers/tests/test-skill-touchpoints.sh
```

## Success Criteria

- All 4 task-017 assertions PASS
- Zero regressions
- Pre-Check B's original text is unchanged except for the one appended sentence
