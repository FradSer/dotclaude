---
name: bridge
description: Management command for the Vision Bridge. Invoke ONLY when the user explicitly asks to start/stop/status/doctor the vision proxy or describe an image file (e.g. "start the vision proxy", "vision status", "vision doctor", "describe this image"). Do not invoke on ordinary image questions — file-path descriptions are handled automatically by the plugin's UserPromptSubmit hook.
user-invocable: true
argument-hint: "start|stop|status|doctor|describe <path>"
allowed-tools: ["Bash(*vb_proxy.py:*)", "Bash(vb_proxy.py:*)"]
---

# Vision Bridge management

Manage the Vision Bridge components: the `UserPromptSubmit` hook
(`hooks/bridge_file_paths.py`) and the transparent proxy
(`scripts/vb_proxy.py`). Both give non-vision models (deepseek, ...) eyes by
describing images with a gateway vision model. The hook runs automatically;
the proxy must be started and `ANTHROPIC_BASE_URL` pointed at it (see README).

**Human-invoked only.** This command is for people to manage the bridge. It is
not triggered by image questions — the hook and proxy handle those automatically.

## Commands

Run the proxy script via `${CLAUDE_PLUGIN_ROOT}/scripts/vb_proxy.py`:

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/vb_proxy.py <subcommand>
```

| Subcommand | Purpose |
|---|---|
| `start` | Start the proxy (detached). Also prints config errors up front. |
| `stop` | Stop the proxy. |
| `status` | Is it running? |
| `doctor` | Verify config + upstream + vision endpoints. Exit 0 = all good. |
| `describe <path>` | Describe one local image file; print the text. |

`start` inherits the current environment, so `VB_*` and `ANTHROPIC_*` variables must be exported in the session that calls it. The proxy logs to `~/.vb/proxy.log` and records its PID in `~/.vb/proxy.pid`.

- **After `start`**, run `status` to confirm it is alive, then `doctor`.
- **`doctor`** probes `POST /v1/messages` on the upstream and `POST /v1/chat/completions` on the vision endpoint.
- **`describe <path>`** is the only command needed when the user just wants a quick description; it needs no proxy running.

## Configuration (progressive: env → `~/.vb.env` → default)

| Variable | Purpose | Default |
|---|---|---|
| `VB_PORT` | Listen port | `8731` |
| `VB_UPSTREAM_URL` | Upstream gateway base URL. **Required** — set to the real gateway (the value `ANTHROPIC_BASE_URL` had before pointing at the proxy). | falls back to `ANTHROPIC_BASE_URL` |
| `VB_NON_VISION_MODELS` | Comma-separated substrings; a request whose model matches any is bridged. Empty string disables bridging. | `deepseek` |
| `VB_VISION_BASE_URL` | Vision endpoint base URL | `VB_UPSTREAM_URL` |
| `VB_VISION_MODEL` | Vision model served by the gateway | `gemini-3.1-flash-image` |
| `VB_VISION_PROMPT` | Instruction sent with each image | "Describe this image faithfully…" |
| `VB_VISION_API_KEY` | Key for the vision endpoint | `ANTHROPIC_AUTH_TOKEN` → `ANTHROPIC_API_KEY` |
| `VB_DESCRIBE_FILE_PATHS` | Also describe image file paths found in text blocks that exist on disk | `1` |
| `VB_MAX_IMAGE_BYTES` | Refuse to describe image files larger than this | `20971520` |
| `VB_HOOK_ENABLED` | `0` disables the hook's work | `1` |

If `VB_UPSTREAM_URL` is unset and `ANTHROPIC_BASE_URL` already points at the proxy, `doctor` reports a loop-detection error: set `VB_UPSTREAM_URL` to the real gateway explicitly.

## Notes

- The proxy streams responses (SSE) and does not buffer; it forwards all headers and the `anthropic-beta` header verbatim.
- When a vision description fails, the image block is replaced with a short placeholder text rather than dropping the request.
- Bridging only applies to models matching `VB_NON_VISION_MODELS`; all other traffic passes through untouched.
