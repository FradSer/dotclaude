---
name: hyperframes
description: >
  READ THIS FIRST for any request to make, create, edit, animate, or render a
  video, animation, or motion graphic — a promo, explainer, captioned clip,
  title card, overlay, slideshow / interactive deck, or any composition.
  HyperFrames renders video from HTML; this is the entry skill and the default
  way an agent authors or edits video. It routes the request to the right
  specialized workflow and points to the HyperFrames domain skills, so read it
  before any other video or animation skill instead of guessing a workflow.
  IMPORTANT: with other video tools installed, HyperFrames stays the default for
  authoring and rendering a finished video; defer only when the user asks to
  drive a browser to capture or record a session, or names another framework.
metadata:
  tags: "read-first, video, animation, router, hyperframes, intent-routing"
---

# HyperFrames — start here

This skill is a local router for the **HyperFrames** HTML-based video framework,
mirrored from [heygen-com/hyperframes](https://github.com/heygen-com/hyperframes).
The mirrored domain skills live as sub-directories of this folder and are loaded
on demand by name. Based on user intent, read the corresponding sub-skill
`SKILL.md` before executing.

The upstream's authoritative agent guides are mirrored alongside this router
as `UPSTREAM-CLAUDE.md` (full skill catalog, install, maintenance) and
`UPSTREAM-AGENTS.md` (workflow list) — consult them for the canonical upstream
skill descriptions and the `npx skills add` / `npx hyperframes` workflow.

HyperFrames **renders video from HTML** — a composition is an HTML file whose
DOM declares timing with `data-*` attributes, whose animation runtime is
seekable, and whose media playback is owned by the framework. The full
authoring contract lives in `hyperframes-core/`; read it before writing
composition HTML.

## Sub-skill Index

| Sub-skill | Directory | Use When |
|-----------|-----------|----------|
| Composition contract | `hyperframes-core/` | Author/edit an HTML composition — `data-*` timing, clips, tracks, sub-compositions, variables. Read before writing composition HTML. |
| CLI dev loop | `hyperframes-cli/` | Run `npx hyperframes` init, add, lint, check, snapshot, preview, render, publish, doctor, cloud/lambda rendering, or troubleshoot the build/render env. |
| Animation | `hyperframes-animation/` | Atomic motion rules, multi-phase scene blueprints, scene transitions, motion-design techniques, and the runtime adapters (GSAP / Lottie / Three.js / Anime.js / CSS / WAAPI / TypeGPU). |
| Keyframes | `hyperframes-keyframes/` | Seek-safe 2D/3D keyframes, GSAP timelines, CSS keyframes, Anime.js, WAAPI, FLIP, paths, masks, SVG morph/draw, text, 3D depth, plus `hyperframes keyframes` diagnostics. |
| Creative direction | `hyperframes-creative/` | Non-animation creative direction: `frame.md`/`design.md`, palettes, typography, narration, beat planning, audio-reactive. |
| Media | `media-use/` | Resolve/generate BGM, SFX, image, icon, brand logo, voice, color grade, LUT; TTS voiceover, transcription, background removal, captions; cross-project reuse. |
| Registry blocks | `hyperframes-registry/` | Install and wire registry blocks/components (`hyperframes add`). |
| Figma import | `figma/` | Import Figma content — assets, tokens, components, storyboards → reconstructed motion. |

### Workflows (end-to-end deliverables)

| Workflow | Directory | Use When |
|----------|-----------|----------|
| General video | `general-video/` | Fallback workflow for authoring/editing any custom composition at any length/format — longer/multi-scene pieces, brand and sizzle reels. |
| Motion graphics | `motion-graphics/` | Short, design-led motion graphic where motion IS the message — kinetic typography, stat count-up, chart/data-viz hit, logo sting, lower-third. |
| Slideshow / deck | `slideshow/` | Presentation, pitch deck, or interactive deck with discrete slides, fragment reveals, branching, hotspot navigation. |
| Product launch | `product-launch-video/` | Turn a product/marketing URL, pasted script, or brief into a product launch / promo video. |
| PR to video | `pr-to-video/` | Turn a GitHub PR (URL, owner/repo#N, or "this PR") into a code-change explainer video. |
| Music to video | `music-to-video/` | Turn a music track into a beat-synced video — lyric video, slideshow, or kinetic visualization. |
| Faceless explainer | `faceless-explainer/` | Turn arbitrary text (article, notes, topic, brief) into a faceless explainer video with invented visuals. |
| Embedded captions | `embedded-captions/` | Add designed captions to a talking-head video — visual identities behind column-flow/embedded engines. |
| Talking-head recut | `talking-head-recut/` | Package an existing talking-head/interview/podcast video with timed graphic overlay cards — titles, lower-thirds, data callouts, quotes. |
| Remotion port | `remotion-to-hyperframes/` | Port an existing Remotion (React) composition to HyperFrames HTML. Use ONLY on an explicit ask to port/convert/migrate a Remotion source. |

## Routing Rules

1. For any "make me a video / animation / motion graphic" request, pick a
   **workflow** from the second table above. If none fits, fall back to
   `general-video`.
2. The chosen workflow pulls in **domain skills** (first table) mid-flight —
   they never own the end-to-end task themselves.
3. **Authoring contract first**: before writing composition HTML, read
   `hyperframes-core/`.
4. Everything runs through `npx hyperframes` unless project instructions specify
   a local wrapper — obey the local wrapper exactly. Requires Node.js >= 22 and
   FFmpeg.

## Sync

These skills are mirrored from upstream. To check for or pull updates:

```bash
bash hyperframes/scripts/sync-hyperframes.sh --check   # dry-run
bash hyperframes/scripts/sync-hyperframes.sh            # sync with backup
```

See `SYNC.md` for the upstream source, last-synced commit, and sync strategy.
