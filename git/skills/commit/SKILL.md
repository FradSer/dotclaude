---
name: commit
description: Creates a conventional git commit using git-agent. This skill should be used when the user requests "commit", "git commit", "create commit", or wants to commit staged and unstaged changes following the conventional commits format. CRITICAL contract — the calling AI MUST auto-fill the argument with its own co-author string in the form `<model> <noreply@anthropic.com>` (e.g., `Claude Opus 4.7 <noreply@anthropic.com>`) using its own runtime model identity; the skill passes it through verbatim to `--co-author`. If the argument is somehow empty, the executor self-derives from its own model identity rather than running without a co-author.
user-invocable: true
model: haiku
argument-hint: <co-author>
allowed-tools: ["Bash(git-agent:*)", "Bash(git:*)"]
---

CRITICAL:
- Do NOT run `git status`, `git diff`, `git log`, or any other commands before `git-agent commit`.
- The calling AI MUST auto-fill `$ARGUMENTS` with its own co-author string `<model> <noreply@anthropic.com>` (e.g., `Claude Opus 4.7 <noreply@anthropic.com>`) at invocation time — `argument-hint: <co-author>` documents this. The skill always passes `$ARGUMENTS` through verbatim as `--co-author "$ARGUMENTS"`; never drop the flag, never run with an empty co-author.

1. Derive a one-sentence intent from the conversation.
2. If `$ARGUMENTS` is empty or whitespace (caller forgot to auto-fill), self-derive `<your-running-model> <noreply@anthropic.com>` from your own runtime identity (e.g., `Claude Haiku 4.5 <noreply@anthropic.com>`) and use it as `$ARGUMENTS`.
3. Run: `git-agent commit --intent "<intent>" --co-author "$ARGUMENTS"`
4. On auth error (401), retry the same command with `--free` appended; keep the `--co-author` flag.
5. Fallback (binary unavailable): manual `git commit` with Conventional Commits format via HEREDOC, including a `Co-Authored-By: $ARGUMENTS` trailer in the message body.

CLI reference: `${CLAUDE_PLUGIN_ROOT}/references/cli.md`
