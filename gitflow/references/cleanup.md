# GitFlow Cleanup Procedure

Run after every `finish` operation to reclaim stale branches and worktrees.
git-flow-next `finish` already deletes the just-finished local and remote
branch by default (see `--keep` / `--keepremote` flags); the steps below are
**idempotent** — they confirm that deletion took effect and sweep up
everything else.

## Steps

### 1. Prune stale remote-tracking branches

```bash
git fetch --prune
```

Removes local refs for remote branches that no longer exist on origin.

### 2. Prune stale worktrees

```bash
git worktree prune
git worktree list
```

`prune` clears metadata for worktree directories whose working folder is gone
(e.g. a checked-out feature/hotfix branch that was finished and deleted). `list`
surfaces any remaining worktrees so the user can decide whether to remove them
explicitly with `git worktree remove <path>`.

### 3. Confirm the just-finished branch is gone

```bash
git branch --list "$BRANCH_PREFIX/$NAME"
git branch -r --list "origin/$BRANCH_PREFIX/$NAME"
```

Both should print nothing. If a ref survives (e.g. `--keep` was in effect or a
prior run was interrupted), delete it explicitly:

```bash
git branch -D "$BRANCH_PREFIX/$NAME" 2>/dev/null || true
git push origin --delete "$BRANCH_PREFIX/$NAME" 2>/dev/null || true
```

### 4. Delete other already-merged local working branches

Sweep `feature/*`, `hotfix/*`, `release/*` branches that have merged into
`develop` **or** `main`. Never delete the current branch or the long-lived
branches (`main`, `develop`, `master`, `production`).

```bash
# Branches merged into develop
git branch --merged develop \
  | grep -E '^\s*(feature|hotfix|release)/' \
  | grep -v '\*' \
  | xargs -r git branch -d 2>/dev/null || true

# Branches merged into main (catches hotfix/release not yet in develop)
git branch --merged main \
  | grep -E '^\s*(feature|hotfix|release)/' \
  | grep -v '\*' \
  | xargs -r git branch -d 2>/dev/null || true
```

`git branch -d` only deletes fully-merged branches — it refuses unmerged ones,
so this is safe. Use `2>/dev/null || true` so a single unmerged branch does not
abort the sweep.

## Safety

- Never operate on `main`, `develop`, `master`, or `production`.
- Never delete the branch you are currently on (`grep -v '\*'`).
- Prefer `-d` over `-D`; reserve `-D` for the explicit just-finished branch in
  step 3 only when git-flow-next's own deletion did not run.
