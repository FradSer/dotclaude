# Task 005-impl: shared-core single-source impl (Green)

**depends-on**: task-005-test

## Description

Add the idempotency guards (`_OBSERVATIONS_LOADED`, `_EVOLUTION_LOG_LOADED`, `_SKILL_EVENTS_LOADED`, `_RETRO_EVENTS_LOADED`) to each wrapper and the shared core, and verify the cross-source property (`_SUPERPOWERS_DEPS_CHECKED` propagates so `utils.sh` is sourced exactly once). Turn the Red test from 005-test into Green. This is a small mechanical patch — the guard idiom is in `best-practices.md` §"BASH_SOURCE guard for double-source protection".

## Execution Context

**Task Number**: 005-impl of 15
**Phase**: Core Features (Green — cross-cutting)
**Prerequisites**: 005-test exists and fails.

## BDD Scenario

```gherkin
Scenario: the three channel helpers source retro-events.sh which sources utils.sh exactly once
  Given a shell with BASH_SOURCE tracking enabled
  When observations.sh, evolution-log.sh, and skill-events.sh are sourced in the same shell session in any order
  Then utils.sh is sourced exactly once
  And _SUPERPOWERS_DEPS_CHECKED is set to 1 after the first source and is not re-evaluated on the second or third
  And no duplicate warning lines about missing deps appear on stderr
```

**Spec Source**: `../2026-05-12-unified-retro-events-design/bdd-specs.md` §1.5.

## Files to Modify/Create

- Modify: `superpowers/lib/retro-events.sh` — confirm `_RETRO_EVENTS_LOADED` guard works; confirm `utils.sh` source is single-shot.
- Modify: `superpowers/lib/observations.sh` — add `[[ -n "${_OBSERVATIONS_LOADED:-}" ]] && return 0` at top, set `_OBSERVATIONS_LOADED=1` at end.
- Modify: `superpowers/lib/evolution-log.sh` — same pattern with `_EVOLUTION_LOG_LOADED`.
- Modify: `superpowers/lib/skill-events.sh` — same pattern with `_SKILL_EVENTS_LOADED`.

## Steps

### Step 1: Confirm Red
- Run `python3 -m unittest tests.test_retro_events_sh -v`. Confirm failure.

### Step 2: Add idempotency guards
- For each wrapper file:
  - Add `[[ -n "${_<WRAPPER>_LOADED:-}" ]] && return 0` immediately after the shebang and any module-level comments.
  - Add `_<WRAPPER>_LOADED=1` as the last line before the dual-mode footer.
- For `retro-events.sh`:
  - Confirm the existing `_RETRO_EVENTS_LOADED` guard from 002-impl is in place.
  - Confirm `source utils.sh` is called only on the first source (the guard handles this).
  - Verify `_SUPERPOWERS_DEPS_CHECKED` from `utils.sh` is not re-evaluated on subsequent sources (the existing `utils.sh` self-guards; this should be a no-op).
- **PROHIBITED**: do not change the function bodies or the contract surface. The change is mechanical guard addition only.

### Step 3: Verify Test Passes (Green)
- Run `python3 -m unittest tests.test_retro_events_sh -v`. MUST PASS.
- Full suite: `python3 -m unittest discover -s tests -v`. No regressions in 002/003/004 tests.

### Step 4: Refactor & Lint
- `shellcheck superpowers/lib/{retro-events,observations,evolution-log,skill-events}.sh` clean.
- `grep -nE '^set -' superpowers/lib/{retro-events,observations,evolution-log,skill-events}.sh` empty.

## Verification Commands

```bash
cd /Users/FradSer/Developer/FradSer/dotclaude/superpowers
python3 -m unittest tests.test_retro_events_sh -v
python3 -m unittest discover -s tests -v
shellcheck lib/retro-events.sh lib/observations.sh lib/evolution-log.sh lib/skill-events.sh
```

## Success Criteria

- All four lib files carry their `_*_LOADED` guards consistently.
- `tests/test_retro_events_sh.py` passes.
- Full suite green.
- No regressions in 002/003/004 tests.
- `shellcheck` clean across all four files.
