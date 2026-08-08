---
name: bridge
description: Management command for the Vision Bridge. Invoke ONLY when the user explicitly asks to start/stop/status/doctor the vision proxy or describe an image file (e.g. "start the vision proxy", "vision status", "vision doctor", "describe this image"). Do not invoke on ordinary image questions — file-path descriptions are handled automatically by the plugin's UserPromptSubmit hook.
user-invocable: true
argument-hint: "start|stop|status|doctor|describe <path>"
allowed-tools: ["Bash(*vision_proxy.py:*)", "Bash(vision_proxy.py:*)"]
---

# Vision Bridge management

Manage the Vision Bridge components: the `UserPromptSubmit` hook
(`hooks/bridge_file_paths.py`) and the transparent proxy
(`scripts/vision_proxy.py`). Both give non-vision models (deepseek, ...) eyes by
describing images with an independent vision provider. The hook runs
automatically; the proxy must be started and `ANTHROPIC_BASE_URL` pointed at it
(see README).

**Human-invoked only.** This command is for people to manage the bridge. It is
not triggered by image questions — the hook and proxy handle those automatically.

## Commands

Run the proxy script via `${CLAUDE_PLUGIN_ROOT}/scripts/vision_proxy.py`:

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/vision_proxy.py <subcommand>
```

| Subcommand | Purpose |
|---|---|
| `start` | Start the proxy (detached). Also prints config errors up front. |
| `stop` | Stop the proxy. |
| `status` | Is it running? |
| `doctor` | Verify config + upstream + vision endpoints. Exit 0 = all good. |
| `describe <path>` | Describe one local image file; print the text. |

`start` inherits the current environment. The proxy reads the three-layer
`vision.json` config, but env vars set in the calling session also apply (they
win over the JSON). The proxy logs to `~/.vb/proxy.log` and records its PID in
`~/.vb/proxy.pid`.

- **After `start`**, run `status` to confirm it is alive, then `doctor`.
- **`doctor`** probes `POST /v1/messages` on the upstream and `POST /v1/chat/completions` on the vision endpoint.
- **`describe <path>`** is the only command needed when the user just wants a quick description; it needs no proxy running.

## Configuration (three-layer `vision.json`)

Reads `vision.json` from three layers, later layers overriding earlier ones
(resolution: **process env → `~/.claude/vision.json` → `<project>/.claude/vision.json` → `<project>/.claude/vision.local.json` → default**). Values can reference environment variables using `$VAR` or `${VAR}` syntax — resolved at read time. The local layer is gitignored — most of this config is sensitive (gateway URL, provider key).

| Key | Purpose | Default |
|---|---|---|
| `port` | Listen port | `8731` |
| `baseUrl` | Upstream gateway and vision provider base URL. **Required**. | `ANTHROPIC_BASE_URL` |
| `blockedModels` | List (or comma string) of model substrings to bridge. Empty list disables bridging. | `["deepseek"]` |
| `model` | Comma-separated fallback chain of vision models, tried in order until one succeeds. | `gemini-3.1-flash-image,gemini-3-flash-agent` |
| `apiKey` | Key for the vision provider. Supports `$VAR` / `${VAR}` env var syntax. | *(required)* |
| `describeFilePaths` | Also describe image file paths in text. | `true` |
| `maxImageBytes` | Refuse to describe image files larger than this. | `20971520` |
| `hookEnabled` | `false` disables the hook's work. | `true` |

**Legacy keys** (`nonVisionModels`, `visionBaseUrl`, `visionPrompt`, `upstreamUrl`, `upstream.url`, `vision.baseUrl`, `vision.model`, `vision.apiKey`, `vision.prompt`) still work for backward compatibility.

If `baseUrl` is unset and `ANTHROPIC_BASE_URL` already points at the proxy, `doctor` reports a loop-detection error: set `baseUrl` to the real gateway explicitly.

## Notes

- The proxy streams responses (SSE) and does not buffer; it forwards all headers and the `anthropic-beta` header verbatim.
- When a vision description fails, the image block is replaced with a short placeholder text rather than dropping the request.
- Bridging only applies to models matching `blockedModels`; all other traffic passes through untouched.