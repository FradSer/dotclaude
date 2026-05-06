"""Regression tests for the mkdir-based state-file lock in lib/utils.sh.

Covers the async race fix between PostToolUse track-changes.sh and sync
UserPromptSubmit task-start.sh, plus the deep-fix follow-ups:
  * release_state_lock must be PID-aware (don't clobber another holder)
  * state_update must fall back to unlocked write on lock timeout
    (silent drops would lose vet's task-synthesis result)
"""

import json
import os
import shlex
import subprocess
import tempfile
import time
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SUPERPOWERS = ROOT / "superpowers"
UTILS = SUPERPOWERS / "lib" / "utils.sh"


def run_bash(script: str, **kwargs) -> subprocess.CompletedProcess:
    """Run a bash script with utils.sh sourced. Returns CompletedProcess."""
    full = f"set +e\nsource {shlex.quote(str(UTILS))}\n{script}"
    return subprocess.run(
        ["bash", "-c", full],
        text=True,
        capture_output=True,
        **kwargs,
    )


class StateLockTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmpdir = tempfile.TemporaryDirectory()
        self.state = Path(self.tmpdir.name) / "test.json"
        self.state.write_text('{"x": 0}')
        self.lockdir = Path(str(self.state) + ".lock")

    def tearDown(self) -> None:
        self.tmpdir.cleanup()

    # ---- acquire / release primitives ----

    def test_acquire_creates_lockdir_with_pid_file(self) -> None:
        result = run_bash(
            f"acquire_state_lock {shlex.quote(str(self.state))} && cat {shlex.quote(str(self.lockdir / 'pid'))}"
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertTrue(self.lockdir.is_dir())
        # PID file exists and contains a numeric value
        self.assertTrue((self.lockdir / "pid").is_file())
        self.assertTrue(result.stdout.strip().isdigit())

    def test_release_with_matching_pid_removes_lockdir(self) -> None:
        result = run_bash(
            f"acquire_state_lock {shlex.quote(str(self.state))} && "
            f"release_state_lock {shlex.quote(str(self.state))}"
        )
        self.assertEqual(result.returncode, 0)
        self.assertFalse(self.lockdir.exists())

    def test_release_does_not_clobber_other_processes_lock(self) -> None:
        # Plant a lock owned by a different PID (init/launchd is always alive).
        self.lockdir.mkdir()
        (self.lockdir / "pid").write_text("1\n")

        result = run_bash(
            f"release_state_lock {shlex.quote(str(self.state))} && echo ok"
        )
        self.assertEqual(result.returncode, 0)
        self.assertIn("ok", result.stdout)
        # CRITICAL: other process's lock must remain intact
        self.assertTrue(self.lockdir.is_dir())
        self.assertEqual((self.lockdir / "pid").read_text().strip(), "1")

    def test_release_is_noop_when_no_lock_held(self) -> None:
        result = run_bash(
            f"release_state_lock {shlex.quote(str(self.state))} && echo ok"
        )
        self.assertEqual(result.returncode, 0)
        self.assertIn("ok", result.stdout)
        self.assertFalse(self.lockdir.exists())

    def test_release_is_noop_on_partial_init_lockdir_without_pid_file(self) -> None:
        # Bare lockdir (mkdir succeeded but pid write didn't yet land) — release
        # must not touch it; acquire is responsible for stale recovery.
        self.lockdir.mkdir()
        result = run_bash(
            f"release_state_lock {shlex.quote(str(self.state))} && echo ok"
        )
        self.assertEqual(result.returncode, 0)
        self.assertTrue(self.lockdir.is_dir())

    # ---- stale lock recovery ----

    def test_stale_lock_with_dead_pid_is_reclaimed(self) -> None:
        self.lockdir.mkdir()
        # PID 999999 is overwhelmingly likely to be unused
        (self.lockdir / "pid").write_text("999999\n")

        start = time.monotonic()
        # timeout=10 = 1s, plenty for stale reclaim
        result = run_bash(
            f"acquire_state_lock {shlex.quote(str(self.state))} 10 && "
            f"release_state_lock {shlex.quote(str(self.state))}"
        )
        elapsed = time.monotonic() - start

        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertLess(elapsed, 1.0, msg=f"stale reclaim took {elapsed:.2f}s")
        self.assertFalse(self.lockdir.exists())

    def test_acquire_times_out_when_holder_is_alive(self) -> None:
        # PID 1 (init/launchd) is always alive on macOS/Linux
        self.lockdir.mkdir()
        (self.lockdir / "pid").write_text("1\n")

        start = time.monotonic()
        # timeout=5 = 0.5s
        result = run_bash(
            f"acquire_state_lock {shlex.quote(str(self.state))} 5 || echo TIMED_OUT"
        )
        elapsed = time.monotonic() - start

        self.assertIn("TIMED_OUT", result.stdout)
        self.assertGreaterEqual(elapsed, 0.4)
        self.assertLess(elapsed, 1.0)
        # Other process's lock untouched
        self.assertTrue(self.lockdir.is_dir())

    # ---- state_update integration ----

    def test_state_update_modifies_field_under_lock(self) -> None:
        result = run_bash(
            f'state_update {shlex.quote(str(self.state))} --argjson n 42 ".x = \\$n"'
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertEqual(json.loads(self.state.read_text())["x"], 42)
        self.assertFalse(self.lockdir.exists())

    def test_concurrent_state_updates_preserve_all_appends(self) -> None:
        self.state.write_text('{"items": []}')
        # 5 concurrent appends; without locking at least one is typically lost
        # to mv-clobbering — here every value must survive.
        cmds = "\n".join(
            f'state_update {shlex.quote(str(self.state))} --arg p item_{i} '
            f'".items += [\\$p]" &'
            for i in range(5)
        )
        result = run_bash(cmds + "\nwait\n")
        self.assertEqual(result.returncode, 0, msg=result.stderr)

        items = json.loads(self.state.read_text())["items"]
        self.assertEqual(len(items), 5, msg=f"lost updates: {items}")
        self.assertEqual(set(items), {f"item_{i}" for i in range(5)})
        self.assertFalse(self.lockdir.exists())

    def test_state_update_falls_back_to_unlocked_write_on_lock_timeout(self) -> None:
        # Force the timeout branch by overriding acquire_state_lock to fail.
        # The fallback must STILL apply the update and emit a stderr warning,
        # otherwise vet's task synthesis would silently drop on contention.
        script = f"""
acquire_state_lock() {{ return 1; }}
state_update {shlex.quote(str(self.state))} --argjson n 99 '.x = $n'
"""
        result = run_bash(script)
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertIn("warning", result.stderr.lower())
        self.assertIn("lock timeout", result.stderr.lower())
        self.assertEqual(
            json.loads(self.state.read_text())["x"],
            99,
            msg="state_update silently dropped update on lock timeout",
        )


if __name__ == "__main__":
    unittest.main()
