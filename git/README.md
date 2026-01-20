# Git Plugin

Conventional Git automation for commits and repository management.

## Overview

This plugin provides automated Git commands that ensure:
- **Atomic Commits**: Logical units of work are committed separately.
- **Conventional Format**: Messages follow the conventional commits specification.
- **Safety**: Quality gates and protections against committing secrets.
- **Project Awareness**: Adapts to project-specific configurations.

## Installation

To install this plugin locally:

```bash
claude config --add-plugin "/path/to/git"
```

## Commands

### `/commit`
Creates atomic conventional commits by analyzing pending changes.

**Features:**
- **Safety Checks**: Detects sensitive files (.env, credentials, secrets), warns about large files (>1MB), and suggests breaking up commits >500 lines
- Analyzes staged and unstaged changes
- Identifies logical units of work
- Generates concise, "why"-focused commit messages
- Skips secrets and build artifacts automatically

### `/commit-and-push`
Creates atomic commits and pushes to the remote repository.

**Features:**
- All `/commit` features
- Automatically sets upstream for new branches
- Verifies push success

### `/gitignore` [technologies...]
Creates or updates `.gitignore` files.

**Usage:**
- `/gitignore` - Auto-detect project technologies
- `/gitignore node react` - Add specific technologies

**Features:**
- Uses Toptal's API for comprehensive rules
- Preserves existing custom rules
- Auto-detects OS and project structure

### `/config`
Interactive git configuration setup.

**Features:**
- Verifies and sets user.name and user.email
- Analyzes project structure and commit history
- Generates project-specific scopes and conventions
- Creates `.claude/git.local.md` configuration file

## Skills

### `conventional-commits`
Expert in creating conventional commits following the Commitizen (cz) style.

**Capabilities:**
- **Conventional Format**: Follows conventional commits specification
- **Atomic Commits**: Identifies logical units of work
- **Message Structure**: Proper title, body, and footer formatting
- **Configuration**: Applies project-specific scopes and types

## Configuration

### Auto-Configuration

The plugin automatically generates configuration on first use when you run `/commit` or `/commit-and-push`. If `.claude/git.local.md` doesn't exist, the plugin will analyze your project structure and git history to generate appropriate scopes with interactive confirmation.

You can also run `/git:config` manually at any time to regenerate the configuration.

### Manual Configuration

You can also manually create or edit `.claude/git.local.md` in your project root.

See [examples/git.local.md](examples/git.local.md) for configuration template.

## Best Practices

### Commit Guidelines
- **Atomic**: One logical change per commit.
- **Conventional**: `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`.
- **Descriptive**: 50-char lowercase titles; explain the "why" in the body.

### Safety Protocol
This plugin adheres to strict safety protocols:
- NEVER runs destructive commands (`force push`, `hard reset`).
- NEVER commits detected secrets (`.env`, credentials).
- ALWAYS creates new commits rather than amending pushed ones.

## Troubleshooting

- **Pre-commit hooks failed**: Fix the issues and run `/commit` again.
- **Nothing to commit**: Verify changes are not ignored.
- **Push failed**: Check remote permissions and branch protection rules.

## License
MIT
