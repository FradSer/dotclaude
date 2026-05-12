# superpowers v3.0 — debt tracker

**Purpose**: single source of truth for v3.0-target debt items that are known, accepted in their current state, and deliberately not bundled into v2.x PRs. Each item names one debt, its empirical incident bar (when "fix it now" overrides "wait"), and the design folder or retro it traces back to.

This file replaces the previous practice of restating "known issues" inline across multiple design docs. Designs and inline comments should LINK here, not re-explain.

## TODO list (v3.0 target)

### T-001: ~~Unify path-resolution across `lib/*.sh` writers~~ — RESOLVED 2026-05-12

**Symptom (historical)**: three different `repo_root` resolutions were going to coexist once `harness-evidence.sh` landed —
- `superpowers/lib/bail-log.sh:39` — `${PWD}/docs/retros` (PWD-only)
- `superpowers/lib/loop.sh:57-66` — inline `git rev-parse --show-toplevel` with `$PWD` fallback
- `superpowers/lib/harness-evidence.sh::_harness_evidence_root` (planned) — third copy.

When a Stop hook fired from a sub-directory, `bail-log.sh` wrote `docs/retros/` under the sub-dir while the other two wrote to the repo root, leaving retrospective Phase 5a unable to find the rows.

**Resolution**:
1. `utils.sh::repo_root` helper added (`${CLAUDE_PROJECT_DIR}` → `git rev-parse --show-toplevel` → `${PWD}`, in that order). `CLAUDE_PROJECT_DIR` is the officially documented Claude Code env var available in every hook event, so the helper inherits the harness's project-root resolution and only falls back when invoked outside hooks (test fixtures, direct CLI runs).
2. `bail-log.sh` now sources `utils.sh` and calls `repo_root()` for the log directory.
3. `loop.sh::_loop_log_plan_completion_if_executing` uses `repo_root()` for `root`; HEAD commit is fetched separately.
4. Future `harness-evidence.sh` lands with `repo_root()` from day one — no third copy.
5. NDJSON field renamed `cwd` → `repo_root` (bail-log) so the schema describes what it actually stores. `tests/test_bail_log_sh.py:62` updated to assert against the new field name.

**Why this happened earlier than the original fix-now bar**: the original bar was "wait for an empirical sub-dir incident". The 2026-05-12 audit found that `tests/test_bail_log_sh.py` was the only consumer asserting against the `cwd` field, no retrospective consumer ever read it, and the upcoming `harness-evidence.sh` PR would have shipped the third copy. Doing the extraction now (~50 LOC) was cheaper than landing a third copy and the inevitable cleanup later.

### T-002: Promote manual-write channels to lib helpers

**Symptom**: per v3 retro `docs/retros/2026-05-09-v3-considered-deferred.md` §5, two Phase 0 channels were claimed as "lib-shipped" but are still Claude-instructed manual writes from SKILL.md without a `lib/*.sh` helper:
- `docs/retros/harness-observations.jsonl` — written by retrospective Phase 5c disable-test outcomes
- `docs/retros/evolution-log.jsonl` — written by retrospective on `retrospective_run` and proposal events

**Why accepted (v2.x)**: the manual-write path works; promoting it requires (a) writing a `lib/observations.sh` + `lib/evolution-log.sh` pair mirroring `bail-log.sh`, (b) refactoring the retrospective SKILL.md bash blocks to call them, (c) adding test coverage. Net add of ~400 LOC for no functional change. Wait until a third channel needs to be added so the pattern is reused at least 3×.

**Fix-now bar**: a third manual-write channel is proposed (so the same boilerplate would otherwise be replicated four times). At that point promote all to lib helpers in one sweep.

**Tracked by**: `docs/retros/2026-05-09-v3-considered-deferred.md` §5 (link target).

### T-003: Drop legacy `SUPERPOWERS_MERGE_SESSION` flag from hook guards

**Symptom**: `superpowers/lib/utils.sh::run_haiku_merge` exports the umbrella `SUPERPOWERS_SUBSESSION=1` only. The 4 hooks check both `SUPERPOWERS_SUBSESSION` and `SUPERPOWERS_MERGE_SESSION` via `||` so any external operator script that still sets the legacy flag for testing/debugging continues to short-circuit hooks correctly.

**Why accepted (v2.x)**: backward compat for operator-side ad-hoc scripts. Removing the `||` branch in the same PR that introduced `SUPERPOWERS_SUBSESSION` would silently break external scripts that set the legacy flag.

**Fix-now bar**: 6 months after the split (target 2026-11-10), OR sooner if no external caller is identified after a project-wide survey. At that point drop the `||` branch from the 4 hooks; the legacy flag becomes inert.

**Tracked by**: `docs/plans/2026-05-09-harness-evidence-channel-design/architecture.md` §A (link target).

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
