---
name: articulate
description: Precise, shared design vocabulary for articulating design decisions, critiques, and reviews — "say precisely what you mean." Covers ~188 terms across 12 domains (typography, color, iconography, layout, interaction, motion, accessibility, information architecture, copywriting, tools, analysis, components). Use when naming a UI or design property precisely, writing or sharpening design critique / review / handoff copy, describing a visual or interaction issue, or when the exact term is unclear.
metadata:
  source: "Index — index.how/to/articulate (Emil Kowalski & Glenn Menu)"
  url: "https://index.how/to/articulate"
---

# Articulate — Design Vocabulary

**Say precisely what you mean.** Vague design feedback ("make it pop", "feels off", "cleaner") wastes iterations. A shared, precise vocabulary lets you name the exact property, state, or pattern at issue — so reviews, critiques, and handoffs land the first time.

Use this skill to **choose the right word**: when describing a UI issue, writing a critique or review, naming a token, or reaching for a term you half-remember. Reach for the precise term below instead of an approximation; if a needed term isn't here, consult the full reference at `index.how/to/articulate`.

## When to use

- Writing or sharpening **critique / review / audit** copy — name the property, not the vibe.
- **Design handoff / rationale** — communicate decisions in terms a designer and engineer share.
- **Describing a UI/interaction issue** precisely (e.g. "the disabled state relies on opacity, not a muted token").
- Reaching for a term and unsure of the exact word (kerning vs tracking, voice vs tone, WCAG vs APCA).

Pairs with `frontend:impeccable` (design execution), `frontend:impeccable-critique` (heuristic review), and `frontend:web-design-guidelines` (standards) — articulate supplies the words those skills' findings should be written in.

## The 12 domains (quick reference)

Representative terms per domain; see the source for the complete ~188-entry set.

| Domain | Use it to name… | Representative terms |
|--------|-----------------|----------------------|
| **Typography** | letterform spacing, metrics, text behavior | kerning, tracking, leading, x-height, cap height, ligatures, variable fonts, hyphenation, widows/orphans, overflow |
| **Color** | spaces, contrast, semantics | sRGB, P3, OKLCH, WCAG, APCA, semantic tokens, saturation, blend modes, dark mode |
| **Iconography** | icon form & clarity | stroke weight, optical centering, filled vs outlined, pixel hinting, meaning collision |
| **Layout** | spatial organization | flexbox, grid, overflow handling, aspect ratio, breakpoints, responsive |
| **Interaction** | feedback & affordance | hover, focus, active, disabled, affordance, touch target, confirmation pattern |
| **Motion** | timing & coordination | easing curve, duration, stagger, reduced motion, choreography |
| **Accessibility** | inclusive access | WCAG, APCA, screen reader, keyboard navigation, semantic HTML, state communication |
| **Information Architecture** | structure & wayfinding | navigation labeling, progressive disclosure, wayfinding, card sorting |
| **Copywriting** | UI language | microcopy, error messaging, voice vs tone, scannability, destructive-action clarity |
| **Tools** | systems & process | design system, tokens, variables, prototyping, handoff |
| **Analysis** | measurement | A/B test, heatmap, funnel, retention, NPS, scroll depth |
| **Components** | UI building blocks (each with state requirements) | button, input, select, dialog, toast, tooltip, data table, … |

## Principles worth quoting precisely

- **Affordance is signal.** "A button looks pressable." When the signal is missing, users hesitate — name the missing affordance rather than calling it "confusing."
- **State needs its own token.** A disabled state needs a specific muted token, **not opacity alone** — opacity dims everything (including focus rings and text contrast) instead of communicating "unavailable."
- **Focus is mandatory.** A visible focus state is required; "removing it is an accessibility failure," not a style choice.
- **Animate GPU properties.** "Opacity and transform run on the GPU"; animating layout properties (width, height, top, left) "forces the browser to recalculate layout on every frame" — say "this animates layout" when flagging jank.
- **Voice vs tone.** "Voice stays the same regardless of context. Tone shifts within it." Use the two words for different things: voice = brand constant, tone = situational register.

## How to apply

1. When you would write a vague word ("clean", "modern", "pop", "off"), substitute the precise term for the property actually changing.
2. In critiques/reviews, **name the domain + term + state** (e.g. "Interaction: the primary button has no `focus-visible` state" beats "the button feels unfinished").
3. When naming design tokens or describing a system, prefer the established term (semantic token, leading, optical centering) over an invented one.
4. If the exact term isn't above, look it up in the full reference rather than approximating: https://index.how/to/articulate

> Source: **Index** — a design vocabulary guide by Emil Kowalski & Glenn Menu, https://index.how/to/articulate. This skill summarizes the taxonomy and key principles; the full ~188-entry reference lives at the source.
