# Image Prompting & Parameter Reference (Gemini 3 Pro Image)

Read this when crafting a non-trivial prompt or when you need the exact flag behavior.

## How to write a strong prompt

Gemini 3 Pro Image rewards described scenes, not keyword soup. Aim for one vivid paragraph
that covers, roughly in this order:

1. **Subject** — who/what, and any defining detail ("a weathered brass diving helmet").
2. **Composition / shot** — framing and angle ("close-up, slight low angle, centered").
3. **Environment** — setting and background ("on a workbench, blurred workshop behind").
4. **Light** — source, direction, quality ("warm window light from the left, soft shadows").
5. **Style / medium** — "photorealistic", "flat vector", "watercolor", "B&W line art", etc.
6. **Mood / palette** — "calm, muted teal and amber".

Explain *intent* when it helps ("for a podcast cover, so leave headroom at the top for a title").
The model has good judgment; a reason often produces a better layout than a rigid instruction.

### Rendering literal text

Put the exact words in quotes and say where they go: `the sign reads "OPEN 24 HRS" in bold
condensed sans-serif, centered`. Keep on-image text short — long paragraphs render unreliably.

### Editing & composing with input images (`-i`)

When you pass one or more `-i` images, the prompt is an instruction *about* them:

- **Edit**: state the change AND what to preserve — "replace the daytime sky with a starry night;
  keep the building, people, and warm street lights unchanged."
- **Compose**: "place the product from image 1 onto the marble surface from image 2, matching the
  lighting of image 2." Reference images by order ("image 1", "image 2").
- **Restyle**: "redraw this photo as a clean black-and-white line-art storyboard panel."

## Examples

**Concept art (fresh generation):**
Input: `generate_image.py "RayNeo AR glasses product hero shot" -o hero.png --aspect-ratio 16:9 --size 2K`
Prompt to use: `A sleek pair of lightweight AR glasses on a matte concrete pedestal, studio
product photography, three-quarter view, soft key light from upper left with a subtle rim light,
seamless dark-charcoal background, shallow depth of field, premium and minimal mood.`

**Edit:**
Input: `generate_image.py "swap the sky to golden-hour sunset, keep everything else" -i street.png -o street_sunset.png`

**Two-image composition:**
Input: `generate_image.py "put the watch from image 1 on the wrist in image 2, match image 2's lighting" -i watch.png -i wrist.png -o composite.png`

## Parameter reference

| Flag | Values | Notes |
|------|--------|-------|
| `--aspect-ratio` | `1:1 2:3 3:2 3:4 4:3 4:5 5:4 9:16 16:9 21:9` | Omit to let the model choose; passed via `image_config.aspect_ratio`. |
| `--size` | `1K` `2K` `4K` | Resolution tier; passed via `image_config.image_size`. Higher = slower/costlier. |
| `--count` | integer | N images = N separate calls (the model returns one image per call); files suffixed `_1`, `_2`, … |
| `-i, --input` | file paths | Repeatable; each becomes an inline image part for edit/compose. |
| `--model` | `pro` / `flash` / raw id | `pro`=`gemini-3-pro-image` (default, highest quality), `flash`=`gemini-3.1-flash-image` (faster/cheaper). Also via `GEMINI_IMAGE_MODEL`. |
| `--api-key` | string | Last-resort override; prefer env/`.env`. |

## Configuration resolution (progressive)

Every configurable value is resolved by `lib/progressive_env.py` as
**CLI flag → process env → `.env` chain → default**, lazily and per-value:

| Value | Env var | Default |
|-------|---------|---------|
| API key | `GEMINI_API_KEY` (or `GOOGLE_API_KEY`) | — (required) |
| Model id | `GEMINI_IMAGE_MODEL` | `pro` (`gemini-3-pro-image`) |

Two model choices: `pro` = `gemini-3-pro-image` (highest quality, the GA id), `flash` =
`gemini-3.1-flash-image` ("Nano Banana 2", faster and cheaper). The aliases expand to these ids;
a raw id or a future id also works (it passes through unchanged). Avoid the deprecated
`gemini-3-pro-image-preview` (shutdown 2026-06-25). If both `GEMINI_API_KEY` and `GOOGLE_API_KEY`
are set, the Google SDK lets `GOOGLE_API_KEY` win — set only one.

The `.env` chain is `$PWD/.env`, then `${CLAUDE_PLUGIN_ROOT}/.env`, then this script's directory.
A value already set in the real environment is trusted over a `.env` file.

## Troubleshooting

- **No image returned** — the prompt likely hit a safety filter (real people, explicit content,
  some logos/celebrities). Reword and retry.
- **`GEMINI_API_KEY is not set`** — set it per the message; get a key at
  https://aistudio.google.com/app/apikey.
- **Wrong aspect/size ignored** — confirm `google-genai>=1.51.0` is what `uv` resolved; older
  SDKs predate `image_config.image_size`. Note `image_size` requires uppercase `K` (`4K`, not `4k`).
