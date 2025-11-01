# Cursor Integration Guide

## Generated Assets

Run `pnpm build:prompts` to populate:

- `dist/cursor/commands/<plugin>/<slug>.md`
- `dist/manifest.json` (lists included commands/agents)

## Installation

1. Copy generated commands into Cursor: `cp dist/cursor/commands/<plugin>/*.md ~/.cursor/commands/`.
2. In Cursor, run `Reload Cursor Commands` via the palette.
3. Use the configured triggers (e.g. `/hierarchical`).

## Notes

- Cursor ignores `!\`` shell interpolation, so the generator converts context commands into inline backticks.
- Adjust `globs` and `tags` in the YAML source if you need narrower scope.
- Rules are additive; delete files from `~/.cursor/rules` to disable a workflow.
