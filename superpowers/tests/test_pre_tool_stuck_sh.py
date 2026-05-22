"""Tests for hooks/pre-tool-stuck.sh — PreToolUse hook that blocks
main-agent Edit/Write/MultiEdit calls inside an executing-plans loop
once the edits-since-last-spawn counter exceeds the direct-edit
allow-list budget (5).

The hook is the front-stop pair of the Stop-hook STUCK banner emitted
from lib/loop.sh:494 — same threshold (edits>5), same skill gate
(executing-plans), same iter gate (>=2), but it fires *before* the
breach lands on disk instead of one turn after.

Contract pinned here:

1. Only intercepts when tool_name ∈ {Edit, Write, MultiEdit}. Bash /
   Read / Glob / Grep are passed through.
2. Requires skill_name=="executing-plans" AND iteration>=2 AND
   edits_since_last_spawn>5. Any other combination → allow.
3. Read-only on state file — no lock acquisition, no writes. State
   reads see the last committed value (writers use tmp+mv atomic
   replace).
4. Best-effort degradation: missing state file, missing session_id,
   malformed JSON, missing jq → silent allow (exit 0, no decision).
5. Block emits a single-line JSON object with
   hookSpecificOutput.permissionDecision="deny" and a
   permissionDecisionReason, exit code 0 — the Claude Code PreToolUse
   protocol ({"decision":"block"} only blocks Stop/SubagentStop).
"""
from __future__ import annotations

import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

SUPERPOWERS_DIR = Path(__file__).resolve().parents[1]
HOOK = SUPERPOWERS_DIR / "hooks" / "pre-tool-stuck.sh"


def _sandbox(tmp: Path, session_id: str, state: dict | None) -> tuple[Path, dict[str, str]]:
    """Build a hermetic project + state-file env. Returns (project, env).

    macOS quirk: $TMPDIR points under /var/folders/ which is a symlink to
    /private/var/folders/. Bash's PWD after chdir resolves through the
    symlink, so the state_dir() key (PWD with / → -) must be built from
    the realpath, not the str() form. Mismatching keys → empty
    find_state_file → silent allow → false negative in block tests."""
    project = (tmp / "project").resolve()
    project.mkdir()
    fake_home = (tmp / "home").resolve()
    (fake_home / ".claude" / "projects").mkdir(parents=True)

    project_key = str(project).replace("/", "-")
    state_dir = fake_home / ".claude" / "projects" / project_key
    state_dir.mkdir(parents=True)

    if state is not None:
        full_state = {"session_id": session_id, **state}
        (state_dir / f"{session_id}.superpowers.json").write_text(json.dumps(full_state))

    env = {k: v for k, v in os.environ.items() if not k.startswith("CLAUDE_")}
    env["HOME"] = str(fake_home)
    env["CLAUDE_PROJECT_DIR"] = str(project)
    return project, env


def _invoke(project: Path, env: dict[str, str], hook_input: dict) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["/bin/bash", str(HOOK)],
        input=json.dumps(hook_input),
        capture_output=True,
        text=True,
        cwd=str(project),
        env=env,
    )


def _assert_allow(testcase: unittest.TestCase, result: subprocess.CompletedProcess[str]) -> None:
    testcase.assertEqual(result.returncode, 0, msg=result.stderr)
    testcase.assertEqual(result.stdout.strip(), "", msg=f"unexpected decision: {result.stdout!r}")


def _assert_block(testcase: unittest.TestCase, result: subprocess.CompletedProcess[str]) -> dict:
    testcase.assertEqual(result.returncode, 0, msg=result.stderr)
    line = result.stdout.strip()
    testcase.assertTrue(line, msg="expected deny JSON, got empty stdout")
    payload = json.loads(line)
    hso = payload["hookSpecificOutput"]
    testcase.assertEqual(hso["hookEventName"], "PreToolUse")
    testcase.assertEqual(hso["permissionDecision"], "deny")
    testcase.assertIn("permissionDecisionReason", hso)
    return hso


class AllowPathTests(unittest.TestCase):
    """The hook MUST default to allow whenever any precondition fails."""

    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.tmp_path = Path(self.tmp.name)

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def test_no_state_file_allows(self) -> None:
        project, env = _sandbox(self.tmp_path, "sid-1", state=None)
        result = _invoke(project, env, {"session_id": "sid-1", "tool_name": "Edit"})
        _assert_allow(self, result)

    def test_skill_not_executing_plans_allows(self) -> None:
        project, env = _sandbox(
            self.tmp_path, "sid-2",
            {"skill_name": "brainstorming", "iteration": 5, "edits_since_last_spawn": 99},
        )
        result = _invoke(project, env, {"session_id": "sid-2", "tool_name": "Edit"})
        _assert_allow(self, result)

    def test_iter_one_allows_even_with_high_edits(self) -> None:
        """Iter=1 is the legitimate first batch — direct edits to handoff
        and sprint contract are within the allow-list."""
        project, env = _sandbox(
            self.tmp_path, "sid-3",
            {"skill_name": "executing-plans", "iteration": 1, "edits_since_last_spawn": 99},
        )
        result = _invoke(project, env, {"session_id": "sid-3", "tool_name": "Edit"})
        _assert_allow(self, result)

    def test_edits_at_budget_allows(self) -> None:
        """Exactly 5 edits — the budget — still allows. Block fires
        only when EDITS > 5 (strict gt)."""
        project, env = _sandbox(
            self.tmp_path, "sid-4",
            {"skill_name": "executing-plans", "iteration": 2, "edits_since_last_spawn": 5},
        )
        result = _invoke(project, env, {"session_id": "sid-4", "tool_name": "Edit"})
        _assert_allow(self, result)

    def test_non_edit_tool_allows_at_breach_threshold(self) -> None:
        """The hook only intercepts Edit/Write/MultiEdit even when the
        breach condition would otherwise fire."""
        project, env = _sandbox(
            self.tmp_path, "sid-5",
            {"skill_name": "executing-plans", "iteration": 2, "edits_since_last_spawn": 99},
        )
        for tool in ("Bash", "Read", "Glob", "Grep", "Agent", "Task"):
            with self.subTest(tool=tool):
                result = _invoke(project, env, {"session_id": "sid-5", "tool_name": tool})
                _assert_allow(self, result)

    def test_missing_session_id_allows(self) -> None:
        project, env = _sandbox(self.tmp_path, "sid-6", {
            "skill_name": "executing-plans", "iteration": 2, "edits_since_last_spawn": 99
        })
        result = _invoke(project, env, {"tool_name": "Edit"})
        _assert_allow(self, result)

    def test_missing_tool_name_allows(self) -> None:
        project, env = _sandbox(self.tmp_path, "sid-7", {
            "skill_name": "executing-plans", "iteration": 2, "edits_since_last_spawn": 99
        })
        result = _invoke(project, env, {"session_id": "sid-7"})
        _assert_allow(self, result)


class BlockPathTests(unittest.TestCase):
    """The hook MUST emit a permissionDecision=deny object when every
    precondition fires simultaneously."""

    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.tmp_path = Path(self.tmp.name)

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def test_blocks_edit_when_over_budget(self) -> None:
        project, env = _sandbox(
            self.tmp_path, "sid-block-edit",
            {"skill_name": "executing-plans", "iteration": 2, "edits_since_last_spawn": 6},
        )
        result = _invoke(project, env, {"session_id": "sid-block-edit", "tool_name": "Edit"})
        decision = _assert_block(self, result)
        self.assertIn("executing-plans Phase 3 HARD RULE", decision["permissionDecisionReason"])
        self.assertIn("6 direct edits", decision["permissionDecisionReason"])

    def test_blocks_write_when_over_budget(self) -> None:
        project, env = _sandbox(
            self.tmp_path, "sid-block-write",
            {"skill_name": "executing-plans", "iteration": 3, "edits_since_last_spawn": 12},
        )
        result = _invoke(project, env, {"session_id": "sid-block-write", "tool_name": "Write"})
        decision = _assert_block(self, result)
        self.assertIn("12 direct edits", decision["permissionDecisionReason"])

    def test_blocks_multiedit_when_over_budget(self) -> None:
        project, env = _sandbox(
            self.tmp_path, "sid-block-multi",
            {"skill_name": "executing-plans", "iteration": 2, "edits_since_last_spawn": 6},
        )
        result = _invoke(project, env, {"session_id": "sid-block-multi", "tool_name": "MultiEdit"})
        _assert_block(self, result)

    def test_block_reason_points_to_recovery(self) -> None:
        """The reason MUST name the recovery path (Agent spawn + sprint
        contract) so the user sees a concrete next action, not just
        'you broke the contract'."""
        project, env = _sandbox(
            self.tmp_path, "sid-block-recovery",
            {"skill_name": "executing-plans", "iteration": 2, "edits_since_last_spawn": 7},
        )
        result = _invoke(project, env, {"session_id": "sid-block-recovery", "tool_name": "Edit"})
        decision = _assert_block(self, result)
        self.assertIn("Agent tool", decision["permissionDecisionReason"])
        self.assertIn("sprint contract", decision["permissionDecisionReason"])


class DegradationTests(unittest.TestCase):
    """Hook bugs MUST NEVER block the user's session. Missing deps,
    malformed input, corrupted state file → silent allow."""

    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.tmp_path = Path(self.tmp.name)

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def test_corrupted_state_file_allows(self) -> None:
        project, env = _sandbox(self.tmp_path, "sid-corrupt", state={})
        # Overwrite with non-JSON garbage.
        project_key = str(project).replace("/", "-")
        state_file = Path(env["HOME"]) / ".claude" / "projects" / project_key / "sid-corrupt.superpowers.json"
        state_file.write_text("not json {{")
        result = _invoke(project, env, {"session_id": "sid-corrupt", "tool_name": "Edit"})
        _assert_allow(self, result)

    def test_malformed_hook_input_allows(self) -> None:
        project, env = _sandbox(self.tmp_path, "sid-malformed", state=None)
        result = subprocess.run(
            ["/bin/bash", str(HOOK)],
            input="this is not json {{",
            capture_output=True,
            text=True,
            cwd=str(project),
            env=env,
        )
        _assert_allow(self, result)


if __name__ == "__main__":
    unittest.main()
