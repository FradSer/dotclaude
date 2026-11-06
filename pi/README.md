# pi Plugin (Claude Code)

This is a **Claude Code plugin** (`@pi/` / `/pi:*`). It is **not** the pi coding agent itself.

It bridges [pi](https://github.com/earendil-works/pi) (dev/pi), a separate terminal coding harness, into Claude Code: resolve Claude-side settings, then run the `pi` CLI through `pi:pi-agent`.

| Layer | What it is | Config |
|-------|------------|--------|
| This plugin | Claude Code commands/agent that call pi | `.claude/pi*.json`, `~/.claude/pi.local.json` |
| pi CLI | External binary `@earendil-works/pi-coding-agent` | `~/.pi/agent/` (`settings.json`, packages, `models.json`) |

**Default clean mode:** bridge runs of `pi` pass `--no-extensions --no-skills`, so pi CLI packages under `~/.pi` do not load. That does not affect other Claude Code plugins. Opt in with `--with-packages` or `"withPackages": true`.

## Prerequisites

- [pi CLI](https://github.com/earendil-works/pi) installed globally:
  ```bash
  npm install -g @earendil-works/pi-coding-agent
  # or
  curl -fsSL https://pi.dev/install.sh | sh
  ```

## Usage

### `/pi:delegate` — Delegate a task to pi

```
/pi:delegate <task description> [--endpoint ENDPOINT] [--provider PROVIDER] [--model MODEL] [--api-key KEY] [--thinking LEVEL] [--tools TOOL_LIST] [--exclude-tools TOOL_LIST] [--no-git] [--with-packages]
```

**Examples:**

```
/pi:delegate refactor this component --model claude-sonnet-4-20250514
/pi:delegate write unit tests --endpoint local-proxy --model gemini-3.6-flash-high
/pi:delegate explain how React reconciliation works --no-git
```

### `/pi:delegate --edit-config` — Edit persistent settings

Opens or creates the settings file in your editor. Three scopes matching the three priority tiers:

| Scope | Command | Path | Git |
|-------|---------|------|-----|
| Project personal | `/pi:delegate --edit-config` (default) | `.claude/pi.local.json` | gitignored |
| Project shared | `/pi:delegate --edit-config --shared` | `.claude/pi.json` | tracked |
| Global personal | `/pi:delegate --edit-config --global` | `~/.claude/pi.local.json` | user home |

Project personal overrides project shared, which overrides global personal. CLI flags override all three.

### `/pi:review` — Review code with pi

Read-only code review via pi CLI. By default reviews uncommitted working-tree changes (`git diff HEAD`) with pi restricted to `--tools read` (it cannot explore the repo); explicit targets (`--branch`, `--diff`, `@file`, PR) or `--explore` widen it to `read,grep,find,ls`.

```
/pi:review [@target] [--branch BRANCH] [--diff RANGE] [--endpoint ENDPOINT] [--model MODEL] [--thinking LEVEL] [--with-packages] | --edit-config [--local|--shared|--global] | --list-models
```

**Examples:**

```
/pi:review                        Review uncommitted working-tree changes (git diff HEAD, read-only)
/pi:review --branch feat/new      Review diff against main
/pi:review --diff HEAD~5..HEAD    Review recent commits
/pi:review @src/index.ts          Review a specific file
/pi:review 42                     Review GitHub PR #42
/pi:review --endpoint local-proxy --model gemini-3.6-flash-high  Review with a specific endpoint/model
/pi:review --list-models          List all configured endpoints and models
/pi:review --edit-config          Edit review settings
```

### `/pi:setup` — Configure pi

Guides you through setting up pi's provider, model, and base URL. Human-only — never auto-invoked.

```
/pi:setup [--endpoint NAME] [--provider PROVIDER] [--model MODEL] [--base-url URL] [--api-key KEY] | --edit-config [--local|--shared|--global] | --list-models | --test
```

**Examples:**

```
/pi:setup --provider openai --model gemini-3.6-flash-high
/pi:setup --list-models              View current configuration
/pi:setup --test                     Test the current configuration
/pi:setup --edit-config              Edit configuration manually
```

After setup, both `/pi:delegate` and `/pi:review` will use these settings by default.

**Note:** Unlike `/pi:delegate`, pi's stdout IS the review output (read-only mode, no file edits).

## How It Works

Both `/pi:delegate` and `/pi:review` delegate execution to the dedicated `pi:pi-agent` — the plugin's single execution layer. It builds the pi command, runs it in the background (no timeout), and verifies the outcome.

### `/pi:delegate`

1. The skill checks if `pi` is installed globally.
2. It reads persistent settings from `.claude/pi.local.json` (project), `.claude/pi.json` (shared), and `~/.claude/pi.local.json` (global), then merges with CLI flags — using the same **named-endpoint format** as `/pi:review`. Legacy flat fields still work as a fallback.
3. It resolves the endpoint, then launches `pi:pi-agent` with the resolved provider/model and the task description.
4. `pi:pi-agent` collects context (CLAUDE.md, git status), writes custom base URLs to the agent-dir `models.json`, and calls `pi -p` (print mode) via `run_in_background`.
5. pi executes the task — its real output is **file edits in the working directory**, not stdout text. The agent verifies via `git diff --stat`.

### `/pi:review`

1. Same checks, settings chain, and endpoint format as `/pi:delegate`.
2. Supports `--list-models` to display all configured endpoints and their models.
3. Captures the review target (diff/branch/PR/file), then delegates to `pi:pi-agent`, which runs `pi -p` with `--tools read` (or `read,grep,find,ls` for explicit targets) — pi cannot edit files.
4. pi's stdout **is** the review output — the agent returns it and you present it directly to the user.

## Flags

| Flag | Description | Source Priority |
|------|-------------|-----------------|
| `--endpoint` | Endpoint key name (must match a key in settings `endpoints`) | CLI > settings > `defaultEndpoint` |
| `--provider` | LLM provider (anthropic, openai, google, etc.) | CLI > settings > endpoint/provider > pi's default |
| `--model` | Model pattern or ID | CLI > settings > pi's default |
| `--api-key` | API key for the provider | CLI > settings > env var or config file |
| `--thinking` | Thinking level (off/minimal/low/medium/high/xhigh/max) | CLI > settings > `max` |
| `--tools` | Comma-separated allowed tools list | CLI > settings > `read,bash,write,edit,grep,find,ls` |
| `--exclude-tools` | Comma-separated blocked tools list | CLI > settings > (none) |
| `--no-git` | Skip collecting git context | CLI > settings > `false` |
| `--with-packages` | Load global pi packages/skills/extensions (default clean mode: off) | CLI > settings `withPackages` > `false` |

## Persistent Settings

Three-tier JSON preference files (priority high to low):

| Priority | Scope | Path | Git |
|----------|-------|------|-----|
| 1 (highest) | Project personal | `.claude/pi.local.json` | gitignored by `**/.claude/*.local.*` |
| 2 | Project shared | `.claude/pi.json` | tracked |
| 3 (lowest) | Global personal | `~/.claude/pi.local.json` | user home, never committed |

CLI flags override all three. Run `/pi:delegate --edit-config` or `/pi:review --edit-config` to quickly create or edit your project settings.

Both skills share the same settings files **and the same named-endpoint format**:

```json
{
  "endpoints": {
    "local-proxy": {
      "provider": "openai",
      "baseUrl": "http://10.10.0.195:8317/v1",
      "models": ["gemini-3.6-flash-high", "gemini-3.6-pro"]
    }
  },
  "defaultEndpoint": "local-proxy",
  "defaultModel": "gemini-3.6-flash-high",
  "thinking": "max",
  "withPackages": false
}
```

Each endpoint has `provider` (required), optional `baseUrl`/`apiKey`, and a `models` array. `withPackages` defaults to false (clean mode); set it to `true` only when bridge tasks should load your interactive pi packages/skills. Both `/pi:delegate` and `/pi:review` resolve the active endpoint via `defaultEndpoint` (or a `--endpoint`/`--model` CLI flag), falling back to the first `models` entry when `defaultModel` is unset.

Values can reference environment variables using `$VAR` or `${VAR}` syntax — they are resolved at read time. This is useful for API keys: `"apiKey": "$MY_API_KEY"` reads from the environment variable at runtime.

Legacy flat fields (`provider`/`model`/`baseUrl`/`apiKey`) are still honored by `/pi:delegate` as a fallback when no `defaultEndpoint` is set, so old configs keep working — but new setups should use the endpoint format above.

## Design

- **Two entry points**: `/pi:delegate` for coding tasks (file edits), `/pi:review` for read-only code review.
- **Dedicated execution layer**: Both commands delegate to `pi:pi-agent`, which builds the pi command, runs it in the background, and verifies the outcome — the main context stays clean and the user never interacts with pi directly.
- **Unified config**: Both commands share the same named-endpoint settings format and the same settings chain.
- **Context-aware**: The skill collects file and git context from the current project.
- **Non-interactive**: All pi tasks run in `-p` (print) mode for clean, text-based output.
- **Isolated (default clean mode)**: Uses `--no-session --no-context-files --approve --no-extensions --no-skills` so interactive pi packages, extensions, and skills under `~/.pi` do not load. Pass `--with-packages` or set `"withPackages": true` to opt in.