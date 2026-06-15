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

## Specialized Skills

Apply these skills for targeted improvements. Each is a standalone skill in this plugin:

| Task | Skill | What it does |
|------|-------|-------------|
| UX evaluation | `impeccable-critique` | Nielsen's 10 Usability Heuristics scoring |
| Quality gate | `impeccable-audit` | Accessibility, performance, standards checks |
| Final pass | `impeccable-polish` | Alignment, typography, spacing fixes |
| Performance | `impeccable-optimize` | Rendering, paint, layout optimization |
| More bold | `impeccable-bolder` | Amplify safe designs to be distinctive |
| Tone down | `impeccable-quieter` | Reduce visual noise and overstimulation |
| Add color | `impeccable-colorize` | Strategic color for monochrome interfaces |
| Typography | `impeccable-typeset` | Font choice, scale, rhythm improvements |
| Add life | `impeccable-delight` | Moments of joy and personality |
| Push limits | `impeccable-overdrive` | Maximum visual impact |
| Simplify | `impeccable-distill` | Strip to essence |
| Better copy | `impeccable-clarify` | UX copy, error messages, microcopy |
| Add motion | `impeccable-animate` | Purposeful transitions |
| Responsive | `impeccable-adapt` | Multi-device, multi-context design |
| Layout | `impeccable-layout` | Grid, flex, spatial organization |
| Shape | `impeccable-shape` | Visual form refinement |
| Resilience | `impeccable-harden` | Error states, edge cases, defensive design |

## Modes

- **Default**: Apply design guidelines and implement working code
- **`craft`**: Shape-then-build flow from `reference/craft.md` -- pass feature description as additional args
- **`teach`**: One-time design context setup -- explore codebase, ask questions, save to `.impeccable.md`
- **`extract`**: Pull reusable components and tokens into the design system per `reference/extract.md`
