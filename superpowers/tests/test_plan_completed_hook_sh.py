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


def _jsonl_line(obj: dict) -> str:
    """Compact one-line JSON matching jq -nc / jsonl-emit (required for dedup anchors)."""
    return json.dumps(obj, separators=(",", ":")) + "\n"


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
        files = ["src/a.py"]
        self._make_plan("2026-06-02-wip-plan", batches=2, summaries=1, files=files, tasks=["001"])
        commit(self.root, "feat: partial", {files[0]: "x"})
        r = self._run()
        self.assertEqual(r.returncode, 0, msg=r.stderr)
        self.assertEqual(self._log(), [])

    def test_uncommitted_plan_not_logged(self) -> None:
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

    def test_idempotent_dedup_blocks_duplicate(self) -> None:
        files = ["src/a.py"]
        self._make_plan("2026-06-02-dup-plan", batches=1, summaries=1, files=files, tasks=["001"])
        commit(self.root, "feat: done", {files[0]: "x"})
        self._run()
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

    def test_stale_handoff_still_logs_when_log_newer_than_handoff(self) -> None:
        """Plan B complete but unlogged while plans-completed.jsonl is newer than B's handoff — B must still log."""
        files_b = ["src/b.py"]
        files_a = ["src/a.py"]
        # Directory names must end with `-plan` (hook glob: docs/plans/*-plan/handoff-state.md).
        plan_b = self._make_plan("2026-06-02-stale-handoff-plan", batches=1, summaries=1, files=files_b, tasks=["001"])
        commit(self.root, "feat: b done", {files_b[0]: "x"})
        self._make_plan("2026-06-01-already-logged-plan", batches=1, summaries=1, files=files_a, tasks=["001"])
        sha_a = commit(self.root, "feat: a done", {files_a[0]: "x"})
        log_file = self.root / "docs" / "retros" / "plans-completed.jsonl"
        log_file.parent.mkdir(parents=True, exist_ok=True)
        log_file.write_text(
            _jsonl_line(
                {
                    "event": "plan_completed",
                    "plan": "docs/plans/2026-06-01-already-logged-plan",
                    "repo_root": str(self.root),
                    "task_count": 1,
                    "batch_count": 1,
                    "completion_commit": sha_a[:7],
                    "completion_modified_files": files_a,
                    "timestamp": "2026-06-01T00:00:00Z",
                }
            )
        )
        time.sleep(0.02)
        r = self._run()
        self.assertEqual(r.returncode, 0, msg=r.stderr)
        plans = [row["plan"] for row in self._log()]
        self.assertIn("docs/plans/2026-06-02-stale-handoff-plan", plans)
        self.assertEqual(plans.count("docs/plans/2026-06-01-already-logged-plan"), 1)

    def test_already_analyzed_plan_not_backfilled(self) -> None:
        name = "2026-05-01-old-plan"
        files = ["src/old.py"]
        self._make_plan(name, batches=1, summaries=1, files=files, tasks=["001"])
        commit(self.root, "feat: old done", {files[0]: "x"})
        evo = self.root / "docs" / "retros" / "evolution-log.jsonl"
        evo.parent.mkdir(parents=True, exist_ok=True)
        evo.write_text(
            _jsonl_line(
                {
                    "event": "retrospective_run",
                    "plans_analyzed": [f"docs/plans/{name}/"],
                    "report": "docs/retros/retro-old.md",
                }
            )
        )
        r = self._run()
        self.assertEqual(r.returncode, 0, msg=r.stderr)
        self.assertEqual(self._log(), [])

    def test_c4b_does_not_skip_unrelated_plan_with_similar_prefix(self) -> None:
        """docs/plans/foo-plan must not be blocked by retro on docs/plans/foo-plan-extra."""
        short = "2026-05-01-foo-plan"
        long = "2026-05-01-foo-plan-extra"
        files_short = ["src/short.py"]
        self._make_plan(short, batches=1, summaries=1, files=files_short, tasks=["001"])
        self._make_plan(long, batches=1, summaries=1, files=["src/long.py"], tasks=["001"])
        commit(self.root, "feat: short", {files_short[0]: "x"})
        evo = self.root / "docs" / "retros" / "evolution-log.jsonl"
        evo.parent.mkdir(parents=True, exist_ok=True)
        evo.write_text(
            _jsonl_line(
                {
                    "event": "retrospective_run",
                    "plans_analyzed": [f"docs/plans/{long}/"],
                    "report": "docs/retros/retro-long.md",
                }
            )
        )
        r = self._run()
        self.assertEqual(r.returncode, 0, msg=r.stderr)
        self.assertEqual([row["plan"] for row in self._log()], [f"docs/plans/{short}"])

    def test_archived_sprint_contract_not_counted_in_batch_total(self) -> None:
        files = ["src/x.py"]
        plan = self._make_plan("2026-06-02-archive-plan", batches=1, summaries=1, files=files, tasks=["001"])
        plan.joinpath("sprint-contract-batch-1.v1.md").write_text("archived")
        commit(self.root, "feat: done", {files[0]: "x"})
        r = self._run()
        self.assertEqual(r.returncode, 0, msg=r.stderr)
        self.assertEqual(self._log()[0]["batch_count"], 1)

    def test_no_plans_dir_exits_clean(self) -> None:
        r = self._run()
        self.assertEqual(r.returncode, 0, msg=r.stderr)
        self.assertEqual(self._log(), [])


if __name__ == "__main__":
    unittest.main()
