---
name: use-git-agent
description: Operates the git-agent CLI — commits, init, config, and provider setup via ~/.config/git-agent/config.yml or git config. Provider CLI overrides belong in exception flows only. Use whenever the user mentions git-agent, wants to commit/init, or needs to configure a provider.
---

# Git Agent CLI

When this skill is loaded, determine the appropriate git-agent command from the conversation context. Do **not** default to `git-agent commit` — ask or infer what the user needs.

## Commit workflow

1. **Intent** — derive a one-sentence intent from the conversation. If no signal exists, run `git diff --stat` to understand what changed, then form the intent from that.

2. **Commit** — run:
   ```
   git-agent commit --intent "..."
   ```
   No provider flags on the first attempt.

3. **On auth error (401 / missing key)** — retry once with `--free`:
   ```
   git-agent commit --intent "..." --free
   ```

4. **If `--free` also fails** — guide the user to create `~/.config/git-agent/config.yml`:
   ```yaml
   base_url: https://api.openai.com/v1
   api_key: sk-...
   model: gpt-4o
   ```
   Other supported providers: Cloudflare Workers AI, local Ollama.

## Useful flags

| Flag | When to use |
|---|---|
| `--dry-run` | User wants to preview the message without committing |
| `--no-stage` | User has already staged specific files and doesn't want auto-staging |
| `--amend` | User wants to rewrite the most recent commit message |
| `--intent "..."` | Always set — keeps generated messages focused |
| `--co-author "Name <email>"` | Attribute a co-author (repeatable); skipped if `no_model_co_author` is set in config |
| `--trailer "Key: Value"` | Add an arbitrary git trailer (repeatable) |
| `--no-attribution` | Omit the default `Co-Authored-By: Git Agent` trailer |
| `--max-diff-lines N` | Cap diff size sent to the model (0 = no limit) |

`--amend` and `--no-stage` are mutually exclusive.

## Multi-commit splitting

git-agent automatically splits staged changes into multiple atomic commits (up to 5 groups) when the AI planner detects logically distinct changes. Each group is staged, committed, and hook-validated separately. No user action is needed — this is the default behavior.

## Auto-scope

If no scopes are configured for the project, git-agent generates scopes from git history automatically before planning. Each scope is a structured object with a `name` and an optional `description` (used as LLM context during commit message generation). To trigger scope generation manually: `git-agent init --scope`.

## Hook failures

If the commit is blocked (exit code `2`), retry with a more specific `--intent`:

```
git-agent commit --intent "update module path"
```

Hook exit codes: `0` = allow, non-zero = block.

## Commit format

```
<type>(<scope>): <description>

- <Bullet one>
- <Bullet two>

<Explanation paragraph>

Co-Authored-By: Git Agent <noreply@git-agent.dev>
```

- Title: lowercase, <=50 chars, no period
- Bullets: uppercase first letter, imperative mood, <=72 chars per bullet; LLM generates as a JSON array — trailers never enter LLM context
- Explanation: required, sentence case; lines >100 chars are wrapped to ~72 chars
- Terminal output shows only the explanation paragraph (bullets appear in the git commit body but not in the CLI output)

## Other commands

| Command | What it does |
|---|---|
| `git-agent init` | Initialize git-agent in a repo (generates scopes, .gitignore, installs hooks) |
| `git-agent init --scope` | Regenerate scopes only |
| `git-agent config show` | Show resolved provider configuration |
| `git-agent config set <key> <value>` | Set a config value (auto-selects scope) |
| `git-agent config get <key>` | Show a config value and its source scope |
| `git-agent completion <shell>` | Generate shell completions (bash/zsh/fish/powershell) |
| `git-agent version` | Print build version |

## CLI reference

Full command reference (all flags, subcommands, config scopes, hook types): [references/cli.md](references/cli.md)
