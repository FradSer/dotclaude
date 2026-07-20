#!/usr/bin/env python3
"""Rename nested lark-*/SKILL.md so they are not auto-discovered as skills.

Claude Code / Cursor treat any directory containing SKILL.md as a skill.
Under office/skills/lark/ only the root router SKILL.md should be discoverable;
upstream sub-skills ship as lark-*/SKILL.md and must be renamed after sync to
lark-*/<dirname>.md. Relative links are rewritten to match.

Usage:
    python3 office/scripts/denest-lark-skills.py            # rename + relink
    python3 office/scripts/denest-lark-skills.py --check     # exit 1 if any nested SKILL.md remains
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
LARK_DIR = SCRIPT_DIR.parent / "skills" / "lark"

# Cross-skill path: lark-foo/SKILL.md, ../lark-foo/SKILL.md, ../../… (#anchor ok)
CROSS_SKILL_RE = re.compile(
    r"(?P<prefix>(?:\.\./)*)(?P<dir>lark-[A-Za-z0-9-]+)/SKILL\.md(?P<anchor>#[^\s)\]`\"]*)?"
)

# Parent entry from a nested file: ../SKILL.md or ./SKILL.md
PARENT_SKILL_RE = re.compile(
    r"(?P<prefix>\.\./|\./)SKILL\.md(?P<anchor>#[^\s)\]`\"]*)?"
)


def iter_subskill_dirs() -> list[Path]:
    dirs: list[Path] = []
    for sub in sorted(LARK_DIR.iterdir()):
        if sub.is_dir() and sub.name.startswith("lark-") and sub.name != ".backup":
            dirs.append(sub)
    return dirs


def owning_subskill(path: Path) -> str | None:
    """Return lark-* dirname if path lives under that sub-skill, else None."""
    try:
        rel = path.resolve().relative_to(LARK_DIR.resolve())
    except ValueError:
        return None
    parts = rel.parts
    if parts and parts[0].startswith("lark-"):
        return parts[0]
    return None


def rewrite_text(text: str, owner: str | None) -> str:
    def cross(m: re.Match[str]) -> str:
        d = m.group("dir")
        anchor = m.group("anchor") or ""
        return f"{m.group('prefix')}{d}/{d}.md{anchor}"

    text = CROSS_SKILL_RE.sub(cross, text)

    if owner:

        def parent(m: re.Match[str]) -> str:
            anchor = m.group("anchor") or ""
            return f"{m.group('prefix')}{owner}.md{anchor}"

        text = PARENT_SKILL_RE.sub(parent, text)
        # Do not rewrite bare prose "SKILL.md" — skill-maker and similar docs
        # describe the upstream Agent Skills filename on purpose.

    return text


def rewrite_links() -> int:
    """Rewrite SKILL.md path references under lark/. Returns files changed."""
    changed = 0
    for path in LARK_DIR.rglob("*.md"):
        if ".backup" in path.parts:
            continue
        # Root SYNC.md documents the rename; leave historical SKILL.md mentions
        # that refer to the router / generator alone — still rewrite path forms.
        owner = owning_subskill(path)
        # Root router: only rewrite cross-skill paths (no owner bare replace).
        original = path.read_text(encoding="utf-8")
        updated = rewrite_text(original, owner)
        if updated != original:
            path.write_text(updated, encoding="utf-8")
            changed += 1
    return changed


def rename_nested() -> list[str]:
    """Rename each lark-*/SKILL.md → lark-*/<dirname>.md. Returns renamed dirs."""
    renamed: list[str] = []
    for sub in iter_subskill_dirs():
        src = sub / "SKILL.md"
        dst = sub / f"{sub.name}.md"
        if not src.is_file():
            continue
        if dst.exists():
            print(f"error: {dst.relative_to(LARK_DIR)} already exists", file=sys.stderr)
            sys.exit(2)
        src.rename(dst)
        renamed.append(sub.name)
    return renamed


def nested_skill_md_paths() -> list[Path]:
    return [
        sub / "SKILL.md"
        for sub in iter_subskill_dirs()
        if (sub / "SKILL.md").is_file()
    ]


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument(
        "--check",
        action="store_true",
        help="exit 1 if any lark-*/SKILL.md still exists (would be auto-discovered)",
    )
    args = ap.parse_args()

    if not LARK_DIR.is_dir():
        print(f"error: missing {LARK_DIR}", file=sys.stderr)
        return 2

    leftover = nested_skill_md_paths()
    if args.check:
        if leftover:
            for p in leftover:
                print(f"nested: {p.relative_to(LARK_DIR)}")
            print(
                f"drift: {len(leftover)} nested SKILL.md file(s) would be auto-discovered",
                file=sys.stderr,
            )
            return 1
        print("ok: no nested lark-*/SKILL.md (sub-skills denested)")
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
