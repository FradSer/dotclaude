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
/pi:delegate <task description> [--provider PROVIDER] [--model MODEL] [--base-url URL] [--thinking LEVEL] [--tools TOOL_LIST] [--exclude-tools TOOL_LIST] [--no-files] [--no-git]
```

**Examples:**

```
/pi:delegate review the TypeScript types in src/
/pi:delegate refactor this component --model claude-sonnet-4-20250514
/pi:delegate write unit tests --base-url http://10.10.0.195:8317/v1 --model gemini-3.6-flash
/pi:delegate audit the security of this codebase --tools read,grep,find,ls
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

## How It Works

1. The skill checks if `pi` is installed globally.
2. It reads persistent settings from `.claude/pi.local.json` (project) and `~/.claude/pi.local.json` (global), then merges with CLI flags. `--base-url` writes to `~/.pi/agent/models.json` (pi's global provider config) — one-time setup per endpoint.
3. It collects context from the current working directory (relevant files, git status, directory structure).
4. It calls `pi -p` (print mode) with the collected context and your task description.
5. pi executes the task and returns the output.

## Flags

| Flag | Description | Source Priority |
|------|-------------|-----------------|
| `--provider` | LLM provider (anthropic, openai, google, etc.) | CLI > settings > `anthropic` |
| `--model` | Model pattern or ID | CLI > settings > (pi's default) |
| `--base-url` | Custom API base URL for OpenAI-compatible endpoint | CLI > settings > (none) |
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

CLI flags override all three. Run `/pi:delegate --edit-config` to quickly create or edit your project settings.

Example `.claude/pi.local.json`:

```json
{
  "provider": "anthropic",
  "model": "claude-sonnet-4-20250514",
  "baseUrl": "http://10.10.0.195:8317/v1",
  "thinking": "low",
  "tools": "read,bash,write,edit,grep,find,ls",
  "excludeTools": "",
  "noFiles": false,
  "noGit": false
}
```

Or `~/.claude/pi.local.json` for global user-wide defaults. Project settings override global settings. CLI flags override both.

Run `/pi:delegate --edit-config` to quickly create or edit your project settings.

## Design

- **Single entry point**: `/pi:delegate` is the only skill — no sub-commands.
- **Context-aware**: The skill automatically collects file and git context from the current project.
- **Non-interactive**: All pi tasks run in `-p` (print) mode for clean, text-based output.
- **Isolated**: Uses `--no-session --no-context-files --approve` to avoid conflicts with the current project's state.