"""Tests for lib/post-plan-diff.sh — closes retrospective Phase 1's
post-plan-diff blind spot. Empirical motivation: user-simulation
2026-05-08, retrospective ran 16 minutes after plan completion and
disabled `recurring_failure_patterns` based on blank-injection signal
alone — the user's 5 refactor commits arrived 12–13h later.
"""
from __future__ import annotations

import json
import subprocess
import tempfile
import unittest
from pathlib import Path

from conftest import commit, make_git_repo

SUPERPOWERS_DIR = Path(__file__).resolve().parents[1]
POST_PLAN_DIFF = SUPERPOWERS_DIR / "lib" / "post-plan-diff.sh"


def run_executed(*args: str, cwd: Path | None = None) -> subprocess.CompletedProcess:
    """Invoke post-plan-diff.sh in executed mode."""
    return subprocess.run(
        ["bash", str(POST_PLAN_DIFF), *args],
        cwd=str(cwd) if cwd else None,
        capture_output=True,
        text=True,
    )


def run_sourced(body: str, cwd: Path | None = None) -> subprocess.CompletedProcess:
    """Source under `set -euo pipefail` and run body. Verifies sourcing
    does not perturb the caller's error-handling regime."""
    script = f"set -euo pipefail\nsource {POST_PLAN_DIFF}\n{body}\n"
    return subprocess.run(
        ["bash", "-c", script],
        cwd=str(cwd) if cwd else None,
        capture_output=True,
        text=True,
    )


class ClassifyCommitSubjectTests(unittest.TestCase):
    """Pure-function unit tests for the conventional-commit classifier."""

    def _classify(self, subject: str) -> str:
        result = run_executed("classify", subject)
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        return result.stdout.strip()

    def test_refactor_is_feedback(self) -> None:
        self.assertEqual(self._classify("refactor(usim): standardize disfluency handling"), "feedback")

    def test_fix_is_feedback(self) -> None:
        self.assertEqual(self._classify("fix: missing await on api call"), "feedback")

    def test_style_is_feedback(self) -> None:
        self.assertEqual(self._classify("style(ui): align indent with biome"), "feedback")

    def test_perf_is_feedback(self) -> None:
        """perf: joined feedback bucket — perf commits on plan files almost
        always mean superpowers wrote it slow and the user fixed it."""
        self.assertEqual(self._classify("perf(timeline): cache disfluency lookup"), "feedback")

    def test_feat_is_evolution(self) -> None:
        self.assertEqual(self._classify("feat(usim): add use_json_response_format flag"), "evolution")

    def test_chore_is_evolution(self) -> None:
        self.assertEqual(self._classify("chore(deps): bump pydantic to 2.5"), "evolution")

    def test_docs_is_evolution(self) -> None:
        self.assertEqual(self._classify("docs: add README architecture section"), "evolution")

    def test_test_is_evolution(self) -> None:
        """test: is evolution — adding tests is requirement growth, not
        superpowers feedback (executing-plans already wrote the test pairs)."""
        self.assertEqual(self._classify("test: add hypothesis property test"), "evolution")

    def test_breaking_change_marker_recognized(self) -> None:
        """Conventional `!` for breaking changes still classifies by type."""
        self.assertEqual(self._classify("refactor!: drop legacy adapter"), "feedback")
        self.assertEqual(self._classify("feat(api)!: rename endpoint"), "evolution")

    def test_no_conventional_prefix_is_unknown(self) -> None:
        self.assertEqual(self._classify("Initial commit"), "unknown")
        self.assertEqual(self._classify("WIP debug"), "unknown")
        self.assertEqual(self._classify("Merge branch 'main'"), "unknown")

    def test_uppercase_type_is_unknown(self) -> None:
        """Strict lowercase by conventional spec — uppercase is unknown."""
        self.assertEqual(self._classify("Refactor: capitalize wrong"), "unknown")

    def test_classify_via_sourced_function(self) -> None:
        """The classifier is callable as a sourced function, not just CLI."""
        result = run_sourced('classify_commit_subject "refactor: x"')
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertEqual(result.stdout.strip(), "feedback")


class PostPlanCommitsTests(unittest.TestCase):
    """Integration tests against a real git repo. Build a plan-completion
    baseline + post-plan history and assert the helper recovers the right
    commits with the right classifications."""

    def setUp(self) -> None:
        self.tmpdir = tempfile.TemporaryDirectory()
        self.root = Path(self.tmpdir.name)
        make_git_repo(self.root)

    def tearDown(self) -> None:
        self.tmpdir.cleanup()

    def test_lists_post_plan_commits_with_classifications(self) -> None:
        """Mirror the real user-simulation timeline: completion commit,
        then a mix of refactor/feat post-plan commits on plan files."""
        completion = commit(
            self.root,
            "feat: superpowers plan completion — initial implementation",
            {"src/runner.py": "def run(): pass\n", "src/distro.py": "WEIGHTS = {}\n"},
        )
        commit(self.root, "refactor(usim): extract distribution models",
               {"src/distro.py": "WEIGHTS = {'a': 1}\n"})
        commit(self.root, "feat(usim): add dialect support",
               {"src/dialect.py": "DIALECTS = []\n"})
        commit(self.root, "refactor(usim): standardize disfluency handling",
               {"src/runner.py": "def run(): return None\n"})

        result = run_executed("list", completion, "src/runner.py", "src/distro.py", "src/dialect.py", cwd=self.root)
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        entries = [json.loads(line) for line in result.stdout.strip().split("\n")]
        self.assertEqual(len(entries), 3)
        # Entries arrive newest-first (git log default).
        classes = [e["classification"] for e in entries]
        self.assertEqual(sorted(classes), ["evolution", "feedback", "feedback"])

    def test_summary_aggregates_correctly(self) -> None:
        completion = commit(self.root, "feat: baseline", {"a.py": "x = 1\n"})
        commit(self.root, "refactor: clean up", {"a.py": "x = 2\n"})
        commit(self.root, "fix: typo", {"a.py": "x = 3\n"})
        commit(self.root, "feat: new flag", {"a.py": "x = 4\n"})
        commit(self.root, "WIP no convention", {"a.py": "x = 5\n"})

        result = run_executed("summary", completion, "a.py", cwd=self.root)
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        summary = json.loads(result.stdout.strip())
        self.assertEqual(summary, {
            "total": 4,
            "feedback": 2,
            "evolution": 1,
            "unknown": 1,
        })

    def test_file_filter_excludes_unrelated_commits(self) -> None:
        """A post-plan commit on a file outside `completion_modified_files`
        is user evolution on unrelated code — must not pollute the diff."""
        completion = commit(self.root, "feat: baseline", {"plan_file.py": "x = 1\n"})
        commit(self.root, "refactor: on plan file", {"plan_file.py": "x = 2\n"})
        commit(self.root, "refactor: on UNRELATED file", {"unrelated.py": "y = 1\n"})

        # File filter restricts to plan_file.py — unrelated.py refactor must drop out.
        result = run_executed("list", completion, "plan_file.py", cwd=self.root)
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        entries = [json.loads(line) for line in result.stdout.strip().split("\n")]
        self.assertEqual(len(entries), 1)
        self.assertIn("on plan file", entries[0]["subject"])

    def test_empty_post_plan_window_returns_no_output(self) -> None:
        """No commits since plan completion → empty stdout, exit 0."""
        completion = commit(self.root, "feat: baseline", {"a.py": "1\n"})
        result = run_executed("list", completion, "a.py", cwd=self.root)
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertEqual(result.stdout.strip(), "")
        # Summary echoes structured zeros even on empty input.
        result = run_executed("summary", completion, "a.py", cwd=self.root)
        summary = json.loads(result.stdout.strip())
        self.assertEqual(summary, {"total": 0, "feedback": 0, "evolution": 0, "unknown": 0})

    def test_recovers_last_commit_without_trailing_newline(self) -> None:
        """Regression: the smoke run against user-simulation showed total=8
        when 9 commits existed because git log's last line lacked \\n and
        `read -r` exited the loop one record early. Fixed via
        `|| [[ -n "$sha" ]]` rescue clause."""
        completion = commit(self.root, "feat: baseline", {"a.py": "1\n"})
        # Three post-plan commits — last one must be counted.
        commit(self.root, "refactor: one", {"a.py": "2\n"})
        commit(self.root, "refactor: two", {"a.py": "3\n"})
        commit(self.root, "refactor: three", {"a.py": "4\n"})

        result = run_executed("summary", completion, "a.py", cwd=self.root)
        summary = json.loads(result.stdout.strip())
        self.assertEqual(summary["total"], 3)
        self.assertEqual(summary["feedback"], 3)


class DegradationTests(unittest.TestCase):
    """The helper must never block the caller — missing git / non-repo /
    bogus commit hash all silently produce empty output."""

    def setUp(self) -> None:
        self.tmpdir = tempfile.TemporaryDirectory()
        self.root = Path(self.tmpdir.name)

    def tearDown(self) -> None:
        self.tmpdir.cleanup()

    def test_non_repo_cwd_returns_empty(self) -> None:
        """No `.git` in cwd → empty output, exit 0."""
        result = run_executed("list", "abc123", "any.py", cwd=self.root)
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertEqual(result.stdout.strip(), "")

    def test_bogus_commit_returns_empty(self) -> None:
        """Commit hash that does not exist in repo → empty output, exit 0.
        retrospective Phase 1 step 8 expects this for force-pushed history."""
        make_git_repo(self.root)
        commit(self.root, "feat: baseline", {"a.py": "1\n"})
        result = run_executed("list", "deadbeefdeadbeef", "a.py", cwd=self.root)
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        # git log with bad commit prints to stderr but stdout stays empty.

    def test_empty_completion_commit_returns_empty(self) -> None:
        """Pre-v2.8.1 plan_completed entries lack completion_commit. The
        helper must short-circuit silently rather than crash."""
        result = run_executed("list", "", "a.py", cwd=self.root)
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertEqual(result.stdout.strip(), "")

    def test_sourcing_under_set_e_does_not_abort_caller(self) -> None:
        """Sourced + bogus commit + set -euo pipefail = caller still alive."""
        make_git_repo(self.root)
        commit(self.root, "feat: baseline", {"a.py": "1\n"})
        body = 'post_plan_commits "deadbeefdeadbeef" "a.py"\necho "still alive"'
        result = run_sourced(body, cwd=self.root)
        self.assertEqual(result.returncode, 0, msg=result.stderr)
        self.assertIn("still alive", result.stdout)


if __name__ == "__main__":
    unittest.main()
