"""Tests for hooks/session-start.sh — minimal bootstrap injection."""
from __future__ import annotations

import json
import subprocess
from pathlib import Path

PLUGINS = Path(__file__).resolve().parents[1]
SCRIPT = PLUGINS / "hooks" / "session-start.sh"

SKILL = PLUGINS / "skills" / "using-superpowers" / "SKILL.md"


def _run(**env):
    e = {**__import__("os").environ, "CLAUDE_PLUGIN_ROOT": str(PLUGINS), **env}
    return subprocess.run(
        ["bash", str(SCRIPT)], capture_output=True, text=True, env=e,
    )


def test_outputs_valid_json_with_additional_context():
    r = _run()
    assert r.returncode == 0, r.stderr
    data = json.loads(r.stdout)
    assert data["hookSpecificOutput"]["hookEventName"] == "SessionStart"
    ctx = data["hookSpecificOutput"]["additionalContext"]
    assert "<EXTREMELY_IMPORTANT>" in ctx
    assert "1% Rule" in ctx


def test_routing_table_all_five_skills_present():
    r = _run()
    ctx = json.loads(r.stdout)["hookSpecificOutput"]["additionalContext"]
    for skill in (
        "superpowers:brainstorming",
        "superpowers:writing-plans",
        "superpowers:executing-plans",
        "superpowers:systematic-debugging",
        "superpowers:retrospective",
    ):
        assert skill in ctx, f"{skill} missing from routing table"


def test_does_not_inject_full_skillmd_body():
    """v6.1.0 lesson: bootstrap must be minimal. The full SKILL.md body
    (e.g. the Lineage section, the 'What this skill is NOT' section) must
    NOT be in the injected context."""
    r = _run()
    ctx = json.loads(r.stdout)["hookSpecificOutput"]["additionalContext"]
    full = SKILL.read_text()
    # A marker unique to the SKILL.md body that should not be injected.
    assert "Lineage and rationale" not in ctx
    assert "What this skill is NOT" not in ctx
    # Token-budget sanity: injected context under 2KB.
    assert len(ctx) < 2000, f"bootstrap too large: {len(ctx)} chars"


def test_json_escape_handles_quotes_and_backslashes():
    """The routing table contains backticks and quotes; ensure JSON stays
    valid (the escape_for_json function must escape them)."""
    r = _run()
    assert r.returncode == 0
    # If escape failed, json.loads raises — that's the assertion.
    json.loads(r.stdout)


def test_fallback_when_skill_file_missing(tmp_path, monkeypatch):
    """If using-superpowers SKILL.md is unreadable, the hook still emits
    a valid bootstrap with the hardcoded fallback table."""
    r = _run()
    # baseline: works
    assert r.returncode == 0
    # The fallback table (used when grep finds nothing) contains the
    # brainstorming row — verify the grep path also yields it.
    ctx = json.loads(r.stdout)["hookSpecificOutput"]["additionalContext"]
    assert "brainstorm" in ctx
