#!/usr/bin/env python3
"""Audit skill/command/agent markdown for bare scripts/ paths that break when
the skill runs with its cwd in the target repo (not the plugin dir).

Background — the bug this catches:
  A skill's SKILL.md instructs the agent to run a bundled script. The skill's
  cwd is the user's project / the PR's repository, NOT the plugin directory, so
  a bare path like `scripts/review-loop.sh` or `Run scripts/batch-progress.sh`
  does not resolve and the agent reports "script doesn't exist in this repo".
  The fix is always ${CLAUDE_PLUGIN_ROOT}/... absolute plugin paths.

  The tricky part: the same text shape ("scripts/foo.sh" inside a code span) is
  ALSO legitimately used for (a) upstream mirrors whose paths are resolved by an
  external CLI at install time (hyperframes, impeccable), and (b) descriptive
  pointers in a References section ("- ./scripts/foo.sh - what it does"). A pure
  regex cannot tell these apart from real executable instructions, so this tool
  is advisory, not a gate: it surfaces every candidate for a human to judge.

Usage:
  python3 scripts/audit-bare-paths.py [plugin-dir ...]
  python3 scripts/audit-bare-paths.py .                  # whole marketplace
  python3 scripts/audit-bare-paths.py github superpowers # specific plugins

Exit code 0 always (advisory). Prints file:line:source for each candidate,
grouped by file, with a one-line reason.

This is the manual companion to the L2 path rule documented in
references/tool-invocations.md — run it after touching any skill that bundles a
script.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

# A bare plugin-relative script path inside a code span (backticks) or a
# line-leading command invocation. Matches `scripts/...` and `./scripts/...`
# and <project>/scripts/... style bare refs, but NOT ${CLAUDE_PLUGIN_ROOT}/...
BARE_IN_CODE = re.compile(r"`[^`]*\bscripts/[\w./-]+`")
LINE_LEADING_EXEC = re.compile(
    r"^\s*(?:[-*+]|\d+\.)?\s*(?:bash|node|python3?|sh|uv run)\s+(?:\.?/?scripts/)"
)
# Tokens that make a bare path safe — resolved by the platform or an external CLI.
SAFE = re.compile(
    r"\$\{?CLAUDE_PLUGIN_ROOT\}?|\$0|\$\(dirname|<SKILL_DIR>|<MEDIA_DIR>|<skill-base-dir>"
)
FENCE = re.compile(r"^\s*(```+|~~~+)")
REFS_HEADER = re.compile(r"^\s*#+\s*(References?|See Also)\b", re.IGNORECASE)
SKIP_DIRS = (".git", ".research", ".backup", "backup", "__pycache__", "node_modules")


def audit_file(path: Path) -> list[tuple[int, str, str]]:
    """Return [(line_no, snippet, reason)] for each suspect bare path."""
    findings: list[tuple[int, str, str]] = []
    try:
        lines = path.read_text().split("\n")
    except OSError:
        return findings

    in_fence = False
    fence_char = ""
    fence_len = 0
    in_refs = False

    for i, line in enumerate(lines, 1):
        stripped = line.strip()
        if not stripped:
            continue

        m = FENCE.match(stripped)
        if m:
            marker = m.group(1)
            if not in_fence:
                in_fence = True
                fence_char = marker[0]
                fence_len = len(marker)
            elif marker[0] == fence_char and len(marker) >= fence_len:
                in_fence = False
                fence_char = ""
                fence_len = 0
            continue

        if in_fence:
            continue

        if REFS_HEADER.match(stripped):
            in_refs = True
            continue

        # Descriptive pointers in a References section (e.g. "- ./scripts/x.sh
        # - what it does") are documentation, not executable instructions; skip.
        if in_refs:
            continue

        # Line-leading command + bare scripts/ path — highest signal.
        if LINE_LEADING_EXEC.match(line) and not SAFE.search(line):
            findings.append((i, stripped[:100], "line-leading command + bare scripts/ path"))
            continue

        # Bare scripts/ path inside a code span — needs human judgment: could be
        # a real executable instruction (bug) or a descriptive reference (ok).
        for m in BARE_IN_CODE.finditer(line):
            seg = m.group(0)
            if not SAFE.search(seg):
                snippet = stripped[:100]
                findings.append((i, snippet, "bare scripts/ path in code span (judge: exec vs desc)"))
                break

    return findings


def audit_tree(root: Path) -> dict[Path, list[tuple[int, str, str]]]:
    results: dict[Path, list[tuple[int, str, str]]] = {}
    for path in root.rglob("SKILL.md"):
        if any(part in SKIP_DIRS for part in path.parts):
            continue
        findings = audit_file(path)
        if findings:
            results[path] = findings
    # Also scan command/agent markdown (they can carry the same bug).
    for path in root.rglob("*.md"):
        if any(part in SKIP_DIRS for part in path.parts):
            continue
        if path.name not in ("command.md", "agent.md") and path.parent.name not in ("commands", "agents"):
            continue
        findings = audit_file(path)
        if findings:
            results.setdefault(path, findings)
    return results


def main(argv: list[str]) -> int:
    roots = [Path(a) for a in argv] or [Path(".")]
    total = 0
    for root in roots:
        if not root.exists():
            print(f"skip (missing): {root}", file=sys.stderr)
            continue
        results = audit_tree(root)
        if not results:
            print(f"{root}: no bare-path candidates")
            continue
        for path, findings in sorted(results.items()):
            try:
                rel = path.relative_to(Path(".").resolve())
            except ValueError:
                rel = path
            print(f"\n{rel}")
            for line_no, snippet, reason in findings:
                print(f"  {line_no}: [{reason}] {snippet}")
            total += len(findings)
    print(f"\n{total} candidate(s) — advisory only, judge each against its skill's cwd contract.")
    print("Real bug = executable instruction with bare path in a skill whose cwd is the target repo.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
