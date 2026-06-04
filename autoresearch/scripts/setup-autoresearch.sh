#!/bin/bash

# Autoresearch Setup Script
# Initializes the autonomous research loop state file for a project.
# The loop prompt embeds the full experiment instructions (equivalent to program.md).
# Domain-agnostic: the editable artifact, the scorer, and the optimization
# direction are all supplied as flags, so the loop works on any problem that can
# be reduced to "edit something, run a scorer that prints one number, keep the
# change if the number improved" — not just ML training.

set -euo pipefail

RUN_TAG=""
MAX_ITERATIONS=0
MAX_SECONDS=0
COMPLETION_PROMISE="null"
SESSION_ID=""
FORCE_START=false

PROMPT=""
OBJECTIVE=""
EDIT=""
SCORE_CMD=""
DIRECTION=""
TRIAL_TIMEOUT=600
READONLY_LIST=()
PRECHECKS=()

STATE_FILE=".claude/autoresearch.local.md"

# Parse a duration with optional h/m/s suffix. Bare numbers use $2 as default unit.
# Usage: parse_duration "$value" h   # bare "8" → 28800
#        parse_duration "$value" s   # bare "600" → 600
parse_duration() {
  local v="$1" default_unit="$2"
  if [[ "$v" =~ ^([0-9]+)([hms]?)$ ]]; then
    local num="${BASH_REMATCH[1]}" unit="${BASH_REMATCH[2]:-$default_unit}"
    case "$unit" in
      h) echo $((num * 3600)) ;;
      m) echo $((num * 60)) ;;
      s) echo "$num" ;;
    esac
    return 0
  fi
  return 1
}

# Escape a string for embedding inside single-quoted sh -c '...'.
sh_single_quote_escape() {
  printf "%s" "$1" | sed "s/'/'\\\\''/g"
}

# Git ref segment for autoresearch/<tag> — reject pathological branch names.
validate_run_tag() {
  local tag="$1"
  if [[ ! "$tag" =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ ]]; then
    echo "Error: run tag '$tag' is not a valid git branch name segment." >&2
    echo "Use letters, digits, dots, underscores, or hyphens; must not start with '.' or '-'." >&2
    exit 1
  fi
  if [[ "$tag" == *".."* ]] || [[ "$tag" == *"//"* ]]; then
    echo "Error: run tag '$tag' contains invalid '..' or '//' sequences." >&2
    exit 1
  fi
}

# Escape a value into a YAML double-quoted scalar for the state-file frontmatter.
# Rejects embedded newlines, which would split the frontmatter block the stop
# hook parses. Backslashes and double quotes are escaped. The hook never parses
# these new fields (they are for monitoring), but valid YAML keeps tools happy.
yaml_escape() {
  local v="$1"
  if [[ "$v" == *$'\n'* ]]; then
    echo "Error: value contains a newline, which would corrupt the state file." >&2
    exit 1
  fi
  v="${v//\\/\\\\}"
  v="${v//\"/\\\"}"
  printf '"%s"' "$v"
}

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      cat << 'HELP_EOF'
autoresearch — Autonomous research loop for any objective

USAGE:
  /autoresearch:start [TAG] --prompt "..." --objective "..." \
    --edit PATH --score-cmd "..." --direction min|max \
    (--max-experiments N | --max-wall-clock 8h) [OPTIONS]

ARGUMENTS:
  TAG    Run tag for the experiment branch.
         Defaults to today's date as <mon><dd> (e.g. mar16 for Mar 16).

REQUIRED CONTRACT:
  --prompt '<text>'        Free-form research goal handed to the agent
  --objective '<text>'     The measurable target you are optimizing
  --edit <glob|path>       The ONLY artifact the agent may modify
  --score-cmd '<shell>'    Command whose LAST stdout line is a single number
  --direction min|max      Whether a lower or higher score is better

  At least one of --max-experiments or --max-wall-clock is ALSO required —
  the loop refuses to start unbounded.

OPTIONS:
  --max-experiments <n>          Stop after N experiments
  --max-wall-clock <duration>    Stop after a wall-clock budget (e.g. 8h, 480m, 30s)
  --readonly <path>              Protect a path from edits (repeatable)
  --trial-timeout <duration>     Hard time limit per scorer run (default 600s; plain numbers are seconds)
  --precheck '<shell>'           Precondition that must exit 0 (repeatable)
  --completion-promise '<text>'  Phrase the agent outputs to signal completion
  --force                        Replace an existing active loop state file
  -h, --help                     Show this help message

DESCRIPTION:
  Starts an autonomous research loop in the current session. Each experiment:
  the agent makes one change to --edit, commits it, runs --score-cmd (hard
  time-limited), reads the LAST stdout line as the score, logs it to
  results.tsv, and keeps the commit only if the score improved in --direction
  — otherwise it discards the change with git reset --hard HEAD~1.

  The stop hook intercepts every exit attempt and feeds the same research
  prompt back, so the agent keeps experimenting until a bound is reached.

  To signal completion, the agent outputs: <promise>YOUR_PHRASE</promise>

EXAMPLES:
  # Data cleaning — maximize F1 from a scorer script
  /autoresearch:start clean1 --prompt 'improve the cleaning rules' \
    --objective 'maximize F1, precision >= 0.90' \
    --edit clean.py --readonly score.sh --score-cmd 'bash score.sh' \
    --direction max --max-experiments 20

  # ML training parity — reproduce the original behavior
  /autoresearch:start --prompt 'lower validation bits-per-byte' \
    --objective 'minimize val_bpb' --edit train.py \
    --readonly prepare.py --readonly evaluate_bpb \
    --score-cmd 'timeout 600 uv run train.py >run.log 2>&1; grep "^val_bpb:" run.log | awk "{print \$2}"' \
    --direction min --max-wall-clock 8h

REQUIREMENTS:
  - A git repository (the loop runs on a dedicated autoresearch/<tag> branch)
  - A --score-cmd that prints one comparable number as its LAST stdout line
  - Whatever runtime that scorer needs (interpreter, data, GPU, ...) — your call

STOPPING:
  - Reaches --max-experiments limit
  - Exceeds --max-wall-clock budget
  - Agent outputs <promise>PHRASE</promise>
  - Run /autoresearch:cancel to force-stop

MONITORING:
  grep '^iteration:' .claude/autoresearch.local.md  # current experiment number
  cat results.tsv                                     # experiment log
HELP_EOF
      exit 0
      ;;
    --max-experiments)
      if [[ -z "${2:-}" ]] || ! [[ "$2" =~ ^[0-9]+$ ]]; then
        echo "Error: --max-experiments requires a non-negative integer (got: '${2:-}')" >&2
        exit 1
      fi
      MAX_ITERATIONS="$2"
      shift 2
      ;;
    --max-wall-clock)
      if [[ -z "${2:-}" ]] || ! MAX_SECONDS=$(parse_duration "$2" h); then
        echo "Error: --max-wall-clock requires a duration like 8h, 480m, or 30s (got: '${2:-}')" >&2
        exit 1
      fi
      shift 2
      ;;
    --prompt)
      if [[ -z "${2:-}" ]]; then echo "Error: --prompt requires a text argument" >&2; exit 1; fi
      PROMPT="$2"; shift 2 ;;
    --objective)
      if [[ -z "${2:-}" ]]; then echo "Error: --objective requires a text argument" >&2; exit 1; fi
      OBJECTIVE="$2"; shift 2 ;;
    --edit)
      if [[ -z "${2:-}" ]]; then echo "Error: --edit requires a path or glob" >&2; exit 1; fi
      EDIT="$2"; shift 2 ;;
    --score-cmd)
      if [[ -z "${2:-}" ]]; then echo "Error: --score-cmd requires a shell command" >&2; exit 1; fi
      SCORE_CMD="$2"; shift 2 ;;
    --direction)
      if [[ "${2:-}" != "min" && "${2:-}" != "max" ]]; then
        echo "Error: --direction must be 'min' or 'max' (got: '${2:-}')" >&2; exit 1
      fi
      DIRECTION="$2"; shift 2 ;;
    --trial-timeout)
      if [[ -z "${2:-}" ]] || ! TRIAL_TIMEOUT=$(parse_duration "$2" s); then
        echo "Error: --trial-timeout requires a duration like 600, 600s, 10m, or 1h (got: '${2:-}')" >&2
        exit 1
      fi
      shift 2
      ;;
    --readonly)
      if [[ -z "${2:-}" ]]; then echo "Error: --readonly requires a path" >&2; exit 1; fi
      READONLY_LIST+=("$2"); shift 2 ;;
    --precheck)
      if [[ -z "${2:-}" ]]; then echo "Error: --precheck requires a shell command" >&2; exit 1; fi
      PRECHECKS+=("$2"); shift 2 ;;
    --completion-promise)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --completion-promise requires a text argument" >&2
        exit 1
      fi
      COMPLETION_PROMISE="$2"
      shift 2
      ;;
    --session-id)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --session-id requires a value" >&2
        exit 1
      fi
      SESSION_ID="$2"
      shift 2
      ;;
    --force)
      FORCE_START=true
      shift
      ;;
    -*)
      echo "Error: Unknown option: $1" >&2
      echo "Run /autoresearch:start --help for usage." >&2
      exit 1
      ;;
    *)
      if [[ -z "$RUN_TAG" ]]; then
        RUN_TAG="$1"
      fi
      shift
      ;;
  esac
done

# Default run tag: current date (e.g. mar16). Force the C locale so the month
# name is always ASCII — a localized `date` (e.g. zh_CN) yields "6月16", which
# is not a valid git branch name.
if [[ -z "$RUN_TAG" ]]; then
  RUN_TAG=$(LC_ALL=C date +%b%d | tr '[:upper:]' '[:lower:]')
fi
validate_run_tag "$RUN_TAG"

# Require at least one stopping bound — never start an unbounded overnight loop.
if [[ "$MAX_ITERATIONS" -eq 0 ]] && [[ "$MAX_SECONDS" -eq 0 ]]; then
  echo "Error: an autoresearch loop must have a bound." >&2
  echo "Provide --max-experiments <n> and/or --max-wall-clock <duration> (e.g. 8h)." >&2
  echo "Run /autoresearch:start --help for details." >&2
  exit 1
fi

# Require the research contract — the loop is domain-agnostic, so the problem,
# the editable artifact, the scorer, and the direction must all be supplied.
MISSING=()
[[ -z "$PROMPT" ]] && MISSING+=(--prompt)
[[ -z "$OBJECTIVE" ]] && MISSING+=(--objective)
[[ -z "$EDIT" ]] && MISSING+=(--edit)
[[ -z "$SCORE_CMD" ]] && MISSING+=(--score-cmd)
[[ -z "$DIRECTION" ]] && MISSING+=(--direction)
if [[ ${#MISSING[@]} -gt 0 ]]; then
  echo "Error: missing required flags: ${MISSING[*]}" >&2
  echo "Run /autoresearch:start --help for the full contract." >&2
  exit 1
fi

# The editable artifact must match at least one existing path, so the agent
# isn't pointed at something that doesn't exist.
if ! compgen -G "$EDIT" >/dev/null; then
  echo "Error: --edit '$EDIT' matches no existing file in the current directory." >&2
  exit 1
fi

# Run domain preconditions (fail loud, like the old train.py/prepare.py checks).
for check in ${PRECHECKS[@]+"${PRECHECKS[@]}"}; do
  if ! sh -c "$check" >/dev/null 2>&1; then
    echo "Error: precheck failed: $check" >&2
    exit 1
  fi
done

# Ensure the loop runs on a dedicated branch, never on a protected branch and
# never on a dirty tree — the loop auto-discards experiments with `git reset
# --hard`, which would otherwise destroy unrelated work. Done here (not in the
# injected prompt) so isolation is deterministic, not left to the agent.
if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "Error: not inside a git repository." >&2
  exit 1
fi

if [[ -n "$(git status --porcelain)" ]]; then
  echo "Error: working tree has uncommitted changes." >&2
  echo "Autoresearch auto-discards experiments with 'git reset --hard', which would destroy them." >&2
  echo "Commit or stash your changes, then re-run /autoresearch:start." >&2
  exit 1
fi

TARGET_BRANCH="autoresearch/$RUN_TAG"
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

if [[ "$CURRENT_BRANCH" != "$TARGET_BRANCH" ]]; then
  if git show-ref --verify --quiet "refs/heads/$TARGET_BRANCH"; then
    git checkout "$TARGET_BRANCH"
  else
    git checkout -b "$TARGET_BRANCH"
  fi
  echo "Switched to experiment branch: $TARGET_BRANCH"
fi

# Quote completion promise for YAML if needed.
if [[ -n "$COMPLETION_PROMISE" ]] && [[ "$COMPLETION_PROMISE" != "null" ]]; then
  COMPLETION_PROMISE_YAML=$(yaml_escape "$COMPLETION_PROMISE")
else
  COMPLETION_PROMISE_YAML="null"
fi

# Session isolation: refuse to start without a resolved session id.
if [[ -z "$SESSION_ID" ]] || [[ "$SESSION_ID" == *'${'* ]]; then
  echo "Error: could not resolve this session's id (CLAUDE_SESSION_ID)." >&2
  echo "Autoresearch requires session isolation so other sessions are not pulled into the loop." >&2
  echo "Re-run /autoresearch:start from a normal Claude Code session." >&2
  exit 1
fi

# Human-readable and machine-readable read-only lists.
if [[ ${#READONLY_LIST[@]} -gt 0 ]]; then
  READONLY_DISPLAY=$(IFS=', '; echo "${READONLY_LIST[*]}")
  READONLY_CSV=$(IFS=','; echo "${READONLY_LIST[*]}")
else
  READONLY_DISPLAY="(none specified)"
  READONLY_CSV=""
fi

# The keep/discard rule, generated from the optimization direction.
_DIR_WORD=$( [[ "$DIRECTION" == "min" ]] && echo LOWER || echo HIGHER )
DECISION_RULE="If SCORE is $_DIR_WORD (better) than the best score recorded so far in results.tsv: keep the commit — it advances the branch. Otherwise: discard it with git reset --hard HEAD~1."

# Pre-escape frontmatter values (the hook never reads these, but keep the block
# well-formed and impossible to break out of).
EDIT_YAML=$(yaml_escape "$EDIT")
SCORE_CMD_YAML=$(yaml_escape "$SCORE_CMD")
OBJECTIVE_YAML=$(yaml_escape "$OBJECTIVE")
READONLY_YAML=$(yaml_escape "$READONLY_CSV")
RUN_TAG_YAML=$(yaml_escape "$RUN_TAG")
SESSION_ID_YAML=$(yaml_escape "$SESSION_ID")
SCORE_CMD_SH=$(sh_single_quote_escape "$SCORE_CMD")

mkdir -p .claude

if [[ -f "$STATE_FILE" ]] && [[ "$FORCE_START" != true ]]; then
  ACTIVE=$(awk '/^---$/{n++; next} n==1 && /^active:/{sub(/^active:[[:space:]]*/, ""); print; exit}' "$STATE_FILE" 2>/dev/null || true)
  if [[ "$ACTIVE" == "true" ]]; then
    echo "Error: an autoresearch loop is already active in this directory." >&2
    echo "Run /autoresearch:cancel to stop it, or pass --force to replace the state file." >&2
    exit 1
  fi
fi

# Unquoted heredoc: substituted values are literal (not re-scanned by the shell).
cat > "$STATE_FILE" << AUTORESEARCH_STATE_EOF
---
active: true
iteration: 1
session_id: $SESSION_ID_YAML
max_iterations: $MAX_ITERATIONS
max_seconds: $MAX_SECONDS
completion_promise: $COMPLETION_PROMISE_YAML
run_tag: $RUN_TAG_YAML
edit_target: $EDIT_YAML
readonly_list: $READONLY_YAML
score_cmd: $SCORE_CMD_YAML
direction: $DIRECTION
trial_timeout: $TRIAL_TIMEOUT
objective: $OBJECTIVE_YAML
started_at: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
started_at_epoch: $(date +%s)
---
You are an autonomous researcher running an experiment loop for run tag: $RUN_TAG.

## Goal

$PROMPT

Your optimization objective: $OBJECTIVE

## Ground rules

- You may edit ONLY: $EDIT
- NEVER modify (read-only): $READONLY_DISPLAY
- The experiment branch is: autoresearch/$RUN_TAG (already checked out — do NOT create or switch branches).
- One concrete change per experiment. Simpler is better: a small improvement from simple code beats a large improvement from complex code.
- Do NOT install new packages or add dependencies unless the goal explicitly requires it.
- Do NOT ask for permission to continue between experiments. Keep iterating until the configured bound (max experiments or wall-clock budget) is reached — the stop hook enforces it automatically. You are the researcher. The human is asleep.

## Setup (first iteration only)

If results.tsv does not exist:
1. You are already on the experiment branch autoresearch/$RUN_TAG. Do NOT create or switch branches.
2. Read README.md (if present) and the editable artifact ($EDIT) to understand the codebase.
3. Create results.tsv with just the header row: printf 'commit\tscore\tstatus\tdescription\n' > results.tsv
4. Run the BASELINE: run the scorer on the unmodified artifact, log the score as the first row (status keep). This is the bar to beat.

## Experiment loop

LOOP until the configured bound is reached:

1. Check git state: current branch and last commit (run: git log --oneline -5)
2. Choose one concrete experimental change to $EDIT aimed at the objective.
3. Commit the change: git add $EDIT && git commit -m "experiment: <short description>"
4. Run the scorer (hard time-limited):
   timeout $TRIAL_TIMEOUT sh -c '$SCORE_CMD_SH'
   - The LAST line of the scorer's stdout MUST be a single number — that is SCORE.
   - A timeout (exit code 124), or a missing / non-numeric last line, counts as a crash: log status crash and move on.
5. Read SCORE = the last stdout line of the scorer.
   - If it crashed: inspect the scorer output to diagnose. Fix simple crashes (typos, missing imports) and re-run. Give up after 3 failed attempts.
6. Log to results.tsv (tab-separated, NOT comma-separated):
   - Format: <7-char-commit>\t<score>\t<status>\t<description>
   - status: keep, discard, or crash
   - Use 0 for the score of a crash.
7. Decision ($DIRECTION):
   - $DECISION_RULE

## Rules

- Modify ONLY $EDIT. Never touch the read-only paths: $READONLY_DISPLAY.
- The scorer command is fixed; do NOT change how the score is measured.
- If stuck, think harder: try a different angle on the objective, not just parameter nudges.
- To stop early when the objective is genuinely achieved, output: <promise>...</promise> (only if a completion promise was configured).
AUTORESEARCH_STATE_EOF

# Print activation message
cat << EOF
Autoresearch loop activated!

Run tag:      $RUN_TAG
Branch:       autoresearch/$RUN_TAG
Edit target:  $EDIT
Read-only:    $READONLY_DISPLAY
Scorer:       $SCORE_CMD
Direction:    $DIRECTION (per-trial timeout ${TRIAL_TIMEOUT}s)
Objective:    $OBJECTIVE
Max experiments: $(if [[ $MAX_ITERATIONS -gt 0 ]]; then echo $MAX_ITERATIONS; else echo "unlimited"; fi)
Wall-clock budget: $(if [[ $MAX_SECONDS -gt 0 ]]; then echo "${MAX_SECONDS}s"; else echo "none"; fi)
Completion promise: $(if [[ "$COMPLETION_PROMISE" != "null" ]]; then echo "$COMPLETION_PROMISE"; else echo "none"; fi)

The stop hook is now active. Every time you try to exit, the research
prompt will be fed back — the loop keeps experimenting until stopped.

Monitor progress:
  grep '^iteration:' .claude/autoresearch.local.md   # experiment count
  cat results.tsv                                     # experiment log

To stop: /autoresearch:cancel
EOF

if [[ "$COMPLETION_PROMISE" != "null" ]]; then
  echo ""
  echo "To signal completion, output this exact text:"
  echo "  <promise>$COMPLETION_PROMISE</promise>"
  echo "(ONLY when the research goal is genuinely achieved)"
fi

echo ""
echo "--- Starting autoresearch for run tag: $RUN_TAG ---"
echo ""
echo "Read the goal and the editable artifact ($EDIT), then begin the experiment loop."
