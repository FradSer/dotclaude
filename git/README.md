# Git Plugin

Conventional Git automation and advanced repository management.

**Version**: 0.4.4

## Installation

```bash
claude plugin install git@frad-dotclaude
```

## Overview

This plugin uses **git-agent** as the primary commit tool, with automatic fallback to manual git commit when git-agent is unavailable.

- **Atomic Commits**: git-agent splits changes into up to 5 atomic commit groups automatically.
- **Conventional Format**: AI-generated messages follow conventional commits specification.
- **Auto-Scope**: Scopes are inferred from git history when not configured.
- **Safety**: Quality gates and protections against committing secrets.
- **Project Awareness**: Adapts to project-specific configurations.

## Skills

This plugin provides 4 user-invocable skills:

### `/commit`
Creates atomic conventional commits using git-agent.
- AI-powered commit message generation via git-agent
- Automatic staging and atomic splitting
- Falls back to manual git commit if git-agent is unavailable

### `/commit-and-push`
Creates atomic commits using git-agent and pushes to remote repository.
- All `/commit` features
- Automatic upstream branch configuration

### `/config-git`
Interactive configuration setup for project-specific Git conventions.
- Analyzes project structure to suggest scopes
- Generates `.claude/git.local.md` configuration
- Validates user identity (name/email)

### `/update-gitignore`
Creates or updates `.gitignore` using git-agent AI generation.
- AI-powered .gitignore generation via `git-agent init --gitignore`
- Preserves custom rules when updating

## Configuration

### Auto-Configuration

Configuration is auto-generated on first use or manually via the `/config-git` command.

### Manual Configuration

You can also manually create or edit `.claude/git.local.md` in your project root.

See [examples/git.local.md](examples/git.local.md) for configuration template.

## Best Practices

### Commit Guidelines
Follows conventional commits specification.

### Safety Protocol
This plugin adheres to strict safety protocols:
- NEVER runs destructive commands (`force push`, `hard reset`).
- NEVER commits detected secrets (`.env`, credentials).
- ALWAYS creates new commits rather than amending pushed ones.

## Troubleshooting

- **git-agent auth error**: Retry with `--free` flag, or configure `~/.config/git-agent/config.yml`.
- **git-agent not installed**: The plugin falls back to manual `git commit` with conventional format.
- **Nothing to commit**: Verify changes are not ignored.
- **Push failed**: Check remote permissions and branch protection rules.

## Author

Frad LEE (fradser@gmail.com)

## License

MIT
