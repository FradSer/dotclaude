#!/usr/bin/env python3
"""Shared denest tool for mirrored skill trees (marketing / lark / hyperframes / interfaces).

Two denest strategies, selected by mode:

- Default (rename) mode: renames each <dirname>/SKILL.md → <dirname>/<dirname>.md
  so only the root router SKILL.md stays auto-discoverable, and rewrites
  cross-skill relative links (`../<name>/SKILL.md` → `../<name>/<name>.md`,
  `../SKILL.md` → exact parent entry). Used by marketing/lark (main-tree)
  and hyperframes (--hf-root).

- --ref-pack <router> mode: demotes every sibling sub-skill dir into
  <router>/references/<domain>/, renames each SKILL.md → overview.md (stripping
  skill frontmatter and the standalone Review Output Format section), and
  rewrites name-based cross-references (`` `better-x` `` → `` `references/x/overview.md` ``)
  plus path-based `../<name>/SKILL.md` links. Used by interfaces, where only
  the router skill is registered and the other domains are reference packs.

Both modes are idempotent: re-running after a sync is a no-op, and --check
reports drift without changing anything (exit 1 if the tree is not denested).

Usage:
    python3 tools/skill-sync/denest.py --tree <skills-dir> [--hf-root] [--check]
    python3 tools/skill-sync/denest.py --tree <skills-dir> \
        --ref-pack <router> [--strip-prefix <prefix>] [--check]

--tree          The skills tree to denest. Main-tree mode (marketing/lark):
                top-level dirs are sub-skills. --hf-root mode (standalone
                hyperframes plugin): the tree root IS the sub-skill tree,
                top-level dirs are sub-skills directly with no extra nesting.
--ref-pack      Router dir name: keep this top-level dir as the discoverable
                skill; move every other top-level dir under
                <router>/references/<domain>/.
--strip-prefix  In --ref-pack mode, strip this prefix from sub-skill dir names
                when naming reference packs (e.g. `better-` → `accessibility`).
--check         Dry-run: report nested SKILL.md files and link rewrites without
                changing anything; exit 1 if any drift remains.
"""

from __future__ import annotations

import argparse
import os
import re
import sys
from pathlib import Path

# Root-level local files that own no sub-skill (not renamed, not rewritten).
LOCAL_FILES = {"SKILL.md", "SYNC.md", "LICENSE", "UPSTREAM-CLAUDE.md", "UPSTREAM-AGENTS.md"}

# Standalone Review Output Format section cut from ref-pack overviews.
STANDALONE_SECTION_MARKER = "## Review Output Format"

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


def strip_frontmatter(text: str) -> str:
    """Remove leading YAML frontmatter (``---\\n ... \\n---\\n``) if present."""
    if not text.startswith("---\n"):
        return text
    end = text.find("\n---\n", 4)
    if end == -1:
        return text
    return text[end + 5 :]


def cut_standalone_section(text: str) -> str:
    """Cut the standalone Review Output Format section (refs are never invoked
    standalone; the router owns the output format)."""
    idx = text.find(STANDALONE_SECTION_MARKER)
    if idx == -1:
        return text
    return text[:idx].rstrip() + "\n"


class RefPacker:
    """Demote sibling sub-skill dirs into a router's references/ packs.

    Used by interfaces: only the router skill (better-interface) is
    registered; each ``better-*`` sub-skill becomes a domain reference pack
    under ``<router>/references/<domain>/`` with its SKILL.md converted to an
    ``overview.md``. The transformation is deterministic and idempotent.
    """

    def __init__(self, tree: Path, router: str, strip_prefix: str = ""):
        self.tree = tree.resolve()
        self.router = router
        self.prefix = strip_prefix
        self.router_dir = self.tree / router

    def pack_plan(self) -> list[tuple[Path, str, Path]]:
        """Return [(sub_dir, domain, dest_dir)] for sub-skills to demote.

        Idempotent: already-packed sub-skills live under references/ and are
        no longer top-level, so they are not planned a second time.
        """
        plan: list[tuple[Path, str, Path]] = []
        for sub in sorted(self.tree.iterdir()):
            if not sub.is_dir() or sub.name in LOCAL_FILES or sub.name == ".backup":
                continue
            if sub.name == self.router:
                continue
            domain = sub.name
            if self.prefix and domain.startswith(self.prefix):
                domain = domain[len(self.prefix) :]
            plan.append((sub, domain, self.router_dir / "references" / domain))
        return plan

    @staticmethod
    def ref_mapping(plan: list[tuple[Path, str, Path]]) -> dict[str, str]:
        """{sub-skill dir name: references/<domain>/overview.md}."""
        return {sub.name: f"references/{domain}/overview.md" for sub, domain, _ in plan}

    @staticmethod
    def rewrite_refs(text: str, mapping: dict[str, str]) -> str:
        """Rewrite name-based (`` `better-x` ``) and path-based (../x/SKILL.md)
        cross-references to references-pack paths, and drop the article before
        a rewritten path ("the `references/…`" → "`references/…`")."""
        for name, target in mapping.items():
            text = text.replace(f"`{name}` skill", f"`{target}`")
            text = text.replace(f"`{name}`", f"`{target}`")
            text = re.sub(rf"\.\./{re.escape(name)}/SKILL\.md", target, text)
        text = text.replace("the `references/", "`references/")
        return text

    def pack_skill_files(self) -> list[Path]:
        """SKILL.md files inside packs (converted to overview.md on apply).

        The router's own SKILL.md is never converted.
        """
        found: list[Path] = []
        for path in self.tree.rglob("SKILL.md"):
            if ".backup" in path.parts or path.parent == self.router_dir:
                continue
            found.append(path)
        return found

    @staticmethod
    def is_local_root(path: Path, tree: Path) -> bool:
        """True for root-level local files (SYNC.md, UPSTREAM-*.md, LICENSE,
        router SKILL.md) that describe the tree in prose and are never
        rewritten by the sync."""
        rel = path.resolve().relative_to(tree.resolve())
        return rel.parts and rel.parts[0] in LOCAL_FILES

    @staticmethod
    def pack_skill_text(text: str) -> str:
        """Ref-pack conversion of a pack SKILL.md: strip skill frontmatter and
        cut the standalone Review Output Format section (refs are never
        invoked standalone; the router owns the output format)."""
        return cut_standalone_section(strip_frontmatter(text))

    def apply(self) -> tuple[list[str], int]:
        """Move sub-skills into references/ packs, convert SKILL.md →
        overview.md, and rewrite links.

        Returns (moved_dirs, files_rewritten). Idempotent: already-packed
        trees have no top-level sub-skills to move and no SKILL.md files to
        convert, and rewritten text is stable under re-rewriting.
        """
        plan = self.pack_plan()
        mapping = self.ref_mapping(plan)
        moved: list[str] = []
        for sub, domain, dest in plan:
            if dest.exists():
                print(f"warn: {dest} already exists, skipping {sub.name}", file=sys.stderr)
                continue
            dest.parent.mkdir(parents=True, exist_ok=True)
            sub.rename(dest)
            moved.append(sub.name)
        rewritten = 0
        for path in self.pack_skill_files():
            overview = path.with_name("overview.md")
            if overview.exists():
                print(f"warn: {overview} already exists, keeping SKILL.md untouched", file=sys.stderr)
                continue
            overview.write_text(self.pack_skill_text(path.read_text(encoding="utf-8")), encoding="utf-8")
            path.unlink()
            rewritten += 1
        for path in sorted(self.tree.rglob("*.md")):
            if ".backup" in path.parts or self.is_local_root(path, self.tree):
                continue
            updated = self.rewrite_refs(path.read_text(encoding="utf-8"), mapping)
            if updated != path.read_text(encoding="utf-8"):
                path.write_text(updated, encoding="utf-8")
                rewritten += 1
        return moved, rewritten

    def check(self) -> bool:
        """Dry-run: report planned moves and content drift. True if in sync."""
        plan = self.pack_plan()
        mapping = self.ref_mapping(plan)
        ok = True
        for sub, domain, dest in plan:
            print(f"ref-pack move: {sub.name}/ → {dest.relative_to(self.tree)}")
            ok = False
        for path in self.pack_skill_files():
            print(f"ref-pack convert: {path.relative_to(self.tree)} → overview.md")
            ok = False
        for path in sorted(self.tree.rglob("*.md")):
            if ".backup" in path.parts or self.is_local_root(path, self.tree):
                continue
            if self.rewrite_refs(path.read_text(encoding="utf-8"), mapping) != path.read_text(encoding="utf-8"):
                print(f"ref-pack rewrite: {path.relative_to(self.tree)}")
                ok = False
        return ok


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("--tree", required=True, type=Path, help="skills tree root")
    parser.add_argument(
        "--hf-root",
        action="store_true",
        help="tree root IS the sub-skill tree (top-level dirs are sub-skills)",
    )
    parser.add_argument(
        "--ref-pack",
        metavar="ROUTER",
        default=None,
        help="ref-pack mode: keep ROUTER as the skill; demote sibling dirs "
        "into ROUTER/references/<domain>/ with SKILL.md → overview.md",
    )
    parser.add_argument(
        "--strip-prefix",
        metavar="PREFIX",
        default="",
        help="in --ref-pack mode, strip PREFIX from sub-skill dir names when "
        "naming reference packs (e.g. better-)",
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="dry-run: report nested SKILL.md / ref-pack drift; exit 1 if any",
    )
    args = parser.parse_args()

    if args.ref_pack:
        p = RefPacker(args.tree, args.ref_pack, args.strip_prefix)
        if not p.router_dir.is_dir():
            print(f"error: router dir not found: {p.router_dir}", file=sys.stderr)
            return 1
        if args.check:
            if p.check():
                print("OK: tree is in ref-pack form")
                return 0
            print("FAILED: ref-pack drift detected", file=sys.stderr)
            return 1
        moved, rewritten = p.apply()
        print(f"ref-pack: moved={len(moved)} rewritten_files={rewritten}", file=sys.stderr)
        return 0

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
