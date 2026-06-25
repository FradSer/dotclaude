---
name: generate-image
description: Generate or edit images from a text prompt via any OpenAI-compatible image endpoint (default Gemini 3 Pro Image, or gpt-image-2 / custom base_url). Use this skill whenever the user wants to create, generate, draw, render, illustrate, or mock up an image, picture, illustration, concept art, storyboard panel, icon, logo, poster, or product shot — and also when they want to edit, restyle, retouch, combine, or extend an existing image. Triggers include "generate an image", "make a picture of", "draw me", "create an illustration", "生成图片", "画一张", "做一张图", "P 一下这张图", or any request that should produce a PNG/JPEG from a description. Prefer this skill over describing an image in text.
user-invocable: true
argument-hint: "\"PROMPT\" [-o out.png] [-i input.png ...] [--aspect-ratio 16:9] [--size 1024x1024] [--count N] [--model gpt-image-2] [--base-url URL]"
allowed-tools: ["Read", "Write", "AskUserQuestion", "Bash(uv run:*)", "Bash(*/generate_image.py:*)"]
---

# Generate Image (OpenAI-compatible image endpoints)

Turn a text prompt — optionally with reference images — into one or more images
via any OpenAI-compatible image endpoint. The default base URL points at
Google's Gemini OpenAI-compatibility endpoint, so `gemini-3-pro-image` works out
of the box; pointing `--base-url` at OpenAI proper (or DashScope, or a
self-hosted gateway) switches backends with no code change. The script does the
API call, file saving, and configuration; your job is to craft a strong prompt
and wire up the flags.

## Prerequisites

- `uv` available (the script is a self-contained `uv run` script; deps install on first run).
- An API key for the chosen endpoint. The script resolves it progressively, so any one works:
  - `export GEMINI_API_KEY=...` (default Gemini endpoint) or `export OPENAI_API_KEY=...` (OpenAI-compatible endpoints), or
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
${CLAUDE_PLUGIN_ROOT}/skills/generate-image/scripts/generate_image.py "PROMPT" -o OUT.png [flags]
```

Flags:

| Flag | Purpose | Default |
|------|---------|---------|
| `-o, --output` | Output path (`.png`/`.jpeg`) | `generated.png` |
| `-i, --input` | Reference/input image to edit (OpenAI-compatible endpoints only; Gemini compat endpoint rejects edits) | none |
| `--aspect-ratio` | `1:1 2:3 3:2 3:4 4:3 4:5 5:4 9:16 16:9 21:9` — Gemini endpoint only (via `extra_body`) | model decides |
| `--size` | Free string (e.g. `1024x1024`, `1536x1536`, `auto`) | `auto` |
| `--count` | Number of images (one call, `n=N`) | 1 |
| `--model` | `pro`, `flash`, or a raw id like `gpt-image-2` (else `GEMINI_IMAGE_MODEL`/`IMAGE_MODEL`) | `pro` |
| `--quality` | `low`/`medium`/`high`/`auto` — OpenAI endpoints only (Gemini endpoint ignores) | model decides |
| `--response-format` | `b64_json` / `url` / `none` — how the endpoint returns the image; `url` is downloaded to disk, `none` omits the param. Some compatible gateways reject this param — use `none` there. | `b64_json` |
| `--base-url` | OpenAI-compatible base URL (else `IMAGE_BASE_URL`/`OPENAI_BASE_URL`) | Gemini compat endpoint |
| `--api-key` | Override the API key (else `GEMINI_API_KEY`/`OPENAI_API_KEY`) | required |

**Models** (pass the alias to `--model` or set `GEMINI_IMAGE_MODEL`/`IMAGE_MODEL`):

| Alias | Model id | Use for |
|-------|----------|---------|
| `pro` (default) | `gemini-3-pro-image` | highest quality (default Gemini endpoint) |
| `flash` | `gemini-2.5-flash-image` | faster / cheaper drafts |
| raw id | `gpt-image-2`, `gpt-image-1`, ... | pass through to any endpoint |

**Switching endpoints** — the default base URL is Google's Gemini OpenAI-compatibility
endpoint, so Gemini works with zero config. To use OpenAI proper or any compatible service,
override `--base-url` (and typically `--model`):

```bash
# OpenAI official, gpt-image-2
generate_image.py "a red bicycle" --base-url https://api.openai.com/v1 --model gpt-image-2 -o oai.png
# DashScope compatible mode
generate_image.py "测试" --base-url https://dashscope.aliyuncs.com/compatible-mode/v1 --model gpt-image-2 -o dash.png
```

When the user wants choices to pick from, request `--count 2` (or more) and show all outputs.
With `-i`, the prompt becomes an edit instruction over the supplied image (single image only;
the Gemini compatibility endpoint does not support edits — point `--base-url` at an OpenAI
endpoint for the edit path).

### 4. Report

Tell the user the saved path(s). If nothing was returned, it is usually a safety-filtered
prompt — say so and offer a reworded prompt. Output files are images: reference them by path;
do not try to inline their bytes.

## Configuration is progressive (the key best practice)

Key, base URL, model, and quality are each resolved by `lib/progressive_env.py`
in this order, stopping at the first hit: **CLI flag → process env → `.env`
chain → built-in default**. This is why the same command works in a project with
a local `.env`, in a shell with exports, or with everything overridden inline —
and why a newer model or a different endpoint can be selected with
`export GEMINI_IMAGE_MODEL=...` / `export IMAGE_BASE_URL=...` without touching
code. See `references/prompting.md` for the parameter reference.

## Files

- `scripts/generate_image.py` — the generator (any OpenAI-compatible image endpoint via the `openai` SDK).
- `references/prompting.md` — prompt-writing guide and full parameter reference.
- `${CLAUDE_PLUGIN_ROOT}/lib/progressive_env.py` — shared progressive config resolver.
