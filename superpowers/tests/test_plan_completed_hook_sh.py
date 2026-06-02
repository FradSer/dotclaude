"""Tests for hooks/plan-completed.sh — the minimal Stop hook that restores
the mechanical plans-completed.jsonl write.

Detection is STATE-BASED (no model-utterance dependency): the hook writes a
plan_completed row when a plan's on-disk artifacts show it is complete and
committed — every batch handed off (handoff-summary count >= batch count) and
a git commit touching the handoff-state.md modified-files set. The model can
stay completely silent. These tests pin that contract: complete+committed
plans are logged once, incomplete or uncommitted plans are not, and unrelated
Stops are inert.
"""
from __future__ import annotations

import json
import os
import subprocess
import tempfile
import time
import unittest
from pathlib import Path

from conftest import commit, make_git_repo

SUPERPOWERS_DIR = Path(__file__).resolve().parents[1]
HOOK = SUPERPOWERS_DIR / "hooks" / "plan-completed.sh"


def _handoff(task_ids: list[str], files: list[str]) -> str:
    tasks = "\n".join(f"- {t}" for t in task_ids)
    mods = "\n".join(f"- `{f}`" for f in files)
    return f"# Handoff State\n\n## Completed Task IDs\n\n{tasks}\n\n## Modified Files (cumulative)\n\n{mods}\n"


class PlanCompletedHookTests(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.root = Path(self._tmp.name)
        make_git_repo(self.root)

    def tearDown(self) -> None:
        self._tmp.cleanup()

    def _make_plan(
        self,
        name: str,
        *,
        batches: int,
        summaries: int,
        files: list[str],
        tasks: list[str],
    ) -> Path:
        plan = self.root / "docs" / "plans" / name
        plan.mkdir(parents=True)
        plan.joinpath("handoff-state.md").write_text(_handoff(tasks, files))
        for n in range(1, batches + 1):
            plan.joinpath(f"sprint-contract-batch-{n}.md").write_text(f"batch {n}")
        for n in range(1, summaries + 1):
            plan.joinpath(f"handoff-summary-{n}.md").write_text(f"summary {n}")
        return plan

    def _run(self) -> subprocess.CompletedProcess:
        return subprocess.run(
            ["bash", str(HOOK)],
            input="{}",
            capture_output=True,
            text=True,
            cwd=str(self.root),
            env={"PATH": os.environ["PATH"], "CLAUDE_PROJECT_DIR": str(self.root)},
        )

    def _log(self) -> list[dict]:
        f = self.root / "docs" / "retros" / "plans-completed.jsonl"
        if not f.exists():
            return []
        return [json.loads(ln) for ln in f.read_text().splitlines() if ln.strip()]

    # --- behavior ---------------------------------------------------------

    def test_complete_committed_plan_is_logged(self) -> None:
        files = ["src/auth.py", "tests/test_auth.py"]
        self._make_plan(
            "2026-06-02-example-plan",
            batches=2,
            summaries=2,
            files=files,
            tasks=["001 (Batch 1, PASS)", "002 (Batch 1, PASS)", "003 (Batch 2, PASS)"],
        )
        sha = commit(self.root, "feat: done", {f: "x" for f in files})
        r = self._run()
        self.assertEqual(r.returncode, 0, msg=r.stderr)
        rows = self._log()
        self.assertEqual(len(rows), 1)
        row = rows[0]
        self.assertEqual(row["event"], "plan_completed")
        self.assertEqual(row["plan"], "docs/plans/2026-06-02-example-plan")
        self.assertEqual(row["batch_count"], 2)
        self.assertEqual(row["task_count"], 3)
        self.assertEqual(row["completion_commit"], sha[:7])
        self.assertEqual(row["completion_modified_files"], files)
        self.assertEqual(row["repo_root"], str(self.root))
        self.assertIn("timestamp", row)

    def test_incomplete_plan_not_logged(self) -> None:
        # 2 batches but only 1 handoff summary -> C2 fails.
        files = ["src/a.py"]
        self._make_plan("2026-06-02-wip-plan", batches=2, summaries=1, files=files, tasks=["001"])
        commit(self.root, "feat: partial", {files[0]: "x"})
        r = self._run()
        self.assertEqual(r.returncode, 0, msg=r.stderr)
        self.assertEqual(self._log(), [])

    def test_uncommitted_plan_not_logged(self) -> None:
        # All batches handed off, but the modified files were never committed
        # -> C3 (a commit touching them) fails.
        self._make_plan(
            "2026-06-02-uncommitted-plan",
            batches=1,
            summaries=1,
            files=["src/never_committed.py"],
            tasks=["001"],
        )
        commit(self.root, "chore: unrelated", {"README.md": "x"})
        r = self._run()
        self.assertEqual(r.returncode, 0, msg=r.stderr)
        self.assertEqual(self._log(), [])

    def test_idempotent_grep_guard_blocks_duplicate(self) -> None:
        files = ["src/a.py"]
        plan = self._make_plan("2026-06-02-dup-plan", batches=1, summaries=1, files=files, tasks=["001"])
        commit(self.root, "feat: done", {files[0]: "x"})
        self._run()
        # Force the cheap mtime gate to pass on the second run so the C4 grep
        # guard (not just the gate) is what prevents the duplicate.
        time.sleep(0.01)
        plan.joinpath("handoff-state.md").write_text(plan.joinpath("handoff-state.md").read_text())
        self._run()
        self.assertEqual(len(self._log()), 1)

    def test_only_complete_plan_among_many_is_logged(self) -> None:
        done_files = ["src/done.py"]
        self._make_plan("2026-06-01-done-plan", batches=1, summaries=1, files=done_files, tasks=["001"])
        self._make_plan("2026-06-02-wip-plan", batches=3, summaries=1, files=["src/wip.py"], tasks=["001"])
        commit(self.root, "feat: done", {done_files[0]: "x"})
        r = self._run()
        self.assertEqual(r.returncode, 0, msg=r.stderr)
        rows = self._log()
        self.assertEqual([row["plan"] for row in rows], ["docs/plans/2026-06-01-done-plan"])

    def test_no_plans_dir_exits_clean(self) -> None:
        r = self._run()
        self.assertEqual(r.returncode, 0, msg=r.stderr)
        self.assertEqual(self._log(), [])


if __name__ == "__main__":
    unittest.main()
