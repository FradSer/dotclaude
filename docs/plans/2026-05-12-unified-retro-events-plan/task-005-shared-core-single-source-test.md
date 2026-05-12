# Task 005-test: shared-core single-source test (Red)

**depends-on**: task-002-impl, task-003-impl, task-004-impl

## Description

Write `superpowers/tests/test_retro_events_sh.py` covering the cross-cutting property that all three channel wrappers share `retro-events.sh` and `utils.sh` without re-evaluating the deps check or emitting duplicate stderr warnings. This is the only property that genuinely requires all three wrappers to exist simultaneously — it cannot be tested per-wrapper.

The Red state of this task is reached only after 002-impl/003-impl/004-impl have shipped (the test logic itself is verifying a property of how those wrappers source the shared core; before the wrappers exist, the test cannot meaningfully express the property — only file-not-found errors). The test depends on the three impls existing.

## Execution Context

**Task Number**: 005-test of 15
**Phase**: Core Features (Red — cross-cutting)
**Prerequisites**: All three wrapper impls landed.

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

- Create: `superpowers/tests/test_retro_events_sh.py`

## Steps

### Step 1: Verify Scenario
- Confirm `bdd-specs.md` §1.5 carries the scenario above.
- Cross-reference `architecture.md` §`lib/retro-events.sh` — the shared core sources `utils.sh` exactly once via the `_SUPERPOWERS_DEPS_CHECKED` guard.

### Step 2: Implement Test (Red)
- `class RetroEventsSharedCoreTests(unittest.TestCase)`:
  - `test_three_wrappers_share_utils_sh_single_source` — write a `tempfile.TemporaryDirectory` project root, write a small bash driver that:
    ```bash
    #!/usr/bin/env bash
    set -euo pipefail
    SOURCES=0
    # Wrap source of utils.sh to count invocations
    _orig_source=$(declare -f source 2>/dev/null) || true
    # Or — simpler — instrument utils.sh itself: BASH_SOURCE tracking via PS4 + `set -x` is messy.
    # Cleanest: rely on _SUPERPOWERS_DEPS_CHECKED being set after the first source. Assert
    # that after sourcing all three wrappers, the var is exported as 1 and the deps-check
    # function has not been re-entered.
    source lib/observations.sh
    source lib/evolution-log.sh
    source lib/skill-events.sh
    echo "DEPS_CHECKED=${_SUPERPOWERS_DEPS_CHECKED:-unset}"
    ```
    The Python test:
    - copies the three lib files + `retro-events.sh` + `utils.sh` into the tempdir under `lib/`
    - invokes the driver via `subprocess.run`, capturing stdout + stderr
    - asserts stdout contains `DEPS_CHECKED=1` exactly once
    - asserts stderr does NOT contain duplicate deps-missing warning lines (count unique warnings if any).
  - `test_sourcing_order_independent` — same as above but permute the source order across three runs (3 permutations is enough — the test is parametric over order, not exhaustive). Assert `DEPS_CHECKED=1` in every run.
  - `test_wrappers_set_their_loaded_guards` — after sourcing each wrapper, assert `_OBSERVATIONS_LOADED`, `_EVOLUTION_LOG_LOADED`, `_SKILL_EVENTS_LOADED`, `_RETRO_EVENTS_LOADED` are all set to `1`.
  - `test_re_sourcing_is_idempotent` — source each wrapper twice in succession; assert no duplicate stderr warnings, the `LOADED` guards return early, and the function definitions remain intact (can call `log_*` and get the same exit-0 behavior).
- **PROHIBITED**: do not modify any production code in this task.

### Step 3: Verify Test Fails (Red)
- Run `cd superpowers && python3 -m unittest tests.test_retro_events_sh -v`.
- **Expected failure modes**:
  - If the wrappers don't define `_*_LOADED` guards yet (likely the case after 002/003/004 impl if the implementer was minimal): the idempotent-resourcing test fails.
  - If `retro-events.sh` doesn't propagate `_SUPERPOWERS_DEPS_CHECKED` correctly across re-sources, the first test fails.
- Confirm the test fails with a meaningful assertion, not a Python `ImportError`.

## Verification Commands

```bash
cd /Users/FradSer/Developer/FradSer/dotclaude/superpowers
python3 -m unittest tests.test_retro_events_sh -v
echo "Expected non-zero exit code (Red): $?"
```

## Success Criteria

- `superpowers/tests/test_retro_events_sh.py` exists with a `RetroEventsSharedCoreTests` TestCase.
- Tests fail with meaningful assertion errors (the `_*_LOADED` guards are not yet implemented or the idempotency property is not yet satisfied).
- No production code touched.
