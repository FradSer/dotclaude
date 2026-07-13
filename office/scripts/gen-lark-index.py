#!/usr/bin/env python3
"""Regenerate the Sub-skill Index table in office/skills/lark/SKILL.md.

Scans each lark-* subdirectory (and lark-shared) under
office/skills/lark/, extracts the name/version/description frontmatter
from each sub-skill's SKILL.md, and rewrites the index table in the
parent SKILL.md between the `## Sub-skill Index` and `## Routing Rules`
markers. Local-only SKILL.md/SYNC.md at the root are never overwritten;
this script only edits the index table region.

Usage:
    python3 office/scripts/gen-lark-index.py            # rewrite
    python3 office/scripts/gen-lark-index.py --check      # dry-run diff, exit 1 if drift
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

import yaml

SCRIPT_DIR = Path(__file__).resolve().parent
LARK_DIR = SCRIPT_DIR.parent / "skills" / "lark"
SKILL_MD = LARK_DIR / "SKILL.md"

# Sub-skills are sorted by name; lark-shared is hoisted to the top because the
# routing rules instruct readers to load it first.
INDEX_START_MARKER = "## Sub-skill Index"
INDEX_END_MARKER = "## Routing Rules"

# Human-readable display labels for the two workflow + a couple of entries
# whose directory name is not an obvious label. Falls back to the directory
# name otherwise.
LABELS: dict[str, str] = {
    "lark-shared": "Shared Config & Auth",
    "lark-doc": "Documents",
    "lark-markdown": "Markdown",
    "lark-sheets": "Spreadsheets",
    "lark-base": "Multidimensional Tables",
    "lark-calendar": "Calendar",
    "lark-im": "Instant Messaging",
    "lark-mail": "Email",
    "lark-task": "Tasks",
    "lark-okr": "OKR",
    "lark-drive": "Drive",
    "lark-wiki": "Wiki",
    "lark-slides": "Slides",
    "lark-apps": "Web Apps (Miaoda)",
    "lark-whiteboard": "Whiteboard",
    "lark-approval": "Approval",
    "lark-attendance": "Attendance",
    "lark-contact": "Contact",
    "lark-vc": "Video Conference",
    "lark-vc-agent": "VC Agent (live)",
    "lark-minutes": "Minutes",
    "lark-note": "Note",
    "lark-event": "Event Subscription",
    "lark-openapi-explorer": "OpenAPI Explorer",
    "lark-skill-maker": "Skill Maker",
    "lark-workflow-meeting-summary": "Workflow: Meeting Summary",
    "lark-workflow-standup-report": "Workflow: Standup Report",
}


def load_subskills() -> list[dict]:
    """Return one record per lark-* subdirectory with a SKILL.md frontmatter."""
    records: list[dict] = []
    for sub in sorted(LARK_DIR.iterdir()):
        if not sub.is_dir() or not sub.name.startswith("lark-"):
            continue
        skill_md = sub / "SKILL.md"
        if not skill_md.is_file():
            print(f"warn: {sub.name}/SKILL.md missing, skipping", file=sys.stderr)
            continue
        text = skill_md.read_text(encoding="utf-8")
        if not text.startswith("---\n"):
            print(f"warn: {sub.name}/SKILL.md has no frontmatter", file=sys.stderr)
            continue
        _, fm_raw, _body = text.split("---\n", 2)
        fm = yaml.safe_load(fm_raw) or {}
        name = fm.get("name", sub.name)
        version = fm.get("version", "")
        description = fm.get("description", "") or ""
        records.append(
            {
                "dir": sub.name,
                "name": name,
                "version": str(version),
                "description": " ".join(description.split()),
            }
        )
    # Hoist lark-shared to the top; everything else stays alphabetical.
    records.sort(key=lambda r: (r["dir"] != "lark-shared", r["dir"]))
    return records


def render_table(records: list[dict]) -> str:
    header = "| Sub-skill | Directory | Version | Use When |\n|-----------|-----------|---------|----------|"
    rows = []
    for r in records:
        label = LABELS.get(r["dir"], r["dir"])
        # Escape pipes inside the description so the markdown table survives.
        use_when = r["description"].replace("|", "\\|")
        rows.append(
            f"| {label} | `{r['dir']}/` | {r['version']} | {use_when} |"
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

    records = load_subskills()
    if not records:
        print("error: no lark-* sub-skills found", file=sys.stderr)
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
