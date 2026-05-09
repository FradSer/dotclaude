---
name: commit-and-push
description: Creates conventional git commits using git-agent and pushes to the remote repository. This skill should be used when the user asks to "commit and push", "push my changes", or wants to commit and immediately push to remote. The executing AI auto-derives its own co-author string from its runtime model identity (e.g., `Claude Opus 4.7 <noreply@anthropic.com>`) and passes it to `--co-author`. `$ARGUMENTS`, if provided, overrides the auto-derived value.
user-invocable: true
argument-hint: <co-author>
allowed-tools: ["Bash(git-agent:*)", "Bash(git:*)"]
---

CRITICAL:
- Do NOT run `git status`, `git diff`, `git log`, or any other commands before `git-agent commit`.
- Always pass `--co-author` to `git-agent commit`. If `$ARGUMENTS` is non-empty, use it verbatim. Otherwise self-derive from your own runtime model identity (the model named in your own system prompt) plus `<noreply@anthropic.com>` — e.g., `Claude Opus 4.7 <noreply@anthropic.com>`. Never run a commit without `--co-author`.

1. Derive a one-sentence intent from the conversation.
2. Resolve `<co-author>`: if `$ARGUMENTS` is non-empty use it verbatim; otherwise build `<your-running-model> <noreply@anthropic.com>` from your own runtime identity.
3. Run: `git-agent commit --intent "<intent>" --co-author "<co-author>"`
4. On auth error (401), retry the same command with `--free` appended; keep the `--co-author` flag.
5. Fallback (binary unavailable): manual `git commit` with Conventional Commits format via HEREDOC, including a `Co-Authored-By: <co-author>` trailer in the message body.
6. `git push` (add `-u origin <branch>` if upstream not set).

CLI reference: `${CLAUDE_PLUGIN_ROOT}/references/cli.md`
