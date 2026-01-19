---
name: gitflow-workflow
description: This skill should be used when working with GitFlow workflows including starting features ("create feature branch", "start new feature", "begin feature"), finishing branches ("merge feature", "complete feature", "finish release"), managing hotfixes ("urgent fix", "production hotfix", "critical bug fix", "hotfix from main"), preparing releases ("start release", "create release branch", "prepare version", "new release"), calculating semantic versions ("what version", "next version number", "bump version", "version calculation"), managing GitFlow branches ("gitflow branches", "feature branches", "show releases"), or applying git-flow-next commands. Use when executing GitFlow operations like start, finish, update, or branch management tasks.
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

GitFlow uses base branches for stable code and topic branches for development work. Each workflow preset has different branch configurations - see the platform-specific reference files for details.

## Workflow Presets

Before executing GitFlow operations, identify the workflow in use and reference the corresponding documentation:

| Workflow | When to Use | Reference |
|----------|------------|-----------|
| **Classic GitFlow** | Projects with main + develop branches, release cycles | `references/classic-gitflow.md` |
| **GitHub Flow** | Simple projects with main only, continuous deployment | `references/github-flow.md` |
| **GitLab Flow** | Multi-environment projects with production + staging | `references/gitlab-flow.md` |

> [!IMPORTANT]
> Always check `.git-flow` config or branch structure first to determine which workflow is active, then reference ONLY the corresponding platform file for specific branch rules and merge strategies.

## Branch Operations

All GitFlow operations (start, finish, update) require pre-operation context gathering and validation. See `references/topic-commands.md` for command details.

## Reference Guide

Comprehensive documentation for GitFlow workflows and operations:

- **`references/context-gathering.md`** - Pre-operation context requirements for each GitFlow operation type (features, hotfixes, releases), including git status checks, branch listing, version tags, and project configuration detection
- **`references/classic-gitflow.md`** - Traditional GitFlow workflow with main, develop, feature/, release/, hotfix/ branches
- **`references/github-flow.md`** - Simplified workflow with main and feature/ branches for continuous deployment
- **`references/gitlab-flow.md`** - Multi-environment workflow with production, staging, main branches
- **`references/naming-rules.md`** - Branch naming conventions and examples
- **`references/version-calculation.md`** - Semantic versioning calculation algorithms from conventional commits, including major/minor/patch bump rules, version file update patterns, and changelog generation from commit history
- **`references/core-commands.md`** - Core git-flow-next commands (init, config, overview, version) with all options, workflow presets, and configuration management
- **`references/topic-commands.md`** - Topic branch commands (start, finish, list, update, delete, rename) with complete options, merge strategies, tagging, and conflict handling procedures

## External References

- [git-flow-next Documentation](https://git-flow.sh/docs/)
- [git-flow-next Commands](https://git-flow.sh/docs/commands/)
- [git-flow-next Cheat Sheet](https://git-flow.sh/docs/cheat-sheet/)
