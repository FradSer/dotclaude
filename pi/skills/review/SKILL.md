---
name: review
description: Reviews code using pi CLI with read-only tools. Delegates the review to pi (dev/pi) with a structured review rubric, running in read-only mode (--tools read,grep,find,ls) to prevent accidental edits. Use when the user asks to "review code with pi", "pi review", "have pi review", "let pi review", or invokes /pi:review.
user-invocable: true
argument-hint: "[@target] [--branch BRANCH] [--diff RANGE] [--endpoint ENDPOINT] [--model MODEL] [--thinking LEVEL] | --edit-config [--local|--shared|--global] | --list-models"
allowed-tools: ["Bash(git:*)", "Bash(jq:*)", "Bash(ls:*)", "Bash(find:*)", "Bash(cat:*)", "Bash(mkdir:*)", "Bash(echo:*)", "Bash(command:*)", "Bash(pi:*)", "Read", "Grep", "Glob"]
---
# CRITICAL: pi Code Review

This skill delegates a code review to the `pi` CLI tool (`@earendil-works/pi-coding-agent`). pi runs with **read-only tools** (`--tools read,grep,find,ls`) to prevent accidental edits — it analyzes code and returns findings as text.

## Before Execution: Check Installation

```bash
command -v pi >/dev/null 2>&1
```

If not installed, tell the user and stop.

## Persistent Settings

User preferences persist across invocations via JSON files. The resolution chain (highest priority first):

1. **CLI flag** (from `$ARGUMENTS`)
2. **`.claude/pi.local.json`** — project-specific overrides, gitignored
3. **`~/.claude/pi.local.json`** — global user-wide defaults
4. **Built-in defaults** (listed below)

### Settings file format

The settings file maps **named endpoint configurations** (user-defined keys) to pi's known providers. Each key can have its own `baseUrl`, `apiKey`, and `models` list. At runtime, the skill writes the chosen endpoint's `baseUrl` into `~/.pi/agent/models.json` under a known provider (default `openai`), then calls pi with `--provider openai`.

Values can reference environment variables using `$VAR` or `${VAR}` syntax — they are resolved at read time. This is useful for API keys: `"apiKey": "$MY_API_KEY"` reads from the environment variable at runtime.

All fields are optional. The example below shows the format — fill in your own endpoints:

```json
{
  "endpoints": {
    "my-proxy": {
      "provider": "openai",
      "baseUrl": "http://10.10.0.195:8317/v1",
      "models": ["gemini-3.6-flash-high", "gemini-3.6-pro"]
    }
  },
  "defaultEndpoint": "my-proxy",
  "defaultModel": "gemini-3.6-flash-high"
}
```

Each endpoint entry has:
- `provider` (required) — pi's known provider name (`openai`, `anthropic`, `google`, etc.). This is what pi's `--provider` flag receives.
- `baseUrl` (optional) — custom API endpoint. When present, the skill writes it to `~/.pi/agent/models.json` for the specified `provider` before running.
- `models` — array of model IDs available via this endpoint.

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

Then extract values, resolving environment variable references:

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

ENDPOINT=$(resolve_env "$(echo "$CONFIG" | jq -r '.defaultEndpoint // ""')")
MODEL=$(resolve_env "$(echo "$CONFIG" | jq -r '.defaultModel // ""')")
THINKING=$(resolve_env "$(echo "$CONFIG" | jq -r '.thinking // "low"')")
PROVIDER=$(resolve_env "$(echo "$CONFIG" | jq -r --arg e "$ENDPOINT" '.endpoints[$e].provider // "openai"')")
BASE_URL=$(resolve_env "$(echo "$CONFIG" | jq -r --arg e "$ENDPOINT" '.endpoints[$e].baseUrl // ""')")
API_KEY=$(resolve_env "$(echo "$CONFIG" | jq -r --arg e "$ENDPOINT" '.endpoints[$e].apiKey // ""')")
# If model not set, use first model from the endpoint
if [ -z "$MODEL" ] || [ "$MODEL" = "null" ]; then
  MODEL=$(echo "$CONFIG" | jq -r --arg e "$ENDPOINT" '.endpoints[$e].models[0] // ""')
fi
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
  CONFIG_PATH=".claude/pi.local.json"
fi

# Create if not exists
mkdir -p "$(dirname "$CONFIG_PATH")"
if [ ! -f "$CONFIG_PATH" ]; then
  cat > "$CONFIG_PATH" << 'EOF'
{
  "endpoints": {},
  "defaultEndpoint": "",
  "defaultModel": "",
  "thinking": ""
}
EOF
fi

# Open in editor
${EDITOR:-vi} "$CONFIG_PATH"
```

Report: "Settings file created/opened at `<path>`. Changes take effect on the next `/pi:review` invocation."

### `--list-models` flag

When `$ARGUMENTS` is exactly `--list-models`, read the merged config and display all configured endpoints and their models:

```bash
echo "$CONFIG" | jq -r '
  .defaultEndpoint as $def |
  .defaultModel as $defm |
  (.endpoints | to_entries[] |
    "\(.key)" + if .key == $def then " (default)" else "" end +
    " → " + .value.provider +
    ":" +
    (.value.models | join(", ")) +
    if .key == $def and $defm != "" then "  ← active: " + $defm else "" end
  )
'
```

Then stop — do not proceed to review.

## Argument Parsing

Parse `$ARGUMENTS` to extract the review target and optional flags. The target is everything before the first `--` flag. If no flags are present, the entire argument is the target.

| Flag | Description | Source Priority |
|------|-------------|-----------------|
| `--endpoint` | Endpoint key name (must match a key in settings `endpoints`) | CLI > settings > `defaultEndpoint` |
| `--model` | Model ID to use for this review | CLI > settings > (endpoint's first model) |
| `--thinking` | Thinking level (off/minimal/low/medium/high/xhigh/max) | CLI > settings > `low` |

### Resolution order per flag

For each flag, resolve the value by checking CLI flag first, then settings file, then built-in default:

1. Parse `$ARGUMENTS` for that flag. If present, use it.
2. Otherwise, read from `$CONFIG` (the merged settings). If non-null/non-empty, use it.
3. Otherwise, use the built-in default.

### Endpoint resolution

1. If `--endpoint` is specified, use it as the key into `endpoints` config.
2. If `--model` is specified without `--endpoint`, scan all endpoints for a model matching the ID — use the first match's endpoint.
3. Otherwise, use `defaultEndpoint` from settings.
4. If the resolved model is empty, use the first model in the resolved endpoint's model list.
5. Resolve the pi provider from the endpoint's `provider` field (default `openai`).

### Base URL resolution

If the resolved endpoint has a `baseUrl`, write it to `~/.pi/agent/models.json` for the resolved provider before running pi:

```bash
if [ -n "$BASE_URL" ]; then
  mkdir -p "$HOME/.pi/agent"
  EXISTING=$(cat "$HOME/.pi/agent/models.json" 2>/dev/null || echo '{}')
  echo "$EXISTING" | jq --arg provider "$PROVIDER" \
    --arg baseUrl "$BASE_URL" \
    '.providers[$provider] = (.providers[$provider] // {}) |
     .providers[$provider].baseUrl = $baseUrl' \
    > "$HOME/.pi/agent/models.json.tmp" && \
    mv "$HOME/.pi/agent/models.json.tmp" "$HOME/.pi/agent/models.json"
fi
```

## Review Target

Determine what to review from the parsed arguments. The target can be:

| Pattern | What it reviews | Example |
|---------|----------------|---------|
| No target | pi explores codebase with its tools | `/pi:review` |
| `--branch <name>` | `git diff main...<branch>` | `/pi:review --branch feat/foo` |
| `--diff <range>` | `git diff <range>` | `/pi:review --diff HEAD~3..HEAD` |
| `@filepath` | Specific file(s) | `/pi:review @src/index.ts` |
| PR number | `gh pr diff <n>` | `/pi:review 42` (numeric = PR) |

### Resolution logic

1. **CRITICAL: Do NOT use `@.`** — pi does not support passing a directory path as `@.`. It will error with `EISDIR`.
2. **By default, do NOT pass file references** — pi has `read`, `grep`, `find`, and `ls` tools and can explore the codebase on its own. Just pass the task description.
3. Only pass `@filepath` references when the user explicitly names specific files (target starts with `@`).
4. If the target is a number (e.g. `42`), treat it as a GitHub PR number — fetch the diff with `gh pr diff <n>`.
5. If the target starts with `--branch`, extract the branch name and capture `git diff main...<branch>`.
6. If the target starts with `--diff`, extract the range and capture `git diff <range>`.
7. Otherwise, pass the remaining arguments as the task description.

### File references (when user specifies @filepath)

When the user passes `@filepath`, pass those file paths directly to pi as `@file.ts` arguments. pi will read them.

## Review Rubric (Embedded in Prompt)

The review prompt given to pi must cover these dimensions. Embed them as part of the task description, not as `--append-system-prompt`:

### 1. Correctness & Logic
- Does the code do what it intends? Any off-by-one, race conditions, null pointer, or type errors?
- Are error paths handled (not just the happy path)?
- Are async operations properly awaited or chained?

### 2. Code Quality & Maintainability
- Naming: do names reveal intent? (Mysterious Name)
- Duplication: is the same logic repeated? (Duplicated Code)
- Coupling: does a module reach into another's internals? (Feature Envy)
- Abstraction: is there speculative generality or missing domain types? (Speculative Generality, Primitive Obsession)
- Size: are functions/classes too large? Do they do one thing?

### 3. Security
- Are user inputs validated/sanitized?
- Any hardcoded secrets, tokens, or credentials?
- Any injection vectors (SQL, command, path traversal)?

### 4. Architecture & Design
- Does the change follow the project's established patterns?
- Does it introduce unnecessary dependencies?
- Is the change scoped appropriately (not shotgun surgery)?

### 5. Testing
- Are there tests for the changed code?
- Do tests cover edge cases and error paths?

## Context Collection

### 1. Pass CLAUDE.md as System Prompt Context

Always pass the CLAUDE.md files as system prompt context so pi understands the project and user conventions. `--append-system-prompt` accepts file paths directly — pi reads them automatically.

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

### 2. Git Context

```bash
git status --short
git diff --stat
git log --oneline -20
git branch --show-current
```

### 2. Capture the diff (for targeted review)

If `--branch` or `--diff` was specified, capture the diff directly:

```bash
# For --branch <name>: diff against main
git diff main...<BRANCH_NAME>

# For --diff <range>
git diff <RANGE>
```

Include the diff text in `--append-system-prompt` alongside the git context.

## Execution

Always use `Bash` with `run_in_background` — pi -p is a single-shot command, not a continuous stream. **Do not add a shell `timeout`** — reviews can be heavy. **Do not use Monitor.**

```bash
# Build CLAUDE.md context — pass file paths, pi reads them
CLAUDE_CONTEXT=""
if [ -f "$HOME/.claude/CLAUDE.md" ]; then
  CLAUDE_CONTEXT="$CLAUDE_CONTEXT --append-system-prompt $HOME/.claude/CLAUDE.md"
fi
if [ -f "CLAUDE.md" ]; then
  CLAUDE_CONTEXT="$CLAUDE_CONTEXT --append-system-prompt CLAUDE.md"
fi

# Build the pi review command with resolved variables
# Do NOT pass @file references by default — pi explores the codebase with its own tools
# Only add @file.ts when the user explicitly named files
PI_CMD="pi -p --provider $PROVIDER --model $MODEL${API_KEY:+ --api-key $API_KEY} --thinking ${THINKING:-low} --tools read,grep,find,ls --no-session --no-context-files --approve $CLAUDE_CONTEXT --append-system-prompt \"Git context: ...\" \"Review the code. Focus on correctness, code quality, security, architecture, and testing. For each issue found, report: file:line: severity (HIGH/MEDIUM/LOW) + description + suggested fix. Group findings by severity. If no issues found, explicitly state that the code looks clean.\""

# Run in background — no timeout
bash -c "$PI_CMD 2>&1" &
```

## Handling Output

### CRITICAL: pi's stdout is the review text

Unlike `/pi:delegate` where pi edits files, review mode uses `--tools read,grep,find,ls` — pi cannot write files. **Its stdout IS the review output.** Capture it and present it to the user.

### On Success (exit code 0)

Present pi's output as the review findings. Format it clearly:

- If pi returned structured findings with severity, present them grouped by severity.
- If pi said "no issues found", report that the code looks clean.
- If stdout is empty but exit was 0, report: "pi completed the review but produced no output. This may indicate the model didn't understand the task. Consider retrying with a more specific prompt."

### On Error (exit code 1+)

Show the error message from stderr. Common causes:
- pi not configured (no API key)
- Provider/model not available
- Task interrupted or killed

## Usage Examples

### Review the whole working directory (default)

```
/pi:review
```

### Review with a specific endpoint

```
/pi:review --endpoint openrouter
```

### Review with a specific model

```
/pi:review --model gemini-3.6-pro
```

### Review a specific branch

```
/pi:review --branch feat/new-widget --endpoint local-proxy --model gemini-3.6-flash-high
```

### Review recent changes

```
/pi:review --diff HEAD~5..HEAD
```

### Review a pull request

```
/pi:review 42
```

### Review a specific file

```
/pi:review @src/core/agent.ts
```

### List configured endpoints

```
/pi:review --list-models
```

### Edit project settings

```
/pi:review --edit-config
```

## Important Notes

- pi runs with `--tools read,grep,find,ls` — **read-only**. It cannot edit files.
- **Do NOT use `@.`** — pi does not support directory paths. pi has `read`, `grep`, `find`, `ls` tools and explores the codebase on its own.
- **CLAUDE.md context is always passed** via `--append-system-prompt` as file paths — `~/.claude/CLAUDE.md` (user global) and `./CLAUDE.md` (project). pi reads them automatically.
- **pi only knows built-in provider names** (`openai`, `anthropic`, `google`, etc.). The settings `endpoints` map is just for user convenience. The skill writes `baseUrl` to `~/.pi/agent/models.json` under the endpoint's `provider` field, then passes `--provider <provider>` to pi.
- No shell `timeout` — reviews can be heavy and should run to completion.
- The review rubric is embedded in the task description, not `--append-system-prompt`, to keep it in pi's context window.
- Git context and diffs go into `--append-system-prompt` as structured context.
- PR review requires `gh` CLI to be installed and authenticated.
- For large codebases, consider targeting a specific branch, diff range, or file to keep the review focused.
- Settings are shared with `/pi:delegate` via the same file chain (`.claude/pi.local.json`, `~/.claude/pi.local.json`). Both skills read the same files, but each uses its own format — you can keep both in the same file.
- To configure pi (provider, model, base URL), run `/pi:setup` instead of passing flags manually.