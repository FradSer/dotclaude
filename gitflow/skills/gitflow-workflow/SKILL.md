---
name: gitflow-workflow
description: This skill should be used when executing GitFlow commands (start-feature, finish-feature, start-hotfix, finish-hotfix, start-release, finish-release), managing GitFlow branches, calculating semantic versions, or applying GitFlow workflow patterns. Based on git-flow-next implementation.
version: 0.1.0
---

## Overview

This skill provides expertise in GitFlow workflow automation based on [git-flow-next](https://git-flow.sh/docs/commands/). It handles branch management, semantic versioning, merge strategies, and follows GitFlow branching model conventions.

## Capabilities

- GitFlow branch model (main, develop, feature, hotfix, release, support)
- Workflow presets (Classic GitFlow, GitHub Flow, GitLab Flow)
- Semantic version calculation from conventional commits
- Branch naming validation and conventions
- Merge strategies (merge, rebase, squash, --no-ff)
- Version file updates and changelog generation
- git-flow-next command compatibility

## Branch Model

### Base Branches

- **main/master**: Production-ready code
- **develop**: Integration branch for ongoing development
- **production** (GitLab Flow): Production deployment branch
- **staging** (GitLab Flow): Pre-production testing branch

### Topic Branches

- **feature/**: New functionality (branches from develop)
- **bugfix/**: Bug fixes (branches from develop)
- **release/**: Preparing production releases (branches from develop)
- **hotfix/**: Urgent production fixes (branches from main)
- **support/**: Maintaining older versions (optional)

## Workflow Presets

Three preset workflows are supported. See `references/branch-strategy.md` for details:

1. **Classic GitFlow**: Traditional workflow with main, develop, feature/, release/, hotfix/
2. **GitHub Flow**: Simplified workflow with main and feature/ only
3. **GitLab Flow**: Multi-environment workflow with production, staging, main, feature/, hotfix/

## Semantic Versioning

Calculate versions from conventional commits:
- **BREAKING CHANGE** → Major version bump (v2.0.0)
- **feat:** → Minor version bump (v1.2.0)
- **fix:** → Patch version bump (v1.1.1)

See `references/version-calculation.md` for detailed logic.

## Merge Strategies

When finishing branches, use appropriate merge strategy:

- **merge** (default): Create merge commit
- **rebase**: Rebase before merging (linear history)
- **squash**: Squash all commits into one
- **--no-ff**: Force merge commit even for fast-forward

## Branch Operations

### Pre-operation Checks

Before executing any GitFlow operation:

1. **Verify git-flow-next installation**: Run `git flow version` to ensure tool is available
   - If command fails, direct user to [installation guide](https://git-flow.sh/docs/installation/)
   - Do not proceed until git-flow-next is installed

2. **Validate branch naming convention**
3. **Check working tree is clean**
4. **Gather required context** (see Context Gathering section)

### Starting Branches

1. Validate branch naming convention
2. Check working tree is clean
3. Create branch from appropriate parent (develop for features, main for hotfixes)
4. Push to origin for collaboration

### Finishing Branches

1. Validate branch name follows convention
2. Ensure working tree is clean
3. Run tests and verify all checks pass
4. Merge to parent branch using configured strategy
5. Delete branch locally and remotely
6. Push updated parent branch

### Handling Conflicts

1. Detect merge conflicts during finish operation
2. Pause and report conflicts
3. Wait for manual resolution
4. Continue with `--continue` flag after resolution
5. Abort with `--abort` if needed

## Version Management

### Version Calculation

Analyze commit history since last tag:
- Scan for `BREAKING CHANGE` or `!` in commit messages
- Count `feat:` commits for minor bumps
- Count `fix:` commits for patch bumps
- Apply highest priority (breaking > feature > fix)

### Version File Updates

Update version in:
- `package.json` (Node.js)
- `version.txt` or `VERSION` file
- `__version__.py` (Python)
- `Cargo.toml` (Rust)
- Other project-specific version files

### Changelog Generation

Generate changelog from commits:
- Group by type (feat, fix, breaking)
- Format with conventional commit messages
- Include issue references
- Add to CHANGELOG.md

## Prerequisites

### git-flow-next Installation

Before executing GitFlow operations, ensure `git-flow-next` is installed:

1. **Check installation**: Run `git flow version` to verify installation
2. **If command fails**: Install git-flow-next following [official installation guide](https://git-flow.sh/docs/installation/)

**Installation Methods:**

- **macOS (Homebrew)**: `brew install gittower/tap/git-flow-next`
- **Manual**: Download from [releases page](https://github.com/gittower/git-flow-next/releases) and add to PATH

If `git flow` command is not found, direct users to install git-flow-next before proceeding with GitFlow operations.

## Best Practices

1. **Keep features focused**: Short-lived branches (2-3 days max)
2. **Atomic commits**: Use `@git/conventional-commits` skill for commit formatting
3. **Test before finish**: Always run tests before merging
4. **Clean merges**: Resolve conflicts before finishing
5. **Version tags**: Create tags on main branch after hotfix/release merges

## Context Gathering

Before executing GitFlow operations, gather necessary context information:
- Current branch and git status
- Existing branches of relevant type
- Latest version tags
- Commit history analysis
- Project configuration (version files, test frameworks)

See `references/context-gathering.md` for detailed context requirements for each operation type.

## Additional Resources

- `references/context-gathering.md` - Context information to gather before operations
- `references/branch-strategy.md` - Detailed branch strategies and naming conventions
- `references/version-calculation.md` - Semantic version calculation logic
- `references/git-flow-next-commands.md` - Complete git-flow-next command reference
- `references/workflow-examples.md` - Complete workflow examples

## External References

- [git-flow-next Documentation](https://git-flow.sh/docs/)
- [git-flow-next Commands](https://git-flow.sh/docs/commands/)
- [git-flow-next Cheat Sheet](https://git-flow.sh/docs/cheat-sheet/)
