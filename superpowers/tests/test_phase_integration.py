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
STOP_HOOK = SUPERPOWERS / "hooks" / "stop-hook.sh"


def run_bash(script: str, **kwargs) -> subprocess.CompletedProcess:
    """Run a bash script with utils.sh + loop.sh + vet.sh sourced.

    Uses `set -euo pipefail` to mirror stop-hook.sh's runtime environment.
    Tests that ran under `set +e` previously masked a CRITICAL regression
    where vet.sh's unguarded bypass call silently aborted vet_phase under
    errexit — the test harness must reproduce production semantics.
    """
    full = (
        "set -euo pipefail\n"
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
        # The helper's contract is `exit 0` for workflow skills, `return 1`
        # for non-workflow. Callers MUST guard with `|| true` (or handle the
        # nonzero in an `if`) under `set -e` — vet.sh:145 and loop.sh:158
        # both do this. The test reproduces the production calling pattern.
        result = run_bash(
            f'bypass_vet_for_workflow_skill {shlex.quote(str(self.state))} || true\n'
            'echo "REACHED_AFTER_BYPASS"'
        )
        # Non-workflow skill: function returns 1, script reaches the next line.
        self.assertIn("REACHED_AFTER_BYPASS", result.stdout)
        # need_vet must NOT be cleared (vet still has a job to do).
        state = json.loads(self.state.read_text())
        self.assertTrue(state.get("need_vet"))

    def test_bypass_clears_need_vet_for_all_workflow_skills(self) -> None:
        """is_workflow_skill enumerates 4 workflow skills. The first-round
        synthesis only tested brainstorming explicitly. This locks in the
        full set so a future is_workflow_skill change can't silently drop
        coverage."""
        for skill in ("brainstorming", "writing-plans", "executing-plans", "retrospective"):
            with self.subTest(skill=skill):
                self.state.write_text(json.dumps({"skill_name": skill, "need_vet": True}))
                result = run_bash(
                    f'bypass_vet_for_workflow_skill {shlex.quote(str(self.state))} || true\n'
                    'echo "REACHED_AFTER_BYPASS"'
                )
                self.assertEqual(result.returncode, 0, msg=result.stderr)
                # Helper exits 0 from inside, never reaches post-call line.
                self.assertNotIn("REACHED_AFTER_BYPASS", result.stdout)
                state = json.loads(self.state.read_text())
                self.assertNotIn("need_vet", state)


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


class StopHookEndToEndTests(unittest.TestCase):
    """Run stop-hook.sh as a real subprocess (not sourced) so the test
    environment exactly mirrors production: `set -euo pipefail`, real
    process exit codes, real `find_state_file` lookup. This is the only
    place the CRITICAL `vet.sh:145` regression would have been caught
    before shipping."""

    def setUp(self) -> None:
        self.tmpdir = tempfile.TemporaryDirectory()
        # Mirror state-dir layout: ~/.claude/projects/<key>/<session>.superpowers.json
        # We override PWD so state_dir() lands inside our tmpdir.
        # NOTE: must `.resolve()` on macOS — tmpdir is /var/folders/... but
        # subprocess cwd resolves to /private/var/folders/... and bash's
        # state_dir() reads $PWD, so the project key would otherwise mismatch.
        self.fake_pwd = (Path(self.tmpdir.name) / "fake-cwd").resolve()
        self.fake_pwd.mkdir()
        self.fake_pwd = self.fake_pwd.resolve()
        project_key = str(self.fake_pwd).replace("/", "-")
        self.state_dir = Path.home() / ".claude" / "projects" / project_key
        self.state_dir.mkdir(parents=True, exist_ok=True)
        self.session_id = "test-session-stop-hook"
        self.state = self.state_dir / f"{self.session_id}.superpowers.json"
        self.transcript = Path(self.tmpdir.name) / "transcript.jsonl"
        self.transcript.write_text("")

    def tearDown(self) -> None:
        for p in self.state_dir.glob("*"):
            p.unlink()
        try:
            self.state_dir.rmdir()
        except OSError:
            pass
        self.tmpdir.cleanup()

    def _run_stop_hook(self, hook_input: dict) -> subprocess.CompletedProcess:
        return subprocess.run(
            ["bash", str(STOP_HOOK)],
            input=json.dumps(hook_input),
            text=True,
            capture_output=True,
            cwd=str(self.fake_pwd),
        )

    def test_need_vet_with_non_workflow_skill_emits_block_under_set_e(self) -> None:
        """REGRESSION: under stop-hook's `set -euo pipefail`, the bare
        `bypass_vet_for_workflow_skill` call in vet.sh aborted vet_phase
        before the verified-tag matcher ran — silently breaking /need-vet.
        This test reproduces the exact production path."""
        self.state.write_text(json.dumps({
            "session_id": self.session_id,
            "skill_name": "need-vet",
            "need_vet": True,
            "task": "verify the deploy",
            "modified_files": ["deploy.yaml"],
        }))
        result = self._run_stop_hook({
            "session_id": self.session_id,
            "transcript_path": str(self.transcript),
            "last_assistant_message": "I think it's done.",
        })
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        # Block JSON must appear on stdout — the verification gate fired.
        self.assertTrue(result.stdout.strip(), msg="expected block JSON, got empty stdout")
        payload = json.loads(result.stdout)
        self.assertEqual(payload["decision"], "block")
        self.assertIn("Verification Checkpoint", payload["reason"])

    def test_need_vet_with_workflow_skill_bypasses_cleanly(self) -> None:
        """Workflow skill path under `set -e` — must exit cleanly, clear
        need_vet, and emit no block JSON."""
        self.state.write_text(json.dumps({
            "session_id": self.session_id,
            "skill_name": "executing-plans",
            "need_vet": True,
            "task": "run plan",
        }))
        result = self._run_stop_hook({
            "session_id": self.session_id,
            "transcript_path": str(self.transcript),
            "last_assistant_message": "Plan executed.",
        })
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertEqual(result.stdout.strip(), "")
        state = json.loads(self.state.read_text())
        self.assertNotIn("need_vet", state)


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

    def test_task_start_bails_soft_when_jq_missing(self) -> None:
        result = self._run_hook(self.HOOKS[1], {
            "session_id": "x",
            "prompt": "test prompt",
        })
        self.assertEqual(result.returncode, 0,
                         msg=f"task-start crashed without jq: {result.stderr}")

    def test_track_changes_bails_soft_when_jq_missing(self) -> None:
        result = self._run_hook(self.HOOKS[2], {
            "session_id": "x",
            "tool_input": {"file_path": "/tmp/some-file.py"},
        })
        self.assertEqual(result.returncode, 0,
                         msg=f"track-changes crashed without jq: {result.stderr}")

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
    iteration logic invoked by stop-hook.sh Phase 1.

    Covers the production paths that prior synthesis rounds left untested:
    - active loop + promise match (falls through to vet)
    - active loop + no match (emits block JSON to continue)
    - corrupted state fields (clears loop, falls through)
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
        """Inactive loop: loop_phase returns 0 — caller falls through to vet."""
        self.state.write_text(json.dumps({"task": "ship it"}))
        self._write_transcript("done")
        result = run_bash(
            f'loop_phase {shlex.quote(str(self.state))} {shlex.quote(str(self.transcript))}\n'
            'echo "FELL_THROUGH"'
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        # Caller continues to next line — vet would run after.
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
        """Active loop + matching promise (non-workflow skill): clear loop fields,
        fall through to vet."""
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

    def test_promise_match_with_workflow_skill_exits_directly(self) -> None:
        """Active loop + matching promise + workflow skill: clear state AND exit 0
        from inside bypass_vet_for_workflow_skill — caller must NOT fall through."""
        self.state.write_text(json.dumps({
            "active": True,
            "iteration": 2,
            "max_iterations": 0,
            "completion_promise": "PLAN_COMPLETE",
            "prompt": "Make a plan",
            "skill_name": "writing-plans",
            "need_vet": True,
        }))
        self._write_transcript("Plan written.\n<promise>PLAN_COMPLETE</promise>")
        result = run_bash(
            f'loop_phase {shlex.quote(str(self.state))} {shlex.quote(str(self.transcript))}\n'
            'echo "FELL_THROUGH"'
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        # bypass_vet_for_workflow_skill exits 0 directly — no fallthrough.
        self.assertNotIn("FELL_THROUGH", result.stdout)
        state = json.loads(self.state.read_text())
        self.assertNotIn("active", state)
        self.assertNotIn("need_vet", state)

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

    def test_loop_reinject_block_extracted_from_skill_md(self) -> None:
        """When skill_name resolves to a SKILL.md carrying LOOP_REINJECT
        markers, the framed excerpt is appended to the block reason. Long
        loops drift away from the terminate conditions otherwise; this is the
        protocol-level (not business-aware) re-injection that fixes that."""
        self.state.write_text(json.dumps({
            "active": True,
            "iteration": 1,
            "max_iterations": 0,
            "completion_promise": "BRAINSTORMING_COMPLETE",
            "prompt": "Design the feature",
            "skill_name": "brainstorming",
        }))
        self._write_transcript("Working on Phase 2...")
        result = run_bash(
            f'loop_phase {shlex.quote(str(self.state))} {shlex.quote(str(self.transcript))}'
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        payload = json.loads(result.stdout)
        # The excerpt itself appears, but the marker delimiters do not — the
        # awk extractor strips the LOOP_REINJECT_BEGIN/END comment lines.
        self.assertIn("BRAINSTORMING_COMPLETE", payload["reason"])
        self.assertIn("Design folder committed to git", payload["reason"])
        self.assertNotIn("LOOP_REINJECT_BEGIN", payload["reason"])
        self.assertNotIn("LOOP_REINJECT_END", payload["reason"])

    def test_skill_name_emits_continue_header_and_preserves_prompt(self) -> None:
        """When skill_name is set, the re-injection header reads as a
        continuation phrase ("Continue superpowers:X — iter N/M") AND the
        original base_prompt is preserved on the next paragraph. This is the
        contract that replaced the previous "Use superpowers:X skill." short-
        circuit, which empirical audit showed Claude treating as a slash-
        command-style re-entry signal — every Stop walked SKILL.md from the
        top, wasting a turn per loop iteration. The continuation phrase plus
        the verbatim prompt (carrying phase-progression hints from
        setup-superpower-loop.sh) keeps the loop anchored to its current phase
        instead of restarting."""
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
        # Header is a continuation phrase, not a skill-trigger phrase.
        self.assertIn("Continue superpowers:writing-plans", reason)
        self.assertNotIn("Use superpowers:writing-plans skill", reason)
        # Iteration tag uses the next iteration (current+1) for orientation.
        self.assertIn("iter 2/100", reason)
        # Original prompt is preserved verbatim — phase hints survive.
        self.assertIn("docs/plans/feat-plan", reason)
        self.assertIn("Continue progressing through phases", reason)
        # systemMessage reads as continuation, not error.
        self.assertIn("Superpower Loop iter 2/100", payload["systemMessage"])
        self.assertIn("Continue writing-plans", payload["systemMessage"])

    def test_non_keyframe_iteration_skips_heavy_blocks(self) -> None:
        """Iterations that are not iteration 1 and not multiples of 5 are
        "lean" — the SKILL.md LOOP_REINJECT excerpt and the cumulative
        "Already produced" file list are omitted, leaving only the
        continuation header + base_prompt + LOOP COMPLETION REQUIRED tail.
        Saves ~1.5KB per Stop in long loops where the heavy blocks would
        otherwise be re-injected verbatim ~30 times in a 30-iteration run."""
        self.state.write_text(json.dumps({
            "active": True,
            "iteration": 2,  # next = 3 → non-keyframe (not 1, not %5==0)
            "max_iterations": 100,
            "completion_promise": "DONE",
            "prompt": "Execute the plan at docs/plans/feat-plan.",
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
        # Continuation header still present.
        self.assertIn("Continue superpowers:brainstorming", reason)
        # Heavy blocks omitted on non-keyframe iterations.
        self.assertNotIn("Design folder committed to git", reason,
                         msg="LOOP_REINJECT excerpt must not appear on non-keyframe iter")
        self.assertNotIn("Already produced this session", reason,
                         msg="modified_files list must not appear on non-keyframe iter")
        # Lean tail still includes the completion promise reminder — that's
        # always required regardless of iteration parity.
        self.assertIn("<promise>DONE</promise>", reason)

    def test_keyframe_iteration_includes_heavy_blocks(self) -> None:
        """Iteration 1 + every 5th iteration are "keyframes" that re-inject
        the full picture: SKILL.md LOOP_REINJECT excerpt + 20-deep
        modified_files snapshot. Acts as a periodic anchor for long loops
        without polluting every single iteration."""
        self.state.write_text(json.dumps({
            "active": True,
            "iteration": 4,  # next = 5 → keyframe (multiple of 5)
            "max_iterations": 100,
            "completion_promise": "BRAINSTORMING_COMPLETE",
            "prompt": "Design the feature.",
            "skill_name": "brainstorming",
            "modified_files": [
                "docs/plans/feat-design/_index.md",
            ],
        }))
        self._write_transcript("checkpoint")
        result = run_bash(
            f'loop_phase {shlex.quote(str(self.state))} {shlex.quote(str(self.transcript))}'
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        payload = json.loads(result.stdout)
        reason = payload["reason"]
        # Heavy blocks present on keyframe.
        self.assertIn("Design folder committed to git", reason)
        self.assertIn("Already produced this session", reason)
        self.assertIn("docs/plans/feat-design/_index.md", reason)

    def test_stuck_detection_emits_recovery_hint(self) -> None:
        """When modified_files count has not grown for 3 consecutive
        iterations (from iteration 5 onward), the loop emits a STUCK
        warning in both systemMessage and reason. This catches the
        empirical pattern from real executing-plans runs where the main
        agent stops repeatedly without spawning a sub-agent — words but
        no artifacts. The recovery hint points at Phase 3 step 2 (spawn
        coordinator) or the promise as the only legitimate exits."""
        # State carries a stuck_count of 2; this iteration brings it to 3
        # (iteration 7, files unchanged from previous_modified_count=2).
        self.state.write_text(json.dumps({
            "active": True,
            "iteration": 7,
            "max_iterations": 100,
            "completion_promise": "EXECUTION_COMPLETE",
            "prompt": "Execute the plan at docs/plans/feat-plan.",
            "skill_name": "executing-plans",
            "modified_files": ["docs/plans/feat-plan/handoff-state.md",
                               "docs/plans/feat-plan/sprint-contract-batch-1.md"],
            "previous_modified_count": 2,
            "stuck_count": 2,
        }))
        self._write_transcript("I will spawn the coordinator next iteration...")
        result = run_bash(
            f'loop_phase {shlex.quote(str(self.state))} {shlex.quote(str(self.transcript))}'
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        payload = json.loads(result.stdout)
        # systemMessage flags STUCK with the count.
        self.assertIn("STUCK", payload["systemMessage"])
        # reason carries the recovery instructions.
        self.assertIn("STUCK DETECTED", payload["reason"])
        self.assertIn("Phase 3 step 2", payload["reason"])
        self.assertIn("EXECUTION_COMPLETE", payload["reason"])
        # State persists the incremented stuck_count for the next iteration.
        state_after = json.loads(self.state.read_text())
        self.assertGreaterEqual(state_after["stuck_count"], 3)

    def test_stuck_count_resets_when_files_grow(self) -> None:
        """A growth in modified_files count resets stuck_count to 0 — a
        successful sub-agent invocation should clear the streak so the
        warning does not persist past the recovery."""
        self.state.write_text(json.dumps({
            "active": True,
            "iteration": 8,
            "max_iterations": 100,
            "completion_promise": "EXECUTION_COMPLETE",
            "prompt": "Execute the plan at docs/plans/feat-plan.",
            "skill_name": "executing-plans",
            "modified_files": ["a.py", "b.py", "c.py", "d.py", "e.py"],  # 5 now
            "previous_modified_count": 2,  # was 2 last iteration
            "stuck_count": 3,  # had been stuck
        }))
        self._write_transcript("Spawned coordinator, files updated.")
        result = run_bash(
            f'loop_phase {shlex.quote(str(self.state))} {shlex.quote(str(self.transcript))}'
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        payload = json.loads(result.stdout)
        # Recovery cleared — no STUCK markers.
        self.assertNotIn("STUCK", payload["systemMessage"])
        self.assertNotIn("STUCK DETECTED", payload["reason"])
        state_after = json.loads(self.state.read_text())
        self.assertEqual(state_after["stuck_count"], 0)
        self.assertEqual(state_after["previous_modified_count"], 5)

    def test_early_iterations_do_not_trigger_stuck(self) -> None:
        """Iterations 1-4 may legitimately have no file growth — Phase 1
        plan review and Phase 2 task creation (TaskCreate, not Edit/Write)
        produce no Edit/Write artifacts. Stuck detection only kicks in
        from iteration 5 onward to avoid false positives during setup."""
        self.state.write_text(json.dumps({
            "active": True,
            "iteration": 3,  # next = 4, still in setup window
            "max_iterations": 100,
            "completion_promise": "EXECUTION_COMPLETE",
            "prompt": "Execute the plan at docs/plans/feat-plan.",
            "skill_name": "executing-plans",
            "modified_files": [],
            "previous_modified_count": 0,
            "stuck_count": 0,
        }))
        self._write_transcript("Phase 1 in progress, no files yet.")
        result = run_bash(
            f'loop_phase {shlex.quote(str(self.state))} {shlex.quote(str(self.transcript))}'
        )
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        payload = json.loads(result.stdout)
        self.assertNotIn("STUCK", payload["systemMessage"])
        self.assertNotIn("STUCK DETECTED", payload["reason"])
        # stuck_count must not increment in the setup window.
        state_after = json.loads(self.state.read_text())
        self.assertEqual(state_after["stuck_count"], 0)

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
        # Workflow skill bypass exits before fallthrough.
        self.assertNotIn("FELL_THROUGH", result.stdout)

        log_file = project_root / "docs" / "retros" / "plans-completed.jsonl"
        self.assertTrue(
            log_file.exists(),
            f"plans-completed.jsonl missing at {log_file}",
        )
        lines = log_file.read_text().strip().split("\n")
        self.assertEqual(len(lines), 1)
        entry = json.loads(lines[0])
        self.assertEqual(entry["event"], "plan_completed")
        self.assertIn("2026-05-07-banner-plan", entry["plan"])
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


if __name__ == "__main__":
    unittest.main()
