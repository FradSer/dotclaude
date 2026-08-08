# Vision Bridge (vision)

Give non-vision models (e.g. `deepseek-*`) eyes, fully automatically, via two
layers:

1. **UserPromptSubmit hook** (`hooks/bridge_file_paths.py`) — when you type an
   image file path (e.g. "what's in `/tmp/photo.png`?"), the hook describes it
   with a vision model and injects the text. No proxy required for this path.
2. **Transparent local proxy** (`scripts/vision_proxy.py`) — sits between Claude
   Code and your gateway (`ANTHROPIC_BASE_URL`). For **pasted screenshots** the
   proxy replaces the image block with vision-described text before forwarding.
   A hook cannot do this — it cannot see or remove image blocks from the
   outbound request.

Both use an **independent vision provider** (a separate multimodal service,
configured under `vision.*` — never your Claude Code gateway credentials). The
vision model chain defaults to `gemini-3.1-flash-image,gemini-3-flash-agent`.
Everything else passes through byte-for-byte.

Fixes: `400 invalid_request_error: Failed to deserialize the JSON body ... unknown variant 'image_url', expected 'text'`.

## How the proxy works

```
Claude Code ──ANTHROPIC_BASE_URL──▶ vision proxy (127.0.0.1:8731)
                                        │  model matches nonVisionModels
                                        │  + messages contain image blocks?
                                        │    → describe via independent vision
                                        │      provider (vision.baseUrl/model)
                                        ▼  (image block → text block)
                                    your gateway (upstream)
```

- Bridging is **opt-in per model**: only requests whose model matches
  `nonVisionModels` (default `["deepseek"]`) are bridged. All other models
  (vision-capable or unknown) pass through untouched.
- Handles both **pasted screenshots** (Anthropic `image` content blocks) and
  **image file paths** mentioned in text (e.g. `/path/to/photo.png`), described
  via the vision endpoint.
- Streams responses (SSE) with proper chunked framing; never buffers a full
  response. Verified against the Claude Code gateway protocol.

## Hook vs proxy: which handles what

| Scenario | Layer | Why |
|---|---|---|
| Image file path in text (`/tmp/x.png`) | **hook** | Hook reads the prompt text, describes the file, injects the description. Automatic, no proxy needed. |
| Pasted screenshot (image block) | **proxy** | A `UserPromptSubmit` hook cannot see or remove image blocks from the outbound `messages[]` — it only injects text or blocks the prompt. The only interception point that can rewrite the request body is the layer `ANTHROPIC_BASE_URL` points at. The proxy is that layer. |

So the hook gives you file-path coverage with zero setup, and the proxy covers
screenshots when you point `ANTHROPIC_BASE_URL` at it. (Verified against current
Claude Code docs.)

## Requirements

- Python 3.10+ with `httpx` (installed automatically via `uv run`).
- **Upstream** — your Claude Code gateway, exposing an Anthropic Messages
  endpoint (`POST /v1/messages`), with its own auth (`ANTHROPIC_AUTH_TOKEN` or
  `ANTHROPIC_API_KEY`).
- **Vision provider** — a separate multimodal service, reachable as an
  OpenAI-compatible endpoint (`POST /v1/chat/completions` with an `image_url`
  content part), with its **own** `vision.apiKey`. This is deliberately
  independent of the upstream gateway and its credentials.

## Installation

1. Install the plugin from the `frad-dotclaude` marketplace (or add this
   directory to your plugin dirs).
2. Make `scripts/vision_proxy.py` executable:
   ```bash
   chmod +x scripts/vision_proxy.py
   ```
3. Note the real upstream gateway URL — the value of `ANTHROPIC_BASE_URL`
   **before** you point it at the proxy. Example: `http://10.10.0.195:8317`.

## Usage

### 1. Start the proxy

```bash
# The proxy reads the three-layer vision.json; env vars also work as overrides.
# upstream = Claude Code's real gateway; vision = independent provider.
export ANTHROPIC_AUTH_TOKEN="..."    # auth for the upstream gateway only
scripts/vision_proxy.py start        # detach; logs to ~/.vb/proxy.log
scripts/vision_proxy.py status       # running?
scripts/vision_proxy.py doctor       # verify config, upstream, vision endpoint
```

`doctor` prints the effective config and probes both endpoints. Exit 0 = ready.

### 2. Point Claude Code at the proxy

Set in `~/.claude/settings.json` (or your project's `.claude/settings.json`):

```json
{
  "env": {
    "ANTHROPIC_BASE_URL": "http://127.0.0.1:8731"
  }
}
```

**Important:** once Claude Code points at the proxy, the proxy must know the
real gateway — `upstream.url` must be set explicitly (it can no longer fall back
to `ANTHROPIC_BASE_URL`, which is now the proxy itself). `doctor` detects this
loop and tells you.

### 3. Use it

**File paths (hook, no proxy needed):** just mention an image path —
"what's in `/tmp/photo.png`?" — the hook describes it and injects the text.

**Pasted screenshots (proxy):** paste a screenshot and chat normally with a
`deepseek-*` model — the proxy describes it and answers.

**Standalone:** `scripts/vision_proxy.py describe /path/img.png` prints a
description on demand.

### 4. Stop the proxy

```bash
scripts/vision_proxy.py stop
```

## Hook setup

The hook (`hooks/bridge_file_paths.py`) needs no `ANTHROPIC_BASE_URL` change —
it only needs the vision config so it can describe files. The plugin's
`plugin.json` registers it automatically when the plugin is installed. It
reuses the exact same `vision.json` config as the proxy (`vision.baseUrl`,
`vision.model`, `vision.apiKey`, `maxImageBytes`), so one config file covers
both. Set `hookEnabled: false` to disable the hook's work.

## Configuration: three-layer `vision.json`

The plugin mirrors Claude Code's own settings layering. Config lives in
**`vision.json`** files (JSON objects whose keys are the config names below),
read from three layers, later layers overriding earlier ones:

| Layer | File | Scope |
|---|---|---|
| 1. Global | `~/.claude/vision.json` | user-wide defaults |
| 2. Project | `<project>/.claude/vision.json` | checked into the project |
| 3. Local | `<project>/.claude/vision.local.json` | gitignored, machine-local overrides |

Resolution order for every variable: **process env → layer 1 → layer 2 →
layer 3 → default**. Process env vars always win; the local layer wins over
project and global. Values can reference environment variables using `$VAR` or
`${VAR}` syntax — resolved at read time. This is useful for API keys: `"apiKey": "$MY_API_KEY"` reads from the environment variable at runtime.

```json
// <project>/.claude/vision.local.json — copy examples/vision.local.example.json
{
  "baseUrl": "http://your-gateway-host:port",
  "blockedModels": ["deepseek"],
  "model": "gemini-3.1-flash-image,gemini-3-flash-agent",
  "apiKey": "$VISION_API_KEY"
}
```

### Configuration keys

| Key | Purpose | Default |
|---|---|---|
| `port` | Listen port | `8731` |
| `baseUrl` | Upstream gateway and vision provider base URL. **Required**. | `ANTHROPIC_BASE_URL` |
| `blockedModels` | List (or comma string) of model substrings to bridge. Empty list disables bridging. | `["deepseek"]` |
| `model` | Comma-separated fallback chain of vision models. | `gemini-3.1-flash-image,gemini-3-flash-agent` |
| `apiKey` | Key for the vision provider. Supports `$VAR` / `${VAR}` env var syntax. | *(required)* |
| `describeFilePaths` | Also describe image file paths in text | `true` |
| `maxImageBytes` | Skip image files larger than this | `20971520` (20 MiB) |
| `hookEnabled` | `false` disables the UserPromptSubmit hook | `true` |

The vision provider reuses the upstream gateway — `baseUrl` serves both. The
hook and proxy read the same three layers, so one config file covers both. A
template lives at `examples/vision.local.example.json`. Legacy keys
(`nonVisionModels`, `visionBaseUrl`, `visionPrompt`, `upstreamUrl`,
`upstream.url`, `vision.baseUrl`, `vision.model`, `vision.apiKey`,
`vision.prompt`) still work for backward compatibility.

Most of this config is sensitive (gateway URL, provider key) — keep it in the
gitignored `vision.local.json` layer.

## Manual describe (no proxy)

```bash
scripts/vision_proxy.py describe /path/to/image.png --prompt "What color is this?"
# [Image 1/1 (image/png, described by gemini-3.1-flash-image)]
# Green
```

## Troubleshooting

- **`400 ... unknown variant 'image_url'`** — still happens directly against
  the gateway. Make sure requests go through the proxy and the model matches
  `nonVisionModels`.
- **`doctor` says "points at this proxy"** — `upstream.url` is unset and
  `ANTHROPIC_BASE_URL` is the proxy. Set `upstream.url` to the real gateway.
- **Proxy won't start** — run `scripts/vision_proxy.py doctor`; it names the missing
  config.
- **Log** — `~/.vb/proxy.log` shows each bridged image (`[vb] bridged 1 image(s)
  for model ...`).

## Files

- `hooks/bridge_file_paths.py` — UserPromptSubmit hook; auto-describes image
  file paths in the prompt (no proxy needed).
- `scripts/vision_proxy.py` — the proxy (`uv run` single file; deps auto-install).
- `skills/bridge/SKILL.md` — management command (`/vision:bridge`).
