---
name: create-pr
allowed-tools: Task, Bash(gh:*), Bash(git:*), Skill
description: Creates comprehensive GitHub pull requests with automated quality validation and security scanning, then hands off to /github:review-pr for CI monitoring and reviewer-comment triage. This skill should be used when the user asks to "create a PR", "submit a pull request", or needs to merge completed work with full compliance checks.
argument-hint: [optional description or issue reference] [--no-monitor] [--auto-merge]
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
1. **Consume `$ARGUMENTS` before deriving anything.** It may carry, in any combination:
   - An **issue reference** (`Closes #456`, `Fixes #12`, or a bare `#456`) — use it verbatim as the auto-closing keyword in the PR body; do not re-derive or second-guess it. `/github:resolve-issues` delegates here and passes the issue it just resolved this way.
   - A **free-text description** — use it as the basis for the PR title and the What/Why section.
   - `--draft` — pass through to `gh pr create` in step 6.
   - `--no-monitor` — a Phase 4 opt-out only; never treat it as description text.
   - `--auto-merge` — pass through to `/github:review-pr` in Phase 4; turns on auto-merge on green in the review loop. Never treat it as description text.
   Strip the flags before using the remainder as description/issue text.
2. Identify and link any *further* related issues using GitHub CLI (in addition to any reference from `$ARGUMENTS`)
3. Generate PR title (≤70 chars, imperative, no emojis)
4. Assemble PR body following template in `references/pr-structure.md`
5. Apply automated labels based on file changes
6. **CRITICAL: auto-closing keywords only fire when the PR merges into the repository's default branch.** If targeting a non-default branch (e.g. `develop`), explicitly warn the user that linked issues will NOT close automatically on merge and must be closed manually — see `references/auto-closing-keywords.md` for the full rule and keyword table.
7. Create PR using `gh pr create` with all metadata
   - Use `--draft` if `$ARGUMENTS` requested it, or if the PR requires early feedback or is not fully complete
   - Set reviewers with `--reviewer` and assignees with `--assignee` when requested
   - Fill title/body automatically using `--fill` for simple changes
8. Report final PR URL and status to user. Do NOT run a foreground `gh pr checks --watch` here — Phase 4 hands off to `/github:review-pr`, which owns the persistent CI watch; a blocking `--watch` would stall the turn and duplicate that watch.
9. **CRITICAL: Proceed to Phase 4.** Creating the PR is not the end of this skill. Skip Phase 4 only if `$ARGUMENTS` contains `--no-monitor` or the user explicitly opts out — never because CI looks green, no reviewers are assigned, or the change looks trivial.

## Phase 4: Post-PR Handoff (default on)

**Trigger**: Default behavior — hand off unless `$ARGUMENTS` contains `--no-monitor` or the user opts out.

**Goal**: Delegate CI monitoring and reviewer-comment triage to the dedicated skill.

**Action**: After the PR is created, invoke `Skill("github:review-pr", "<PR#>")` to run the baseline review and launch the persistent CI + comment watch. The review-pr skill owns the Monitor script, the skeptical triage agent, the review → fix → commit+push → wait-for-review loop, through to the merge decision and the post-merge branch hygiene (remote + local head cleanup, `fetch --prune`, fast-forward `main`/`develop`). See `references/pr-creation-handoff.md` for the handoff contract including post-merge hygiene. This skill does not duplicate that cleanup; it is the handoff target's responsibility.

**`--auto-merge` passthrough**: If `$ARGUMENTS` carried `--auto-merge`, pass it through to the review-pr invocation as `Skill("github:review-pr", "<PR#> --auto-merge")`. It instructs review-pr to skip the merge `AskUserQuestion` and auto-merge with `gh pr merge --merge` once CI is green and every non-escalate comment is triaged — see `references/pr-creation-handoff.md` for the contract and the escalate fallback. Pass it through **only** when the user explicitly set it; never infer it.

**CRITICAL: this skill is the plugin's only PR-creating path.** Other skills (e.g. `/github:resolve-issues`) delegate here instead of calling `gh pr create` themselves, precisely so no PR escapes the quality gate or this handoff. See `references/pr-creation-handoff.md` for the full contract. Do not add a bypass.

## References

- **Requirements**: `references/requirements.md` - Pre-creation checklist and commit standards
- **Repository Templates**: `references/repository-templates.md` - Contributing guidelines and PR templates
- **Quality Validation**: `references/quality-validation.md` - Node.js/Python validation commands
- **PR Structure**: `references/pr-structure.md` - Title guidelines, body template, labels
- **Auto-Closing Keywords**: `references/auto-closing-keywords.md` - Default-branch limitation and keyword table
- **PR Creation Handoff**: `references/pr-creation-handoff.md` - Only PR-creating path contract
- **Failure Resolution**: `references/failure-resolution.md` - Agent collaboration for fixing failures
- **Examples**: `references/examples.md` - Commit message examples
