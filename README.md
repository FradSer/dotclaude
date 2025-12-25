# FradSer's dotagent ![](https://img.shields.io/badge/A%20FRAD%20PRODUCT-green)

[![Twitter Follow](https://img.shields.io/twitter/follow/FradSer?style=social)](https://twitter.com/FradSer) [![Claude Code](https://img.shields.io/badge/Claude%20Code-Plugin%20Marketplace-blue.svg)](https://docs.anthropic.com/en/docs/claude-code/plugins) [![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**English | [中文](README.zh-CN.md)**

`FradSer/dotagent` is a cross-assistant workflow marketplace that bundles five opinionated packs covering code review, Git automation, GitHub operations, SwiftUI architecture reviews, and developer utilities. All commands/agents originate from the canonical YAML under `prompts/` and are transformed into Claude/Cursor/Codex/Gemini deliverables via `pnpm build:prompts`, which also regenerates `.claude-plugin/marketplace.json`.

## Plugin Installation

<details>
<summary>Claude Code installation instructions</summary>

How to install and use plugins from this marketplace in Claude Code.

#### 1. Add the marketplace

```bash
/plugin marketplace add FradSer/dotagent
```

When the marketplace manifest name is `fradser-dotagent`, Claude generates install slugs in the form `<plugin>@fradser-dotagent`.

#### 2. Install the plugins you need

```bash
# Browse marketplace and install from the UI picker
/plugin

# Or install plugins directly when you know the slug
/plugin install review@fradser-dotagent
/plugin install git@fradser-dotagent
/plugin install github@fradser-dotagent
/plugin install swift@fradser-dotagent
/plugin install utils@fradser-dotagent
```

> Tip: Install `review@fradser-dotagent` + `git@fradser-dotagent` for the core workflow, then add the others as needed.

</details>

<details>
<summary>Cursor installation instructions</summary>

```bash
cd path/to/this/repo

cp -r dist/cursor/* $HOME/.cursor/
```

This will copy all Cursor command files from `dist/cursor/` to your Cursor configuration directory, making them available in the Cursor command palette.

</details>

<details>
<summary>Codex installation instructions</summary>

```bash
cd path/to/this/repo

cp -r dist/codex/* $HOME/.codex/
```

This will copy all Codex prompt files from `dist/codex/` to your Codex configuration directory, making them available as reference prompts.

</details>

<details>
<summary>Gemini installation instructions</summary>

```bash
cd path/to/this/repo

cp -r dist/gemini/* $HOME/.gemini/
```

This will copy all Gemini command TOML files from `dist/gemini/` to your Gemini configuration directory, making them available in the Gemini command palette.

</details>

## Plugin Catalog

### review (`plugins/code-review-toolkit`) · productivity
Multi-agent review system for enforcing high quality.
- **Agents:** `@code-reviewer`, `@security-reviewer`, `@tech-lead-reviewer`, `@ux-reviewer`, `@code-simplifier`
- **Slash commands:** `/hierarchical`, `/quick`, `/refactor`
- **Use it for:** full-stack audits, security reviews, architectural guidance, guided refactors

### git (`plugins/git`) · development
Conventional Git and GitFlow automation.
- **Slash commands:** `/commit`, `/push`, `/commit-and-push`, `/gitignore`
- **GitFlow helpers:** `/start-feature`, `/finish-feature`, `/start-release`, `/finish-release`, `/start-hotfix`, `/finish-hotfix`
- **Use it for:** atomic commits, branch discipline, automated .gitignore generation

### github (`plugins/github`) · productivity
GitHub project operations with quality gates.
- **Slash commands:** `/create-issues`, `/create-pr`, `/resolve-issues`
- **Highlights:** worktree-based issue resolution, automated label management, security and quality validation before PRs ship

### swift (`plugins/swiftui`) · development
Dedicated SwiftUI Clean Architecture reviewer.
- **Agent:** `@swiftui-clean-architecture-reviewer`
- **Use it for:** enforcing MVVM + Clean Architecture layering, SwiftData integration reviews, platform compliance checks

### utils (`plugins/utils`) · productivity
Utility commands for day-to-day automation.
- **Slash commands:** `/continue`, `/create-command`
- **Use it for:** resuming stalled sessions, scaffolding new custom slash commands

---

## CLAUDE.md Sync Tool

**Separate utility for syncing your global CLAUDE.md configuration file.**

The `sync-to-github.sh` script synchronizes your `CLAUDE.md` file between `$HOME/.claude` and this GitHub repository. This is independent of the plugin installation above.

### Usage

**Run locally (if you've cloned this repo):**
```bash
bash sync-to-github.sh
```

**Run remotely (one-liner):**
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/FradSer/dotagent/main/sync-to-github.sh)
```

### Options

```bash
sync-to-github.sh [options]

Options:
  -y, --yes, --non-interactive   Run without prompts; requires --prefer
      --prefer <local|repo>      Choose source of truth when differences are found (default: repo)
      --branch <name>            Override target branch (default: main)
      --exclude <pattern>        Add extra exclude pattern (can be repeated)
      --https                    Clone via HTTPS instead of SSH
  -h, --help                     Show this help
```

### Examples

**Non-interactive mode (prefer local changes):**
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/FradSer/dotagent/main/sync-to-github.sh) --yes --prefer local
```

**Non-interactive mode (prefer repository version):**
```bash
bash sync-to-github.sh --yes --prefer repo
```

**Interactive mode (prompts for choices):**
```bash
bash sync-to-github.sh
```

## Repository Layout

```text
dotagent/
├── .claude-plugin/              # Claude marketplace manifest (auto-generated)
├── dist/                        # Generated outputs for each assistant
│   ├── claude/plugins/...       # Claude marketplace bundles
│   ├── cursor/commands/...      # Cursor command palette entries
│   ├── codex/prompts/...        # Copilot reference prompts (<plugin>-<slug>.md)
│   └── gemini/commands/...      # Gemini command TOML files
├── prompts/                     # Canonical cross-assistant definitions
│   ├── <plugin>/plugin.yaml
│   ├── <plugin>/commands/*.yaml
│   └── <plugin>/agents/*.yaml
├── config/platforms/*.yaml      # Platform output requirements
├── docs/                        # Integration guides (Claude, Cursor, Codex, Gemini)
├── scripts/build/index.mjs      # Multi-platform generator (pnpm build:prompts)
└── archive/                     # Archived legacy Claude plugin sources
```

See [`CLAUDE.md`](CLAUDE.md) for the full development playbook that inspired these workflows, including mandatory TDD, Clean Architecture guardrails, and tooling conventions. Check `docs/` for platform-specific usage guides.

## FAQ

- **How do I update plugins?** Use `/plugin update review@fradser-dotagent` (replace name as needed) or reinstall.
- **Can I fork and customize?** Yes. Fork the repo, adjust plugin content, update `.claude-plugin/marketplace.json`, and point your team to your fork.
- **Can I install a subset?** Absolutely. Each plugin is independent—install only what fits your workflow.
- **Do I need all agents for reviews?** The `review` plugin bundles agents so you can selectively call the specialist you need.

## License

MIT License – see [LICENSE](LICENSE) for details.
