---
name: create-pr
allowed-tools: Task, Bash(gh:*), Bash(git:*), Monitor, PushNotification, TaskStop
description: Creates comprehensive GitHub pull requests with automated quality validation and security scanning. This skill should be used when the user asks to "create a PR", "submit a pull request", or needs to merge completed work with full compliance checks.
argument-hint: [optional description or issue reference] [--monitor]
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
7. Check remote CI status with `gh pr checks <pr-number> --watch` to ensure all checks pass remotely
8. Report final PR URL and status to user
9. If `$ARGUMENTS` contains `--monitor`, proceed to Phase 4

## Phase 4: Post-PR Monitoring and Auto-Fix (Optional)

**Trigger**: `$ARGUMENTS` contains `--monitor`

**Goal**: Use the Monitor tool to watch BOTH CI checks and new PR comments in one persistent background watch, auto-fix what is actionable, and surface ambiguous items to the user — without busy-polling in the foreground.

**Actions**:
1. Launch a single Monitor with `persistent: true` whose command emits one tagged stdout line per new event: `[ci] <name>: <bucket>` for checks reaching a terminal bucket, and `[comment] ...` for new issue comments, inline review comments, and review summaries. Use the consolidated script in `references/post-pr-monitoring.md` — do not run a foreground `while` loop.
2. React as each Monitor event arrives (the watch runs across turns):
   - `[ci]` failure → analyze logs via `gh run view --log-failed`, apply the fix, commit, push. The push triggers a fresh CI run that the same Monitor re-emits — no relaunch needed.
   - `[comment]` batch arrives → **CRITICAL: Spawn an independent review-triage agent** to evaluate every comment. The main conversation context is biased by the PR creation flow — it authored the code and tends to either defend or over-correct. The triage agent starts with a **clean context**, reads the diff and each comment independently, and returns a verdict per comment: `fix` / `reject` (with reason) / `escalate`. Apply ONLY the `fix` verdicts. See `references/post-pr-monitoring.md` for the agent prompt template and verdict format.
   - `[comment]` escalated (design disagreement, scope change, unclear intent) → send a PushNotification and report the comment body, author, and file context to the user; do not guess.
3. Stop the Monitor with TaskStop when all `[ci]` checks are terminal AND passing, no actionable comments remain, and the user no longer wants live coverage. If a PR has no CI and no reviewers (terminal immediately), report that and skip launching the watch rather than polling an empty signal.

See `references/post-pr-monitoring.md` for the consolidated Monitor script, comment parsing rules, triage agent prompt, and verdict format.

## References

- **Requirements**: `references/requirements.md` - Pre-creation checklist and commit standards
- **Repository Templates**: `references/repository-templates.md` - Contributing guidelines and PR templates
- **Quality Validation**: `references/quality-validation.md` - Node.js/Python validation commands
- **PR Structure**: `references/pr-structure.md` - Title guidelines, body template, labels
- **Failure Resolution**: `references/failure-resolution.md` - Agent collaboration for fixing failures
- **Post-PR Monitoring**: `references/post-pr-monitoring.md` - Monitor commands, comment parsing, auto-fix rules
- **Examples**: `references/examples.md` - Commit message examples
