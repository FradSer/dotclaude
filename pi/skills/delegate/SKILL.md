---
name: delegate
description: Delegates a coding task to pi (dev/pi), a minimal terminal coding harness. This skill should be used when the user asks to "use pi", "run pi", "delegate to pi", "let pi handle this", "ask pi to", "have pi do", or invokes /pi:delegate. It bridges the current Claude Code context to pi CLI for execution, passing relevant files, git state, and the task description.
user-invocable: true
argument-hint: "<task description> [--provider PROVIDER] [--model MODEL] [--base-url URL] [--thinking LEVEL] [--tools TOOL_LIST] [--exclude-tools TOOL_LIST] [--no-files] [--no-git] | --edit-config [--local|--shared|--global]"
allowed-tools: ["Bash(pi:*)", "Read", "Grep", "Glob"]
---

# CRITICAL: pi CLI Integration

This skill delegates a task to the `pi` CLI tool (`@earendil-works/pi-coding-agent`). It is the ONLY entry point for the pi plugin.

## Before Execution: Check Installation

```bash
# Check if pi is installed
command -v pi >/dev/null 2>&1
```

If not installed, tell the user:
```
pi is not installed. Install it globally:

  npm install -g @earendil-works/pi-coding-agent

Or via the standalone installer:

  curl -fsSL https://pi.dev/install.sh | sh
```

Then stop — do not proceed without pi installed.

## Persistent Settings

User preferences persist across invocations via JSON files. The resolution chain (highest priority first):

1. **CLI flag** (from `$ARGUMENTS`)
2. **`.claude/pi.local.json`** — project-specific overrides, gitignored
3. **`~/.claude/pi.local.json`** — global user-wide defaults
4. **Built-in defaults** (listed below)

### Settings file format

```json
{
  "provider": "anthropic",
  "model": "claude-sonnet-4-20250514",
  "baseUrl": "https://my-proxy.example.com/v1",
  "thinking": "low",
  "tools": "read,bash,write,edit,grep,find,ls",
  "excludeTools": "",
  "noFiles": false,
  "noGit": false
}
```

Only include fields the user wants to override. Partial files are fine — the chain merges per-field.

### Reading settings

Before parsing `$ARGUMENTS`, read the settings files in priority order (lowest first, so each overrides the previous):

```bash
# Start with empty config
CONFIG='{}'

# 1. Global personal (lowest priority)
if [ -f "$HOME/.claude/pi.local.json" ]; then
  CONFIG=$(jq -s '.[0] * .[1]' <<<"$CONFIG" "$HOME/.claude/pi.local.json" 2>/dev/null || echo "$CONFIG")
fi

# 2. Project shared
if [ -f ".claude/pi.json" ]; then
  CONFIG=$(jq -s '.[0] * .[1]' <<<"$CONFIG" ".claude/pi.json" 2>/dev/null || echo "$CONFIG")
fi

# 3. Project personal (highest file priority)
if [ -f ".claude/pi.local.json" ]; then
  CONFIG=$(jq -s '.[0] * .[1]' <<<"$CONFIG" ".claude/pi.local.json" 2>/dev/null || echo "$CONFIG")
fi
```

Then extract values: `echo "$CONFIG" | jq -r '.provider // "anthropic"'`

### `--edit-config` flag

When `$ARGUMENTS` is exactly `--edit-config` (with optional scope flag), open the settings file for editing. Three scopes matching the three priority tiers:

| Scope | Flag | Path | Description | Git |
|-------|------|------|-------------|-----|
| Project personal | `--edit-config` (default) or `--edit-config --local` | `.claude/pi.local.json` | Per-project overrides | gitignored |
| Project shared | `--edit-config --shared` | `.claude/pi.json` | Team defaults, committed | tracked |
| Global personal | `--edit-config --global` or `--edit-config -g` | `~/.claude/pi.local.json` | User-wide across all projects | user home |

```bash
# Detect scope
if [[ "$ARGUMENTS" == *"--global"* || "$ARGUMENTS" == *"-g"* ]]; then
  CONFIG_PATH="$HOME/.claude/pi.local.json"
elif [[ "$ARGUMENTS" == *"--shared"* ]]; then
  CONFIG_PATH=".claude/pi.json"
else
  # --local (default)
  CONFIG_PATH=".claude/pi.local.json"
fi

# Create if not exists
mkdir -p "$(dirname "$CONFIG_PATH")"
if [ ! -f "$CONFIG_PATH" ]; then
  cat > "$CONFIG_PATH" << 'EOF'
{
  "provider": "anthropic",
  "model": "",
  "baseUrl": "",
  "thinking": "low",
  "tools": "read,bash,write,edit,grep,find,ls",
  "excludeTools": "",
  "noFiles": false,
  "noGit": false
}
EOF
fi

# Open in editor
${EDITOR:-vi} "$CONFIG_PATH"
```

Report: "Settings file created/opened at `<path>`. Changes take effect on the next `/pi:delegate` invocation."

## Argument Parsing

Parse `$ARGUMENTS` to extract the task description and optional flags. The task description is everything before the first `--` flag. If no flags are present, the entire argument is the task description.

| Flag | Description | Source Priority |
|------|-------------|-----------------|
| `--provider` | LLM provider (anthropic, openai, google, etc.) | CLI > settings > `anthropic` |
| `--model` | Model pattern or ID (e.g. `claude-sonnet-4-20250514`, `openai/gpt-4o`) | CLI > settings > (pi's default) |
| `--base-url` | Custom API base URL for OpenAI-compatible endpoint | CLI > settings > (none) |
| `--thinking` | Thinking level (off/minimal/low/medium/high/xhigh/max) | CLI > settings > `low` |
| `--tools` | Comma-separated allowed tools list | CLI > settings > `read,bash,write,edit,grep,find,ls` |
| `--exclude-tools` | Comma-separated blocked tools list | CLI > settings > (none) |
| `--no-files` | Skip collecting file context | CLI > settings > `false` |
| `--no-git` | Skip collecting git context | CLI > settings > `false` |

### Resolution order per flag

For each flag, resolve the value by checking CLI flag first, then settings file, then built-in default:

1. Parse `$ARGUMENTS` for that flag. If present, use it.
2. Otherwise, read from `$CONFIG` (the merged settings). If non-null/non-empty, use it.
3. Otherwise, use the built-in default.

### Defaults behavior

- **provider**: Default to `anthropic` (Claude Code users typically have `ANTHROPIC_API_KEY` set).
- **thinking**: Default to `low` to keep responses fast and cheap.
- **tools**: Default to full toolset `read,bash,write,edit,grep,find,ls`.
- **base-url**: When resolved, write to `~/.pi/agent/models.json` for the provider (defaults to `openai`). The user can override the provider explicitly via CLI flag.

## Context Collection Strategy

Collect context from the current working directory before calling pi. The goal is to give pi the same situational awareness that Claude Code has.

### 1. Collect File Context (unless `--no-files`)

Use Glob to find relevant files in the current directory. Collect:

- **Modified files** (from git status)
- **Key project files**: README.md, CLAUDE.md, AGENTS.md, package.json, pyproject.toml, go.mod, Cargo.toml, etc.
- **Files the user explicitly mentioned** in their request

For each file, use `@filepath` syntax when passing to pi. Do NOT read the file contents yourself — pi will handle that.

### 2. Collect Git Context (unless `--no-git`)

```bash
git status --short
git diff --stat
git log --oneline -10
```

These go into `--append-system-prompt` as structured context.

### 3. Collect Directory Structure

```bash
ls -la
```

Or for deeper context:
```bash
find . -maxdepth 2 -type f 2>/dev/null | head -50
```

## Executing pi

### Command Construction

Build the pi command with these components in order:

1. **Base**: `pi -p` (print mode, non-interactive)
2. **Provider/Model flags** (only if user specified or default):
   - `--provider anthropic` (default, only pass if needed)
   - `--model <value>` (only if user specified)
   - `--thinking low` (default, only pass if needed)
3. **Custom base URL**: If `--base-url` is resolved, write it to `~/.pi/agent/models.json` for the provider (see Base URL section below).
4. **Tool restrictions** (only if user specified):
   - `--tools <value>` (only if user wants to restrict)
   - `--exclude-tools <value>` (only if user specified)
5. **Session control**: `--no-session --no-context-files --approve`
6. **File references**: `@file1.ts @file2.ts @README.md` (for each collected file, relative paths)
7. **Appended context**: `--append-system-prompt "context block"` (for git status, directory listing, etc.)
8. **Task description**: The quoted task description as the final argument

### Default provider note

pi itself defaults to `google` provider (Gemini), but Claude Code users typically have `ANTHROPIC_API_KEY` set. The skill defaults to `--provider anthropic`. If the user explicitly passes `--provider`, respect that over the default. If they pass `--base-url`, write to `models.json` for the resolved provider — defaulting to `openai` (unless they also pass `--provider`).

### Pattern for appended context

Format the git/project context as a single block:

```
--append-system-prompt "Project context at $(pwd):
Working directory: $(basename $(pwd))
Git status:
$(git status --short 2>/dev/null || echo '(not a git repo)')

Recent commits:
$(git log --oneline -10 2>/dev/null || echo '')

Current branch: $(git branch --show-current 2>/dev/null || echo '')"
```

### Execute

```bash
# Default: anthropic provider, low thinking, full tools
pi -p --provider anthropic --thinking low --no-session --no-context-files --approve @file1.ts @file2.ts "task description"

# With custom base URL (OpenAI-compatible endpoint) — models.json already configured
pi -p --provider openai --model gemini-3.6-flash --thinking low --no-session --no-context-files --approve @file1.ts "task description"
```

For long-running tasks, use Monitor with a timeout (default 300s, extend with `--timeout` if the task is expected to be long).

### Important: Pi's Default Provider

pi defaults to the `google` provider (Gemini). This skill defaults to `--provider anthropic` since Claude Code users typically have `ANTHROPIC_API_KEY` set. Respect the user's explicit choices; if they don't specify a provider, use `anthropic`.

### Base URL via models.json

pi does not support `OPENAI_BASE_URL` environment variable. Custom API endpoints are configured through `~/.pi/agent/models.json`. When `--base-url` is resolved (from CLI flag or settings), the skill ensures the provider's baseUrl is set in pi's models.json.

```bash
# When base-url is resolved, write/merge into pi's models.json
if [ -n "$BASE_URL" ]; then
  PROVIDER="${PROVIDER:-openai}"
  mkdir -p "$HOME/.pi/agent"
  EXISTING=$(cat "$HOME/.pi/agent/models.json" 2>/dev/null || echo '{}')
  # Merge: set baseUrl and apiKey for the provider
  echo "$EXISTING" | jq --arg provider "$PROVIDER" \
    --arg baseUrl "$BASE_URL" \
    --arg apiKey "${API_KEY:-}" \
    '.providers[$provider] = (.providers[$provider] // {}) | 
     .providers[$provider].baseUrl = $baseUrl |
     if $apiKey != "" then .providers[$provider].apiKey = $apiKey else . end' \
    > "$HOME/.pi/agent/models.json.tmp" && \
    mv "$HOME/.pi/agent/models.json.tmp" "$HOME/.pi/agent/models.json"
fi
```

The `--provider` defaults to `openai` when `--base-url` is used (since custom endpoints are typically OpenAI-compatible). The user can override with `--provider` explicitly.

## Handling Output

### On Success (exit code 0)

Present pi's output as the result. If the output is a single block of text, show it directly. If it contains structured information (file changes, analysis results), format it clearly.

### On Error (exit code 1)

Show the error message from stderr. Common error causes:
- pi not configured (no API key)
- Provider/model not available
- Task interrupted or timed out

### On Timeout

If the Monitor times out, report: "pi task timed out after N seconds. The task may still be running. Consider using a more specific task description or passing --timeout with a larger value."

## Usage Examples

### Basic task with file context
User: `/pi:delegate review the TypeScript types in src/`

Claude: Collects all .ts files in src/ via Glob, builds git context, then runs:
```bash
pi -p --provider anthropic --thinking low --no-session --no-context-files --approve @src/types.ts @src/index.ts --append-system-prompt "Git status: ..." "review the TypeScript types in src/"
```

### Specific model
User: `/pi:delegate refactor this component --model claude-sonnet-4-20250514`

Claude: Collects context, passes --model flag:
```bash
pi -p --provider anthropic --model claude-sonnet-4-20250514 --thinking low --no-session --no-context-files --approve @src/component.tsx "refactor this component"
```

### Custom base URL (OpenAI-compatible proxy)
User: `/pi:delegate write unit tests for this module --base-url http://10.10.0.195:8317/v1 --model gemini-3.6-flash`

Claude: Writes baseUrl to `~/.pi/agent/models.json` for the `openai` provider, then runs:
```bash
pi -p --provider openai --model gemini-3.6-flash --thinking low --no-session --no-context-files --approve @src/module.ts "write unit tests for this module"
```

### Read-only analysis
User: `/pi:delegate audit the security of this codebase --tools read,grep,find,ls`

Claude: Passes --tools to restrict pi to read-only tools:
```bash
pi -p --provider anthropic --thinking low --tools read,grep,find,ls --no-session --no-context-files --approve @src/ "audit the security of this codebase"
```

### No file context, just conceptual
User: `/pi:delegate explain how React reconciliation works --no-files`

Claude: Skips file collection, just sends the prompt:
```bash
pi -p --provider anthropic --thinking low --no-session --no-context-files --approve "explain how React reconciliation works"
```

## Important Notes

- pi MUST be installed globally. The skill checks and blocks if not found.
- The skill uses `pi -p` (print mode) for all tasks — this is non-interactive and produces text output.
- Settings in `.claude/pi.local.json` and `.claude/pi.json` are on the reading path — shared settings (`.claude/pi.json`) is tracked, personal settings (`.claude/pi.local.json`) is gitignored by `**/.claude/*.local.*`.
- `--base-url` writes to `~/.pi/agent/models.json` (pi's global provider config) — this is a one-time setup per endpoint, not per-session.
- `--no-session` prevents pi from creating session files.
- `--no-context-files` prevents pi from reading its own AGENTS.md/CLAUDE.md (which could conflict with the current project's context).
- `--approve` skips any project trust prompts (non-interactive mode).
- File paths are passed as `@filepath` (relative to cwd) — pi handles reading and embedding them.
- Git context is passed via `--append-system-prompt` as structured text.
- For very large file sets, be selective: only pass the most relevant files (key source files, configuration, and files the user mentioned). Passing too many files can hit context limits.