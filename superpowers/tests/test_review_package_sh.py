"""Tests for lib/review-package.sh — generate a net-diff review package."""
from __future__ import annotations

import subprocess
from pathlib import Path

import sys
sys.path.insert(0, str(Path(__file__).resolve().parent))
from conftest import make_git_repo, commit  # type: ignore

PLUGINS = Path(__file__).resolve().parents[1]
SCRIPT = PLUGINS / "lib" / "review-package.sh"


def _run(args, cwd=None, **kw):
    return subprocess.run(
        ["bash", str(SCRIPT), *args],
        capture_output=True, text=True, cwd=cwd, **kw,
    )


def test_writes_review_package_with_commits_and_diff(tmp_path: Path):
    make_git_repo(tmp_path)
    base = commit(tmp_path, "base", {"a.txt": "a\n"})
    head = commit(tmp_path, "add b", {"b.txt": "b\n"})
    plan_dir = tmp_path / "docs" / "plans" / "demo-plan"
    plan_dir.mkdir(parents=True)
    r = _run([base, head, str(plan_dir)], cwd=tmp_path)
    assert r.returncode == 0, r.stderr
    pkg = plan_dir / "_reviews" / f"review-{base[:7]}..{head[:7]}.diff"
    assert pkg.exists()
    content = pkg.read_text()
    assert "## Commits" in content
    assert "## Files changed" in content
    assert "## Diff" in content
    assert "add b" in content
    assert "b.txt" in content


def test_bad_base_exits_2(tmp_path: Path):
    make_git_repo(tmp_path)
    commit(tmp_path, "base", {"a.txt": "a\n"})
    plan_dir = tmp_path / "plan"
    plan_dir.mkdir()
    r = _run(["not-a-real-ref", "HEAD", str(plan_dir)], cwd=tmp_path)
    assert r.returncode == 2
    assert "bad BASE" in r.stderr


def test_bad_head_exits_2(tmp_path: Path):
    make_git_repo(tmp_path)
    commit(tmp_path, "base", {"a.txt": "a\n"})
    plan_dir = tmp_path / "plan"
    plan_dir.mkdir()
    r = _run(["HEAD", "not-a-real-ref", str(plan_dir)], cwd=tmp_path)
    assert r.returncode == 2
    assert "bad HEAD" in r.stderr


def test_bad_arg_count_exits_2(tmp_path: Path):
    r = _run([])
    assert r.returncode == 2


def test_explicit_outfile(tmp_path: Path):
    make_git_repo(tmp_path)
    base = commit(tmp_path, "base", {"a.txt": "a\n"})
    head = commit(tmp_path, "change", {"a.txt": "a\nb\n"})
    out = tmp_path / "custom.diff"
    r = _run([base, head, str(tmp_path / "plan"), str(out)], cwd=tmp_path)
    assert r.returncode == 0, r.stderr
    assert out.exists()
    assert "## Diff" in out.read_text()
