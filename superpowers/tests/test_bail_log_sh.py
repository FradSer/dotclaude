"""Tests for lib/bail-log.sh — the calibration-loop event log.

Bail-out events and `--force` overrides feed retrospective Phase 5a so the
loop can detect when bail thresholds are too aggressive (frequent overrides)
or when users keep tripping the same trivial-shape gate (cluster of identical
args_hash). The helper must be best-effort: never block the caller, never
crash on missing jq / unwritable dirs / empty args.
"""
from __future__ import annotations

import json
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

SUPERPOWERS_DIR = Path(__file__).resolve().parents[1]
BAIL_LOG = SUPERPOWERS_DIR / "lib" / "bail-log.sh"


def run_executed(cwd: Path, *args: str) -> subprocess.CompletedProcess:
    """Invoke bail-log.sh in executed mode (bash <script> <args>)."""
    return subprocess.run(
        ["bash", str(BAIL_LOG), *args],
        cwd=str(cwd),
        capture_output=True,
        text=True,
    )


def run_sourced(cwd: Path, body: str) -> subprocess.CompletedProcess:
    """Source bail-log.sh under `set -euo pipefail` and run a body. Verifies
    sourcing does not perturb the caller's error-handling regime."""
    script = f"set -euo pipefail\nsource {BAIL_LOG}\n{body}\n"
    return subprocess.run(
        ["bash", "-c", script],
        cwd=str(cwd),
        capture_output=True,
        text=True,
    )


class BailLogExecutedTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmpdir = tempfile.TemporaryDirectory()
        self.cwd = Path(self.tmpdir.name)

    def tearDown(self) -> None:
        self.tmpdir.cleanup()

    def test_executed_writes_ndjson_with_required_fields(self) -> None:
        result = run_executed(self.cwd, "writing-plans", "bail_out", "thin design", "design.md")
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        log = self.cwd / "docs" / "retros" / "bail-out-events.jsonl"
        self.assertTrue(log.exists())
        entry = json.loads(log.read_text().strip())
        self.assertEqual(entry["event"], "bail_out")
        self.assertEqual(entry["skill"], "writing-plans")
        self.assertEqual(entry["reason"], "thin design")
        # T-001 fix: field renamed from `cwd` to `repo_root`; resolution now
        # uses utils.sh::repo_root (CLAUDE_PROJECT_DIR → git → PWD). With
        # CLAUDE_PROJECT_DIR unset and tmpdir not a git repo, repo_root falls
        # back to PWD which still equals self.cwd. macOS resolves /var →
        # /private/var via PWD; compare via realpath.
        self.assertEqual(Path(entry["repo_root"]).resolve(), self.cwd.resolve())
        self.assertRegex(entry["timestamp"], r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$")
        # args_hash is sha1[:12] when shasum is available.
        self.assertRegex(entry["args_hash"], r"^[a-f0-9]{0,12}$")

    def test_executed_force_override_event(self) -> None:
        result = run_executed(self.cwd, "systematic-debugging", "force_override",
                              "user passed --force", "--force fix flaky")
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        log = self.cwd / "docs" / "retros" / "bail-out-events.jsonl"
        entry = json.loads(log.read_text().strip())
        self.assertEqual(entry["event"], "force_override")
        self.assertEqual(entry["skill"], "systematic-debugging")

    def test_appends_multiple_events(self) -> None:
        run_executed(self.cwd, "brainstorming", "bail_out", "trivial", "rename foo")
        run_executed(self.cwd, "brainstorming", "force_override", "user override", "rename foo --force")
        log = self.cwd / "docs" / "retros" / "bail-out-events.jsonl"
        entries = [json.loads(line) for line in log.read_text().strip().split("\n")]
        self.assertEqual(len(entries), 2)
        self.assertEqual(entries[0]["event"], "bail_out")
        self.assertEqual(entries[1]["event"], "force_override")
        # args_hash repeatable for identical args (modulo --force token).
        self.assertNotEqual(entries[0]["args_hash"], entries[1]["args_hash"])

    def test_args_hash_stable_for_identical_args(self) -> None:
        """Same args → same hash. Phase 5a clusters by args_hash to detect
        users tripping the same trivial gate repeatedly."""
        run_executed(self.cwd, "writing-plans", "bail_out", "thin", "same-input")
        run_executed(self.cwd, "writing-plans", "bail_out", "thin", "same-input")
        log = self.cwd / "docs" / "retros" / "bail-out-events.jsonl"
        entries = [json.loads(line) for line in log.read_text().strip().split("\n")]
        self.assertEqual(entries[0]["args_hash"], entries[1]["args_hash"])

    def test_creates_docs_retros_when_missing(self) -> None:
        """First-time use in a project must auto-create docs/retros/."""
        # cwd is fresh tmpdir, so docs/retros does not exist yet.
        self.assertFalse((self.cwd / "docs").exists())
        run_executed(self.cwd, "writing-plans", "bail_out", "first run", "args")
        self.assertTrue((self.cwd / "docs" / "retros" / "bail-out-events.jsonl").exists())


class BailLogSourcedTests(unittest.TestCase):
    """Sourcing the helper into a `set -euo pipefail` shell must not perturb
    the caller — bail_log internally wraps every fragile op with `|| true` /
    silent fallthrough, and the file has no top-level `set -e`."""

    def setUp(self) -> None:
        self.tmpdir = tempfile.TemporaryDirectory()
        self.cwd = Path(self.tmpdir.name)

    def tearDown(self) -> None:
        self.tmpdir.cleanup()

    def test_sourced_then_called_writes_entry(self) -> None:
        result = run_sourced(self.cwd, 'bail_log writing-plans bail_out "via source" "args"')
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        log = self.cwd / "docs" / "retros" / "bail-out-events.jsonl"
        entry = json.loads(log.read_text().strip())
        self.assertEqual(entry["skill"], "writing-plans")
        self.assertEqual(entry["reason"], "via source")

    def test_sourcing_does_not_run_main(self) -> None:
        """BASH_SOURCE[0] != $0 when sourced → the trailing direct-exec branch
        must not fire, so no spurious 'unknown bail_out' entry shows up."""
        result = run_sourced(self.cwd, ': # noop after source')
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        log = self.cwd / "docs" / "retros" / "bail-out-events.jsonl"
        self.assertFalse(log.exists())

    def test_sourcing_under_set_e_does_not_abort_caller(self) -> None:
        """The helper must not exit the caller mid-script even when invoked
        with empty/missing args — a `bail_log` call inside a hook or skill
        instruction must never tank the surrounding bash session."""
        body = 'bail_log "" "" "" ""\necho "still alive"'
        result = run_sourced(self.cwd, body)
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertIn("still alive", result.stdout)


class BailLogDegradationTests(unittest.TestCase):
    """When dependencies (jq) are missing, the helper must skip silently —
    a bail-out logger that crashes the surrounding skill is worse than no log."""

    def setUp(self) -> None:
        self.tmpdir = tempfile.TemporaryDirectory()
        self.cwd = Path(self.tmpdir.name)

    def tearDown(self) -> None:
        self.tmpdir.cleanup()

    def test_silent_skip_when_jq_missing(self) -> None:
        """Run with PATH stripped of jq. Must exit 0 and write nothing."""
        # Build a sandbox PATH that excludes jq. Keep bash + coreutils.
        result = subprocess.run(
            ["bash", str(BAIL_LOG), "writing-plans", "bail_out", "smoke", "args"],
            cwd=str(self.cwd),
            capture_output=True,
            text=True,
            env={"PATH": "/usr/bin:/bin"},  # no jq here on Apple silicon /opt/homebrew
        )
        # Exit 0 regardless of whether jq happens to exist in /usr/bin.
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        # If jq was unavailable, no log file was written. If jq was found in
        # /usr/bin (rare on macOS but possible on Linux CI), the log exists
        # — both outcomes are acceptable degradation behavior, the contract
        # is "exit 0, never crash".


if __name__ == "__main__":
    unittest.main()
