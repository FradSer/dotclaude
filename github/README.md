# GitHub Plugin

GitHub project operations with quality gates, TDD workflows, and comprehensive issue management.

**Version**: 0.4.0

## Installation

```bash
claude plugin install github@frad-dotclaude
```

**Requirements:**
- GitHub CLI (`gh`) must be installed and authenticated
- Repository must have a GitHub remote
- Project must have lint, test, and build commands configured
- Git must support worktrees (Git 2.5+)

## Overview

The GitHub Plugin automates GitHub operations including pull request creation, issue management, and quality validation. It ensures all PRs meet quality standards before submission and follows TDD principles with atomic commits and conventional commit formats.

**Every PR enters the review loop.** `/github:create-pr` is the plugin's single PR-creating path, and it always hands off to `/github:review-pr` once the PR exists. Other skills — `/github:resolve-issues` included — delegate to it rather than calling `gh pr create` themselves, so no PR can skip the quality gate or the loop:

```
create PR → baseline review → triage each comment skeptically
          → apply only verified fixes → commit + push
          → wait for the next review round
          ↺ until CI is green and every comment is triaged
          → summary + body rewrite → ask the user whether to merge
```

The loop is the default; opting out takes a deliberate act — passing `--no-monitor` to `/github:create-pr`, or telling Claude directly that you only want the PR created or only want a baseline review. It is never skipped just because CI looks quiet: auto-review services and human reviewers comment on their own schedule, so a repo with no CI workflows still gets watched.

**Plugin Architecture**: Optimized with progressive disclosure - core workflows (~500 tokens) in SKILL.md files with detailed references in `references/` subdirectories for efficient context loading.

## Plugin Structure

Each skill follows a phase-based workflow structure with detailed reference materials:

```
skills/
├── create-issues/
│   ├── SKILL.md                    # Core workflow (~534 tokens)
│   └── references/
│       ├── requirements.md         # TDD and commit standards
│       ├── decision-logic.md       # Branch decisions and issue types
│       ├── issue-structure.md      # Structure requirements
│       └── examples.md             # Commit message examples
├── create-pr/
│   ├── SKILL.md                    # Core workflow (~634 tokens)
│   └── references/
│       ├── requirements.md         # Pre-creation checklist
│       ├── quality-validation.md   # Node.js/Python checks
│       ├── pr-structure.md         # Title/body templates
│       ├── failure-resolution.md   # Agent collaboration
│       └── examples.md             # Commit message examples
├── resolve-issues/
│   ├── SKILL.md                    # Core workflow (~591 tokens)
│   └── references/
│       ├── requirements.md         # Worktree and TDD workflow
│       ├── workflow-details.md     # Detailed process steps
│       └── examples.md             # Commit message examples
└── review-pr/
    ├── SKILL.md                    # Review + CI/comment watch loop
    ├── scripts/
    │   └── review-loop.sh          # Monitor poll script
    └── references/
        ├── review-loop.md          # Poll interval, triage prompt, verdicts
        └── closeout.md             # Summary, body rewrite, merge decision
```

This architecture enables efficient context loading by keeping core workflows concise while providing comprehensive reference materials on demand.

## Commands

### `/github:create-pr`

Creates comprehensive GitHub pull requests with quality validation and gates, then hands off to `/github:review-pr`. This is the plugin's only PR-creating path.

**Metadata:**

| Field | Value |
|-------|-------|
| Allowed Tools | `Task`, `Bash(gh:*)`, `Bash(git:*)`, `Skill` |
| Argument Hint | `[optional description or issue reference] [--no-monitor]` |

**What it does:**
1. Validates repository status and GitHub authentication
2. Analyzes all commits in the branch (full history analysis)
3. Enforces atomic commits: each commit represents one complete, cohesive change
4. Runs comprehensive quality and security checks:
   - Lint validation
   - Test suite execution
   - Build verification
   - Security scanning for sensitive data
5. Validates commit messages follow conventional format:
   - **Format**: `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`
   - **Title**: lowercase, <50 chars, imperative mood, optional scope
   - **Body**: ≤72 chars per line, describes what and why
   - **Footer**: References issues with auto-closing keywords
6. Ensures all checks pass before PR creation
7. Creates comprehensive PR description with:
   - Summary of changes (1-3 bullet points)
   - Test plan checklist
   - Related issues and PRs
   - Quality validation status
8. Applies automated labels based on changes
9. Creates PR using GitHub CLI with proper metadata
10. Hands off to `/github:review-pr` for the review loop (unless `--no-monitor`)

**Usage:**
```bash
/github:create-pr

# Create the PR but skip the review loop
/github:create-pr --no-monitor
```

**Example workflow:**
```bash
# Make atomic commits following conventional format
/git:commit  # First feature commit
/git:commit  # Second feature commit

# Create PR with quality gates
/github:create-pr

# Claude will:
# - Validate all commits follow conventional format
# - Run lint, test, build, security checks
# - Ensure all quality gates pass
# - Generate comprehensive PR description
# - Apply labels and link issues
# - Create PR and provide URL
# - Hand off to /github:review-pr to watch CI and reviewer comments
```

**Features:**
- **Quality gates**: All checks must pass before PR creation
- **Atomic commits**: Validates each commit is a logical unit
- **Conventional commits**: Enforces commit message standards
- **Comprehensive validation**: Lint, test, build, security
- **Auto-labeling**: Applies labels based on change types
- **Issue linking**: Automatically links related issues
- **Security scanning**: Checks for sensitive data exposure
- **Failure resolution**: Systematic process to fix issues
- **Review loop handoff**: Delegates to `/github:review-pr` after creation

**Failure resolution process:**
When quality checks fail, the command:
1. Creates specific task lists for failures
2. Fixes issues systematically with validation
3. Re-runs checks until all pass

---

### `/github:create-issues`

Creates GitHub issues following TDD principles with proper labels, scope, and auto-closing keywords.

**Metadata:**

| Field | Value |
|-------|-------|
| Allowed Tools | `Task`, `Bash(gh:*)`, `Bash(git:*)` |
| Argument Hint | `[description]` |

**What it does:**
1. Analyzes repository context and existing issues
2. Determines issue type (epic, PR-scoped, or review issue)
3. Creates proper labels if they don't exist:
   - `priority:high` - High priority - this sprint
   - `priority:medium` - Medium priority - next sprint
   - `priority:low` - Low priority - backlog
4. Creates issues with required structure:
   - Title (≤70 chars, imperative, no emojis)
   - Proper labels
   - Detailed body with problem description
   - Acceptance criteria
   - Context and links
5. Applies auto-closing keywords for PR-scoped issues
6. Provides issue URLs and tracking information

**Usage:**
```bash
/github:create-issues [\"Bug description\" \"Feature description\"]
```

**Example workflows:**
```bash
# Create single issue
/github:create-issues \"Fix memory leak in auth service\"

# Create multiple issues
/github:create-issues \"Add rate limiting\" \"Update payment API\" \"Fix mobile layout\"

# With detailed description (interactive)
/github:create-issues
# Claude will ask for details and create properly formatted issue
```

**Features:**
- **TDD-first**: Follows test-driven development workflow
- **Branch-aware**: Decision tree based on current branch
- **Proper labeling**: Automatic label assignment
- **Scope determination**: Epic vs PR-scoped issues
- **Auto-closing**: Uses keywords (Closes, Fixes, Resolves)
- **Structured format**: Consistent issue templates

**Branch-based decision logic:**
- **On main/develop**: Create issue directly
- **On PR branch**: Ask "Must this be fixed before merge?"
  - **Yes**: Comment in PR with detailed context
  - **No**: Create new issue for later with justification

**Issue types:**
1. **Epic issues**: Multi-PR initiatives (no auto-close keywords)
2. **PR-scoped issues**: Single PR resolution (use auto-close keywords)
3. **Review issues**: Non-blocking feedback from PR reviews

---

### `/github:resolve-issues`

Resolves GitHub issues using isolated worktrees and TDD workflow with comprehensive quality validation.

**Metadata:**

| Field | Value |
|-------|-------|
| Allowed Tools | `Bash(gh:*)`, `Bash(git:*)`, `EnterWorktree`, `ExitWorktree`, `Task`, `Skill` |
| Argument Hint | `[issue number or description]` |

**What it does:**
1. **Issue Selection**: Evaluates open issues and prioritizes next actionable item
2. **Worktree Setup**: Creates or reuses isolated worktree with descriptive branch name
3. **TDD Implementation**:
   - Plan implementation and assess architectural impact
   - Write failing tests (red phase)
   - Implement fixes
   - Refactor while keeping tests green
4. **Quality Validation**: Runs project-specific lint, test, and build commands for fast local feedback
5. **PR Creation**: Pushes the branch, then delegates to `/github:create-pr` with the issue reference — which runs the authoritative quality gate and enters the `/github:review-pr` loop. This skill does not resume inline; `/github:review-pr` owns the PR through to the merge decision.
6. **Cleanup** (later turn, after the PR actually merges): verifies the worktree is still on the issue branch, then removes worktree and branch with documentation

**Usage:**
```bash
/github:resolve-issues
```

**Example workflow:**
```bash
# Start issue resolution
/github:resolve-issues

# Claude will:
# - Show open issues and ask which to resolve
# - Create worktree: git worktree add ../fix-123-auth-redirect
# - Plan with tech-lead-reviewer
# - Write failing tests
# - Implement fix
# - Run quality checks
# - Delegate to /github:create-pr with \"Fixes #123\"
#   └─ which hands off to /github:review-pr for the loop
# - Clean up worktree in a later turn, once the PR has merged
```

**Features:**
- **Isolated worktrees**: Clean environment for each issue
- **TDD workflow**: Red → Green → Refactor cycle
- **Quality gates**: All checks must pass
- **Review loop**: Reaches `/github:review-pr` via `/github:create-pr`
- **Auto-cleanup**: Removes worktrees after completion
- **Documentation**: Tracks all decisions and actions

---

### `/github:review-pr`

Reviews a PR, then keeps a persistent watch over CI results and incoming reviewer comments until the PR settles. Reached automatically from `/github:create-pr`; also usable standalone on any existing PR.

**Metadata:**

| Field | Value |
|-------|-------|
| Allowed Tools | `Task`, `Bash(gh:*)`, `Bash(git:*)`, `Monitor`, `PushNotification`, `TaskStop`, `Skill`, `AskUserQuestion`, `Read`, `Edit`, `Write` |
| Argument Hint | `<PR number or URL>` |

**What it does:**
1. Runs a baseline review with the built-in `/review`, treating its findings as the first comment batch
2. Launches one persistent background `Monitor` polling CI and new comments, with the interval sized to the PR
3. On each event:
   - **CI failure** → fetches logs, fixes, commits + pushes (stops and reports for auth, secret, flaky, or infra failures)
   - **New comments** → spawns an independent skeptical triage agent with a clean context, which returns `fix` / `reject <reason>` / `escalate` per comment
4. Applies only the `fix` verdicts, replies to rejections, notifies on escalations
5. Commits + pushes each round, which triggers fresh CI that the same Monitor re-emits — the loop continues
6. Hides resolved comments and resolves their threads
7. Once CI is green and every comment is triaged: posts a summary comment, rewrites the PR body to link it, and asks whether to merge

**Usage:**
```bash
/github:review-pr 123
/github:review-pr https://github.com/owner/repo/pull/123
```

**Features:**
- **Skeptical triage**: Comments are suggestions to consider, not orders — rejecting noise is the expected outcome
- **Independent context**: The triage agent never sees the authoring context, so it can't rationalize the diff
- **Persistent watch**: Survives across turns; a quiet comment queue is not a stop signal
- **Never auto-merges**: Merging always requires an explicit user choice

## Best Practices

### Using `/github:create-pr`
- **Quality-first**: All checks must pass before PR creation
- **Atomic commits**: Each commit should be a logical unit
- **Conventional format**: Follow commit message standards
- **Small PRs**: Easier to review and merge
- **Issue linking**: Reference issues in commits for auto-closing
- **Review the PR**: Verify description accuracy before submission

### Using `/github:create-issues`
- **Clear descriptions**: Provide specific problem statements
- **Acceptance criteria**: Define measurable completion conditions
- **TDD workflow**: Create issues before implementation
- **Proper scoping**: Distinguish between epics and PR-scoped issues
- **Label consistently**: Use priority and type labels
- **Link related items**: Connect issues to related work

### Using `/github:resolve-issues`
- **Select wisely**: Prioritize the next actionable issue
- **Follow TDD**: Write tests before implementation
- **Use worktrees**: Keep environments isolated
- **Collaborate**: Use specialized agents for review
- **Quality gates**: All checks must pass before PR
- **Clean up**: Remove worktrees after merge
- **Document**: Track decisions and lessons learned

## Workflow Integration

### Complete development workflow:
```bash
# 1. Create issue for feature
/github:create-issues \"Add OAuth authentication\"

# 2. Resolve the issue
/github:resolve-issues
# - Select the OAuth issue
# - Work in isolated worktree
# - Follow TDD cycle
# - Delegate to /github:create-pr when complete

# 3. Or manual development
/git:commit  # Follow conventional format
/git:commit

# 4. Create PR with quality gates
/github:create-pr
# - All checks pass
# - PR description generated
# - Issues linked automatically

# 5. The review loop runs automatically from step 2 or 4
# /github:review-pr takes over:
# - Baseline review, then watches CI and reviewer comments
# - Triages each comment, fixes what's verified, pushes
# - Repeats until CI is green and no comments remain
# - Asks whether to merge
```

Steps 2 and 4 both funnel through `/github:create-pr` → `/github:review-pr`, so no PR opens and gets walked away from unless you explicitly opt out.

## Requirements

- GitHub CLI (`gh`) must be installed
- GitHub CLI must be authenticated: `gh auth login`
- Repository must have a GitHub remote named `origin`
- Project must have configured lint, test, and build commands
- Git version 2.5+ for worktree support

## Troubleshooting

### `/github:create-pr` fails quality checks

**Issue**: Lint, test, build, or security checks fail

**Solution**:
- Review failure output carefully
- Fix all issues systematically
- Re-run `/github:create-pr` after all fixes
- Consider splitting large PRs if too many issues

### GitHub CLI not authenticated

**Issue**: `gh` commands fail with authentication error

**Solution**:
- Install GitHub CLI: `brew install gh` (macOS) or see [GitHub CLI installation](https://cli.github.com/)
- Authenticate: `gh auth login`
- Select appropriate authentication method
- Verify with: `gh auth status`
- Ensure repository remote: `git remote -v`

### PR description is incomplete

**Issue**: PR description missing context or details

**Solution**:
- Ensure commits follow conventional format
- Write descriptive commit messages
- Reference issues in commit messages
- Manually edit PR after creation if needed
- Check full commit history for context

### Worktree operations fail

**Issue**: `git worktree` commands fail

**Solution**:
- Update Git to version 2.5+
- Check worktree list: `git worktree list`
- Remove orphaned worktrees: `git worktree remove <path>`
- Clean up with: `git worktree prune`
- Ensure sufficient disk space

### Issue auto-closing doesn't work

**Issue**: Merged PR doesn't close linked issues

**Solution**:
- Use correct keywords: Closes, Fixes, Resolves
- Reference issue in PR or commit message
- Check GitHub repository permissions
- Verify issue exists and is open
- Manually close if needed and update process

## Safety Features

- **Protected branches**: Enforces PR workflow for main/develop
- **Quality gates**: All checks must pass before PR creation
- **Security scanning**: Detects sensitive data before commits
- **Atomic commits**: Validates each commit is a logical unit
- **Worktree isolation**: Prevents repository corruption
- **Atomic PR creation**: Either all succeeds or all fails

## Key Principles

- **TDD-First**: Test → Code → Refactor cycle
- **Quality Gates**: All checks pass before PR
- **Atomic Commits**: One logical change per commit
- **Issue-Driven**: Work from well-defined issues
- **Collaborative**: Multi-agent review and validation
- **Clean Workflow**: Isolated worktrees, automated cleanup

## Author

Frad LEE (fradser@gmail.com)

## License

MIT
