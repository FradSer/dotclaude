# FradSer's Claude Code Plugin Marketplace ![](https://img.shields.io/badge/A%20FRAD%20PRODUCT-green)

[![Twitter Follow](https://img.shields.io/twitter/follow/FradSer?style=social)](https://twitter.com/FradSer) [![Claude Code](https://img.shields.io/badge/Claude%20Code-Plugin%20Marketplace-blue.svg)](https://docs.anthropic.com/en/docs/claude-code/plugins) [![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**English | [中文](README.zh-CN.md)**

`FradSer/dotclaude` is a Claude Code plugin marketplace that bundles five opinionated workflow packs covering code review, Git automation, GitHub operations, SwiftUI architecture reviews, and developer utilities.

## Plugin Installation

How to install and use plugins from this marketplace in Claude Code.

### 1. Add the marketplace

```bash
/plugin marketplace add FradSer/dotclaude
```

When the marketplace manifest name is `fradser-dotclaude`, Claude generates install slugs in the form `<plugin>@fradser-dotclaude`.

### 2. Install the plugins you need

```bash
# Browse marketplace and install from the UI picker
/plugin

# Or install plugins directly when you know the slug
/plugin install review@fradser-dotclaude
/plugin install git@fradser-dotclaude
/plugin install github@fradser-dotclaude
/plugin install swift@fradser-dotclaude
/plugin install ults@fradser-dotclaude
```

> Tip: Install `review@fradser-dotclaude` + `git@fradser-dotclaude` for the core workflow, then add the others as needed.

## Plugin Catalog

### 🔍 review (`plugins/code-review-toolkit`) · productivity
Multi-agent review system for enforcing high quality.
- **Agents:** `@code-reviewer`, `@security-reviewer`, `@tech-lead-reviewer`, `@ux-reviewer`, `@code-simplifier`
- **Slash commands:** `/hierarchical`, `/quick`, `/refactor`
- **Use it for:** full-stack audits, security reviews, architectural guidance, guided refactors
- **Install:** `/plugin install review@fradser-dotclaude`

### 🌿 git (`plugins/git-workflow`) · development
Conventional Git and GitFlow automation.
- **Slash commands:** `/commit`, `/push`, `/commit-and-push`, `/gitignore`
- **GitFlow helpers:** `/start-feature`, `/finish-feature`, `/start-release`, `/finish-release`, `/start-hotfix`, `/finish-hotfix`
- **Use it for:** atomic commits, branch discipline, automated .gitignore generation
- **Install:** `/plugin install git@fradser-dotclaude`

### 🐙 github (`plugins/github-integration`) · productivity
GitHub project operations with quality gates.
- **Slash commands:** `/create-issues`, `/create-pr`, `/resolve-issues`
- **Highlights:** worktree-based issue resolution, automated label management, security and quality validation before PRs ship
- **Install:** `/plugin install github@fradser-dotclaude`

### 📱 swift (`plugins/swiftui-architecture`) · development
Dedicated SwiftUI Clean Architecture reviewer.
- **Agent:** `@swiftui-clean-architecture-reviewer`
- **Use it for:** enforcing MVVM + Clean Architecture layering, SwiftData integration reviews, platform compliance checks
- **Install:** `/plugin install swift@fradser-dotclaude`

### 🛠️ ults (`plugins/dev-utilities`) · productivity
Utility commands for day-to-day automation.
- **Slash commands:** `/continue`, `/create-command`
- **Use it for:** resuming stalled sessions, scaffolding new custom slash commands
- **Install:** `/plugin install ults@fradser-dotclaude`

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
bash <(curl -fsSL https://raw.githubusercontent.com/FradSer/dotclaude/main/sync-to-github.sh)
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
bash <(curl -fsSL https://raw.githubusercontent.com/FradSer/dotclaude/main/sync-to-github.sh) --yes --prefer local
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
dotclaude/
├── .claude-plugin/
│   └── marketplace.json          # Manifest with plugin registrations
├── plugins/
│   ├── code-review-toolkit/      # review plugin content
│   │   ├── agents/
│   │   └── commands/
│   ├── git-workflow/             # git plugin content
│   │   └── commands/
│   ├── github-integration/       # github plugin content
│   │   └── commands/
│   ├── swiftui-architecture/     # swift plugin content
│   │   └── agents/
│   └── dev-utilities/            # ults plugin content
│       └── commands/
└── README.md
```

See [`CLAUDE.md`](CLAUDE.md) for the full development playbook that inspired these workflows, including mandatory TDD, Clean Architecture guardrails, and tooling conventions.

## FAQ

- **How do I update plugins?** Use `/plugin update review@fradser-dotclaude` (replace name as needed) or reinstall.
- **Can I fork and customize?** Yes. Fork the repo, adjust plugin content, update `.claude-plugin/marketplace.json`, and point your team to your fork.
- **Can I install a subset?** Absolutely. Each plugin is independent—install only what fits your workflow.
- **Do I need all agents for reviews?** The `review` plugin bundles agents so you can selectively call the specialist you need.

## License

MIT License – see [LICENSE](LICENSE) for details.
