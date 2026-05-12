"""Integration tests for the lib/loop.sh phase entrypoint, the
`find_state_file` legacy fallback warning, and the setup-superpower-loop
reentry guard.

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

from conftest import commit, make_git_repo


ROOT = Path(__file__).resolve().parents[2]
SUPERPOWERS = ROOT / "superpowers"
UTILS = SUPERPOWERS / "lib" / "utils.sh"
LOOP = SUPERPOWERS / "lib" / "loop.sh"
SETUP = SUPERPOWERS / "scripts" / "setup-superpower-loop.sh"
STOP_HOOK = SUPERPOWERS / "hooks" / "stop-hook.sh"
TRACK_CHANGES = SUPERPOWERS / "hooks" / "track-changes.sh"
TRACK_SPAWNS = SUPERPOWERS / "hooks" / "track-spawns.sh"


def run_bash(script: str, **kwargs) -> subprocess.CompletedProcess:
    """Run a bash script with utils.sh + loop.sh sourced.

    Uses `set -euo pipefail` to mirror stop-hook.sh's runtime environment.
    """
    full = (
        "set -euo pipefail\n"
        f"source {shlex.quote(str(UTILS))}\n"
        f"source {shlex.quote(str(LOOP))}\n"
        f"{script}"
    )
    return subprocess.run(
        ["bash", "-c", full],
        text=True,
        capture_output=True,
        **kwargs,
    )



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



class StopHookCorruptedStateTests(unittest.TestCase):
    """The stop-hook corrupted-JSON guard (stop-hook.sh:43-52) acquires
    a lock under a 1-second timeout, then falls back to an unlocked rm
    so a pathological lock holder never blocks Stop. Untested before
    this round."""

    def setUp(self) -> None:
        self.tmpdir = tempfile.TemporaryDirectory()
        self.fake_pwd = (Path(self.tmpdir.name) / "fake-cwd-corrupt").resolve()
        self.fake_pwd.mkdir()
        self.fake_pwd = self.fake_pwd.resolve()
        project_key = str(self.fake_pwd).replace("/", "-")
        self.state_dir = Path.home() / ".claude" / "projects" / project_key
        self.state_dir.mkdir(parents=True, exist_ok=True)
        self.session_id = "test-corrupt-session"
        self.state = self.state_dir / f"{self.session_id}.superpowers.json"
        self.transcript = Path(self.tmpdir.name) / "transcript.jsonl"
        self.transcript.write_text("")

    def tearDown(self) -> None:
        for p in self.state_dir.glob("*"):
            if p.is_dir():
                # Could be a `.lock` directory leftover.
                for child in p.glob("*"):
                    child.unlink()
                p.rmdir()
            else:
                p.unlink()
        try:
            self.state_dir.rmdir()
        except OSError:
            pass
        self.tmpdir.cleanup()

    def test_corrupted_state_file_is_removed_and_hook_exits_zero(self) -> None:
        # Write garbage that is not valid JSON.
        self.state.write_text("{ this is not json at all <<<")
        result = subprocess.run(
            ["bash", str(STOP_HOOK)],
            input=json.dumps({
                "session_id": self.session_id,
                "transcript_path": str(self.transcript),
                "last_assistant_message": "hi",
            }),
            text=True,
            capture_output=True,
            cwd=str(self.fake_pwd),
            timeout=15,
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        # The hook must have removed the corrupted file.
        self.assertFalse(self.state.exists(), msg="corrupted state file should be removed")
        # And the warning surfaced on stderr.
        self.assertIn("State file corrupted", result.stderr)


class FindStateFileMultiLegacyTests(unittest.TestCase):
    """Boundary case the first synthesis round missed: when MULTIPLE legacy
    files exist without session_id, find_state_file deterministically picks
    one and warns about which other files were ignored. Silent multi-file
    selection was a known crosstalk vector."""

    def setUp(self) -> None:
        self.tmpdir = tempfile.TemporaryDirectory()
        self.fake_pwd = Path(self.tmpdir.name) / "fake-cwd-multi"
        self.fake_pwd.mkdir()
        project_key = str(self.fake_pwd).replace("/", "-")
        self.state_dir = Path.home() / ".claude" / "projects" / project_key
        self.state_dir.mkdir(parents=True, exist_ok=True)

    def tearDown(self) -> None:
        for p in self.state_dir.glob("*"):
            p.unlink()
        try:
            self.state_dir.rmdir()
        except OSError:
            pass
        self.tmpdir.cleanup()

    def test_warns_when_multiple_legacy_files_exist(self) -> None:
        (self.state_dir / "a.superpowers.json").write_text("{}")
        (self.state_dir / "b.superpowers.json").write_text("{}")
        (self.state_dir / "c.superpowers.json").write_text("{}")
        result = subprocess.run(
            ["bash", "-c", f'cd {shlex.quote(str(self.fake_pwd))} && '
                           f'source {shlex.quote(str(UTILS))} && '
                           f'find_state_file "wanted-session"'],
            text=True,
            capture_output=True,
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        # One file picked, warning surfaces both the chosen file and the count.
        self.assertIn(".superpowers.json", result.stdout)
        self.assertIn("legacy file without session_id", result.stderr)
        # New invariant: warning must surface the multi-file case so the
        # user is not silently routed to one of N candidates.
        self.assertIn("3 legacy file", result.stderr)


class HookDepsMissingBailSoftTests(unittest.TestCase):
    """When jq or perl are missing from PATH, every hook must exit 0
    cleanly without crashing the user's session. utils.sh sets
    _SUPERPOWERS_DEPS_MISSING=1 and emits a one-line warning; the
    hooks check the flag immediately after sourcing.

    Empty PATH simulates the missing-deps environment without having
    to actually uninstall jq."""

    HOOKS = [
        SUPERPOWERS / "hooks" / "stop-hook.sh",
        SUPERPOWERS / "hooks" / "task-start.sh",
        SUPERPOWERS / "hooks" / "track-changes.sh",
    ]

    def setUp(self) -> None:
        self.tmpdir = tempfile.TemporaryDirectory()
        import shutil
        bash_path = shutil.which("bash")
        if not bash_path:
            self.skipTest("bash not on PATH; cannot run hook tests")
        self.bash = bash_path
        # Build a curated PATH dir: symlink in the coreutils the hooks need
        # (dirname, cat, mkdir, sort, grep, sed, date, mv, rm) but NOT jq
        # or perl. This works regardless of where jq lives on the host
        # (macOS now ships jq in /usr/bin, breaking the "minimal PATH"
        # approach). The deps check fires deterministically.
        self.curated_bin = Path(self.tmpdir.name) / "curated-bin"
        self.curated_bin.mkdir()
        for tool in ("dirname", "cat", "mkdir", "sort", "grep", "sed",
                     "date", "mv", "rm", "find", "tr", "tail", "ps",
                     "sleep", "command", "echo", "head", "stat", "cut", "wc"):
            src = shutil.which(tool)
            if src:
                (self.curated_bin / tool).symlink_to(src)
        self.empty_path = str(self.curated_bin)

    def tearDown(self) -> None:
        self.tmpdir.cleanup()

    def _run_hook(self, hook: Path, input_data: dict) -> subprocess.CompletedProcess:
        env = os.environ.copy()
        env["PATH"] = self.empty_path
        return subprocess.run(
            [self.bash, str(hook)],
            input=json.dumps(input_data),
            text=True,
            capture_output=True,
            env=env,
            timeout=10,
        )

    def test_stop_hook_bails_soft_when_jq_missing(self) -> None:
        result = self._run_hook(self.HOOKS[0], {
            "session_id": "x",
            "transcript_path": "/tmp/none.jsonl",
            "last_assistant_message": "",
        })
        # Must exit 0 — anything else blocks the user's Stop.
        self.assertEqual(result.returncode, 0,
                         msg=f"stop-hook crashed without jq: {result.stderr}")
        # Warning surfaces so user sees why hook is silent.
        self.assertIn("requires", result.stderr)
        # D1 fix (2026-05-12): sync hooks emit a Claude-Code-visible
        # systemMessage JSON instead of dying silently. Previously the
        # hook went mute and there was no surface signaling the skip.
        self.assertIn("systemMessage", result.stdout)
        self.assertIn("missing runtime deps", result.stdout)

    def test_task_start_bails_soft_when_jq_missing(self) -> None:
        result = self._run_hook(self.HOOKS[1], {
            "session_id": "x",
            "prompt": "test prompt",
        })
        self.assertEqual(result.returncode, 0,
                         msg=f"task-start crashed without jq: {result.stderr}")
        # D1: sync hook surfaces systemMessage on deps-missing.
        self.assertIn("systemMessage", result.stdout)
        self.assertIn("missing runtime deps", result.stdout)

    def test_track_changes_bails_soft_when_jq_missing(self) -> None:
        result = self._run_hook(self.HOOKS[2], {
            "session_id": "x",
            "tool_input": {"file_path": "/tmp/some-file.py"},
        })
        self.assertEqual(result.returncode, 0,
                         msg=f"track-changes crashed without jq: {result.stderr}")
        # D1: async PostToolUse hook deliberately stays silent on
        # deps-missing — its stdout is not user-visible UI, and emitting
        # systemMessage here would dilute the sync-hook signal.
        self.assertEqual(result.stdout.strip(), "")

    def test_setup_superpower_loop_hard_fails_when_jq_missing(self) -> None:
        """Inverse of the hook bail-soft: setup-superpower-loop is a
        user-invoked CLI that needs jq to construct JSON. It should
        hard-fail with a clear message rather than produce a broken
        state file."""
        env = os.environ.copy()
        env["PATH"] = self.empty_path
        result = subprocess.run(
            [self.bash, str(SETUP), "--completion-promise", "DONE", "Test"],
            text=True,
            capture_output=True,
            env=env,
            timeout=10,
        )
        # Hard fail: nonzero exit, error message names jq.
        self.assertNotEqual(result.returncode, 0,
                            msg="setup-superpower-loop should refuse without jq")
        self.assertIn("jq", result.stderr)


class LoopPhaseTests(unittest.TestCase):
    """End-to-end tests for loop_phase (lib/loop.sh) — the Superpower Loop
    iteration logic invoked by stop-hook.sh.

    Covers the production paths that prior synthesis rounds left untested:
    - active loop + promise match (clears state, allows session exit)
    - active loop + no match (emits block JSON to continue)
    - corrupted state fields (clears loop, allows exit)
    - terminal conditions (max iterations, missing transcript)
    """

    def setUp(self) -> None:
        self.tmpdir = tempfile.TemporaryDirectory()
        self.state = Path(self.tmpdir.name) / "state.json"
        self.transcript = Path(self.tmpdir.name) / "transcript.jsonl"

    def tearDown(self) -> None:
        self.tmpdir.cleanup()

    def _write_transcript(self, last_text: str) -> None:
        """Write a single assistant message into the transcript JSONL.

        Uses compact JSON (no separator spaces) because extract_last_assistant_text
        greps for the literal substring `"role":"assistant"` — pretty-printed
        `"role": "assistant"` would produce a false negative."""
        line = {
            "role": "assistant",
            "message": {"content": [{"type": "text", "text": last_text}]},
        }
        self.transcript.write_text(json.dumps(line, separators=(",", ":")) + "\n")

    def test_returns_zero_when_no_active_loop(self) -> None:
        """Inactive loop: loop_phase returns 0 — caller falls through to exit."""
        self.state.write_text(json.dumps({"task": "ship it"}))
        self._write_transcript("done")
        result = run_bash(
            f'loop_phase {shlex.quote(str(self.state))} {shlex.quote(str(self.transcript))}\n'
            'echo "FELL_THROUGH"'
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        # Caller continues to next line — session exit follows.
        self.assertIn("FELL_THROUGH", result.stdout)

    def test_active_loop_no_promise_emits_block_json(self) -> None:
        """Active loop without match: emit block JSON, exit 0, increment iteration."""
        self.state.write_text(json.dumps({
            "active": True,
            "iteration": 1,
            "max_iterations": 0,
            "completion_promise": "DONE",
            "prompt": "Build the thing",
            "skill_name": "",
        }))
        self._write_transcript("Still working on it...")
        result = run_bash(
            f'loop_phase {shlex.quote(str(self.state))} {shlex.quote(str(self.transcript))}\n'
            'echo "FELL_THROUGH"'
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        # loop_phase must exit, not fall through.
        self.assertNotIn("FELL_THROUGH", result.stdout)
        # Block JSON shape.
        payload = json.loads(result.stdout)
        self.assertEqual(payload["decision"], "block")
        self.assertIn("Build the thing", payload["reason"])
        self.assertIn("DONE", payload["reason"])
        # systemMessage uses the compact "iter N" tag (no max → no /M).
        self.assertIn("iter 2", payload["systemMessage"])
        self.assertIn("Superpower Loop", payload["systemMessage"])
        # Iteration incremented in state.
        state = json.loads(self.state.read_text())
        self.assertEqual(state["iteration"], 2)

    def test_active_loop_with_promise_match_clears_state(self) -> None:
        """Active loop + matching promise: clear loop fields, allow session exit."""
        self.state.write_text(json.dumps({
            "active": True,
            "iteration": 3,
            "max_iterations": 0,
            "completion_promise": "DONE",
            "prompt": "Build the thing",
            "skill_name": "ad-hoc",
        }))
        self._write_transcript("Finished and verified.\n<promise>DONE</promise>")
        result = run_bash(
            f'loop_phase {shlex.quote(str(self.state))} {shlex.quote(str(self.transcript))}\n'
            'echo "FELL_THROUGH"'
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertIn("FELL_THROUGH", result.stdout)
        # Loop fields must be cleared.
        state = json.loads(self.state.read_text())
        for field in ("active", "iteration", "max_iterations", "completion_promise",
                      "prompt", "started_at"):
            self.assertNotIn(field, state, msg=f"{field} not cleared")

    def test_max_iterations_reached_clears_loop(self) -> None:
        """Loop hits max: announce, clear, fall through."""
        self.state.write_text(json.dumps({
            "active": True,
            "iteration": 5,
            "max_iterations": 5,
            "completion_promise": "DONE",
            "prompt": "Try it",
            "skill_name": "",
        }))
        self._write_transcript("attempt 5")
        result = run_bash(
            f'loop_phase {shlex.quote(str(self.state))} {shlex.quote(str(self.transcript))}\n'
            'echo "FELL_THROUGH"'
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertIn("FELL_THROUGH", result.stdout)
        self.assertIn("Max iterations", result.stdout)
        state = json.loads(self.state.read_text())
        self.assertNotIn("active", state)

    def test_corrupted_iteration_field_clears_loop(self) -> None:
        """Non-numeric iteration: warn, clear, fall through (no crash under set -e)."""
        self.state.write_text(json.dumps({
            "active": True,
            "iteration": "NaN",  # corrupted
            "max_iterations": 0,
            "completion_promise": "DONE",
            "prompt": "Try",
            "skill_name": "",
        }))
        self._write_transcript("anything")
        result = run_bash(
            f'loop_phase {shlex.quote(str(self.state))} {shlex.quote(str(self.transcript))}\n'
            'echo "FELL_THROUGH"'
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertIn("FELL_THROUGH", result.stdout)
        self.assertIn("not numeric", result.stderr)
        state = json.loads(self.state.read_text())
        self.assertNotIn("active", state)

    def test_corrupted_max_iterations_field_clears_loop(self) -> None:
        self.state.write_text(json.dumps({
            "active": True,
            "iteration": 1,
            "max_iterations": "infinity",  # corrupted
            "completion_promise": "DONE",
            "prompt": "Try",
            "skill_name": "",
        }))
        self._write_transcript("anything")
        result = run_bash(
            f'loop_phase {shlex.quote(str(self.state))} {shlex.quote(str(self.transcript))}\n'
            'echo "FELL_THROUGH"'
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertIn("FELL_THROUGH", result.stdout)
        self.assertIn("not numeric", result.stderr)
        state = json.loads(self.state.read_text())
        self.assertNotIn("active", state)

    def test_missing_transcript_clears_loop(self) -> None:
        """No transcript file: clear loop silently, fall through."""
        self.state.write_text(json.dumps({
            "active": True,
            "iteration": 1,
            "max_iterations": 0,
            "completion_promise": "DONE",
            "prompt": "Try",
            "skill_name": "",
        }))
        # transcript intentionally not created.
        result = run_bash(
            f'loop_phase {shlex.quote(str(self.state))} {shlex.quote(str(self.transcript))}\n'
            'echo "FELL_THROUGH"'
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertIn("FELL_THROUGH", result.stdout)
        state = json.loads(self.state.read_text())
        self.assertNotIn("active", state)

    def test_missing_prompt_clears_loop_with_warning(self) -> None:
        """State has no prompt: clear with warning, fall through (cannot re-inject
        without a prompt to replay)."""
        self.state.write_text(json.dumps({
            "active": True,
            "iteration": 1,
            "max_iterations": 0,
            "completion_promise": "DONE",
            "prompt": "",  # missing
            "skill_name": "",
        }))
        self._write_transcript("still going")
        result = run_bash(
            f'loop_phase {shlex.quote(str(self.state))} {shlex.quote(str(self.transcript))}\n'
            'echo "FELL_THROUGH"'
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertIn("FELL_THROUGH", result.stdout)
        self.assertIn("no prompt", result.stderr)
        state = json.loads(self.state.read_text())
        self.assertNotIn("active", state)

    def test_modified_files_injected_into_block_reason(self) -> None:
        """Active loop with track-changes.sh-accumulated modified_files: block
        reason includes the cumulative artifact snapshot so iteration N+1 can
        Read/Edit existing files instead of recreating them. Without this the
        loop body has no progress indicator beyond what's recoverable from the
        transcript, which compaction can drop."""
        self.state.write_text(json.dumps({
            "active": True,
            "iteration": 1,
            "max_iterations": 0,
            "completion_promise": "DONE",
            "prompt": "Build it",
            "skill_name": "",
            "modified_files": [
                "docs/plans/2026-05-07-feat-design/_index.md",
                "docs/plans/2026-05-07-feat-design/bdd-specs.md",
            ],
        }))
        self._write_transcript("Working...")
        result = run_bash(
            f'loop_phase {shlex.quote(str(self.state))} {shlex.quote(str(self.transcript))}'
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        payload = json.loads(result.stdout)
        self.assertIn("Already produced this session", payload["reason"])
        self.assertIn("docs/plans/2026-05-07-feat-design/_index.md", payload["reason"])
        self.assertIn("docs/plans/2026-05-07-feat-design/bdd-specs.md", payload["reason"])

    def test_modified_files_capped_at_twenty_with_overflow_pointer(self) -> None:
        """Without a cap the artifact snapshot grows monotonically across long
        loops (50 files * 30 iterations = 4KB re-injected every turn) — exactly
        the working-context pollution superpowers is supposed to prevent.
        Cap at 20 + emit a `... (N more — see state file)` pointer for
        overflow so Claude knows where to look when the visible list is
        truncated."""
        files = [f"src/module_{i:02d}.py" for i in range(25)]
        self.state.write_text(json.dumps({
            "active": True,
            "iteration": 1,
            "max_iterations": 0,
            "completion_promise": "DONE",
            "prompt": "Build it",
            "skill_name": "",
            "modified_files": files,
        }))
        self._write_transcript("Working...")
        result = run_bash(
            f'loop_phase {shlex.quote(str(self.state))} {shlex.quote(str(self.transcript))}'
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        payload = json.loads(result.stdout)
        # First 20 entries (sorted) appear; sort -u sorts lexicographically,
        # so module_00 .. module_19 are the visible window.
        for i in range(20):
            self.assertIn(f"src/module_{i:02d}.py", payload["reason"])
        # Overflow pointer present.
        self.assertIn("... (5 more", payload["reason"])
        # Entries 20-24 must NOT leak through.
        for i in range(20, 25):
            self.assertNotIn(f"src/module_{i:02d}.py", payload["reason"])

    def test_empty_modified_files_omits_artifact_section(self) -> None:
        """No modified_files (or empty array): omit the snapshot block entirely
        rather than emit a section with no entries — keeps re-injection lean
        when there's nothing to report."""
        self.state.write_text(json.dumps({
            "active": True,
            "iteration": 1,
            "max_iterations": 0,
            "completion_promise": "DONE",
            "prompt": "Build it",
            "skill_name": "",
            "modified_files": [],
        }))
        self._write_transcript("Working...")
        result = run_bash(
            f'loop_phase {shlex.quote(str(self.state))} {shlex.quote(str(self.transcript))}'
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        payload = json.loads(result.stdout)
        self.assertNotIn("Already produced this session", payload["reason"])

    def test_skill_name_emits_continue_header_without_base_prompt(self) -> None:
        """When skill_name is set, the re-injection header is the bare
        continuation phrase "Continue superpowers:X (iter N/M)." — no
        verbose prompt body, no "do NOT re-run" prefix. The original
        base_prompt is intentionally NOT re-injected: SKILL.md's
        "Resumed loop" guard + TaskList state are the source of truth
        for resume location, and re-pasting the same multi-sentence
        prompt every iteration is the working-context pollution this
        plugin is supposed to prevent."""
        self.state.write_text(json.dumps({
            "active": True,
            "iteration": 1,
            "max_iterations": 100,
            "completion_promise": "DONE",
            "prompt": "Execute the plan at docs/plans/feat-plan. Continue progressing through phases.",
            "skill_name": "writing-plans",
        }))
        self._write_transcript("working")
        result = run_bash(
            f'loop_phase {shlex.quote(str(self.state))} {shlex.quote(str(self.transcript))}'
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        payload = json.loads(result.stdout)
        reason = payload["reason"]
        # Continuation phrase, no slash-command-style re-entry signal.
        self.assertIn("Continue superpowers:writing-plans", reason)
        self.assertNotIn("Use superpowers:writing-plans skill", reason)
        self.assertIn("iter 2/100", reason)
        # base_prompt content must NOT leak into reason.
        self.assertNotIn("docs/plans/feat-plan", reason)
        self.assertNotIn("Continue progressing through phases", reason)
        # systemMessage mirrors the continuation phrasing.
        self.assertIn("Superpower Loop iter 2/100", payload["systemMessage"])
        self.assertIn("Continue writing-plans", payload["systemMessage"])

    def test_post_first_iteration_omits_modified_files_section(self) -> None:
        """After the first re-injection (next_iteration > 2), the
        cumulative modified_files snapshot is omitted entirely. The
        list is in the state file and SKILL.md is in working context;
        re-pasting it every turn is exactly the pollution this plugin
        claims to prevent."""
        self.state.write_text(json.dumps({
            "active": True,
            "iteration": 2,  # next = 3, past the first re-injection
            "max_iterations": 100,
            "completion_promise": "DONE",
            "prompt": "Execute the plan.",
            "skill_name": "brainstorming",
            "modified_files": [
                "docs/plans/feat-design/_index.md",
                "docs/plans/feat-design/bdd-specs.md",
            ],
        }))
        self._write_transcript("Phase 2 in flight...")
        result = run_bash(
            f'loop_phase {shlex.quote(str(self.state))} {shlex.quote(str(self.transcript))}'
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        payload = json.loads(result.stdout)
        reason = payload["reason"]
        self.assertIn("Continue superpowers:brainstorming", reason)
        self.assertNotIn("Already produced this session", reason)
        # Footer's promise reminder is always present.
        self.assertIn("<promise>DONE</promise>", reason)

    def test_stuck_triggers_when_executing_plans_direct_edits_exceed_threshold(self) -> None:
        """Stuck detection fires when the active skill is executing-plans
        AND iteration >= 2 AND edits_since_last_spawn > 5. This catches
        the empirical bug pattern from a real run: main agent does Phase 3
        steps 0-1 correctly, then instead of spawning a coordinator (step 2),
        it inline-edits batch task source files turn after turn. Each
        Edit/Write/MultiEdit hits PostToolUse track-changes.sh which bumps
        .edits_since_last_spawn — once the counter exceeds 5, the loop
        flags STUCK and points the agent at Phase 3 step 2 + the
        Main Agent's Direct-Edit Allow-List for recovery."""
        self.state.write_text(json.dumps({
            "active": True,
            "iteration": 4,
            "max_iterations": 100,
            "completion_promise": "EXECUTION_COMPLETE",
            "prompt": "Execute the plan at docs/plans/feat-plan.",
            "skill_name": "executing-plans",
            "edits_since_last_spawn": 8,  # past the 5-edit threshold
        }))
        self._write_transcript("Working on the next batch...")
        result = run_bash(
            f'loop_phase {shlex.quote(str(self.state))} {shlex.quote(str(self.transcript))}'
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        payload = json.loads(result.stdout)
        # systemMessage flags STUCK with the precise edit count and signal name.
        self.assertIn("STUCK", payload["systemMessage"])
        self.assertIn("8 direct edits", payload["systemMessage"])
        self.assertIn("Phase 3 step 2", payload["systemMessage"])
        # reason carries the recovery instructions naming the exact mechanism.
        self.assertIn("**STUCK**", payload["reason"])
        self.assertIn("8 direct file edits", payload["reason"])
        self.assertIn("Agent tool", payload["reason"])
        self.assertIn("EXECUTION_COMPLETE", payload["reason"])
        # The base_prompt (which would carry phase hints) is intentionally
        # OMITTED in the stuck branch — the recovery instructions take
        # precedence over routine continuation guidance, otherwise the
        # agent would continue acting on the original "do the plan" prompt
        # and skip past the recovery hint.
        self.assertNotIn(
            "Execute the plan at docs/plans/feat-plan", payload["reason"],
            msg="base_prompt must not be appended on stuck — recovery takes precedence",
        )

    def test_stuck_does_not_trigger_for_non_executing_plans_skill(self) -> None:
        """Stuck detection is scoped strictly to executing-plans because
        brainstorming and writing-plans LEGITIMATELY produce many
        main-context edits (design docs, plan files) — they have no
        sub-agent spawn requirement, so a high edits_since_last_spawn
        counter there is normal, not a violation. A scope leak would
        false-positive on every brainstorming/writing-plans run."""
        for skill in ("brainstorming", "writing-plans"):
            with self.subTest(skill=skill):
                self.state.write_text(json.dumps({
                    "active": True,
                    "iteration": 5,
                    "max_iterations": 100,
                    "completion_promise": "DONE",
                    "prompt": f"Run {skill}",
                    "skill_name": skill,
                    "edits_since_last_spawn": 25,  # would trigger if scoped wrong
                }))
                self._write_transcript("Writing design doc...")
                result = run_bash(
                    f'loop_phase {shlex.quote(str(self.state))} {shlex.quote(str(self.transcript))}'
                )
                self.assertEqual(result.returncode, 0, msg=result.stderr)
                payload = json.loads(result.stdout)
                self.assertNotIn("STUCK", payload["systemMessage"])
                self.assertNotIn("STUCK DETECTED", payload["reason"])

    def test_stuck_does_not_trigger_in_first_iteration(self) -> None:
        """Iteration 1 is the loop's setup turn — main agent legitimately
        writes its allow-list files (handoff-state.md, sprint-contract-
        batch-1.md, possibly an _index.md update from PIVOT logic). The
        stuck gate requires iteration >= 2 specifically to spare these
        legitimate setup edits from false-positive STUCK flags."""
        self.state.write_text(json.dumps({
            "active": True,
            "iteration": 1,
            "max_iterations": 100,
            "completion_promise": "EXECUTION_COMPLETE",
            "prompt": "Execute the plan at docs/plans/feat-plan.",
            "skill_name": "executing-plans",
            "edits_since_last_spawn": 10,  # would trigger if iter gate wrong
        }))
        self._write_transcript("Setup batch in progress.")
        result = run_bash(
            f'loop_phase {shlex.quote(str(self.state))} {shlex.quote(str(self.transcript))}'
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        payload = json.loads(result.stdout)
        self.assertNotIn("STUCK", payload["systemMessage"])
        self.assertNotIn("STUCK DETECTED", payload["reason"])

    def test_stuck_does_not_trigger_at_or_below_threshold(self) -> None:
        """Threshold semantics are strictly `> 5` (six or more), giving the
        main agent headroom for its allow-list per batch: handoff-state +
        sprint contract + maybe an _index.md PIVOT update + an
        evaluation-round-N-batch-M.md = ~4. Five direct edits without a
        spawn is borderline-but-tolerable; the sixth crosses into "this
        is batch task work, not allow-list work" territory."""
        for edits in (0, 3, 5):
            with self.subTest(edits=edits):
                self.state.write_text(json.dumps({
                    "active": True,
                    "iteration": 4,
                    "max_iterations": 100,
                    "completion_promise": "EXECUTION_COMPLETE",
                    "prompt": "Execute the plan at docs/plans/feat-plan.",
                    "skill_name": "executing-plans",
                    "edits_since_last_spawn": edits,
                }))
                self._write_transcript("Continuing batch.")
                result = run_bash(
                    f'loop_phase {shlex.quote(str(self.state))} {shlex.quote(str(self.transcript))}'
                )
                self.assertEqual(result.returncode, 0, msg=result.stderr)
                payload = json.loads(result.stdout)
                self.assertNotIn("STUCK", payload["systemMessage"],
                                 msg=f"edits={edits} should not trigger STUCK")
                self.assertNotIn("STUCK DETECTED", payload["reason"])

    def test_executing_plans_promise_match_writes_plan_completion_log(self) -> None:
        """When executing-plans loop promise matches, the hook appends a
        plan_completed entry to <project>/docs/retros/plans-completed.jsonl.
        Empirical audit (agentbook real project, 2 completed plans) found
        this file never existed despite the SKILL.md instructing Claude to
        write it — the manual write was being silently dropped, decaying
        retrospective auto-scope, RETROSPECTIVE DUE reminders, and Phase 5c
        assumption tests to no-ops. Hook makes the write mechanical."""
        project_root = Path(self.tmpdir.name) / "fake-project"
        project_root.mkdir()

        self.state.write_text(json.dumps({
            "active": True,
            "iteration": 5,
            "max_iterations": 0,
            "completion_promise": "EXECUTION_COMPLETE",
            "prompt": "Execute the plan at docs/plans/2026-05-07-banner-plan. Continue progressing through superpowers:executing-plans skill phases.",
            "skill_name": "executing-plans",
        }))
        self._write_transcript("All tasks done and committed.\n<promise>EXECUTION_COMPLETE</promise>")

        result = run_bash(
            f'loop_phase {shlex.quote(str(self.state))} {shlex.quote(str(self.transcript))}\n'
            'echo "FELL_THROUGH"',
            cwd=str(project_root),
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        # Post-vet-removal (2026-05-12): loop_phase returns 0 and the caller
        # falls through to session exit. The plan-completion log write
        # happens BEFORE _loop_clear_state, so the log entry still lands.
        self.assertIn("FELL_THROUGH", result.stdout)

        log_file = project_root / "docs" / "retros" / "plans-completed.jsonl"
        self.assertTrue(
            log_file.exists(),
            f"plans-completed.jsonl missing at {log_file}",
        )
        lines = log_file.read_text().strip().split("\n")
        self.assertEqual(len(lines), 1)
        entry = json.loads(lines[0])
        self.assertEqual(entry["event"], "plan_completed")
        # v2.8.2: plan field is repo-relative (no /Users/ or /tmp/ prefix —
        # cross-worktree / cross-clone stable so dedup matches reliably).
        self.assertEqual(entry["plan"], "docs/plans/2026-05-07-banner-plan")
        self.assertNotIn("/Users/", entry["plan"])
        self.assertNotIn("/tmp/", entry["plan"])
        self.assertNotIn(str(project_root), entry["plan"])
        self.assertRegex(entry["timestamp"], r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$")

    def test_writing_plans_promise_match_does_not_write_completion_log(self) -> None:
        """plans-completed.jsonl is the executing-plans-only completion log.
        Other workflow skills (brainstorming, writing-plans) emit different
        promises (BRAINSTORMING_COMPLETE / PLAN_COMPLETE) and must not
        pollute this file — retrospective Phase 1 auto-scope reads it and
        would conflate design/plan completion with execution completion."""
        project_root = Path(self.tmpdir.name) / "fake-project"
        project_root.mkdir()

        self.state.write_text(json.dumps({
            "active": True,
            "iteration": 2,
            "max_iterations": 0,
            "completion_promise": "PLAN_COMPLETE",
            "prompt": "Write an implementation plan for: docs/plans/2026-05-07-banner-design.",
            "skill_name": "writing-plans",
        }))
        self._write_transcript("Plan written.\n<promise>PLAN_COMPLETE</promise>")

        result = run_bash(
            f'loop_phase {shlex.quote(str(self.state))} {shlex.quote(str(self.transcript))}',
            cwd=str(project_root),
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        log_file = project_root / "docs" / "retros" / "plans-completed.jsonl"
        self.assertFalse(
            log_file.exists(),
            "writing-plans completion must not pollute plans-completed.jsonl",
        )

    def test_plan_completion_log_includes_task_and_batch_counts(self) -> None:
        """plan_completed entries enrich with task_count + batch_count when the
        plan dir contains _index.md (with `- id:` YAML rows) and at least one
        sprint-contract-batch-*.md file. Retrospective Phase 1 + executing-plans
        Phase 6 retro-due reminder both treat 0 as 'unknown' but a real
        non-zero value lets retrospective compute task density across plans."""
        project_root = Path(self.tmpdir.name) / "fake-project"
        plan_dir = project_root / "docs" / "plans" / "2026-05-07-banner-plan"
        plan_dir.mkdir(parents=True)
        (plan_dir / "_index.md").write_text(
            "# banner plan\n\n## Execution Plan\n\n```yaml\n"
            "tasks:\n"
            "  - id: \"001\"\n    subject: setup\n"
            "  - id: \"002\"\n    subject: red\n"
            "  - id: \"003\"\n    subject: green\n"
            "  - id: \"004\"\n    subject: refactor\n"
            "```\n"
        )
        (plan_dir / "sprint-contract-batch-1.md").write_text("contract 1\n")
        (plan_dir / "sprint-contract-batch-2.md").write_text("contract 2\n")

        self.state.write_text(json.dumps({
            "active": True,
            "iteration": 5,
            "max_iterations": 0,
            "completion_promise": "EXECUTION_COMPLETE",
            "prompt": "Execute the plan at docs/plans/2026-05-07-banner-plan.",
            "skill_name": "executing-plans",
        }))
        self._write_transcript("done\n<promise>EXECUTION_COMPLETE</promise>")

        result = run_bash(
            f'loop_phase {shlex.quote(str(self.state))} {shlex.quote(str(self.transcript))}',
            cwd=str(project_root),
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)

        log_file = project_root / "docs" / "retros" / "plans-completed.jsonl"
        entry = json.loads(log_file.read_text().strip().split("\n")[0])
        self.assertEqual(entry["task_count"], 4)
        self.assertEqual(entry["batch_count"], 2)

    def test_plan_completion_log_zero_counts_when_files_missing(self) -> None:
        """When the prompt resolves a plan dir that does not exist on disk
        (e.g., the user committed the plan and wiped the worktree before the
        promise fired), task_count + batch_count default to 0 but the entry
        is still written. Downstream consumers treat 0 as 'unknown'."""
        project_root = Path(self.tmpdir.name) / "fake-project"
        project_root.mkdir()

        self.state.write_text(json.dumps({
            "active": True,
            "iteration": 5,
            "max_iterations": 0,
            "completion_promise": "EXECUTION_COMPLETE",
            "prompt": "Execute the plan at docs/plans/2026-05-07-ghost-plan.",
            "skill_name": "executing-plans",
        }))
        self._write_transcript("done\n<promise>EXECUTION_COMPLETE</promise>")

        result = run_bash(
            f'loop_phase {shlex.quote(str(self.state))} {shlex.quote(str(self.transcript))}',
            cwd=str(project_root),
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)

        log_file = project_root / "docs" / "retros" / "plans-completed.jsonl"
        entry = json.loads(log_file.read_text().strip().split("\n")[0])
        self.assertEqual(entry["task_count"], 0)
        self.assertEqual(entry["batch_count"], 0)
        # Required fields all present even on empty enrichment.
        self.assertEqual(entry["event"], "plan_completed")
        # v2.8.2: plan stays repo-relative even when the dir doesn't exist.
        self.assertEqual(entry["plan"], "docs/plans/2026-05-07-ghost-plan")
        self.assertRegex(entry["timestamp"], r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$")

    def test_plan_completion_log_includes_completion_commit_when_in_git_repo(self) -> None:
        """v2.8.1: plan_completed entries capture completion_commit (HEAD SHA
        at completion) so retrospective Phase 1 step 8 can run a post-plan
        diff. Empirical motivation: user-simulation 2026-05-08 retrospective
        ran 16 minutes after plan completion and disabled
        recurring_failure_patterns based on blank-injection signal alone —
        the user's 5 refactor commits arrived 12-13h later and were never
        seen. Hook-side capture closes that data gap mechanically."""
        project_root = Path(self.tmpdir.name) / "fake-project"
        plan_dir = project_root / "docs" / "plans" / "2026-05-07-banner-plan"
        plan_dir.mkdir(parents=True)
        (plan_dir / "_index.md").write_text("# banner plan\n")
        make_git_repo(project_root)
        expected_sha = commit(project_root, "feat: completion baseline",
                              {"_baseline.txt": "x\n"})

        self.state.write_text(json.dumps({
            "active": True,
            "iteration": 5,
            "max_iterations": 0,
            "completion_promise": "EXECUTION_COMPLETE",
            "prompt": "Execute the plan at docs/plans/2026-05-07-banner-plan.",
            "skill_name": "executing-plans",
            "modified_files": ["src/foo.py", "tests/test_foo.py"],
        }))
        self._write_transcript("done\n<promise>EXECUTION_COMPLETE</promise>")

        result = run_bash(
            f'loop_phase {shlex.quote(str(self.state))} {shlex.quote(str(self.transcript))}',
            cwd=str(project_root),
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)

        log_file = project_root / "docs" / "retros" / "plans-completed.jsonl"
        entry = json.loads(log_file.read_text().strip().split("\n")[0])
        self.assertEqual(entry["completion_commit"], expected_sha)
        self.assertEqual(entry["completion_modified_files"], ["src/foo.py", "tests/test_foo.py"])

    def test_plan_completion_log_completion_commit_empty_outside_git_repo(self) -> None:
        """When the project root is not a git repo (rare but possible —
        sandboxed plan directory, archive extraction), completion_commit
        falls back to empty string and modified_files defaults to []. The
        canonical event still lands so downstream consumers (retrospective
        auto-scope, RETROSPECTIVE DUE counter) keep working."""
        project_root = Path(self.tmpdir.name) / "fake-project"
        plan_dir = project_root / "docs" / "plans" / "2026-05-07-banner-plan"
        plan_dir.mkdir(parents=True)
        (plan_dir / "_index.md").write_text("# banner plan\n")
        # Deliberately NOT calling git init — completion_commit must fall back.

        self.state.write_text(json.dumps({
            "active": True,
            "iteration": 5,
            "max_iterations": 0,
            "completion_promise": "EXECUTION_COMPLETE",
            "prompt": "Execute the plan at docs/plans/2026-05-07-banner-plan.",
            "skill_name": "executing-plans",
            # state without modified_files — defaults to [].
        }))
        self._write_transcript("done\n<promise>EXECUTION_COMPLETE</promise>")

        result = run_bash(
            f'loop_phase {shlex.quote(str(self.state))} {shlex.quote(str(self.transcript))}',
            cwd=str(project_root),
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)

        log_file = project_root / "docs" / "retros" / "plans-completed.jsonl"
        entry = json.loads(log_file.read_text().strip().split("\n")[0])
        self.assertEqual(entry["completion_commit"], "")
        self.assertEqual(entry["completion_modified_files"], [])

    def test_plan_completion_log_dedups_same_plan_across_re_entries(self) -> None:
        """v2.8.2: plans-completed.jsonl is "first completion per plan".
        Multiple promise fires on the same plan (re-entry, amendment,
        partial rerun) must NOT produce multiple entries — that would
        inflate RETROSPECTIVE DUE counts and pollute retrospective auto-scope.
        Empirical motivation: user-simulation 2026-05-08 logged the same
        plan twice (once with trailing slash + no enrichment, once without
        + with enrichment) because v2.7.0 had no dedup gate."""
        project_root = Path(self.tmpdir.name) / "fake-project"
        plan_dir = project_root / "docs" / "plans" / "2026-05-07-banner-plan"
        plan_dir.mkdir(parents=True)
        (plan_dir / "_index.md").write_text("# banner plan\n")

        # Fire promise once — should write 1 line.
        self.state.write_text(json.dumps({
            "active": True,
            "iteration": 5,
            "max_iterations": 0,
            "completion_promise": "EXECUTION_COMPLETE",
            "prompt": "Execute the plan at docs/plans/2026-05-07-banner-plan.",
            "skill_name": "executing-plans",
        }))
        self._write_transcript("done\n<promise>EXECUTION_COMPLETE</promise>")
        result = run_bash(
            f'loop_phase {shlex.quote(str(self.state))} {shlex.quote(str(self.transcript))}',
            cwd=str(project_root),
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)

        # Fire promise a second time on the same plan — must NOT append.
        self.state.write_text(json.dumps({
            "active": True,
            "iteration": 8,
            "max_iterations": 0,
            "completion_promise": "EXECUTION_COMPLETE",
            "prompt": "Execute the plan at docs/plans/2026-05-07-banner-plan.",
            "skill_name": "executing-plans",
        }))
        self._write_transcript("done again\n<promise>EXECUTION_COMPLETE</promise>")
        result = run_bash(
            f'loop_phase {shlex.quote(str(self.state))} {shlex.quote(str(self.transcript))}',
            cwd=str(project_root),
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)

        log_file = project_root / "docs" / "retros" / "plans-completed.jsonl"
        lines = log_file.read_text().strip().split("\n")
        self.assertEqual(len(lines), 1, msg=f"expected exactly 1 entry, got: {lines}")

    def test_plan_completion_log_dedup_normalizes_trailing_slash(self) -> None:
        """v2.8.2: 'docs/plans/foo-plan' and 'docs/plans/foo-plan/' refer to
        the same plan. The hook strips trailing slash before dedup so a
        prompt with slash followed by a prompt without slash (or vice-versa)
        produces exactly 1 entry, not 2 — the empirical user-simulation
        bug shape."""
        project_root = Path(self.tmpdir.name) / "fake-project"
        plan_dir = project_root / "docs" / "plans" / "2026-05-07-banner-plan"
        plan_dir.mkdir(parents=True)

        # Round 1: prompt has TRAILING SLASH on plan path.
        self.state.write_text(json.dumps({
            "active": True, "iteration": 5, "max_iterations": 0,
            "completion_promise": "EXECUTION_COMPLETE",
            "prompt": "Execute the plan at docs/plans/2026-05-07-banner-plan/.",
            "skill_name": "executing-plans",
        }))
        self._write_transcript("done\n<promise>EXECUTION_COMPLETE</promise>")
        run_bash(
            f'loop_phase {shlex.quote(str(self.state))} {shlex.quote(str(self.transcript))}',
            cwd=str(project_root),
        )

        # Round 2: prompt WITHOUT trailing slash, same plan.
        self.state.write_text(json.dumps({
            "active": True, "iteration": 9, "max_iterations": 0,
            "completion_promise": "EXECUTION_COMPLETE",
            "prompt": "Execute the plan at docs/plans/2026-05-07-banner-plan.",
            "skill_name": "executing-plans",
        }))
        self._write_transcript("done\n<promise>EXECUTION_COMPLETE</promise>")
        run_bash(
            f'loop_phase {shlex.quote(str(self.state))} {shlex.quote(str(self.transcript))}',
            cwd=str(project_root),
        )

        log_file = project_root / "docs" / "retros" / "plans-completed.jsonl"
        lines = log_file.read_text().strip().split("\n")
        self.assertEqual(len(lines), 1, msg=f"trailing-slash dedup failed: {lines}")
        # Stored value MUST be the no-slash form (canonical).
        entry = json.loads(lines[0])
        self.assertEqual(entry["plan"], "docs/plans/2026-05-07-banner-plan")

    def test_plan_completion_log_repo_root_uses_git_toplevel(self) -> None:
        """v2.8.2: when cwd is inside a git work tree, repo_root is the
        git toplevel — even when the loop fires from a deeper subdir.
        Pre-v2.8.2 used $PWD blindly which broke for nested invocations
        (Claude cd'd into a subfolder mid-session)."""
        project_root = Path(self.tmpdir.name) / "fake-project"
        plan_dir = project_root / "docs" / "plans" / "2026-05-07-banner-plan"
        plan_dir.mkdir(parents=True)
        (plan_dir / "_index.md").write_text("# plan\n")
        make_git_repo(project_root)
        commit(project_root, "init", {"_baseline.txt": "x\n"})

        # Run loop_phase from a NESTED subdir, not project_root itself.
        nested = plan_dir  # project_root/docs/plans/2026-05-07-banner-plan
        self.state.write_text(json.dumps({
            "active": True, "iteration": 5, "max_iterations": 0,
            "completion_promise": "EXECUTION_COMPLETE",
            "prompt": "Execute the plan at docs/plans/2026-05-07-banner-plan.",
            "skill_name": "executing-plans",
        }))
        self._write_transcript("done\n<promise>EXECUTION_COMPLETE</promise>")
        result = run_bash(
            f'loop_phase {shlex.quote(str(self.state))} {shlex.quote(str(self.transcript))}',
            cwd=str(nested),
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)

        # Log lands in <repo_root>/docs/retros, NOT <nested>/docs/retros.
        log_file = project_root / "docs" / "retros" / "plans-completed.jsonl"
        self.assertTrue(log_file.exists(),
                        msg="log must land at repo toplevel, not at the nested cwd")
        entry = json.loads(log_file.read_text().strip().split("\n")[0])
        # repo_root field carries the absolute toplevel for audit.
        self.assertEqual(Path(entry["repo_root"]).resolve(), project_root.resolve())
        # plan stays repo-relative.
        self.assertEqual(entry["plan"], "docs/plans/2026-05-07-banner-plan")

    def test_plan_completion_log_repo_root_falls_back_to_pwd_outside_git(self) -> None:
        """v2.8.2: when cwd is not inside a git work tree, repo_root falls
        back to $PWD so the canonical event still lands. Sandboxed plan
        dirs and tarball-extracted projects must keep working."""
        project_root = Path(self.tmpdir.name) / "non-git-project"
        plan_dir = project_root / "docs" / "plans" / "2026-05-07-banner-plan"
        plan_dir.mkdir(parents=True)
        # Deliberately no `git init` — repo_root must fall back to PWD.

        self.state.write_text(json.dumps({
            "active": True, "iteration": 5, "max_iterations": 0,
            "completion_promise": "EXECUTION_COMPLETE",
            "prompt": "Execute the plan at docs/plans/2026-05-07-banner-plan.",
            "skill_name": "executing-plans",
        }))
        self._write_transcript("done\n<promise>EXECUTION_COMPLETE</promise>")
        result = run_bash(
            f'loop_phase {shlex.quote(str(self.state))} {shlex.quote(str(self.transcript))}',
            cwd=str(project_root),
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)

        log_file = project_root / "docs" / "retros" / "plans-completed.jsonl"
        entry = json.loads(log_file.read_text().strip().split("\n")[0])
        self.assertEqual(Path(entry["repo_root"]).resolve(), project_root.resolve())
        # completion_commit is empty when not in a git repo.
        self.assertEqual(entry["completion_commit"], "")

    def test_plan_completion_log_dedup_survives_corrupt_existing_line(self) -> None:
        """v2.8.2: dedup uses jq with try/catch — a single corrupt jsonl
        line doesn't disable the dedup gate or crash the hook. Defensive
        against external tools / manual edits that wrote a malformed row."""
        project_root = Path(self.tmpdir.name) / "fake-project"
        plan_dir = project_root / "docs" / "plans" / "2026-05-07-banner-plan"
        plan_dir.mkdir(parents=True)
        retros_dir = project_root / "docs" / "retros"
        retros_dir.mkdir(parents=True)
        # Pre-seed jsonl with corrupt + valid entries. The valid entry's
        # plan field MATCHES what the hook is about to write.
        (retros_dir / "plans-completed.jsonl").write_text(
            "this is not json\n"
            '{"event":"plan_completed","plan":"docs/plans/2026-05-07-banner-plan","timestamp":"2026-05-01T00:00:00Z"}\n'
        )

        self.state.write_text(json.dumps({
            "active": True, "iteration": 5, "max_iterations": 0,
            "completion_promise": "EXECUTION_COMPLETE",
            "prompt": "Execute the plan at docs/plans/2026-05-07-banner-plan.",
            "skill_name": "executing-plans",
        }))
        self._write_transcript("done\n<promise>EXECUTION_COMPLETE</promise>")
        result = run_bash(
            f'loop_phase {shlex.quote(str(self.state))} {shlex.quote(str(self.transcript))}',
            cwd=str(project_root),
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)

        # Dedup must trigger — the file still has 2 lines (corrupt + the
        # pre-existing valid match), no third line appended.
        lines = (retros_dir / "plans-completed.jsonl").read_text().strip().split("\n")
        self.assertEqual(len(lines), 2,
                         msg=f"dedup must not bypass on corrupt prior line: {lines}")

    def test_executing_plans_without_plan_path_in_prompt_skips_log(self) -> None:
        """Defensive: if for any reason state.prompt does not contain a
        recognizable `docs/plans/<topic>-plan` path, the log helper returns
        without writing rather than emitting a malformed entry. Promise
        completion must continue to clear state regardless."""
        project_root = Path(self.tmpdir.name) / "fake-project"
        project_root.mkdir()

        self.state.write_text(json.dumps({
            "active": True,
            "iteration": 3,
            "max_iterations": 0,
            "completion_promise": "EXECUTION_COMPLETE",
            "prompt": "execute everything",  # no plan path embedded
            "skill_name": "executing-plans",
        }))
        self._write_transcript("done\n<promise>EXECUTION_COMPLETE</promise>")

        result = run_bash(
            f'loop_phase {shlex.quote(str(self.state))} {shlex.quote(str(self.transcript))}',
            cwd=str(project_root),
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        log_file = project_root / "docs" / "retros" / "plans-completed.jsonl"
        self.assertFalse(log_file.exists())
        # State still cleared even though logging skipped.
        state = json.loads(self.state.read_text())
        self.assertNotIn("active", state)


class LoopStallDetectionTests(unittest.TestCase):
    """Tests for the loop_phase stall detector — three consecutive identical
    (or empty) last_output payloads force-clear the loop and emit a
    systemMessage. Empirically observed lockup: writing-plans batch-completes
    Phase 2 in iter 1, then iter 2..N produce near-identical 'Continue' echoes
    that never close with `<promise>...</promise>` and burn the full
    max_iterations budget. The detector caps that to 3-after-baseline."""

    def setUp(self) -> None:
        self.tmpdir = tempfile.TemporaryDirectory()
        self.state = Path(self.tmpdir.name) / "state.json"
        self.transcript = Path(self.tmpdir.name) / "transcript.jsonl"

    def tearDown(self) -> None:
        self.tmpdir.cleanup()

    def _write_transcript(self, last_text: str) -> None:
        line = {
            "role": "assistant",
            "message": {"content": [{"type": "text", "text": last_text}]},
        }
        self.transcript.write_text(json.dumps(line, separators=(",", ":")) + "\n")

    def _call_loop_phase(self) -> subprocess.CompletedProcess:
        """Invoke loop_phase once. Uses a fall-through sentinel so callers
        can distinguish 'emitted block + exit' from 'cleared + return 0'."""
        return run_bash(
            f"loop_phase {shlex.quote(str(self.state))} {shlex.quote(str(self.transcript))}\n"
            'echo "FELL_THROUGH"'
        )

    def test_stall_detector_clears_after_three_identical_outputs(self) -> None:
        """Baseline + 3 identical repeats triggers force-clear on the 4th call."""
        self.state.write_text(json.dumps({
            "active": True,
            "iteration": 5,
            "max_iterations": 50,
            "completion_promise": "DONE",
            "prompt": "Build the thing",
            "skill_name": "writing-plans",
        }))
        self._write_transcript("Continuing the plan work.")

        # Call 1: establishes baseline hash. stall_count stays at 0.
        r1 = self._call_loop_phase()
        self.assertEqual(r1.returncode, 0, msg=r1.stderr)
        self.assertNotIn("FELL_THROUGH", r1.stdout)
        self.assertEqual(json.loads(r1.stdout)["decision"], "block")
        state = json.loads(self.state.read_text())
        self.assertEqual(state["stall_count"], 0)
        self.assertNotEqual(state["last_output_hash"], "")

        # Calls 2 and 3: same output → stall_count climbs to 2, still emits block.
        for expected in (1, 2):
            r = self._call_loop_phase()
            self.assertEqual(r.returncode, 0, msg=r.stderr)
            self.assertEqual(json.loads(r.stdout)["decision"], "block")
            self.assertEqual(json.loads(self.state.read_text())["stall_count"], expected)

        # Call 4: stall_count hits 3 → force-clear + systemMessage, no block.
        r4 = self._call_loop_phase()
        self.assertEqual(r4.returncode, 0, msg=r4.stderr)
        # Force-clear path uses exit 0, so the fall-through sentinel must not appear.
        self.assertNotIn("FELL_THROUGH", r4.stdout)
        payload = json.loads(r4.stdout)
        self.assertTrue(payload.get("continue"))
        self.assertIn("force-cleared", payload["systemMessage"])
        self.assertIn("stalled", payload["systemMessage"])
        self.assertIn("Stalled 3 iterations", r4.stderr)
        # Loop fields cleared (incl. the new stall_count / last_output_hash).
        state = json.loads(self.state.read_text())
        for field in ("active", "iteration", "completion_promise", "prompt",
                      "stall_count", "last_output_hash"):
            self.assertNotIn(field, state, msg=f"{field} not cleared on force-clear")

    def test_stall_count_resets_on_new_output(self) -> None:
        """A near-threshold stall that recovers (different last_output) must
        zero the counter — otherwise the next-iter identical re-output would
        trip force-clear on a healthy loop."""
        self.state.write_text(json.dumps({
            "active": True,
            "iteration": 3,
            "max_iterations": 50,
            "completion_promise": "DONE",
            "prompt": "Build",
            "skill_name": "writing-plans",
            "stall_count": 2,
            "last_output_hash": "deadbeefdeadbeefdeadbeefdeadbeefdeadbeef",
        }))
        self._write_transcript("Fresh new progress message.")

        result = run_bash(
            f"loop_phase {shlex.quote(str(self.state))} {shlex.quote(str(self.transcript))}"
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        payload = json.loads(result.stdout)
        self.assertEqual(payload["decision"], "block")  # Not force-cleared.
        state = json.loads(self.state.read_text())
        self.assertEqual(state["stall_count"], 0)
        self.assertNotEqual(state["last_output_hash"], "deadbeefdeadbeefdeadbeefdeadbeefdeadbeef")

    def test_promise_match_clears_stall_fields_too(self) -> None:
        """Normal completion (promise detected) must wipe stall_count and
        last_output_hash alongside the other loop fields — a follow-up loop
        starting in the same session must not inherit a near-threshold counter."""
        self.state.write_text(json.dumps({
            "active": True,
            "iteration": 3,
            "max_iterations": 0,
            "completion_promise": "DONE",
            "prompt": "Build the thing",
            "skill_name": "writing-plans",
            "stall_count": 2,
            "last_output_hash": "abc123",
        }))
        self._write_transcript("All done.\n<promise>DONE</promise>")
        result = run_bash(
            f"loop_phase {shlex.quote(str(self.state))} {shlex.quote(str(self.transcript))}\n"
            'echo "FELL_THROUGH"'
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertIn("FELL_THROUGH", result.stdout)
        state = json.loads(self.state.read_text())
        self.assertNotIn("stall_count", state)
        self.assertNotIn("last_output_hash", state)

    def test_skill_name_branch_emits_phase_pointer_hint(self) -> None:
        """Fix A' — when skill_name is set the re-injection header carries a
        'Re-check SKILL.md for the current phase' hint so Claude resumes from
        the next incomplete phase instead of bare 'Continue' (which lost phase
        position once SKILL.md was compacted out of working context)."""
        self.state.write_text(json.dumps({
            "active": True,
            "iteration": 4,
            "max_iterations": 50,
            "completion_promise": "PLAN_COMPLETE",
            "prompt": "Write a plan for X",
            "skill_name": "writing-plans",
        }))
        self._write_transcript("Working on phase 2 still.")
        result = run_bash(
            f"loop_phase {shlex.quote(str(self.state))} {shlex.quote(str(self.transcript))}"
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        payload = json.loads(result.stdout)
        self.assertEqual(payload["decision"], "block")
        self.assertIn("Continue superpowers:writing-plans", payload["reason"])
        self.assertIn("Re-check SKILL.md", payload["reason"])
        self.assertIn("resume from the next incomplete phase", payload["reason"])
        # The LOOP COMPLETION REQUIRED footer (separate from the Fix A' line)
        # still carries the actual promise tag.
        self.assertIn("PLAN_COMPLETE", payload["reason"])


class ExtractLastAssistantTextTests(unittest.TestCase):
    """Tests for extract_last_assistant_text — the parser that drives whether
    loop_phase detects the completion promise. A regression here breaks the
    Superpower Loop's exit detection silently."""

    def setUp(self) -> None:
        self.tmpdir = tempfile.TemporaryDirectory()
        self.transcript = Path(self.tmpdir.name) / "transcript.jsonl"

    def tearDown(self) -> None:
        self.tmpdir.cleanup()

    def _run_extract(self, max_lines: int = 100) -> subprocess.CompletedProcess:
        return run_bash(
            f'extract_last_assistant_text {shlex.quote(str(self.transcript))} {max_lines}'
        )

    def test_returns_empty_for_missing_transcript(self) -> None:
        """No file → empty output, no crash."""
        result = self._run_extract()
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertEqual(result.stdout.strip(), "")

    def test_returns_text_for_single_assistant_message(self) -> None:
        line = {
            "role": "assistant",
            "message": {"content": [{"type": "text", "text": "hello world"}]},
        }
        self.transcript.write_text(json.dumps(line, separators=(",", ":")) + "\n")
        result = self._run_extract()
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertIn("hello world", result.stdout)

    def test_returns_last_text_when_multiple_assistant_messages(self) -> None:
        lines = [
            {"role": "assistant",
             "message": {"content": [{"type": "text", "text": "first"}]}},
            {"role": "user",
             "message": {"content": [{"type": "text", "text": "interlude"}]}},
            {"role": "assistant",
             "message": {"content": [{"type": "text", "text": "second"}]}},
        ]
        self.transcript.write_text(
            "\n".join(json.dumps(x, separators=(",", ":")) for x in lines) + "\n"
        )
        result = self._run_extract()
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        # Latest assistant message wins.
        self.assertIn("second", result.stdout)
        # User message must not leak in.
        self.assertNotIn("interlude", result.stdout)

    def test_extracts_text_block_among_mixed_content_types(self) -> None:
        """Assistant content arrays can contain tool_use blocks alongside text.
        The extractor must isolate the text block."""
        line = {
            "role": "assistant",
            "message": {
                "content": [
                    {"type": "tool_use", "name": "Bash", "input": {"cmd": "ls"}},
                    {"type": "text", "text": "<promise>DONE</promise>"},
                ]
            },
        }
        self.transcript.write_text(json.dumps(line, separators=(",", ":")) + "\n")
        result = self._run_extract()
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        # The text block is extracted; the tool_use block is ignored.
        self.assertIn("<promise>DONE</promise>", result.stdout)
        self.assertNotIn("Bash", result.stdout)

    def test_promise_in_extracted_text_is_detected_by_extract_promise_text(self) -> None:
        """End-to-end shape check: a transcript carrying a final <promise> tag
        flows through extract_last_assistant_text → extract_promise_text and
        yields the promise content. This is the exact pipeline loop_phase
        depends on; a regression breaks loop completion."""
        line = {
            "role": "assistant",
            "message": {
                "content": [{"type": "text",
                             "text": "Verified all checks.\n<promise>EXECUTION_COMPLETE</promise>"}]
            },
        }
        self.transcript.write_text(json.dumps(line, separators=(",", ":")) + "\n")
        result = run_bash(
            f'last=$(extract_last_assistant_text {shlex.quote(str(self.transcript))} 100); '
            f'extract_promise_text "$last"'
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertEqual(result.stdout.strip(), "EXECUTION_COMPLETE")


class EditsSinceLastSpawnHookTests(unittest.TestCase):
    """Tests for the hook pair that drives stuck detection:
    track-changes.sh increments .edits_since_last_spawn on every
    Edit/Write/MultiEdit; track-spawns.sh resets it on every Agent
    PostToolUse. The previous modified_files-growth signal had the
    wrong sign (it grew during the bug it tried to catch); this pair
    measures the precise anti-pattern executing-plans Phase 3 step 2
    forbids."""

    def setUp(self) -> None:
        self.tmpdir = tempfile.TemporaryDirectory()
        # Hooks resolve the state directory from $HOME/.claude/projects/<key>/
        # where <key> is $PWD with '/' → '-'. We override $HOME to isolate
        # state files between test runs and from the user's real session.
        self.fake_home = Path(self.tmpdir.name) / "home"
        self.fake_home.mkdir()
        self.cwd = Path(self.tmpdir.name) / "project"
        self.cwd.mkdir()
        project_key = str(self.cwd).replace("/", "-")
        self.state_dir = self.fake_home / ".claude" / "projects" / project_key
        self.state_dir.mkdir(parents=True)
        self.session_id = "test-session-123"
        self.state_file = self.state_dir / f"{self.session_id}.superpowers.json"

    def tearDown(self) -> None:
        self.tmpdir.cleanup()

    def _run_hook(self, hook_path: Path, hook_input: dict) -> subprocess.CompletedProcess:
        """Run a hook with $HOME pointed at the fake home dir so state_dir()
        resolves to our isolated location."""
        env = {
            **os.environ,
            "HOME": str(self.fake_home),
            "PWD": str(self.cwd),
        }
        return subprocess.run(
            ["bash", str(hook_path)],
            input=json.dumps(hook_input),
            text=True,
            capture_output=True,
            env=env,
            cwd=str(self.cwd),
        )

    def test_track_changes_creates_state_with_counter_at_one(self) -> None:
        """First Edit/Write in a fresh session: hook creates the state stub
        with edits_since_last_spawn=1. This is the path that runs when
        track-changes.sh fires before task-start.sh has had a chance to
        seed the file (e.g. an @mention that suppressed the user_prompt)."""
        result = self._run_hook(TRACK_CHANGES, {
            "session_id": self.session_id,
            "tool_input": {"file_path": "/abs/path/foo.py"},
        })
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertTrue(self.state_file.exists())
        state = json.loads(self.state_file.read_text())
        self.assertEqual(state["edits_since_last_spawn"], 1)
        self.assertIn("/abs/path/foo.py", state["modified_files"])

    def test_track_changes_increments_counter_on_each_call(self) -> None:
        """Each Edit/Write/MultiEdit invocation increments the counter by 1
        regardless of how many file paths the call touched. The counter
        measures tool-call count (= main-agent edit operations), not
        file-path count, because the bug pattern is "agent makes many
        edit calls without ever calling Agent" — one MultiEdit touching
        five files is one operation, not five."""
        # Seed state with counter=2 so we can observe a clean increment.
        self.state_file.write_text(json.dumps({
            "session_id": self.session_id,
            "modified_files": ["a.py", "b.py"],
            "edits_since_last_spawn": 2,
        }))

        # MultiEdit-style hook input: nested edits[].file_path.
        result = self._run_hook(TRACK_CHANGES, {
            "session_id": self.session_id,
            "tool_input": {
                "edits": [
                    {"file_path": "/abs/c.py"},
                    {"file_path": "/abs/d.py"},
                    {"file_path": "/abs/e.py"},
                ],
            },
        })
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        state = json.loads(self.state_file.read_text())
        # +1 per tool call, not +3 per file.
        self.assertEqual(state["edits_since_last_spawn"], 3)
        # All files still recorded in modified_files (dedup with prior).
        for f in ("a.py", "b.py", "/abs/c.py", "/abs/d.py", "/abs/e.py"):
            self.assertIn(f, state["modified_files"])

    def test_track_spawns_resets_counter_to_zero(self) -> None:
        """Agent tool PostToolUse zeroes edits_since_last_spawn. Counter
        increments from sub-agent tool calls during the spawn (those
        Edit/Write hooks fire in the main session too) get discarded
        cleanly along with the main-agent edits that preceded the spawn.
        Net semantic: 'edits the main agent has made since the last
        sub-agent returned'."""
        self.state_file.write_text(json.dumps({
            "session_id": self.session_id,
            "edits_since_last_spawn": 17,  # was high
        }))

        result = self._run_hook(TRACK_SPAWNS, {
            "session_id": self.session_id,
            "tool_name": "Agent",
            "tool_input": {"description": "Run batch 1"},
        })
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        state = json.loads(self.state_file.read_text())
        self.assertEqual(state["edits_since_last_spawn"], 0)

    def test_track_spawns_initializes_counter_when_state_lacks_it(self) -> None:
        """Backward compat: a state file from before this hook existed
        has no edits_since_last_spawn. track-spawns.sh must set it via
        `// 0` default rather than crash on the missing key."""
        self.state_file.write_text(json.dumps({
            "session_id": self.session_id,
            "task": "old session",
        }))

        result = self._run_hook(TRACK_SPAWNS, {
            "session_id": self.session_id,
            "tool_name": "Agent",
        })
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        state = json.loads(self.state_file.read_text())
        self.assertEqual(state["edits_since_last_spawn"], 0)
        # Other fields preserved.
        self.assertEqual(state["task"], "old session")

    def test_track_spawns_no_state_file_is_a_noop(self) -> None:
        """No state file means no active task tracking and no
        stuck-detection consumer; the hook exits 0 without creating
        anything. Avoids the surprise of an Agent tool call in an
        unrelated session creating spurious state files."""
        # state_file intentionally not created.
        result = self._run_hook(TRACK_SPAWNS, {
            "session_id": self.session_id,
            "tool_name": "Agent",
        })
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertFalse(self.state_file.exists())

    def test_full_cycle_edits_then_spawn_then_edits(self) -> None:
        """End-to-end: 3 Edits → counter=3, then Agent → counter=0, then
        2 more Edits → counter=2. This mirrors the real flow during a
        well-behaved batch (main agent writes contract + handoff state,
        spawns coordinator, then on next batch starts with contract +
        handoff state again from a clean counter)."""
        # Three pre-spawn edits.
        for path in ("/abs/contract.md", "/abs/handoff.md", "/abs/_index.md"):
            self._run_hook(TRACK_CHANGES, {
                "session_id": self.session_id,
                "tool_input": {"file_path": path},
            })
        state = json.loads(self.state_file.read_text())
        self.assertEqual(state["edits_since_last_spawn"], 3)

        # Spawn resets counter.
        self._run_hook(TRACK_SPAWNS, {
            "session_id": self.session_id,
            "tool_name": "Agent",
        })
        state = json.loads(self.state_file.read_text())
        self.assertEqual(state["edits_since_last_spawn"], 0)

        # Two post-spawn edits (next batch's contract + handoff).
        for path in ("/abs/contract2.md", "/abs/handoff2.md"):
            self._run_hook(TRACK_CHANGES, {
                "session_id": self.session_id,
                "tool_input": {"file_path": path},
            })
        state = json.loads(self.state_file.read_text())
        self.assertEqual(state["edits_since_last_spawn"], 2)


if __name__ == "__main__":
    unittest.main()
