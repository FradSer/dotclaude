#!/bin/bash

# Superpower Loop Setup Script
# Creates JSON state file for in-session Superpower loop

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
# shellcheck source=../lib/utils.sh
source "${SCRIPT_DIR}/../lib/utils.sh"

# Runtime-deps check — unlike the hooks (which soft-bail to keep Stop
# unblocked), this is a user-invoked CLI that constructs JSON via jq and
# merges via perl. Without those, we cannot proceed; hard-fail with a
# clear message rather than producing an empty/broken state file.
if [[ "${_SUPERPOWERS_DEPS_MISSING:-}" == "1" ]]; then
  echo "Error: superpowers requires 'jq' and 'perl' in PATH to set up a loop." >&2
  echo "       Install jq (https://stedolan.github.io/jq/) and ensure perl is available." >&2
  exit 1
fi

# Parse arguments
PROMPT_PARTS=()
PROMPT_FILE=""
MAX_ITERATIONS=0
COMPLETION_PROMISE="null"
STATE_FILE_OVERRIDE=""
FORCE_OVERRIDE=0

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
  --force                        Overwrite an existing active loop (resets iteration to 1).
                                 Without this, refusing to clobber active=true is the default —
                                 use only when you're certain the previous loop is dead.
  -h, --help                     Show this help message

DESCRIPTION:
  Starts a Superpower Loop in your CURRENT session. The stop hook prevents
  exit and feeds your output back as input until completion or iteration limit.

  State files are stored in ~/.claude/projects/<project-key>/ as JSON.

  To signal completion, you must output <promise>YOUR_PHRASE</promise> as the final standalone line.

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
    --force)
      # Reentry guard override — only required when an active loop already
      # exists at the resolved state file path.
      FORCE_OVERRIDE=1
      shift
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
# Prefer existing state file (created by task-start.sh with session_id from hook input)
# to avoid mismatch with CLAUDE_CODE_SESSION_ID env var
SESSION_ID="${CLAUDE_CODE_SESSION_ID:-default}"
if [[ -n "$STATE_FILE_OVERRIDE" ]]; then
  STATE_FILE="$STATE_FILE_OVERRIDE"
  mkdir -p "$(dirname "$STATE_FILE")"
else
  EXISTING_FILE=$(find_state_file "$SESSION_ID")
  if [[ -n "$EXISTING_FILE" ]]; then
    STATE_FILE="$EXISTING_FILE"
  else
    STATE_DIR="$(state_dir)"
    mkdir -p "$STATE_DIR"
    STATE_FILE="${STATE_DIR}/${SESSION_ID}.superpowers.json"
  fi
fi

NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Build completion_promise as proper JSON value
if [[ "$COMPLETION_PROMISE" == "null" ]]; then
  PROMISE_JSON="null"
else
  PROMISE_JSON=$(jq -n --arg p "$COMPLETION_PROMISE" '$p')
fi

# Reentry guard — refuse to clobber an active loop unless --force is set.
# Without this, a second invocation silently resets iteration/started_at
# and effectively doubles max_iterations.
if [[ -f "$STATE_FILE" ]] && [[ "$FORCE_OVERRIDE" != "1" ]]; then
  if jq -e '.active == true' "$STATE_FILE" >/dev/null 2>&1; then
    EXISTING_ITER=$(jq -r '.iteration // "?"' "$STATE_FILE" 2>/dev/null)
    EXISTING_MAX=$(jq -r '.max_iterations // "?"' "$STATE_FILE" 2>/dev/null)
    EXISTING_START=$(jq -r '.started_at // "?"' "$STATE_FILE" 2>/dev/null)
    echo "Error: an active Superpower Loop already exists at $STATE_FILE." >&2
    echo "       Iteration ${EXISTING_ITER}/${EXISTING_MAX}, started ${EXISTING_START}." >&2
    echo "       Recovery options:" >&2
    echo "         - If the previous loop is genuinely active, let it finish." >&2
    echo "         - If it crashed/stalled, re-run this command with --force (resets iteration to 1)." >&2
    echo "         - Or delete the stale state file: rm \"$STATE_FILE\"" >&2
    exit 1
  fi
fi

# Create or merge JSON state file via the same locked code path for both
# branches: pre-create an empty {} if missing, then state_update merges
# fields preserving prior state (task, modified_files, etc.) when present.
# This closes the previous race where the bare jq>FILE fallback could
# clobber a stub track-changes.sh had just created.
if [[ ! -f "$STATE_FILE" ]]; then
  printf '{}\n' > "$STATE_FILE"
fi
state_update "$STATE_FILE" \
  --arg session_id "$SESSION_ID" \
  --arg prompt "$PROMPT" \
  --argjson iteration 1 \
  --argjson max_iterations "$MAX_ITERATIONS" \
  --argjson completion_promise "$PROMISE_JSON" \
  --arg started_at "$NOW" \
  --arg updated_at "$NOW" \
  '. + {
    session_id: $session_id,
    active: true,
    iteration: $iteration,
    max_iterations: $max_iterations,
    completion_promise: $completion_promise,
    prompt: $prompt,
    started_at: $started_at,
    updated_at: $updated_at
  }'

# Output setup message
cat <<EOF
Superpower loop activated in this session!

State file: $STATE_FILE
Iteration: 1
Max iterations: $(if [[ $MAX_ITERATIONS -gt 0 ]]; then echo $MAX_ITERATIONS; else echo "unlimited"; fi)
Completion promise: $(if [[ "$COMPLETION_PROMISE" != "null" ]]; then echo "${COMPLETION_PROMISE} (emit promptly once criteria are met)"; else echo "none (runs forever)"; fi)

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
#
# Wording principle: encourage *prompt emission* the moment criteria are
# met. Earlier versions of this banner ("Do NOT lie even if you think you
# should exit", "Trust the process") biased the assistant toward caution —
# empirical effect was 5+ wasted iterations after the work was genuinely
# done because the assistant kept running extra review/polish passes. The
# loop's safety nets (hash-identity stall + max_iterations) catch the
# opposite failure, so the banner now leans the other way: emit promptly,
# do not over-polish.
if [[ "$COMPLETION_PROMISE" != "null" ]]; then
  echo ""
  echo "==============================================================="
  echo "Superpower Loop Completion Promise"
  echo "==============================================================="
  echo ""
  echo "To exit this loop, output this EXACT text as the final standalone line:"
  echo "  <promise>$COMPLETION_PROMISE</promise>"
  echo ""
  echo "When to emit:"
  echo "  - The moment your skill's completion criteria are met"
  echo "    (artifacts written + verified, evaluator PASS, commit made)."
  echo "  - Immediately after the final phase's exit action succeeds."
  echo "  - NO extra review / polish / verification pass after that point."
  echo ""
  echo "Format requirements:"
  echo "  - Use <promise> XML tags EXACTLY as shown above"
  echo "  - Promise tag must be the LAST non-whitespace line — nothing after"
  echo "  - Only emit when the statement is genuinely TRUE for your skill"
  echo ""
  echo "Cost of NOT emitting when ready:"
  echo "  Each extra iteration costs user attention. The loop will fire"
  echo "  another 'Continue X' injection every turn until you emit. If"
  echo "  your work is done, emit now — the loop is not asking for more."
  echo "==============================================================="
fi
