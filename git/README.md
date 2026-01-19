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
claude config --add-plugin "/Users/FradSer/Developer/FradSer/dotclaude/git"
```

## Commands

### `/commit`
Creates atomic conventional commits by analyzing pending changes.

**Features:**
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

## Skills

### `conventional-commits`
Expert in creating conventional commits following the Commitizen (cz) style.

**Capabilities:**
- **Conventional Format**: Follows conventional commits specification
- **Atomic Commits**: Identifies logical units of work
- **Message Structure**: Proper title, body, and footer formatting
- **Configuration**: Applies project-specific scopes and types

### `git-config`
Expert in analyzing project structure and generating git configuration.

**Capabilities:**
- **Project Analysis**: Analyzes all directories and git history
- **Scope Generation**: Generates appropriate scopes based on project size
- **Interactive Configuration**: Creates `.claude/git.local.md` with user confirmation

## Configuration

### Auto-Configuration

The plugin automatically generates configuration on first use:
- When you run `/commit` or `/commit-and-push` for the first time
- If `.claude/git.local.md` doesn't exist
- Analyzes project structure and git history
- Generates appropriate scopes based on project size
- Interactive confirmation via AskUserQuestion

**Auto-configuration process:**
1. Analyzes all project directories
2. Examines git history for existing scopes
3. Determines project size (small vs large)
4. Generates scopes using appropriate strategy
5. Presents scopes for interactive confirmation
6. Creates `.claude/git.local.md` with selected scopes

### Manual Configuration

You can also manually create or edit `.claude/git.local.md` in your project root.

See [skills/git-config/examples/git.local.md](skills/git-config/examples/git.local.md) for configuration template.

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
