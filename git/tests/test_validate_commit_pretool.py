"""Tests for hooks/validate-commit-pretool.sh — the git plugin's PreToolUse guard.

The hook denies raw `git commit` (always) and standalone `git add` on Bash tool
calls, redirecting to the /git:commit skill. Two documented exceptions pass:
  1. `git add <path> && git-agent commit ...` chained in ONE command — scoped
     staging for `git-agent commit --no-stage` (superpowers design/plan commits).
  2. The GIT_SKILL_FALLBACK=1 marker — the /git:commit and /git:commit-and-push
     skills' manual fallback when the git-agent binary is unavailable. The deny
     messages must never reveal this marker.

A guard script's worst failure mode is a silent no-op that stays green — every
deny case here asserts the actual deny JSON, not just "no crash".
"""
from __future__ import annotations

import json
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

GIT_PLUGIN_DIR = Path(__file__).resolve().parents[1]
HOOK = GIT_PLUGIN_DIR / "hooks" / "validate-commit-pretool.sh"

ESCAPE_MARKER = "GIT_SKILL_FALLBACK=1"


def run_hook(stdin_text: str, env: dict | None = None) -> subprocess.CompletedProcess:
    return subprocess.run(
        ["bash", str(HOOK)],
        input=stdin_text,
        capture_output=True,
        text=True,
        env=env,
    )


def payload(command: str) -> str:
    return json.dumps({"tool_name": "Bash", "tool_input": {"command": command}})


class DenyPathTests(unittest.TestCase):
    """Commands that must be denied with the PreToolUse deny JSON."""

    def assert_denied(self, command: str) -> dict:
        result = run_hook(payload(command))
        self.assertEqual(result.returncode, 0, f"hook must exit 0 on deny: {command}")
        out = json.loads(result.stdout)
        decision = out["hookSpecificOutput"]["permissionDecision"]
        self.assertEqual(decision, "deny", f"expected deny for: {command}")
        # The escape marker must never leak through a deny reason
        self.assertNotIn(ESCAPE_MARKER, out["hookSpecificOutput"]["permissionDecisionReason"])
        return out

    def test_raw_commit(self) -> None:
        self.assert_denied("git commit -m foo")

    def test_standalone_add(self) -> None:
        self.assert_denied("git add docs/plans/2026-07-02-x-design/")

    def test_chained_add_then_raw_commit(self) -> None:
        self.assert_denied("git add . && git commit -m foo")

    def test_raw_commit_even_with_git_agent_later(self) -> None:
        self.assert_denied("git commit -m x && git-agent commit")

    def test_multiple_spaces_between_tokens(self) -> None:
        self.assert_denied("git  add .")

    def test_add_after_cd_prefix(self) -> None:
        self.assert_denied("cd repo && git add file.txt")

    def test_add_with_git_agent_only_as_argument(self) -> None:
        # `git-agent commit` as an echo argument is not a chained invocation
        self.assert_denied("git add -A && echo git-agent commit")

    def test_add_with_git_agent_only_in_comment(self) -> None:
        self.assert_denied("git add -A # git-agent commit later")

    def test_commit_with_separator_suffix(self) -> None:
        for command in ("git commit&&true", "git commit|cat", "git commit;"):
            self.assert_denied(command)

    def test_escape_marker_requires_word_boundary(self) -> None:
        self.assert_denied(f"FOO_{ESCAPE_MARKER} git commit -m x")


class AllowPathTests(unittest.TestCase):
    """Commands that must pass through silently (empty stdout, exit 0)."""

    def assert_allowed(self, command: str) -> None:
        result = run_hook(payload(command))
        self.assertEqual(result.returncode, 0, f"hook must exit 0 on allow: {command}")
        self.assertEqual(result.stdout, "", f"expected empty stdout (allow) for: {command}")

    def test_chained_add_with_git_agent_commit(self) -> None:
        self.assert_allowed(
            'git add docs/plans/2026-07-02-x-design/ && git-agent commit --no-stage --intent "add design"'
        )

    def test_chained_add_with_git_agent_commit_multiline(self) -> None:
        self.assert_allowed(
            'git add docs/plans/2026-07-02-x-design/ && \\\n  git-agent commit --no-stage --intent "add design"'
        )

    def test_plain_git_agent_commit(self) -> None:
        self.assert_allowed("git-agent commit --intent foo")

    def test_readonly_git_commands(self) -> None:
        for command in ("git log -1", "git status", "git push", "git config user.name"):
            self.assert_allowed(command)

    def test_unrelated_command(self) -> None:
        self.assert_allowed("ls -la")

    def test_substrings_do_not_match(self) -> None:
        for command in ("git address-book", "git commitish", "npm run add-thing"):
            self.assert_allowed(command)

    def test_escape_hatch_add_and_commit(self) -> None:
        self.assert_allowed(f'{ESCAPE_MARKER} git add -A && git commit -m "fix: x"')

    def test_escape_hatch_commit_only(self) -> None:
        self.assert_allowed(f'{ESCAPE_MARKER} git commit -m "fix: x"')

    def test_escape_hatch_with_semicolon_suffix(self) -> None:
        self.assert_allowed(f"export {ESCAPE_MARKER}; git commit -m x")

    def test_quoted_mentions_do_not_deny(self) -> None:
        for command in (
            'git-agent commit --intent "document git commit hook behavior"',
            'echo "git commit is denied by the hook"',
        ):
            self.assert_allowed(command)


class NoJqFallbackTests(unittest.TestCase):
    """The grep/sed extraction path (jq absent) must keep core verdicts intact."""

    @classmethod
    def setUpClass(cls) -> None:
        cls._tmp = tempfile.TemporaryDirectory()
        shim = Path(cls._tmp.name)
        for name in ("bash", "cat", "grep", "sed", "head"):
            src = shutil.which(name)
            assert src, f"{name} not on PATH"
            (shim / name).symlink_to(src)
        cls.env = {"PATH": str(shim)}

    @classmethod
    def tearDownClass(cls) -> None:
        cls._tmp.cleanup()

    def test_raw_commit_denied_without_jq(self) -> None:
        result = run_hook(payload("git commit -m foo"), env=self.env)
        out = json.loads(result.stdout)
        self.assertEqual(out["hookSpecificOutput"]["permissionDecision"], "deny")

    def test_unrelated_allowed_without_jq(self) -> None:
        result = run_hook(payload("ls -la"), env=self.env)
        self.assertEqual(result.returncode, 0)
        self.assertEqual(result.stdout, "")

    def test_chained_git_agent_allowed_without_jq(self) -> None:
        result = run_hook(payload("git add docs/ && git-agent commit --no-stage --intent x"), env=self.env)
        self.assertEqual(result.returncode, 0)
        self.assertEqual(result.stdout, "")


class FailOpenTests(unittest.TestCase):
    """Parse failures must allow (never block legitimate work on bad input)."""

    def assert_fail_open(self, stdin_text: str) -> None:
        result = run_hook(stdin_text)
        self.assertEqual(result.returncode, 0)
        self.assertEqual(result.stdout, "")

    def test_empty_stdin(self) -> None:
        self.assert_fail_open("")

    def test_malformed_json(self) -> None:
        self.assert_fail_open("{not json")

    def test_missing_command_field(self) -> None:
        self.assert_fail_open(json.dumps({"tool_name": "Bash", "tool_input": {}}))


if __name__ == "__main__":
    unittest.main()
