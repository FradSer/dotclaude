---
name: finish-release
allowed-tools: ["Bash(git-agent:*)", "Bash(git:*)", "Bash(gh:*)", "Read", "Write"]
description: Finalizes a release and merges it into main and develop with a tag using git-flow. This skill should be used when the user asks to "finish a release", "merge release branch", "complete release", "git flow release finish", or wants to finalize a release.
model: haiku
argument-hint: [version]
user-invocable: true
disable-model-invocation: true
---

## Workflow Execution

**Launch a general-purpose agent** that executes all 6 phases in a single task.

**Prompt template**:
```
Execute the finish-release workflow (6 phases).

## Pre-operation Checks
Verify working tree is clean and current branch matches `release/*` per `${CLAUDE_PLUGIN_ROOT}/references/invariants.md`.

## Phase 1: Identify Version
**Goal**: Determine release version from current branch or argument.
1. If `$ARGUMENTS` provided, use it as version (strip 'v' prefix if present)
2. Otherwise, extract from current branch: `git branch --show-current` (strip `release/` prefix)
3. Store clean version without 'v' prefix (e.g., "1.0.0")

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

## Phase 4: Finish Release
**Goal**: Complete release using git-flow-next CLI.
1. Run `git flow release finish $VERSION --tagname "v$VERSION" -m "Release v$VERSION"`
2. Verify current branch: `git branch --show-current` (should be on develop)
3. Push all: `git push origin main develop --tags`

## Phase 5: GitHub Release
**Goal**: Create GitHub release from existing tag.
1. Extract changelog for this version from CHANGELOG.md
2. Run `gh release create "v$VERSION" --title "v$VERSION" --notes "<changelog>" --verify-tag`

## Phase 6: Finalize
**Goal**: Ensure working branch is develop.
1. Switch to develop: `git checkout develop`
2. Pull latest: `git pull origin develop`
3. Verify: `git branch --show-current` (should output "develop")
```

**Execute**: Launch a general-purpose agent using the prompt template above
