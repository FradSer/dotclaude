---
name: generate-video
description: Generate short videos from a text prompt or from still images using ByteDance Seedance on Volcengine Ark (火山方舟). Use this skill whenever the user wants to create, generate, render, or animate a video, clip, animation, motion graphic, or product demo — including text-to-video ("a drone shot over a forest at sunrise") and image-to-video, where a still becomes the first frame, or two stills are morphed start-to-end. Triggers include "generate a video", "make a clip", "animate this image", "turn this storyboard into video", "生成视频", "做个视频", "让这张图动起来", "图生视频", "首尾帧生成视频". Prefer this skill over describing a video in text.
user-invocable: true
argument-hint: "\"PROMPT\" [-o out.mp4] [--first-frame img] [--last-frame img] [--duration 5] [--resolution 720p] [--ratio 16:9] [--no-audio] [--seed N]"
allowed-tools: ["Read", "Write", "AskUserQuestion", "Bash(uv run:*)", "Bash(*/generate_video.py:*)"]
---

# Generate Video (Seedance on Volcengine Ark)

Turn a text prompt — optionally anchored by a first frame, a last frame, or reference
images — into a short video. The script submits an async task, polls until it finishes,
and downloads the `.mp4`. Generation takes a few minutes, so set expectations and let it run.

## Prerequisites

- `uv` available (self-contained `uv run` script; deps install on first run).
- A Volcengine Ark key. Resolved progressively, so any one works:
  - `export ARK_API_KEY=...` in the shell, or
  - a `.env` file (checked in order: `$PWD/.env`, then `${CLAUDE_PLUGIN_ROOT}/.env`), or
  - `--api-key ...` on the command line.

  **CRITICAL** -- Never paste the API key into chat or commit a `.env`. If the key is missing,
  the script prints exactly how to set it — relay that instead of guessing.

## Workflow

### 1. Decide the mode

- **Text-to-video** — prompt only. Best when there is no source image.
- **Image-to-video** — pass `--first-frame img.png`. The still becomes the opening frame and
  the model adds motion. This is the right mode for animating a storyboard panel or product render.
- **First→last morph** — pass both `--first-frame a.png` and `--last-frame b.png` to interpolate
  a transition between two stills.
- **Reference-guided** — `--image path:reference_image` (repeatable) to steer style/composition.

If the user attached an image, default to image-to-video unless they clearly want a fresh scene.

### 2. Craft the prompt

Read `references/prompting.md` before writing a non-trivial prompt. Seedance responds well to
prompts that describe the shot over time (beats like `[0s-2s] … [2s-5s] …`), the camera move,
and what must stay fixed. For image-to-video, explicitly state which traits of the source to
preserve (style, framing, colors) so the clip does not drift.

### 3. Run the script

Invoke it directly (the shebang runs it through `uv`):

```bash
${CLAUDE_PLUGIN_ROOT}/skills/generate-video/scripts/generate_video.py "PROMPT" -o OUT.mp4 [flags]
```

Flags:

| Flag | Purpose | Default |
|------|---------|---------|
| `-o, --output` | Output `.mp4` path | `output.mp4` |
| `--first-frame` | Start-frame image (image-to-video) | none |
| `--last-frame` | End-frame image (morph start→end) | none |
| `--image` | `PATH` or `PATH:ROLE` (`first_frame`/`last_frame`/`reference_image`); repeatable | none |
| `--ratio` | Aspect ratio: `16:9`, `9:16`, `1:1`, … | `16:9` |
| `--resolution` | `480p` / `720p` / `1080p` (no 2K/4K on Ark) | `720p` |
| `--duration` | seconds, `4`–`15` for Seedance 2.0 | 5 |
| `--watermark` | Keep the provider watermark | off |
| `--no-audio` | Disable native audio (2.0 generates synced audio by default) | audio on |
| `--seed` | Integer seed for reproducibility | random |
| `--model` | `pro`, `fast`, `mini`, or a raw id (else `SEEDANCE_MODEL`) | `pro` |

**Models** (pass the alias to `--model` or set `SEEDANCE_MODEL`):

| Alias | Model id | Use for |
|-------|----------|---------|
| `pro` (default) | `doubao-seedance-2-0-260128` | full quality, up to 1080p |
| `fast` | `doubao-seedance-2-0-fast-260128` | cheaper / faster, 720p max |
| `mini` | `doubao-seedance-2-0-mini-260615` | lightest / cheapest |

The script blocks while polling (status prints to stderr). For batch work, prefer longer
single runs over many tiny ones — each task has fixed overhead, and the API bills per task.

### 4. Report

Tell the user the saved path and the settings used (duration, resolution). The output is an
`.mp4`: reference it by path. If a task fails, relay the provider's error message and suggest
a fix (often a softer prompt, a different ratio, or a valid source image).

## Configuration is progressive (the key best practice)

API key, model id, AND base URL are each resolved by `lib/progressive_env.py` in this order,
stopping at the first hit: **CLI flag → process env → `.env` chain → built-in default**.

Two consequences worth knowing:
- **Switch model versions without code changes.** The default is the current
  `doubao-seedance-2-0-260128`; to use a different/newer Seedance build, set
  `export SEEDANCE_MODEL=<id>` (or pass `--model`). Confirm the exact id in the Ark console —
  do not assume a marketing name like "Seedance 3" maps to a literal model id.
- **Switch regions without code changes.** Default base URL is the cn-beijing endpoint; set
  `export ARK_BASE_URL=...` for another Ark region.

## Files

- `scripts/generate_video.py` — the generator (Seedance via Ark REST, async + poll + download).
- `references/prompting.md` — prompt-writing guide and full parameter reference.
- `${CLAUDE_PLUGIN_ROOT}/lib/progressive_env.py` — shared progressive config resolver.
