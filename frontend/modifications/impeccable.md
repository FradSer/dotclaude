# Modifications — impeccable

Upstream: `pbakaus/impeccable` → `skills/impeccable`
Sync script: `scripts/sync-impeccable.sh`

Upstream ships a single `impeccable` skill (v3.6.0+ consolidated every command into
`reference/<cmd>.md`). The sync script wipes the skill directory and copies upstream
content verbatim — **including upstream's own `SKILL.md`** — then saves that upstream
`SKILL.md` to `reference/upstream-SKILL.md`. The frontend plugin exposes a *curated*
local `SKILL.md` instead (slim entry point + Context Gathering Protocol + sub-command
index). Re-apply the block below after every sync to restore it.

> Why curated rather than upstream-verbatim: upstream's `SKILL.md` is a long
> standalone-CLI guide with `npx impeccable` setup scripts and a 20-command
> argument-hint. The local version is a slim plugin entry that defers the full guide
> to `reference/upstream-SKILL.md` and indexes the sub-commands.

---

## Replace: SKILL.md — curated local entry point

**Target**: `skills/impeccable/SKILL.md`

**Intent**: The sync copies upstream's `SKILL.md` into place; overwrite it with the
curated local version below. This is the plugin's user-facing `/impeccable` entry: it
keeps context-gathering enforcement and a sub-command index, and points to
`reference/upstream-SKILL.md` for the full upstream design guide. Keep the reference
links in sync with the files that actually exist under `reference/` (the post-sync
`check-references.sh` run will flag any that don't).

**Content**: overwrite the entire file with:

````markdown
---
name: impeccable
description: Create distinctive, production-grade frontend interfaces with high design quality. Generates creative, polished code that avoids generic AI aesthetics. Use when the user asks to build web components, pages, artifacts, posters, or applications, or when any design skill requires project context. Call with 'craft' for shape-then-build, 'teach' for design context setup, or 'extract' to pull reusable components and tokens into the design system.
version: 2.1.1
user-invocable: true
argument-hint: "[craft|teach|extract]"
---

Create distinctive, production-grade frontend interfaces that avoid generic "AI slop" aesthetics. Implement real working code with exceptional attention to aesthetic details and creative choices.

## Context Gathering Protocol

Design skills produce generic output without project context. Confirm design context before any design work.

**Required context** (every design skill needs at minimum):
- **Target audience**: Who uses this product and in what context?
- **Use cases**: What jobs are they trying to get done?
- **Brand personality/tone**: How should the interface feel?

**Gathering order:**
1. Check current instructions for a **Design Context** section -- proceed immediately if found
2. Check `.impeccable.md` from the project root -- proceed if it has the required context
3. Run `/impeccable teach` if neither source has context -- do NOT skip, do NOT infer from codebase

## Design Direction

Commit to a BOLD aesthetic direction with: Purpose, Tone (pick an extreme -- minimalist, maximalist, retro-futuristic, organic, luxury, playful, editorial, brutalist, etc.), Constraints, and Differentiation (the unforgettable element).

## Design Guidelines

See `reference/upstream-SKILL.md` for the full upstream design guide covering:
- Color (contrast floors, tinted neutrals, OKLCH color strategy)
- Typography (line length, font pairing, display clamps, text-wrap)
- Layout (rhythm, cards-are-lazy, flex-vs-grid, semantic z-index)
- Motion (exponential easing, reduced-motion, reveal-on-visible)
- Interaction (stacking-context-safe overlays)
- Absolute bans (match-and-refuse: side-stripe borders, gradient text, glassmorphism, hero-metric, eyebrows) and the AI slop test

Pick the matching register guide before design work:
- `reference/brand.md` -- design IS the product (marketing, landing, campaign, portfolio, long-form)
- `reference/product.md` -- design SERVES the product (app UI, admin, dashboard, tools)

Workflow references:
- `reference/craft.md` -- shape-then-build a feature end-to-end
- `reference/shape.md` -- plan UX/UI before writing code
- `reference/extract.md` -- pull reusable tokens and components into the design system
- `reference/init.md` -- set up project context (PRODUCT.md / DESIGN.md)
- `reference/document.md` -- generate DESIGN.md from existing code
- `reference/interaction-design.md` -- feedback, affordance, state
- `reference/live.md` -- in-browser visual variant iteration

## Sub-commands

Invoke these as `/impeccable <command> [target]`. Each loads its reference file from `reference/<command>.md` and follows that flow. See `reference/upstream-SKILL.md` for the full command table, routing rules, and per-command details.

| Task | Command | What it does |
|------|---------|-------------|
| UX evaluation | `critique` | UX design review with heuristic scoring |
| Quality gate | `audit` | Accessibility, performance, responsive checks |
| Final pass | `polish` | Final quality pass before shipping |
| Performance | `optimize` | Diagnose and fix UI performance |
| More bold | `bolder` | Amplify safe or bland designs |
| Tone down | `quieter` | Reduce visual noise and overstimulation |
| Add color | `colorize` | Strategic color for monochrome interfaces |
| Typography | `typeset` | Font choice, scale, rhythm improvements |
| Add life | `delight` | Personality and memorable touches |
| Push limits | `overdrive` | Maximum visual impact |
| Simplify | `distill` | Strip to essence, remove complexity |
| Better copy | `clarify` | UX copy, error messages, microcopy |
| Add motion | `animate` | Purposeful transitions and motion |
| Responsive | `adapt` | Multi-device, multi-context design |
| Layout | `layout` | Spacing, rhythm, visual hierarchy |
| Shape | `shape` | Plan UX/UI before writing code |
| Resilience | `harden` | Error states, edge cases, i18n |
| First-run | `onboard` | Empty states, activation, first-run flows |
| Generate spec | `document` | Generate DESIGN.md from existing code |
| Browser iterate | `live` | In-browser visual variant iteration |

## Modes

- **Default**: Apply design guidelines and implement working code
- **`craft`**: Shape-then-build flow from `reference/craft.md` -- pass feature description as additional args
- **`teach`**: One-time design context setup -- explore codebase, ask questions, save to `.impeccable.md`
- **`extract`**: Pull reusable components and tokens into the design system per `reference/extract.md`
````

**Added**: 2026-06-16

> Known staleness to revisit (not a sync concern): upstream deprecated `teach` in
> favor of `init` and now uses `PRODUCT.md`/`DESIGN.md` (via `scripts/context.mjs`)
> rather than `.impeccable.md`. The curated entry above still documents the older
> `teach` / `.impeccable.md` convention. Refresh deliberately when revisiting the
> skill's setup flow.
