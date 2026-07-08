---
name: create-pr
allowed-tools: Task, Bash(gh:*), Bash(git:*), Skill
description: Creates comprehensive GitHub pull requests with automated quality validation and security scanning, then hands off to /github:review-pr for CI monitoring and reviewer-comment triage. This skill should be used when the user asks to "create a PR", "submit a pull request", or needs to merge completed work with full compliance checks.
argument-hint: [optional description or issue reference] [--no-monitor]
user-invocable: true
---

# Create GitHub Pull Request

Execute automated PR creation workflow with comprehensive quality validation and security scanning.

## Context

- Current git status: !`git status`
- Current branch: !`git branch --show-current`
- Unpushed commits: !`git log --oneline -5`
- GitHub authentication: !`gh auth status`
- Repository changes: !`git diff --stat HEAD~1..HEAD`

## Requirements Summary

Ensure repository readiness with clean state and authentication. Complete all quality checks (lint, test, build, security) before PR creation. Link related issues with auto-closing keywords and apply accurate labels. See `references/requirements.md` for complete checklist.

## Phase 1: Validation and Analysis

**Goal**: Validate repository state, analyze changes, detect templates, and identify blockers.

**Actions**:
1. Verify GitHub authentication from context
2. Check branch status and unpushed commits
3. Analyze commit history for conventional commit compliance
4. Identify changed files and determine PR scope
5. Check for contributing guidelines (`CONTRIBUTING.md`) and follow its requirements
6. Detect PR templates (`.github/PULL_REQUEST_TEMPLATE.md` or root/docs locations)
7. Detect potential blockers (merge conflicts, missing tests, etc.)

See `references/repository-templates.md` for template detection and compliance details.

## Phase 2: Quality and Security Checks

**Goal**: Execute comprehensive quality validation and security scanning.

**Actions**:
1. Run project-specific quality checks (see `references/quality-validation.md` for commands)
2. Execute security scanning for sensitive files and hardcoded secrets
3. Validate commit message format against standards
4. If checks fail: follow failure resolution process in `references/failure-resolution.md`
5. Re-run all checks until passing

## Phase 3: PR Assembly and Creation

**Goal**: Create pull request with proper structure, metadata, and links.

**Actions**:
1. Identify and link related issues using GitHub CLI
2. Generate PR title (≤70 chars, imperative, no emojis)
3. Assemble PR body following template in `references/pr-structure.md`
4. Apply automated labels based on file changes
5. **CRITICAL: Auto-closing keywords (`Closes`/`Fixes`/`Resolves #N`) only trigger when the PR merges into the repository's default branch. If targeting a non-default branch (e.g. `develop`), explicitly warn the user that linked issues will NOT close automatically on merge and must be closed manually.**
6. Create PR using `gh pr create` with all metadata
   - Use `--draft` if the PR requires early feedback or is not fully complete
   - Set reviewers with `--reviewer` and assignees with `--assignee` when requested
   - Fill title/body automatically using `--fill` for simple changes
7. Report final PR URL and status to user. Do NOT run a foreground `gh pr checks --watch` here — Phase 4 hands off to `/github:review-pr`, which owns the persistent CI watch; a blocking `--watch` would stall the turn and duplicate that watch.
8. Proceed to Phase 4 by default. Skip Phase 4 only if `$ARGUMENTS` contains `--no-monitor` or the user explicitly opts out.

## Phase 4: Post-PR Handoff (default on)

**Trigger**: Default behavior — hand off unless `$ARGUMENTS` contains `--no-monitor` or the user opts out.

**Goal**: Delegate CI monitoring and reviewer-comment triage to the dedicated skill.

**Action**: After the PR is created, invoke `Skill("github:review-pr", "<PR#>")` to run the baseline review and launch the persistent CI + comment watch. The review-pr skill owns the Monitor script, the skeptical triage agent, and the fix→commit→push loop.

## References

- **Requirements**: `references/requirements.md` - Pre-creation checklist and commit standards
- **Repository Templates**: `references/repository-templates.md` - Contributing guidelines and PR templates
- **Quality Validation**: `references/quality-validation.md` - Node.js/Python validation commands
- **PR Structure**: `references/pr-structure.md` - Title guidelines, body template, labels
- **Failure Resolution**: `references/failure-resolution.md` - Agent collaboration for fixing failures
- **Examples**: `references/examples.md` - Commit message examples
