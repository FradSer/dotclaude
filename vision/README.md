# Vision Bridge (vision)

Give non-vision models (e.g. `deepseek-*`) eyes for **image file paths**, via a
`UserPromptSubmit` hook that describes images with an **independent vision
provider** and injects the text into the prompt:

1. **Automatic** — mention an image path ("what's in `/tmp/photo.png`?") and the
   hook (`hooks/bridge_file_paths.py`) describes the file and injects the text.
   No proxy, no daemon.
2. **On demand** — `scripts/vision_proxy.py describe <path>` prints a
   description, and `scripts/vision_proxy.py doctor` verifies the vision config.

The vision provider is a separate multimodal service configured under
`vision.json` — never the Claude Code gateway credentials. The vision model
chain defaults to `gemini-3.1-flash-image,gemini-3-flash-agent`.

## What it covers — and what it doesn't

| Scenario | Layer | How |
|---|---|---|
| Image file path in text (`/tmp/x.png`) | **hook** | Hook reads the prompt, describes the file, injects the description. Automatic. |
| Quick description of one image | **describe** | `vision_proxy.py describe /path/to/img.png` |
| Pasted screenshot (image block) | **not supported** | A `UserPromptSubmit` hook cannot see or remove image blocks from the outbound `messages[]`. Non-vision models (deepseek) cannot receive pasted screenshots — use a vision-capable model, or save the image and `describe` the path. |

There is intentionally no transparent proxy. Pasted-screenshot bridging was
removed in 0.2.0: the proxy could rewrite image blocks, but it required an
`ANTHROPIC_BASE_URL` override and a constantly running daemon. The hook + on
demand describe cover the file-path cases with none of that machinery.

## Requirements

- Python 3.10+ with `httpx` (installed automatically via `uv run`).
- **Vision provider** — a multimodal service reachable as an OpenAI-compatible
  endpoint (`POST /v1/chat/completions` with an `image_url` content part), with
  its **own** `apiKey`. Deliberately independent of the Claude Code gateway and
  its credentials.

## Installation

1. Install the plugin from the `frad-dotclaude` marketplace (or add this
   directory to your plugin dirs).
2. Make `scripts/vision_proxy.py` executable:
   ```bash
   chmod +x scripts/vision_proxy.py
   ```

## Usage

**Automatic (hook):** just mention an image path — "what's in `/tmp/photo.png`?"
— the hook describes it and injects the text. Works out of the box.

**On demand:**

```bash
scripts/vision_proxy.py describe /tmp/photo.png          # print description
scripts/vision_proxy.py describe /tmp/photo.png --prompt "What color is this?"
scripts/vision_proxy.py doctor                            # verify config + endpoint
```

`describe` prints a labeled description:

```text
[Image 1/1 (image/png, described by gemini-3.1-flash-image)]
A green field with a white line across the middle.
```

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
`${VAR}` syntax — resolved at read time. This is useful for API keys:
`"apiKey": "$VISION_API_KEY"` reads from the environment variable at runtime.

```json
// <project>/.claude/vision.local.json — copy examples/vision.local.example.json
{
  "baseUrl": "http://your-vision-provider:port",
  "model": "gemini-3.1-flash-image,gemini-3-flash-agent",
  "apiKey": "$VISION_API_KEY"
}
```

### Configuration keys

| Key | Purpose | Default |
|---|---|---|
| `baseUrl` | Vision provider base URL (OpenAI-compatible). **Required**. | *(unset)* |
| `model` | Comma-separated fallback chain of vision models, tried in order until one succeeds. | `gemini-3.1-flash-image,gemini-3-flash-agent` |
| `apiKey` | Key for the vision provider. Supports `$VAR` / `${VAR}` env var syntax. | *(required)* |
| `describeFilePaths` | Also describe image file paths in text | `true` |
| `maxImageBytes` | Skip image files larger than this | `20971520` (20 MiB) |
| `hookEnabled` | `false` disables the UserPromptSubmit hook | `true` |

Legacy keys (`nonVisionModels`, `visionBaseUrl`, `visionPrompt`, `upstreamUrl`,
`upstream.url`, `vision.baseUrl`, `vision.model`, `vision.apiKey`,
`vision.prompt`) still work for backward compatibility. `blockedModels` /
`nonVisionModels` are ignored — they belonged to the removed proxy.

Most of this config is sensitive (provider key) — keep it in the gitignored
`vision.local.json` layer.

## Hook setup

The hook (`hooks/bridge_file_paths.py`) needs no `ANTHROPIC_BASE_URL` change —
it only needs the vision config so it can describe files. The plugin's
`plugin.json` registers it automatically when the plugin is installed. It
reuses the exact same `vision.json` config as the CLI (`baseUrl`, `model`,
`apiKey`, `maxImageBytes`), so one config file covers both. Set
`hookEnabled: false` to disable the hook's work.

## Troubleshooting

- **`doctor` fails on the vision endpoint** — `doctor` probes each model in the
  `model` chain with a plain-text "ping"; a model may be cooling down
  (rate-limited) on the gateway. Try `describe` on a real image, or check
  `~/.vb/` logs if you were running the old proxy.
- **"No vision endpoint / no vision key"** — `baseUrl` and `apiKey` are not set
  in any `vision.json` layer. Run `scripts/vision_proxy.py doctor`.
- **"What's in this pasted screenshot?" doesn't work on deepseek** — expected:
  image blocks can't reach a non-vision model. Save the screenshot and
  `describe <path>`, or switch to a vision-capable model.

## Files

- `hooks/bridge_file_paths.py` — UserPromptSubmit hook; auto-describes image
  file paths in the prompt.
- `scripts/vision_proxy.py` — `describe` + `doctor` CLI (`uv run` single file;
  deps auto-install). Also the config + describe engine shared with the hook.
- `skills/bridge/SKILL.md` — management command (`/vision:bridge`).
