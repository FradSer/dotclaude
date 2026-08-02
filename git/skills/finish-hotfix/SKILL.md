---
name: finish-hotfix
allowed-tools: ["Bash(git-agent:*)", "Bash(git:*)", "Read", "Write"]
description: Finalizes a hotfix and merges it into main and develop using git-flow, then prunes stale branches and worktrees. This skill should be used when the user asks to "finish a hotfix", "merge hotfix branch", "complete hotfix", "git flow hotfix finish", or wants to finalize a hotfix.
model: haiku
argument-hint: [version]
user-invocable: true
disable-model-invocation: true
---

## Workflow Execution

**Launch a general-purpose agent** that executes all 6 phases in a single task.

**Prompt template**:
```
Execute the finish-hotfix workflow (6 phases).

CRITICAL:
- Verify working tree is clean (`git status --porcelain` is empty) before finishing.
- Verify current branch matches `hotfix/*` before finishing — wrong branch type merges to the wrong parent.
See `${CLAUDE_PLUGIN_ROOT}/references/invariants.md` for details.

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
4. Determine the Claude model name for co-author attribution
   - Derive it from your own runtime model identity (e.g. Claude Opus 4.8) so it never goes stale; do not hardcode a fixed version
5. Stage and commit in ONE chained command — a standalone `git add` is denied (see invariants.md §Committing): `git add CHANGELOG.md && git-agent commit --no-stage --intent "update changelog for v$VERSION" --co-author "Claude <Model> <Version> <noreply@anthropic.com>"`
6. On auth error (401), retry with `--free`
7. **Fallback** (git-agent unavailable): invoke the `/git:commit` skill via the Skill tool; full ladder in invariants.md §Committing

## Phase 4: Finish Hotfix
**Goal**: Complete hotfix using git-flow-next CLI.
1. Run `git flow hotfix finish $VERSION --tagname "v$VERSION" -m "Release v$VERSION"`
2. Verify current branch: `git branch --show-current` (git-flow-next lands you on `main` after finish; `develop` is updated automatically). git-flow-next does NOT auto-push.
3. Push all: `git push origin main develop --tags`

## Phase 5: Finalize
**Goal**: Return to develop for ongoing work (git-flow-next leaves you on `main` after a hotfix finish).
1. Switch to develop: `git checkout develop`
2. Pull latest: `git pull origin develop`
3. Verify: `git branch --show-current` (should output "develop")

## Phase 6: Cleanup
**Goal**: Reclaim stale branches and worktrees after finish.
Follow `${CLAUDE_PLUGIN_ROOT}/references/cleanup.md` in full. With `$BRANCH_PREFIX=hotfix` and `$NAME=$VERSION`:
1. `git fetch --prune`
2. `git worktree prune` (then `git worktree list` to surface survivors)
3. Confirm `hotfix/$VERSION` is gone locally and on origin; delete explicitly if a ref survived
4. Sweep other already-merged `feature/*`, `hotfix/*`, `release/*` branches (merged into `develop` or `main`)
```

**Execute**: Launch a general-purpose agent using the prompt template above
