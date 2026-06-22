---
name: generate-image
description: Generate or edit images from a text prompt using Google's Gemini 3 Pro Image model. Use this skill whenever the user wants to create, generate, draw, render, illustrate, or mock up an image, picture, illustration, concept art, storyboard panel, icon, logo, poster, or product shot — and also when they want to edit, restyle, retouch, combine, or extend an existing image. Triggers include "generate an image", "make a picture of", "draw me", "create an illustration", "生成图片", "画一张", "做一张图", "P 一下这张图", or any request that should produce a PNG/JPEG from a description. Prefer this skill over describing an image in text.
user-invocable: true
argument-hint: "\"PROMPT\" [-o out.png] [-i input.png ...] [--aspect-ratio 16:9] [--size 2K] [--count N]"
allowed-tools: ["Read", "Write", "AskUserQuestion", "Bash(uv run:*)", "Bash(*/generate_image.py:*)"]
---

# Generate Image (Gemini 3 Pro Image)

Turn a text prompt — optionally with reference images — into one or more images
using the `gemini-3-pro-image` model. The script does the API call, file saving,
and configuration; your job is to craft a strong prompt and wire up the flags.

## Prerequisites

- `uv` available (the script is a self-contained `uv run` script; deps install on first run).
- A Google AI Studio key. The script resolves it progressively, so any one of these works:
  - `export GEMINI_API_KEY=...` in the shell, or
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
| `-i, --input` | Reference/input image to edit or compose; repeatable | none |
| `--aspect-ratio` | `1:1 2:3 3:2 3:4 4:3 4:5 5:4 9:16 16:9 21:9` | model decides |
| `--size` | `1K` / `2K` / `4K` | model decides |
| `--count` | Number of candidates (each is a separate call; one image per call) | 1 |
| `--model` | `pro`, `flash`, or a raw id (else `GEMINI_IMAGE_MODEL`) | `pro` |

**Models** (pass the alias to `--model` or set `GEMINI_IMAGE_MODEL`):

| Alias | Model id | Use for |
|-------|----------|---------|
| `pro` (default) | `gemini-3-pro-image` | highest quality, up to 4K |
| `flash` | `gemini-3.1-flash-image` | faster / cheaper drafts |

When the user wants choices to pick from, request `--count 2` (or more) and show all outputs.
With `-i`, the prompt becomes an edit/compose instruction over the supplied image(s).

### 4. Report

Tell the user the saved path(s). If nothing was returned, it is usually a safety-filtered
prompt — say so and offer a reworded prompt. Output files are images: reference them by path;
do not try to inline their bytes.

## Configuration is progressive (the key best practice)

Key, model id, and the API key are each resolved by `lib/progressive_env.py` in this order,
stopping at the first hit: **CLI flag → process env → `.env` chain → built-in default**. This
is why the same command works in a project with a local `.env`, in a shell with exports, or
with everything overridden inline — and why a newer model can be selected with
`export GEMINI_IMAGE_MODEL=...` without touching code. See `references/prompting.md` for the
parameter reference.

## Files

- `scripts/generate_image.py` — the generator (Gemini 3 Pro Image via `google-genai`).
- `references/prompting.md` — prompt-writing guide and full parameter reference.
- `${CLAUDE_PLUGIN_ROOT}/lib/progressive_env.py` — shared progressive config resolver.
