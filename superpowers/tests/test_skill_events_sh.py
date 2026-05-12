"""Tests for lib/skill-events.sh — the skill-events NDJSON helper that
systematic-debugging Phase 4 will call on its success branch.

Mirrors the three-mode structure of `tests/test_bail_log_sh.py`:
Executed / Sourced / Degradation TestCases. Adds a fourth TestCase
covering the `args_hash` derivation (skill-events is the only wrapper
in this design that hashes args). Until `lib/skill-events.sh` lands,
these tests fail at the file-not-found stage — the intended Red state
for task 004-impl to turn Green.

Spec source: docs/plans/2026-05-12-unified-retro-events-design/bdd-specs.md
§1.1, §1.2 (fix_completed envelope), §2 (best-effort degradation).
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
SKILL_EVENTS = SUPERPOWERS_DIR / "lib" / "skill-events.sh"

# The skill-events envelope NESTS the payload (distinct from
# evolution-log.sh which merges). Schema:
#   {event, skill, timestamp, repo_root, args_hash, payload: {...}}
ENVELOPE_KEYS = {"event", "skill", "timestamp", "repo_root", "args_hash", "payload"}

ISO_UTC_REGEX = r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$"
ARGS_HASH_REGEX = r"^[0-9a-f]{12}$"


def run_executed(
    cwd: Path,
    *args: str,
    env: dict[str, str] | None = None,
) -> subprocess.CompletedProcess:
    """Invoke skill-events.sh in executed mode."""
    return subprocess.run(
        ["bash", str(SKILL_EVENTS), *args],
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
    """Source skill-events.sh under `set -euo pipefail` and run a body."""
    script = f"set -euo pipefail\nsource {SKILL_EVENTS}\n{body}\n"
    return subprocess.run(
        ["bash", "-c", script],
        cwd=str(cwd),
        capture_output=True,
        text=True,
        env=env,
    )


def _log_path(cwd: Path) -> Path:
    return cwd / "docs" / "retros" / "skill-events.jsonl"


def _read_one(testcase: unittest.TestCase, cwd: Path) -> dict:
    log = _log_path(cwd)
    testcase.assertTrue(log.exists(), "skill-events.jsonl was not created")
    lines = log.read_text().splitlines()
    testcase.assertEqual(len(lines), 1, msg=f"expected one row, got: {lines!r}")
    return json.loads(lines[0])


class SkillEventsExecutedTests(unittest.TestCase):
    """`bash lib/skill-events.sh <skill> <event> <payload_filter> [args]`."""

    def setUp(self) -> None:
        self.tmpdir = tempfile.TemporaryDirectory()
        self.cwd = Path(self.tmpdir.name)

    def tearDown(self) -> None:
        self.tmpdir.cleanup()

    def test_executed_writes_ndjson_with_required_fields(self) -> None:
        """Happy path: helper exits 0, writes one row with all envelope
        fields populated and a non-empty payload sub-object."""
        result = run_executed(
            self.cwd,
            "systematic-debugging",
            "fix_completed",
            "{root_cause: $rc, fix_paths: ($fp | split(\",\"))}",
            "--arg", "rc", "race in cache",
            "--arg", "fp", "src/cache.ts,tests/cache_test.ts",
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        entry = _read_one(self, self.cwd)
        self.assertEqual(entry["event"], "fix_completed")
        self.assertEqual(entry["skill"], "systematic-debugging")
        self.assertRegex(entry["timestamp"], ISO_UTC_REGEX)
        self.assertEqual(
            Path(entry["repo_root"]).resolve(), self.cwd.resolve()
        )
        self.assertRegex(entry["args_hash"], ARGS_HASH_REGEX)
        # Payload is a nested object — distinct from evolution-log.sh.
        self.assertIsInstance(entry["payload"], dict)
        self.assertEqual(entry["payload"]["root_cause"], "race in cache")
        self.assertEqual(
            entry["payload"]["fix_paths"],
            ["src/cache.ts", "tests/cache_test.ts"],
        )

    def test_payload_keys_do_not_collide_with_envelope(self) -> None:
        """Even if the caller's payload includes a key like `event` or
        `skill`, it must remain inside `payload`, not shadow the envelope.
        The envelope's top-level keys must NEVER appear in payload."""
        result = run_executed(
            self.cwd,
            "systematic-debugging",
            "fix_completed",
            "{event: $e2, skill: $s2, payload_marker: $pm}",
            "--arg", "e2", "INNER_EVENT",
            "--arg", "s2", "INNER_SKILL",
            "--arg", "pm", "marker-value",
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        entry = _read_one(self, self.cwd)
        top_keys = set(entry.keys())
        payload_keys = set(entry["payload"].keys())
        # Top-level envelope fields keep their own values.
        self.assertEqual(entry["event"], "fix_completed")
        self.assertEqual(entry["skill"], "systematic-debugging")
        # Payload's `event`/`skill` live inside payload, not at top.
        self.assertEqual(entry["payload"]["event"], "INNER_EVENT")
        self.assertEqual(entry["payload"]["skill"], "INNER_SKILL")
        # Top-level keys are exactly the envelope set.
        self.assertEqual(top_keys, ENVELOPE_KEYS)
        # All five envelope keys are present in top but not in payload's
        # collision set — payload happens to share `event`/`skill` names
        # but they live under `payload.`, not at top.
        envelope_only = {"timestamp", "repo_root", "args_hash", "payload"}
        self.assertTrue(envelope_only.isdisjoint(payload_keys))

    def test_appends_multiple_events(self) -> None:
        """Two invocations → two distinct lines; first row byte-unchanged."""
        result1 = run_executed(
            self.cwd,
            "systematic-debugging",
            "fix_completed",
            "{root_cause: $rc}",
            "--arg", "rc", "first run",
        )
        self.assertEqual(result1.returncode, 0, msg=result1.stderr)
        log = _log_path(self.cwd)
        first_bytes = log.read_bytes()
        result2 = run_executed(
            self.cwd,
            "systematic-debugging",
            "fix_completed",
            "{root_cause: $rc}",
            "--arg", "rc", "second run",
        )
        self.assertEqual(result2.returncode, 0, msg=result2.stderr)
        raw = log.read_bytes()
        self.assertTrue(
            raw.startswith(first_bytes),
            msg=f"prior row mutated; got first bytes: {raw[: len(first_bytes)]!r}",
        )
        entries = [json.loads(line) for line in raw.decode().splitlines()]
        self.assertEqual(len(entries), 2)
        self.assertEqual(entries[0]["payload"]["root_cause"], "first run")
        self.assertEqual(entries[1]["payload"]["root_cause"], "second run")

    def test_creates_docs_retros_when_missing(self) -> None:
        """Fresh project: docs/retros/ must auto-create on first use."""
        self.assertFalse((self.cwd / "docs").exists())
        result = run_executed(
            self.cwd,
            "systematic-debugging",
            "fix_completed",
            "{root_cause: $rc}",
            "--arg", "rc", "bootstrap",
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertTrue(_log_path(self.cwd).exists())


class SkillEventsSourcedTests(unittest.TestCase):
    """Sourced into a `set -euo pipefail` shell must not perturb caller."""

    def setUp(self) -> None:
        self.tmpdir = tempfile.TemporaryDirectory()
        self.cwd = Path(self.tmpdir.name)

    def tearDown(self) -> None:
        self.tmpdir.cleanup()

    def test_sourced_then_called_writes_entry(self) -> None:
        body = (
            "log_skill_event systematic-debugging fix_completed "
            "'{root_cause: $rc}' "
            '--arg rc "via source"'
        )
        result = run_sourced(self.cwd, body)
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        entry = _read_one(self, self.cwd)
        self.assertEqual(entry["skill"], "systematic-debugging")
        self.assertEqual(entry["event"], "fix_completed")
        self.assertEqual(entry["payload"]["root_cause"], "via source")

    def test_sourcing_does_not_run_main(self) -> None:
        """Sourcing alone (no call) must NOT trigger the dual-mode footer
        and therefore must not produce a jsonl file."""
        result = run_sourced(self.cwd, ": # noop after source")
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertFalse(_log_path(self.cwd).exists())

    def test_sourcing_under_set_e_does_not_abort_caller(self) -> None:
        """Empty args inside `set -euo pipefail` must not crash; the
        still-alive marker must reach stdout."""
        body = (
            "log_skill_event \"\" \"\" \"\" || true\n"
            "echo still-alive"
        )
        result = run_sourced(self.cwd, body)
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertIn("still-alive", result.stdout)

    def test_executed_equals_sourced_modulo_timestamp(self) -> None:
        """Invoke both modes with identical args, strip timestamps,
        assert byte-equal under `jq -S 'del(.timestamp)'`."""
        # Executed run.
        exec_cwd_tmp = tempfile.TemporaryDirectory()
        exec_cwd = Path(exec_cwd_tmp.name)
        try:
            run_executed(
                exec_cwd,
                "systematic-debugging",
                "fix_completed",
                "{root_cause: $rc}",
                "--arg", "rc", "parity-test",
            )
            exec_entry = json.loads(_log_path(exec_cwd).read_text().strip())
        finally:
            exec_cwd_tmp.cleanup()

        # Sourced run.
        body = (
            "log_skill_event systematic-debugging fix_completed "
            "'{root_cause: $rc}' "
            '--arg rc "parity-test"'
        )
        run_sourced(self.cwd, body)
        src_entry = json.loads(_log_path(self.cwd).read_text().strip())

        # Strip timestamps; strip repo_root (different tmpdirs).
        for entry in (exec_entry, src_entry):
            entry.pop("timestamp", None)
            entry.pop("repo_root", None)
        self.assertEqual(exec_entry, src_entry)


class SkillEventsDegradationTests(unittest.TestCase):
    """Hostile environments → exit 0, never crash. Same contract as
    `bail-log.sh` and `observations.sh`."""

    def setUp(self) -> None:
        self.tmpdir = tempfile.TemporaryDirectory()
        self.cwd = Path(self.tmpdir.name)

    def tearDown(self) -> None:
        # Guard clause replaces try/except OSError: pass per CODE-QUAL-02.
        if self.cwd.exists():
            os.chmod(self.cwd, 0o700)
        self.tmpdir.cleanup()

    def test_silent_skip_when_jq_missing(self) -> None:
        """PATH without jq. Must exit 0; if jq is genuinely absent, no
        log appears. On Linux CI where jq is in /usr/bin, the write may
        still succeed — both outcomes are valid degradation."""
        result = subprocess.run(
            [
                "bash",
                str(SKILL_EVENTS),
                "systematic-debugging",
                "fix_completed",
                "{root_cause: $rc}",
                "--arg", "rc", "no-jq smoke",
            ],
            cwd=str(self.cwd),
            capture_output=True,
            text=True,
            env={"PATH": "/usr/bin:/bin"},
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        if not _jq_in(["/usr/bin", "/bin"]):
            self.assertFalse(
                _log_path(self.cwd).exists(),
                msg="log was written despite missing jq",
            )

    def test_args_hash_empty_when_shasum_and_sha1sum_missing(self) -> None:
        """§2.2: when neither `shasum` nor `sha1sum` is on PATH, the
        emitted row carries `args_hash == ""` and all other fields
        populate normally. Build a PATH dir containing only the binaries
        the helper needs minus the hashers."""
        shim_dir = Path(self.tmpdir.name) / "no-hash-bin"
        shim_dir.mkdir()
        # Symlink essential binaries from /usr/bin /bin so the helper
        # (executed via `bash <script>`) can find bash/jq/date/etc. but
        # NOT shasum/sha1sum.
        essentials = [
            "/bin/bash", "/bin/sh",
            "/usr/bin/dirname", "/usr/bin/awk", "/usr/bin/cut",
            "/usr/bin/printf", "/usr/bin/env", "/usr/bin/command",
            "/bin/mkdir", "/bin/date", "/bin/cat", "/bin/echo",
            "/usr/bin/tail", "/usr/bin/grep", "/usr/bin/git",
            "/usr/bin/pwd",
        ]
        for binary in essentials:
            src = Path(binary)
            if src.exists():
                (shim_dir / src.name).symlink_to(src)
        # Add jq from wherever it lives on this host.
        jq_path = shutil.which("jq")
        if jq_path is None:
            self.skipTest("jq not in PATH on this host")
        (shim_dir / "jq").symlink_to(jq_path)
        env = {"PATH": str(shim_dir)}
        result = run_executed(
            self.cwd,
            "systematic-debugging",
            "fix_completed",
            "{root_cause: $rc}",
            "--arg", "rc", "no-hashers",
            env=env,
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        # If the helper ran end-to-end, args_hash is the empty string.
        log = _log_path(self.cwd)
        if log.exists():
            entry = json.loads(log.read_text().strip())
            self.assertEqual(entry["args_hash"], "")
            # Other fields remain populated.
            self.assertEqual(entry["event"], "fix_completed")
            self.assertEqual(entry["skill"], "systematic-debugging")

    def test_returns_zero_when_docs_retros_unwritable(self) -> None:
        """Read-only cwd → mkdir fails → helper returns 0, no file."""
        os.chmod(self.cwd, stat.S_IRUSR | stat.S_IXUSR)
        try:
            result = run_executed(
                self.cwd,
                "systematic-debugging",
                "fix_completed",
                "{root_cause: $rc}",
                "--arg", "rc", "ro fs",
            )
        finally:
            os.chmod(self.cwd, 0o700)
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertFalse(_log_path(self.cwd).exists())

    def test_returns_zero_when_repo_root_empty(self) -> None:
        """No CLAUDE_PROJECT_DIR, no PWD, cwd outside any git repo →
        repo_root_or_skip returns empty → helper returns 0."""
        env = {
            "PATH": os.environ.get("PATH", "/usr/bin:/bin"),
        }
        result = subprocess.run(
            [
                "bash",
                str(SKILL_EVENTS),
                "systematic-debugging",
                "fix_completed",
                "{root_cause: $rc}",
                "--arg", "rc", "no-root",
            ],
            cwd="/",
            capture_output=True,
            text=True,
            env=env,
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertFalse(_log_path(self.cwd).exists())

    def test_returns_zero_when_date_fails(self) -> None:
        """A shimmed `date` that always errors → timestamp_or_skip
        returns 1 → helper returns 0 with no file."""
        shim_dir = Path(self.tmpdir.name) / "shim-bin"
        shim_dir.mkdir()
        date_shim = shim_dir / "date"
        date_shim.write_text("#!/usr/bin/env bash\nexit 1\n")
        date_shim.chmod(0o755)
        env = {
            "PATH": f"{shim_dir}:/usr/bin:/bin",
        }
        result = run_executed(
            self.cwd,
            "systematic-debugging",
            "fix_completed",
            "{root_cause: $rc}",
            "--arg", "rc", "date-fail",
            env=env,
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertFalse(_log_path(self.cwd).exists())


class SkillEventsArgsHashTests(unittest.TestCase):
    """args_hash is sha1[:12] of joined positional args after the payload
    filter. Stable for identical args, distinct for different args."""

    def setUp(self) -> None:
        self.tmpdir = tempfile.TemporaryDirectory()
        self.cwd = Path(self.tmpdir.name)

    def tearDown(self) -> None:
        self.tmpdir.cleanup()

    def test_args_hash_stable_for_identical_args(self) -> None:
        """Same positional args → same hash. Phase 5a clusters by
        args_hash to detect repeat invocations."""
        for _ in range(2):
            run_executed(
                self.cwd,
                "systematic-debugging",
                "fix_completed",
                "{root_cause: $rc}",
                "--arg", "rc", "identical",
            )
        entries = [
            json.loads(line)
            for line in _log_path(self.cwd).read_text().strip().split("\n")
        ]
        self.assertEqual(len(entries), 2)
        self.assertEqual(entries[0]["args_hash"], entries[1]["args_hash"])

    def test_args_hash_differs_for_different_args(self) -> None:
        """Different positional args → different hashes."""
        run_executed(
            self.cwd,
            "systematic-debugging",
            "fix_completed",
            "{root_cause: $rc}",
            "--arg", "rc", "first",
        )
        run_executed(
            self.cwd,
            "systematic-debugging",
            "fix_completed",
            "{root_cause: $rc}",
            "--arg", "rc", "second",
        )
        entries = [
            json.loads(line)
            for line in _log_path(self.cwd).read_text().strip().split("\n")
        ]
        self.assertNotEqual(entries[0]["args_hash"], entries[1]["args_hash"])

    def test_args_hash_format(self) -> None:
        """args_hash matches ^[0-9a-f]{12}$ — exactly 12 lowercase hex."""
        run_executed(
            self.cwd,
            "systematic-debugging",
            "fix_completed",
            "{root_cause: $rc}",
            "--arg", "rc", "format-check",
        )
        entry = json.loads(_log_path(self.cwd).read_text().strip())
        self.assertRegex(entry["args_hash"], ARGS_HASH_REGEX)


def _jq_in(dirs: list[str]) -> bool:
    """True iff `jq` is found in any of the given directories."""
    return any(shutil.which("jq", path=d) for d in dirs)


if __name__ == "__main__":
    unittest.main()
