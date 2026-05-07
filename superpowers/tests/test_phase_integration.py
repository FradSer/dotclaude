"""Integration tests for the lib/loop.sh + lib/vet.sh phase entrypoints, the
shared `bypass_vet_for_workflow_skill` helper, the `find_state_file` legacy
fallback warning, and the setup-superpower-loop reentry guard.

These cover the hook-orchestration paths that the existing test_state_lock.py
deliberately skipped — the bulk of hooks/lib lines were untested before this
file landed.
"""

import json
import os
import shlex
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SUPERPOWERS = ROOT / "superpowers"
UTILS = SUPERPOWERS / "lib" / "utils.sh"
LOOP = SUPERPOWERS / "lib" / "loop.sh"
VET = SUPERPOWERS / "lib" / "vet.sh"
SETUP = SUPERPOWERS / "scripts" / "setup-superpower-loop.sh"


def run_bash(script: str, **kwargs) -> subprocess.CompletedProcess:
    """Run a bash script with utils.sh + loop.sh + vet.sh sourced."""
    full = (
        "set +e\n"
        f"source {shlex.quote(str(UTILS))}\n"
        f"source {shlex.quote(str(LOOP))}\n"
        f"source {shlex.quote(str(VET))}\n"
        f"{script}"
    )
    return subprocess.run(
        ["bash", "-c", full],
        text=True,
        capture_output=True,
        **kwargs,
    )


class BypassVetForWorkflowSkillTests(unittest.TestCase):
    """The shared helper added to utils.sh — single source of truth for the
    workflow-skill bypass that loop.sh and vet.sh both delegate to."""

    def setUp(self) -> None:
        self.tmpdir = tempfile.TemporaryDirectory()
        self.state = Path(self.tmpdir.name) / "state.json"

    def tearDown(self) -> None:
        self.tmpdir.cleanup()

    def test_bypass_clears_need_vet_and_exits_for_workflow_skill(self) -> None:
        self.state.write_text(json.dumps({"skill_name": "brainstorming", "need_vet": True}))
        result = run_bash(
            f'bypass_vet_for_workflow_skill {shlex.quote(str(self.state))}\n'
            'echo "REACHED_AFTER_BYPASS"'
        )
        # The function must `exit 0` from inside, never reaching the post-call line.
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertNotIn("REACHED_AFTER_BYPASS", result.stdout)
        # need_vet must be cleared.
        state = json.loads(self.state.read_text())
        self.assertNotIn("need_vet", state)

    def test_bypass_returns_nonzero_for_non_workflow_skill(self) -> None:
        self.state.write_text(json.dumps({"skill_name": "need-vet", "need_vet": True}))
        result = run_bash(
            f'bypass_vet_for_workflow_skill {shlex.quote(str(self.state))}\n'
            'echo "REACHED_AFTER_BYPASS"'
        )
        # Non-workflow skill: function returns 1, script reaches the next line.
        self.assertIn("REACHED_AFTER_BYPASS", result.stdout)
        # need_vet must NOT be cleared (vet still has a job to do).
        state = json.loads(self.state.read_text())
        self.assertTrue(state.get("need_vet"))


class FindStateFileLegacyWarningTests(unittest.TestCase):
    """find_state_file must warn to stderr when falling back to a legacy
    file without a session_id — silent crosstalk between concurrent
    sessions in the same cwd was the bug."""

    def setUp(self) -> None:
        self.tmpdir = tempfile.TemporaryDirectory()
        # Override state_dir() by changing PWD so the function picks our tmp.
        self.fake_pwd = Path(self.tmpdir.name) / "fake-cwd"
        self.fake_pwd.mkdir()
        self.state_dir = Path.home() / ".claude" / "projects" / str(self.fake_pwd).replace("/", "-")
        self.state_dir.mkdir(parents=True, exist_ok=True)
        self.legacy = self.state_dir / "legacy.superpowers.json"
        self.legacy.write_text("{}")

    def tearDown(self) -> None:
        # Clean up our injected files but leave the project dir alone — other
        # tests might need it.
        for p in self.state_dir.glob("*.superpowers.json"):
            p.unlink()
        self.state_dir.rmdir()
        self.tmpdir.cleanup()

    def test_legacy_fallback_warns_on_stderr(self) -> None:
        result = subprocess.run(
            ["bash", "-c", f'cd {shlex.quote(str(self.fake_pwd))} && '
                           f'source {shlex.quote(str(UTILS))} && '
                           f'find_state_file "wanted-session-id"'],
            text=True,
            capture_output=True,
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        # stdout returns the legacy path, stderr contains the warning.
        self.assertIn("legacy.superpowers.json", result.stdout)
        self.assertIn("legacy file without session_id", result.stderr)

    def test_exact_session_match_does_not_warn(self) -> None:
        match = self.state_dir / "match.superpowers.json"
        match.write_text(json.dumps({"session_id": "wanted"}))
        try:
            result = subprocess.run(
                ["bash", "-c", f'cd {shlex.quote(str(self.fake_pwd))} && '
                               f'source {shlex.quote(str(UTILS))} && '
                               f'find_state_file "wanted"'],
                text=True,
                capture_output=True,
            )
            self.assertEqual(result.returncode, 0, msg=result.stderr)
            self.assertIn("match.superpowers.json", result.stdout)
            self.assertNotIn("legacy file without session_id", result.stderr)
        finally:
            match.unlink()


class VetPhaseTests(unittest.TestCase):
    """End-to-end tests for vet_phase (lib/vet.sh) — the verification gate
    that blocks Stop until the user emits a verified tag.

    Note: these tests do not exercise run_haiku_merge — that depends on the
    `claude` CLI being in PATH, which is a heavy assumption for unit tests."""

    def setUp(self) -> None:
        self.tmpdir = tempfile.TemporaryDirectory()
        self.state = Path(self.tmpdir.name) / "state.json"
        self.transcript = Path(self.tmpdir.name) / "transcript.jsonl"
        self.transcript.write_text("")

    def tearDown(self) -> None:
        self.tmpdir.cleanup()

    def test_skips_when_need_vet_not_set(self) -> None:
        self.state.write_text(json.dumps({"task": "ship it"}))
        result = run_bash(
            f'vet_phase {shlex.quote(str(self.state))} "" {shlex.quote(str(self.transcript))}\n'
            'echo "REACHED_AFTER_VET"'
        )
        # vet_phase always exits — never reach post-call line.
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertNotIn("REACHED_AFTER_VET", result.stdout)
        # No block JSON emitted.
        self.assertEqual(result.stdout.strip(), "")

    def test_bypasses_for_workflow_skill_and_clears_need_vet(self) -> None:
        self.state.write_text(json.dumps({
            "skill_name": "executing-plans",
            "need_vet": True,
            "task": "run plan",
        }))
        result = run_bash(
            f'vet_phase {shlex.quote(str(self.state))} "" {shlex.quote(str(self.transcript))}'
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        # need_vet cleared by the bypass helper.
        state = json.loads(self.state.read_text())
        self.assertNotIn("need_vet", state)
        # No block JSON.
        self.assertEqual(result.stdout.strip(), "")

    def test_emits_block_json_when_verified_tag_missing(self) -> None:
        self.state.write_text(json.dumps({
            "need_vet": True,
            "task": "verify the deploy",
            "modified_files": ["deploy.yaml"],
        }))
        last_msg = "Looks good to me, but I haven't tested anything."
        result = run_bash(
            f'vet_phase {shlex.quote(str(self.state))} {shlex.quote(last_msg)} '
            f'{shlex.quote(str(self.transcript))}'
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        # Block JSON on stdout — `decision: block` and reason markdown.
        payload = json.loads(result.stdout)
        self.assertEqual(payload["decision"], "block")
        self.assertIn("Verification Checkpoint", payload["reason"])
        self.assertIn("verify the deploy", payload["reason"])
        self.assertIn("deploy.yaml", payload["reason"])
        self.assertIn("absolute last line", payload["reason"])
        # need_vet must still be set — verification not yet satisfied.
        state = json.loads(self.state.read_text())
        self.assertTrue(state.get("need_vet"))

    def test_passes_through_when_verified_tag_matches(self) -> None:
        self.state.write_text(json.dumps({
            "need_vet": True,
            "task": "verify the deploy",
        }))
        last_msg = "Ran the smoke test and saw 200 OK.\n<verified>Fully Vetted.</verified>"
        # Make `claude` CLI absent so _vet_synthesize_final_task no-ops cleanly.
        env = os.environ.copy()
        env["PATH"] = "/usr/bin:/bin"  # strip any user-installed `claude`
        result = run_bash(
            f'vet_phase {shlex.quote(str(self.state))} {shlex.quote(last_msg)} '
            f'{shlex.quote(str(self.transcript))}',
            env=env,
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        # No block JSON — verification accepted.
        self.assertEqual(result.stdout.strip(), "")
        # need_vet cleared.
        state = json.loads(self.state.read_text())
        self.assertNotIn("need_vet", state)


class SetupReentryGuardTests(unittest.TestCase):
    """setup-superpower-loop.sh must refuse to clobber an active loop
    without --force — the previous behavior silently reset iteration
    and effectively doubled max_iterations."""

    def setUp(self) -> None:
        self.tmpdir = tempfile.TemporaryDirectory()
        self.state = Path(self.tmpdir.name) / "state.json"

    def tearDown(self) -> None:
        self.tmpdir.cleanup()

    def test_refuses_without_force_when_active_loop_exists(self) -> None:
        self.state.write_text(json.dumps({
            "active": True,
            "iteration": 5,
            "max_iterations": 30,
            "started_at": "2026-05-07T10:00:00Z",
        }))
        result = subprocess.run(
            ["bash", str(SETUP), "--state-file", str(self.state),
             "--completion-promise", "DONE", "--max-iterations", "10",
             "Test prompt"],
            text=True,
            capture_output=True,
        )
        self.assertNotEqual(result.returncode, 0, msg="should refuse")
        self.assertIn("active Superpower Loop already exists", result.stderr)
        self.assertIn("--force", result.stderr)
        # State unchanged — iteration must still be 5, not reset to 1.
        state = json.loads(self.state.read_text())
        self.assertEqual(state["iteration"], 5)

    def test_force_flag_overwrites_active_loop(self) -> None:
        self.state.write_text(json.dumps({
            "active": True,
            "iteration": 5,
            "max_iterations": 30,
            "started_at": "2026-05-07T10:00:00Z",
        }))
        result = subprocess.run(
            ["bash", str(SETUP), "--state-file", str(self.state),
             "--completion-promise", "DONE", "--max-iterations", "10",
             "--force", "Test prompt"],
            text=True,
            capture_output=True,
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        state = json.loads(self.state.read_text())
        # iteration reset to 1, max_iterations from new args.
        self.assertEqual(state["iteration"], 1)
        self.assertEqual(state["max_iterations"], 10)
        self.assertEqual(state["completion_promise"], "DONE")
        self.assertTrue(state["active"])

    def test_normal_path_when_no_active_loop(self) -> None:
        # Inactive state file (e.g. left over from previous completed loop).
        self.state.write_text(json.dumps({"task": "stale"}))
        result = subprocess.run(
            ["bash", str(SETUP), "--state-file", str(self.state),
             "--completion-promise", "DONE", "--max-iterations", "10",
             "Test prompt"],
            text=True,
            capture_output=True,
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        state = json.loads(self.state.read_text())
        self.assertTrue(state["active"])
        self.assertEqual(state["iteration"], 1)
        # Pre-existing fields preserved by the new `. + {...}` merge.
        self.assertEqual(state.get("task"), "stale")


if __name__ == "__main__":
    unittest.main()
