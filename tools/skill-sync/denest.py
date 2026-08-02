#!/usr/bin/env python3
"""Shared denest tool for mirrored skill trees (marketing / lark / hyperframes).

Renames each <dirname>/SKILL.md → <dirname>/<dirname>.md so only the root
router SKILL.md stays auto-discoverable, and rewrites cross-skill relative
links (`../<name>/SKILL.md` → `../<name>/<name>.md`, `../SKILL.md` → exact
parent entry). The three mirrored plugins used to ship separate copies of
this logic; sync scripts now call this one tool.

Usage:
    python3 tools/skill-sync/denest.py --tree <skills-dir> [--hf-root] [--check]

--tree    The skills tree to denest. Main-tree mode (marketing/lark): top-level
          dirs are sub-skills. --hf-root mode (standalone hyperframes plugin):
          the tree root IS the sub-skill tree, top-level dirs are sub-skills
          directly with no extra nesting.
--check   Dry-run: report nested SKILL.md files and link rewrites without
          changing anything; exit 1 if any nested SKILL.md remains.
"""

from __future__ import annotations

import argparse
import os
import re
import sys
from pathlib import Path

# Root-level local files that own no sub-skill (not renamed, not rewritten).
LOCAL_FILES = {"SKILL.md", "SYNC.md", "LICENSE", "UPSTREAM-CLAUDE.md", "UPSTREAM-AGENTS.md"}

# Cross-skill path: ../lark-foo/SKILL.md, ../../lark-foo/SKILL.md (#anchor ok)
CROSS_SKILL_RE = re.compile(
    r"(?P<prefix>\.\./)+"
    r"(?P<dir>[a-z0-9]+(?:-[a-z0-9]+)*)"
    r"/SKILL\.md(?P<anchor>#[^\s)\]`\"]*)?"
)

# Parent entry from a nested file: ../SKILL.md or ./SKILL.md
PARENT_SKILL_RE = re.compile(
    r"(?P<prefix>\.\./|\./)SKILL\.md(?P<anchor>#[^\s)\]`\"]*)?"
)


class Denester:
    def __init__(self, tree: Path, hf_root: bool = False):
        self.tree = tree.resolve()
        self.hf_root = hf_root

    def owning_subskill(self, path: Path) -> Path | None:
        """Return the sub-skill dir (relative to tree) owning this path.

        Main-tree mode (marketing/lark): the top-level dir is the skill.
        --hf-root mode (hyperframes): top-level dirs are sub-skills directly.
        Paths at the tree root (SYNC.md, SKILL.md, UPSTREAM-*, LICENSE) belong
        to no sub-skill.
        """
        try:
            rel = path.resolve().relative_to(self.tree)
        except ValueError:
            return None
        parts = rel.parts
        if not parts:
            return None
        first = parts[0]
        if first in LOCAL_FILES or first == ".backup":
            return None
        return Path(first)

    def parent_entry(self, owner: Path, path: Path) -> str:
        """Exact relative path from path's dir to <owner>/<owner-name>.md."""
        entry = self.tree / owner / f"{owner.name}.md"
        return os.path.relpath(str(entry), str(path.resolve().parent))

    def rewrite_text(self, text: str, owner: Path | None, path: Path) -> str:
        def cross(m: re.Match[str]) -> str:
            d = m.group("dir")
            anchor = m.group("anchor") or ""
            return f"{m.group('prefix')}{d}/{d}.md{anchor}"

        text = CROSS_SKILL_RE.sub(cross, text)

        if owner:
            def parent(m: re.Match[str]) -> str:
                anchor = m.group("anchor") or ""
                return f"{self.parent_entry(owner, path)}{anchor}"

            text = PARENT_SKILL_RE.sub(parent, text)
            # Do not rewrite bare prose "SKILL.md" — docs that describe the
            # upstream Agent Skills filename on purpose keep it.

        return text

    def rename_nested(self) -> list[str]:
        """Rename each <dirname>/SKILL.md → <dirname>/<dirname>.md."""
        renamed: list[str] = []
        for sub in sorted(self.tree.iterdir()):
            if not sub.is_dir() or sub.name in LOCAL_FILES or sub.name == ".backup":
                continue
            src = sub / "SKILL.md"
            dst = sub / f"{sub.name}.md"
            if not src.is_file():
                continue
            if dst.exists():
                print(f"warn: {dst} already exists, keeping SKILL.md untouched", file=sys.stderr)
                continue
            src.rename(dst)
            renamed.append(sub.name)
        return renamed

    def rewrite_links(self) -> int:
        """Rewrite SKILL.md path references under the tree. Returns files changed."""
        changed = 0
        for path in self.tree.rglob("*.md"):
            if ".backup" in path.parts:
                continue
            owner = self.owning_subskill(path)
            if owner is None:
                # Root-level files (SKILL.md, SYNC.md, UPSTREAM-*.md, LICENSE)
                # are local additions that describe upstream paths in prose —
                # leave them untouched.
                continue
            original = path.read_text(encoding="utf-8")
            updated = self.rewrite_text(original, owner, path)
            if updated != original:
                path.write_text(updated, encoding="utf-8")
                changed += 1
        return changed

    def nested_skill_mds(self) -> list[Path]:
        """Nested SKILL.md files that would be renamed."""
        found: list[Path] = []
        for sub in sorted(self.tree.iterdir()):
            if not sub.is_dir() or sub.name in LOCAL_FILES or sub.name == ".backup":
                continue
            src = sub / "SKILL.md"
            if src.is_file():
                found.append(src)
        return found


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("--tree", required=True, type=Path, help="skills tree root")
    parser.add_argument(
        "--hf-root",
        action="store_true",
        help="tree root IS the sub-skill tree (top-level dirs are sub-skills)",
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="dry-run: report nested SKILL.md; exit 1 if any remains",
    )
    args = parser.parse_args()

    d = Denester(args.tree, args.hf_root)
    if args.check:
        nested = d.nested_skill_mds()
        for p in nested:
            print(f"nested SKILL.md: {p}")
        if nested:
            print(f"FAILED: {len(nested)} nested SKILL.md remain", file=sys.stderr)
            return 1
        print("OK: no nested SKILL.md")
        return 0

    renamed = d.rename_nested()
    links = d.rewrite_links()
    print(f"denest: renamed={len(renamed)} link_files={links}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
