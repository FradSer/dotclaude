---
name: generate-image
description: Generate or edit images from a text prompt via one of two explicit backends — Google Gemini (gemini-3-pro-image, native SDK, with aspect-ratio / image-size / multi-image compose) or any OpenAI-compatible endpoint (gpt-image-2, dall-e-3, custom base_url / api_key). Use this skill whenever the user wants to create, generate, draw, render, illustrate, or mock up an image, picture, illustration, concept art, storyboard panel, icon, logo, poster, or product shot — and also when they want to edit, restyle, retouch, combine, or extend an existing image. Triggers include "generate an image", "make a picture of", "draw me", "create an illustration", "生成图片", "画一张", "做一张图", "P 一下这张图", or any request that should produce a PNG/JPEG from a description. Prefer this skill over describing an image in text.
user-invocable: true
argument-hint: "\"PROMPT\" --backend gemini|openai [-o out.png] [-i input.png ...] [--aspect-ratio 16:9] [--size 2K|1024x1024] [--count N] [--model ...] [--base-url URL]"
allowed-tools: ["Read", "Write", "AskUserQuestion", "Bash(uv run:*)", "Bash(*/generate_image.py:*)"]
---

# Generate Image (gemini / openai backends)

Turn a text prompt — optionally with reference images — into one or more images
via one of two explicit backends. **`--backend` has no default** — always pick
one (`gemini` or `openai`), or set `IMAGE_BACKEND`. The script does the API
call, file saving, and configuration; your job is to pick the backend, craft a
strong prompt, and wire up the flags.

- **`gemini`** — Google's native Gemini API via `google-genai`. Full feature
  set: `--aspect-ratio`, `--size` tiers (`1K`/`2K`/`4K`), and multi-image
  edit/compose (`-i a.png -i b.png`). Use `GEMINI_API_KEY` / `GEMINI_IMAGE_MODEL`.
- **`openai`** — any OpenAI-compatible image endpoint (OpenAI official,
  DashScope, new-api gateways, ...). Use `OPENAI_API_KEY` / `OPENAI_BASE_URL` /
  `OPENAI_IMAGE_MODEL`. Supports `gpt-image-2`, `dall-e-3`, etc.

## Prerequisites

- `uv` available (the script is a self-contained `uv run` script; deps install on first run).
- The API key for the chosen backend. The script resolves it progressively, so any one works:
  - `export GEMINI_API_KEY=...` (gemini backend) or `export OPENAI_API_KEY=...` (openai backend), or
  - a `.env` file (checked in order: `$PWD/.env`, then `${CLAUDE_PLUGIN_ROOT}/.env`), or
  - `--api-key ...` on the command line.

  **CRITICAL** -- Never paste the API key into chat or commit a `.env`. If the key is missing,
  the script prints exactly how to set it — relay that to the user rather than guessing.

## Workflow

### 1. Clarify intent (only if genuinely ambiguous)

A one-line request like "draw a fox in a spacesuit" needs no questions — just generate.
Ask (via AskUserQuestion) only when a choice would materially change the result and you
cannot reasonably default it, e.g. aspect ratio for a "banner vs. avatar", or whether an
attached image should be *edited* vs. used as *style reference*.

### 2. Craft the prompt

Read `references/prompting.md` before writing a non-trivial prompt. In short: describe
subject, composition, lighting, style, and mood in concrete terms; put any literal text to
render in quotes; and for edits, state what to change AND what to keep. A vivid one-paragraph
prompt beats a terse phrase.

### 3. Run the script

Invoke it directly (the shebang runs it through `uv`):

```bash
${CLAUDE_PLUGIN_ROOT}/skills/generate-image/scripts/generate_image.py "PROMPT" --backend BACKEND -o OUT.png [flags]
```

Flags:

| Flag | Purpose | Default |
|------|---------|---------|
| `--backend` | `gemini` (native Google API) or `openai` (OpenAI-compatible endpoint). No default — also via `IMAGE_BACKEND`. | required |
| `-o, --output` | Output path (`.png`/`.jpeg`) | `generated.png` |
| `-i, --input` | Reference/input image (repeatable). gemini: edit/compose multi-image. openai: edit single image (first wins). | none |
| `--aspect-ratio` | `1:1 2:3 3:2 3:4 4:3 4:5 5:4 9:16 16:9 21:9`. gemini: via `image_config`. openai: via `extra_body` (Gemini-compat endpoints only). | model decides |
| `--size` | gemini: `1K`/`2K`/`4K`. openai: free string (`1024x1024`, `auto`, ...). | model decides |
| `--count` | Number of images. gemini: N separate calls. openai: one call, `n=N`. | 1 |
| `--model` | Model id or alias (else `GEMINI_IMAGE_MODEL`/`OPENAI_IMAGE_MODEL`). gemini: `pro`/`flash`/raw id. openai: raw id (e.g. `gpt-image-2`). | backend default |
| `--quality` | `low`/`medium`/`high`/`auto` — openai backend only. | model decides |
| `--response-format` | `b64_json`/`url`/`none` — openai backend only. `url` is downloaded to disk; `none` omits the param. Some gateways require `url` or reject the param (use `none`). | `b64_json` |
| `--base-url` | openai backend only: OpenAI-compatible base URL. Also via `IMAGE_BASE_URL`/`OPENAI_BASE_URL`. | required for openai |
| `--api-key` | Override the API key (else `GEMINI_API_KEY` for gemini, `OPENAI_API_KEY` for openai). | required |

**Models** (pass the alias to `--model` or set the backend's env var):

| Backend | Alias / id | Notes |
|---------|-----------|-------|
| gemini | `pro` (default) → `gemini-3-pro-image` | highest quality |
| gemini | `flash` → `gemini-2.5-flash-image` | faster / cheaper |
| openai | `gpt-image-2`, `dall-e-3`, `gpt-image-1`, ... | any id the endpoint serves |

**Examples:**

```bash
# Gemini, 2K wide banner
generate_image.py "podcast cover art" --backend gemini --aspect-ratio 16:9 --size 2K -o cover.png
# Gemini multi-image compose
generate_image.py "put the watch from image 1 on the wrist in image 2" --backend gemini -i watch.png -i wrist.png -o composite.png
# OpenAI-compatible gateway, gpt-image-2 (this gateway needs url format)
generate_image.py "a red bicycle" --backend openai --base-url https://api.tu-zi.com/v1 \
  --model gpt-image-2 --size 1024x1024 --response-format url -o bike.png
# OpenAI official
generate_image.py "a red bicycle" --backend openai --base-url https://api.openai.com/v1 --model gpt-image-2 -o bike.png
```

When the user wants choices to pick from, request `--count 2` (or more) and show all outputs.
With `-i`, the prompt becomes an edit/compose instruction over the supplied image(s).

### 4. Report

Tell the user the saved path(s). If nothing was returned, it is usually a safety-filtered
prompt — say so and offer a reworded prompt. Output files are images: reference them by path;
do not try to inline their bytes.

## Configuration is progressive (the key best practice)

Backend, key, base URL, model, and quality are each resolved by
`lib/progressive_env.py` in this order, stopping at the first hit: **CLI flag →
process env → `.env` chain → built-in default**. This is why the same command
works in a project with a local `.env`, in a shell with exports, or with
everything overridden inline — and why a newer model or a different endpoint can
be selected with `export GEMINI_IMAGE_MODEL=...` / `export OPENAI_BASE_URL=...`
without touching code. See `references/prompting.md` for the parameter reference.

## Files

- `scripts/generate_image.py` — the generator (`google-genai` for gemini, `openai` for openai).
- `references/prompting.md` — prompt-writing guide and full parameter reference.
- `${CLAUDE_PLUGIN_ROOT}/lib/progressive_env.py` — shared progressive config resolver.
