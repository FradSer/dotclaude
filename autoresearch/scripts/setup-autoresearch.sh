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
CHECK_CMD=""
RUBRIC=""
DIRECTION=""
TRIAL_TIMEOUT=600
READONLY_LIST=()
PRECHECKS=()

STATE_FILE=".claude/autoresearch.local.md"

# Absolute path to the bundled tournament engine. The plateau-escalation step in
# the injected prompt invokes it via the Workflow tool, but ${CLAUDE_PLUGIN_ROOT}
# is NOT available when the stop hook re-injects the prompt — so bake the absolute
# path in here, where the script knows its own location.
PLUGIN_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
GAN_SCRIPT="$PLUGIN_ROOT/workflows/gan.mjs"

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

  EVALUATOR — at least one of these (combine for a gated optimization):
  --score-cmd '<shell>'    Numeric scorer; LAST stdout line is a single number
                           (requires --direction)
  --check-cmd '<shell>'    Objective gate; exit 0 = pass, non-zero = fail. A
                           failing candidate is rejected. Use alone to "iterate
                           until it passes", or with --score-cmd as a hard filter.
  --rubric '<text>'        Criteria an LLM judge panel applies when a plateau
                           escalates to a tournament. Needs a --score-cmd or
                           --check-cmd anchor (a judge-only loop reward-hacks).
  --direction min|max      Whether a lower or higher score is better (score only)

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
  — otherwise it discards the change with git checkout -- $EDIT.

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
    --check-cmd)
      if [[ -z "${2:-}" ]]; then echo "Error: --check-cmd requires a shell command" >&2; exit 1; fi
      CHECK_CMD="$2"; shift 2 ;;
    --rubric)
      if [[ -z "${2:-}" ]]; then echo "Error: --rubric requires a text argument" >&2; exit 1; fi
      RUBRIC="$2"; shift 2 ;;
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
if [[ ${#MISSING[@]} -gt 0 ]]; then
  echo "Error: missing required flags: ${MISSING[*]}" >&2
  echo "Run /autoresearch:start --help for the full contract." >&2
  exit 1
fi

# Evaluator contract: the loop needs at least one way to evaluate a change —
# a numeric scorer (--score-cmd), an objective gate (--check-cmd), and/or an LLM
# rubric (--rubric). Sequential rounds use the objective signal (score/gate); the
# rubric is applied by independent judges only when a plateau escalates to a
# tournament (a single agent self-judging a rubric would reward-hack). A numeric
# scorer also needs --direction. A rubric needs an objective anchor.
if [[ -z "$SCORE_CMD" ]] && [[ -z "$CHECK_CMD" ]] && [[ -z "$RUBRIC" ]]; then
  echo "Error: provide an evaluator — --score-cmd (numeric), --check-cmd (pass/fail gate), and/or --rubric (LLM judge, applied on tournament escalation)." >&2
  exit 1
fi
if [[ -n "$RUBRIC" ]] && [[ -z "$SCORE_CMD" ]] && [[ -z "$CHECK_CMD" ]]; then
  echo "Error: --rubric needs an objective anchor — add --score-cmd or --check-cmd. A judge-only loop reward-hacks." >&2
  exit 1
fi
if [[ -n "$SCORE_CMD" ]] && [[ -z "$DIRECTION" ]]; then
  echo "Error: --score-cmd requires --direction min|max." >&2
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
  echo "The loop edits the artifact and discards changes with 'git checkout --', which would overwrite uncommitted edits." >&2
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

# The commit the run starts from. Experiments fold into ONE temporary "WIP"
# commit on top of this; at the end the WIP is collapsed back to here so the
# net result is an uncommitted diff for the human to review and land via the
# dedicated /git:commit flow. No real/conventional commit happens inside the loop.
BASELINE_SHA=$(git rev-parse HEAD)

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

# Pluggable evaluator: a numeric scorer (--score-cmd) and/or an objective gate
# (--check-cmd). The gate is a hard filter (exit 0 = pass); the numeric score
# ranks among gate-passers. Build the EVALUATE block, the keep/discard DECISION,
# and the baseline caveat from whichever evaluator(s) were supplied. Crashes and
# gate failures log NA (never 0), so they can never pose as BEST_KEPT — that
# would otherwise wedge --direction min, where 0 looks like the best score.
HAS_SCORE=false; [[ -n "$SCORE_CMD" ]] && HAS_SCORE=true
HAS_GATE=false;  [[ -n "$CHECK_CMD" ]] && HAS_GATE=true
SCORE_CMD_SH=$(sh_single_quote_escape "$SCORE_CMD")
CHECK_CMD_SH=$(sh_single_quote_escape "$CHECK_CMD")

GATE_EVAL=""
if $HAS_GATE; then
  GATE_EVAL="   a. GATE (objective ground truth): run  timeout $TRIAL_TIMEOUT sh -c '$CHECK_CMD_SH'  — exit code 0 = PASS, any non-zero (or a timeout, 124) = FAIL. The gate command is FIXED: never edit it or the read-only paths to force a pass. A candidate that FAILS the gate is rejected: log status=gatefail, score=NA, discard with git checkout -- $EDIT, and skip the rest of this experiment."
fi
SCORE_EVAL=""
if $HAS_SCORE; then
  SCORE_EVAL="   b. SCORE$( $HAS_GATE && echo ' (only if the gate PASSED)' || : ): run  timeout $TRIAL_TIMEOUT sh -c '$SCORE_CMD_SH'  — the LAST stdout line MUST be a single number = SCORE. A timeout/missing/non-numeric last line is a crash: log status=crash, score=NA, discard. Fix simple crashes (typos, missing imports) and retry; give up after 3 attempts. The scorer is FIXED; never change how the score is measured."
fi
EVAL_BLOCK="$GATE_EVAL"
[[ -n "$EVAL_BLOCK" && -n "$SCORE_EVAL" ]] && EVAL_BLOCK="$EVAL_BLOCK
$SCORE_EVAL"
[[ -z "$EVAL_BLOCK" ]] && EVAL_BLOCK="$SCORE_EVAL"

if $HAS_SCORE; then
  _DIR_WORD=$( [[ "$DIRECTION" == "min" ]] && echo LOWER || echo HIGHER )
  DECISION_RULE="Keep the commit only if$( $HAS_GATE && echo ' the gate PASSED AND' || : ) SCORE is $_DIR_WORD (strictly better) than BEST_KEPT — the best score among results.tsv rows with status=keep (ignore crash, gatefail, and discard rows). Otherwise — gate failed, crash, worse, or tied — discard with git checkout -- $EDIT. crash/gatefail rows log score NA (never 0), so they can never become BEST_KEPT."
  BASELINE_RULE="Run the evaluator on the UNMODIFIED artifact and log the first row. If it produces a valid number$( $HAS_GATE && echo ' and the gate passes' || : ), status=keep and that number is BEST_KEPT, the bar to beat. If it crashes$( $HAS_GATE && echo ' or the gate fails for reasons outside '"$EDIT" || : ), log status=crash/gatefail with score NA, fix only non-read-only preconditions, and re-run. Never let NA or 0 stand in as BEST_KEPT — the first valid scored experiment becomes BEST_KEPT."
else
  DECISION_RULE="There is no numeric score — the objective is to make the GATE pass. Keep the commit if the gate PASSES (status=keep); discard it with git checkout -- $EDIT if it FAILS (status=gatefail). Once the gate passes AND the goal in ## Goal is genuinely met, you are done: output the completion promise if one is configured, and stop making changes that do not advance the stated goal."
  BASELINE_RULE="Run the gate on the UNMODIFIED artifact and log the first row (status=keep if it passes, gatefail if not, score column NA either way — a gate has no number). If it already passes and the goal is met, the run is already complete."
fi

# Hybrid strategy: rounds default to a cheap sequential change; when sequential
# stalls (a plateau / local optimum), escalate ONE round to a parallel tournament
# via the bundled gan engine. A tournament costs ~100k+ tokens, so it is reserved
# for when it is worth it. Only feasible for a single-file artifact (the engine
# passes full file contents between agents).
ESCALATE_AFTER=3
if [[ $(compgen -G "$EDIT" 2>/dev/null | grep -c .) -eq 1 ]]; then
  TOURNAMENT_BLOCK="## Plateau escalation (break out of a local optimum)

Watch results.tsv. If the last $ESCALATE_AFTER rows are ALL non-improving (status discard/crash/gatefail, no new keep), sequential search is stuck. For THIS round only, run ONE parallel tournament instead of a single change, then resume sequential next round:
- Invoke the Workflow tool with scriptPath \"$GAN_SCRIPT\" and args built from THIS run's contract: edit \"$EDIT\", the objective and goal above, the SAME evaluator shown in the frontmatter (score_cmd / check_cmd / direction / rubric — include the rubric if one is set, since the tournament has independent judges that can apply it), plus max_rounds 1, candidates 3, trial_timeout $TRIAL_TIMEOUT. (args may be a JSON object or string; the engine accepts both.)
- It returns best_content — the winning/synthesized artifact. Re-evaluate it against BEST_KEPT with the DECIDE rule: if it wins, write best_content to $EDIT and KEEP it (fold into the temporary WIP commit, same as a normal keep), log status tournament; otherwise git checkout -- $EDIT and log status discard.
- Then resume sequential rounds. Do not run a tournament every round — only to break a genuine plateau."
else
  TOURNAMENT_BLOCK="## Plateau escalation

Not available for this run: --edit matches multiple files and the tournament engine optimizes a single file. Stay sequential; when stuck, attack the objective from a different angle rather than nudging parameters."
fi

# Pre-escape frontmatter values (the hook never reads these, but keep the block
# well-formed and impossible to break out of).
EDIT_YAML=$(yaml_escape "$EDIT")
SCORE_CMD_YAML=$( [[ -n "$SCORE_CMD" ]] && yaml_escape "$SCORE_CMD" || echo null )
CHECK_CMD_YAML=$( [[ -n "$CHECK_CMD" ]] && yaml_escape "$CHECK_CMD" || echo null )
RUBRIC_YAML=$( [[ -n "$RUBRIC" ]] && yaml_escape "$RUBRIC" || echo null )
OBJECTIVE_YAML=$(yaml_escape "$OBJECTIVE")
READONLY_YAML=$(yaml_escape "$READONLY_CSV")
RUN_TAG_YAML=$(yaml_escape "$RUN_TAG")
SESSION_ID_YAML=$(yaml_escape "$SESSION_ID")

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
check_cmd: $CHECK_CMD_YAML
rubric: $RUBRIC_YAML
direction: ${DIRECTION:-null}
trial_timeout: $TRIAL_TIMEOUT
objective: $OBJECTIVE_YAML
started_at: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
started_at_epoch: $(date +%s)
baseline_sha: $BASELINE_SHA
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
- results.tsv is your durable append-only log — the ONE place the run is recorded. Keep it UNTRACKED: stage ONLY the artifact with "git add $EDIT" — NEVER "git add -A", "git add .", or "git add results.tsv" (staging it would fold the log into the scratch WIP commit and a discard could lose entries).
- Do NOT make real/conventional commits during the loop. Kept experiments fold into ONE temporary "autoresearch WIP" scratch commit; the human runs the real commit (/git:commit) only after reviewing — see "Commits are temporary" below.
- Do NOT ask for permission to continue between experiments. Keep iterating until the configured bound (max experiments or wall-clock budget) is reached — the stop hook enforces it automatically. You are the researcher. The human is asleep.

## Setup (first iteration only)

If results.tsv does not exist:
1. You are already on the experiment branch autoresearch/$RUN_TAG. Do NOT create or switch branches.
2. Read README.md (if present) and the editable artifact ($EDIT) to understand the codebase.
3. Create results.tsv with just the header row: printf 'commit\tscore\tstatus\tdescription\n' > results.tsv
4. Run the BASELINE. $BASELINE_RULE

## Experiment loop

LOOP until the configured bound is reached:

1. Check git state: current branch and recent commits (run: git log --oneline -5)
2. Make ONE concrete change to $EDIT aimed at the objective (edit the file; do NOT commit yet).
3. EVALUATE the candidate (hard time-limited; run each part in order):
$EVAL_BLOCK
4. DECIDE: $DECISION_RULE
5. APPLY the decision via the TEMPORARY scratch commit (you NEVER make a real commit in the loop — see below):
   - KEEP: git add $EDIT; then fold it into the single rolling scratch commit — if HEAD is still the baseline run: git commit -m "autoresearch WIP (temporary)"; otherwise run: git commit --amend --no-edit. The working tree now holds the new best.
   - DISCARD: git checkout -- $EDIT (reverts to the last kept best, or the baseline if nothing has been kept yet).
6. LOG to results.tsv (tab-separated, NOT comma-separated):
   - Format: <7-char-commit-or-dash>\t<score-or-NA>\t<status>\t<description>
   - status is one of: keep, discard, gatefail, crash, tournament. Use NA (never 0) in the score column for gatefail/crash, and for a gate-only run.

$TOURNAMENT_BLOCK

## Commits are temporary — the human lands the result

You are on a throwaway branch and you NEVER make a real or conventional commit during the loop. Kept experiments fold into ONE rolling scratch commit titled "autoresearch WIP (temporary)", so the next experiment can be discarded with a simple git checkout -- $EDIT. results.tsv is the durable record of every experiment.

When the run ends (a bound is hit, or you output the completion promise), do NOT land the result yourself and do NOT run a conventional commit. Leave the WIP commit in place and report: the baseline-to-best change, results.tsv, and that the human should review and then run the dedicated commit flow (/git:commit) to make the real commit. To turn the net optimization back into an uncommitted diff for that flow: git reset --soft $BASELINE_SHA.

## Rules

- Modify ONLY $EDIT. Never touch the read-only paths: $READONLY_DISPLAY.
- The evaluator (scorer and/or gate) is fixed; do NOT change how success is measured, and never edit it or the read-only paths to game it.
- If stuck, think harder: try a different angle on the objective, not just parameter nudges.
- To stop early when the objective is genuinely achieved, output: <promise>...</promise> (only if a completion promise was configured).
AUTORESEARCH_STATE_EOF

# Stop-hook block cap check. Claude Code force-ends the turn after a Stop hook
# blocks CLAUDE_CODE_STOP_HOOK_BLOCK_CAP times in a row (default 8) — and the
# docs do NOT define whether intervening work resets that counter, so a loop
# that wants more than the cap must not assume it does. This stop hook is itself
# the loop's termination authority (it enforces --max-experiments / --max-wall-
# clock and the completion promise), so the generic cap is redundant here and
# only risks ending an overnight run early. A hook cannot set the env var (it is
# read at session start), so detect the risk and tell the user to set it.
CAP="${CLAUDE_CODE_STOP_HOOK_BLOCK_CAP:-8}"
[[ "$CAP" =~ ^[0-9]+$ ]] || CAP=8
CAP_RISK=false
if [[ "$CAP" != "0" ]]; then
  # Wall-clock-only runs are unbounded in iterations; an experiment count above
  # the cap also intends more blocks than the cap allows.
  if [[ "$MAX_ITERATIONS" -eq 0 ]] || [[ "$MAX_ITERATIONS" -gt "$CAP" ]]; then
    CAP_RISK=true
  fi
fi

# Print activation message
cat << EOF
Autoresearch loop activated!

Run tag:      $RUN_TAG
Branch:       autoresearch/$RUN_TAG
Edit target:  $EDIT
Read-only:    $READONLY_DISPLAY
Scorer:       $(if $HAS_SCORE; then echo "$SCORE_CMD (direction: $DIRECTION)"; else echo "(none — gate-only)"; fi)
Gate:         $(if $HAS_GATE; then echo "$CHECK_CMD (must exit 0)"; else echo "(none)"; fi)
Per-trial timeout: ${TRIAL_TIMEOUT}s
Objective:    $OBJECTIVE
Max experiments: $(if [[ $MAX_ITERATIONS -gt 0 ]]; then echo $MAX_ITERATIONS; else echo "unlimited"; fi)
Wall-clock budget: $(if [[ $MAX_SECONDS -gt 0 ]]; then echo "${MAX_SECONDS}s"; else echo "none"; fi)
Completion promise: $(if [[ "$COMPLETION_PROMISE" != "null" ]]; then echo "$COMPLETION_PROMISE"; else echo "none"; fi)

The stop hook is now active. Every time you try to exit, the research
prompt will be fed back — the loop keeps experimenting until stopped.

Experiments fold into ONE temporary "autoresearch WIP" commit on this branch
(results.tsv is the log). The loop never makes a real commit — after the run,
review the result and run /git:commit to land it (git reset --soft $BASELINE_SHA
first to turn the WIP into an uncommitted diff).

Monitor progress:
  grep '^iteration:' .claude/autoresearch.local.md   # experiment count
  cat results.tsv                                     # experiment log

To stop: /autoresearch:cancel
EOF

if [[ "$CAP_RISK" == true ]]; then
  cat << CAP_EOF

================================ ACTION REQUIRED ================================
Claude Code force-stops a Stop hook after it blocks $CAP times in a row
(CLAUDE_CODE_STOP_HOOK_BLOCK_CAP, default 8). This loop re-blocks once per
experiment, so it WILL likely hit that ceiling before reaching its own bound.

Autoresearch enforces its own stopping bound (experiments / wall-clock /
completion promise), so disable the redundant cap. Add to .claude/settings.json:

  { "env": { "CLAUDE_CODE_STOP_HOOK_BLOCK_CAP": "0" } }

("0" disables the cap; or set a number comfortably above your experiment count.)
The env var is read at SESSION START, so set it and restart Claude Code BEFORE
relying on a long run — it does not take effect in the current session.
================================================================================
CAP_EOF
fi

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
