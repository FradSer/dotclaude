# Multi-Assistant Prompt Schema

## Overview

This project now models marketplace content as platform-agnostic prompts stored under `prompts/` (one subdirectory per plugin). Each directory contains a lightweight `plugin.yaml` plus granular command/agent files, then rendered for Claude, Cursor, Codex, and Gemini by platform-specific generators. Platform capability metadata lives in `config/platforms`.

## Prompt Definition

- `version`: schema revision for backwards compatibility.
- `plugin.yaml`: top-level metadata (`id`, `label`, `category`, `summary`, `tags`).
- `commands/<slug>.yaml`: reusable workflows with fields:
  - `slug`, `title`, `summary`, optional `argument_hint`.
  - `instructions`: canonical Markdown body (shared across platforms).
  - `follow_up`: structured actions such as `offer_fix_implementation`.
  - Platform-specific tweaks (模型、命名空间、触发词等) 建议集中在独立的映射文件内（例如 `config/platform-mapping.yaml`），由生成器统一套用，避免在每个命令中重复 `platform_overrides`。
- `agents/<slug>.yaml`: specialized reviewers with `slug`, `summary`, `model`, `instructions`。平台差异同样建议集中维护，保持 YAML 主体平台无关。

## Platform Manifests

Per-assistant capability files describe output folders and supported metadata:

- `config/platforms/claude.yaml` — Claude marketplace front matter requirements.
- `config/platforms/cursor.yaml` — Cursor workspace rule expectations (front matter, tags, palette mapping).
- `config/platforms/codex.yaml` — Copilot/Codex prompt and snippet outputs.
- `config/platforms/gemini.yaml` — Gemini command TOML structure and namespace expectations.

Generators will write rendered assets into:

- `dist/cursor/commands/....md`
- `dist/codex/prompts/<plugin>-<slug>.md`
- `dist/gemini/commands/....toml`
- (Claude continues to use `plugins/<pack>/...` for marketplace exports.)

## Next Steps

1. Port remaining plugins into `prompts/<plugin>/` following this structure.
2. Implement build scripts under `scripts/build/` that hydrate each platform directory from the canonical YAML.
3. Update documentation (`docs/{cursor,codex,gemini}.md`) with platform-specific import instructions once generators ship.
