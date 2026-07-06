"""Tests for lib/task-ledger.sh — the durable per-task completion ledger.

Unlike lib/jsonl-emit.sh (best-effort audit stream, silently no-ops on
missing jq), this ledger is a correctness-critical anti-redispatch guard:
missing jq is a hard failure (exit 2), not a silent skip, since a silent
skip here would defeat the whole point (a fresh coordinator would have no
record to check before re-dispatching a task).
"""
from __future__ import annotations

import json
import os
import subprocess
from pathlib import Path

SUPERPOWERS_DIR = Path(__file__).resolve().parents[1]
SCRIPT = SUPERPOWERS_DIR / "lib" / "task-ledger.sh"

BASH = "/bin/bash"


def _run(args, cwd=None, env=None):
    return subprocess.run(
        [BASH, str(SCRIPT), *args],
        capture_output=True, text=True, cwd=cwd, env=env,
    )


def test_append_writes_one_jsonl_line_with_expected_fields(tmp_path: Path):
    plan_dir = tmp_path / "plan"
    plan_dir.mkdir()
    r = _run(["append", str(plan_dir), "003", "2", "abc1234..def5678", "PASS"])
    assert r.returncode == 0, r.stderr
    ledger = plan_dir / "task-ledger.jsonl"
    assert ledger.exists()
    lines = ledger.read_text().splitlines()
    assert len(lines) == 1
    row = json.loads(lines[0])
    assert row["task_id"] == "003"
    assert row["batch"] == "2"
    assert row["commit_range"] == "abc1234..def5678"
    assert row["verdict"] == "PASS"
    assert "ts" in row and row["ts"]


def test_check_finds_pass_entry(tmp_path: Path):
    plan_dir = tmp_path / "plan"
    plan_dir.mkdir()
    _run(["append", str(plan_dir), "003", "2", "abc1234..def5678", "PASS"])
    r = _run(["check", str(plan_dir), "003"])
    assert r.returncode == 0, r.stderr
    row = json.loads(r.stdout.strip())
    assert row["task_id"] == "003"
    assert row["verdict"] == "PASS"


def test_check_missing_ledger_exits_1(tmp_path: Path):
    plan_dir = tmp_path / "plan"
    plan_dir.mkdir()
    r = _run(["check", str(plan_dir), "003"])
    assert r.returncode == 1
    assert r.stdout == ""


def test_check_ignores_non_pass_verdicts(tmp_path: Path):
    plan_dir = tmp_path / "plan"
    plan_dir.mkdir()
    _run(["append", str(plan_dir), "003", "2", "abc1234..def5678", "REWORK"])
    r = _run(["check", str(plan_dir), "003"])
    assert r.returncode == 1


def test_check_ignores_other_task_ids(tmp_path: Path):
    plan_dir = tmp_path / "plan"
    plan_dir.mkdir()
    _run(["append", str(plan_dir), "003", "2", "abc1234..def5678", "PASS"])
    r = _run(["check", str(plan_dir), "004"])
    assert r.returncode == 1


def test_check_returns_latest_pass_when_task_appears_twice(tmp_path: Path):
    plan_dir = tmp_path / "plan"
    plan_dir.mkdir()
    _run(["append", str(plan_dir), "003", "1", "aaa1111..bbb2222", "PASS"])
    _run(["append", str(plan_dir), "003", "2", "ccc3333..ddd4444", "PASS"])
    r = _run(["check", str(plan_dir), "003"])
    assert r.returncode == 0, r.stderr
    row = json.loads(r.stdout.strip())
    assert row["commit_range"] == "ccc3333..ddd4444"


def test_append_bad_plan_dir_exits_2(tmp_path: Path):
    r = _run(["append", str(tmp_path / "does-not-exist"), "003", "2", "a..b", "PASS"])
    assert r.returncode == 2
    assert "no such plan dir" in r.stderr


def test_append_wrong_arg_count_exits_2(tmp_path: Path):
    plan_dir = tmp_path / "plan"
    plan_dir.mkdir()
    r = _run(["append", str(plan_dir), "003"])
    assert r.returncode == 2


def test_no_args_exits_2():
    r = _run([])
    assert r.returncode == 2


def test_unknown_subcommand_exits_2(tmp_path: Path):
    r = _run(["frobnicate", str(tmp_path)])
    assert r.returncode == 2
    assert "unknown subcommand" in r.stderr


def test_missing_jq_exits_2(tmp_path: Path):
    plan_dir = tmp_path / "plan"
    plan_dir.mkdir()
    env = {k: v for k, v in os.environ.items() if k != "PATH"}
    env["PATH"] = "/nonexistent"
    r = _run(["append", str(plan_dir), "003", "2", "a..b", "PASS"], env=env)
    assert r.returncode == 2
    assert "requires jq" in r.stderr
