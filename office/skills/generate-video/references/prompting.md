# Video Prompting & Parameter Reference (Seedance on Volcengine Ark)

Read this when crafting a non-trivial prompt or when you need exact flag/role behavior.

## How to write a strong prompt

Seedance responds well to prompts that describe the shot **over time** plus the camera and what
must stay fixed. A reliable structure:

1. **Lock the viewpoint / style** up front — "first-person AR-glasses POV, eye-level, steady" or
   "black-and-white line-art storyboard style, bold black border, do not add color."
2. **Beat the action by timestamp** — `[0s-2s] establish … [2s-5s] hands lift into frame … [5s-8s]
   the panel turns from green to full color … [8s-10s] settle, clean hold.`
3. **Direct the camera explicitly** — "slow, small push-in, no large moves, no shake."
4. **State the constraints** — what NOT to do ("no distortion, no lens flare, do not turn the simple
   HUD into a complex UI"). Negative guidance matters a lot for keeping clips on-style.

Keep total motion calm unless the user wants energy — over-asking for action causes warping.

## Image-to-video: preserve the source

When anchoring with `--first-frame`, tell the model which traits of the still to keep, or the clip
drifts away from it:

> "Use the reference image as the exact starting frame. Keep its composition, character, line-art
> style and black border unchanged. Add only restrained motion: gentle breathing, a small head turn,
> the floating HUD card bobbing slightly. Do not recolor; stay pure black and white."

With both `--first-frame` and `--last-frame`, describe the *transition* between them.

## Roles (how images attach)

The `content` array sends each image with a role. Convenience flags map to roles:

| You pass | Role sent | Meaning |
|----------|-----------|---------|
| `--first-frame img` | `first_frame` | img is the opening frame |
| `--last-frame img` | `last_frame` | img is the closing frame (morph target) |
| `--image path` | `reference_image` | style/composition guidance, not a fixed frame |
| `--image path:first_frame` | `first_frame` | explicit role form |

## Examples

**Text-to-video:**
`generate_video.py "Cinematic drone shot rising over a misty pine forest at sunrise; slow, smooth ascent; warm light breaking through; no text." --resolution 1080p --duration 5`

**Animate a storyboard panel (image-to-video):**
`generate_video.py "Keep the B&W line-art panel and its black border exactly; add only gentle breathing and a small floating HUD bob; very slow tiny push-in; no color, no distortion." --first-frame panel_03.png -o panel_03.mp4 --duration 5 --resolution 480p`

**First→last morph:**
`generate_video.py "Smoothly transform the start frame into the end frame over the clip; steady eye-level camera; the green UI panel fills with full color from the point of contact; clean settle." --first-frame green_ui.png --last-frame color_ui.png --duration 10`

## Parameter reference

| Flag | Values | Notes |
|------|--------|-------|
| `--ratio` | `16:9` `9:16` `1:1` `4:3` `3:4` `21:9` `adaptive` | Sent as top-level `ratio`. |
| `--duration` | integer `4`–`15` s (Seedance 2.0) | Sent as `duration`. Longer = costlier/slower. |
| `--resolution` | `480p` `720p` `1080p` | Sent as `resolution`. No 2K/4K on Ark. Fast model caps at `720p`. Use `480p` for cheap drafts. |
| `--watermark` | flag | Off by default (`watermark: false`); pass to keep it on. |
| `--no-audio` | flag | Seedance 2.0 produces native synced audio by default (`generate_audio: true`); pass to silence. |
| `--seed` | integer | Sent as `seed` only when given; fixes output for reproducibility. |
| `--first-frame`/`--last-frame`/`--image` | file paths | Become image parts with a role (table above). |
| `--model` | `pro` / `fast` / `mini` / raw id | `pro`=`doubao-seedance-2-0-260128` (default), `fast`=`…-fast-260128` (720p max), `mini`=`…-mini-260615`. Also via `SEEDANCE_MODEL`. |

## API contract (for reference)

- **Create**: `POST {ARK_BASE_URL}/contents/generations/tasks` with
  `{model, content:[{type:"text",text}, {type:"image_url",image_url:{url:<data-uri>},role}], ratio, duration, resolution, watermark, generate_audio[, seed]}`.
  Returns `{id}`. (In Seedance 2.0 these are top-level JSON fields; the legacy `--flag` suffixes
  appended to the prompt text still parse but validate weakly — prefer the JSON fields.)
- **Poll**: `GET {ARK_BASE_URL}/contents/generations/tasks/{id}` every 10s. Status flows
  `queued → running → succeeded`; terminal failure states are `failed`, `cancelled`, `expired`
  (the script treats all three as errors). 
- **Result**: video URL at `content.video_url` (signed MP4, ~24h TTL); the script downloads it to `--output`.

## Configuration resolution (progressive)

Every configurable value is resolved by `lib/progressive_env.py` as
**CLI flag → process env → `.env` chain → default**, lazily and per-value:

| Value | Env var | Default |
|-------|---------|---------|
| API key | `ARK_API_KEY` | — (required) |
| Model id | `SEEDANCE_MODEL` | `pro` (`doubao-seedance-2-0-260128`) |
| Base URL | `ARK_BASE_URL` | `https://ark.cn-beijing.volces.com/api/v3` |

The `.env` chain is `$PWD/.env`, then `${CLAUDE_PLUGIN_ROOT}/.env`, then this script's directory.
A value already set in the real environment is trusted over a `.env` file. Because the model id and
base URL resolve the same way, you can point at a newer Seedance build or another Ark region purely
through env — no code edit.

Model-id reality check: as of mid-2026 the **latest Seedance is 2.0** — there is no "Seedance 3".
Three ids are available, exposed as aliases (the script expands `pro`/`fast`/`mini`; a raw id
passes through unchanged):

| Alias | Model id | Notes |
|-------|----------|-------|
| `pro` (default) | `doubao-seedance-2-0-260128` | full quality, up to 1080p |
| `fast` | `doubao-seedance-2-0-fast-260128` | cheaper / faster, 720p max |
| `mini` | `doubao-seedance-2-0-mini-260615` | lightest / cheapest |

Always confirm the literal `model` string in the Ark console before pinning a new one — a
marketing name is not necessarily the API id.

Regions:
- China (default): `https://ark.cn-beijing.volces.com/api/v3`, ids prefixed `doubao-seedance-…`.
- International (BytePlus ModelArk): `https://ark.ap-southeast.bytepluses.com/api/v3`, ids prefixed
  `dreamina-seedance-…`. To use it, set both `ARK_BASE_URL` and `SEEDANCE_MODEL` accordingly.

## Troubleshooting

- **`ARK_API_KEY is not set`** — set it per the message; create a key at
  https://console.volcengine.com/ark.
- **Task failed** — relay the provider message. Common causes: an unsupported ratio/resolution for
  the chosen model, an over-aggressive prompt (warping), or an invalid source image.
- **Slow** — generation is minutes per task; `480p` + `5s` is the fastest draft loop.
