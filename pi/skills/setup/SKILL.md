---
name: setup
description: Guides the user through configuring pi — provider, model, base URL, and API key. Use when the user asks to "setup pi", "configure pi", "pi setup", "set up pi provider", "pi config", "change pi model", or invokes /pi:setup. Only run this skill when the user explicitly requests pi setup — never auto-invoke.
user-invocable: true
argument-hint: "[--provider PROVIDER] [--model MODEL] [--api-key KEY] | --edit-config | --list-models | --test | --doctor"
allowed-tools: ["Bash(pi:*)", "Bash(jq:*)", "Bash(cat:*)", "Bash(mkdir:*)", "Bash(echo:*)", "Bash(command:*)", "Bash(ls:*)", "Read", "Write"]
---

# CRITICAL: User setup only — do not auto-invoke

This skill is for **human-only** setup. Never invoke it automatically. Only run when the user explicitly calls `/pi:setup`. Configure pi's provider, model, and endpoint so `/pi:delegate` and `/pi:review` can use them without repeating flags.

## Before Execution: Check Installation

```bash
command -v pi >/dev/null 2>&1
```

If not installed, guide the user:

```bash
npm install -g @earendil-works/pi-coding-agent
```

Or via the standalone installer:

```bash
curl -fsSL https://pi.dev/install.sh | sh
```

Then stop — do not proceed without pi installed.

## Settings File

Both `/pi:delegate` and `/pi:review` read from the same settings chain:

1. **CLI flag** (from `$ARGUMENTS`)
2. **`.claude/pi.local.json`** — project-specific overrides, gitignored
3. **`~/.claude/pi.local.json`** — global user-wide defaults
4. **pi's own defaults** (pi decides its own default provider and model)

This skill writes to `~/.claude/pi.local.json` (global, takes effect for all projects).

### Settings file format

Settings files only override what the user wants to change. All fields are optional:

Values can reference environment variables using `$VAR` or `${VAR}` syntax — they are resolved at read time by `/pi:delegate` and `/pi:review`. This is useful for API keys: `"apiKey": "$MY_API_KEY"` reads from the environment variable at runtime.

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

### `--list-models` flag

When `$ARGUMENTS` is exactly `--list-models`, read the current settings and show the effective configuration:

```bash
echo "=== Current pi configuration ==="
echo "Settings file: $HOME/.claude/pi.local.json"
if [ -f "$HOME/.claude/pi.local.json" ]; then
  cat "$HOME/.claude/pi.local.json"
else
  echo "(not configured — pi uses its defaults)"
fi
echo ""
echo "To configure, run: /pi:setup --provider <name> --model <id> [--base-url <url>]"
echo "Or use interactive mode: /pi:setup --edit-config"
```

Then stop — do not proceed to setup.

### `--test` flag

When `$ARGUMENTS` includes `--test`, run a quick connectivity test:

```bash
pi -p --provider "$PROVIDER" --model "$MODEL" --thinking low --no-session --no-context-files --approve "Reply with exactly: OK. Model: <model-name>"
```

Report the result: "pi responded successfully with model <name>" on exit 0, or the error on failure.

## Setup Process

### Step 1: Detect current state

Show the user their current configuration:

```bash
echo "=== Current pi configuration ==="
if [ -f "$HOME/.claude/pi.local.json" ]; then
  cat "$HOME/.claude/pi.local.json"
else
  echo "No configuration file found."
fi
```

### Step 2: Collect configuration from CLI flags or interactive

If `$ARGUMENTS` contains flags, parse them directly:

| Flag | Description |
|------|-------------|
| `--provider` | LLM provider name (`openai`, `anthropic`, `google`, etc.) |
| `--model` | Model ID (e.g. `gemini-3.6-flash-high`, `claude-sonnet-4-20250514`) |
| `--api-key` | API key for the provider (stored in settings file, or reference `$ENV_VAR`) |

If no flags are provided, use the AskUserQuestion tool to ask the user:

1. **Provider**: What provider do you want to use? (Options: `openai`, `anthropic`, `google`, or "Other" for custom)
2. **Model**: What model ID? (e.g. `gemini-3.6-flash-high`, `claude-sonnet-4-20250514`)
3. **API Key** (optional): API key or `$ENV_VAR` reference? (leave empty to use environment variables)

### Step 3: Write configuration

```bash
mkdir -p "$HOME/.claude"

# Read existing config
EXISTING="{}"
if [ -f "$HOME/.claude/pi.local.json" ]; then
  EXISTING=$(cat "$HOME/.claude/pi.local.json")
fi

# Merge with new values (only override non-empty fields)
echo "$EXISTING" | jq \
  --arg provider "${PROVIDER:-}" \
  --arg model "${MODEL:-}" \
  --arg baseUrl "${BASE_URL:-}" \
  --arg apiKey "${API_KEY:-}" \
  '.provider = (if $provider != "" then $provider else .provider end) |
   .model = (if $model != "" then $model else .model end) |
   .baseUrl = (if $baseUrl != "" then $baseUrl else .baseUrl end) |
   .apiKey = (if $apiKey != "" then $apiKey else .apiKey end)' \
  > "$HOME/.claude/pi.local.json"
```

### Step 4: Verify with `--test`

Run the test automatically after writing config:

```bash
pi -p --provider "$PROVIDER" --model "$MODEL" ${BASE_URL:+--base-url "$BASE_URL"} --thinking low --no-session --no-context-files --approve "Reply with exactly: OK. Model: <model-name>"
```

Report success or failure to the user.

### Step 5: Summary

Show the final configuration and tell the user:

```
pi configured successfully. Both `/pi:delegate` and `/pi:review` will use these settings by default.

To override for a single invocation:
  /pi:delegate <task> --provider <name> --model <id>
  /pi:review --model <id>

To edit manually:
  /pi:setup --edit-config

To view current config:
  /pi:setup --list-models
```

## Common configurations

### OpenAI-compatible endpoint (with custom base URL)

Configure `baseUrl` in `~/.claude/pi.local.json`:

```json
{
  "provider": "openai",
  "model": "gemini-3.6-flash-high",
  "baseUrl": "http://10.10.0.195:8317/v1"
}
```

Or via `/pi:setup --edit-config --global`.

### Anthropic direct

```bash
/pi:setup --provider anthropic --model claude-sonnet-4-20250514
```

### Google Gemini direct

```bash
/pi:setup --provider google --model gemini-3.6-flash-high
```

## References

- `/pi:delegate` — delegates coding tasks to pi
- `/pi:review` — reviews code via pi with read-only tools
- `~/.claude/pi.local.json` — global user settings (read by both delegate and review)