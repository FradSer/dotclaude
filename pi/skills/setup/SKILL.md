---
name: setup
description: Guides the user through configuring pi — provider, model, base URL, and API key. Use when the user asks to "setup pi", "configure pi", "pi setup", "set up pi provider", "pi config", "change pi model", or invokes /pi:setup. Only run this skill when the user explicitly requests pi setup — never auto-invoke.
user-invocable: true
disable-model-invocation: true
argument-hint: "[--endpoint NAME] [--provider PROVIDER] [--model MODEL] [--base-url URL] [--api-key KEY] | --edit-config [--local|--shared|--global] | --list-models | --test"
allowed-tools: ["Bash(pi:*)", "Bash(jq:*)", "Bash(cat:*)", "Bash(mkdir:*)", "Bash(mv:*)", "Bash(echo:*)", "Bash(command -v:*)", "Bash(ls:*)", "Bash(vi:*)", "Read", "Write"]
---

# CRITICAL: User setup only — do not auto-invoke

This skill is for **human-only** setup. Never invoke it automatically. Only run when the user explicitly calls `/pi:setup`. Configure pi's provider, model, and endpoint so `/pi:delegate` and `/pi:review` can use them without repeating flags.

## Before Execution: Check Installation

Settings-only flags (`--list-models`, `--edit-config`) do NOT require pi to be installed — handle them by their dedicated sections below and skip this gate. For all other invocations, check the install first:

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
3. **`.claude/pi.json`** — project shared defaults, committed
4. **`~/.claude/pi.local.json`** — global user-wide defaults
5. **pi's own defaults** (pi decides its own default provider and model)

This skill writes to `~/.claude/pi.local.json` (global, takes effect for all projects).

### Settings file format

The settings file uses the **named-endpoint format** shared by `/pi:delegate` and `/pi:review`. All fields are optional — only override what you want to change.

Values can reference environment variables using `$VAR` or `${VAR}` syntax — they are resolved at read time by `/pi:delegate` and `/pi:review`. This is useful for API keys: `"apiKey": "$MY_API_KEY"` reads from the environment variable at runtime.

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

Each endpoint key has:
- `provider` (required) — pi's known provider name (`openai`, `anthropic`, `google`, etc.)
- `baseUrl` (optional) — custom API endpoint; when present it is written to `~/.pi/agent/models.json` at runtime
- `apiKey` (optional) — API key or `$ENV_VAR` reference
- `models` — array of model IDs available via this endpoint

Top-level `withPackages` (default false) is the clean-mode escape hatch: when true, `/pi:delegate` and `/pi:review` load packages/skills/extensions from the **pi CLI home** (`~/.pi`, configured via `pi install` / `pi list` — not Claude Code plugins). Leave it false unless you intentionally want bridge tasks to inherit that interactive pi configuration.

Legacy flat fields (`provider`/`model`/`baseUrl`/`apiKey`) are still honored by the delegate skill as a fallback when no `defaultEndpoint` is set, but new setups should use the endpoint format.

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
echo "To configure, run: /pi:setup --endpoint <name> --provider <name> --model <id> [--base-url <url>]"
echo "Or use interactive mode: /pi:setup --edit-config"
```

Then stop — do not proceed to setup.

### `--edit-config` flag

When `$ARGUMENTS` is exactly `--edit-config` (with an optional scope flag), open the settings file for editing. Three scopes matching the three priority tiers:

| Scope | Flag | Path | Git |
|-------|------|------|-----|
| Project personal | `--edit-config` (default) or `--edit-config --local` | `.claude/pi.local.json` | gitignored |
| Project shared | `--edit-config --shared` | `.claude/pi.json` | tracked |
| Global personal | `--edit-config --global` or `--edit-config -g` | `~/.claude/pi.local.json` | user home |

**Shared scope (`--shared`) is committed to git** — never put a literal `apiKey` in it; use a `$ENV_VAR` reference instead. Literal keys belong in the personal scopes.

```bash
# Detect scope
if [[ "$ARGUMENTS" == *"--global"* || "$ARGUMENTS" == *"-g"* ]]; then
  CONFIG_PATH="$HOME/.claude/pi.local.json"
elif [[ "$ARGUMENTS" == *"--shared"* ]]; then
  CONFIG_PATH=".claude/pi.json"
else
  CONFIG_PATH=".claude/pi.local.json"
fi

# Create if not exists (seed matches the endpoint-based format)
mkdir -p "${CONFIG_PATH%/*}"
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

Report: "Settings file created/opened at `<path>`. Changes take effect on the next `/pi:delegate` invocation." Then stop — do not proceed to setup.

### `--test` flag

When `$ARGUMENTS` includes `--test`, run a quick connectivity test. Build the command as an array so each flag is a distinct argument under both bash and zsh (zsh does not word-split an unquoted `${PROVIDER:+--provider ...}` expansion):

```bash
CMD=(pi -p)
# Provider: use the resolved PROVIDER; else if a custom BASE_URL is set, use the
# models.json key (PROVIDER_KEY, default openai) so the probe reaches the custom endpoint.
if [ -n "$PROVIDER" ]; then
  CMD+=(--provider "$PROVIDER")
elif [ -n "$BASE_URL" ]; then
  CMD+=(--provider "${PROVIDER_KEY:-openai}")
fi
# Only pass --model when set — an empty --model is silently accepted by pi but the
# probe then runs without the intended model (setup never resolves MODEL itself).
[ -n "$MODEL" ] && CMD+=(--model "$MODEL")
CMD+=(--thinking low --no-session --no-context-files --approve --no-extensions --no-skills "Reply with exactly: OK. Model: <model-name>")
# </dev/null: pi -p hangs on a terminal/pipe stdin (mis-detects interactive) — force non-interactive.
"${CMD[@]}" </dev/null
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
| `--endpoint` | Endpoint key name (default `local-proxy`) |
| `--provider` | LLM provider name (`openai`, `anthropic`, `google`, etc.) |
| `--model` | Model ID (e.g. `gemini-3.6-flash-high`, `claude-sonnet-4-20250514`) |
| `--base-url` | Custom API endpoint URL (OpenAI-compatible) |
| `--api-key` | API key for the provider (stored in settings file, or reference `$ENV_VAR`) |

If no flags are provided, use the AskUserQuestion tool to ask the user:

1. **Provider**: What provider do you want to use? (Options: `openai`, `anthropic`, `google`, or "Other" for custom)
2. **Model**: What model ID? (e.g. `gemini-3.6-flash-high`, `claude-sonnet-4-20250514`)
3. **Base URL** (optional): Custom endpoint URL, or empty for the provider's default
4. **API Key** (optional): API key or `$ENV_VAR` reference? (leave empty to use environment variables)

### Step 3: Write configuration

```bash
mkdir -p "$HOME/.claude"

# Read existing config
EXISTING="{}"
if [ -f "$HOME/.claude/pi.local.json" ]; then
  EXISTING=$(cat "$HOME/.claude/pi.local.json")
fi

# Endpoint target: an explicit --endpoint names the key to write; otherwise reconfigure
# the existing defaultEndpoint (so a plain /pi:setup reaches the endpoint the skills read).
ENDPOINT_IS_EXPLICIT="0"
if [[ "$ARGUMENTS" == *"--endpoint"* ]]; then
  ENDPOINT_IS_EXPLICIT="1"
  ENDPOINT="${ENDPOINT:-local-proxy}"
else
  ENDPOINT="${ENDPOINT:-$(echo "$EXISTING" | jq -r 'if .defaultEndpoint and .defaultEndpoint != "" then .defaultEndpoint else "local-proxy" end')}"
fi

# Merge into the endpoints map — only override non-empty fields.
# When an explicit --endpoint is given, make it the default so provider and model
# resolve consistently (see defaultModel note below).
echo "$EXISTING" | jq \
  --arg e "$ENDPOINT" \
  --arg explicit "${ENDPOINT_IS_EXPLICIT:-}" \
  --arg provider "${PROVIDER:-}" \
  --arg model "${MODEL:-}" \
  --arg baseUrl "${BASE_URL:-}" \
  --arg apiKey "${API_KEY:-}" \
  '.endpoints[$e] = (.endpoints[$e] // {provider: (if $provider != "" then $provider else "openai" end)}) |
   .endpoints[$e].provider = (if $provider != "" then $provider else .endpoints[$e].provider end) |
   .endpoints[$e].baseUrl = (if $baseUrl != "" then $baseUrl else .endpoints[$e].baseUrl // "" end) |
   .endpoints[$e].apiKey = (if $apiKey != "" then $apiKey else .endpoints[$e].apiKey // "" end) |
   .endpoints[$e].models = ((.endpoints[$e].models // []) + [($model | select(. != ""))] | unique) |
   .defaultEndpoint = (if $explicit == "1" then $e else (.defaultEndpoint // $e) end) |
   .defaultModel = (if $model != "" then $model else .defaultModel // "" end)' \
  > "$HOME/.claude/pi.local.json.tmp" && \
  mv "$HOME/.claude/pi.local.json.tmp" "$HOME/.claude/pi.local.json"
```

### Step 4: Verify with `--test`

Run the test automatically after writing config. pi has no `--base-url` flag — a custom endpoint goes through `~/.pi/agent/models.json`. Write it there first (idempotent: register baseUrl + model, skip when unchanged), then test:

```bash
# Resolve the agent dir the same way pi-agent does, so setup writes to the
# endpoint pi actually reads (matches AGENT_DIR / PI_CODING_AGENT_DIR overrides).
AGENT_DIR="${AGENT_DIR:-${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}}"

# Ensure the endpoint is in the agent-dir models.json (pi reads endpoints from there)
# Use PROVIDER_KEY for the write so $PROVIDER (possibly empty = pi's default) is untouched.
if [ -n "$BASE_URL" ]; then
  PROVIDER_KEY="${PROVIDER:-openai}"
  mkdir -p "$AGENT_DIR"
  EXISTING=$(cat "$AGENT_DIR/models.json" 2>/dev/null)
  EXISTING="${EXISTING:-{}}"   # empty file (exists but 0 bytes) → {} so jq has valid input
  NEW=$(echo "$EXISTING" | jq -c --arg provider "$PROVIDER_KEY" --arg baseUrl "$BASE_URL" --arg model "$MODEL" \
    '.providers[$provider] = (.providers[$provider] // {}) |
     .providers[$provider].baseUrl = $baseUrl |
     if $model != "" then
       (.providers[$provider].models //= []) |
       .providers[$provider].models |= (
         if any(.id == $model) then . else . + [{id: $model}] end
       )
     else . end')
  if [ "$NEW" != "$EXISTING" ]; then
    echo "$NEW" > "$AGENT_DIR/models.json.tmp" && mv "$AGENT_DIR/models.json.tmp" "$AGENT_DIR/models.json"
  fi
fi

CMD=(pi -p)
# Provider: use the resolved PROVIDER; else if a custom BASE_URL is set, use the
# models.json key (PROVIDER_KEY, default openai) so the probe reaches the custom endpoint.
if [ -n "$PROVIDER" ]; then
  CMD+=(--provider "$PROVIDER")
elif [ -n "$BASE_URL" ]; then
  CMD+=(--provider "${PROVIDER_KEY:-openai}")
fi
# Only pass --model when set — an empty --model is silently accepted by pi but the
# probe then runs without the intended model (setup never resolves MODEL itself).
[ -n "$MODEL" ] && CMD+=(--model "$MODEL")
CMD+=(--thinking low --no-session --no-context-files --approve --no-extensions --no-skills "Reply with exactly: OK. Model: <model-name>")
# Pin the probe to the agent dir we just wrote (matches pi-agent's run pattern).
# </dev/null: pi -p hangs on a terminal/pipe stdin (mis-detects interactive).
PI_CODING_AGENT_DIR="$AGENT_DIR" "${CMD[@]}" </dev/null
```

Report success or failure to the user.

### Step 5: Summary

Show the final configuration and tell the user:

```
pi configured successfully. Both `/pi:delegate` and `/pi:review` will use these settings by default.

To override for a single invocation:
  /pi:delegate <task> --endpoint <name> --model <id>
  /pi:review --endpoint <name> --model <id>

To edit manually:
  /pi:setup --edit-config

To view current config:
  /pi:setup --list-models
```

## Common configurations

### OpenAI-compatible endpoint (with custom base URL)

Configure an endpoint in `~/.claude/pi.local.json`:

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

Or via `/pi:setup --edit-config --global`.

### Anthropic direct

```bash
/pi:setup --endpoint anthropic-direct --provider anthropic --model claude-sonnet-4-20250514
```

### Google Gemini direct

```bash
/pi:setup --endpoint google --provider google --model gemini-3.6-flash-high
```

## References

- `/pi:delegate` — delegates coding tasks to pi
- `/pi:review` — reviews code via pi with read-only tools
- `~/.claude/pi.local.json` — global user settings (read by both delegate and review)
