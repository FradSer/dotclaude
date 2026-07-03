#!/usr/bin/env bash
# SessionStart hook for the superpowers plugin (Claude Code only).
#
# Injects a MINIMAL bootstrap — the 1% Rule one-liner plus the routing table
# extracted from skills/using-superpowers/SKILL.md — so every fresh session /
# clear / compact knows the skill library exists. v6.1.0 upstream lesson:
# bootstrap must be compressed to reduce startup token cost. We inject the
# routing table only, NOT the full SKILL.md body. The full body loads on demand
# via the Skill tool when a trigger fires.
#
# Output: Claude Code hookSpecificOutput.additionalContext JSON.
# (No Cursor/Codex/Copilot fan-out — this fork targets Claude Code only.)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

USING_SKILL="${PLUGIN_ROOT}/skills/using-superpowers/SKILL.md"

# Extract the routing table DATA rows — lines beginning with "| " that cite a
# superpowers skill (skip the markdown header `| Trigger signal | Invoke |`
# and the `|---|---|` separator, which contain no skill name).
# Fall back to a hardcoded table if the skill file is missing or the table
# can't be found, so the hook never fails silently.
routing_table=""
if [ -f "$USING_SKILL" ]; then
  routing_table=$(grep -E '^\| .*superpowers:' "$USING_SKILL" || true)
fi

if [ -z "$routing_table" ]; then
  routing_table='| "brainstorm"/"design"/new feature idea | `superpowers:brainstorming` |
| "write a plan"/"decompose into tasks" | `superpowers:writing-plans` |
| "execute the plan"/"implement" | `superpowers:executing-plans` |
| Bug, error, test failure, "why does X happen" | `superpowers:systematic-debugging` |
| "run a retrospective"/"evolve checklists" | `superpowers:retrospective` |'
fi

# Build the bootstrap context (kept under ~250 tokens).
bootstrap=$(printf 'You have superpowers skills. The 1%% Rule: if there is even a 1%% chance one of the user-invocable superpowers skills is the right tool for the current request, invoke it explicitly via the Skill tool rather than improvising. Each skill has a Bail-Out Check that exits cheaply on trivial work — when in doubt, invoke.\n\nRouting table (loaded from using-superpowers SKILL.md):\n%s\n\nInvoke via the Skill tool, e.g. /superpowers:brainstorming. The full skill body loads on demand.' "$routing_table")

# Build session_context with REAL newlines (printf interprets \n). Using a
# double-quoted bash string would leave \n as literal backslash-n, which
# escape_for_json then doubles into a JSON \\n = literal backslash+n when
# consumed — the tags would sit on one line with stray \n text. printf is
# the single source of truth for newlines here.
session_context=$(printf '<EXTREMELY_IMPORTANT>\n%s\n</EXTREMELY_IMPORTANT>' "$bootstrap")

# Escape for JSON embedding using bash parameter substitution (no python dep).
escape_for_json() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\r'/\\r}"
  s="${s//$'\t'/\\t}"
  printf '%s' "$s"
}

escaped=$(escape_for_json "$session_context")

printf '{\n  "hookSpecificOutput": {\n    "hookEventName": "SessionStart",\n    "additionalContext": "%s"\n  }\n}\n' "$escaped"

exit 0
