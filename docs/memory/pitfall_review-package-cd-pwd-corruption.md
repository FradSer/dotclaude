---
name: review-package-cd-pwd-corruption
category: pitfall
summary: review-package.sh cd+pwd substitution corrupts PLAN_DIR resolution
source: docs/plans/2026-07-04-superpowers-memory-layer-plan/handoff-state.md
created: 2026-07-06
updated: 2026-07-06
---

# review-package.sh's directory resolution corrupts output inside command substitution

## Fact
`superpowers/lib/review-package.sh` resolves its own directory using a
`cd $(dirname "$0") && pwd` pattern invoked inside a command substitution.
When run this way, the `cd`'s side effects get folded into the substitution's
captured output, corrupting the resolved path. Any caller invoking
`review-package.sh BASE HEAD PLAN_DIR` the normal way gets a broken diff
package instead of the expected `_reviews/review-<base7>..<head7>.diff` file.

## Why
All 5 batch coordinators executing the superpowers-memory-layer-plan
(2026-07-04..07-06) independently hit this and worked around it the same
way — first flagged by the batch-1 coordinator, then re-confirmed by
batches 2-5. Recurring identically across 5 independent sub-agent contexts
makes this a genuine cross-cutting gotcha, not a one-off environment quirk.
`lib/docs-index.sh`'s own header comment already documents a similar
`cd`-in-command-substitution workaround, suggesting this class of bug has
bitten this codebase before and is worth a standing warning.

## How to Apply
Before trusting `review-package.sh`'s output, sanity-check that `PLAN_DIR`
resolved correctly. Until the script is fixed, generate review diffs
directly instead:
`git diff <base> -- <files> > <plan-dir>/_reviews/review-<base7>..<head7>.diff`.
A proper fix replaces the `cd ... && pwd` idiom with
`dirname "$(readlink -f "$0")"` or `${BASH_SOURCE[0]}`-based resolution that
doesn't rely on a subshell `cd` side effect leaking into `$(...)`.

## Related
- Source plan: `docs/plans/2026-07-04-superpowers-memory-layer-plan/handoff-state.md` (flagged in Key Decisions across all 5 batches)
