"""Tests for systematic-debugging Phase 4 emission contract.

The unit under test is the SKILL.md emission step — not the helper itself.
Each test drives a small bash harness that imitates what Phase 4's "Verify
Fix" success branch is expected to do:

  1. Read `skill_name` from the session state file via `state_read`
     (mirroring `loop.sh::_loop_log_plan_completion_if_executing`).
  2. Skip silently when the state file is missing or `skill_name` is empty.
  3. Compute an args_hash for the dedup key.
  4. Tail-200 dedup-check `skill-events.jsonl` for matching
     `(skill, event, args_hash)`.
  5. On dedup miss, invoke `log_skill_event` with a payload carrying
     `root_cause`, `regression_test_path`, `investigation_phase_count` —
     and never `test_stdout`, `test_stderr`, or `fix_diff`.

Until task 009-impl wires this same contract into
`systematic-debugging/SKILL.md`, the test runs through a fixture harness
that exercises the same shell idioms. The Red state for the dedup tests
is reached because the harness mirrors the SKILL.md prose exactly — any
divergence between the SKILL.md and this harness surfaces as a missing
row, an extra row, or a hardcoded skill name.

Spec source: docs/plans/2026-05-12-unified-retro-events-design/bdd-specs.md
§4 (all four scenarios), §6 (both dedup scenarios).
"""
from __future__ import annotations

import json
import subprocess
import tempfile
import unittest
from pathlib import Path

SUPERPOWERS_DIR = Path(__file__).resolve().parents[1]
LIB_DIR = SUPERPOWERS_DIR / "lib"
SKILL_MD = SUPERPOWERS_DIR / "skills" / "systematic-debugging" / "SKILL.md"

SKILL_EVENTS = LIB_DIR / "skill-events.sh"
RETRO_EVENTS = LIB_DIR / "retro-events.sh"
UTILS = LIB_DIR / "utils.sh"
BAIL_LOG = LIB_DIR / "bail-log.sh"


# ---------------------------------------------------------------------------
# Harness composition — the bash blocks below imitate the SKILL.md emission
# contract. They are intentionally close to the prose that 009-impl will add
# to `systematic-debugging/SKILL.md`. Tests assert on the resulting jsonl
# file plus exit code, not on shell-internal state.
# ---------------------------------------------------------------------------

HARNESS_PROLOGUE = f"""
set -uo pipefail
source {UTILS}
source {RETRO_EVENTS}
source {SKILL_EVENTS}
"""


def _harness_emit(
    state_file: str | None,
    root_cause: str,
    regression_test_path: str,
    phase_count: int,
) -> str:
    """Compose the Phase 4 terminal-step emission body.

    Mirrors what 009-impl is expected to add to SKILL.md. The block:
      - reads skill_name via state_read (silent skip on empty/missing)
      - computes args_hash via shasum/sha1sum (matches skill-events.sh §2.2)
      - dedup-checks the last 200 lines of skill-events.jsonl
      - calls log_skill_event only on dedup miss
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

# args_hash mirrors skill-events.sh's own derivation: sha1[:12] of the
# joined positional args after the payload filter.
joined=$(printf '%s\\n' --arg rc "$ROOT_CAUSE" --arg rt "$REGRESSION_TEST_PATH" --argjson count "$PHASE_COUNT")
if command -v shasum >/dev/null 2>&1; then
  args_hash=$(printf '%s' "$joined" | shasum -a 1 2>/dev/null | awk '{{print $1}}' | cut -c1-12)
elif command -v sha1sum >/dev/null 2>&1; then
  args_hash=$(printf '%s' "$joined" | sha1sum 2>/dev/null | awk '{{print $1}}' | cut -c1-12)
else
  args_hash=""
fi

root=$(repo_root)
log="$root/docs/retros/skill-events.jsonl"
needle="\\"args_hash\\":\\"$args_hash\\""
if [[ -n "$args_hash" ]] && dedup_check "$log" "$needle"; then
  exit 0
fi

log_skill_event "$skill_name" fix_completed \\
  '{{root_cause: $rc, regression_test_path: $rt, investigation_phase_count: $count}}' \\
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

    def test_skill_md_phase_4_invokes_skill_events_helper(self) -> None:
        text = SKILL_MD.read_text()
        self.assertIn(
            "lib/skill-events.sh",
            text,
            msg=(
                "systematic-debugging SKILL.md must invoke lib/skill-events.sh "
                "from Phase 4 (009-impl wires this in)"
            ),
        )

    def test_skill_md_emission_does_not_hardcode_skill_name(self) -> None:
        """The emission must read skill_name from state, not pass the
        literal string "systematic-debugging" as the helper's $1."""
        text = SKILL_MD.read_text()
        # Locate any line that invokes the helper and assert the $1 slot
        # uses a variable, not a literal.
        lines = text.splitlines()
        helper_lines = [
            (i, ln) for i, ln in enumerate(lines)
            if "lib/skill-events.sh" in ln
        ]
        self.assertTrue(
            helper_lines,
            msg="no skill-events.sh invocation found in SKILL.md",
        )
        # Walk forward up to 5 lines to find the $1 argument (the line
        # after a `\` continuation typically holds it).
        joined = "\n".join(lines)
        # A hardcoded literal "systematic-debugging" as the $1 of the
        # helper is the architecture-prohibited form. Allow the string
        # to appear in prose (frontmatter, headers) but reject the
        # specific shell pattern that uses it as $1.
        forbidden = 'lib/skill-events.sh" "systematic-debugging"'
        forbidden_alt = 'lib/skill-events.sh" systematic-debugging'
        self.assertNotIn(forbidden, joined)
        self.assertNotIn(forbidden_alt, joined)

    def test_skill_md_allowed_tools_lists_skill_events_helper(self) -> None:
        text = SKILL_MD.read_text()
        # frontmatter is at the top; assert the allowed-tools entry exists.
        self.assertIn(
            'Bash(${CLAUDE_PLUGIN_ROOT}/lib/skill-events.sh:*)',
            text,
            msg=(
                "allowed-tools must include skill-events.sh after 009-impl"
            ),
        )

    def test_skill_md_does_not_emit_fix_abandoned(self) -> None:
        """Out-of-scope for this iteration — no fix_abandoned event."""
        text = SKILL_MD.read_text()
        self.assertNotIn("fix_abandoned", text)


if __name__ == "__main__":
    unittest.main()
