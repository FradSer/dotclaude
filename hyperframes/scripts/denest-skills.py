#!/usr/bin/env python3
"""Rename nested SKILL.md files so they are not auto-discovered as skills.

Claude Code / Cursor treat any directory containing SKILL.md as a skill.
Under hyperframes/skills/ only the root router SKILL.md should be
discoverable; upstream sub-skills ship as <dirname>/SKILL.md and must be
renamed after sync to <dirname>/<dirname>.md. Relative links are rewritten
to match.

Run with HF_TREE_ROOT=1: the tree root IS the hyperframes sub-tree, so
top-level dirs are sub-skills directly.

Usage:
    python3 hyperframes/scripts/denest-skills.py
    python3 hyperframes/scripts/denest-skills.py --check
"""

from __future__ import annotations

import argparse
import os
import re
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
# MARKETING_DIR_OVERRIDE lets the sync scripts run this against a temp copy of
# upstream (so check_diff compares denested-vs-denested).
MARKETING_DIR = Path(os.environ.get("MARKETING_DIR_OVERRIDE", SCRIPT_DIR.parent / "skills"))
# hyperframes/SKILL.md is a local router — do NOT denest it.
LOCAL_ROUTERS = {"SKILL.md"}  # root SKILL.md, hyperframes/SKILL.md
# Paths that should never be renamed or have their content rewritten.
LOCAL_FILES = {"SYNC.md", "SKILL.md", "LICENSE", "UPSTREAM-CLAUDE.md", "UPSTREAM-AGENTS.md"}

# Cross-skill path: foo/SKILL.md, ../foo/SKILL.md, ../../foo/SKILL.md (#anchor ok)
CROSS_SKILL_RE = re.compile(
    r"(?P<prefix>(?:\.\./)*)(?P<dir>[A-Za-z0-9_-]+)/SKILL\.md(?P<anchor>#[^\s)\]`\"]*)?"
)

# Parent entry from a nested file: ../SKILL.md or ./SKILL.md
PARENT_SKILL_RE = re.compile(
    r"(?P<prefix>\.\./|\./)SKILL\.md(?P<anchor>#[^\s)\]`\"]*)?"
)


def owning_subskill(path: Path) -> Path | None:
    """Return the sub-skill dir (relative to MARKETING_DIR) owning this path.

    Marketing main tree: the top-level dir is the skill (offers/...).
    Hyperframes sub-tree: the second-level dir is the skill
    (hyperframes/media-use/...). Paths at a tree root (SYNC.md, SKILL.md,
    UPSTREAM-*) belong to no sub-skill.
    """
    try:
        rel = path.resolve().relative_to(MARKETING_DIR.resolve())
    except ValueError:
        return None
    parts = rel.parts
    if not parts:
        return None
    first = parts[0]
    if first in LOCAL_FILES or first == ".backup":
        return None
    # When the tree root IS the hyperframes sub-tree (sync-hyperframes.sh passes
    # TARGET_DIR as MARKETING_DIR_OVERRIDE), top-level dirs are sub-skills
    # directly — no hyperframes/ nesting to special-case.
    if os.environ.get("HF_TREE_ROOT") == "1":
        return Path(first)
    if first != "hyperframes":
        return Path(first)
    if len(parts) >= 2 and parts[1] not in LOCAL_FILES and parts[1] != ".backup":
        return Path(first) / parts[1]
    return None


def parent_entry(owner: Path, path: Path) -> str:
    """Exact relative path from path's dir to <owner>/<owner-name>.md."""
    entry = MARKETING_DIR / owner / f"{owner.name}.md"
    return str(os.path.relpath(entry.resolve(), path.resolve().parent))


def rewrite_text(text: str, owner: str | None, path: Path) -> str:
    def cross(m: re.Match[str]) -> str:
        d = m.group("dir")
        anchor = m.group("anchor") or ""
        return f"{m.group('prefix')}{d}/{d}.md{anchor}"

    text = CROSS_SKILL_RE.sub(cross, text)

    if owner:

        def parent(m: re.Match[str]) -> str:
            anchor = m.group("anchor") or ""
            return f"{parent_entry(owner, path)}{anchor}"

        text = PARENT_SKILL_RE.sub(parent, text)
        # Do not rewrite bare prose "SKILL.md" — skill-maker and similar docs
        # describe the upstream Agent Skills filename on purpose.

    return text


def rewrite_links() -> int:
    """Rewrite SKILL.md path references. Returns files changed."""
    changed = 0
    for path in MARKETING_DIR.rglob("*.md"):
        if ".backup" in path.parts:
            continue
        owner = owning_subskill(path)
        if owner is None:
            # Root-level files (SKILL.md, SYNC.md, UPSTREAM-*.md, LICENSE)
            # are local additions that describe upstream paths in prose —
            # leave them untouched.
            continue
        original = path.read_text(encoding="utf-8")
        updated = rewrite_text(original, owner, path)
        if updated != original:
            path.write_text(updated, encoding="utf-8")
            changed += 1
    return changed


def is_hf_tree_root() -> bool:
    """True when MARKETING_DIR IS the hyperframes sub-tree (HF_TREE_ROOT=1).

    In that mode top-level dirs are hyperframes sub-skills directly — no
    hyperframes/ nesting to special-case.
    """
    return os.environ.get("HF_TREE_ROOT") == "1"


def rename_nested() -> list[str]:
    """Rename each <dirname>/SKILL.md → <dirname>/<dirname>.md. Returns renamed dirs."""
    renamed: list[str] = []
    for sub in sorted(MARKETING_DIR.iterdir()):
        if not sub.is_dir() or sub.name in LOCAL_FILES or sub.name == ".backup":
            continue
        if not is_hf_tree_root() and sub.name == "hyperframes":
            # Skip hyperframes/ root — it has its own SKILL.md router
            continue
        src = sub / "SKILL.md"
        dst = sub / f"{sub.name}.md"
        if not src.is_file():
            continue
        if dst.exists():
            print(f"error: {dst.relative_to(MARKETING_DIR)} already exists", file=sys.stderr)
            sys.exit(2)
        src.rename(dst)
        renamed.append(sub.name)

    # Now handle hyperframes sub-skills (not the router) — only when the tree
    # root is the marketing skills dir itself.
    hyperframes_dir = MARKETING_DIR / "hyperframes"
    if not is_hf_tree_root() and hyperframes_dir.is_dir():
        for sub in sorted(hyperframes_dir.iterdir()):
            if not sub.is_dir() or sub.name in LOCAL_FILES or sub.name == ".backup":
                continue
            src = sub / "SKILL.md"
            dst = sub / f"{sub.name}.md"
            if not src.is_file():
                continue
            if dst.exists():
                print(f"error: {dst.relative_to(MARKETING_DIR)} already exists", file=sys.stderr)
                sys.exit(2)
            src.rename(dst)
            renamed.append(f"hyperframes/{sub.name}")

    return renamed


def nested_skill_md_paths() -> list[Path]:
    paths = []
    for sub in sorted(MARKETING_DIR.iterdir()):
        if not sub.is_dir() or sub.name in LOCAL_FILES or sub.name == ".backup":
            continue
        if not is_hf_tree_root() and sub.name == "hyperframes":
            continue
        if (sub / "SKILL.md").is_file():
            paths.append(sub / "SKILL.md")
    hyperframes_dir = MARKETING_DIR / "hyperframes"
    if not is_hf_tree_root() and hyperframes_dir.is_dir():
        for sub in sorted(hyperframes_dir.iterdir()):
            if not sub.is_dir() or sub.name in LOCAL_FILES or sub.name == ".backup":
                continue
            if (sub / "SKILL.md").is_file():
                paths.append(sub / "SKILL.md")
    return paths


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument(
        "--check",
        action="store_true",
        help="exit 1 if any nested SKILL.md still exists (would be auto-discovered)",
    )
    args = ap.parse_args()

    if not MARKETING_DIR.is_dir():
        print(f"error: missing {MARKETING_DIR}", file=sys.stderr)
        return 2

    leftover = nested_skill_md_paths()
    if args.check:
        if leftover:
            for p in leftover:
                print(f"nested: {p.relative_to(MARKETING_DIR)}")
            print(
                f"drift: {len(leftover)} nested SKILL.md file(s) would be auto-discovered",
                file=sys.stderr,
            )
            return 1
        print("ok: no nested SKILL.md (sub-skills denested)")
        return 0

    renamed = rename_nested()
    link_files = rewrite_links()
    if renamed:
        print(f"ok: renamed {len(renamed)} nested SKILL.md → <dirname>.md")
    else:
        print("ok: no nested SKILL.md to rename")
    print(f"ok: rewrote links in {link_files} markdown file(s)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
