---
name: acpx
description: Use acpx as a headless ACP CLI for agent-to-agent communication. Use when running coding agents through acpx, managing persistent ACP sessions, queueing prompts, overriding the Claude system prompt, consuming structured agent output from scripts, or composing multi-agent workflows with defineFlow/decision/decisionEdge.
---

# acpx

## When to use this skill

Use this skill when you need to run coding agents through `acpx`, manage persistent ACP sessions, queue prompts, override the Claude system prompt, prune stale sessions, consume structured agent output from scripts, or compose multi-agent workflows declaratively with `acpx/flows`.

## What acpx is

`acpx` is a headless, scriptable CLI client for the Agent Client Protocol (ACP). It is built for agent-to-agent communication over the command line and avoids PTY scraping.

Core capabilities:

- Persistent multi-turn sessions per repo/cwd
- One-shot execution mode (`exec`)
- Named parallel sessions (`-s/--session`)
- Idempotent session creation (`sessions ensure`)
- Session retention controls (`sessions prune` with age filters and history cleanup)
- Portable session export/import for moving records and history across machines
- Queue-aware prompt submission with optional fire-and-forget (`--no-wait`)
- Cooperative cancel command (`cancel`) for in-flight turns
- Graceful cancellation via ACP `session/cancel` on interrupt
- Session control methods (`set-mode`, `set <key> <value>`)
- Agent reconnect/resume after dead subprocess detection
- Prompt input via stdin or `--file`
- Config files with global+project merge and `config show|init`
- Session metadata/history inspection (`sessions show`, `sessions history`)
- Local agent process checks via `status`
- Stable ACP client methods for filesystem and terminal requests
- Stable ACP `authenticate` handshake via env/config credentials
- Structured streaming output (`text`, `json`, `quiet`) with optional `--suppress-reads`
- Built-in agent registry plus raw `--agent` escape hatch
- Claude system prompt override via `--system-prompt` / `--append-system-prompt`
- Optional terminal capability disable via `--no-terminal` for review-only flows
- Tool whitelist (`--allowed-tools`), turn cap (`--max-turns`), retry on transient failures (`--prompt-retries`)
- Multi-agent flows via `acpx flow run` and the `acpx/flows` authoring API (`defineFlow`, `decision`, `decisionEdge`, `acp`, `action`, `compute`, `checkpoint`)

## Install

```bash
npm i -g acpx
```

For normal session reuse, prefer a global install over `npx`.

## Command model

`prompt` is the default verb.

```bash
acpx [global_options] [prompt_text...]
acpx [global_options] prompt [prompt_options] [prompt_text...]
acpx [global_options] exec [prompt_options] [prompt_text...]
acpx [global_options] cancel [-s <name>]
acpx [global_options] set-mode <mode> [-s <name>]
acpx [global_options] set <key> <value> [-s <name>]
acpx [global_options] status [-s <name>]
acpx [global_options] sessions [list | new [--name <name>] | ensure [--name <name>] | close [name] | show [name] | history [name] [--limit <count>] | export [name] --output <path> | import <archive> [--name <name>] [--cwd <dir>] | prune [--dry-run] [--before <date> | --older-than <days>] [--include-history]]
acpx [global_options] config [show | init]
acpx [global_options] flow run <file> [--input-json '<json>' | --input-file <path>] [--default-agent <name>]
```

If prompt text is omitted and stdin is piped, `acpx` reads prompt text from stdin.

## Built-in agent registry

Friendly agent names resolve to commands:

- `pi` -> `npx pi-acp`
- `openclaw` -> `openclaw acp`
- `codex` -> `npx -y @agentclientprotocol/codex-acp`
- `claude` -> `npx -y @agentclientprotocol/claude-agent-acp`
- `gemini` -> `gemini --acp`
- `cursor` -> `cursor-agent acp`
- `copilot` -> `copilot --acp --stdio`
- `droid` -> `droid exec --output-format acp`
- `fast-agent` -> `uvx fast-agent-mcp acp`
- `iflow` -> `iflow --experimental-acp`
- `kilocode` -> `npx -y @kilocode/cli acp`
- `kimi` -> `kimi acp`
- `kiro` -> `kiro-cli-chat acp`
- `opencode` -> `npx -y opencode-ai acp`
- `qoder` -> `qodercli --acp`
- `qwen` -> `qwen --acp`
- `trae` -> `traecli acp serve`

Rules:

- Default agent is `codex` for top-level `prompt`, `exec`, and `sessions`.
- Unknown positional agent tokens are treated as raw agent commands.
- `--agent <command>` explicitly sets a raw ACP adapter command.
- Do not combine a positional agent and `--agent` in the same command.

## Key commands

### Prompt (default, persistent session)

```bash
acpx codex 'fix flaky tests'
acpx codex prompt 'fix flaky tests'
acpx prompt 'fix flaky tests'   # defaults to codex
```

- Uses a saved session for the session scope key, auto-resumes prior session
- If no session exists for the scope, exits with `NO_SESSION` and prompts for `sessions new`
- Is queue-aware when another prompt is already running for the same session
- On interrupt during an active turn, sends ACP `session/cancel` before force-kill fallback

Prompt options: `-s, --session <name>`, `--no-wait`, `-f, --file <path>`

### Exec (one-shot)

```bash
acpx exec 'summarize this repo'
acpx codex exec 'summarize this repo'
```

Runs a single prompt in a temporary ACP session. Does not reuse or save persistent session state.

### Cancel / Mode / Config / Model

```bash
acpx codex cancel
acpx codex set-mode auto
acpx codex set model gpt-5.2[high]
acpx codex set model gpt-5.4
```

- `cancel`: sends cooperative `session/cancel` through queue-owner IPC
- `set-mode`: calls ACP `session/set_mode`
- `set`: calls ACP `session/set_config_option`
- `set model <id>`: calls `session/set_model` for mid-session model switching

### Sessions

```bash
acpx sessions list                          # list all sessions
acpx sessions new --name backend            # create fresh session
acpx sessions ensure --name backend         # idempotent: get or create
acpx sessions close backend                 # close a session
acpx sessions show backend                  # show metadata
acpx sessions history backend --limit 20    # show turn history
acpx sessions export backend --output backend-session.json
acpx sessions import backend-session.json --name backend-restored
acpx sessions prune --dry-run --older-than 7
acpx sessions prune --older-than 30 --include-history
acpx status                                 # check local agent process
```

Prefix any command with an agent name: `acpx codex sessions ensure --name backend`

## Global options

- `--agent <command>`: raw ACP agent command (escape hatch)
- `--cwd <dir>`: working directory for session scope (default: current directory)
- `--approve-all`: auto-approve all permission requests
- `--approve-reads`: auto-approve reads/searches, prompt for writes (default mode)
- `--deny-all`: deny all permission requests
- `--non-interactive-permissions <policy>`: when prompting is unavailable, choose `deny` or `fail`
- `--permission-policy <json-or-file>` / `--policy`: per-tool ACP permission rules
- `--format <fmt>`: output format (`text`, `json`, `quiet`)
- `--json-strict`: strict JSON mode; requires `--format json` and suppresses non-JSON stderr output
- `--suppress-reads`: suppress raw read-file contents while preserving the selected format
- `--timeout <seconds>`: max wait time (positive number)
- `--ttl <seconds>`: queue owner idle TTL before shutdown (default `300`, `0` disables TTL)
- `--model <id>`: request an agent model during session creation
- `--system-prompt <text>`: replace the agent system prompt (persisted in session)
- `--append-system-prompt <text>`: append text to the agent system prompt
- `--allowed-tools <list>`: comma-separated tool whitelist (use `""` for no tools)
- `--max-turns <count>`: cap session turn count
- `--prompt-retries <count>`: retry failed prompt turns on transient errors (default `0`)
- `--no-terminal`: do not advertise the ACP terminal capability
- `--verbose`: verbose ACP/debug logs to stderr

Permission flags are mutually exclusive.

## System prompt override (Claude)

```bash
# Replace the system prompt for a named session, persisted across reuse
acpx --system-prompt "You are a code reviewer who challenges every implicit assumption." claude -s review

# Append a guideline on top of the default system prompt
acpx --append-system-prompt "Always explain trade-offs before recommending a fix." claude -s impl
```

The override is forwarded via ACP `_meta.systemPrompt` on `session/new` and stored in `session_options.system_prompt`. Subsequent `prompt`/`ensure` calls in the same scope keep the override unless you explicitly create a new session. Non-Claude adapters ignore the field.

## Config files

Config files are merged in this order (later wins):

- global: `~/.acpx/config.json`
- project: `<cwd>/.acpxrc.json`

Supported keys: `defaultAgent`, `defaultPermissions`, `nonInteractivePermissions`, `ttl`, `timeout`, `format`, `agents` map, `auth` map.

Use `acpx config show` to inspect the resolved config and `acpx config init` to create the global template.

For ACP `authenticate` handshakes, use either config `auth` entries or explicit `ACPX_AUTH_<METHOD_ID>` environment variables such as `ACPX_AUTH_OPENAI_API_KEY`.

## Session behavior

Persistent prompt sessions are scoped by: `agentCommand`, absolute `cwd`, optional session `name`.

- Session records are stored in `~/.acpx/sessions/*.json`
- `-s/--session` creates parallel named conversations in the same repo
- Changing `--cwd` changes scope and therefore session lookup
- Closed sessions are retained on disk with `closed: true` and `closedAt` until pruned
- Auto-resume by scope skips closed sessions
- Prompt mode attempts to reconnect to saved session; if adapter-side session is invalid/not found, `acpx` creates a fresh session and updates the saved record

## Prompt queueing and `--no-wait`

Queueing is per persistent session. The active `acpx` process for a running prompt becomes the queue owner. Other invocations submit prompts over local IPC.

- Default: enqueue and wait for queued prompt completion, streaming updates back
- `--no-wait`: enqueue and return after queue acknowledgement
- `Ctrl+C` during an active turn sends ACP `session/cancel`, waits briefly, then force-kills only if cancellation does not finish in time
- `cancel` sends the same cooperative cancellation without requiring terminal signals
- After the queue drains, owner shutdown is governed by TTL (default 300s, configurable with `--ttl`)

## Output formats

Use `--format <fmt>`:

- `text` (default): human-readable stream with updates/tool status and done line
- `json`: NDJSON event stream (good for automation)
- `quiet`: final assistant text only
- `--suppress-reads`: replace raw read-file contents with `[read output suppressed]`
- `--json-strict`: pair with `--format json` to suppress non-JSON stderr noise

Example automation:

```bash
acpx --format json codex exec 'review changed files' \
  | jq -r 'select(.type=="tool_call") | [.status, .title] | @tsv'
```

## Flows (multi-agent workflows)

Flows let you declare a multi-agent workflow as a graph of typed nodes connected by edges, executed by the `acpx` runtime. The runtime owns persistence, retries, timeouts, and routing — the flow file declares the shape, not the engine.

```bash
acpx flow run ./my-flow.flow.ts --input-file ./flow-input.json
acpx flow run ./my-flow.flow.ts --input-json '{"task":"FIX: add a regression test"}'
acpx --approve-all flow run examples/flows/pr-triage/pr-triage.flow.ts \
  --input-json '{"repo":"openclaw/acpx","prNumber":150}'
acpx flow run ./my-flow.flow.ts --default-agent claude
```

Run artifacts persist under `~/.acpx/flows/runs/<runId>/`. Default per-step timeout is 15 minutes when `--timeout` is unset.

The authoring surface lives in `acpx/flows`. Node types: `acp` (model-driven step), `decision` (constrained-choice LLM step), `action` (runtime-supervised deterministic operation), `compute` (pure local data transform), `checkpoint` (pause point for human or external trigger).

See `references/advanced.md` for the full authoring example, edge shapes, and detailed node type reference.

## Practical workflows

Persistent repo assistant:

```bash
acpx codex 'inspect failing tests and propose a fix plan'
acpx codex 'apply the smallest safe fix and run tests'
```

Parallel named streams:

```bash
acpx codex -s backend 'fix API pagination bug'
acpx codex -s docs 'draft changelog entry for release'
```

Specialized Claude reviewer that survives session reuse:

```bash
acpx --system-prompt "You are a reviewer who refuses to approve untested changes." claude -s reviewer
acpx claude -s reviewer 'review the diff in src/auth/'
```

Idempotent session bootstrap (safe to call before every prompt in scripts):

```bash
acpx codex sessions ensure -s ci
acpx codex -s ci 'run the smoke suite and report failures'
```

Queue follow-up without waiting:

```bash
acpx codex 'run full test suite and investigate failures'
acpx codex --no-wait 'after tests, summarize root causes and next steps'
```

One-shot script step:

```bash
acpx --format quiet exec 'summarize repo purpose in 3 lines'
```

Machine-readable output for orchestration:

```bash
acpx --format json --json-strict codex 'review current branch changes' > events.ndjson
```

Raw custom adapter command:

```bash
acpx --agent './bin/custom-acp-server --profile ci' 'run validation checks'
```

Periodic cleanup:

```bash
acpx codex sessions prune --dry-run --older-than 14
acpx codex sessions prune --older-than 30 --include-history
```

Multi-agent triage flow:

```bash
acpx --approve-all flow run ./pr-triage.flow.ts --input-json '{"prNumber": 842}'
```

Repo-scoped review with permissive mode:

```bash
acpx --cwd ~/repos/shop --approve-all codex -s pr-842 \
  'review PR #842 for regressions and propose minimal patch'
```
