# Git Plugin

Conventional Git automation and advanced repository management.

**Version**: 0.5.1

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

This plugin provides 3 user-invocable skills:

### `/commit`
Creates atomic conventional commits using git-agent.
- AI-powered commit message generation via git-agent
- Automatic staging and atomic splitting
- Falls back to manual git commit if git-agent is unavailable

### `/commit-and-push`
Creates atomic commits using git-agent and pushes to remote repository.
- All `/commit` features
- Automatic upstream branch configuration

### `/setup`
Initializes git-agent for the repository — generates commit scopes from git history and `.gitignore` via AI.
- Verifies git user identity (name/email)
- Preserves custom `.gitignore` rules when regenerating
- Supports selective mode: `/setup scope` or `/setup gitignore`

## Configuration

### Auto-Configuration

Run `/setup` to auto-generate scopes and `.gitignore` via git-agent. Configuration is stored in `.git-agent/config.yml` and read directly by `git-agent commit`.

### Manual Configuration

Edit `.git-agent/config.yml` directly to customize scopes, hooks, or other settings. Use `git-agent config set <key> <value>` for individual fields.

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
