# Image Prompting & Parameter Reference (gemini / openai backends)

Read this when crafting a non-trivial prompt or when you need the exact flag behavior.
The script has two explicit backends (`--backend gemini` | `--backend openai`, no default);

## How to write a strong prompt

Both backends reward described scenes, not keyword soup. Aim for one vivid paragraph
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

### Editing with an input image (`-i`)

When you pass `-i`, the prompt is an instruction *about* the supplied image:

- **Edit**: state the change AND what to preserve — "replace the daytime sky with a starry night;
  keep the building, people, and warm street lights unchanged."
- **Compose** (gemini only): "place the product from image 1 onto the marble surface from image
  2, matching the lighting of image 2." Reference images by order ("image 1", "image 2").
- **Restyle**: "redraw this photo as a clean black-and-white line-art storyboard panel."

Backend differences:

- **gemini** accepts multiple `-i` images and composes them (full multimodal input).
- **openai** uses `/images/edits`, which accepts a **single** image; if you pass multiple `-i`
  flags, only the first is used (a note is printed).

## Examples

**Gemini, fresh generation:**
```bash
generate_image.py "a red bicycle leaning on a brick wall, golden hour" --backend gemini \
  -o bike.png --aspect-ratio 3:2 --size 2K
```
Prompt to use: `A sleek red bicycle leaning against a weathered brick wall, golden-hour side
light, shallow depth of field, photorealistic, calm and warm mood.`

**Gemini, two-image compose:**
```bash
generate_image.py "put the watch from image 1 on the wrist in image 2, match image 2's lighting" \
  --backend gemini -i watch.png -i wrist.png -o composite.png
```

**OpenAI-compatible gateway, gpt-image-2:**
```bash
generate_image.py "a red bicycle leaning on a brick wall, golden hour" --backend openai \
  --base-url https://api.tu-zi.com/v1 --model gpt-image-2 --size 1024x1024 \
  --response-format url -o bike.png
```

## Parameter reference

| Flag | gemini | openai |
|------|--------|--------|
| `--backend` | `gemini` | `openai` |
| `--aspect-ratio` | via `image_config.aspect_ratio` | via `extra_body.aspect_ratio` (Gemini-compat endpoints only; OpenAI proper ignores) |
| `--size` | `1K` / `2K` / `4K` (via `image_config.image_size`) | free string (`1024x1024`, `1536x1536`, `auto`, ...) — OpenAI `size` param |
| `--count` | N separate calls (one image per call) | one call with `n=N` |
| `-i, --input` | repeatable; full multimodal edit/compose | single image for `/images/edits`; first wins if repeated |
| `--model` | `pro` / `flash` alias, or raw id (else `GEMINI_IMAGE_MODEL`) | raw id, e.g. `gpt-image-2` (else `OPENAI_IMAGE_MODEL`/`IMAGE_MODEL`) |
| `--quality` | not applicable | `low` / `medium` / `high` / `auto` (also `OPENAI_IMAGE_QUALITY`) |
| `--response-format` | not applicable | `b64_json` / `url` / `none` (also `IMAGE_RESPONSE_FORMAT`) |
| `--base-url` | not applicable (uses Google's API) | OpenAI-compatible base URL (also `IMAGE_BASE_URL`/`OPENAI_BASE_URL`) |
| `--api-key` | `GEMINI_API_KEY` / `GOOGLE_API_KEY` | `OPENAI_API_KEY` / `IMAGE_API_KEY` |

## Configuration resolution (progressive)

Every configurable value is resolved by `lib/progressive_env.py` as
**CLI flag → process env → `.env` chain → default**, lazily and per-value:

| Value | Env vars | Default |
|-------|----------|---------|
| Backend | `IMAGE_BACKEND` | — (required; `--backend` or env) |
| API key (gemini) | `GEMINI_API_KEY` / `GOOGLE_API_KEY` | — (required) |
| API key (openai) | `OPENAI_API_KEY` / `IMAGE_API_KEY` | — (required) |
| Base URL (openai) | `IMAGE_BASE_URL` / `OPENAI_BASE_URL` | — (required; no built-in default) |
| Model (gemini) | `GEMINI_IMAGE_MODEL` | `pro` (`gemini-3-pro-image`) |
| Model (openai) | `OPENAI_IMAGE_MODEL` / `IMAGE_MODEL` | — (required; must name a model) |
| Quality (openai) | `OPENAI_IMAGE_QUALITY` | unset (model decides) |
| Response format (openai) | `IMAGE_RESPONSE_FORMAT` | `b64_json` |

The `.env` chain is `$PWD/.env`, then `${CLAUDE_PLUGIN_ROOT}/.env`, then this script's
directory. A value already set in the real environment is trusted over a `.env` file.

## Using the openai backend with compatible gateways

The openai backend targets any OpenAI-compatible image endpoint. Point `--base-url` at the
gateway and `--model` at a model it serves:

```bash
# OpenAI official — gpt-image-2
generate_image.py "a red bicycle" --backend openai --base-url https://api.openai.com/v1 --model gpt-image-2 -o oai.png
# DashScope compatible mode
generate_image.py "测试" --backend openai --base-url https://dashscope.aliyuncs.com/compatible-mode/v1 --model gpt-image-2 -o dash.png
# A new-api gateway
generate_image.py "测试" --backend openai --base-url https://api.tu-zi.com/v1 --model gpt-image-2 --response-format url -o gw.png
```

Gateway-specific gotchas (the script surfaces these as clean errors, but worth knowing):

- **`--response-format`** — some gateways only return `url` and hang on `b64_json` (e.g. tu-zi
  for gpt-image-2); others reject the param outright. Use `--response-format url` or `none` there.
- **`--quality`** is OpenAI-specific; a Gemini-compat base URL silently ignores it.
- **`--aspect-ratio`** travels via `extra_body` and is honored by Gemini-compat endpoints; OpenAI
  proper ignores it — use `--size` there instead.
- **Edits (`-i`)** use `/images/edits`, which only some endpoints implement.
- **HTTP transport** — the script forces HTTP/1.1 for the openai backend because some gateways
  mishandle HTTP/2 on the long (~60s) image-generation requests.

## Troubleshooting

- **No image returned** — the prompt likely hit a safety filter, or the endpoint rejected the
  request. Reword and retry; check stderr for the HTTP error.
- **`No backend selected`** — pass `--backend gemini` or `--backend openai` (or `export IMAGE_BACKEND=...`).
- **`No base URL set` (openai)** — pass `--base-url` or `export OPENAI_BASE_URL=...`.
- **`No model set` (openai)** — pass `--model` or `export OPENAI_IMAGE_MODEL=...`.
- **`Connection error` / 60s timeout on gpt-image-2** — the gateway likely needs `url` format;
  add `--response-format url`. (The script already forces HTTP/1.1, which is the other common fix.)
- **`Unknown parameter: 'response_format'`** — pass `--response-format none`.
- **`Invalid value: 'standard'` for quality on dall-e-3** — the gateway injected a default the
  upstream rejected. Pass an explicit `--quality` (e.g. `medium`).
- **`--aspect-ratio` has no effect on OpenAI proper** — expected; that param is Gemini-only. Use `--size`.
- **`--size` rejected on gemini** — gemini uses `1K`/`2K`/`4K`, not `1024x1024`.
