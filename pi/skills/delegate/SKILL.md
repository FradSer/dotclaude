---
name: delegate
description: Delegates a coding task to pi (dev/pi), a minimal terminal coding harness. This skill should be used when the user asks to "use pi", "run pi", "delegate to pi", "let pi handle this", "ask pi to", "have pi do", or invokes /pi:delegate. It bridges the current Claude Code context to pi CLI for execution, passing relevant files, git state, and the task description.
user-invocable: true
argument-hint: "<task description> [--provider PROVIDER] [--model MODEL] [--api-key KEY] [--thinking LEVEL] [--tools TOOL_LIST] [--exclude-tools TOOL_LIST] [--no-files] [--no-git] | --edit-config [--local|--shared|--global] | --doctor"
allowed-tools: ["Bash(git:*)", "Bash(jq:*)", "Bash(ls:*)", "Bash(find:*)", "Bash(cat:*)", "Bash(mkdir:*)", "Bash(echo:*)", "Bash(command:*)", "Bash(pi:*)", "Read", "Grep", "Glob"]
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
2. **Process env** — `PI_PROVIDER`, `PI_MODEL`, `PI_API_KEY`, `PI_BASE_URL`, `PI_THINKING`, `PI_TOOLS`
3. **`.claude/pi.local.json`** — project-specific overrides, gitignored
4. **`~/.claude/pi.local.json`** — global user-wide defaults
5. **pi's own defaults** (pi decides its own default provider and model)

### Settings file format

Settings files only override what the user wants to change. All fields are optional — omit any field to let pi's own default apply.

Values can reference environment variables using `$VAR` or `${VAR}` syntax — they are resolved at read time.

```json
{
  "provider": "",
  "model": "",
  "baseUrl": "",
  "apiKey": "",
  "thinking": "",
  "tools": "",
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
  CONFIG=$(jq -s '.[0] * .[1]' /dev/stdin "$HOME/.claude/pi.local.json" 2>/dev/null <<<"$CONFIG" || echo "$CONFIG")
fi

# 2. Project shared
if [ -f ".claude/pi.json" ]; then
  CONFIG=$(jq -s '.[0] * .[1]' /dev/stdin ".claude/pi.json" 2>/dev/null <<<"$CONFIG" || echo "$CONFIG")
fi

# 3. Project personal (highest file priority)
if [ -f ".claude/pi.local.json" ]; then
  CONFIG=$(jq -s '.[0] * .[1]' /dev/stdin ".claude/pi.local.json" 2>/dev/null <<<"$CONFIG" || echo "$CONFIG")
fi
```

Then extract values, resolving environment variable references. After file-based config, process env vars (`PI_*`) override any JSON value:

```bash
# Resolve env vars in a JSON value: "$VAR" or "${VAR}" → actual value
resolve_env() {
  local val="$1"
  while [[ "$val" =~ \$\{?([a-zA-Z_][a-zA-Z0-9_]*)\}? ]]; do
    local var_name="${BASH_REMATCH[1]}"
    local var_value="${!var_name:-}"
    val="${val//${BASH_REMATCH[0]}/$var_value}"
  done
  echo "$val"
}

# Read from merged config (files), then let process env override
PROVIDER=$(resolve_env "${PI_PROVIDER:-$(echo "$CONFIG" | jq -r '.provider // ""')}")
MODEL=$(resolve_env "${PI_MODEL:-$(echo "$CONFIG" | jq -r '.model // ""')}")
BASE_URL=$(resolve_env "${PI_BASE_URL:-$(echo "$CONFIG" | jq -r '.baseUrl // ""')}")
API_KEY=$(resolve_env "${PI_API_KEY:-$(echo "$CONFIG" | jq -r '.apiKey // ""')}")
THINKING=$(resolve_env "${PI_THINKING:-$(echo "$CONFIG" | jq -r '.thinking // "low"')}")
TOOLS=$(resolve_env "${PI_TOOLS:-$(echo "$CONFIG" | jq -r '.tools // ""')}")
EXCLUDE_TOOLS=$(resolve_env "${PI_EXCLUDE_TOOLS:-$(echo "$CONFIG" | jq -r '.excludeTools // ""')}")
```

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
  "provider": "",
  "model": "",
  "baseUrl": "",
  "apiKey": "",
  "thinking": "",
  "tools": "",
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

### `--doctor` flag

When `$ARGUMENTS` is exactly `--doctor`, run a comprehensive configuration check. See `references/doctor.md` for the script.

## Argument Parsing

Parse `$ARGUMENTS` to extract the task description and optional flags. The task description is everything before the first `--` flag. If no flags are present, the entire argument is the task description.

| Flag | Description | Source Priority |
|------|-------------|-----------------|
| `--provider` | LLM provider (anthropic, openai, google, etc.) | CLI > settings > pi's default |
| `--model` | Model pattern or ID (e.g. `claude-sonnet-4-20250514`, `openai/gpt-4o`) | CLI > settings > pi's default |
| `--api-key` | API key for the provider | CLI > settings > env var or config file |
| `--thinking` | Thinking level (off/minimal/low/medium/high/xhigh/max) | CLI > settings > `low` |
| `--tools` | Comma-separated allowed tools list | CLI > settings > `read,bash,write,edit,grep,find,ls` |
| `--exclude-tools` | Comma-separated blocked tools list | CLI > settings > (none) |
| `--no-files` | Skip collecting file context | CLI > settings > `false` |
| `--no-git` | Skip collecting git context | CLI > settings > `false` |

### Resolution order per flag

For each flag, resolve the value by checking CLI flag first, then settings file, then pi's built-in default:

1. Parse `$ARGUMENTS` for that flag. If present, use it.
2. Otherwise, read from `$CONFIG` (the merged settings). If non-null/non-empty, use it.
3. Otherwise, use pi's built-in default (see below).

### Defaults behavior

- **provider**: No default — let pi's own default decide. The settings chain (CLI > config file > pi's internal default) resolves the value.
- **model**: No default — let pi's own default decide. Only pass `--model` if the user explicitly specified it or the settings file has a value.
- **thinking**: Default to `low` to keep responses fast and cheap.
- **tools**: Default to full toolset `read,bash,write,edit,grep,find,ls`.
- **base-url**: When resolved, write to `~/.pi/agent/models.json` for the provider (defaults to `openai`). The user can override the provider explicitly via CLI flag.

## Context Collection Strategy

Collect context from the current working directory before calling pi. The goal is to give pi the same situational awareness that Claude Code has.

### 1. Pass CLAUDE.md as System Prompt Context

**pi has `read`, `grep`, `find`, and `ls` tools** — it can explore the codebase on its own. Do not pass `@.` file references (pi errors on directory paths). Just pass the task description and let pi use its tools to read what it needs.

However, **always pass the CLAUDE.md files** as system prompt context so pi understands the project and user conventions. `--append-system-prompt` accepts file paths directly — pi reads them automatically.

```bash
# Build CLAUDE.md context — pass file paths, pi reads them
CLAUDE_CONTEXT=""
if [ -f "$HOME/.claude/CLAUDE.md" ]; then
  CLAUDE_CONTEXT="$CLAUDE_CONTEXT --append-system-prompt $HOME/.claude/CLAUDE.md"
fi
if [ -f "CLAUDE.md" ]; then
  CLAUDE_CONTEXT="$CLAUDE_CONTEXT --append-system-prompt CLAUDE.md"
fi
```

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
2. **Provider/Model flags** (use resolved values from settings chain, only pass if non-default):
   - `--provider <value>` (from settings or pi's default)
   - `--model <value>` (only if specified in settings or CLI)
   - `--api-key <value>` (only if resolved from settings or CLI flag)
   - `--thinking low` (default, only pass if needed)
3. **Custom base URL**: If `baseUrl` is resolved from settings or CLI flag, write it to `~/.pi/agent/models.json` for the provider before calling pi (see Base URL section below). Never pass `--base-url` to pi — pi does not support it as a CLI flag.
4. **Tool restrictions** (only if user specified):
   - `--tools <value>` (only if user wants to restrict)
   - `--exclude-tools <value>` (only if user specified)
5. **Session control**: `--no-session --no-context-files --approve`
6. **CLAUDE.md context**: `$CLAUDE_CONTEXT` (built above — passes `~/.claude/CLAUDE.md` and `./CLAUDE.md` as `--append-system-prompt` file paths, pi reads them automatically)
7. **Appended context**: `--append-system-prompt "context block"` (for git status, directory listing, etc.)
8. **Task description**: The quoted task description as the final argument

### Default provider note

Do not hardcode a provider. Resolve from the settings chain (CLI flag > config file > pi's built-in default). pi's own default is `google` (Gemini). If the user has set `"provider": "google"` in `~/.claude/pi.local.json`, that takes effect without needing CLI flags.

### Pattern for appended context

First build the CLAUDE.md context, then format the git/project context as a single block:

```bash
# Build CLAUDE.md context — pass file paths, pi reads them
CLAUDE_CONTEXT=""
if [ -f "$HOME/.claude/CLAUDE.md" ]; then
  CLAUDE_CONTEXT="$CLAUDE_CONTEXT --append-system-prompt $HOME/.claude/CLAUDE.md"
fi
if [ -f "CLAUDE.md" ]; then
  CLAUDE_CONTEXT="$CLAUDE_CONTEXT --append-system-prompt CLAUDE.md"
fi
```

Then format the git context:

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

Always use `Bash` with `run_in_background` — pi -p is a single-shot command, not a continuous stream. Monitor is designed for event streams (like `tail -f`) and will timeout when pi's output is delayed or batched.

**Do not add a shell `timeout`** — pi tasks can be heavy and may run for a long time. Let pi run to completion naturally.

```bash
# Build CLAUDE.md context — pass file paths, pi reads them
CLAUDE_CONTEXT=""
if [ -f "$HOME/.claude/CLAUDE.md" ]; then
  CLAUDE_CONTEXT="$CLAUDE_CONTEXT --append-system-prompt $HOME/.claude/CLAUDE.md"
fi
if [ -f "CLAUDE.md" ]; then
  CLAUDE_CONTEXT="$CLAUDE_CONTEXT --append-system-prompt CLAUDE.md"
fi

# Build the pi command — no file references, pi uses its tools to explore
PI_CMD="pi -p --thinking low${API_KEY:+ --api-key $API_KEY} --no-session --no-context-files --approve $CLAUDE_CONTEXT \"task description\""

# Run in background — no timeout, let pi finish naturally
bash -c "$PI_CMD 2>&1" &
```

### Important: Pi's Default Provider

Do not hardcode a provider. Resolve from the settings chain (CLI flag > config file > pi's built-in default). pi's own default is `google` (Gemini). If the user has set `"provider": "google"` in `~/.claude/pi.local.json`, that takes effect without needing CLI flags.

### Base URL via models.json

pi does not support `--base-url` CLI flag or `OPENAI_BASE_URL` environment variable. Custom API endpoints are configured through `~/.pi/agent/models.json`. When `baseUrl` is resolved from settings or CLI flag, the skill writes it to pi's models.json before calling pi — then calls pi without `--base-url`.

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

### CRITICAL: pi's Real Output Is File Edits, Not stdout

**pi writes code by editing files in the working directory. Its stdout is secondary — often empty or minimal, especially with long `--append-system-prompt`.** Do not judge success by stdout content.

| Signal | Meaning |
|--------|---------|
| Exit code 0 | pi completed successfully |
| Exit code 1 | pi failed (check stderr) |
| stdout empty | Normal — pi already applied edits to files |
| Modified files exist | Reliable indicator of work done |

### On Success (exit code 0)

**Always check for modified files first** — this is where pi's real output lives:

```bash
git diff --stat
```

- If git shows changes, present those changes to the user. Describe what pi modified (additions, deletions, file count).
- If git shows no changes and exit was 0, the task was understood but resulted in no modifications (read-only analysis, conceptual questions, or the task was already satisfied).

Include pi's stdout in the report if it's non-empty, but the file changes are the primary deliverable.

### On Error (exit code 1+)

Show the error message from stderr. Common error causes:
- pi not configured (no API key)
- Provider/model not available
- Task interrupted or killed

## Usage Examples

### Basic task with file context
User: `/pi:delegate review the TypeScript types in src/`

Claude: Builds CLAUDE.md context, collects git context, then runs:
```bash
CLAUDE_CONTEXT=""
if [ -f "$HOME/.claude/CLAUDE.md" ]; then
  CLAUDE_CONTEXT="$CLAUDE_CONTEXT --append-system-prompt $HOME/.claude/CLAUDE.md"
fi
if [ -f "CLAUDE.md" ]; then
  CLAUDE_CONTEXT="$CLAUDE_CONTEXT --append-system-prompt CLAUDE.md"
fi

PI_CMD="pi -p --thinking low --no-session --no-context-files --approve $CLAUDE_CONTEXT \"review the TypeScript types in src/\""
bash -c "$PI_CMD 2>&1" &
```

### Specific model
User: `/pi:delegate refactor this component --model claude-sonnet-4-20250514`

Claude: Builds CLAUDE.md context, passes --model flag:
```bash
CLAUDE_CONTEXT=""
if [ -f "$HOME/.claude/CLAUDE.md" ]; then
  CLAUDE_CONTEXT="$CLAUDE_CONTEXT --append-system-prompt $HOME/.claude/CLAUDE.md"
fi
if [ -f "CLAUDE.md" ]; then
  CLAUDE_CONTEXT="$CLAUDE_CONTEXT --append-system-prompt CLAUDE.md"
fi

PI_CMD="pi -p --model claude-sonnet-4-20250514 --thinking low --no-session --no-context-files --approve $CLAUDE_CONTEXT --append-system-prompt \"Git status: ...\" \"refactor this component\""
bash -c "$PI_CMD 2>&1" &
```

### Custom base URL (OpenAI-compatible proxy via models.json)
User: `/pi:delegate write unit tests for this module --provider openai --model gemini-3.6-flash-high`

Claude: Checks `~/.claude/pi.local.json` for `baseUrl`, writes it to `~/.pi/agent/models.json` for the `openai` provider, then runs:
```bash
CLAUDE_CONTEXT=""
if [ -f "$HOME/.claude/CLAUDE.md" ]; then
  CLAUDE_CONTEXT="$CLAUDE_CONTEXT --append-system-prompt $HOME/.claude/CLAUDE.md"
fi
if [ -f "CLAUDE.md" ]; then
  CLAUDE_CONTEXT="$CLAUDE_CONTEXT --append-system-prompt CLAUDE.md"
fi

PI_CMD="pi -p --provider openai --model gemini-3.6-flash-high --thinking low --no-session --no-context-files --approve $CLAUDE_CONTEXT \"write unit tests for this module\""
bash -c "$PI_CMD 2>&1" &
```

### Read-only analysis
User: `/pi:delegate audit the security of this codebase --tools read,grep,find,ls`

Claude: Builds CLAUDE.md context, passes --tools to restrict pi to read-only tools:
```bash
CLAUDE_CONTEXT=""
if [ -f "$HOME/.claude/CLAUDE.md" ]; then
  CLAUDE_CONTEXT="$CLAUDE_CONTEXT --append-system-prompt $HOME/.claude/CLAUDE.md"
fi
if [ -f "CLAUDE.md" ]; then
  CLAUDE_CONTEXT="$CLAUDE_CONTEXT --append-system-prompt CLAUDE.md"
fi

PI_CMD="pi -p --thinking low --tools read,grep,find,ls --no-session --no-context-files --approve $CLAUDE_CONTEXT \"audit the security of this codebase\""
bash -c "$PI_CMD 2>&1" &
```

### No file context, just conceptual
User: `/pi:delegate explain how React reconciliation works --no-files`

Claude: Builds CLAUDE.md context, sends the prompt:
```bash
CLAUDE_CONTEXT=""
if [ -f "$HOME/.claude/CLAUDE.md" ]; then
  CLAUDE_CONTEXT="$CLAUDE_CONTEXT --append-system-prompt $HOME/.claude/CLAUDE.md"
fi
if [ -f "CLAUDE.md" ]; then
  CLAUDE_CONTEXT="$CLAUDE_CONTEXT --append-system-prompt CLAUDE.md"
fi

PI_CMD="pi -p --thinking low --no-session --no-context-files --approve $CLAUDE_CONTEXT \"explain how React reconciliation works\""
bash -c "$PI_CMD 2>&1" &
```

## Important Notes

- pi MUST be installed globally. The skill checks and blocks if not found.
- The skill uses `pi -p` (print mode) for all tasks — this is non-interactive and produces text output.
- Settings in `.claude/pi.local.json` and `.claude/pi.json` are on the reading path — shared settings (`.claude/pi.json`) is tracked, personal settings (`.claude/pi.local.json`) is gitignored by `**/.claude/*.local.*`.
- `--base-url` writes to `~/.pi/agent/models.json` (pi's global provider config) — this is a one-time setup per endpoint, not per-session.
- `--no-session` prevents pi from creating session files.
- `--no-context-files` prevents pi from reading its own AGENTS.md/CLAUDE.md (which could conflict with the current project's context).
- `--approve` skips any project trust prompts (non-interactive mode).
- **CLAUDE.md context is always passed** via `--append-system-prompt` as file paths — `~/.claude/CLAUDE.md` (user global) and `./CLAUDE.md` (project). pi reads them automatically.
- To configure pi (provider, model, base URL), run `/pi:setup` instead of passing flags manually.
- Git context is passed via `--append-system-prompt` as structured text.