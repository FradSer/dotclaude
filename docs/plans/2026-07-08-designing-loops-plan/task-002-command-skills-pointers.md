# Task 002: Five command skills pointer sentences + systematic-debugging second anchor

**depends-on**: task-001 (the `loop-types.md` file must exist before pointers can target it)

## Description

Add one pointer sentence to each of the 5 command skills' `## Recommended: run wrapped in /goal` section (brainstorming, writing-plans, executing-plans, retrospective, systematic-debugging), pointing to `../../skills/references/loop-types.md`. For `systematic-debugging`, add a second anchor — a sentence at "When Process Reveals No Root Cause" plus a `**Related skills:**` bullet. These edits make `loop-types.md` reachable from the skills that are already loaded when the `/goal` decision arises. The 4 reachability scenarios carried here assert the file is consultable from the relevant skill's anchor.

## Execution Context

**Task Number**: 002 of 005
**Phase**: Integration
**Prerequisites**: `superpowers/skills/references/loop-types.md` exists (task 001).

## BDD Scenario

This task carries the flaky-test reproduction scenario (shared with task 001, which owns the file's time-based content) inline — it is listed here because the *reverse* pointer (systematic-debugging's "When Process Reveals No Root Cause" section pointing back to `loop-types.md`) is this task's edit. The remaining reachability is the structural requirement REQ-011 (a static edit; `architecture.md` §3.1-3.2 anchors) verified by REQ-014's grep set in task 005.

```gherkin
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
```

The pointer-sentence reachability itself is the structural requirement REQ-011 (a static edit; `architecture.md` §3.1-3.2 anchors) verified by REQ-014's grep set in task 005. The behavioral scenarios that exercise the *content* reached via these pointers are the 16 carried by task 001.

**Spec Source**: `../2026-07-08-designing-loops-design/bdd-specs.md` (for reference)

## Interfaces

**Exposes** (interfaces this task produces):
- File edits (one pointer sentence each, exact anchors in `architecture.md` §3.1):
  - `superpowers/skills/brainstorming/SKILL.md` — pointer after the `/goal` section's closing goal-wrapper citation, before the next `##` heading.
  - `superpowers/skills/writing-plans/SKILL.md` — same anchor pattern.
  - `superpowers/skills/executing-plans/SKILL.md` — same anchor pattern.
  - `superpowers/skills/retrospective/SKILL.md` — merged single sentence (token ceiling) naming retrospective as a natural time-based/proactive (`/schedule`) candidate.
  - `superpowers/skills/systematic-debugging/SKILL.md` — pointer after the `/goal` section (§3.1) PLUS a second anchor at "When Process Reveals No Root Cause" (§3.2): one sentence on time-based `/loop` re-verification for flaky/timing-dependent symptoms, plus one bullet appended to the existing `**Related skills:**` list.

**Consumes** (interfaces from `depends-on` tasks this task relies on):
- `superpowers/skills/references/loop-types.md` (from task 001) — the pointer target; must exist with the `## Time-based` section the systematic-debugging reverse-pointer names.

**Global Constraints respected**: REQ-011 (pointer sentences at the verified anchors), REQ-016 (single-sentence edits to `retrospective`/`writing-plans`; validator must stay exit 0 after each), REQ-012-adjacent (this task does NOT touch `using-superpowers` — that is task 003, which must keep the pointer outside the scraped table rows).

## Files to Modify/Create

- Modify: `superpowers/skills/brainstorming/SKILL.md` (~line 20, before `## CRITICAL: Bail-Out Check` ~line 22) — exact text in `architecture.md` §3.1
- Modify: `superpowers/skills/writing-plans/SKILL.md` (~line 21, before `## CRITICAL: Bail-Out Check (run first)` ~line 23) — single sentence
- Modify: `superpowers/skills/executing-plans/SKILL.md` (~line 21, before `## Step 1 of every iteration` ~line 23)
- Modify: `superpowers/skills/retrospective/SKILL.md` (~line 23, before `## Pre-Check` ~line 25) — merged single sentence
- Modify: `superpowers/skills/systematic-debugging/SKILL.md` — (a) ~line 27 pointer before `## CRITICAL: Bail-Out Check` ~line 29; (b) after ~line 361 (`**Note:** 95% of "no root cause"...`), before ~line 363 `## References`, one sentence on time-based `/loop` re-verification; (c) one bullet appended to the `**Related skills:**` list (~lines 372-373)

## Steps

### Step 1: Add pointer sentences to the 4 non-retrospective command skills
- For `brainstorming`, `writing-plans`, `executing-plans`, `systematic-debugging` (first anchor only): insert the sentence *"To decide whether this run should be a plain turn, `/goal`, `/loop`, or `/schedule`, see `../../skills/references/loop-types.md`."* after each `/goal` section's closing goal-wrapper citation, before the next `##` heading (anchors in `architecture.md` §3.1).

### Step 2: Add the merged pointer sentence to retrospective
- Insert the merged single sentence *"Retrospective is periodic maintenance work — a natural time-based/proactive (`/schedule`) candidate rather than a one-off `/goal` run; see `../../skills/references/loop-types.md`."* at the verified anchor (§3.1). Single sentence — token ceiling.

### Step 3: Add systematic-debugging's second anchor + Related skills bullet
- After `**Note:** 95% of "no root cause"...` (~line 361), before `## References` (~line 363): insert one sentence — environmental/timing-dependent symptoms and flaky reproductions fit a time-based `/loop` re-verification loop; pointer to `../../skills/references/loop-types.md` (§3.2).
- Append one bullet to the existing `**Related skills:**` list: `- \`../../skills/references/loop-types.md\` - loop-type classification (turn/goal/time/proactive) for flaky or recurring debugging work` (§3.2).

### Step 4: Re-validate token ceilings after EACH SKILL.md edit
- After each edit to `retrospective/SKILL.md` or `writing-plans/SKILL.md` (the two near-ceiling files), run the validator and confirm exit 0. Do not batch edits to these two files without an intervening validation.

## Verification Commands

```bash
# Pointer existence in all 5 command skills (REQ-014, partial — full 8-file grep is task 005)
grep -l "loop-types" \
  superpowers/skills/{brainstorming,writing-plans,executing-plans,retrospective,systematic-debugging}/SKILL.md
# systematic-debugging carries BOTH anchors (the /goal-section pointer AND the Related-skills bullet)
grep -c "loop-types" superpowers/skills/systematic-debugging/SKILL.md   # expect >= 3 (pointer + 2nd-anchor sentence + bullet)
# Token ceilings — must stay exit 0 after every retrospective/writing-plans edit (REQ-016)
python3 plugin-optimizer/scripts/validate-plugin.py superpowers
```

## Success Criteria

- Each of the 5 command skills' SKILL.md contains the pointer sentence at the verified anchor (REQ-011).
- `systematic-debugging` carries the second anchor (sentence + `**Related skills:**` bullet) (REQ-011).
- `retrospective` and `writing-plans` edits are single sentences; validator exit 0 after each (REQ-016).
- No "autonomous loop" introduced (REQ-015).
