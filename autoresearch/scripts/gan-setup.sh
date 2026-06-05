#!/bin/bash

# Autoresearch GAN Setup
# Validates the GAN-tournament contract, isolates the run on a dedicated
# autoresearch/gan-<tag> branch, and prints a one-line JSON config on stdout for
# the gan workflow (passed verbatim as the Workflow `args`). Human-readable
# messages go to stderr so stdout carries only the JSON.
#
# GAN differs from the ralph-loop (/autoresearch:start): it is a foreground,
# Workflow-driven tournament — parallel candidate edits, judged and synthesized,
# re-scored, iterated until --target-score or --max-rounds. Because a Workflow
# script cannot read the wall clock, the hard bound is --max-rounds (not
# --max-wall-clock), and the artifact must be a SINGLE file (candidates pass full
# file contents as text between agents).

set -euo pipefail

RUN_TAG=""
PROMPT=""
OBJECTIVE=""
EDIT=""
SCORE_CMD=""
CHECK_CMD=""
RUBRIC=""
DIRECTION=""
TARGET_SCORE=""
MAX_ROUNDS=0
CANDIDATES=4
TRIAL_TIMEOUT=600
READONLY_LIST=()
FORCE_START=false

log() { echo "$@" >&2; }

validate_run_tag() {
  local tag="$1"
  if [[ ! "$tag" =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ ]]; then
    log "Error: run tag '$tag' is not a valid git branch name segment."
    log "Use letters, digits, dots, underscores, or hyphens; must not start with '.' or '-'."
    exit 1
  fi
  if [[ "$tag" == *".."* ]] || [[ "$tag" == *"//"* ]]; then
    log "Error: run tag '$tag' contains invalid '..' or '//' sequences."
    exit 1
  fi
}

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      cat >&2 << 'HELP_EOF'
autoresearch GAN — tournament optimizer (fan out, judge, synthesize, iterate)

USAGE:
  /autoresearch:gan [TAG] --prompt "..." --objective "..." --edit FILE \
    --score-cmd "..." --direction min|max --max-rounds N \
    [--target-score X] [--candidates N] [--trial-timeout DUR] [--readonly PATH]

REQUIRED:
  --prompt '<text>'        Research goal handed to each candidate
  --objective '<text>'     What success means
  --edit <file>            The ONE artifact to optimize (must be a single file)
  --max-rounds <n>         Hard bound on tournament rounds (GAN has no wall-clock bound)

  EVALUATOR — at least one (combine freely; a --rubric MUST be anchored by
  --score-cmd or --check-cmd so the judge can't be reward-hacked):
  --score-cmd '<shell>'    Numeric scorer; LAST stdout line is a number (needs --direction)
  --check-cmd '<shell>'    Objective gate; exit 0 = pass. Filters out failing candidates.
  --rubric '<text>'        Criteria an LLM judge panel ranks candidates against
  --direction min|max      Whether a lower or higher score is better (score only)

OPTIONS:
  --target-score <number>  Stop early once the best score reaches/passes this
  --candidates <n>         Parallel candidates per round (default 4)
  --trial-timeout <secs>   Hard time limit per scorer run (default 600)
  --readonly <path>        Protect a path from edits (repeatable)
  --force                  Reuse/replace an existing gan-<tag> branch
  -h, --help               Show this help

Each round: N candidates edit the artifact in isolated worktrees and self-score;
a judge ranks them and flags graftable ideas; a synthesis step combines the
winner with those ideas and is re-scored. The real scorer is always the arbiter.
HELP_EOF
      exit 0
      ;;
    --prompt) [[ -z "${2:-}" ]] && { log "Error: --prompt requires text"; exit 1; }; PROMPT="$2"; shift 2 ;;
    --objective) [[ -z "${2:-}" ]] && { log "Error: --objective requires text"; exit 1; }; OBJECTIVE="$2"; shift 2 ;;
    --edit) [[ -z "${2:-}" ]] && { log "Error: --edit requires a file"; exit 1; }; EDIT="$2"; shift 2 ;;
    --score-cmd) [[ -z "${2:-}" ]] && { log "Error: --score-cmd requires a command"; exit 1; }; SCORE_CMD="$2"; shift 2 ;;
    --check-cmd) [[ -z "${2:-}" ]] && { log "Error: --check-cmd requires a command"; exit 1; }; CHECK_CMD="$2"; shift 2 ;;
    --rubric) [[ -z "${2:-}" ]] && { log "Error: --rubric requires text"; exit 1; }; RUBRIC="$2"; shift 2 ;;
    --direction)
      if [[ "${2:-}" != "min" && "${2:-}" != "max" ]]; then log "Error: --direction must be min or max (got '${2:-}')"; exit 1; fi
      DIRECTION="$2"; shift 2 ;;
    --target-score)
      if [[ -z "${2:-}" ]] || ! [[ "$2" =~ ^-?[0-9]+([.][0-9]+)?$ ]]; then
        log "Error: --target-score requires a number (got '${2:-}')"; exit 1
      fi
      TARGET_SCORE="$2"; shift 2 ;;
    --max-rounds)
      if [[ -z "${2:-}" ]] || ! [[ "$2" =~ ^[0-9]+$ ]] || [[ "$2" -lt 1 ]]; then
        log "Error: --max-rounds requires a positive integer (got '${2:-}')"; exit 1
      fi
      MAX_ROUNDS="$2"; shift 2 ;;
    --candidates)
      if [[ -z "${2:-}" ]] || ! [[ "$2" =~ ^[0-9]+$ ]] || [[ "$2" -lt 2 ]]; then
        log "Error: --candidates requires an integer >= 2 (got '${2:-}')"; exit 1
      fi
      CANDIDATES="$2"; shift 2 ;;
    --trial-timeout)
      if [[ -z "${2:-}" ]] || ! [[ "$2" =~ ^[0-9]+$ ]] || [[ "$2" -lt 1 ]]; then
        log "Error: --trial-timeout requires a positive integer in seconds (got '${2:-}')"; exit 1
      fi
      TRIAL_TIMEOUT="$2"; shift 2 ;;
    --readonly) [[ -z "${2:-}" ]] && { log "Error: --readonly requires a path"; exit 1; }; READONLY_LIST+=("$2"); shift 2 ;;
    --force) FORCE_START=true; shift ;;
    -*) log "Error: unknown option: $1"; log "Run /autoresearch:gan --help for usage."; exit 1 ;;
    *) [[ -z "$RUN_TAG" ]] && RUN_TAG="$1"; shift ;;
  esac
done

if [[ -z "$RUN_TAG" ]]; then
  RUN_TAG=$(LC_ALL=C date +%b%d | tr '[:upper:]' '[:lower:]')
fi
validate_run_tag "$RUN_TAG"

# Required contract.
MISSING=()
[[ -z "$PROMPT" ]] && MISSING+=(--prompt)
[[ -z "$OBJECTIVE" ]] && MISSING+=(--objective)
[[ -z "$EDIT" ]] && MISSING+=(--edit)
[[ "$MAX_ROUNDS" -eq 0 ]] && MISSING+=(--max-rounds)
if [[ ${#MISSING[@]} -gt 0 ]]; then
  log "Error: missing required flags: ${MISSING[*]}"
  log "Run /autoresearch:gan --help for the full contract."
  exit 1
fi

# Pluggable evaluator: numeric scorer, objective gate, and/or LLM rubric judge.
if [[ -z "$SCORE_CMD" ]] && [[ -z "$CHECK_CMD" ]] && [[ -z "$RUBRIC" ]]; then
  log "Error: provide an evaluator — --score-cmd (numeric), --check-cmd (pass/fail gate), and/or --rubric (LLM judge)."
  exit 1
fi
if [[ -n "$SCORE_CMD" ]] && [[ -z "$DIRECTION" ]]; then
  log "Error: --score-cmd requires --direction min|max."
  exit 1
fi
# Anti-reward-hack: a rubric (subjective) must be anchored to an objective signal
# so the tournament cannot just optimize the judge's opinion.
if [[ -n "$RUBRIC" ]] && [[ -z "$SCORE_CMD" ]] && [[ -z "$CHECK_CMD" ]]; then
  log "Error: --rubric needs an objective anchor — add --score-cmd or --check-cmd."
  log "A judge-only loop reward-hacks its own evaluator; ground it in a number or a gate."
  exit 1
fi

# GAN passes full file contents between agents, so the artifact must be ONE file.
EDIT_MATCHES=$(compgen -G "$EDIT" 2>/dev/null || true)
EDIT_COUNT=$(printf '%s\n' "$EDIT_MATCHES" | grep -c . || true)
if [[ "$EDIT_COUNT" -ne 1 ]]; then
  log "Error: --edit '$EDIT' must match exactly ONE existing file (matched: ${EDIT_COUNT})."
  log "GAN mode optimizes a single-file artifact. Use /autoresearch:start for multi-file or glob targets."
  exit 1
fi
EDIT="$EDIT_MATCHES"
if [[ ! -f "$EDIT" ]]; then
  log "Error: --edit '$EDIT' is not a regular file."
  exit 1
fi

# Git isolation: clean tree, dedicated branch (candidates run in worktrees off it).
if ! git rev-parse --git-dir >/dev/null 2>&1; then
  log "Error: not inside a git repository."
  exit 1
fi
if [[ -n "$(git status --porcelain)" ]]; then
  log "Error: working tree has uncommitted changes."
  log "GAN candidates run in worktrees off this branch; commit or stash first."
  exit 1
fi

TARGET_BRANCH="autoresearch/gan-$RUN_TAG"
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [[ "$CURRENT_BRANCH" != "$TARGET_BRANCH" ]]; then
  if git show-ref --verify --quiet "refs/heads/$TARGET_BRANCH"; then
    if [[ "$FORCE_START" != true ]]; then
      log "Error: branch $TARGET_BRANCH already exists. Pass --force to reuse it, or choose a different TAG."
      exit 1
    fi
    git checkout "$TARGET_BRANCH" >&2
  else
    git checkout -b "$TARGET_BRANCH" >&2
  fi
  log "Switched to GAN branch: $TARGET_BRANCH"
fi

# Emit the workflow config as a single JSON line on stdout (python handles escaping).
TARGET_ARG="${TARGET_SCORE:-}" \
EDIT="$EDIT" PROMPT="$PROMPT" OBJECTIVE="$OBJECTIVE" SCORE_CMD="$SCORE_CMD" \
CHECK_CMD="$CHECK_CMD" RUBRIC="$RUBRIC" \
DIRECTION="$DIRECTION" MAX_ROUNDS="$MAX_ROUNDS" CANDIDATES="$CANDIDATES" \
TRIAL_TIMEOUT="$TRIAL_TIMEOUT" RUN_TAG="$RUN_TAG" \
READONLY_CSV="$( IFS=$'\n'; echo "${READONLY_LIST[*]-}" )" \
python3 -c '
import json, os
ro = [x for x in os.environ.get("READONLY_CSV", "").split("\n") if x]
t = os.environ.get("TARGET_ARG", "")
def opt(k):
    v = os.environ.get(k, "")
    return v if v else None
cfg = {
    "run_tag": os.environ["RUN_TAG"],
    "edit": os.environ["EDIT"],
    "prompt": os.environ["PROMPT"],
    "objective": os.environ["OBJECTIVE"],
    "score_cmd": opt("SCORE_CMD"),
    "check_cmd": opt("CHECK_CMD"),
    "rubric": opt("RUBRIC"),
    "direction": opt("DIRECTION"),
    "target_score": (float(t) if t else None),
    "max_rounds": int(os.environ["MAX_ROUNDS"]),
    "candidates": int(os.environ["CANDIDATES"]),
    "trial_timeout": int(os.environ["TRIAL_TIMEOUT"]),
    "readonly": ro,
}
print(json.dumps(cfg))
'

log ""
log "GAN configured on branch $TARGET_BRANCH:"
log "  edit:        $EDIT"
log "  evaluator:   $( [[ -n "$SCORE_CMD" ]] && echo "score='$SCORE_CMD' ($DIRECTION)" )$( [[ -n "$CHECK_CMD" ]] && echo " gate='$CHECK_CMD'" )$( [[ -n "$RUBRIC" ]] && echo " rubric='$RUBRIC'" )"
log "  target: ${TARGET_SCORE:-none}   max-rounds: $MAX_ROUNDS   candidates: $CANDIDATES   per-run timeout ${TRIAL_TIMEOUT}s"
log ""
log "Next: run the gan workflow with the JSON config above as its args."
