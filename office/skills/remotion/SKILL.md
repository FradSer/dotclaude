---
name: remotion
version: 1.0.0
description: "Programmatic video creation in React with Remotion. Use this skill whenever the user writes Remotion, npx create-video, remotion studio/render/still, useCurrentFrame/interpolate/Sequence, Composition, Mediabunny, or any React-driven video/animation/caption/motion-graphics task — including scaffolding a project, writing markup, rendering/exporting (incl. transparent), adding captions/subtitles, making Studio-editable animations, building a Remotion SaaS (Player/Lambda/Vercel/Cloudflare), or getting media metadata. Do NOT use for ffmpeg-only pipelines, video.js/players, WebRTC live streaming, framer-motion web animation, or After Effects."
metadata:
  tags: [remotion, video, react, animation, composition, render, captions, saas]
---

# Remotion Skills

This skill is a router for all Remotion video-creation operations. It mirrors the upstream `remotion-dev/skills` repository. Based on user intent, read the corresponding sub-skill `SKILL.md` before executing.

**Sub-skills are authoritative.** The files under each sub-skill directory are upstream content kept verbatim — do not edit them; re-sync from upstream instead. The table below is the index, the sub-skill `SKILL.md` is the instruction.

## Sub-skill Index

| Sub-skill | Directory | Use When |
|-----------|-----------|----------|
| New Project | `remotion-create/` | Scaffold a new Remotion project (`npx create-video`), design a video, start the Studio preview |
| React Markup | `remotion-markup/` | Writing Remotion React markup — the core: animations, media, sequences, timing, fonts, effects, maps, Lottie, DOM measurement, transitions, trimming |
| Rendering | `remotion-render/` | Rendering videos and stills (`npx remotion render/still`), transparent videos |
| Captions | `remotion-captions/` | Transcribing, importing SRT, and displaying captions/subtitles |
| Interactivity | `remotion-interactivity/` | Making animations editable in Remotion Studio Visual Mode |
| SaaS / Apps | `remotion-saas/` | Building video apps — `<Player>`, rendering on Lambda/Vercel/Cloudflare/Node, client-side rendering, choosing a framework |
| Mediabunny | `mediabunny/` | Multimedia handling in the browser — get audio/video duration, get video dimensions |

## How to route

1. Identify the user's intent against the **Use When** column.
2. If the task spans several domains (e.g. "build a Remotion SaaS that renders captions"), load each relevant sub-skill in the order the task needs them.
3. Read the sub-skill's `SKILL.md`, then follow any `references/`-style `.md` files it points to (each sub-skill folder carries its own detail files).
4. Sub-skills reference each other via relative paths like `../remotion-markup/SKILL.md` — these resolve within this `remotion/` directory.

## Notes on cross-references

Some upstream sub-skill files contain links like `[Remotion Best Practices](../remotion-best-practices/SKILL.md)`. There is no `remotion-best-practices/` directory here — that role is filled by this top-level `SKILL.md`. Treat such links as "go back to the Remotion router" (i.e. this file). All other sibling cross-references (`../remotion-markup/SKILL.md`, `../remotion-captions/SKILL.md`, etc.) resolve correctly.
