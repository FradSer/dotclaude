#!/bin/bash

# Autoresearch Setup Script
# Initializes the autonomous research loop state file for a project.
# The loop prompt embeds the full experiment instructions (equivalent to program.md).

set -euo pipefail

RUN_TAG=""
MAX_ITERATIONS=0
COMPLETION_PROMISE="null"

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      cat << 'HELP_EOF'
autoresearch — Autonomous ML research loop

USAGE:
  /autoresearch:start [TAG] [OPTIONS]

ARGUMENTS:
  TAG    Run tag for the experiment branch (e.g. mar16).
         Defaults to today's date (e.g. mar16).

OPTIONS:
  --max-experiments <n>          Stop after N experiments (default: unlimited)
  --completion-promise '<text>'  Phrase Claude outputs to signal research complete
  -h, --help                     Show this help message

DESCRIPTION:
  Starts an autonomous research loop in the current session.
  Claude modifies train.py, runs 5-minute training experiments, logs
  results to results.tsv, and iterates indefinitely — like a researcher
  working overnight.

  The stop hook intercepts every exit attempt and feeds the same
  research prompt back, so Claude keeps experimenting.

  To signal completion, Claude must output: <promise>YOUR_PHRASE</promise>

EXAMPLES:
  /autoresearch:start
  /autoresearch:start mar16 --max-experiments 50
  /autoresearch:start --completion-promise 'RESEARCH COMPLETE' --max-experiments 100

REQUIREMENTS:
  - A single NVIDIA GPU
  - uv installed (https://docs.astral.sh/uv/)
  - Data prepared: uv run prepare.py (one-time setup)
  - train.py and prepare.py present in the working directory

STOPPING:
  - Reaches --max-experiments limit
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
    --completion-promise)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --completion-promise requires a text argument" >&2
        exit 1
      fi
      COMPLETION_PROMISE="$2"
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

# Quote completion promise for YAML if needed
if [[ -n "$COMPLETION_PROMISE" ]] && [[ "$COMPLETION_PROMISE" != "null" ]]; then
  COMPLETION_PROMISE_YAML="\"$COMPLETION_PROMISE\""
else
  COMPLETION_PROMISE_YAML="null"
fi

# Create state file
mkdir -p .claude

cat > .claude/autoresearch.local.md << EOF
---
active: true
iteration: 1
session_id: ${CLAUDE_CODE_SESSION_ID:-}
max_iterations: $MAX_ITERATIONS
completion_promise: $COMPLETION_PROMISE_YAML
run_tag: $RUN_TAG
started_at: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
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
1. Verify the experiment branch exists (autoresearch/$RUN_TAG). If not, run: git checkout -b autoresearch/$RUN_TAG
2. Verify data exists: check that ~/.cache/autoresearch/ contains data shards and a tokenizer. If not, tell the human to run: uv run prepare.py
3. Create results.tsv with just the header row: printf 'commit\tval_bpb\tmemory_gb\tstatus\tdescription\n' > results.tsv
4. Read README.md, prepare.py, and train.py to understand the codebase.
5. Run the baseline experiment (do not modify train.py yet).

## Experiment loop

LOOP FOREVER (until manually stopped or max experiments reached):

1. Check git state: current branch and last commit (run: git log --oneline -5)
2. Choose an experimental idea — modify train.py with one concrete change (architecture, optimizer, hyperparameters, batch size, etc.)
3. Commit the change: git add train.py && git commit -m "experiment: <short description>"
4. Run the experiment: uv run train.py > run.log 2>&1
   - Each run takes exactly 5 minutes (fixed time budget)
   - If a run exceeds 10 minutes, kill it and treat as failure
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
- NEVER STOP or ask for permission to continue. Run indefinitely.
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
Completion promise: $(if [[ "$COMPLETION_PROMISE" != "null" ]]; then echo "$COMPLETION_PROMISE"; else echo "none (runs forever)"; fi)

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
