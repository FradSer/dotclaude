#!/usr/bin/env python3
"""Regenerate the Sub-skill Index table in marketing/skills/SKILL.md.

Scans each skill directory under marketing/skills/ (excluding hyperframes,
which is a separately-synced sub-tree with its own router SKILL.md), extracts
the name/version/description frontmatter from each sub-skill's <dirname>.md
(nested SKILL.md is denested after sync so it is not auto-discovered), and
rewrites the index table in the parent SKILL.md between the `## Sub-skill
Index` and `## Routing Rules` markers. Local-only SKILL.md/SYNC.md at the root
are never overwritten; this script only edits the index table region.

Version resolution: `metadata.version` in the sub-skill frontmatter (the
marketing upstream convention), falling back to a top-level `version` field,
then to the VERSIONS.md registry for entries that omit it.

Usage:
    python3 marketing/scripts/gen-marketing-index.py            # rewrite
    python3 marketing/scripts/gen-marketing-index.py --check      # dry-run diff, exit 1 if drift
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

import yaml

SCRIPT_DIR = Path(__file__).resolve().parent
MARKETING_DIR = SCRIPT_DIR.parent / "skills"
SKILL_MD = MARKETING_DIR / "SKILL.md"
VERSIONS_MD = SCRIPT_DIR.parent / "VERSIONS.md"

# Sub-trees / local files that are NOT marketing sub-skills.
EXCLUDED_DIRS = {"hyperframes", ".backup"}

INDEX_START_MARKER = "## Sub-skill Index"
INDEX_END_MARKER = "## Routing Rules"

# VERSIONS.md row: "| skill-name | 1.2.3 | 2026-07-01 |" — fallback registry.
VERSION_ROW_RE = re.compile(r"^\|\s*([a-z0-9-]+)\s*\|\s*([0-9]+\.[0-9]+\.[0-9]+)\s*\|")


def load_version_registry() -> dict[str, str]:
    """Parse VERSIONS.md into {skill-name: version}."""
    registry: dict[str, str] = {}
    if not VERSIONS_MD.is_file():
        return registry
    for line in VERSIONS_MD.read_text(encoding="utf-8").splitlines():
        m = VERSION_ROW_RE.match(line)
        if m:
            registry[m.group(1)] = m.group(2)
    return registry


def subskill_entry(sub: Path) -> Path | None:
    """Prefer denested <dirname>.md; fall back to upstream SKILL.md if present."""
    denested = sub / f"{sub.name}.md"
    if denested.is_file():
        return denested
    legacy = sub / "SKILL.md"
    if legacy.is_file():
        return legacy
    return None


def read_frontmatter(path: Path) -> dict:
    text = path.read_text(encoding="utf-8")
    if not text.startswith("---\n"):
        return {}
    _, fm_raw, _ = text.split("---\n", 2)
    return yaml.safe_load(fm_raw) or {}


def load_subskills(registry: dict[str, str]) -> list[dict]:
    """Return one record per sub-skill directory with entry-file frontmatter."""
    records: list[dict] = []
    for sub in sorted(MARKETING_DIR.iterdir()):
        if not sub.is_dir() or sub.name in EXCLUDED_DIRS:
            continue
        entry = subskill_entry(sub)
        if entry is None:
            print(f"warn: {sub.name}/{{SKILL.md|{sub.name}.md}} missing, skipping", file=sys.stderr)
            continue
        fm = read_frontmatter(entry)
        name = fm.get("name", sub.name)
        version = ""
        if isinstance(fm.get("metadata"), dict):
            version = str(fm["metadata"].get("version", ""))
        if not version:
            version = str(fm.get("version", ""))
        if not version:
            version = registry.get(sub.name, "")
        description = fm.get("description", "") or ""
        records.append(
            {
                "dir": sub.name,
                "name": name,
                "version": version,
                "description": " ".join(str(description).split()),
            }
        )
    records.sort(key=lambda r: r["dir"])
    return records


def render_table(records: list[dict]) -> str:
    header = (
        "| Sub-skill | Entry | Version | Use When |\n"
        "|-----------|-------|---------|----------|"
    )
    rows = []
    for r in records:
        entry = f"{r['dir']}/{r['dir']}.md"
        # Escape pipes inside the description so the markdown table survives.
        use_when = r["description"].replace("|", "\\|")
        label = r["name"]
        rows.append(
            f"| {label} | [`{entry}`]({entry}) | {r['version']} | {use_when} |"
        )
    return header + "\n" + "\n".join(rows) + "\n\n"


def rebuild_skill_md(new_table: str) -> str:
    src = SKILL_MD.read_text(encoding="utf-8")
    start = src.index(INDEX_START_MARKER)
    end = src.index(INDEX_END_MARKER)
    # Keep the "## Sub-skill Index" header line (it ends with a newline), then
    # the table, then resume at "## Routing Rules".
    header_line = src[start : src.index("\n", start) + 1]
    return src[:start] + header_line + "\n" + new_table + src[end:]


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--check", action="store_true", help="dry-run; exit 1 if SKILL.md would change")
    args = ap.parse_args()

    if not SKILL_MD.is_file():
        print(f"error: missing {SKILL_MD} (router SKILL.md must exist)", file=sys.stderr)
        return 2

    registry = load_version_registry()
    records = load_subskills(registry)
    if not records:
        print("error: no marketing sub-skills found", file=sys.stderr)
        return 2
    new_table = render_table(records)
    new_src = rebuild_skill_md(new_table)
    old_src = SKILL_MD.read_text(encoding="utf-8")

    if new_src == old_src:
        print("ok: SKILL.md index already in sync with sub-skill frontmatter")
        return 0

    if args.check:
        print("drift: SKILL.md index table is stale vs sub-skill frontmatter")
        return 1

    SKILL_MD.write_text(new_src, encoding="utf-8")
    print(f"ok: regenerated index table for {len(records)} sub-skills in {SKILL_MD}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
