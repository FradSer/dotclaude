# Image Prompting & Parameter Reference (OpenAI-compatible endpoints)

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

### Editing with an input image (`-i`)

When you pass `-i`, the prompt is an instruction *about* the supplied image:

- **Edit**: state the change AND what to preserve — "replace the daytime sky with a starry night;
  keep the building, people, and warm street lights unchanged."
- **Restyle**: "redraw this photo as a clean black-and-white line-art storyboard panel."

The edit path uses OpenAI's `/images/edits`, which accepts a **single** image. If you pass
multiple `-i` flags, only the first is used (a note is printed). The default Gemini
compatibility endpoint does **not** support `/images/edits`; for edits, point `--base-url` at an
OpenAI-compatible endpoint that does (e.g. `https://api.openai.com/v1` with `--model gpt-image-2`).

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
| `--aspect-ratio` | `1:1 2:3 3:2 3:4 4:3 4:5 5:4 9:16 16:9 21:9` | Gemini endpoint only; sent via `extra_body.aspect_ratio`. OpenAI endpoints ignore it. |
| `--size` | free string (`1024x1024`, `1536x1536`, `auto`, …) | Passed as the OpenAI `size` param. Default `auto`. The Gemini endpoint accepts `size` too; old `1K`/`2K`/`4K` values are not recognized — use `--aspect-ratio` there instead. |
| `--count` | integer | N images in one call (`n=N`); files suffixed `_1`, `_2`, … when > 1. |
| `-i, --input` | file path | Single image for `/images/edits`; first one wins if repeated. Gemini compat endpoint rejects edits. |
| `--model` | `pro` / `flash` / raw id | `pro`=`gemini-3-pro-image` (default), `flash`=`gemini-2.5-flash-image`. A raw id (`gpt-image-2`, …) passes through. Also via `GEMINI_IMAGE_MODEL`/`IMAGE_MODEL`. |
| `--quality` | `low` / `medium` / `high` / `auto` | OpenAI endpoints only; Gemini endpoint ignores. Also via `OPENAI_IMAGE_QUALITY`. |
| `--response-format` | `b64_json` / `url` / `none` | How the image comes back: `b64_json` (decoded inline, default), `url` (downloaded to disk), or `none` (omit the param — for gateways that reject it). Also via `IMAGE_RESPONSE_FORMAT`. |
| `--base-url` | URL | OpenAI-compatible base URL. Default: Gemini compat endpoint. Also via `IMAGE_BASE_URL`/`OPENAI_BASE_URL`. |
| `--api-key` | string | Override the API key. Also via `GEMINI_API_KEY`/`OPENAI_API_KEY`/`IMAGE_API_KEY`. |

## Configuration resolution (progressive)

Every configurable value is resolved by `lib/progressive_env.py` as
**CLI flag → process env → `.env` chain → default**, lazily and per-value:

| Value | Env vars accepted | Default |
|-------|-------------------|---------|
| API key | `GEMINI_API_KEY` / `OPENAI_API_KEY` / `IMAGE_API_KEY` | — (required) |
| Base URL | `IMAGE_BASE_URL` / `OPENAI_BASE_URL` | `https://generativelanguage.googleapis.com/v1beta/openai/` (Gemini compat) |
| Model | `GEMINI_IMAGE_MODEL` / `IMAGE_MODEL` | `pro` (`gemini-3-pro-image`) |
| Quality | `OPENAI_IMAGE_QUALITY` | unset (model decides) |
| Response format | `IMAGE_RESPONSE_FORMAT` | `b64_json` |

The legacy `GEMINI_API_KEY` / `GEMINI_IMAGE_MODEL` names are still honored so existing `.env`
files and exports keep working unchanged; the `OPENAI_*` / `IMAGE_*` names are the generic
alternatives. The `.env` chain is `$PWD/.env`, then `${CLAUDE_PLUGIN_ROOT}/.env`, then this
script's directory. A value already set in the real environment is trusted over a `.env` file.

## Using an OpenAI-compatible backend

The default base URL is Google's Gemini OpenAI-compatibility endpoint, so Gemini image models
work with zero config. To target OpenAI proper or any compatible service, override `--base-url`
(and usually `--model`):

```bash
# OpenAI official — gpt-image-2
generate_image.py "a red bicycle" --base-url https://api.openai.com/v1 --model gpt-image-2 -o oai.png
# DashScope compatible mode
generate_image.py "测试" --base-url https://dashscope.aliyuncs.com/compatible-mode/v1 --model gpt-image-2 -o dash.png
# A self-hosted gateway
generate_image.py "hero shot" --base-url https://gateway.internal/v1 --model gpt-image-2 -o hero.png
```

Endpoint-specific behavior to keep in mind:

- **`--aspect-ratio`** travels via `extra_body.aspect_ratio` and is honored by the Gemini
  compatibility endpoint; OpenAI endpoints silently ignore it. For OpenAI, steer dimensions via
  `--size` (`1024x1024`, `1536x1536`, …) instead.
- **`--quality`** is sent only when set and is honored by OpenAI endpoints; the Gemini
  compatibility endpoint silently ignores it.
- **Edits (`-i`)** use `/images/edits`, which only OpenAI-compatible endpoints implement. The
  Gemini compatibility endpoint does not document it; the script refuses the edit path there and
  tells the user to point `--base-url` at an endpoint that supports edits.

## Troubleshooting

- **No image returned** — the prompt likely hit a safety filter (real people, explicit content,
  some logos/celebrities), or the endpoint rejected the request. Reword and retry; check stderr
  for the HTTP error if the endpoint rejected the call.
- **`No API key set`** — set `GEMINI_API_KEY` (default Gemini endpoint, key at
  https://aistudio.google.com/app/apikey) or `OPENAI_API_KEY` (OpenAI-compatible endpoints).
- **Edit rejected on the Gemini endpoint** — `/images/edits` is not supported there; point
  `--base-url` at an OpenAI-compatible endpoint (e.g. `https://api.openai.com/v1`).
- **`--aspect-ratio` has no effect on OpenAI** — expected; that param is Gemini-only. Use
  `--size` (`1024x1024`, `1536x1536`, …) on OpenAI endpoints.
- **`--quality` has no effect on Gemini** — expected; that param is OpenAI-only.
- **`Unknown parameter: 'response_format'`** — some compatible gateways reject this param. Pass `--response-format none` (or `export IMAGE_RESPONSE_FORMAT=none`).
- **`Invalid value: 'standard'` for quality on dall-e-3** — the gateway injected a default the upstream rejected. Pass an explicit `--quality` (e.g. `medium`) to override it.
