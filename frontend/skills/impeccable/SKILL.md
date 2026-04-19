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

See `reference/SKILL.md` for the full design guide covering:
- Typography (modular scale, fluid sizing, font selection)
- Color & Contrast (OKLCH, 60-30-10 rule, tinted neutrals)
- Layout & Space (4pt scale, semantic tokens, gap not margins)
- Visual Details (absolute bans: side-stripe borders > 1px, gradient text)
- Motion (exponential easing, staggered reveals, transform+opacity only)
- Interaction (optimistic UI, progressive disclosure)
- Responsive (container queries for components)
- UX Writing (every word earns its place)

Detailed reference files for each domain:
- `reference/typography.md` -- Type scale, font selection, line height
- `reference/color-and-contrast.md` -- OKLCH, theming, contrast
- `reference/spatial-design.md` -- Spacing, grid, containment
- `reference/motion-design.md` -- Easing, transitions, orchestration
- `reference/interaction-design.md` -- Feedback, affordance, state
- `reference/responsive-design.md` -- Breakpoints, container queries
- `reference/ux-writing.md` -- Microcopy, labels, error messages
- `reference/craft.md` -- Shape-then-build workflow
- `reference/extract.md` -- Design system extraction

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
