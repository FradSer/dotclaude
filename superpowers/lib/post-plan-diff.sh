#!/bin/bash
# lib/post-plan-diff.sh — read post-plan git activity for retrospective Phase 1.
#
# Empirical motivation (user-simulation project, superpowers v2.7.0): a plan
# completed 2026-05-08T02:14, the retrospective ran 16 minutes later (02:30),
# and the user produced 5 refactor commits in the 12-13h window after the
# retrospective ran. Those refactors directly indicated recurring patterns
# the evaluator missed (disfluency standardization, OpenAI client model
# parameters, PII patterns) — but with no post-plan diff loop, the
# retrospective saw "Recurring Failure Patterns injection empty in 6
# batches" and disabled the component as redundant. The disable decision
# was based on the absence of a signal the harness could not see.
#
# This helper closes that gap by treating post-plan commits as the missing
# data channel:
#   - `refactor:` / `fix:` / `style:` commits  → feedback on superpowers
#                                                output (real signal)
#   - `feat:` / `chore:` / `docs:` / `build:` / `ci:` / `test:`
#                                              → evolution (noise — user
#                                                added new requirements,
#                                                not corrected the harness)
#   - everything else                          → unknown (LLM tiebreak,
#                                                retrospective decides)
#
# Two invocation modes:
#   1. Sourced: source "${CLAUDE_PLUGIN_ROOT}/lib/post-plan-diff.sh"
#              then call classify_commit_subject / post_plan_commits
#   2. Executed (returns NDJSON): bash "${CLAUDE_PLUGIN_ROOT}/lib/post-plan-diff.sh"
#                                      <subcommand> <args>
#                                 subcommands: classify | list | summary
#
# Best-effort throughout. Helper deliberately has no `set -e` so sourcing
# does not alter the caller's error-handling regime.

# Conventional-commit type buckets — single source of truth for the
# feedback/evolution partition. `perf` joins feedback because a perf commit
# on plan files almost always means superpowers wrote it slow. `revert` is
# evolution: a revert is a deliberate course-correction by the user, not a
# defect in the original output. Anything not listed → unknown.
# Whitespace-padded so substring matching is exact-token.
_FEEDBACK_TYPES=" refactor fix style perf "
_EVOLUTION_TYPES=" feat chore docs build ci test revert "

# Classify a single commit subject line by conventional commit type.
# Echoes one of: feedback | evolution | unknown
# Usage: classify_commit_subject "refactor(scope): message"
classify_commit_subject() {
  local subject="${1:-}"
  # Conventional-commit prefix: lowercase type, optional `(scope)`,
  # optional `!` (breaking change), then `:`. Anchor at the start so
  # subjects with the type embedded mid-line are not misclassified.
  local prefix
  prefix=$(printf '%s' "$subject" | sed -nE 's/^([a-z]+)(\([^)]*\))?!?:.*/\1/p')

  if [[ -n "$prefix" && "$_FEEDBACK_TYPES" == *" $prefix "* ]]; then
    echo "feedback"
  elif [[ -n "$prefix" && "$_EVOLUTION_TYPES" == *" $prefix "* ]]; then
    echo "evolution"
  else
    echo "unknown"
  fi
}

# List commits made after a given completion_commit that touch any of the
# given files. Output: one NDJSON line per commit with sha, subject, type,
# classification. Restricting to plan-modified files filters out unrelated
# user work in the same repo (the most common false-positive).
#
# Usage: post_plan_commits <completion_commit> <files...>
#        files... is the unpacked .completion_modified_files array; pass
#        absolute or repo-relative paths (git accepts both via -- separator).
#        When the file list is empty, falls back to ALL files (caller's
#        responsibility to know this is a wide net).
post_plan_commits() {
  local completion_commit="${1:-}"
  shift || true
  local files=("$@")

  [[ -z "$completion_commit" ]] && return 0
  command -v git >/dev/null 2>&1 || return 0
  command -v jq >/dev/null 2>&1 || return 0

  # `git log <commit>..HEAD` lists commits AFTER completion_commit. Empty
  # output (no post-plan activity) is a meaningful signal handled by the
  # caller — do not warn here.
  local log_args=(--no-pager log "${completion_commit}..HEAD"
                  --pretty=format:'%H%x09%s' --no-merges)
  if [[ ${#files[@]} -gt 0 ]]; then
    log_args+=(--)
    log_args+=("${files[@]}")
  fi

  # `|| [[ -n "$sha" ]]` rescues the last line when git log's output lacks
  # a trailing newline — `read -r` returns 1 in that case, exiting the
  # loop one record early. Smoke against user-simulation showed 8/9
  # commits without this rescue.
  local sha subject classification
  while IFS=$'\t' read -r sha subject || [[ -n "$sha" ]]; do
    [[ -z "$sha" ]] && continue
    classification=$(classify_commit_subject "$subject")
    jq -nc \
      --arg sha "$sha" \
      --arg subject "$subject" \
      --arg class "$classification" \
      '{sha:$sha, subject:$subject, classification:$class}'
  done < <(git "${log_args[@]}" 2>/dev/null || true)
}

# Summarize post-plan commits as counts per classification. Streams git log
# directly through classify_commit_subject — avoids the per-commit jq fork
# the NDJSON-emitting list path needs.
# Output: single NDJSON object with feedback / evolution / unknown / total.
# Usage: post_plan_summary <completion_commit> <files...>
post_plan_summary() {
  local completion_commit="${1:-}"
  shift || true
  local files=("$@")
  local feedback=0 evolution=0 unknown=0 total=0

  [[ -z "$completion_commit" ]] && command -v git >/dev/null 2>&1 || {
    [[ -z "$completion_commit" ]] || command -v jq >/dev/null 2>&1 || true
  }

  if [[ -n "$completion_commit" ]] && command -v git >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    local log_args=(--no-pager log "${completion_commit}..HEAD"
                    --pretty=format:'%s' --no-merges)
    if [[ ${#files[@]} -gt 0 ]]; then
      log_args+=(--)
      log_args+=("${files[@]}")
    fi

    local subject
    while IFS= read -r subject || [[ -n "$subject" ]]; do
      [[ -z "$subject" ]] && continue
      case "$(classify_commit_subject "$subject")" in
        feedback)  feedback=$((feedback + 1)) ;;
        evolution) evolution=$((evolution + 1)) ;;
        *)         unknown=$((unknown + 1)) ;;
      esac
      total=$((total + 1))
    done < <(git "${log_args[@]}" 2>/dev/null || true)
  fi

  jq -nc \
    --argjson feedback "$feedback" \
    --argjson evolution "$evolution" \
    --argjson unknown "$unknown" \
    --argjson total "$total" \
    '{total:$total, feedback:$feedback, evolution:$evolution, unknown:$unknown}'
}

# Direct execution dispatcher — supports CLI use from SKILL.md instructions.
# Sourcing this file (BASH_SOURCE[0] != $0) does not trigger this branch.
if [[ "${BASH_SOURCE[0]:-$0}" == "${0}" ]]; then
  case "${1:-}" in
    classify) shift; classify_commit_subject "$@" ;;
    list)     shift; post_plan_commits "$@" ;;
    summary)  shift; post_plan_summary "$@" ;;
    *)
      echo "usage: post-plan-diff.sh {classify <subject> | list <commit> [files...] | summary <commit> [files...]}" >&2
      exit 2
      ;;
  esac
fi
