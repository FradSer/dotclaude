# superpowers v3.0 — debt tracker

**Purpose**: single source of truth for v3.0-target debt items that are known, accepted in their current state, and deliberately not bundled into v2.x PRs. Each item names one debt, its empirical incident bar (when "fix it now" overrides "wait"), and the design folder or retro it traces back to.

This file replaces the previous practice of restating "known issues" inline across multiple design docs. Designs and inline comments should LINK here, not re-explain.

## TODO list (v3.0 target)

### T-002: Promote manual-write channels to lib helpers

**Symptom**: per v3 retro `docs/retros/2026-05-09-v3-considered-deferred.md` §5, two Phase 0 channels were claimed as "lib-shipped" but are still Claude-instructed manual writes from SKILL.md without a `lib/*.sh` helper:
- `docs/retros/harness-observations.jsonl` — written by retrospective Phase 5c disable-test outcomes
- `docs/retros/evolution-log.jsonl` — written by retrospective on `retrospective_run` and proposal events

**Why accepted (v2.x)**: the manual-write path works; promoting it requires (a) writing a `lib/observations.sh` + `lib/evolution-log.sh` pair mirroring `bail-log.sh`, (b) refactoring the retrospective SKILL.md bash blocks to call them, (c) adding test coverage. Net add of ~400 LOC for no functional change. Wait until a third channel needs to be added so the pattern is reused at least 3×.

**Resolution (v2.9, 2026-05-21)**: superseded by `lib/jsonl-emit.sh`, a single dispatcher that took the place of four short-lived per-channel wrappers (`retro-events.sh` + `observations.sh` + `evolution-log.sh` + `skill-events.sh`). The four wrappers and their migration-parity test layer (`test_migration_parity.py` + the `legacy-*.sh` fixtures) were deleted in the same pass — no backward-compat seam survives. Retrospective and systematic-debugging callers now compose the envelope inline and route via `bash jsonl-emit.sh <channel> <jq_program>`.

**Tracked by**: `docs/retros/2026-05-09-v3-considered-deferred.md` §5 (historical link).

## Anti-add-bias guard

Adding a new T-NNN item to this file is itself an add-bias risk. Before adding:

1. Is this a real debt with a concrete fix-now bar, or a vague "should be nicer"? If vague, do not add.
2. Is it cross-cutting v2.x → v3.0, or solvable inside the current PR? If solvable now, solve now.
3. Is the fix-now bar a measurable incident, or a calendar date with no evidence? Prefer measurable.

Per v3 retro §6: do not advance v3.0 inside any conversational arc that produces v2.8.x or v2.9.x retract patches. Items here are records of "intentionally deferred" — not seeds for new scope.

## Cross-references

- `docs/retros/2026-05-09-v3-considered-deferred.md` — the v3.x knowledge-platform reject retro; §4 activation gate; §5 conflict table; §7 audit trail
- `docs/plans/2026-05-09-harness-evidence-channel-design/` — the condition-2 channel design and the source of the SUPERPOWERS_SUBSESSION split
- `docs/retros/meta-retro-2026-05-08-superpowers-v2.8.x.md` — sibling retro on the add-bias failure mode this tracker prevents
