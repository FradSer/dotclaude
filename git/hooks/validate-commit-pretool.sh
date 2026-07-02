#!/usr/bin/env bash
#
# PreToolUse hook — redirect bare `git commit` / `git add` to the /git:commit skill.
#
# Background: Claude Code's built-in commit flow (status -> diff -> add -> commit) takes
# priority over single-line CLAUDE.md instructions. Without this hook the agent runs the
# built-in flow instead of the /git:commit skill. This hook intercepts the Bash call and
# denies it with a message pointing at the skill.
#
# Allowed exceptions:
#   1. `git add <path> && git-agent commit ...` chained in one command — scoped staging
#      for `git-agent commit --no-stage` (superpowers/gitflow folder commits).
#   2. The GIT_SKILL_FALLBACK=1 marker — the /git:commit skills' manual fallback.
#
# Matching is textual and anchors subcommands to a command position (start of string or
# physical line, or after ;/&/|). Quoted mentions ("document git commit behavior") do
# not match. Tokenizer-level evasion (sh -c, xargs, `git -c k=v commit`) is out of
# scope — this is a guardrail against the habitual built-in flow, not a security boundary.
#
# Input (stdin JSON): { "tool_name": "Bash", "tool_input": { "command": "..." }, ... }
# Deny convention (current preferred): exit 0 + JSON on stdout
#   { "hookSpecificOutput": { "hookEventName": "PreToolUse",
#       "permissionDecision": "deny", "permissionDecisionReason": "..." } }
#
# Reference: https://code.claude.com/docs/en/hooks (PreToolUse)

set -uo pipefail

input=$(</dev/stdin)

# Fast path: this hook runs on every Bash tool call — if the raw JSON contains no `git`
# substring anywhere, the command cannot either. Zero forks for the common case.
case "$input" in
  *git*) ;;
  *) exit 0 ;;
esac

# Extract the command. Prefer jq; fall back to a tolerant grep so a missing jq never
# blocks legitimate work (fail open — allow the call rather than deny on parse error).
if command -v jq >/dev/null 2>&1; then
  cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || true)
else
  cmd=$(printf '%s' "$input" | grep -oE '"command"[[:space:]]*:[[:space:]]*"([^"\\]|\\.)*"' | head -1 \
    | sed -E 's/.*"command"[[:space:]]*:[[:space:]]*"(.*)"/\1/' || true)
fi

[ -z "$cmd" ] && exit 0

deny() {
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$1"
  exit 0
}

# Escape hatch: the /git:commit and /git:commit-and-push skills prefix their manual
# fallback (git-agent binary unavailable) with the GIT_SKILL_FALLBACK=1 marker. The
# marker is documented only inside those skills — the built-in commit flow never
# carries it — and the deny messages below must not reveal it.
MARKER='(^|[;&|[:space:]])GIT_SKILL_FALLBACK=1([;&|[:space:]]|$)'
[[ $cmd =~ $MARKER ]] && exit 0

# Command position: start of string or physical line, or after ;/&/|, then optional
# whitespace and optional NAME=value env-assignment prefixes (`VAR=1 git commit` is
# still an invocation). Bash =~ anchors ^ at string start only, so the class carries
# a literal newline for continuation lines; END keeps subcommand tokens whole.
POS=$'(^|[;&|\n])[[:space:]]*([A-Za-z_][A-Za-z_0-9]*=[^[:space:]]*[[:space:]]+)*'
END='([;&|[:space:]]|$)'

# Raw `git commit` at a command position is always denied — commit creation belongs to
# the /git:commit skill (or git-agent).
RE_COMMIT="${POS}git[[:space:]]+commit${END}"
if [[ $cmd =~ $RE_COMMIT ]]; then
  deny "Use the /git:commit skill (via the Skill tool) instead of raw git add/git commit. It stages changes and generates a conventional commit message."
fi

# `git add` at a command position is denied unless the same command chains a
# `git-agent commit` invocation (also at a command position) — scoped staging for
# `git-agent commit --no-stage`, not the built-in flow. A `git-agent commit` that only
# appears as an argument or comment (`echo git-agent commit`) does not lift the deny.
RE_ADD="${POS}git[[:space:]]+add${END}"
RE_AGENT="${POS}git-agent[[:space:]]+commit${END}"
if [[ $cmd =~ $RE_ADD ]] && ! [[ $cmd =~ $RE_AGENT ]]; then
  deny "Use the /git:commit skill (via the Skill tool) instead of raw git add. For folder-scoped staging, chain it with git-agent in one command: git add <path> && git-agent commit --no-stage ..."
fi

exit 0
