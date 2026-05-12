# Handoff Summary 3 — Batch 3

## Completed Tasks

| ID | Subject | Checklist Result | Batch |
|----|---------|------------------|-------|
| 001 | Test fixtures and scaffolding | PASS | 1 |
| 002-test | observations.sh helper test (Red) | PASS | 1 |
| 002-impl | observations.sh + retro-events.sh primitives impl (Green) | PASS | 1 |
| 003-test | evolution-log.sh helper test (Red) | PASS | 2 |
| 003-impl | evolution-log.sh helper impl (Green) | PASS | 2 |
| 004-test | skill-events.sh helper test (Red) | PASS | 2 |
| 004-impl | skill-events.sh helper impl (Green) | PASS | 2 |
| 005-test | shared-core single-source test (Red) | PASS (4 tests, file-not-guard Red) | 3 |
| 005-impl | shared-core single-source impl (Green) | PASS (4 tests pass; 158 suite green) | 3 |
| 006-test | Migration parity test (Red) | PASS (8 tests, key-order Red) | 3 |
| 006-impl | Migration parity impl (Green) | PASS (8 tests pass; 158 suite green) | 3 |

## Remaining Tasks

| ID | Subject | Status | Dependencies |
|----|---------|--------|--------------|
| 007 | Phase 5c SKILL.md migration to observations.sh | pending | 006-impl |
| 008 | Phase 4 + Phase 6 SKILL.md migration to evolution-log.sh | pending | 006-impl |
| 009-test | systematic-debugging Phase 4 emission test (Red) | pending | 004-impl |
| 009-impl | systematic-debugging Phase 4 emission impl (Green) | pending | 009-test |

## Key Decisions

- **005-impl** added the missing `_OBSERVATIONS_LOADED` guard to `lib/observations.sh`. The other three wrappers already had their `_*_LOADED` guards.
- **006-impl** flipped the jq merge in `lib/evolution-log.sh` from left-biased `{envelope} + (payload)` to right-biased `(payload) + {envelope}`. This lets the caller's payload filter control top-level key positioning by referencing `$event`/`$timestamp` inline; envelope values still override authoritatively. Required to satisfy legacy key-order parity for `item_added` (`{timestamp, event, ...}`) while preserving `retrospective_run` parity (`{event, timestamp, ...}`).
- **`post_plan_diff` is conditionally included** in `evolution-log.sh` — omitted (not nullified) when the caller does not pass it.
- **Schema drift documented**: `observations.sh` terse-row `{event, component, reason, repo_root, timestamp}` is NOT byte-for-byte equivalent to the legacy `{event, component, timestamp, retrospective_id}` row — they share three keys. The migration parity test (006) was written to assert byte-equality on the shared intersection only; this softening is intentional and documented in the handoff-state. The plan's Phase 5c migration (task 007) will adopt the new schema; downstream Phase 1 reader is unaffected because it only consumes the shared keys.

## File Ownership

| File Path | Last Modified By Task |
|-----------|-----------------------|
| `superpowers/tests/fixtures/*` | 001 |
| `superpowers/tests/test_observations_sh.py` | 002-test (+ 002-impl quality fixes) |
| `superpowers/lib/retro-events.sh` | 002-impl |
| `superpowers/lib/observations.sh` | 002-impl (→ 005-impl guard add → 006-impl jq tweaks) |
| `superpowers/lib/evolution-log.sh` | 003-impl (→ 005-impl guard add → 006-impl jq tweaks) |
| `superpowers/lib/skill-events.sh` | 004-impl (→ 005-impl guard add) |
| `superpowers/tests/test_evolution_log_sh.py` | 003-test |
| `superpowers/tests/test_skill_events_sh.py` | 004-test |
| `superpowers/tests/test_retro_events_sh.py` | 005-test |
| `superpowers/tests/test_migration_parity.py` | 006-test |

## Blockers

None.
