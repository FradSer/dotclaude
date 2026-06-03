#!/bin/bash

# Autoresearch Setup Script
# Initializes the autonomous research loop state file for a project.
# The loop prompt embeds the full experiment instructions (equivalent to program.md).

set -euo pipefail

RUN_TAG=""
MAX_ITERATIONS=0
MAX_SECONDS=0
COMPLETION_PROMISE="null"
SESSION_ID=""

# Convert a duration like "8h", "480m", "30s", or plain "8" (hours) to seconds.
parse_duration() {
  local v="$1"
  if [[ "$v" =~ ^([0-9]+)([hms]?)$ ]]; then
    local num="${BASH_REMATCH[1]}" unit="${BASH_REMATCH[2]}"
    case "$unit" in
      h|"") echo $((num * 3600)) ;;
      m)    echo $((num * 60)) ;;
      s)    echo "$num" ;;
    esac
    return 0
  fi
  return 1
}

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      cat << 'HELP_EOF'
autoresearch — Autonomous ML research loop

USAGE:
  /autoresearch:start [TAG] [OPTIONS]

ARGUMENTS:
  TAG    Run tag for the experiment branch.
         Defaults to today's date as <mon><dd> (e.g. mar16 for Mar 16).

OPTIONS:
  --max-experiments <n>          Stop after N experiments
  --max-wall-clock <duration>    Stop after a wall-clock budget (e.g. 8h, 480m, 30s)
  --completion-promise '<text>'  Phrase Claude outputs to signal research complete
  -h, --help                     Show this help message

  At least one of --max-experiments or --max-wall-clock is REQUIRED —
  the loop refuses to start unbounded.

DESCRIPTION:
  Starts an autonomous research loop in the current session.
  Claude modifies train.py, runs 5-minute training experiments, logs
  results to results.tsv, and iterates indefinitely — like a researcher
  working overnight.

  The stop hook intercepts every exit attempt and feeds the same
  research prompt back, so Claude keeps experimenting.

  To signal completion, Claude must output: <promise>YOUR_PHRASE</promise>

EXAMPLES:
  /autoresearch:start --max-wall-clock 8h
  /autoresearch:start mar16 --max-experiments 50
  /autoresearch:start --completion-promise 'RESEARCH COMPLETE' --max-experiments 100

REQUIREMENTS:
  - A single NVIDIA GPU
  - uv installed (https://docs.astral.sh/uv/)
  - Data prepared: uv run prepare.py (one-time setup)
  - train.py and prepare.py present in the working directory

STOPPING:
  - Reaches --max-experiments limit
  - Exceeds --max-wall-clock budget
  - Claude outputs <promise>PHRASE</promise>
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
      if [[ -z "${2:-}" ]] || ! MAX_SECONDS=$(parse_duration "$2"); then
        echo "Error: --max-wall-clock requires a duration like 8h, 480m, or 30s (got: '${2:-}')" >&2
        exit 1
      fi
      shift 2
      ;;
    --completion-promise)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --completion-promise requires a text argument" >&2
        exit 1
      fi
      COMPLETION_PROMISE="$2"
      shift 2
      ;;
    --session-id)
      SESSION_ID="${2:-}"
      shift 2
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

# Default run tag: current date (e.g. mar16)
if [[ -z "$RUN_TAG" ]]; then
  RUN_TAG=$(date +%b%d | tr '[:upper:]' '[:lower:]')
fi

# Require at least one stopping bound — never start an unbounded overnight loop.
if [[ "$MAX_ITERATIONS" -eq 0 ]] && [[ "$MAX_SECONDS" -eq 0 ]]; then
  echo "Error: an autoresearch loop must have a bound." >&2
  echo "Provide --max-experiments <n> and/or --max-wall-clock <duration> (e.g. 8h)." >&2
  echo "Run /autoresearch:start --help for details." >&2
  exit 1
fi

# Validate prerequisites
if [[ ! -f "train.py" ]]; then
  echo "Error: train.py not found in current directory." >&2
  echo "Run this command from an autoresearch project directory." >&2
  exit 1
fi

if [[ ! -f "prepare.py" ]]; then
  echo "Error: prepare.py not found in current directory." >&2
  exit 1
fi

# Ensure the loop runs on a dedicated branch, never on a protected branch and
# never on a dirty tree — the loop auto-discards experiments with `git reset
# --hard`, which would otherwise destroy unrelated work. Done here (not in the
# injected prompt) so isolation is deterministic, not left to the agent.
if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "Error: not inside a git repository." >&2
  exit 1
fi

TARGET_BRANCH="autoresearch/$RUN_TAG"
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

if [[ "$CURRENT_BRANCH" != "$TARGET_BRANCH" ]]; then
  if [[ -n "$(git status --porcelain)" ]]; then
    echo "Error: working tree has uncommitted changes." >&2
    echo "Autoresearch auto-discards experiments with 'git reset --hard', which would destroy them." >&2
    echo "Commit or stash your changes, then re-run /autoresearch:start." >&2
    exit 1
  fi
  if git show-ref --verify --quiet "refs/heads/$TARGET_BRANCH"; then
    git checkout "$TARGET_BRANCH"
  else
    git checkout -b "$TARGET_BRANCH"
  fi
  echo "Switched to experiment branch: $TARGET_BRANCH"
fi

# Quote completion promise for YAML if needed
if [[ -n "$COMPLETION_PROMISE" ]] && [[ "$COMPLETION_PROMISE" != "null" ]]; then
  COMPLETION_PROMISE_YAML="\"$COMPLETION_PROMISE\""
else
  COMPLETION_PROMISE_YAML="null"
fi

# Session isolation: the stop hook only continues the loop for the session
# whose id matches this one. If the id couldn't be resolved (empty, or the
# ${CLAUDE_SESSION_ID} token wasn't substituted), warn loudly rather than
# silently recording an empty id — an empty id disables isolation, letting any
# session in this directory get pulled into the loop.
if [[ -z "$SESSION_ID" ]] || [[ "$SESSION_ID" == *'${'* ]]; then
  echo "WARNING: could not resolve this session's id — session isolation is DISABLED." >&2
  echo "         Any Claude session run in this directory may be drawn into the loop." >&2
  echo "         Use /autoresearch:cancel to stop, and avoid other sessions here meanwhile." >&2
  SESSION_ID=""
fi

# Create state file
mkdir -p .claude

cat > .claude/autoresearch.local.md << EOF
---
active: true
iteration: 1
session_id: $SESSION_ID
max_iterations: $MAX_ITERATIONS
max_seconds: $MAX_SECONDS
completion_promise: $COMPLETION_PROMISE_YAML
run_tag: $RUN_TAG
started_at: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
started_at_epoch: $(date +%s)
---
You are an autonomous ML researcher running experiment loop for run tag: $RUN_TAG.

## Context

Read these files for full context before experimenting:
- README.md — repository overview
- prepare.py — fixed constants, data prep, tokenizer, dataloader, evaluation. Do NOT modify.
- train.py — the ONLY file you modify. Model architecture, optimizer, training loop.

The experiment branch is: autoresearch/$RUN_TAG

## Setup (first iteration only)

If results.tsv does not exist:
1. You are already on the experiment branch autoresearch/$RUN_TAG (the setup script switched to it). Do NOT create or switch branches.
2. Verify data exists: check that ~/.cache/autoresearch/ contains data shards and a tokenizer. If not, tell the human to run: uv run prepare.py
3. Create results.tsv with just the header row: printf 'commit\tval_bpb\tmemory_gb\tstatus\tdescription\n' > results.tsv
4. Read README.md, prepare.py, and train.py to understand the codebase.
5. Run the baseline experiment (do not modify train.py yet).

## Experiment loop

LOOP FOREVER (until manually stopped or max experiments reached):

1. Check git state: current branch and last commit (run: git log --oneline -5)
2. Choose an experimental idea — modify train.py with one concrete change (architecture, optimizer, hyperparameters, batch size, etc.)
3. Commit the change: git add train.py && git commit -m "experiment: <short description>"
4. Run the experiment: timeout 600 uv run train.py > run.log 2>&1
   - Each run takes ~5 minutes (fixed time budget); the timeout hard-kills any run that exceeds 10 minutes
   - A timeout (exit code 124) counts as a crash: log status crash and move on
5. Read results: grep "^val_bpb:\|^peak_vram_mb:" run.log
   - If grep output is empty: the run crashed. Run: tail -n 50 run.log to diagnose.
   - Fix simple crashes (typos, missing imports) and re-run. Give up after 3 failed attempts.
6. Log to results.tsv (tab-separated, NOT comma-separated):
   - Format: <7-char-commit>\t<val_bpb>\t<memory_gb>\t<status>\t<description>
   - status: keep, discard, or crash
   - memory_gb: peak_vram_mb / 1024, rounded to 1 decimal
   - Use 0.000000 and 0.0 for crashes
7. Decision:
   - If val_bpb improved (lower): keep the commit — advance the branch
   - If val_bpb equal or worse: git reset --hard HEAD~1

## Rules

- Modify ONLY train.py. Never touch prepare.py.
- Do NOT install new packages or add dependencies.
- Do NOT modify the evaluate_bpb function.
- Simpler is better: a small improvement from simple code beats a large improvement from complex code.
- Do NOT ask for permission to continue between experiments. Keep iterating until the configured bound (max experiments or wall-clock budget) is reached — the stop hook enforces it automatically.
- If stuck, think harder: try architectural changes, different optimizers, regularization, etc.

## Output format reference

A successful run prints:
---
val_bpb:          0.997900
training_seconds: 300.1
total_seconds:    325.9
peak_vram_mb:     45060.2
mfu_percent:      39.80
total_tokens_M:   499.6
num_steps:        953
num_params_M:     50.3
depth:            8
EOF

# Print activation message
cat << EOF
Autoresearch loop activated!

Run tag:      $RUN_TAG
Branch:       autoresearch/$RUN_TAG
Max experiments: $(if [[ $MAX_ITERATIONS -gt 0 ]]; then echo $MAX_ITERATIONS; else echo "unlimited"; fi)
Wall-clock budget: $(if [[ $MAX_SECONDS -gt 0 ]]; then echo "${MAX_SECONDS}s"; else echo "none"; fi)
Completion promise: $(if [[ "$COMPLETION_PROMISE" != "null" ]]; then echo "$COMPLETION_PROMISE"; else echo "none"; fi)

The stop hook is now active. Every time you try to exit, the research
prompt will be fed back — Claude keeps experimenting until stopped.

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
echo "Read program context from README.md, prepare.py, and train.py, then begin the experiment loop."
