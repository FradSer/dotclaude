# Interfaces Plugin

Agent skills for building great product interfaces, from typography and color to accessibility and UX writing.

**Version**: 1.0.0

## Installation

```bash
claude plugin install interfaces@frad-dotclaude
```

## Overview

One skill — `better-interface` — owns cross-discipline interface review. Its domain knowledge lives in six reference packs under `skills/better-interface/references/`: accessibility, layout, writing, typography, colors, and ui. Each pack holds an `overview.md` (the domain's core rules) plus topic files (checks, tables, examples).

- **`/better-interface`** — User-invoked, cross-discipline interface review that reads all six domain references, coordinates their rules, and consolidates evidence into one prioritized verdict. Supports `quick` and `full` review modes.

## Structure

```
skills/better-interface/
├── SKILL.md          # Orchestration: scope, modes, consolidation, output format
└── references/       # Domain knowledge, loaded by the orchestrator as needed
    ├── accessibility/    (overview + focus/keyboard, forms, hit areas, ARIA, screen readers)
    ├── colors/           (overview + contrast, conversion, usage, gamut, palettes)
    ├── layout/           (overview + grouping/alignment, spacing/adaptivity)
    ├── typography/       (overview + fonts, CSS, wrapping, spacing, variable fonts)
    ├── ui/               (overview + animations, icons, performance, surfaces)
    └── writing/          (overview)
```

## Skills

- `/better-interface` — slash command (registered under `commands`). The domain references are not standalone skills; they are loaded only through the orchestrator.

## Origin

Forked from [jakubkrehel/skills](https://github.com/jakubkrehel/skills) (see [interfaces.dev](https://interfaces.dev/)).
