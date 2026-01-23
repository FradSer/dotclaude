# Git Plugin

Conventional Git automation and advanced repository management.

## Installation

```bash
claude plugin install git@frad-dotclaude
```

## Overview

This plugin provides automated Git commands that ensure:
- **Atomic Commits**: Logical units of work are committed separately.
- **Conventional Format**: Messages follow the conventional commits specification.
- **Safety**: Quality gates and protections against committing secrets.
- **Project Awareness**: Adapts to project-specific configurations.

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

### `/config-git`
Interactive git configuration setup.

**Features:**
- Verifies and sets user.name and user.email
- Analyzes project structure and commit history
- Generates project-specific scopes and conventions
- Creates `.claude/git.local.md` configuration file

## Skills

This plugin provides 4 user-invocable skills:

### `/commit`
Creates atomic conventional commits following Commitizen style.
- Validates against conventional commits specification v1.0.0
- Enforces lowercase descriptions and imperative mood
- Requires bullet-point body format

### `/commit-and-push`
Creates atomic commits and pushes to remote repository.
- All `/commit` features
- Automatic upstream branch configuration

### `/config-git`
Interactive configuration setup for project-specific Git conventions.
- Analyzes project structure to suggest scopes
- Generates `.claude/git.local.md` configuration
- Validates user identity (name/email)

### `/update-gitignore`
Creates or updates `.gitignore` using Toptal's API.
- Auto-detects technologies from project structure
- Preserves custom rules when updating
- Supports manual technology specification

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

## Hooks

This plugin uses **PreToolUse hooks** to validate commit messages BEFORE execution:

- **Automatic Validation**: Every `git commit` command is validated before execution
- **Format Checking**: Ensures conventional commit format compliance
- **Early Prevention**: Blocks invalid commits before they are created
- **No PostToolUse**: Validation happens pre-execution only (not after commit is created)

The PreToolUse hook validates:
- Commit message format: `<type>[scope]: <description>`
- Required bullet points in commit body
- Lowercase descriptions
- Title length (<50 characters)
- Imperative mood usage

## Troubleshooting

- **Pre-commit hooks failed**: Fix the issues and run `/commit` again.
- **Nothing to commit**: Verify changes are not ignored.
- **Push failed**: Check remote permissions and branch protection rules.

## Author

Frad LEE (fradser@gmail.com)

## License

MIT
