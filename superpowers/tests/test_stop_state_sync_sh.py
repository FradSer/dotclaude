"""Tests for hooks/stop-state-sync.sh — the single superpowers Stop hook.

The hook is the state-based writer for every durable docs/retros/*.jsonl side-
effect the skills otherwise emit as a Claude-instructed step. Detection is
STATE-BASED (no model-utterance dependency); every row is deduped so the normal
in-skill path (which writes richer rows first) makes the hook a no-op.

Two responsibilities, both pinned here:
  1. plans-completed.jsonl — a plan_completed row when a plan's on-disk
     artifacts show it is complete and committed.
  2. evolution-log.jsonl backfill — (2a) a retrospective_run watermark when a
     retro-*.md report has no row referencing it, and (2b) item_added /
     item_removed deltas diffed from consecutive checklist versions when no log
     row carries that version.
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
HOOK = SUPERPOWERS_DIR / "hooks" / "stop-state-sync.sh"


def _jsonl_line(obj: dict) -> str:
    """Compact one-line JSON matching jq -nc / jsonl-emit (required for dedup anchors)."""
    return json.dumps(obj, separators=(",", ":")) + "\n"


def _handoff(task_ids: list[str], files: list[str]) -> str:
    tasks = "\n".join(f"- {t}" for t in task_ids)
    mods = "\n".join(f"- `{f}`" for f in files)
    return f"# Handoff State\n\n## Completed Task IDs\n\n{tasks}\n\n## Modified Files (cumulative)\n\n{mods}\n"


class StopStateSyncPlanCompletionTests(unittest.TestCase):
    """Responsibility 1: plans-completed.jsonl."""

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
        self._make_plan("2026-06-02-stale-handoff-plan", batches=1, summaries=1, files=files_b, tasks=["001"])
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


class StopStateSyncEvolutionLogBackfillTests(unittest.TestCase):
    """Responsibility 2: evolution-log.jsonl backfill (2a watermark, 2b deltas).

    These exercise the state-based safety net independent of any plan: only
    docs/retros/ artifacts (reports + checklist versions) drive the writes.
    repo_root resolves from CLAUDE_PROJECT_DIR, so no git repo is required.
    """

    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.root = Path(self._tmp.name)
        self.retros = self.root / "docs" / "retros"
        self.checklists = self.retros / "checklists"

    def tearDown(self) -> None:
        self._tmp.cleanup()

    def _run(self) -> subprocess.CompletedProcess:
        return subprocess.run(
            ["bash", str(HOOK)],
            input="{}",
            capture_output=True,
            text=True,
            cwd=str(self.root),
            env={"PATH": os.environ["PATH"], "CLAUDE_PROJECT_DIR": str(self.root)},
        )

    def _evolog(self) -> list[dict]:
        f = self.retros / "evolution-log.jsonl"
        if not f.exists():
            return []
        return [json.loads(ln) for ln in f.read_text().splitlines() if ln.strip()]

    def _report(self, name: str) -> None:
        self.retros.mkdir(parents=True, exist_ok=True)
        (self.retros / name).write_text("# Retro\n")

    def _checklist(self, mode: str, version: int, item_ids: list[str]) -> None:
        self.checklists.mkdir(parents=True, exist_ok=True)
        body = "## Checklist Items\n\n" + "\n".join(
            f"### {iid} -- description for {iid}" for iid in item_ids
        )
        (self.checklists / f"{mode}-v{version}.md").write_text(body + "\n")

    def _write_evolog(self, rows: list[dict]) -> None:
        self.retros.mkdir(parents=True, exist_ok=True)
        (self.retros / "evolution-log.jsonl").write_text("".join(_jsonl_line(r) for r in rows))

    # --- 2a: retrospective_run watermark ---------------------------------
    def test_watermark_backfilled_when_report_unlogged(self) -> None:
        self._report("retro-2026-06-08-example.md")
        r = self._run()
        self.assertEqual(r.returncode, 0, msg=r.stderr)
        runs = [e for e in self._evolog() if e.get("event") == "retrospective_run"]
        self.assertEqual(len(runs), 1)
        self.assertEqual(runs[0]["report"], "docs/retros/retro-2026-06-08-example.md")
        self.assertEqual(runs[0]["provenance"], "hook_backfill")
        self.assertEqual(runs[0]["plans_analyzed"], [])
        self.assertIn("timestamp", runs[0])

    def test_watermark_not_backfilled_when_run_already_logged(self) -> None:
        report = "docs/retros/retro-2026-06-08-example.md"
        self._report("retro-2026-06-08-example.md")
        self._write_evolog(
            [{"event": "retrospective_run", "report": report, "proposals_approved": 2}]
        )
        r = self._run()
        self.assertEqual(r.returncode, 0, msg=r.stderr)
        runs = [e for e in self._evolog() if e.get("event") == "retrospective_run"]
        self.assertEqual(len(runs), 1)
        self.assertNotIn("provenance", runs[0])  # untouched rich row

    def test_watermark_backfill_idempotent(self) -> None:
        self._report("retro-2026-06-08-example.md")
        self._run()
        self._run()
        runs = [e for e in self._evolog() if e.get("event") == "retrospective_run"]
        self.assertEqual(len(runs), 1)

    def test_watermark_backfilled_when_only_item_rows_reference_report(self) -> None:
        """Closure dropped but item_* rows written: the basename appears in the log,
        yet no retrospective_run row exists — the watermark must still be backfilled."""
        report = "docs/retros/retro-2026-06-08-example.md"
        self._report("retro-2026-06-08-example.md")
        self._write_evolog(
            [
                {
                    "event": "item_added",
                    "item_id": "CODE-X",
                    "checklist_version": "code-v2.md",
                    "retrospective_report": report,
                }
            ]
        )
        r = self._run()
        self.assertEqual(r.returncode, 0, msg=r.stderr)
        runs = [e for e in self._evolog() if e.get("event") == "retrospective_run"]
        self.assertEqual(len(runs), 1)
        self.assertEqual(runs[0]["provenance"], "hook_backfill")

    # --- 2b: item_added / item_removed from version diff -----------------
    def test_item_deltas_backfilled_from_version_diff(self) -> None:
        self._checklist("code", 1, ["CODE-A", "CODE-B"])
        self._checklist("code", 2, ["CODE-A", "CODE-C"])
        r = self._run()
        self.assertEqual(r.returncode, 0, msg=r.stderr)
        items = {(e["event"], e["item_id"]) for e in self._evolog() if e.get("event", "").startswith("item_")}
        self.assertIn(("item_added", "CODE-C"), items)
        self.assertIn(("item_removed", "CODE-B"), items)
        self.assertNotIn(("item_added", "CODE-A"), items)  # unchanged item not logged
        for e in self._evolog():
            if e.get("event", "").startswith("item_"):
                self.assertEqual(e["provenance"], "hook_backfill")
                self.assertEqual(e["checklist_version"], "code-v2.md")

    def test_item_id_colon_form_parsed(self) -> None:
        self.checklists.mkdir(parents=True, exist_ok=True)
        (self.checklists / "design-v1.md").write_text("### JUST-01 -- keep\n")
        (self.checklists / "design-v2.md").write_text("### JUST-01 -- keep\n### NEW-01: added with colon\n")
        r = self._run()
        self.assertEqual(r.returncode, 0, msg=r.stderr)
        added = [e["item_id"] for e in self._evolog() if e.get("event") == "item_added"]
        self.assertIn("NEW-01", added)

    def test_item_backfill_skipped_when_version_already_logged(self) -> None:
        self._checklist("code", 1, ["CODE-A", "CODE-B"])
        self._checklist("code", 2, ["CODE-A", "CODE-C"])
        self._write_evolog(
            [
                {
                    "event": "item_added",
                    "item_id": "CODE-C",
                    "checklist_version": "code-v2.md",
                    "provenance": "retrospective",
                    "rationale": "real",
                }
            ]
        )
        r = self._run()
        self.assertEqual(r.returncode, 0, msg=r.stderr)
        backfilled = [e for e in self._evolog() if e.get("provenance") == "hook_backfill"]
        self.assertEqual(backfilled, [])

    def test_no_item_backfill_without_predecessor_version(self) -> None:
        self._checklist("code", 1, ["CODE-A", "CODE-B"])
        r = self._run()
        self.assertEqual(r.returncode, 0, msg=r.stderr)
        items = [e for e in self._evolog() if e.get("event", "").startswith("item_")]
        self.assertEqual(items, [])

    def test_item_backfill_idempotent(self) -> None:
        self._checklist("code", 1, ["CODE-A", "CODE-B"])
        self._checklist("code", 2, ["CODE-A", "CODE-C"])
        self._run()
        self._run()
        items = [e for e in self._evolog() if e.get("event", "").startswith("item_")]
        self.assertEqual(len(items), 2)  # one add + one remove, not doubled

    def test_no_retros_dir_exits_clean(self) -> None:
        r = self._run()
        self.assertEqual(r.returncode, 0, msg=r.stderr)
        self.assertEqual(self._evolog(), [])


if __name__ == "__main__":
    unittest.main()
