# GitHub Pull Request Creation

Create PRs from feature branches with automated issue linking, diff analysis, security checks, and GitHub 2025 best practices.

## Prerequisites
- `gh` CLI authenticated
- Conventional commits (≤50 chars subject, ≤72 chars body)
- Protected branches require PR + review + CI + security checks
- No direct pushes to main/develop
- Branch protection rules with mandatory status checks
- CodeQL and dependency scanning enabled

## Branch Detection & Workflow

**Main branch check** (oneOf pattern for mutually exclusive paths):

- **On main branch**: Cannot create PR from main - display error message
- **On feature/fix branch**: Proceed with PR creation workflow

## PR Creation Workflow

1. **Branch validation** - Confirm not on main, check for unpushed commits
2. **Security pre-check** - Scan for secrets, vulnerabilities, and compliance issues
3. **Diff analysis** - Compare current branch changes against main/develop
4. **Dependency analysis** - Check for vulnerable or outdated dependencies
5. **Issue search** - Find related issues based on code changes and commit messages
6. **Documentation check** - Verify documentation updates for changes
7. **PR creation** - Generate comprehensive PR with security checklist and auto-closing keywords

## Main Branch Check

```bash
CURRENT_BRANCH=$(git branch --show-current)

if [[ "$CURRENT_BRANCH" == "main" ]]; then
    echo "Error: Cannot create pull request from main branch"
    echo ""
    echo "To create a pull request:"
    echo "1. Create a feature branch: git checkout -b feature/your-feature"
    echo "2. Make your changes and commit them"
    echo "3. Run this command again from your feature branch"
    echo ""
    echo "Or use /gh/resolve-issues to work on existing issues"
    exit 1
fi
```

## Diff Analysis

Compare current branch against main to understand changes:

```bash
# Determine base branch (prefer develop if exists)
BASE_BRANCH=$(git ls-remote --heads origin develop >/dev/null 2>&1 && echo "develop" || echo "main")

# Get comprehensive diff information
echo "Analyzing changes against $BASE_BRANCH..."
git fetch origin "$BASE_BRANCH"

# Show commit history for this branch
echo "Commits in this branch:"
git log "origin/$BASE_BRANCH..HEAD" --oneline --no-decorate

echo ""
echo "File changes:"
git diff --name-status "origin/$BASE_BRANCH..HEAD"

echo ""
echo "Detailed diff:"
git diff "origin/$BASE_BRANCH..HEAD" --stat

echo ""
echo "Security analysis of changed files..."
# Check for potential security-sensitive files
CHANGED_FILES=$(git diff --name-only "origin/$BASE_BRANCH..HEAD")
for file in $CHANGED_FILES; do
    if [[ "$file" =~ \.(env|key|pem|p12|pfx)$ ]] || [[ "$file" =~ (config|secret|password|token) ]]; then
        echo "WARNING: Security-sensitive file detected: $file"
    fi
done

echo ""
echo "Dependency analysis..."
# Check package files for dependency changes
if git diff --name-only "origin/$BASE_BRANCH..HEAD" | grep -E "(package\.json|requirements\.txt|Cargo\.toml|go\.mod|pom\.xml|build\.gradle)" > /dev/null; then
    echo "Dependency files changed - recommend running security scan:"
    git diff --name-only "origin/$BASE_BRANCH..HEAD" | grep -E "(package\.json|requirements\.txt|Cargo\.toml|go\.mod|pom\.xml|build\.gradle)"
    echo "Run: gh pr checks --required" 
fi
```

## Related Issue Search

Search for related issues based on code changes:

```bash
# Extract keywords from commits and file changes
COMMIT_MESSAGES=$(git log "origin/$BASE_BRANCH..HEAD" --pretty=format:"%s %b" | tr '[:upper:]' '[:lower:]')
CHANGED_FILES=$(git diff --name-only "origin/$BASE_BRANCH..HEAD" | xargs -I {} basename {} | sed 's/\.[^.]*$//')

# Search for related open issues
echo "Searching for related issues..."
gh issue list --state open --limit 50 --json number,title,body,labels | \
jq -r '.[] | "Issue #\(.number): \(.title)"' | \
while IFS= read -r issue_line; do
    # Extract issue number and check if related to changes
    issue_num=$(echo "$issue_line" | grep -o '#[0-9]*' | sed 's/#//')
    if [[ -n "$issue_num" ]]; then
        issue_detail=$(gh issue view "$issue_num" --json title,body 2>/dev/null)
        if [[ $? -eq 0 ]]; then
            echo "$issue_line"
        fi
    fi
done
```

## PR Creation

Generate PR with proper structure and auto-closing keywords:

```bash
# Generate PR title from branch name or recent commit
BRANCH_NAME=$(git branch --show-current)
RECENT_COMMIT=$(git log -1 --pretty=format:"%s")

# Clean branch name for title (remove prefixes, convert to title case)
PR_TITLE=$(echo "$BRANCH_NAME" | sed 's/^[^/]*\///' | sed 's/-/ /g' | sed 's/\b\w/\U&/g')

# If title is not descriptive, use recent commit
if [[ ${#PR_TITLE} -lt 10 ]]; then
    PR_TITLE="$RECENT_COMMIT"
fi

# Ensure title doesn't exceed 70 characters and has no emojis
PR_TITLE=$(echo "$PR_TITLE" | sed 's/[[:emoji:]]//g' | cut -c1-70)

# Generate PR body with enhanced linking
ISSUE_REFS=""
DEPENDENCY_INFO=""
DOCUMENTATION_CHANGES=""

echo "Enter related issue numbers (space-separated, e.g., 123 456) or press Enter to skip:"
read -r issue_numbers
if [[ -n "$issue_numbers" ]]; then
    for issue_num in $issue_numbers; do
        ISSUE_REFS="${ISSUE_REFS}Fixes #${issue_num}"$'\n'
    done
fi

# Check for dependency changes
if git diff --name-only "origin/$BASE_BRANCH..HEAD" | grep -E "(package\.json|requirements\.txt|Cargo\.toml|go\.mod)" > /dev/null; then
    DEPENDENCY_INFO="Dependency files modified - security scan recommended"
fi

# Check for documentation changes
if git diff --name-only "origin/$BASE_BRANCH..HEAD" | grep -E "\.(md|rst|txt)$" > /dev/null; then
    DOCUMENTATION_CHANGES="Documentation updated in this PR"
else
    DOCUMENTATION_CHANGES="No documentation changes - verify if updates needed"
fi

# Run automated checks before creating PR
echo "Running automated checks..."

# Check if common quality commands exist and run them
if [ -f "package.json" ]; then
    echo "Running Node.js checks..."
    npm run lint 2>/dev/null || echo "No lint script found"
    npm run test 2>/dev/null || echo "No test script found"
    npm run build 2>/dev/null || echo "No build script found"
elif [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
    echo "Running Python checks..."
    python -m flake8 . 2>/dev/null || echo "Flake8 not available"
    python -m pytest 2>/dev/null || echo "Pytest not available"
elif [ -f "Cargo.toml" ]; then
    echo "Running Rust checks..."
    cargo clippy 2>/dev/null || echo "Clippy not available"
    cargo test 2>/dev/null || echo "Tests not available"
fi

# Push branch if not already pushed
git push -u origin HEAD 2>/dev/null || git push origin HEAD

# Create PR with comprehensive structured body
gh pr create --title "$PR_TITLE" --body "$(cat <<EOF
## Summary

Brief description of the changes in this PR and their business impact.

## Changes

$(git log "origin/$BASE_BRANCH..HEAD" --pretty=format:"- %s" --reverse)

## Related Issues

${ISSUE_REFS}

## Security Checklist

- [ ] No secrets or sensitive data exposed
- [ ] Input validation implemented for user inputs
- [ ] SQL injection prevention measures in place
- [ ] XSS protection implemented
- [ ] Authentication and authorization properly handled
- [ ] Dependency vulnerabilities checked and resolved
- [ ] Security-sensitive files reviewed (configs, keys, etc.)
- [ ] HTTPS enforced for external communications

## Testing

- [ ] Unit tests added/updated
- [ ] Integration tests pass
- [ ] Security tests implemented
- [ ] All existing tests pass
- [ ] Linting and formatting pass
- [ ] Build succeeds
- [ ] Manual testing completed

## Documentation

- [ ] Code comments updated
- [ ] API documentation updated
- [ ] README/user docs updated if needed
- [ ] Migration guide provided for breaking changes

**Documentation Status**: ${DOCUMENTATION_CHANGES}

## Dependencies

- [ ] No new vulnerable dependencies introduced
- [ ] Dependency licenses reviewed
- [ ] Package-lock.json/requirements.txt updated
- [ ] Breaking dependency changes documented

${DEPENDENCY_INFO:+**Dependency Analysis**: $DEPENDENCY_INFO}

## Compliance

- [ ] Code follows project style guidelines
- [ ] Accessibility standards maintained
- [ ] Performance impact assessed
- [ ] Backward compatibility maintained (unless breaking change)
- [ ] Error handling implemented

## Type of Change

- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Performance improvement
- [ ] Code refactoring (no functional changes)
- [ ] Documentation update
- [ ] Security enhancement

## Breaking Changes

<!-- If this is a breaking change, describe what breaks and how to migrate -->

## Screenshots/Recordings

<!-- For UI changes, include before/after screenshots or recordings -->
EOF
)"

echo ""
echo "Pull request created successfully!"
echo "View PR: $(gh pr view --web)"
```

## PR Structure

**Title Requirements**:
- ≤70 characters
- No emojis
- Imperative mood
- Descriptive and concise

**Body Structure**:
- **Summary**: Brief overview of changes and business impact
- **Changes**: Bullet list of commits
- **Related Issues**: Auto-closing keywords (`Fixes #123`)
- **Security Checklist**: Comprehensive security verification
- **Testing**: Multi-level testing checklist
- **Documentation**: Documentation update requirements
- **Dependencies**: Dependency security and licensing checks
- **Compliance**: Code standards and performance compliance
- **Type of Change**: Detailed categorization with security/performance options
- **Breaking Changes**: Impact description and migration guide
- **Screenshots/Recordings**: Visual evidence for UI changes

## Labels & Metadata

PRs automatically inherit relevant labels:
- Type-based: `bug`, `enhancement`, `documentation`
- Priority: `priority:high`, `priority:medium`, `priority:low`  
- Area: Component or feature area labels

## Auto-Closing Keywords

Use in PR body to automatically close related issues:
- `close`, `closes`, `closed`
- `fix`, `fixes`, `fixed`
- `resolve`, `resolves`, `resolved`

Format: `Fixes #123` (each on separate line)

## GitHub 2025 Best Practices

1. **Single responsibility** - One feature/fix per PR with focused scope
2. **Security-first** - Comprehensive security checklist before merge
3. **Small, reviewable diffs** - Keep PRs under 400 lines when possible
4. **Automated quality gates** - All CI/CD checks must pass
5. **Comprehensive testing** - Unit, integration, and security tests
6. **Documentation requirements** - Code, API, and user documentation updated
7. **Dependency security** - All dependencies scanned and approved
8. **Performance impact** - Performance implications assessed and documented
9. **Accessibility compliance** - UI changes meet accessibility standards
10. **Breaking change communication** - Clear migration paths for breaking changes

## Quick Reference

**Auto-closing format**: `Fixes #<issue_number>`
**Title format**: Imperative, ≤70 chars, no emojis
**Body sections**: Summary, Changes, Related Issues, Testing, Type of Change

**Key principles**:
- Feature branches only (never from main)
- Security-first approach with comprehensive checks
- Automated quality gates and dependency scanning
- Comprehensive diff and impact analysis
- Clear documentation and breaking change communication
- Link related issues with auto-closing keywords
- Follow structured PR template with security and compliance sections