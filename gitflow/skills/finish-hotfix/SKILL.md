---
name: finish-hotfix
allowed-tools: ["Bash(git-agent:*)", "Bash(git:*)", "Read", "Write"]
description: Finalizes a hotfix and merges it into main and develop using git-flow. This skill should be used when the user asks to "finish a hotfix", "merge hotfix branch", "complete hotfix", "git flow hotfix finish", or wants to finalize a hotfix.
model: haiku
argument-hint: [version]
user-invocable: true
disable-model-invocation: true
---

## Workflow Execution

**Launch a general-purpose agent** that executes all 4 phases in a single task.

**Prompt template**:
```
Execute the finish-hotfix workflow (4 phases).

## Pre-operation Checks
Verify working tree is clean and current branch matches `hotfix/*` per `${CLAUDE_PLUGIN_ROOT}/references/invariants.md`.

## Phase 1: Identify Version
**Goal**: Determine hotfix version from current branch or argument.
1. If `$ARGUMENTS` provided, use it as version (strip 'v' prefix if present)
2. Otherwise, extract from current branch: `git branch --show-current` (strip `hotfix/` prefix)
3. Store clean version without 'v' prefix (e.g., "1.0.1")

## Phase 2: Pre-finish Checks
**Goal**: Run tests before finishing.
1. Identify test commands (check package.json, Makefile, etc.)
2. Run tests if available; exit if tests fail

## Phase 3: Update Changelog
**Goal**: Generate changelog from commits.
1. Get previous tag: `git tag --sort=-v:refname | head -1`
2. Collect commits per `${CLAUDE_PLUGIN_ROOT}/references/changelog-generation.md`
3. Update CHANGELOG.md per `${CLAUDE_PLUGIN_ROOT}/examples/changelog.md`
4. Stage CHANGELOG.md: `git add CHANGELOG.md`
5. Determine the correct Claude model name for co-author attribution
   - Valid models: Claude Sonnet 4.6, Claude Opus 4.6, Claude Haiku 4.5
6. Commit with git-agent: `git-agent commit --no-stage --intent "update changelog for v$VERSION" --co-author "Claude <Model> <Version> <noreply@anthropic.com>"`
7. On auth error (401), retry with `--free`
8. **Fallback** (git-agent unavailable): `git commit -m "chore: update changelog for v$VERSION"` with conventional format and `Co-Authored-By` footer

## Phase 4: Finish Hotfix
**Goal**: Complete hotfix using git-flow-next CLI.
1. Run `git flow hotfix finish $VERSION --tagname "v$VERSION" -m "Release v$VERSION"`
2. Verify current branch: `git branch --show-current` (should be on develop)
3. Push all: `git push origin main develop --tags`
```

**Execute**: Launch a general-purpose agent using the prompt template above
