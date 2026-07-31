"""Tests for lib/task-brief.sh — extract one task's text to a file."""
from __future__ import annotations

import subprocess
from pathlib import Path

PLUGINS = Path(__file__).resolve().parents[1]
SCRIPT = PLUGINS / "lib" / "task-brief.sh"

PLAN = """# Demo Plan

## Task 1: Setup

Setup the project skeleton.

## Task 2: Auth test

Write a failing auth test.

## Task 10: Integration

Glue everything together.
"""


def _run(args, **kw):
    return subprocess.run(
        ["bash", str(SCRIPT), *args],
        capture_output=True, text=True, **kw,
    )


def test_extracts_single_task(tmp_path: Path):
    plan = tmp_path / "_index.md"
    plan.write_text(PLAN)
    out = tmp_path / "brief.md"
    r = _run([str(plan), "2", str(out)])
    assert r.returncode == 0, r.stderr
    content = out.read_text()
    assert "Auth test" in content
    assert "Setup" not in content  # task 1 excluded
    assert "Integration" not in content  # task 10 excluded


def test_default_outfile_lands_in_plan_dir_briefs(tmp_path: Path):
    plan = tmp_path / "_index.md"
    plan.write_text(PLAN)
    r = _run([str(plan), "1"])
    assert r.returncode == 0, r.stderr
    expected = tmp_path / "_briefs" / "task-1-brief.md"
    assert expected.exists()
    assert "Setup" in expected.read_text()


def test_task_not_found_exits_3(tmp_path: Path):
    plan = tmp_path / "_index.md"
    plan.write_text(PLAN)
    out = tmp_path / "brief.md"
    r = _run([str(plan), "99", str(out)])
    assert r.returncode == 3
    assert "not found" in r.stderr


def test_no_such_plan_file_exits_2(tmp_path: Path):
    out = tmp_path / "brief.md"
    r = _run([str(tmp_path / "nope.md"), "1", str(out)])
    assert r.returncode == 2


def test_bad_arg_count_exits_2(tmp_path: Path):
    r = _run([])
    assert r.returncode == 2


def test_task_number_not_substring_match(tmp_path: Path):
    """Task 1 must not match Task 10 — the awk guards [^0-9] after N."""
    plan = tmp_path / "_index.md"
    plan.write_text(PLAN)
    out = tmp_path / "brief.md"
    r = _run([str(plan), "1", str(out)])
    assert r.returncode == 0, r.stderr
    content = out.read_text()
    assert "Setup" in content
    assert "Integration" not in content  # task 10 not pulled by task 1
