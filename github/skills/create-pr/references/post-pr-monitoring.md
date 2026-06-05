# Post-PR Monitoring and Auto-Fix

## Monitor Setup

After PR creation, set up a Monitor to watch CI checks until they reach terminal state:

```bash
# Watch CI checks — emit on each terminal status, exit when all complete
prev=""
while true; do
  s=$(gh pr checks <pr-number> --json name,state,bucket 2>&1)
  cur=$(echo "$s" | jq -r '.[] | select(.bucket != "pending") | "\(.name): \(.bucket)"' | sort)
  comm -13 <(echo "$prev") <(echo "$cur")
  prev=$cur
  echo "$s" | jq -e 'all(.bucket != "pending")' >/dev/null && break
  sleep 30
done
```

## CI Failure Analysis

When a check fails:

```bash
# Get failed run details
gh run view <run-id> --log-failed

# List all runs for the PR
gh run list --branch <branch-name> --json status,conclusion,name,databaseId
```

### Auto-Fixable CI Failures

| Failure Type | Signal | Action |
|---|---|---|
| Lint error | `eslint`, `ruff`, `biome` exit non-zero | Run formatter/linter, commit fix, push |
| Type error | `tsc`, `mypy` exit non-zero | Read error, apply type fix, push |
| Test failure | `jest`, `pytest` output `FAIL` | Analyze stack trace, fix code or update test, push |
| Build error | `npm run build`, `cargo build` fails | Read error, fix import/config, push |
| Format drift | `prettier --check`, `black --check` fails | Run formatter, commit, push |

### Non-Auto-Fixable CI Failures (Stop and Report)

| Failure Type | Signal | Action |
|---|---|---|
| Permission/auth | `403`, `401`, `token expired` | Report to user — infrastructure issue |
| Missing secret | `secret not found`, `env var missing` | Report to user — needs manual config |
| Flaky test | Same test passes on retry | Report to user with test name and log link |
| Infrastructure | `timeout`, `OOM`, `runner unavailable` | Report to user — not a code issue |

## Review Comment Monitoring

Poll for new review comments on a 30-second interval:

```bash
# Fetch PR comments (reviews + issue comments)
gh api repos/{owner}/{repo}/issues/<pr-number>/comments \
  --jq '.[] | {id: .id, user: .user.login, body: .body, created_at: .created_at, path: .path}'

# Fetch inline review comments
gh api repos/{owner}/{repo}/pulls/<pr-number>/comments \
  --jq '.[] | {id: .id, user: .user.login, body: .body, path: .path, line: .line, diff_hunk: .diff_hunk}'

# Fetch review summaries (approve/request-changes/comment)
gh api repos/{owner}/{repo}/pulls/<pr-number>/reviews \
  --jq '.[] | {id: .id, user: .user.login, state: .state, body: .body}'
```

Track seen comment IDs to avoid reprocessing. Only act on comments newer than the last check.

## Auto-Fix Decision Matrix

### Actionable (Auto-Fix)

A comment is actionable when ALL of these are true:
1. It points to a specific file and line (inline comment)
2. The request is unambiguous (typo, missing import, style violation, missing test, clear bug)
3. The fix does not change behavior or API surface

Examples of actionable comments:
- "Typo: `recieve` should be `receive`"
- "Missing null check here"
- "This should use `const` not `let`"
- "Add a test for the edge case where input is empty"
- "Unused import"

### Ambiguous (Stop and Report)

A comment is ambiguous when ANY of these are true:
1. It questions a design decision
2. It requests a scope change or new feature
3. It is unclear what the reviewer wants
4. It requires understanding of business context not in the diff
5. Multiple valid interpretations exist

Examples of ambiguous comments:
- "Why not use X instead of Y?" (design preference)
- "This feels over-engineered" (subjective)
- "Can we also handle Z?" (scope change)
- "I'm not sure this is the right approach" (needs discussion)

When ambiguous: stop the monitor, report the comment content with author and file context, and let the user decide.

## Comment Response Protocol

After applying an auto-fix from a review comment:
1. Commit with message: `fix(scope): address review feedback on <file>`
2. Push to the PR branch
3. Reply to the comment via API to acknowledge:

```bash
gh api repos/{owner}/{repo}/issues/comments/<comment-id>/replies \
  -f body="Fixed in <commit-sha>."
```

Do NOT reply to comments that were not auto-fixed — those are reported to the user for manual response.

## Exit Conditions

Monitoring exits when ALL of the following are true:
1. All CI checks have reached terminal state AND all pass
2. No new review comments since last poll
3. No pending auto-fixes to push

If monitoring runs for more than 30 minutes without convergence, stop and report current status to the user.

## Push After Fix

After applying auto-fixes:

```bash
# Stage, commit, push
git add -A
git commit -m "fix(scope): address review feedback"
git push origin <branch>
```

Then re-enter monitoring loop to watch the new CI run.
