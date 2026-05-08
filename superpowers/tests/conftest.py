"""Shared pytest fixtures for superpowers test suite.

Currently exposes git-repo factories used by tests that need a real repo
to exercise hook behavior (`completion_commit` capture, post-plan diff
classification). `git init` is collapsed to a single subprocess via
`-c key=value` flags so each fixture call is one fork instead of four.
"""
from __future__ import annotations

import subprocess
from pathlib import Path


def make_git_repo(root: Path) -> None:
    """Init a temp git repo with deterministic identity. One subprocess."""
    subprocess.run(
        [
            "git",
            "-c", "user.email=test@example.com",
            "-c", "user.name=Test",
            "-c", "commit.gpgsign=false",
            "init", "-q", "-b", "main",
        ],
        cwd=root,
        check=True,
    )
    # `init -c` doesn't persist config into the repo — re-set the keys git
    # actually reads at commit time. Two extra forks, but local-scoped
    # config stays out of the user's global state.
    subprocess.run(["git", "config", "user.email", "test@example.com"], cwd=root, check=True)
    subprocess.run(["git", "config", "user.name", "Test"], cwd=root, check=True)
    subprocess.run(["git", "config", "commit.gpgsign", "false"], cwd=root, check=True)


def commit(root: Path, msg: str, files: dict[str, str]) -> str:
    """Write files + commit. Returns full SHA."""
    for path, content in files.items():
        full = root / path
        full.parent.mkdir(parents=True, exist_ok=True)
        full.write_text(content)
        subprocess.run(["git", "add", path], cwd=root, check=True)
    subprocess.run(["git", "commit", "-q", "-m", msg], cwd=root, check=True)
    return subprocess.run(
        ["git", "rev-parse", "HEAD"],
        cwd=root, capture_output=True, text=True, check=True,
    ).stdout.strip()
