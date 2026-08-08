---
name: bridge
description: Management command for the Vision helper. Invoke ONLY when the user explicitly asks to describe an image file (e.g. "describe this image", "what's in this image") or check vision config ("vision doctor"). Do not invoke on ordinary image questions — file-path descriptions are handled automatically by the plugin's UserPromptSubmit hook.
user-invocable: true
argument-hint: "describe <path>|doctor"
allowed-tools: ["Bash(*vision_proxy.py:*)", "Bash(vision_proxy.py:*)"]
---

# Vision helper

Give non-vision models (deepseek, ...) eyes for **image file paths** by
describing them with an independent vision provider. Two paths share one
`vision.json` config:

- The `UserPromptSubmit` hook (`hooks/bridge_file_paths.py`) runs automatically:
  mention an image path in your prompt ("what's in `/tmp/photo.png`?") and it
  injects the description as additional context.
- This command's `describe <path>` subcommand describes one image on demand,
  and `doctor` verifies the vision config and endpoint.

**Human-invoked only.** This command is for people to describe a file or check
config. It is not triggered by image questions — the hook handles those
automatically.

## Commands

Run the script via `${CLAUDE_PLUGIN_ROOT}/scripts/vision_proxy.py`:

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/vision_proxy.py <subcommand>
```

| Subcommand | Purpose |
|---|---|
| `describe <path>` | Describe one local image file; print the text. |
| `doctor` | Verify config + vision endpoint. Exit 0 = all good. |

- **`describe <path>`** is the only command needed for a quick description; it
  needs no proxy or hook running.
- **`doctor`** probes `POST /v1/chat/completions` on the vision endpoint with
  each configured model (the fallback chain) and reports the first success.

## Configuration (three-layer `vision.json`)

Reads `vision.json` from three layers, later layers overriding earlier ones
(resolution: **process env → `~/.claude/vision.json` → `<project>/.claude/vision.json` → `<project>/.claude/vision.local.json` → default**). Values can reference environment variables using `$VAR` or `${VAR}` syntax — resolved at read time. The local layer is gitignored — most of this config is sensitive (provider key).

| Key | Purpose | Default |
|---|---|---|
| `baseUrl` | Vision provider base URL (OpenAI-compatible). **Required**. | *(unset)* |
| `model` | Comma-separated fallback chain of vision models, tried in order until one succeeds. | `gemini-3.1-flash-image,gemini-3-flash-agent` |
| `apiKey` | Key for the vision provider. Supports `$VAR` / `${VAR}` env var syntax. | *(required)* |
| `describeFilePaths` | Also describe image file paths in text. | `true` |
| `maxImageBytes` | Refuse to describe image files larger than this. | `20971520` |
| `hookEnabled` | `false` disables the hook's work. | `true` |

**Legacy keys** (`nonVisionModels`, `visionBaseUrl`, `visionPrompt`, `upstreamUrl`, `upstream.url`, `vision.baseUrl`, `vision.model`, `vision.apiKey`, `vision.prompt`) still work for backward compatibility. `blockedModels` / `nonVisionModels` are ignored — they belonged to the removed proxy.

## Notes

- The vision provider is independent of the Claude Code gateway — it uses its
  own `baseUrl` + `apiKey`, never the gateway's `ANTHROPIC_*` credentials.
- This covers **image file paths** in text. Pasted screenshots (image blocks)
  are not visible to a hook; non-vision models cannot receive them — use a
  vision-capable model or `describe <path>` instead.
- When a vision description fails, the hook injects a short error note rather
  than blocking the prompt.
