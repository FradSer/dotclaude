"""Tests for lib/observations.sh — the terse-row harness-observations
helper that retrospective Phase 5c's refusal gate will call.

Mirrors the three-mode structure of `tests/test_bail_log_sh.py`:
Executed / Sourced / Degradation. Until `lib/observations.sh` lands
these tests fail at the file-not-found stage — that is the intended
Red state for task 002-impl to turn Green.

Spec source: docs/plans/2026-05-12-unified-retro-events-design/bdd-specs.md
§1.3 (parity row shape), §2 (best-effort degradation), §5.3 (existing
rows never rewritten).
"""
from __future__ import annotations

import json
import os
import shutil
import stat
import subprocess
import tempfile
import unittest
from pathlib import Path

SUPERPOWERS_DIR = Path(__file__).resolve().parents[1]
OBSERVATIONS = SUPERPOWERS_DIR / "lib" / "observations.sh"

# The terse-row schema lives in
# docs/plans/2026-05-12-unified-retro-events-design/architecture.md
# §`lib/observations.sh`. Keys are listed in the order architecture.md
# specifies; the helper's `jq -nc` filter MUST emit them in this order
# so byte-equality with the captured fixtures (task 006) holds.
EXPECTED_KEYS = ["event", "component", "reason", "repo_root", "timestamp"]

ISO_UTC_REGEX = r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$"


def run_executed(
    cwd: Path,
    *args: str,
    env: dict[str, str] | None = None,
) -> subprocess.CompletedProcess:
    """Invoke observations.sh in executed mode."""
    return subprocess.run(
        ["bash", str(OBSERVATIONS), *args],
        cwd=str(cwd),
        capture_output=True,
        text=True,
        env=env,
    )


def run_sourced(
    cwd: Path,
    body: str,
    env: dict[str, str] | None = None,
) -> subprocess.CompletedProcess:
    """Source observations.sh under `set -euo pipefail` and run a body.
    Verifies sourcing does not perturb the caller's error-handling regime."""
    script = f"set -euo pipefail\nsource {OBSERVATIONS}\n{body}\n"
    return subprocess.run(
        ["bash", "-c", script],
        cwd=str(cwd),
        capture_output=True,
        text=True,
        env=env,
    )


class ObservationsExecutedTests(unittest.TestCase):
    """`bash lib/observations.sh <component> <outcome> <reason>` path."""

    def setUp(self) -> None:
        self.tmpdir = tempfile.TemporaryDirectory()
        self.cwd = Path(self.tmpdir.name)

    def tearDown(self) -> None:
        self.tmpdir.cleanup()

    def _log_path(self) -> Path:
        return self.cwd / "docs" / "retros" / "harness-observations.jsonl"

    def test_executed_writes_one_ndjson_row(self) -> None:
        """Happy path: helper exits 0 and writes exactly one valid NDJSON line."""
        result = run_executed(
            self.cwd, "plan_evaluator", "component_unsupported", "removed in v2.6.0"
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        log = self._log_path()
        self.assertTrue(log.exists(), "harness-observations.jsonl was not created")
        lines = log.read_text().splitlines()
        self.assertEqual(len(lines), 1, msg=f"expected one row, got: {lines!r}")
        entry = json.loads(lines[0])
        self.assertIsInstance(entry, dict)

    def test_executed_row_has_terse_schema_keys(self) -> None:
        """The row's key set equals {event, component, reason, repo_root,
        timestamp} — no extras, no missing keys (architecture.md
        `lib/observations.sh` schema table)."""
        result = run_executed(
            self.cwd, "evaluator_per_batch", "unsupported", "smoke reason"
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        entry = json.loads(self._log_path().read_text().strip())
        self.assertEqual(set(entry.keys()), set(EXPECTED_KEYS))

    def test_executed_event_field_carries_outcome_arg(self) -> None:
        """The `event` field on disk equals the `<outcome>` positional arg."""
        result = run_executed(
            self.cwd, "evaluator_per_batch", "component_unsupported", "smoke"
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        entry = json.loads(self._log_path().read_text().strip())
        self.assertEqual(entry["event"], "component_unsupported")
        self.assertEqual(entry["component"], "evaluator_per_batch")
        self.assertEqual(entry["reason"], "smoke")

    def test_executed_timestamp_is_iso8601_utc(self) -> None:
        """`timestamp` matches `YYYY-MM-DDTHH:MM:SSZ` (UTC). Asserted via
        regex rather than direct equality because the helper resolves
        `now` at run time."""
        result = run_executed(self.cwd, "evaluator_per_batch", "unsupported", "")
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        entry = json.loads(self._log_path().read_text().strip())
        self.assertRegex(entry["timestamp"], ISO_UTC_REGEX)

    def test_executed_repo_root_resolves_to_cwd(self) -> None:
        """With no `CLAUDE_PROJECT_DIR` and tmpdir not a git repo,
        `repo_root` falls back to `$PWD` (utils.sh::repo_root). macOS
        resolves /var → /private/var via PWD so compare via realpath."""
        result = run_executed(self.cwd, "evaluator_per_batch", "unsupported", "")
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        entry = json.loads(self._log_path().read_text().strip())
        self.assertEqual(
            Path(entry["repo_root"]).resolve(), self.cwd.resolve()
        )

    def test_executed_preserves_prior_rows_byte_for_byte(self) -> None:
        """Append-only contract (§5.3): an existing row must be unchanged
        after the helper writes a second row to the same file."""
        log = self._log_path()
        log.parent.mkdir(parents=True, exist_ok=True)
        legacy = (
            '{"event":"component_unsupported","component":"plan_evaluator",'
            '"timestamp":"2026-04-01T12:00:00Z","retrospective_id":"docs/retros/r.md"}\n'
        )
        log.write_bytes(legacy.encode())
        result = run_executed(
            self.cwd, "evaluator_per_batch", "unsupported", "second row"
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        raw = log.read_bytes()
        # The legacy row is line 1, byte-for-byte unchanged.
        self.assertTrue(
            raw.startswith(legacy.encode()),
            msg=f"prior row mutated; got first line bytes: {raw[: len(legacy)]!r}",
        )
        # Total line count is 2.
        self.assertEqual(len(raw.decode().splitlines()), 2)


class ObservationsSourcedTests(unittest.TestCase):
    """`source lib/observations.sh; log_harness_observation ...` path.
    Sourcing under `set -euo pipefail` must not perturb the caller."""

    def setUp(self) -> None:
        self.tmpdir = tempfile.TemporaryDirectory()
        self.cwd = Path(self.tmpdir.name)

    def tearDown(self) -> None:
        self.tmpdir.cleanup()

    def test_sourced_then_called_writes_entry(self) -> None:
        body = (
            'log_harness_observation evaluator_per_batch '
            '"component_unsupported" "via source"'
        )
        result = run_sourced(self.cwd, body)
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        log = self.cwd / "docs" / "retros" / "harness-observations.jsonl"
        self.assertTrue(log.exists())
        entry = json.loads(log.read_text().strip())
        self.assertEqual(entry["component"], "evaluator_per_batch")
        self.assertEqual(entry["reason"], "via source")

    def test_sourcing_under_set_e_does_not_abort_caller(self) -> None:
        """Empty args must not crash the surrounding shell — the still-alive
        marker has to reach stdout."""
        body = 'log_harness_observation "" "" ""\necho still-alive'
        result = run_sourced(self.cwd, body)
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertIn("still-alive", result.stdout)


class ObservationsDegradationTests(unittest.TestCase):
    """When the environment is hostile (no jq, read-only fs, no repo root,
    no `date`) the helper returns 0 silently. Same contract as
    `bail-log.sh`: a write failure must never tank the caller."""

    def setUp(self) -> None:
        self.tmpdir = tempfile.TemporaryDirectory()
        self.cwd = Path(self.tmpdir.name)

    def tearDown(self) -> None:
        # Restore writable so cleanup succeeds even if a test chmod'd cwd.
        # `os.chmod` may raise on already-cleaned paths; swallow it via the
        # truthy guard rather than a try/except with a lone `pass` body.
        if self.cwd.exists():
            os.chmod(self.cwd, 0o700)
        self.tmpdir.cleanup()

    def _log_path(self) -> Path:
        return self.cwd / "docs" / "retros" / "harness-observations.jsonl"

    def test_silent_skip_when_jq_missing(self) -> None:
        """PATH stripped of jq. Helper must exit 0; on macOS where jq
        only lives in /opt/homebrew/bin, no log file appears. On Linux CI
        where /usr/bin/jq exists, the write may still succeed — both
        outcomes are valid degradation per `bail-log.sh` precedent."""
        result = subprocess.run(
            [
                "bash",
                str(OBSERVATIONS),
                "evaluator_per_batch",
                "unsupported",
                "no-jq smoke",
            ],
            cwd=str(self.cwd),
            capture_output=True,
            text=True,
            env={"PATH": "/usr/bin:/bin"},
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        if not _jq_in(["/usr/bin", "/bin"]):
            self.assertFalse(
                self._log_path().exists(),
                msg="log was written despite missing jq",
            )

    def test_returns_zero_when_docs_retros_unwritable(self) -> None:
        """`mkdir -p docs/retros` fails when cwd is read-only. The helper
        must return 0 and write nothing — no fallback path elsewhere."""
        # Make the project root read-only so `mkdir -p docs/retros` fails.
        os.chmod(self.cwd, stat.S_IRUSR | stat.S_IXUSR)
        try:
            result = run_executed(
                self.cwd, "evaluator_per_batch", "unsupported", "ro fs"
            )
        finally:
            # Restore for tearDown's cleanup pass.
            os.chmod(self.cwd, 0o700)
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertFalse(self._log_path().exists())

    def test_returns_zero_when_repo_root_empty(self) -> None:
        """With CLAUDE_PROJECT_DIR unset, PWD unset, and cwd not a git
        repo, `utils.sh::repo_root` returns empty. The helper must short-
        circuit before any file operation."""
        # Sanitize the env: bash needs PATH for `command -v jq`, but
        # neither CLAUDE_PROJECT_DIR nor PWD may be set.
        env = {
            "PATH": os.environ.get("PATH", "/usr/bin:/bin"),
        }
        result = subprocess.run(
            ["bash", str(OBSERVATIONS), "evaluator_per_batch", "unsupported", ""],
            cwd="/",  # outside any git repo
            capture_output=True,
            text=True,
            env=env,
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertFalse(self._log_path().exists())

    def test_returns_zero_when_date_fails(self) -> None:
        """A shimmed `date` that always exits non-zero must not crash the
        helper — `timestamp_or_skip` returns 1 and the helper returns 0."""
        shim_dir = Path(self.tmpdir.name) / "shim-bin"
        shim_dir.mkdir()
        date_shim = shim_dir / "date"
        date_shim.write_text("#!/usr/bin/env bash\nexit 1\n")
        date_shim.chmod(0o755)
        # PATH-prepend the shim so `date` resolves to it first. Keep
        # /usr/bin and /bin so jq and bash builtins remain reachable; on
        # this host jq lives at /usr/bin/jq.
        env = {
            "PATH": f"{shim_dir}:/usr/bin:/bin",
        }
        result = run_executed(
            self.cwd,
            "evaluator_per_batch",
            "unsupported",
            "date-fail smoke",
            env=env,
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertFalse(self._log_path().exists())


def _jq_in(dirs: list[str]) -> bool:
    """True iff `jq` is found in any of the given directories. Used to
    branch the no-jq-PATH degradation assertion: when jq does live in
    /usr/bin, the write succeeds and we can only assert exit 0."""
    return any(shutil.which("jq", path=d) for d in dirs)


if __name__ == "__main__":
    unittest.main()
