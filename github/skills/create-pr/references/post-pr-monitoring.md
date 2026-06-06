# Post-PR Monitoring and Auto-Fix

Monitoring uses the **Monitor tool** — a single persistent background watch that emits
one tagged stdout line per new event for BOTH CI checks and PR comments. Each line
arrives as a notification across turns, so react to events instead of blocking on a
manual `while true` loop.

## One Monitor for CI and Comments

Launch one Monitor with `persistent: true` (PR reviews arrive on no fixed schedule).
The command below emits:

- `[ci] <name>: <bucket>` once per check reaching a terminal bucket (pass/fail/cancel/skipping)
- `[comment] issue @<user>: <body>` for new issue-level comments
- `[comment] inline @<user> <path>:<line>: <body>` for new inline review comments
- `[comment] review @<user> [<STATE>]: <body>` for new review summaries (approve / request-changes / comment)

```bash
PR=<pr-number>
REPO=<owner>/<repo>
since=$(date -u +%Y-%m-%dT%H:%M:%SZ)   # server-side dedup for comments
seen_ci=" "                            # space-padded set of emitted "name=bucket" keys

while true; do
  now=$(date -u +%Y-%m-%dT%H:%M:%SZ)

  # --- CI: emit each check that newly reached a terminal bucket (covers failures, not just passes)
  checks=$(gh pr checks "$PR" --repo "$REPO" --json name,bucket 2>/dev/null || true)
  if [ -n "$checks" ]; then
    while IFS=$'\t' read -r name bucket; do
      [ -z "$name" ] && continue
      case "$seen_ci" in
        *" $name=$bucket "*) ;;
        *) echo "[ci] $name: $bucket"; seen_ci="$seen_ci$name=$bucket " ;;
      esac
    done <<< "$(jq -r '.[] | select(.bucket!="pending") | "\(.name)\t\(.bucket)"' <<< "$checks" 2>/dev/null)"
  fi

  # --- Comments: issue-level, inline review, and review summaries (?since handles dedup)
  gh api "repos/$REPO/issues/$PR/comments?since=$since" \
    --jq '.[] | "[comment] issue @\(.user.login): \(.body | gsub("\n";" "))"' 2>/dev/null || true
  gh api "repos/$REPO/pulls/$PR/comments?since=$since" \
    --jq '.[] | "[comment] inline @\(.user.login) \(.path):\(.line // .original_line): \(.body | gsub("\n";" "))"' 2>/dev/null || true
  gh api "repos/$REPO/pulls/$PR/reviews" \
    --jq ".[] | select(.state != \"PENDING\" and .submitted_at > \"$since\") | \"[comment] review @\(.user.login) [\(.state)]: \(.body | gsub(\"\n\";\" \"))\"" 2>/dev/null || true

  since=$now
  sleep 30
done
```

Run via the Monitor tool with `persistent: true` and a specific `description`
(e.g. `"CI + new comments on PR #<n>"`). Stop it with TaskStop when done — never
leave it running once the PR is settled. `|| true` on every poll keeps one transient
API failure from killing the watch.

## Reacting to Events

Each emitted line is a notification. The Monitor keeps running while you act, so apply
fixes, push, and let the same watch re-emit the resulting CI lines.

### `[ci]` failure

```bash
gh run view <run-id> --log-failed          # failed step logs
gh run list --branch <branch> --json status,conclusion,name,databaseId
```

| Failure Type | Signal | Action |
|---|---|---|
| Lint error | `eslint`, `ruff`, `biome` non-zero | Run formatter/linter, commit, push |
| Type error | `tsc`, `mypy` non-zero | Read error, apply type fix, push |
| Test failure | `jest`, `pytest` output `FAIL` | Fix code or update test, push |
| Build error | `npm run build`, `cargo build` fails | Fix import/config, push |
| Format drift | `prettier --check`, `black --check` fails | Run formatter, commit, push |

Stop and report (do NOT auto-fix) for: permission/auth (`403`, `401`, `token expired`),
missing secret (`secret not found`, `env var missing`), flaky test (passes on retry),
infrastructure (`timeout`, `OOM`, `runner unavailable`).

### `[comment]` actionable — fix all needed

Actionable when ALL are true:
1. It points to a specific file/line (inline) or names a concrete change
2. The request is unambiguous (typo, missing import, style violation, missing test, clear bug)
3. The fix does not change behavior or API surface

Examples: "Typo: `recieve` should be `receive`", "Missing null check here",
"Use `const` not `let`", "Add a test for the empty-input case", "Unused import".

**Fix all needed in the batch.** A single poll can surface several new comments at once.
Triage every one, apply a fix for each that is actionable, and only then commit and push —
one round addressing the whole batch, not one comment per push. After pushing, keep polling:
later rounds may surface more comments (or follow-ups on your fix), and each round again
fixes all newly actionable items until none remain unaddressed. Report any ambiguous ones
separately (next section) — never let an ambiguous comment block fixing the actionable ones.

Apply the fixes, then acknowledge each:

```bash
git add -A
git commit -m "fix(scope): address review feedback on <file>"
git push origin <branch>
# Reply to an inline review comment to acknowledge
gh api repos/$REPO/pulls/$PR/comments/<comment-id>/replies -f body="Fixed in <commit-sha>."
```

### `[comment]` ambiguous — PushNotification and report

Ambiguous when ANY are true: questions a design decision; requests a scope change or new
feature; unclear intent; needs business context not in the diff; multiple valid readings.

Examples: "Why not use X instead of Y?", "This feels over-engineered",
"Can we also handle Z?", "I'm not sure this is the right approach".

For these: send a **PushNotification** (the user may have stepped away), report the comment
body + author + file context, and let the user decide. Do NOT reply to or guess at these.

## Lifecycle

- The Monitor runs across turns; you keep working and react as lines arrive.
- A pushed fix triggers a fresh CI run that the same Monitor re-emits — no need to relaunch it.
- Stop with **TaskStop** when: all `[ci]` checks are terminal AND passing, no new actionable
  comments remain, and the user no longer wants live coverage. If the user wants ongoing
  review coverage, leave it persistent and stop on their signal.
