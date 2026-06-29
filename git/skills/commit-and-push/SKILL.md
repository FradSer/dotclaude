---
name: commit-and-push
description: Creates conventional git commits using git-agent and pushes to the remote repository. This skill should be used when the user asks to "commit and push", "push my changes", or wants to commit and immediately push to remote. The executing AI auto-derives its own co-author string from its runtime model identity (e.g., `Claude Opus 4.7 <noreply@anthropic.com>`, `GLM-4.5 <noreply@zhipuai.cn>`) and passes it to `--co-author`. `$ARGUMENTS`, if provided, overrides the auto-derived value.
user-invocable: true
argument-hint: <co-author>
allowed-tools: ["Bash(git-agent:*)", "Bash(git:*)"]
---

CRITICAL:
- Do NOT run `git status`, `git diff`, `git log`, or any other commands before `git-agent commit`.
- Always pass `--co-author` to `git-agent commit`. If `$ARGUMENTS` is non-empty, use it verbatim. Otherwise self-derive from your own runtime model identity: take the model identifier from your own system prompt, map it to a provider domain via the table below, and build `<Display Name> <noreply@<domain>>`. Never run a commit without `--co-author`.

1. Derive a one-sentence intent from the conversation.
2. Resolve `<co-author>`: if `$ARGUMENTS` is non-empty use it verbatim; otherwise pick the row below whose model-prefix matches the model named in your own system prompt, and build `<Display Name> <noreply@<domain>>` (e.g. `Claude Opus 4.7 <noreply@anthropic.com>`, `GLM-4.5 <noreply@zhipuai.cn>`).

   | Model prefix | Display Name | noreply domain |
   |---|---|---|
   | `claude-` / `Claude` (Fable/Opus/Sonnet/Haiku) | Claude <variant> | anthropic.com |
   | `gpt-` / `o1-` / `o3-` / `openai` | GPT <variant> | openai.com |
   | `gemini-` / `Gemini` | Gemini <variant> | google.com |
   | `glm-` / `GLM` / `chatglm` | GLM <variant> | zhipuai.cn |
   | `qwen` | Qwen <variant> | qwen.ai |
   | `deepseek` | DeepSeek <variant> | deepseek.com |
   | `moonshot` / `kimi` | Kimi <variant> | moonshot.ai |

   If the model name matches no row, default to `Claude <model-identifier> <noreply@anthropic.com>` (the host that runs this marketplace), using the raw model identifier as the display name, and proceed — do not block the commit on attribution ambiguity.
3. Run: `git-agent commit --intent "<intent>" --co-author "<co-author>"`
4. On auth error (401), retry the same command with `--free` appended; keep the `--co-author` flag.
5. Fallback (binary unavailable): manual `git commit` with Conventional Commits format via HEREDOC, including a `Co-Authored-By: <co-author>` trailer in the message body.
6. `git push` (add `-u origin <branch>` if upstream not set).

CLI reference: `${CLAUDE_PLUGIN_ROOT}/references/cli.md`
