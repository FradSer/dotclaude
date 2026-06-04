---
name: delegate
description: Delegates a self-contained task to a Google Gemini Managed Agent (Antigravity) running in a remote sandbox with code execution, web search, and URL reading. This skill should be used when the user asks to "delegate to Gemini", "offload to Antigravity", "run this in a remote sandbox", or wants a task executed in an isolated Linux sandbox with Google Search and code execution, then the result read back. Invoked via "/antigravity:delegate".
argument-hint: "<task prompt> [--tools code_execution,google_search,url_context] [--network default|none] [--repo URL]"
allowed-tools: ["Bash(uv:*)", "Monitor", "Read"]
user-invocable: true
---

# Antigravity Delegate

Delegate `$ARGUMENTS` to the `antigravity-preview-05-2026` managed agent in a remote
Gemini sandbox, wait for it to finish, and report the result.

The script is at `${CLAUDE_PLUGIN_ROOT}/scripts/antigravity.py`. It is self-daemonizing:
`delegate` returns immediately with a `run_id`, a detached worker performs the
interaction, and a `status` file flips to `completed` / `failed` when done.
Requires `GEMINI_API_KEY` in the environment and `uv` on PATH.

## Phase 1: Parse arguments

**Goal**: Separate the task prompt from flags.

**Actions**:
1. Treat the leading free text of `$ARGUMENTS` (before any `--flag`) as the task prompt.
2. Recognize optional flags and pass them through unchanged:
   - `--tools` — comma list of `code_execution`, `google_search`, `url_context` (default: all three)
   - `--network` — `default` (open outbound, the default) or `none` (sandbox code cannot reach the internet; Google Search and URL reading still work)
   - `--repo URL` — mount a GitHub repository at `/workspace/repo`
3. If the prompt is empty, ask the user what to delegate and stop.

## Phase 2: Launch the run

**Goal**: Start the detached worker and capture its handles.

**Actions**:
1. Run the script with the parsed prompt and flags:
   ```
   uv run "${CLAUDE_PLUGIN_ROOT}/scripts/antigravity.py" delegate --prompt "<task>" [flags]
   ```
2. Capture `run_id`, `output_file`, and `wait_command` from stdout.
3. If stdout reports an error (for example a missing `GEMINI_API_KEY`), surface it and stop.

## Phase 3: Wait for completion

**Goal**: Block until the run reaches a terminal state without busy-looping the model.

**Actions**:
1. Start a Monitor on the captured `wait_command`. It emits exactly one line —
   `antigravity run <id>: completed` or `... failed` (or `... timeout`) — then exits:
   ```
   uv run "${CLAUDE_PLUGIN_ROOT}/scripts/antigravity.py" wait --run <run_id>
   ```
   Set the Monitor `timeout_ms` to 900000 (15 min) and a clear description such as
   "antigravity delegate <run_id>".
2. When the Monitor event arrives, proceed to Phase 4. Do not poll manually in a loop.

## Phase 4: Report the result

**Goal**: Present the agent's output and what it did.

**Actions**:
1. Fetch the full result:
   ```
   uv run "${CLAUDE_PLUGIN_ROOT}/scripts/antigravity.py" status --run <run_id> --full
   ```
   Or read the rendered `output_file` directly.
2. Summarize for the user: the agent's output text, the tool trace (code/search/url steps),
   the `interaction_id` and `environment_id` (useful for follow-up), and token usage.
3. If the status is `failed`, report the recorded error and likely cause
   (missing API key, unsupported tool, network policy).

## Notes

- Preview limits: only `code_execution`, `google_search`, `url_context` are supported.
  Function calling, MCP servers, and structured output are not available.
- The sandbox persists for ~7 days; reuse its `environment_id` for follow-up turns.
- See `references/usage.md` for the API surface, environment options, and examples.
