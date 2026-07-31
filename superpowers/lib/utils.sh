#!/bin/bash
# Shared utilities for the surviving superpowers lib scripts (jsonl-emit.sh,
# post-plan-diff.sh, seed-checklists.sh) and the executing-plans batch-progress
# helper. Slimmed in v3.0.0 to a single helper — the broader state-machine /
# concurrency / promise-extraction surface was removed alongside the
# continuation-loop runtime (Removed in v3.0.0).

# Resolve the project (repo) root path used by every writer that targets
# docs/retros/* under the project root.
#
# Resolution order:
#   1. ${CLAUDE_PROJECT_DIR}  — official Claude Code env var (set in every
#      hook event, and `claude` exports it in non-hook contexts as well).
#   2. `git rev-parse --show-toplevel` — fallback when running outside the
#      hook harness (e.g. test fixtures, direct CLI invocations).
#   3. ${PWD} — last-resort fallback when not in a git repo and the env var
#      is absent; preserves the pre-T-001 PWD-anchored behavior.
#
# Single source of truth — jsonl-emit.sh / post-plan-diff.sh / seed-checklists.sh
# / executing-plans/scripts/batch-progress.sh and any future writer must call
# this helper rather than re-implementing the resolution.
# Usage: ROOT=$(repo_root)
repo_root() {
  if [[ -n "${CLAUDE_PROJECT_DIR:-}" ]]; then
    printf '%s' "$CLAUDE_PROJECT_DIR"
    return 0
  fi
  local git_root
  git_root=$(git rev-parse --show-toplevel 2>/dev/null || true)
  if [[ -n "$git_root" ]]; then
    printf '%s' "$git_root"
    return 0
  fi
  printf '%s' "${PWD:-}"
}
