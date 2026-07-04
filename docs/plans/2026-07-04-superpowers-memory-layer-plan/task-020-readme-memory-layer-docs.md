# Task 020: README memory-layer documentation

**depends-on**: task-019

## Description

Document the new memory-layer capability in `superpowers/README.md`, matching the existing per-skill bullet-list style in the "User-Invocable Skills" section. Surfaced by `git-agent related` as a historically high-coupling co-change (55 co-changes) whenever the 5 skills' `SKILL.md` files change together.

## Execution Context

**Task Number**: 020 of 020
**Phase**: Housekeeping
**Prerequisites**: task-019 merged (version bump lands before the README describes the shipped feature)

## BDD Scenario

N/A — pure documentation, no runtime behavior; not part of the design's `bdd-specs.md` scope.

## Interfaces

**Exposes**: none

**Consumes**: none

**Global Constraints respected**: additive documentation only — no restructuring of the existing "User-Invocable Skills" section; one bullet added per skill's existing bullet list, matching each section's current sentence style and length.

## Files to Modify/Create

- Modify: `superpowers/README.md:62-73` (`### /superpowers:brainstorming` bullet list) — add one bullet: "Consults and, on repeated rework, contributes to a shared project memory layer (`docs/README.md` `kind=memory`) of reusable facts/decisions/pitfalls"
- Modify: `superpowers/README.md:75-86` (`### /superpowers:writing-plans` bullet list) — add the matching one-line bullet
- Modify: `superpowers/README.md:88-100` (`### /superpowers:executing-plans` bullet list) — add the matching one-line bullet
- Modify: `superpowers/README.md:102-113` (`### /superpowers:retrospective` bullet list) — add a bullet noting retrospective is the primary memory writer and bridges recalled private-memory priors into the project-local layer
- Modify: `superpowers/README.md:115-126` (`### /superpowers:systematic-debugging` bullet list) — add a bullet noting this is the skill's only `docs/` touchpoint, conditional on its existing 3+-failed-fixes trigger

## Steps

### Step 1: Verify Scenario
- N/A (no BDD scenario for this task — confirmed above).

### Step 2: Implement Logic
- Add the 5 bullets, one per skill section, matching each section's existing tone and bullet density (do not add a new top-level `##` section — the design's memory layer is a property of the 5 existing skills, not a 6th user-invocable skill).

### Step 3: Verify & Refactor
- Re-read the full "User-Invocable Skills" section to confirm no existing bullet was altered or removed, only additions.

## Verification Commands

```bash
grep -c "memory layer\|kind=memory" superpowers/README.md
```

## Success Criteria

- Each of the 5 skill sections gains exactly one new bullet describing its memory-layer touchpoint
- No pre-existing bullet, heading, or section is altered or removed
- This is the plan's final task — after this task, `superpowers:executing-plans` Phase 6 transitions to the plan's own commit
