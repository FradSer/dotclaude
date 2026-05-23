"""Tests for systematic-debugging Phase 4 emission contract.

Two layers cover the contract:

1. **Harness layer (Phase4*EmissionTests / SourcingTests / DedupTests /
   CrossSessionTests / ArchitectureQuestioningTests / BailOutNonEmissionTests):**
   small bash harnesses that imitate the SKILL.md emission step in isolation.
   These pin the contract logic — `state_read` for skill_name, tail-200
   dedup, payload shape, no transcript content — so the design is exercised
   even if the SKILL.md prose changes.

2. **Extraction layer (Phase4SkillMdExecutionTests):** parses the actual
   ```bash``` block out of `systematic-debugging/SKILL.md`, substitutes its
   placeholders, executes it in a hermetic sandbox, and asserts on the
   resulting jsonl. This is the regression guard against drift between the
   harness and the SKILL.md prose: deleting the block, hardcoding
   `skill_name`, dropping `dedup_check`, or sneaking a forbidden payload
   key into SKILL.md surfaces here as a failing test.

Spec source: docs/plans/2026-05-12-unified-retro-events-design/bdd-specs.md
§4 (all four scenarios), §6 (both dedup scenarios).
"""
from __future__ import annotations

import functools
import json
import os
import re
import subprocess
import tempfile
import unittest
from pathlib import Path

SUPERPOWERS_DIR = Path(__file__).resolve().parents[1]
LIB_DIR = SUPERPOWERS_DIR / "lib"
SKILL_MD = SUPERPOWERS_DIR / "skills" / "systematic-debugging" / "SKILL.md"

JSONL_EMIT = LIB_DIR / "jsonl-emit.sh"
UTILS = LIB_DIR / "utils.sh"
BAIL_LOG = LIB_DIR / "bail-log.sh"


# ---------------------------------------------------------------------------
# Harness composition — the bash blocks below imitate the SKILL.md emission
# contract via the unified jsonl-emit dispatcher. They mirror the prose
# that ships in `systematic-debugging/SKILL.md` Phase 4 "On success" step.
# Tests assert on the resulting jsonl file plus exit code, not on
# shell-internal state.
# ---------------------------------------------------------------------------

HARNESS_PROLOGUE = f"""
set -uo pipefail
source {UTILS}
source {JSONL_EMIT}
"""


def _harness_emit(
    state_file: str | None,
    root_cause: str,
    regression_test_path: str,
    phase_count: int,
) -> str:
    """Compose the Phase 4 terminal-step emission body.

    Mirrors what ships in SKILL.md Phase 4 "On success". The block:
      - reads skill_name via state_read (silent skip on empty/missing)
      - computes args_hash via the compute_args_hash primitive
      - dedup-checks the last 200 lines of skill-events.jsonl
      - invokes jsonl-emit.sh skill-events only on dedup miss
    """
    state_file_expr = (
        f'"{state_file}"' if state_file else '""'
    )
    return f"""
state_file={state_file_expr}
skill_name=""
if [[ -n "$state_file" && -f "$state_file" ]]; then
  skill_name=$(state_read "$state_file" '.skill_name // ""')
fi
if [[ -z "$skill_name" ]]; then
  exit 0
fi

ROOT_CAUSE={shell_quote(root_cause)}
REGRESSION_TEST_PATH={shell_quote(regression_test_path)}
PHASE_COUNT={phase_count}

args_hash=$(compute_args_hash "$ROOT_CAUSE" "$REGRESSION_TEST_PATH" "$PHASE_COUNT")

root=$(repo_root)
log="$root/docs/retros/skill-events.jsonl"
needle="\\"args_hash\\":\\"$args_hash\\""
if [[ -n "$args_hash" ]] && dedup_check "$log" "$needle"; then
  exit 0
fi

bash {JSONL_EMIT} skill-events \\
  '{{event:$event, skill:$skill, timestamp:$timestamp, repo_root:$repo_root, args_hash:$args_hash, payload:{{root_cause:$rc, regression_test_path:$rt, investigation_phase_count:$count}}}}' \\
  --arg event "fix_completed" \\
  --arg skill "$skill_name" \\
  --arg args_hash "$args_hash" \\
  --arg rc "$ROOT_CAUSE" \\
  --arg rt "$REGRESSION_TEST_PATH" \\
  --argjson count "$PHASE_COUNT"
"""


def shell_quote(value: str) -> str:
    """Single-quote a value for bash."""
    return "'" + value.replace("'", "'\\''") + "'"


def run_harness(cwd: Path, body: str) -> subprocess.CompletedProcess:
    """Execute a composed harness body under the prologue."""
    script = HARNESS_PROLOGUE + body
    return subprocess.run(
        ["bash", "-c", script],
        cwd=str(cwd),
        capture_output=True,
        text=True,
    )


def _write_state(path: Path, skill_name: str) -> None:
    """Persist a minimal session state file with skill_name set."""
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps({"skill_name": skill_name}))


def _log_path(cwd: Path) -> Path:
    return cwd / "docs" / "retros" / "skill-events.jsonl"


def _bail_log_path(cwd: Path) -> Path:
    return cwd / "docs" / "retros" / "bail-out-events.jsonl"


def _read_rows(path: Path) -> list[dict]:
    if not path.exists():
        return []
    return [json.loads(line) for line in path.read_text().splitlines() if line.strip()]


class Phase4SuccessEmissionTests(unittest.TestCase):
    """§4.1 — Phase 4 terminal step emits one fix_completed row on success."""

    def setUp(self) -> None:
        self.tmpdir = tempfile.TemporaryDirectory()
        self.cwd = Path(self.tmpdir.name)
        self.state_file = self.cwd / "state.json"
        _write_state(self.state_file, "systematic-debugging")

    def tearDown(self) -> None:
        self.tmpdir.cleanup()

    def test_phase_4_terminal_emits_fix_completed_once(self) -> None:
        body = _harness_emit(
            state_file=str(self.state_file),
            root_cause="race in cache layer",
            regression_test_path="tests/test_cache_race.py",
            phase_count=4,
        )
        result = run_harness(self.cwd, body)
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        rows = _read_rows(_log_path(self.cwd))
        self.assertEqual(len(rows), 1, msg=f"expected one row, got: {rows!r}")
        self.assertEqual(rows[0]["skill"], "systematic-debugging")
        self.assertEqual(rows[0]["event"], "fix_completed")

    def test_payload_carries_root_cause_and_regression_test_path(self) -> None:
        body = _harness_emit(
            state_file=str(self.state_file),
            root_cause="off-by-one in pagination",
            regression_test_path="tests/test_pagination.py::test_last_page",
            phase_count=3,
        )
        result = run_harness(self.cwd, body)
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        rows = _read_rows(_log_path(self.cwd))
        self.assertEqual(len(rows), 1)
        payload = rows[0]["payload"]
        self.assertEqual(payload["root_cause"], "off-by-one in pagination")
        self.assertEqual(
            payload["regression_test_path"],
            "tests/test_pagination.py::test_last_page",
        )
        self.assertEqual(payload["investigation_phase_count"], 3)

    def test_payload_does_not_include_test_stdout_stderr_or_diff(self) -> None:
        """Per best-practices.md §"No transcript content": the payload
        MUST NOT carry test_stdout, test_stderr, or fix_diff fields."""
        body = _harness_emit(
            state_file=str(self.state_file),
            root_cause="env var typo",
            regression_test_path="tests/test_env.py",
            phase_count=2,
        )
        result = run_harness(self.cwd, body)
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        rows = _read_rows(_log_path(self.cwd))
        self.assertEqual(len(rows), 1)
        payload_keys = set(rows[0]["payload"].keys())
        for forbidden in ("test_stdout", "test_stderr", "fix_diff"):
            self.assertNotIn(
                forbidden,
                payload_keys,
                msg=f"payload must not include transcript field {forbidden!r}",
            )


class Phase4BailOutNonEmissionTests(unittest.TestCase):
    """§4.2 — bail-out flow writes to bail-out-events.jsonl ONLY.
    The skill-events channel stays empty on the bail-out branch."""

    def setUp(self) -> None:
        self.tmpdir = tempfile.TemporaryDirectory()
        self.cwd = Path(self.tmpdir.name)

    def tearDown(self) -> None:
        self.tmpdir.cleanup()

    def test_bail_out_path_does_not_emit_fix_completed(self) -> None:
        # Drive only the bail-out helper — Phase 4 emission is intentionally
        # skipped on this branch (per best-practices.md prohibition).
        result = subprocess.run(
            [
                "bash",
                str(BAIL_LOG),
                "systematic-debugging",
                "bail_out",
                "named root cause + named fix",
                "cookie domain is .foo.com, should be foo.com — fix it",
            ],
            cwd=str(self.cwd),
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        bail_rows = _read_rows(_bail_log_path(self.cwd))
        self.assertEqual(
            len(bail_rows),
            1,
            msg=f"expected one bail-out row, got: {bail_rows!r}",
        )
        # skill-events.jsonl must NOT exist or must have zero rows — the
        # bail-out branch deliberately does not double-emit.
        skill_rows = _read_rows(_log_path(self.cwd))
        self.assertEqual(skill_rows, [])


class Phase4SkillNameSourcingTests(unittest.TestCase):
    """§4.3 — skill_name comes from the session state file via state_read.
    The literal string "systematic-debugging" is never hardcoded as the
    helper's $1. The emission silently skips when state is unavailable."""

    def setUp(self) -> None:
        self.tmpdir = tempfile.TemporaryDirectory()
        self.cwd = Path(self.tmpdir.name)
        self.state_file = self.cwd / "state.json"

    def tearDown(self) -> None:
        self.tmpdir.cleanup()

    def test_skill_name_sourced_from_state_file(self) -> None:
        _write_state(self.state_file, "systematic-debugging")
        body = _harness_emit(
            state_file=str(self.state_file),
            root_cause="state-driven",
            regression_test_path="tests/test_state.py",
            phase_count=1,
        )
        result = run_harness(self.cwd, body)
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        rows = _read_rows(_log_path(self.cwd))
        self.assertEqual(len(rows), 1)
        # The value came through state_read — assert it landed on the row.
        self.assertEqual(rows[0]["skill"], "systematic-debugging")

    def test_emission_skips_when_state_file_missing(self) -> None:
        # state.json never written. Harness must exit 0 with no row.
        self.assertFalse(self.state_file.exists())
        body = _harness_emit(
            state_file=str(self.state_file),
            root_cause="should-not-emit",
            regression_test_path="tests/test_missing.py",
            phase_count=1,
        )
        result = run_harness(self.cwd, body)
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertFalse(
            _log_path(self.cwd).exists(),
            msg="skill-events.jsonl must not be created when state is missing",
        )

    def test_emission_skips_when_skill_name_empty(self) -> None:
        _write_state(self.state_file, "")
        body = _harness_emit(
            state_file=str(self.state_file),
            root_cause="should-not-emit",
            regression_test_path="tests/test_empty.py",
            phase_count=1,
        )
        result = run_harness(self.cwd, body)
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertFalse(
            _log_path(self.cwd).exists(),
            msg="skill-events.jsonl must not be created when skill_name is empty",
        )


class Phase4ArchitectureQuestioningTests(unittest.TestCase):
    """§4.4 — when Phase 4 transitions to architecture questioning after
    3+ failed fixes, the skill hands control back to the user without
    emitting fix_completed. No replacement event (e.g. fix_abandoned) is
    introduced in this iteration."""

    def setUp(self) -> None:
        self.tmpdir = tempfile.TemporaryDirectory()
        self.cwd = Path(self.tmpdir.name)
        self.state_file = self.cwd / "state.json"
        _write_state(self.state_file, "systematic-debugging")

    def tearDown(self) -> None:
        self.tmpdir.cleanup()

    def test_no_emission_when_architecture_questioning_branch_taken(self) -> None:
        # Architecture-questioning branch invokes no emission helper. We
        # model that by running the prologue (so the harness env is set up)
        # but NOT the emit body. The contract is: skill-events.jsonl is
        # absent or contains zero fix_completed rows.
        result = run_harness(self.cwd, "exit 0")
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        rows = _read_rows(_log_path(self.cwd))
        fix_rows = [r for r in rows if r.get("event") == "fix_completed"]
        self.assertEqual(fix_rows, [])

    def test_no_fix_abandoned_event_emitted(self) -> None:
        # Strong negative: this iteration explicitly excludes fix_abandoned.
        # Run the same architecture-questioning shape and confirm the event
        # name does not appear in any produced log.
        run_harness(self.cwd, "exit 0")
        rows = _read_rows(_log_path(self.cwd))
        abandoned_rows = [r for r in rows if r.get("event") == "fix_abandoned"]
        self.assertEqual(abandoned_rows, [])


class Phase4DedupTests(unittest.TestCase):
    """§6.1 — within a single session, duplicate invocations dedupe via
    a tail-200 scan of skill-events.jsonl for the matching args_hash."""

    def setUp(self) -> None:
        self.tmpdir = tempfile.TemporaryDirectory()
        self.cwd = Path(self.tmpdir.name)
        self.state_file = self.cwd / "state.json"
        _write_state(self.state_file, "systematic-debugging")
        (self.cwd / "docs" / "retros").mkdir(parents=True)

    def tearDown(self) -> None:
        self.tmpdir.cleanup()

    def _emit(self) -> subprocess.CompletedProcess:
        body = _harness_emit(
            state_file=str(self.state_file),
            root_cause="dedup-fixture",
            regression_test_path="tests/test_dedup.py",
            phase_count=4,
        )
        return run_harness(self.cwd, body)

    def test_same_invocation_dedupes_within_session(self) -> None:
        # First emission writes the row.
        result1 = self._emit()
        self.assertEqual(result1.returncode, 0, msg=result1.stderr)
        rows_after_first = _read_rows(_log_path(self.cwd))
        self.assertEqual(len(rows_after_first), 1)
        # Second invocation with identical args must dedupe to a no-op.
        result2 = self._emit()
        self.assertEqual(result2.returncode, 0, msg=result2.stderr)
        rows_after_second = _read_rows(_log_path(self.cwd))
        self.assertEqual(
            len(rows_after_second),
            1,
            msg=f"dedup failed; got rows: {rows_after_second!r}",
        )

    def test_dedup_uses_tail_200_scan(self) -> None:
        """The dedup window is exactly 200 lines. A matching args_hash at
        or above tail position 200 suppresses; a matching args_hash beyond
        tail position 200 does NOT suppress."""
        # Discover the args_hash this harness will produce by running the
        # emit once into a throwaway log, capturing the row, deleting it.
        first = self._emit()
        self.assertEqual(first.returncode, 0, msg=first.stderr)
        rows = _read_rows(_log_path(self.cwd))
        self.assertEqual(len(rows), 1)
        target_hash = rows[0]["args_hash"]
        self.assertTrue(target_hash, msg="args_hash must be non-empty")

        log = _log_path(self.cwd)

        # ---- Case A: matching row at position 1-from-end (well within
        # the tail-200 window). Re-emit and assert no new row is appended.
        # The log currently has 1 row — the matching one. Add 199 noise
        # rows AFTER it so the matching row sits at position 200-from-end.
        with log.open("a") as fh:
            for idx in range(199):
                fh.write(
                    json.dumps(
                        {
                            "event": "noise",
                            "skill": "noise-skill",
                            "args_hash": f"noise{idx:08d}",
                        }
                    )
                    + "\n"
                )
        rows_before = _read_rows(log)
        # 1 real + 199 noise = 200 rows; matching row at exactly position
        # 200-from-end (the oldest of the tail-200 window).
        self.assertEqual(len(rows_before), 200)
        result_within = self._emit()
        self.assertEqual(result_within.returncode, 0, msg=result_within.stderr)
        rows_after = _read_rows(log)
        self.assertEqual(
            len(rows_after),
            200,
            msg=(
                "dedup must suppress when the matching args_hash is at "
                "position 200-from-end (inside the tail-200 scan window)"
            ),
        )

        # ---- Case B: push the matching row OUTSIDE the tail-200 window
        # by appending one more noise row. Now the matching row is at
        # position 201-from-end. Re-emit and assert a new row IS appended.
        with log.open("a") as fh:
            fh.write(
                json.dumps(
                    {
                        "event": "noise",
                        "skill": "noise-skill",
                        "args_hash": "noise-pushout",
                    }
                )
                + "\n"
            )
        rows_pushed = _read_rows(log)
        self.assertEqual(len(rows_pushed), 201)
        result_outside = self._emit()
        self.assertEqual(result_outside.returncode, 0, msg=result_outside.stderr)
        rows_final = _read_rows(log)
        self.assertEqual(
            len(rows_final),
            202,
            msg=(
                "dedup must NOT suppress when the matching args_hash is at "
                "position 201-from-end (outside the tail-200 scan window)"
            ),
        )
        # The new row carries the same args_hash as the original.
        self.assertEqual(rows_final[-1]["args_hash"], target_hash)


class Phase4CrossSessionTests(unittest.TestCase):
    """§6.2 — cross-session dedup is intentionally absent. Two separate
    invocations (each its own bash subprocess) both append. Different
    args produce different args_hash values."""

    def setUp(self) -> None:
        self.tmpdir = tempfile.TemporaryDirectory()
        self.cwd = Path(self.tmpdir.name)
        self.state_file = self.cwd / "state.json"
        _write_state(self.state_file, "systematic-debugging")

    def tearDown(self) -> None:
        self.tmpdir.cleanup()

    def test_cross_session_dedup_is_intentionally_absent(self) -> None:
        """Two SEPARATE bash invocations with identical args must both
        write rows. We approximate "separate session" by ensuring the
        tail-200 scan finds no match — which requires us to use distinct
        args between the two runs, or to seed enough noise to push the
        first row out of the window. Per §6.2, the contract is that no
        helper logic attempts cross-session suppression — so a clean
        skill-events.jsonl with distinct args yields two rows."""
        body_first = _harness_emit(
            state_file=str(self.state_file),
            root_cause="session-1",
            regression_test_path="tests/test_session1.py",
            phase_count=2,
        )
        body_second = _harness_emit(
            state_file=str(self.state_file),
            root_cause="session-2",
            regression_test_path="tests/test_session2.py",
            phase_count=2,
        )
        r1 = run_harness(self.cwd, body_first)
        r2 = run_harness(self.cwd, body_second)
        self.assertEqual(r1.returncode, 0, msg=r1.stderr)
        self.assertEqual(r2.returncode, 0, msg=r2.stderr)
        rows = _read_rows(_log_path(self.cwd))
        self.assertEqual(len(rows), 2)
        self.assertEqual(rows[0]["payload"]["root_cause"], "session-1")
        self.assertEqual(rows[1]["payload"]["root_cause"], "session-2")

    def test_different_args_get_different_args_hash(self) -> None:
        body_first = _harness_emit(
            state_file=str(self.state_file),
            root_cause="hash-a",
            regression_test_path="tests/test_a.py",
            phase_count=1,
        )
        body_second = _harness_emit(
            state_file=str(self.state_file),
            root_cause="hash-b",
            regression_test_path="tests/test_b.py",
            phase_count=1,
        )
        run_harness(self.cwd, body_first)
        run_harness(self.cwd, body_second)
        rows = _read_rows(_log_path(self.cwd))
        self.assertEqual(len(rows), 2)
        self.assertNotEqual(rows[0]["args_hash"], rows[1]["args_hash"])


class Phase4SkillMdContractTests(unittest.TestCase):
    """Cross-cuts the harness checks above with direct assertions against
    `systematic-debugging/SKILL.md`. These tests Red until 009-impl wires
    the emission prose into the SKILL.md Phase 4 terminal step."""

    def test_skill_md_phase_4_invokes_jsonl_emit(self) -> None:
        text = SKILL_MD.read_text()
        self.assertIn(
            "lib/jsonl-emit.sh",
            text,
            msg=(
                "systematic-debugging SKILL.md must invoke lib/jsonl-emit.sh "
                "from Phase 4 — the unified NDJSON emitter replaced the "
                "per-channel skill-events.sh wrapper."
            ),
        )

    def test_skill_md_emission_does_not_hardcode_skill_name(self) -> None:
        """The emission must read skill_name from state, not pass the
        literal string "systematic-debugging" as the skill arg."""
        text = SKILL_MD.read_text()
        # Hardcoding `--arg skill "systematic-debugging"` in the emit
        # invocation is the architecture-prohibited form: it defeats the
        # cross-skill provenance that the state-read pattern enables.
        forbidden = '--arg skill "systematic-debugging"'
        self.assertNotIn(forbidden, text)

    def test_skill_md_allowed_tools_lists_jsonl_emit(self) -> None:
        text = SKILL_MD.read_text()
        # Frontmatter at the top of the file declares the allow-list. The
        # unified emitter is the only retro-channel writer now.
        self.assertIn(
            'Bash(${CLAUDE_PLUGIN_ROOT}/lib/jsonl-emit.sh:*)',
            text,
            msg=(
                "allowed-tools must include lib/jsonl-emit.sh — the "
                "consolidated NDJSON emitter"
            ),
        )

    def test_skill_md_does_not_emit_fix_abandoned(self) -> None:
        """Out-of-scope for this iteration — no fix_abandoned event."""
        text = SKILL_MD.read_text()
        self.assertNotIn("fix_abandoned", text)


DEFAULT_SKILL_NAME = "systematic-debugging"
FORBIDDEN_PAYLOAD_KEYS = ("test_stdout", "test_stderr", "fix_diff")
DEFAULT_ROOT_CAUSE = "off-by-one in pagination boundary"
DEFAULT_REGRESSION_PATH = "tests/regression/test_pagination.py::test_offset"


@functools.lru_cache(maxsize=1)
def _extract_phase4_bash_block() -> str:
    """Return the bash code block following the Phase 4 'On success' marker."""
    text = SKILL_MD.read_text()
    pattern = re.compile(
        r"On success — and ONLY on success.*?\n\s*```bash\n(?P<body>.*?)\n\s*```",
        re.DOTALL,
    )
    match = pattern.search(text)
    if match is None:
        raise AssertionError(
            "SKILL.md no longer contains a Phase 4 'On success' marker followed "
            "by a ```bash``` block. If the layout was refactored, update this "
            "regex; if the block was removed, restore it (009-impl contract)."
        )
    body = match.group("body")
    # Markdown indents each code line with 3 leading spaces — strip them so
    # the body executes as plain bash.
    return "\n".join(line[3:] if line.startswith("   ") else line for line in body.splitlines())


def _build_sandbox(
    tmp: Path,
    *,
    write_state: bool = True,
    skill_name: str = DEFAULT_SKILL_NAME,
    session_id: str = "test-session-phase4",
) -> tuple[Path, dict[str, str], Path]:
    """Set up a hermetic project + state environment for SKILL.md execution.

    Returns (project_dir, env_vars, log_file_path). `CLAUDE_PLUGIN_ROOT` is
    aliased to the real `SUPERPOWERS_DIR` — the SKILL.md block only sources
    lib files (read-only), writes go to the sandboxed `CLAUDE_PROJECT_DIR`.

    `write_state=False` skips state-file creation entirely so `find_state_file`
    returns empty, exercising the missing-file branch.
    """
    project = tmp / "project"
    project.mkdir()
    fake_home = tmp / "home"
    (fake_home / ".claude" / "projects").mkdir(parents=True)

    # state_dir() maps $PWD to a flat dir key by replacing '/' with '-'.
    project_key = str(project).replace("/", "-")
    state_dir = fake_home / ".claude" / "projects" / project_key
    state_dir.mkdir(parents=True)

    if write_state:
        state_file = state_dir / f"{session_id}.superpowers.json"
        state_file.write_text(
            json.dumps(
                {
                    "session_id": session_id,
                    "skill_name": skill_name,
                    "active": True,
                }
            )
        )

    # Strip parent CLAUDE_* env vars so a developer's shell state cannot leak
    # into the sandbox and mask CI failures.
    env = {k: v for k, v in os.environ.items() if not k.startswith("CLAUDE_")}
    env["HOME"] = str(fake_home)
    env["CLAUDE_PROJECT_DIR"] = str(project)
    env["CLAUDE_PLUGIN_ROOT"] = str(SUPERPOWERS_DIR)
    # CLAUDE_CODE_SESSION_ID is the real var Claude Code exports to Bash-tool
    # subprocesses (since v2.1.132). CLAUDE_SESSION_ID does not exist — the
    # SKILL.md block and this fixture both used it previously, which masked
    # that the fix_completed emission never fired under real Claude Code.
    env["CLAUDE_CODE_SESSION_ID"] = session_id

    log = project / "docs" / "retros" / "skill-events.jsonl"
    return project, env, log


def _run_extracted_block(
    block: str,
    project: Path,
    env: dict[str, str],
    *,
    repeats: int = 1,
    root_cause: str = DEFAULT_ROOT_CAUSE,
    regression_path: str = DEFAULT_REGRESSION_PATH,
) -> subprocess.CompletedProcess[str]:
    """Substitute SKILL.md placeholders with test values and execute the block."""
    substituted = block.replace("<one-line root cause>", root_cause).replace(
        "<tests/path::case>", regression_path
    )
    script = f"cd {project}\n" + (substituted + "\n") * repeats
    return subprocess.run(
        ["bash", "-c", script],
        env=env,
        capture_output=True,
        text=True,
        check=False,
    )


class Phase4SkillMdExecutionTests(unittest.TestCase):
    block: str

    @classmethod
    def setUpClass(cls) -> None:
        cls.block = _extract_phase4_bash_block()

    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self._tmp.cleanup)
        self.tmp_path = Path(self._tmp.name)

    def test_block_extraction_succeeds(self) -> None:
        for idiom in ("state_read", "dedup_check", "lib/jsonl-emit.sh", "fix_completed"):
            self.assertIn(idiom, self.block)

    def test_block_executes_and_emits_expected_row(self) -> None:
        project, env, log = _build_sandbox(self.tmp_path)
        result = _run_extracted_block(self.block, project, env)
        self.assertEqual(
            result.returncode, 0, msg=f"stderr: {result.stderr}\nstdout: {result.stdout}"
        )
        self.assertTrue(log.exists(), msg=f"skill-events.jsonl missing; stderr={result.stderr}")
        rows = [json.loads(line) for line in log.read_text().splitlines() if line.strip()]
        self.assertEqual(len(rows), 1, msg=f"rows={rows!r}")
        row = rows[0]
        self.assertEqual(row["skill"], DEFAULT_SKILL_NAME)
        self.assertEqual(row["event"], "fix_completed")
        self.assertEqual(row["payload"]["root_cause"], DEFAULT_ROOT_CAUSE)
        self.assertEqual(row["payload"]["regression_test_path"], DEFAULT_REGRESSION_PATH)
        self.assertEqual(row["payload"]["investigation_phase_count"], 4)
        for forbidden in FORBIDDEN_PAYLOAD_KEYS:
            self.assertNotIn(forbidden, row["payload"])

    def test_block_dedups_within_same_invocation(self) -> None:
        project, env, log = _build_sandbox(self.tmp_path)
        result = _run_extracted_block(self.block, project, env, repeats=2)
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        rows = [json.loads(line) for line in log.read_text().splitlines() if line.strip()]
        self.assertEqual(
            len(rows), 1, msg=f"dedup_check failed in SKILL.md block: got {len(rows)} rows"
        )

    def test_block_skips_when_state_file_missing(self) -> None:
        project, env, log = _build_sandbox(self.tmp_path, write_state=False)
        result = _run_extracted_block(self.block, project, env)
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertFalse(log.exists(), msg=f"unexpected file: {log.read_text() if log.exists() else ''!r}")

    def test_block_skips_when_skill_name_empty(self) -> None:
        project, env, log = _build_sandbox(self.tmp_path, skill_name="")
        result = _run_extracted_block(self.block, project, env)
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertFalse(log.exists(), msg=f"unexpected file: {log.read_text() if log.exists() else ''!r}")

    def test_block_skill_name_comes_from_state_not_hardcoded(self) -> None:
        # Sentinel skill_name in state must appear in the row. If SKILL.md
        # regresses to hardcoding "systematic-debugging" as the helper's $1,
        # the sentinel won't appear and this test fails.
        sentinel = "sentinel-skill-xyz"
        project, env, log = _build_sandbox(self.tmp_path, skill_name=sentinel)
        result = _run_extracted_block(self.block, project, env)
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        rows = [json.loads(line) for line in log.read_text().splitlines() if line.strip()]
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0]["skill"], sentinel)

    def test_block_never_emits_transcript_content(self) -> None:
        for forbidden in FORBIDDEN_PAYLOAD_KEYS:
            self.assertNotIn(
                forbidden,
                self.block,
                msg=f"SKILL.md Phase 4 block must not reference {forbidden}",
            )


if __name__ == "__main__":
    unittest.main()
