---
name: research
description: Runs a deep-research query on Google Gemini's deep-research managed agent and returns a cited report. This skill should be used when the user asks to "deep research with Gemini", "run Gemini deep research", "have Antigravity research X", or wants a thorough, multi-source web research report produced by a remote Gemini agent. Invoked via "/antigravity:research". Supports a higher-effort max mode via "--max".
argument-hint: "<research question> [--max]"
allowed-tools: ["Bash(uv:*)", "Monitor", "Read"]
user-invocable: true
---

# Antigravity Deep Research

Run `$ARGUMENTS` as a deep-research query on Gemini's deep-research managed agent,
wait for it to finish, and report the cited result. Two models are available:
`deep-research-preview-04-2026` (default) and `deep-research-max-preview-04-2026`
(max mode — slower, higher effort), selected with `--max`.

The script is at `${CLAUDE_PLUGIN_ROOT}/scripts/antigravity.py`. It is self-daemonizing:
`research` returns immediately with a `run_id`, a detached worker runs the research,
and a `status` file flips to `completed` / `failed` when done. Requires `GEMINI_API_KEY`
in the environment and `uv` on PATH. Deep research can take several minutes.

## Phase 1: Frame the query

**Goal**: Turn `$ARGUMENTS` into a clear research question.

**Actions**:
1. Use the full `$ARGUMENTS` text (minus a `--max` flag) as the research question.
   Pass `--max` through to the script when the user wants max mode (deeper, slower).
2. If it is empty or too vague to research (no subject, scope, or constraints),
   ask the user one or two clarifying questions, then proceed.

## Phase 2: Launch the run

**Goal**: Start the detached research worker.

**Actions**:
1. Run the script:
   ```
   uv run "${CLAUDE_PLUGIN_ROOT}/scripts/antigravity.py" research --query "<question>" [--max]
   ```
2. Capture `run_id`, `output_file`, and `wait_command` from stdout.
3. If stdout reports an error (for example a missing `GEMINI_API_KEY`), surface it and stop.

## Phase 3: Wait for completion

**Goal**: Block until the research finishes without busy-looping the model.

**Actions**:
1. Start a Monitor on the captured `wait_command`. It emits one line —
   `antigravity run <id>: completed` / `failed` / `timeout` — then exits:
   ```
   uv run "${CLAUDE_PLUGIN_ROOT}/scripts/antigravity.py" wait --run <run_id>
   ```
   Deep research is slow: set the Monitor `timeout_ms` to 1800000 (30 min) and pass
   `--timeout 1800` to the wait command. Use a clear description like
   "antigravity research <run_id>".
2. When the Monitor event arrives, read the last word of its line:
   - `completed` or `failed` → proceed to Phase 4.
   - `timeout` → the research is still running (the worker keeps polling up to ~2h).
     Start the Monitor on the same `wait_command` again to keep waiting. After a second
     consecutive timeout, tell the user it is still running and give them
     `... status --run <run_id> --full` to fetch it later, then stop.
   Never present a `timeout` / still-running state as the report.

## Phase 4: Report the result

**Goal**: Present the research report.

**Actions**:
1. Fetch the full result:
   ```
   uv run "${CLAUDE_PLUGIN_ROOT}/scripts/antigravity.py" status --run <run_id> --full
   ```
   Or read the rendered `output_file` directly.
2. Present the report text to the user, preserving any citations and sources.
3. If the status is `failed`, report the recorded error and likely cause.

## Notes

- This uses Gemini's managed deep-research agent; it manages its own search and
  browsing. No sandbox tools or network flags apply here.
- See `../delegate/references/usage.md` for the shared API surface and limits.
