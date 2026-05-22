"""Shared pytest fixtures for superpowers test suite.

Currently exposes git-repo factories used by tests that need a real repo
to exercise hook behavior (`completion_commit` capture, post-plan diff
classification). `git init` is collapsed to a single subprocess via
`-c key=value` flags so each fixture call is one fork instead of four.
"""
from __future__ import annotations

import os
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


def path_without_commands(shim_dir: Path, exclude: set[str]) -> str:
    """Build a one-entry PATH that mirrors the current environment minus
    the named commands. Symlinks every executable on the current PATH into
    shim_dir except those whose basename is in `exclude`, then returns
    shim_dir as the PATH string. Lets a test exercise a command-absent
    degradation path (e.g. no shasum/sha1sum) while keeping bash, jq, git,
    awk, and friends resolvable."""
    shim_dir.mkdir(parents=True, exist_ok=True)
    for d in os.environ.get("PATH", "").split(os.pathsep):
        if not d or not os.path.isdir(d):
            continue
        for name in os.listdir(d):
            if name in exclude:
                continue
            link = shim_dir / name
            if link.exists() or link.is_symlink():
                continue
            src = os.path.join(d, name)
            if os.path.isdir(src) or not os.access(src, os.X_OK):
                continue
            try:
                link.symlink_to(src)
            except OSError:
                pass
    return str(shim_dir)
