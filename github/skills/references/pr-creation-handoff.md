# PR Creation Handoff Contract

This is the canonical contract for how PRs get created across the `/github:*` plugin. All skills that need a PR created delegate to `/github:create-pr`; none call `gh pr create` themselves.

## CRITICAL: create-pr is the plugin's ONLY PR-creating path

No other skill calls `gh pr create`. Other skills (`/github:resolve-issues`, and any future caller) delegate via `Skill("github:create-pr", "<issue reference>")` so no PR escapes the quality gate or the mandatory `/github:review-pr` handoff. **Do not add a bypass.**

## Duties owned by create-pr (not duplicated by callers)

1. **Pre-creation quality + security gate** — lint/test/build/type-check + secret scan, all must pass before `gh pr create`.
2. **Auto-closing-keyword linkage + non-default-branch warning** — see `references/auto-closing-keywords.md`.
3. **Mandatory handoff to `/github:review-pr`** — the review → fix → commit+push → wait-for-review loop, until CI is green and every comment is triaged. This handoff is default-on; skipped only on explicit `--no-monitor` or user opt-out.
4. **Post-merge branch hygiene** — delegated onward to `/github:review-pr` (Phase 5 closeout), which deletes the remote + local head branches (when stack-safe and in the main worktree), runs `fetch --prune`, fast-forwards local `main`/`develop`, and drops other already-merged locals. See `references/closeout.md`.

## Caller contract (resolve-issues and any future caller)

- Invoke `Skill("github:create-pr", "Closes #<n>")` with the issue reference **verbatim** — do not re-derive or second-guess the auto-closing keyword.
- Pass `--draft` through if early feedback is needed.
- Pass `--no-monitor` through **only** on an explicit user opt-out (never infer it).
- Pass `--auto-merge` through **only** on an explicit user opt-in (never infer it). create-pr forwards it to `/github:review-pr` as `Skill("github:review-pr", "<PR#> --auto-merge")`; review-pr then skips the merge `AskUserQuestion` and runs `gh pr merge --merge` once CI is green and every non-escalate comment is triaged. `escalate` items suspend the opt-in and fall back to the explicit question — see `review-pr/references/closeout.md` (Auto-merge branch).
- Do NOT wait inline for the PR URL; do NOT re-report the PR; do NOT call `gh pr create`.
- Creating the PR directly skips the quality gate, the auto-closing-keyword linkage, the non-default-branch warning, and the review-pr loop — all of it.

## Protected PR workflow

- No direct pushes to `main`/`develop`.
- All changes go through PR + review + CI.
- Every PR enters the `/github:review-pr` loop after creation — review, fix what is verified, commit+push, wait for the next review round — until CI is green and every comment is triaged.
- Use worktrees to isolate development work; clean up after successful merge.

This file consolidates the four copies of the "only PR-creating path" contract that had drifted in their enumerated sub-items (duty order, `--no-monitor` placement, owned-duties list).
