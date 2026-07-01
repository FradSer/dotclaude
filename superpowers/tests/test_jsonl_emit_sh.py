"""Tests for lib/jsonl-emit.sh — the consolidated NDJSON emitter that
replaced the four-helper stack (retro-events / observations /
evolution-log / skill-events).

Two contract layers:

1. **Executed mode** (`bash jsonl-emit.sh <channel> <jq_program> [args]`).
   Routes to `docs/retros/<channel>.jsonl`, auto-injects $timestamp and
   $repo_root, no per-channel envelope shape is hard-coded.

2. **Sourced mode** — provides six primitives identical in contract to
   the deleted retro-events.sh: jq_or_skip, timestamp_or_skip,
   repo_root_or_skip, ensure_log_dir, write_jsonl, dedup_check.

The emitter is best-effort everywhere — missing jq, unwritable
docs/retros, missing repo_root, or a date failure all silently skip the
write and return 0. This file pins those degradation paths.
"""
from __future__ import annotations

import json
import os
import re
import subprocess
import tempfile
import unittest
from pathlib import Path

SUPERPOWERS_DIR = Path(__file__).resolve().parents[1]
JSONL_EMIT = SUPERPOWERS_DIR / "lib" / "jsonl-emit.sh"
UTILS = SUPERPOWERS_DIR / "lib" / "utils.sh"

ISO_UTC_REGEX = r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$"


# Absolute /bin/bash invocation avoids needing PATH to resolve `bash`,
# which lets tests scope PATH to absent-dependency scenarios (missing jq)
# without losing the shell itself.
BASH = "/bin/bash"


def run_executed(
    cwd: Path,
    *args: str,
    env: dict[str, str] | None = None,
) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [BASH, str(JSONL_EMIT), *args],
        cwd=str(cwd),
        capture_output=True,
        text=True,
        env=env,
    )


def run_sourced(
    cwd: Path,
    body: str,
    env: dict[str, str] | None = None,
) -> subprocess.CompletedProcess[str]:
    script = f"set -euo pipefail\nsource {JSONL_EMIT}\n{body}\n"
    return subprocess.run(
        [BASH, "-c", script],
        cwd=str(cwd),
        capture_output=True,
        text=True,
        env=env,
    )


def _realpath(p: Path) -> str:
    """macOS /var is a symlink to /private/var; the bash side resolves via
    PWD/git rev-parse, which yields /private/var, so tests must compare
    against the realpath, not the str(TemporaryDirectory)."""
    return str(Path(p).resolve())


def _log(cwd: Path, channel: str) -> Path:
    return cwd / "docs" / "retros" / f"{channel}.jsonl"


def _read_one(testcase: unittest.TestCase, cwd: Path, channel: str) -> dict:
    log = _log(cwd, channel)
    testcase.assertTrue(log.exists(), f"{channel}.jsonl was not created")
    lines = log.read_text().splitlines()
    testcase.assertEqual(len(lines), 1, msg=f"expected one row, got: {lines!r}")
    return json.loads(lines[0])


class ExecutedModeTests(unittest.TestCase):
    """Routes <channel> arg to docs/retros/<channel>.jsonl with caller-
    composed envelope. $timestamp and $repo_root are auto-injected."""

    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.cwd = Path(self.tmp.name)
        subprocess.run(["git", "init", "-q"], cwd=str(self.cwd), check=True)

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def test_evolution_log_merged_row(self) -> None:
        """Retrospective Phase 4 evolution rows: flat top-level keys, no
        nested payload. Caller provides every field."""
        result = run_executed(
            self.cwd,
            "evolution-log",
            '{timestamp: $timestamp, event: $event, mode: $mode, item_id: $item_id}',
            "--arg", "event", "item_added",
            "--arg", "mode", "code",
            "--arg", "item_id", "TEST-001",
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        row = _read_one(self, self.cwd, "evolution-log")
        self.assertEqual(row["event"], "item_added")
        self.assertEqual(row["mode"], "code")
        self.assertEqual(row["item_id"], "TEST-001")
        self.assertNotIn("payload", row)

    def test_missing_channel_or_program_skips_silently(self) -> None:
        """Empty channel or jq_program → exit 0, no file, no error."""
        result = run_executed(self.cwd)
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertFalse(_log(self.cwd, "any").exists())

    def test_invalid_jq_program_does_not_crash(self) -> None:
        """jq parse failure is swallowed; rc stays 0 (best-effort contract)."""
        result = run_executed(
            self.cwd,
            "evolution-log",
            "this is not jq syntax {{",
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        # The file may exist empty or not exist; the contract is "rc 0,
        # no crash". Either outcome is acceptable degradation.

    def test_unwritable_docs_retros_returns_zero(self) -> None:
        """Read-only docs/retros must not abort the emit (silent skip)."""
        docs_retros = self.cwd / "docs" / "retros"
        docs_retros.mkdir(parents=True)
        os.chmod(docs_retros, 0o555)
        try:
            result = run_executed(
                self.cwd,
                "evolution-log",
                '{event:$event, repo_root:$repo_root, timestamp:$timestamp}',
                "--arg", "event", "test",
            )
            self.assertEqual(result.returncode, 0, msg=result.stderr)
        finally:
            os.chmod(docs_retros, 0o755)


class SourcedModePrimitivesTests(unittest.TestCase):
    """Six primitives exported in sourced mode."""

    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.cwd = Path(self.tmp.name)
        subprocess.run(["git", "init", "-q"], cwd=str(self.cwd), check=True)

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def test_jq_or_skip_returns_zero_when_jq_present(self) -> None:
        result = run_sourced(self.cwd, "jq_or_skip && echo OK")
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertIn("OK", result.stdout)

    def test_timestamp_or_skip_emits_iso_utc(self) -> None:
        result = run_sourced(self.cwd, "timestamp_or_skip")
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertRegex(result.stdout.strip(), ISO_UTC_REGEX)

    def test_repo_root_or_skip_returns_git_root(self) -> None:
        result = run_sourced(self.cwd, "repo_root_or_skip")
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertEqual(result.stdout.strip(), _realpath(self.cwd))

    def test_ensure_log_dir_creates_directory(self) -> None:
        target = self.cwd / "a" / "b" / "c"
        result = run_sourced(self.cwd, f'ensure_log_dir "{target}" && echo OK')
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertTrue(target.is_dir())

    def test_write_jsonl_appends_one_row(self) -> None:
        log = self.cwd / "out.jsonl"
        body = (
            f'write_jsonl "{log}" '
            "'{event:$event}' --arg event hello\n"
            f'write_jsonl "{log}" '
            "'{event:$event}' --arg event world"
        )
        result = run_sourced(self.cwd, body)
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        lines = log.read_text().splitlines()
        self.assertEqual(len(lines), 2)
        self.assertEqual(json.loads(lines[0])["event"], "hello")
        self.assertEqual(json.loads(lines[1])["event"], "world")

    def test_dedup_check_finds_recent_substring(self) -> None:
        log = self.cwd / "dedup.jsonl"
        log.write_text('{"a":1}\n{"args_hash":"deadbeef"}\n')
        body = (
            f'dedup_check "{log}" \'"args_hash":"deadbeef"\' && echo FOUND;'
            f'dedup_check "{log}" \'"args_hash":"missing"\' || echo MISS'
        )
        result = run_sourced(self.cwd, body)
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertIn("FOUND", result.stdout)
        self.assertIn("MISS", result.stdout)


class DegradationContractTests(unittest.TestCase):
    """The emitter must never propagate failures to the calling skill."""

    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.cwd = Path(self.tmp.name)

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def test_missing_jq_returns_zero(self) -> None:
        """Empty PATH → jq_or_skip returns 1 → executed-mode exits 0."""
        env = {k: v for k, v in os.environ.items() if k != "PATH"}
        env["PATH"] = "/nonexistent"
        result = run_executed(
            self.cwd,
            "evolution-log",
            '{event:$event}',
            "--arg", "event", "test",
            env=env,
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)

    def test_no_top_level_set_e(self) -> None:
        """Sourcing this file MUST NOT alter the caller's error-handling
        regime. set -e / set -u / set -o pipefail must remain absent at
        the top level. Mirrors the contract of the deleted retro-events.sh."""
        text = JSONL_EMIT.read_text()
        # Anchor on line start to avoid matching set commands inside
        # function bodies. We are checking the top-level only.
        for forbidden in ("set -e", "set -u", "set -o pipefail"):
            for line in text.splitlines():
                stripped = line.strip()
                if stripped == forbidden:
                    raise AssertionError(
                        f"top-level `{forbidden}` would corrupt sourcing callers"
                    )


if __name__ == "__main__":
    unittest.main()
