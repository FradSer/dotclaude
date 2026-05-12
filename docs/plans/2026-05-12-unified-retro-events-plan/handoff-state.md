# Handoff State — Unified Retro Events Plan

> Rolling cross-batch memory rewritten each batch. The spawned batch coordinator reads this file as its ONLY cumulative context beyond its sprint contract.

## Plan Identity

- **Plan ID:** `docs/plans/2026-05-12-unified-retro-events-plan/`
- **Goal:** Promote three retro NDJSON channels into one shared helper layer, migrate two inline-bash emission points in `retrospective` SKILL.md, and add one new emission point in `systematic-debugging` Phase 4.

## Architecture Decisions Carried Forward

- **Single shared core** `superpowers/lib/retro-events.sh` exposes six primitives. Three thin wrappers source it.
- **Best-effort contract**: every helper returns 0 unconditionally; failures are silent.
- **Dual-mode wrappers**: every wrapper is sourceable and executable; footer pattern `if [[ "${BASH_SOURCE[0]:-$0}" == "${0}" ]]; then <fn> "$@"; fi`.
- **No top-level `set -`** (NF3).
- **Module guards** (all in place after Batch 3): `_RETRO_EVENTS_LOADED`, `_OBSERVATIONS_LOADED`, `_EVOLUTION_LOG_LOADED`, `_SKILL_EVENTS_LOADED`.
- **bail-log.sh is NOT refactored** (out of scope).
- **observations.sh** uses **terse-row schema** `{event, component, reason, repo_root, timestamp}`. **Schema drift note**: this differs from the legacy Phase 5c row `{event, component, timestamp, retrospective_id}` — they share `{event, component, timestamp}` but the legacy row's `retrospective_id` is replaced by the new schema's `reason` + `repo_root`. The migration parity test (006) asserts byte-equality on the shared intersection only.
- **evolution-log.sh** envelope merges payload via right-biased merge: `(payload_filter) + {event, timestamp}` — the caller's payload filter dictates top-level key positioning by referencing `$event`/`$timestamp` inline; envelope values override authoritatively. Adopted in Batch 3 task 006-impl to satisfy legacy key-order parity for both `item_added` (`{timestamp, event, ...}`) and `retrospective_run` (`{event, timestamp, ...}`). `post_plan_diff` is conditionally included (omitted, never nullified).
- **skill-events.sh** envelope **nests** payload under `payload:` key — distinct from evolution-log.
- **args_hash** in skill-events: sha1[:12] of joined positional args after payload_filter; `shasum` → `sha1sum` → empty fallback.
- **Quality findings to avoid**: no `"stub"` substring in any string literal (trips CODE-QUAL-01); no `try/except OSError: pass` in tearDown (trips CODE-QUAL-02; use guard clauses).
- **Verification caveat**: `shellcheck` not installed on host; NF3 enforced via `grep -nE '^set -' <file>` exiting 1 (no matches).

## Completed Task IDs

- 001 — Test fixtures and scaffolding (Batch 1, PASS)
- 002-test — observations.sh helper test (Red) (Batch 1, PASS)
- 002-impl — observations.sh + retro-events.sh primitives impl (Green) (Batch 1, PASS)
- 003-test — evolution-log.sh helper test (Red) (Batch 2, PASS) — 17 tests
- 003-impl — evolution-log.sh helper impl (Green) (Batch 2, PASS)
- 004-test — skill-events.sh helper test (Red) (Batch 2, PASS) — 16 tests
- 004-impl — skill-events.sh helper impl (Green) (Batch 2, PASS)
- 005-test — shared-core single-source test (Red) (Batch 3, PASS) — 4 tests
- 005-impl — shared-core single-source impl (Green) (Batch 3, PASS)
- 006-test — Migration parity test (Red) (Batch 3, PASS) — 8 tests
- 006-impl — Migration parity impl (Green) (Batch 3, PASS)

## Modified Files (cumulative)

- `superpowers/tests/fixtures/legacy-harness-observation.sh`
- `superpowers/tests/fixtures/legacy-retrospective-run.sh`
- `superpowers/tests/fixtures/legacy-evolution-item.sh`
- `superpowers/tests/fixtures/README.md`
- `superpowers/tests/test_observations_sh.py`
- `superpowers/tests/test_evolution_log_sh.py`
- `superpowers/tests/test_skill_events_sh.py`
- `superpowers/tests/test_retro_events_sh.py`
- `superpowers/tests/test_migration_parity.py`
- `superpowers/lib/retro-events.sh`
- `superpowers/lib/observations.sh`
- `superpowers/lib/evolution-log.sh`
- `superpowers/lib/skill-events.sh`

## Test Suite Health

- Total passing tests: **158** (101 baseline + 12 observations + 17 evolution-log + 16 skill-events + 4 retro-events shared-core + 8 migration parity)
- Zero regressions across batches.

## Recurring Failure Patterns

None across Batches 1, 2, and 3. All three evaluators returned PASS on first round.

## Open Blockers

None.

## Outstanding Verification Caveats

- `shellcheck` not installed; NF3 enforced via `grep -nE '^set -'` substitute.
- Plugin validator (`python3 plugin-optimizer/scripts/validate-plugin.py superpowers`) has not been run yet; Batch 4 SKILL.md edits MUST pass it.

## Known Gap

F6 (retrospective Phase 1 surface of `skill-events.jsonl`) is **deferred** — out of scope for this plan.

## File Conventions

- All new shell files under `superpowers/lib/`
- Test files under `superpowers/tests/test_*.py` (Python 3 + `unittest`)
- Fixtures under `superpowers/tests/fixtures/`
- Structural mirrors: `superpowers/tests/conftest.py`, `superpowers/tests/test_bail_log_sh.py`, `superpowers/tests/test_observations_sh.py`, `superpowers/tests/test_evolution_log_sh.py`, `superpowers/tests/test_skill_events_sh.py`
- SKILL.md frontmatter `allowed-tools` is the single source of truth (no separate plugin config file).
