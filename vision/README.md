# Vision Bridge (vision)

Give non-vision models (e.g. `deepseek-*`) eyes, fully automatically, via two
layers:

1. **UserPromptSubmit hook** (`hooks/bridge_file_paths.py`) — when you type an
   image file path (e.g. "what's in `/tmp/photo.png`?"), the hook describes it
   with a vision model and injects the text. No proxy required for this path.
2. **Transparent local proxy** (`scripts/vb_proxy.py`) — sits between Claude
   Code and your gateway (`ANTHROPIC_BASE_URL`). For **pasted screenshots** the
   proxy replaces the image block with vision-described text before forwarding.
   A hook cannot do this — it cannot see or remove image blocks from the
   outbound request.

Both use a vision-capable model on your gateway (`gemini-3.1-flash-image` by
default). Everything else passes through byte-for-byte.

Fixes: `400 invalid_request_error: Failed to deserialize the JSON body ... unknown variant 'image_url', expected 'text'`.

## How the proxy works

```
Claude Code ──ANTHROPIC_BASE_URL──▶ vision proxy (127.0.0.1:8731)
                                        │  model matches VB_NON_VISION_MODELS
                                        │  + messages contain image blocks?
                                        │    → describe via gateway vision model
                                        ▼  (image block → text block)
                                    your gateway (upstream)
```

- Bridging is **opt-in per model**: only requests whose model matches
  `VB_NON_VISION_MODELS` (default `deepseek`) are bridged. All other models
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
- A gateway that exposes:
  - an **Anthropic Messages** endpoint (`POST /v1/messages`) — your upstream;
  - a **vision model** reachable as an OpenAI-compatible endpoint
    (`POST /v1/chat/completions` with an `image_url` content part). The same
    gateway works for both (the `vb` plugin was tested against a CLI Proxy API
    gateway that serves `gemini-3.1-flash-image`).
- Auth token for both endpoints (`ANTHROPIC_AUTH_TOKEN` or `ANTHROPIC_API_KEY`,
  or `VB_VISION_API_KEY` for the vision endpoint).

## Installation

1. Install the plugin from the `frad-dotclaude` marketplace (or add this
   directory to your plugin dirs).
2. Make `scripts/vb_proxy.py` executable:
   ```bash
   chmod +x scripts/vb_proxy.py
   ```
3. Note the real upstream gateway URL — the value of `ANTHROPIC_BASE_URL`
   **before** you point it at the proxy. Example: `http://10.10.0.195:8317`.

## Usage

### 1. Start the proxy

```bash
export VB_UPSTREAM_URL="http://<your-gateway>:<port>"   # the REAL upstream
export ANTHROPIC_AUTH_TOKEN="..."                        # auth for gateway + vision
scripts/vb_proxy.py start        # detach; logs to ~/.vb/proxy.log
scripts/vb_proxy.py status       # running?
scripts/vb_proxy.py doctor       # verify config, upstream, vision endpoint
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
real gateway — `VB_UPSTREAM_URL` must be set explicitly (it can no longer fall
back to `ANTHROPIC_BASE_URL`, which is now the proxy itself). `doctor` detects
this loop and tells you.

### 3. Use it

**File paths (hook, no proxy needed):** just mention an image path —
"what's in `/tmp/photo.png`?" — the hook describes it and injects the text.

**Pasted screenshots (proxy):** paste a screenshot and chat normally with a
`deepseek-*` model — the proxy describes it and answers.

**Standalone:** `scripts/vb_proxy.py describe /path/img.png` prints a
description on demand.

### 4. Stop the proxy

```bash
scripts/vb_proxy.py stop
```

## Hook setup

The hook (`hooks/bridge_file_paths.py`) needs no `ANTHROPIC_BASE_URL` change —
it only needs the vision config so it can describe files. The plugin's
`plugin.json` registers it automatically when the plugin is installed. It
reuses the same config as the proxy:

| Variable | Purpose |
|---|---|
| `VB_HOOK_ENABLED` | `0` to disable the hook's work (default `1`) |
| `VB_VISION_BASE_URL` | Vision endpoint (else `VB_UPSTREAM_URL`) |
| `VB_VISION_MODEL` / `VB_VISION_API_KEY` / `VB_VISION_PROMPT` | Vision model, key, prompt |
| `VB_MAX_IMAGE_BYTES` | Skip image files larger than this |

Set these in the environment or `~/.vb.env` so the hook process sees them.

## Configuration (proxy)

All variables are resolved progressively: **process env → `~/.vb.env` (script
dir, then cwd, then home; home wins) → default**.

| Variable | Purpose | Default |
|---|---|---|
| `VB_PORT` | Listen port | `8731` |
| `VB_UPSTREAM_URL` | Upstream gateway base URL (required) | `ANTHROPIC_BASE_URL` |
| `VB_NON_VISION_MODELS` | Comma-separated substrings; model matches any → bridged. `""` disables bridging | `deepseek` |
| `VB_VISION_BASE_URL` | Vision endpoint base URL | `VB_UPSTREAM_URL` |
| `VB_VISION_MODEL` | Vision model served by the gateway | `gemini-3.1-flash-image` |
| `VB_VISION_API_KEY` | Key for vision endpoint | `ANTHROPIC_AUTH_TOKEN` → `ANTHROPIC_API_KEY` |
| `VB_VISION_PROMPT` | Instruction sent with each image | "Describe this image faithfully…" |
| `VB_DESCRIBE_FILE_PATHS` | Also describe image file paths in text | `1` |
| `VB_MAX_IMAGE_BYTES` | Skip image files larger than this | `20971520` (20 MiB) |

Example `~/.vb.env`:

```bash
VB_UPSTREAM_URL=http://10.10.0.195:8317
VB_NON_VISION_MODELS=deepseek
VB_VISION_MODEL=gemini-3.1-flash-image
```

## Manual describe (no proxy)

```bash
scripts/vb_proxy.py describe /path/to/image.png --prompt "What color is this?"
# [Image 1/1 (image/png, described by gemini-3.1-flash-image)]
# Green
```

## Troubleshooting

- **`400 ... unknown variant 'image_url'`** — still happens directly against
  the gateway. Make sure requests go through the proxy and the model matches
  `VB_NON_VISION_MODELS`.
- **`doctor` says "points at this proxy"** — `VB_UPSTREAM_URL` is unset and
  `ANTHROPIC_BASE_URL` is the proxy. Set `VB_UPSTREAM_URL` to the real gateway.
- **Proxy won't start** — run `scripts/vb_proxy.py doctor`; it names the missing
  config.
- **Log** — `~/.vb/proxy.log` shows each bridged image (`[vb] bridged 1 image(s)
  for model ...`).

## Files

- `hooks/bridge_file_paths.py` — UserPromptSubmit hook; auto-describes image
  file paths in the prompt (no proxy needed).
- `scripts/vb_proxy.py` — the proxy (`uv run` single file; deps auto-install).
- `skills/bridge/SKILL.md` — management command (`/vision:bridge`).
