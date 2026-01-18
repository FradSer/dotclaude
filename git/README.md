# Git Plugin

Conventional Git automation for commits and repository management.

## Overview

Simple Git automation commands following conventional commits specification.

## Commands

### `/git:commit`

Create atomic conventional commits.

```bash
/git:commit
```

Analyzes changes, creates atomic commits with conventional messages.

### `/git:commit-and-push`

Create commits and push to remote.

```bash
/git:commit-and-push
```

Same as commit, plus pushes to remote with upstream configuration.

### `/git:gitignore`

Create or update `.gitignore` file.

```bash
/git:gitignore                    # Auto-detect technologies
/git:gitignore react typescript   # Add specific technologies
```

Uses Toptal gitignore templates with auto-detection.

## Hooks

### PreToolUse (Commit Validation)

Validates git commit commands follow conventional commits format:
- Lowercase title < 50 chars
- Format: `type: description` or `type(scope): description`
- Valid types: feat, fix, docs, refactor, test, chore, etc.

## Requirements

- Git installed and configured
- Git repository initialized

## Safety Features

- Never force pushes
- Validates files before staging
- Skips common secret files (.env, credentials, etc.)
- Follows Git Safety Protocol

## Author

Frad LEE (fradser@gmail.com)

## Version

1.0.0
