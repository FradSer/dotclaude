#!/usr/bin/env python3
"""Verify the mattpocock fork against a recorded upstream revision.

Offline by default. Pass --upstream to also compare against an already-cloned
mattpocock/skills checkout. The checker never clones, fetches, or writes.

Exit 0: all checks pass, JSON report on stdout.
Exit 1: first violation on stderr, no report.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from pathlib import Path

PLUGIN_DIR = Path(__file__).resolve().parent.parent
SELECTION_PATH = PLUGIN_DIR / "upstream-selection.json"
SKILLS_DIR = PLUGIN_DIR / "skills"
MANIFEST_PATH = PLUGIN_DIR / ".claude-plugin" / "plugin.json"

COMMIT_RE = re.compile(r"^[0-9a-f]{40}$")
DENY_PATTERNS = [
    (r"\bmatt_pocock_(?:workflow|active|ask)\b", "Pi-only tool name"),
    (r"\bavailable_skills\b", "Pi-only skill surface"),
    (r"\bTOTAL_MINUTES\b", "removed wizard variable"),
    (r"\bAgent tool\b", "harness-specific agent phrasing"),
    (r"\bgeneral-purpose\b", "harness-specific agent name"),]
NAMESPACED_RE = re.compile(r"/mattpocock:([\w-]+)")
LINK_RE = re.compile(r"\[[^\]]*\]\(([^)]+)\)")
# Built-in Claude Code commands and non-skill paths must not be mistaken for
# bare skill references.
BUILTIN_COMMANDS = {"clear", "compact", "plugin", "help", "init", "model",
                    "memory", "config", "permissions", "cost", "doctor",
                    "mcp", "skills", "hooks", "status", "terminal", "settings",
                    "tmp", "settings"}

# Distinctive behavioral fixes introduced upstream since the recorded baseline.
# Each maps the local skill path to a phrase that must appear in its body.
# Restructured prose (routers, examples, bullet wording) is deliberately NOT
# checked: those lines are whole-paragraph rewrites, not portable fixes.
CONTENT_FIX_MARKERS = {
    "engineering/ask-matt": "read that skill's SKILL.md",
    "engineering/code-review": "Start every sub-agent with a fresh context window",
    "engineering/codebase-design/DESIGN-IT-TWICE.md": "fresh context window",
    "engineering/diagnosing-bugs": "prove the mutation landed",
    "engineering/implement": "fetch it from the issue tracker and state its title",
    "engineering/improve-codebase-architecture": "fresh context window",
    "engineering/research": "Start it with a fresh context window",
    "engineering/setup-matt-pocock-skills": "A GitHub or GitLab tracker needs a reachable repo",
    "engineering/tdd": "one-line note on what it catches and what it misses",
    "engineering/to-tickets": "Omit this section when blockers were set as native edges",
    "engineering/wayfinder": "never a triage label like `ready-for-agent`",
    "engineering/wizard": "run_wizard",
    "productivity/grilling": 'Word each question so "yes" accepts your recommended answer',
    "productivity/handoff": "the temporary directory of the user's OS",
    "productivity/teach": "resolve from the directory",
    "productivity/wait-what": "GLOSSARY-MAP.md",
}


class Violation(Exception):
    """A single failing invariant."""


def fail(message: str) -> None:
    raise Violation(message)


def require_string(value: object, field: str) -> str:
    if not isinstance(value, str) or not value.strip():
        fail(f"{field} must be a non-empty string")
    return value


def require_commit(value: object, field: str) -> str:
    text = require_string(value, field)
    if not COMMIT_RE.fullmatch(text):
        fail(f"{field} must be a full lowercase Git commit")
    return text


def duplicates(values: list[str]) -> list[str]:
    seen: set[str] = set()
    repeated: set[str] = set()
    for value in values:
        if value in seen:
            repeated.add(value)
        seen.add(value)
    return sorted(repeated)


def load_selection(path: Path) -> dict:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError) as error:
        fail(f"cannot read selection metadata: {error}")


def validate_metadata(meta: dict) -> None:
    if meta.get("schemaVersion") != 1:
        fail("schemaVersion must be 1")
    require_string(meta.get("repository"), "repository")
    for field in ("comparedCommit", "resolvedTagCommit", "latestCheckedCommit"):
        require_commit(meta.get(field), field)
    require_string(meta.get("comparisonTag"), "comparisonTag")

    for field in ("selected", "excluded", "deletedUpstream", "localOnly"):
        if not isinstance(meta.get(field), list):
            fail(f"{field} must be an array")
    if not meta["selected"]:
        fail("selected must be non-empty")

    for label in ("selected", "excluded", "deletedUpstream", "localOnly"):
        for index, item in enumerate(meta[label]):
            if not isinstance(item, dict):
                fail(f"{label}[{index}] must be an object")

    for index, item in enumerate(meta["selected"]):
        for field in ("upstreamSkill", "upstreamPath", "upstreamInvocation", "localSkill"):
            require_string(item.get(field), f"selected[{index}].{field}")
        if item["upstreamInvocation"] not in {"model", "user"}:
            fail(f"selected[{index}].upstreamInvocation must be model or user")
        expected = f"skills/{item['upstreamPath'].split('/')[1]}/{item['upstreamSkill']}/SKILL.md"
        if item["upstreamPath"] != expected:
            fail(f"selected[{index}] upstream path does not match its skill name")
        if not (SKILLS_DIR / item["localSkill"] / "SKILL.md").is_file():
            fail(f"selected[{index}].localSkill has no SKILL.md: {item['localSkill']}")

    for index, item in enumerate(meta["excluded"]):
        for field in ("upstreamSkill", "upstreamPath", "reason"):
            require_string(item.get(field), f"excluded[{index}].{field}")
        if item["upstreamPath"].split("/")[-2] != item["upstreamSkill"]:
            fail(f"excluded[{index}] upstream path does not match its skill name")

    local_only = {item["localSkill"] for item in meta["localOnly"]}
    for index, item in enumerate(meta["deletedUpstream"]):
        for field in ("upstreamSkill", "upstreamPath", "preservedLocalSkill", "reason"):
            require_string(item.get(field), f"deletedUpstream[{index}].{field}")
        expected = f"skills/{item['upstreamPath'].split('/')[1]}/{item['upstreamSkill']}/SKILL.md"
        if item["upstreamPath"] != expected:
            fail(f"deletedUpstream[{index}] upstream path does not match its skill name")
        local = item["preservedLocalSkill"]
        if local not in local_only:
            fail(f"deletedUpstream[{index}].preservedLocalSkill is not in localOnly: {local}")
        if not (SKILLS_DIR / local / "SKILL.md").is_file():
            fail(f"deletedUpstream[{index}].preservedLocalSkill has no SKILL.md: {local}")

    for index, item in enumerate(meta["localOnly"]):
        require_string(item.get("localSkill"), f"localOnly[{index}].localSkill")
        require_string(item.get("reason"), f"localOnly[{index}].reason")
        if not (SKILLS_DIR / item["localSkill"] / "SKILL.md").is_file():
            fail(f"localOnly[{index}].localSkill has no SKILL.md: {item['localSkill']}")

    all_upstream = meta["selected"] + meta["excluded"] + meta["deletedUpstream"]
    for label, values in [
        ("upstream skill", [i.get("upstreamSkill", "") for i in all_upstream]),
        ("upstream path", [i.get("upstreamPath", "") for i in all_upstream]),
        ("local skill", [i.get("localSkill", "") for i in meta["selected"] + meta["localOnly"]]),
    ]:
        repeated = duplicates(values)
        if repeated:
            fail(f"duplicate {label}: {', '.join(repeated)}")


def validate_manifest(registered: set[str], meta: dict) -> None:
    """Every registered path resolves, is classified, and matches the
    selection metadata's `registered` flags.
    """
    try:
        manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    except (OSError, ValueError) as error:
        fail(f"cannot read plugin.json: {error}")
    paths = manifest.get("skills", [])
    if not isinstance(paths, list) or not paths:
        fail("plugin.json skills must be a non-empty array")
    for path in paths:
        if not (PLUGIN_DIR / path / "SKILL.md").is_file():
            fail(f"registered skill has no SKILL.md: {path}")
    names = [str(Path(path).name) for path in paths]
    repeated = duplicates(names)
    if repeated:
        fail(f"duplicate registered skill: {', '.join(repeated)}")
    unclassified = set(names) - registered
    if unclassified:
        fail(f"registered skills missing from selection metadata: {', '.join(sorted(unclassified))}")

    flagged = {item["localSkill"].split("/")[-1] for item in meta["selected"]
               if item.get("registered") is True}
    for item in meta["selected"]:
        if "registered" in item and not isinstance(item["registered"], bool):
            fail(f"selected localSkill {item['localSkill']}: registered must be a boolean")
    wrong = flagged - set(names)
    if wrong:
        fail(f"selection metadata marks unregistered skills as registered: {', '.join(sorted(wrong))}")
    missing_flag = (set(names) - flagged) - {
        item["localSkill"].split("/")[-1] for item in meta["localOnly"]
    }
    if missing_flag:
        fail(f"plugin.json registers skills not flagged in selection metadata: "
             f"{', '.join(sorted(missing_flag))}")


def strip_code(text: str) -> str:
    """Remove fenced and inline code: example trees and snippet links are not real links."""
    text = re.sub(r"^```.*?^```", "", text, flags=re.S | re.M)
    return re.sub(r"`[^`\n]*`", "", text)


def validate_references(registered: set[str]) -> int:
    """Check namespaced commands, bare skill refs and relative links.
    Returns the link count.
    """
    checked_links = 0
    bare_re = re.compile(r"(?<![\w:/.])(/)([a-z][a-z0-9-]*)(?![\w/])")
    all_names = registered | {
        item.split("/")[-1] for item in registered
    }
    suffixes = (".md", ".sh", ".yaml", ".yml", ".json", ".cjs", ".ts", ".py")
    for skill_file in sorted(path for path in SKILLS_DIR.rglob("*")
                             if path.is_file() and path.suffix in suffixes):
        text = skill_file.read_text(encoding="utf-8", errors="replace")
        for name in NAMESPACED_RE.findall(text):
            if name not in registered:
                fail(f"{skill_file.relative_to(PLUGIN_DIR)}: /mattpocock:{name} is not registered")
        for match in bare_re.finditer(text):
            name = match.group(2)
            if name in BUILTIN_COMMANDS or name in {"tmp", "tmpdir"}:
                continue
            # A bare reference is only a defect when it names one of this
            # plugin's skills and is not part of a namespaced command.
            if name not in registered:
                continue
            before = text[max(0, match.start() - 12):match.start()]
            if "mattpocock:" in before or "://" in before:
                continue
            fail(f"{skill_file.relative_to(PLUGIN_DIR)}: bare /{name} reference "
                 f"to a registered skill (use /mattpocock:{name})")
        prose = strip_code(text)
        for target in LINK_RE.findall(prose):
            target = target.strip()
            if not target or target.startswith(("http://", "https://", "#", "mailto:")):
                continue
            target = target.split("#", 1)[0].split(" ", 1)[0]
            if not target:
                continue
            resolved = (skill_file.parent / target).resolve()
            if not resolved.is_file():
                fail(f"{skill_file.relative_to(PLUGIN_DIR)}: broken link {target}")
            checked_links += 1
    return checked_links


def validate_deny_list() -> None:
    """Reject host-specific syntax and stale domain-file names.
    The one legitimate CONTEXT.md mention is the setup skill's legacy migration.
    """
    suffixes = (".md", ".sh", ".yaml", ".yml", ".json", ".cjs", ".ts", ".py")
    for skill_file in sorted(p for p in SKILLS_DIR.rglob("*")
                             if p.is_file() and p.suffix in suffixes):
        text = skill_file.read_text(encoding="utf-8", errors="replace")
        for pattern, label in DENY_PATTERNS:
            if re.search(pattern, text):
                fail(f"{skill_file.relative_to(PLUGIN_DIR)}: {label} ({pattern})")
        legacy = re.findall(r"CONTEXT(?:-MAP|-FORMAT)?\.md", text)
        allowed = ("setup-matt-pocock-skills/SKILL.md" in str(skill_file)
                   and len(legacy) == 2 and "legacy" in text)
        if legacy and not allowed:
            fail(f"{skill_file.relative_to(PLUGIN_DIR)}: stale CONTEXT*.md "
                 f"reference ({', '.join(sorted(set(legacy)))})")

    setup = SKILLS_DIR / "engineering" / "setup-matt-pocock-skills" / "SKILL.md"
    if setup.is_file() and "legacy `CONTEXT.md` / `CONTEXT-MAP.md`" not in setup.read_text(encoding="utf-8"):
        fail("setup-matt-pocock-skills/SKILL.md lost its legacy CONTEXT.md migration line")


def git(upstream: Path, *args: str) -> str:
    try:
        result = subprocess.run(
            ["git", "-C", str(upstream), *args],
            capture_output=True, text=True, check=True,
        )
        return result.stdout.strip()
    except (OSError, subprocess.CalledProcessError) as error:
        fail(f"could not inspect upstream Git revision: {error}")


EXPECTED_BASELINE = "c55ee46073ed923f86ce59a5eb3b6d895095d1b7"


def validate_upstream_revisions(meta: dict, upstream: Path) -> None:
    head = git(upstream, "rev-parse", "HEAD")
    if head != meta["latestCheckedCommit"]:
        fail(f"upstream HEAD is {head}, metadata latestCheckedCommit is {meta['latestCheckedCommit']}")
    # comparedCommit must be the recorded baseline, not merely any valid commit.
    if meta["comparedCommit"] != EXPECTED_BASELINE:
        fail(f"comparedCommit {meta['comparedCommit']} is not the recorded "
             f"fork baseline {EXPECTED_BASELINE}; update EXPECTED_BASELINE deliberately")
    compared = git(upstream, "rev-parse", f"{meta['comparedCommit']}^{{commit}}")
    if compared != meta["comparedCommit"]:
        fail(f"comparedCommit does not resolve to itself: {compared}")
    # The baseline must be an ancestor of the reviewed HEAD, or the diff is meaningless.
    try:
        subprocess.run(["git", "-C", str(upstream), "merge-base", "--is-ancestor",
                        meta["comparedCommit"], "HEAD"], capture_output=True, text=True, check=True)
    except subprocess.CalledProcessError:
        fail(f"comparedCommit {meta['comparedCommit']} is not an ancestor of upstream HEAD")
    tag_commit = git(upstream, "rev-parse", f"{meta['comparisonTag']}^{{commit}}")
    if tag_commit != meta["resolvedTagCommit"]:
        fail(f"{meta['comparisonTag']} resolves to {tag_commit}, "
             f"metadata resolvedTagCommit is {meta['resolvedTagCommit']}")


def compare_upstream(meta: dict, upstream: Path) -> dict:
    validate_upstream_revisions(meta, upstream)
    declared = {item["upstreamPath"] for item in meta["selected"] + meta["excluded"]}
    for item in meta["selected"] + meta["excluded"]:
        source = upstream / item["upstreamPath"]
        if not source.is_file():
            fail(f"declared upstream skill not found: {item['upstreamPath']}")
        text = source.read_text(encoding="utf-8")
        match = re.match(r"^---\s*\n(.*?)\n---", text, re.S)
        if not match:
            fail(f"upstream SKILL.md has no frontmatter: {item['upstreamPath']}")
        frontmatter = match.group(1)
        name = re.search(r'^name:\s*["\']?([^"\'\n]+)', frontmatter, re.M)
        if not name or name.group(1).strip() != item["upstreamSkill"]:
            fail(f"{item['upstreamPath']} declares name {name.group(1).strip() if name else '?'}")
        invocation = "user" if re.search(r"^disable-model-invocation:\s*true", frontmatter, re.M) else "model"
        if item.get("upstreamInvocation") and invocation != item["upstreamInvocation"]:
            fail(f"{item['upstreamPath']} invocation is {invocation}, metadata says {item['upstreamInvocation']}")

    found = {
        str(path.relative_to(upstream)).replace(os.sep, "/")
        for path in (upstream / "skills").rglob("SKILL.md")
    }
    undeclared = found - declared
    missing = declared - found
    if undeclared:
        fail(f"unclassified upstream skills: {', '.join(sorted(undeclared))}")
    if missing:
        fail(f"declared upstream skills not found: {', '.join(sorted(missing))}")
    for item in meta["deletedUpstream"]:
        if (upstream / item["upstreamPath"]).exists():
            fail(f"deletedUpstream skill still exists at HEAD: {item['upstreamPath']}")

    exact = adapted = 0
    for item in meta["selected"]:
        upstream_body = (upstream / item["upstreamPath"]).read_text(encoding="utf-8")
        local_body = (SKILLS_DIR / item["localSkill"] / "SKILL.md").read_text(encoding="utf-8")
        upstream_body = re.sub(r"^---\s*\n.*?\n---\s*\n?", "", upstream_body, flags=re.S).strip()
        local_body = re.sub(r"^---\s*\n.*?\n---\s*\n?", "", local_body, flags=re.S).strip()
        if upstream_body == local_body:
            exact += 1
            continue
        adapted += 1
        # A gutted local body must fail. Adaptations are expected to keep the
        # upstream methodology, so require a substantial overlap of distinctive
        # lines (long, non-heading prose) between the two bodies.
        def distinctive(text: str) -> set[str]:
            return {line.strip() for line in text.splitlines()
                    if len(line.strip()) >= 60 and not line.lstrip().startswith("#")}
        up_lines = distinctive(upstream_body)
        local_lines = distinctive(local_body)
        if len(up_lines) >= 5:
            overlap = len(up_lines & local_lines) / len(up_lines)
            if overlap < 0.2 and len(local_lines) < len(up_lines) * 0.5:
                fail(f"{item['localSkill']}: SKILL.md body appears gutted "
                     f"(upstream line overlap {overlap:.0%}); this is more than an adaptation")

    return {"upstreamSkills": len(found), "content": {"exact": exact, "adapted": adapted}}


def check_content_absorption() -> dict:
    """Verify the distinctive behavioral fixes introduced upstream since the
    recorded baseline are present in the fork. This reads only local files, so
    it runs in BOTH offline and --upstream modes. Structural prose rewrites are
    excluded: those are merged by hand, not by line matching.
    """
    missing: list[str] = []
    checked = 0
    for local, phrase in CONTENT_FIX_MARKERS.items():
        target = (SKILLS_DIR / local) if local.endswith(".md") else (SKILLS_DIR / local / "SKILL.md")
        if not target.is_file():
            missing.append(f"{local}: SKILL.md missing")
            continue
        checked += 1
        if phrase not in target.read_text(encoding="utf-8"):
            missing.append(f"{local}: missing upstream fix {phrase!r}")
    if missing:
        fail("upstream content not absorbed:\n  " + "\n  ".join(missing))
    return {"checkedContentFixes": checked, "missing": 0}


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Verify the mattpocock fork against its recorded upstream revision.",
    )
    parser.add_argument("--upstream", help="path to an already-cloned mattpocock/skills checkout")
    parser.add_argument("--selection", type=Path, default=SELECTION_PATH,
                        help="path to upstream-selection.json")
    args = parser.parse_args()

    try:
        meta = load_selection(args.selection)
        validate_metadata(meta)
        classified = {item["localSkill"].split("/")[-1]
                      for item in meta["selected"] + meta["localOnly"]}
        validate_manifest(classified, meta)
        # Namespaced slash commands must resolve to a skill actually registered
        # in plugin.json, not merely to a mirrored-but-unregistered skill.
        manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
        registered = {str(Path(path).name) for path in manifest["skills"]}
        checked_links = validate_references(registered)
        validate_deny_list()
        absorption = check_content_absorption()
        comparison: dict = {}
        if args.upstream:
            upstream = Path(args.upstream).resolve()
            if not (upstream / "skills").is_dir():
                fail(f"--upstream is not a skills checkout: {upstream}")
            comparison = compare_upstream(meta, upstream)
        report = {
            "ok": True,
            "upstreamCompared": bool(args.upstream),
            "selected": len(meta["selected"]),
            "excluded": len(meta["excluded"]),
            "deletedUpstream": len(meta["deletedUpstream"]),
            "localOnly": len(meta["localOnly"]),
            "classifiedLocalSkills": len(classified),
            "registeredSkills": len(registered),
            "checkedLinks": checked_links,
            "contentAbsorption": absorption,
            **comparison,
        }
        print(json.dumps(report, sort_keys=True))
        return 0
    except (Violation, TypeError, AttributeError, KeyError, OSError) as error:
        print(f"invalid selection metadata or plugin state: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
