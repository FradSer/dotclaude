# pi Plugin

Bridges [pi](https://github.com/earendil-works/pi) (dev/pi), a minimal terminal coding harness, into Claude Code. Delegates coding tasks to the `pi` CLI tool for execution.

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
/pi:delegate <task description> [--provider PROVIDER] [--model MODEL] [--api-key KEY] [--thinking LEVEL] [--tools TOOL_LIST] [--exclude-tools TOOL_LIST] [--no-files] [--no-git]
```

**Examples:**

```
/pi:delegate refactor this component --model claude-sonnet-4-20250514
/pi:delegate write unit tests --provider openai --model gemini-3.6-flash-high
/pi:delegate explain how React reconciliation works --no-files
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

Read-only code review via pi CLI. Runs pi with `--tools read,grep,find,ls` to prevent edits.

```
/pi:review [@target] [--branch BRANCH] [--diff RANGE] [--endpoint ENDPOINT] [--model MODEL] [--thinking LEVEL] | --edit-config [--local|--shared|--global] | --list-models
```

**Examples:**

```
/pi:review                        Review the whole working directory (pi uses its own tools to explore)
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
/pi:setup [--provider PROVIDER] [--model MODEL] [--api-key KEY] | --edit-config | --list-models | --test
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

### `/pi:delegate`

1. The skill checks if `pi` is installed globally.
2. It reads persistent settings from `.claude/pi.local.json` (project) and `~/.claude/pi.local.json` (global), then merges with CLI flags. Custom base URLs are configured via `~/.pi/agent/models.json` — written automatically by the skill when `baseUrl` is set in the config file.
3. It collects context from the current working directory (relevant files, git status, directory structure).
4. It calls `pi -p` (print mode) via `run_in_background` with the collected context and your task description. No timeout — pi tasks run to completion naturally.
5. pi executes the task — its real output is **file edits in the working directory**, not stdout text. Always check `git diff --stat` after completion.

### `/pi:review`

1. Same checks and settings chain as `/pi:delegate`, but uses a **multi-provider** settings format.
2. Supports `--list-models` to display all configured providers and their models.
3. Runs `pi -p` with `--tools read,grep,find,ls` (read-only) — pi cannot edit files.
4. pi's stdout **is** the review output — present it directly to the user.

## Flags

| Flag | Description | Source Priority |
|------|-------------|-----------------|
| `--provider` | LLM provider (anthropic, openai, google, etc.) | CLI > settings > pi's default |
| `--model` | Model pattern or ID | CLI > settings > pi's default |
| `--api-key` | API key for the provider | CLI > settings > env var or config file |
| `--thinking` | Thinking level (off/minimal/low/medium/high/xhigh/max) | CLI > settings > `low` |
| `--tools` | Comma-separated allowed tools list | CLI > settings > `read,bash,write,edit,grep,find,ls` |
| `--exclude-tools` | Comma-separated blocked tools list | CLI > settings > (none) |
| `--no-files` | Skip collecting file context | CLI > settings > `false` |
| `--no-git` | Skip collecting git context | CLI > settings > `false` |

## Persistent Settings

Three-tier JSON preference files (priority high to low):

| Priority | Scope | Path | Git |
|----------|-------|------|-----|
| 1 (highest) | Project personal | `.claude/pi.local.json` | gitignored by `**/.claude/*.local.*` |
| 2 | Project shared | `.claude/pi.json` | tracked |
| 3 (lowest) | Global personal | `~/.claude/pi.local.json` | user home, never committed |

CLI flags override all three. Run `/pi:delegate --edit-config` or `/pi:review --edit-config` to quickly create or edit your project settings.

Both skills share the same settings files, but use different formats:

- **`/pi:delegate`** uses flat format (single provider + model):
  ```json
  {
    "provider": "openai",
    "model": "gemini-3.6-flash-high",
    "baseUrl": "http://10.10.0.195:8317/v1"
  }
  ```

- **`/pi:review`** uses multi-endpoint format (named endpoints, each with `provider` + optional `baseUrl` + `models`):
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
    "defaultModel": "gemini-3.6-flash-high"
  }
  ```

Values can reference environment variables using `$VAR` or `${VAR}` syntax — they are resolved at read time. This is useful for API keys: `"apiKey": "$MY_API_KEY"` reads from the environment variable at runtime.

You can include both formats in the same file — the `jq` merge will combine them. The review skill reads `endpoints` and `defaultEndpoint`, while the delegate skill reads `provider` and `model`.

## Design

- **Two entry points**: `/pi:delegate` for coding tasks (file edits), `/pi:review` for read-only code review.
- **Context-aware**: The skill automatically collects file and git context from the current project.
- **Non-interactive**: All pi tasks run in `-p` (print) mode for clean, text-based output.
- **Isolated**: Uses `--no-session --no-context-files --approve` to avoid conflicts with the current project's state.