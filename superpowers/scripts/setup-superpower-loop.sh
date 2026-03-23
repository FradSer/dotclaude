#!/bin/bash

# Superpower Loop Setup Script
# Creates JSON state file for in-session Superpower loop

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
# shellcheck source=../lib/utils.sh
source "${SCRIPT_DIR}/../lib/utils.sh"

# Parse arguments
PROMPT_PARTS=()
PROMPT_FILE=""
MAX_ITERATIONS=0
COMPLETION_PROMISE="null"
STATE_FILE_OVERRIDE=""

# Parse options and positional arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      cat << 'HELP_EOF'
Superpower Loop - Interactive self-referential development loop

USAGE:
  /superpower-loop [PROMPT...] [OPTIONS]

ARGUMENTS:
  PROMPT...    Initial prompt to start the loop (can be multiple words without quotes)

OPTIONS:
  --prompt-file <path>           Read prompt from file (avoids shell escaping issues)
  --max-iterations <n>           Maximum iterations before auto-stop (default: unlimited)
  --completion-promise '<text>'  Promise phrase (USE QUOTES for multi-word)
  --state-file <path>            Custom state file path (overrides default)
  -h, --help                     Show this help message

DESCRIPTION:
  Starts a Superpower Loop in your CURRENT session. The stop hook prevents
  exit and feeds your output back as input until completion or iteration limit.

  State files are stored in ~/.claude/projects/<project-key>/ as JSON.

  To signal completion, you must output: <promise>YOUR_PHRASE</promise>

  Use this for:
  - Interactive iteration where you want to see progress
  - Tasks requiring self-correction and refinement
  - Learning how the loop works

EXAMPLES:
  /superpower-loop Build a todo API --completion-promise 'DONE' --max-iterations 20
  /superpower-loop --max-iterations 10 Fix the auth bug
  /superpower-loop Refactor cache layer  (runs forever)
  /superpower-loop --completion-promise 'TASK COMPLETE' Create a REST API
  /superpower-loop --prompt-file task.md --completion-promise 'DONE' --max-iterations 20

STOPPING:
  Only by reaching --max-iterations or detecting --completion-promise
  No manual stop - loop runs infinitely by default!

MONITORING:
  # View current state:
  cat ~/.claude/projects/<project-key>/<session_id>.superpowers.json | jq .
HELP_EOF
      exit 0
      ;;
    --max-iterations)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --max-iterations requires a number argument" >&2
        echo "" >&2
        echo "   Valid examples:" >&2
        echo "     --max-iterations 10" >&2
        echo "     --max-iterations 50" >&2
        echo "     --max-iterations 0  (unlimited)" >&2
        exit 1
      fi
      if ! [[ "$2" =~ ^[0-9]+$ ]]; then
        echo "Error: --max-iterations must be a positive integer or 0, got: $2" >&2
        echo "" >&2
        echo "   Valid examples:" >&2
        echo "     --max-iterations 10" >&2
        echo "     --max-iterations 50" >&2
        echo "     --max-iterations 0  (unlimited)" >&2
        exit 1
      fi
      MAX_ITERATIONS="$2"
      shift 2
      ;;
    --completion-promise)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --completion-promise requires a text argument" >&2
        echo "" >&2
        echo "   Valid examples:" >&2
        echo "     --completion-promise 'DONE'" >&2
        echo "     --completion-promise 'TASK COMPLETE'" >&2
        exit 1
      fi
      COMPLETION_PROMISE="$2"
      shift 2
      ;;
    --state-file)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --state-file requires a path argument" >&2
        exit 1
      fi
      STATE_FILE_OVERRIDE="$2"
      shift 2
      ;;
    --prompt-file)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --prompt-file requires a path argument" >&2
        exit 1
      fi
      if [[ ! -f "$2" ]]; then
        echo "Error: --prompt-file path does not exist: $2" >&2
        exit 1
      fi
      PROMPT_FILE="$2"
      shift 2
      ;;
    *)
      PROMPT_PARTS+=("$1")
      shift
      ;;
  esac
done

# Join all prompt parts with spaces or read from file
if [[ -n "$PROMPT_FILE" ]]; then
  PROMPT=$(cat "$PROMPT_FILE")
else
  PROMPT="${PROMPT_PARTS[*]:-}"
fi

# Validate prompt is non-empty
if [[ -z "$PROMPT" ]]; then
  echo "Error: No prompt provided" >&2
  echo "" >&2
  echo "   Examples:" >&2
  echo "     /superpower-loop Build a REST API for todos" >&2
  echo "     /superpower-loop Fix the auth bug --max-iterations 20" >&2
  echo "     /superpower-loop --completion-promise 'DONE' Refactor code" >&2
  echo "     /superpower-loop --prompt-file task.md --max-iterations 20" >&2
  echo "" >&2
  echo "   For all options: /superpower-loop --help" >&2
  exit 1
fi

# Resolve state file path
SESSION_ID="${CLAUDE_CODE_SESSION_ID:-default}"
if [[ -n "$STATE_FILE_OVERRIDE" ]]; then
  STATE_FILE="$STATE_FILE_OVERRIDE"
  mkdir -p "$(dirname "$STATE_FILE")"
else
  STATE_DIR="$(state_dir)"
  mkdir -p "$STATE_DIR"
  STATE_FILE="${STATE_DIR}/${SESSION_ID}.superpowers.json"
fi

NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Build completion_promise as proper JSON value
if [[ "$COMPLETION_PROMISE" == "null" ]]; then
  PROMISE_JSON="null"
else
  PROMISE_JSON=$(jq -n --arg p "$COMPLETION_PROMISE" '$p')
fi

# Create JSON state file
jq -n \
  --arg session_id "$SESSION_ID" \
  --arg prompt "$PROMPT" \
  --argjson iteration 1 \
  --argjson max_iterations "$MAX_ITERATIONS" \
  --argjson completion_promise "$PROMISE_JSON" \
  --arg started_at "$NOW" \
  --arg updated_at "$NOW" \
  '{
    session_id: $session_id,
    active: true,
    iteration: $iteration,
    max_iterations: $max_iterations,
    completion_promise: $completion_promise,
    prompt: $prompt,
    started_at: $started_at,
    updated_at: $updated_at
  }' > "$STATE_FILE"

# Output setup message
cat <<EOF
Superpower loop activated in this session!

State file: $STATE_FILE
Iteration: 1
Max iterations: $(if [[ $MAX_ITERATIONS -gt 0 ]]; then echo $MAX_ITERATIONS; else echo "unlimited"; fi)
Completion promise: $(if [[ "$COMPLETION_PROMISE" != "null" ]]; then echo "${COMPLETION_PROMISE} (ONLY output when TRUE - do not lie!)"; else echo "none (runs forever)"; fi)

The stop hook is now active. When you try to exit, the SAME PROMPT will be
fed back to you. You'll see your previous work in files, creating a
self-referential loop where you iteratively improve on the same task.

To monitor: jq . $STATE_FILE
EOF

# Output the initial prompt if provided
if [[ -n "$PROMPT" ]]; then
  echo ""
  echo "$PROMPT"
fi

# Display completion promise requirements if set
if [[ "$COMPLETION_PROMISE" != "null" ]]; then
  echo ""
  echo "==============================================================="
  echo "CRITICAL - Superpower Loop Completion Promise"
  echo "==============================================================="
  echo ""
  echo "To complete this loop, output this EXACT text:"
  echo "  <promise>$COMPLETION_PROMISE</promise>"
  echo ""
  echo "STRICT REQUIREMENTS (DO NOT VIOLATE):"
  echo "  - Use <promise> XML tags EXACTLY as shown above"
  echo "  - The statement MUST be completely and unequivocally TRUE"
  echo "  - Do NOT output false statements to exit the loop"
  echo "  - Do NOT lie even if you think you should exit"
  echo ""
  echo "IMPORTANT - Do not circumvent the loop:"
  echo "  Even if you believe you're stuck, the task is impossible,"
  echo "  or you've been running too long - you MUST NOT output a"
  echo "  false promise statement. The loop is designed to continue"
  echo "  until the promise is GENUINELY TRUE. Trust the process."
  echo ""
  echo "  If the loop should stop, the promise statement will become"
  echo "  true naturally. Do not force it by lying."
  echo "==============================================================="
fi
