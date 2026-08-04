# Interfaces Plugin

Agent skills for building great product interfaces, from typography and color to accessibility and UX writing.

**Version**: 1.0.0

## Installation

```bash
claude plugin install interfaces@frad-dotclaude
```

## Overview

This plugin bundles seven discipline-focused skills for interface design and review. Each `better-*` skill owns one domain (accessibility, layout, writing, typography, colors, UI polish); the `better-interface` skill orchestrates them into a single cross-discipline review.

- **`/better-interface`** — User-invoked, cross-discipline interface review that coordinates all six `better-*` skills. Supports `quick` and `full` review modes.
- **`better-accessibility`** — Accessibility rules (WCAG-aligned checks).
- **`better-layout`** — Structure, spacing, and layout rules.
- **`better-writing`** — Copy and UX writing rules.
- **`better-typography`** — Typography and type-scale rules.
- **`better-colors`** — Color usage and contrast rules.
- **`better-ui`** — Visual polish, motion, and UI detail rules.

## Skills

- `/better-interface` — slash command (registered under `commands`). The remaining six skills are internal domain knowledge, loaded automatically during interface review.

## Origin

Forked from [jakubkrehel/skills](https://github.com/jakubkrehel/skills) (see [interfaces.dev](https://interfaces.dev/)).
