"""Tests for the cross-cutting shared-core single-source property.

The three retro channel wrappers (`observations.sh`, `evolution-log.sh`,
`skill-events.sh`) all source `retro-events.sh`, which in turn sources
`utils.sh` exactly once. When two or more wrappers are sourced in the
same shell session, the deps check must not be re-evaluated, no
duplicate stderr warnings appear, and each wrapper exposes an
idempotent `_*_LOADED` guard so re-sourcing is a no-op.

This test only makes sense after `observations.sh`, `evolution-log.sh`,
and `skill-events.sh` all exist (Batches 1 and 2 shipped them). The
Red state is reached before Batch 3 task 005-impl adds the
`_OBSERVATIONS_LOADED` guard to `observations.sh`.

Spec source: docs/plans/2026-05-12-unified-retro-events-design/bdd-specs.md §1.5.
"""
from __future__ import annotations

import itertools
import subprocess
import unittest
from pathlib import Path

SUPERPOWERS_DIR = Path(__file__).resolve().parents[1]
LIB_DIR = SUPERPOWERS_DIR / "lib"

OBSERVATIONS = LIB_DIR / "observations.sh"
EVOLUTION_LOG = LIB_DIR / "evolution-log.sh"
SKILL_EVENTS = LIB_DIR / "skill-events.sh"
RETRO_EVENTS = LIB_DIR / "retro-events.sh"

WRAPPER_FILES = [OBSERVATIONS, EVOLUTION_LOG, SKILL_EVENTS]

# Each wrapper sets its own `_<NAME>_LOADED=1` after sourcing
# `retro-events.sh` so a second source short-circuits at the top.
WRAPPER_GUARDS = {
    OBSERVATIONS: "_OBSERVATIONS_LOADED",
    EVOLUTION_LOG: "_EVOLUTION_LOG_LOADED",
    SKILL_EVENTS: "_SKILL_EVENTS_LOADED",
}


def run_bash(script: str, env: dict[str, str] | None = None) -> subprocess.CompletedProcess:
    """Run a bash -c script and capture stdout/stderr/exit_code."""
    return subprocess.run(
        ["bash", "-c", script],
        capture_output=True,
        text=True,
        env=env,
    )


def _source_all_script(order: list[Path]) -> str:
    """Build a bash script that sources the listed wrappers in order and
    prints diagnostic markers stdout the test will assert on."""
    lines = ["set -euo pipefail"]
    for path in order:
        lines.append(f"source {path}")
    lines.append('printf "DEPS_CHECKED=%s\\n" "${_SUPERPOWERS_DEPS_CHECKED:-unset}"')
    lines.append('printf "RETRO_EVENTS_LOADED=%s\\n" "${_RETRO_EVENTS_LOADED:-unset}"')
    lines.append('printf "OBSERVATIONS_LOADED=%s\\n" "${_OBSERVATIONS_LOADED:-unset}"')
    lines.append('printf "EVOLUTION_LOG_LOADED=%s\\n" "${_EVOLUTION_LOG_LOADED:-unset}"')
    lines.append('printf "SKILL_EVENTS_LOADED=%s\\n" "${_SKILL_EVENTS_LOADED:-unset}"')
    return "\n".join(lines) + "\n"


def _count_dup_warnings(stderr: str) -> int:
    """Count how many times any single deps-missing warning line repeats.
    Returns the max repeat count across distinct warning lines. A repeat
    count >1 indicates the deps check ran more than once."""
    counts: dict[str, int] = {}
    for line in stderr.splitlines():
        if "superpowers requires" in line and "did not find it" in line:
            counts[line] = counts.get(line, 0) + 1
    return max(counts.values(), default=0)


class RetroEventsSharedCoreTests(unittest.TestCase):
    """Cross-cutting invariants that span all three wrappers."""

    def test_three_wrappers_share_utils_sh_single_source(self) -> None:
        """Sourcing all three wrappers in one shell must set
        `_SUPERPOWERS_DEPS_CHECKED=1` exactly once. The deps check loop
        inside `utils.sh` self-guards on this flag, so a second source
        of `utils.sh` from a sibling wrapper is a no-op. No deps-missing
        warning may repeat on stderr."""
        script = _source_all_script([OBSERVATIONS, EVOLUTION_LOG, SKILL_EVENTS])
        result = run_bash(script)
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertIn("DEPS_CHECKED=1", result.stdout)
        # The DEPS_CHECKED marker is printed exactly once by the driver,
        # but the variable being set to 1 is the load-bearing assertion.
        self.assertEqual(result.stdout.count("DEPS_CHECKED=1"), 1)
        # No deps-missing warning may repeat across the three wrapper sources.
        self.assertLessEqual(
            _count_dup_warnings(result.stderr),
            1,
            msg=f"duplicate deps-missing warning detected; stderr was:\n{result.stderr}",
        )

    def test_sourcing_order_independent(self) -> None:
        """Permute the source order; every permutation must yield
        `DEPS_CHECKED=1` and all four `*_LOADED` guards set. The
        invariant must not depend on which wrapper sources first."""
        # itertools.permutations is exhaustive; six orderings is cheap.
        for order in itertools.permutations(WRAPPER_FILES):
            with self.subTest(order=[p.name for p in order]):
                script = _source_all_script(list(order))
                result = run_bash(script)
                self.assertEqual(result.returncode, 0, msg=result.stderr)
                self.assertIn("DEPS_CHECKED=1", result.stdout)
                self.assertIn("RETRO_EVENTS_LOADED=1", result.stdout)
                self.assertIn("OBSERVATIONS_LOADED=1", result.stdout)
                self.assertIn("EVOLUTION_LOG_LOADED=1", result.stdout)
                self.assertIn("SKILL_EVENTS_LOADED=1", result.stdout)

    def test_wrappers_set_their_loaded_guards(self) -> None:
        """After sourcing each wrapper exactly once (and in turn,
        `retro-events.sh`), every `_*_LOADED` flag must be `1`. This is
        the property 005-impl introduces — observations.sh currently
        ships without an `_OBSERVATIONS_LOADED` guard, so the Red state
        of this test is reached before the impl phase."""
        script = _source_all_script([OBSERVATIONS, EVOLUTION_LOG, SKILL_EVENTS])
        result = run_bash(script)
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        for guard in ("_RETRO_EVENTS_LOADED", "_OBSERVATIONS_LOADED",
                      "_EVOLUTION_LOG_LOADED", "_SKILL_EVENTS_LOADED"):
            # The driver formats each guard as `<NAME without leading _>=1`.
            marker = f"{guard.lstrip('_')}=1"
            self.assertIn(
                marker,
                result.stdout,
                msg=f"missing guard marker {marker!r}; stdout was:\n{result.stdout}",
            )

    def test_re_sourcing_is_idempotent(self) -> None:
        """Source each wrapper twice in succession. The second source
        must short-circuit at the `_*_LOADED` guard at the top of the
        file, producing no duplicate deps-missing warning and leaving
        the function definitions intact (still callable). The
        before-and-after `_SUPERPOWERS_DEPS_CHECKED` value must remain
        `1` across the second pass — the deps loop must not re-run."""
        lines = ["set -euo pipefail"]
        # Double-source each wrapper.
        for path in WRAPPER_FILES * 2:
            lines.append(f"source {path}")
        # Call each function — they must still be defined after the
        # second source so the guard did not corrupt the symbol table.
        lines.append("declare -F log_harness_observation >/dev/null && echo HAS_OBS")
        lines.append("declare -F log_evolution_event   >/dev/null && echo HAS_EVO")
        lines.append("declare -F log_skill_event       >/dev/null && echo HAS_SKL")
        lines.append('printf "DEPS_CHECKED=%s\\n" "${_SUPERPOWERS_DEPS_CHECKED:-unset}"')
        script = "\n".join(lines) + "\n"
        result = run_bash(script)
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertIn("HAS_OBS", result.stdout)
        self.assertIn("HAS_EVO", result.stdout)
        self.assertIn("HAS_SKL", result.stdout)
        self.assertIn("DEPS_CHECKED=1", result.stdout)
        # A re-source must NOT cause the deps loop to re-warn.
        self.assertLessEqual(
            _count_dup_warnings(result.stderr),
            1,
            msg=(
                "deps-missing warning repeated after re-source — guard is not idempotent;"
                f" stderr was:\n{result.stderr}"
            ),
        )


if __name__ == "__main__":
    unittest.main()
