---
name: use-acpx
description: Provides knowledge about acpx CLI for agent-to-agent communication. Use when user asks about acpx commands, ACP protocol, agent sessions, prompt queueing, or scriptable agent workflows.
user-invocable: false
---

# acpx

## CRITICAL: Background Execution Required

**MUST** use `run_in_background: true` for ALL `acpx` bash commands. Running `acpx` in the foreground will block Claude Code and make the session unusable.

When executing any `acpx` command:

```json
{
  "command": "acpx codex 'your prompt here'",
  "run_in_background": true
}
```

Failure to run in background will cause Claude Code to block indefinitely while waiting for the agent to complete.

## What acpx is

`acpx` is a headless, scriptable CLI client for the Agent Client Protocol (ACP). It is built for agent-to-agent communication over the command line and avoids PTY scraping.

**WARNING**: Never use Claude-related ACP agents with acpx. Using Claude to call Claude creates recursive loops and unpredictable behavior. Use alternative agents like `codex`, `openclaw`, `gemini`, etc.

Core capabilities:

- Persistent multi-turn sessions per repo/cwd
- One-shot execution mode (`exec`)
- Named parallel sessions (`-s/--session`)
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
- Structured streaming output (`text`, `json`, `quiet`)
- Built-in agent registry plus raw `--agent` escape hatch

## Install

```bash
npm i -g acpx
```

For normal session reuse, prefer a global install over `npx`.

## Command model

`prompt` is the default verb. Commands follow this shape:

```bash
acpx [global_options] [<agent>] [verb] [prompt_options] [prompt_text...]
```

Verbs: `prompt` (default), `exec`, `cancel`, `set-mode`, `set`, `status`, `sessions`, `config`. When prompt text is omitted and stdin is piped, `acpx` reads from stdin. For the full grammar, see `./references/cli.md`.

## Built-in agent registry

**IMPORTANT**: Do NOT use Claude-related ACP agents (e.g., `claude`, `@zed-industries/claude-agent-acp`). These create recursive agent-calling-agent scenarios that can cause infinite loops or unexpected behavior.

Friendly agent names resolve to commands:

- `pi` -> `npx pi-acp`
- `openclaw` -> `openclaw acp`
- `codex` -> `npx @zed-industries/codex-acp`
- `gemini` -> `gemini --acp`
- `cursor` -> `cursor-agent acp`
- `copilot` -> `copilot --acp --stdio`
- `droid` -> `droid exec --output-format acp`
- `kimi` -> `kimi acp`
- `opencode` -> `npx -y opencode-ai acp`
- `kiro` -> `kiro-cli acp`
- `kilocode` -> `npx -y @kilocode/cli acp`
- `qwen` -> `qwen --acp`

Rules:

- Default agent is `codex` for top-level `prompt`, `exec`, and `sessions`.
- Unknown positional agent tokens are treated as raw agent commands.
- `--agent <command>` explicitly sets a raw ACP adapter command.
- Do not combine a positional agent and `--agent` in the same command.

## Commands

### Prompt (default, persistent session)

```bash
acpx codex 'fix flaky tests'             # implicit prompt
acpx codex prompt 'fix flaky tests'      # explicit
acpx prompt 'fix flaky tests'            # defaults to codex
```

Auto-resumes the saved session for scope `(agentCommand, cwd, name?)`. Exits code `4` if no session exists — run `sessions new` first. Queue-aware: submits to running queue owner when a prompt is already in flight. On interrupt, sends ACP `session/cancel` before force-kill.

Prompt options: `-s/--session <name>`, `--no-wait`, `-f/--file <path>`.

### Exec (one-shot)

```bash
acpx codex exec 'summarize this repo'
```

Runs a single prompt in a temporary session; does not reuse or persist session state.

### Cancel / Mode / Set

```bash
acpx codex cancel
acpx codex set-mode auto
acpx codex set approval_policy conservative
```

`cancel` sends cooperative `session/cancel` via IPC. `set-mode` calls ACP `session/set_mode` (mode ids are adapter-defined). `set` calls ACP `session/set_config_option`. Both route through queue-owner IPC when active.

### Sessions

```bash
acpx sessions list
acpx sessions new [--name <name>]
acpx sessions close [name]
acpx sessions show [name]
acpx sessions history [name] [--limit <count>]
acpx status

acpx codex sessions new --name backend
acpx codex sessions close backend
acpx codex sessions show backend
acpx codex sessions history backend --limit 20
acpx codex status
```

Key behaviors: `sessions` and `sessions list` are equivalent. `new` creates a fresh session for the current scope; if an open session already exists in that scope, it is soft-closed. `show [name]` prints metadata; `history [name]` prints turn previews (default 20).

For the complete subcommand list including `ensure`, all flags, global options, config keys, session scoping rules, queueing internals, output format details, permission modes, and exit codes, see `./references/cli.md`.

## Global options (summary)

- `--agent <command>`: raw ACP command (escape hatch)
- `--cwd <dir>`: working directory for session scope
- `--approve-all` / `--approve-reads` (default) / `--deny-all`: permission mode (mutually exclusive)
- `--format <fmt>`: `text` (default), `json`, `quiet`
- `--timeout <seconds>` / `--ttl <seconds>`: timing controls (TTL default 300s)
- `--verbose`: ACP/debug logs to stderr

## Reference summary

**Config files**: merged in order — `~/.acpx/config.json` (global), `<cwd>/.acpxrc.json` (project). Key settings: `defaultAgent`, `defaultPermissions`, `ttl`, `timeout`, `format`, `agents` map, `auth` map. Run `acpx config show` to inspect; `acpx config init` to create global template.

**Session behavior**: sessions scoped by `agentCommand` + absolute `cwd` + optional `name`. Records in `~/.acpx/sessions/*.json`. Prompt mode auto-resumes by walking up to git root; exits code `4` if no session found (run `sessions new`). Dead PIDs are respawned. Use `-s/--session <name>` for parallel conversations.

**Prompt queueing**: the first `acpx` process for a session becomes the queue owner; others submit over local IPC. Default: wait for completion. `--no-wait`: return after enqueue. `Ctrl+C` sends ACP `session/cancel` before force-kill. Owner shuts down after TTL idle (default 300s).

**Output formats**: `--format text` (default) human-readable stream, `--format json` NDJSON for automation, `--format quiet` final text only, `--json-strict` suppresses non-JSON stderr.

**Permission modes**: choose one — `--approve-all`, `--approve-reads` (default), `--deny-all`. If all requests are denied/cancelled and none approved, `acpx` exits with permission-denied status.

For full details on all options, subcommands, exit codes, and IPC internals, see `./references/cli.md`.

## Practical workflows

Persistent repo assistant (multi-turn):

```bash
acpx codex 'inspect failing tests and propose a fix plan'
acpx codex 'apply the smallest safe fix and run tests'
```

Parallel named sessions + queued follow-up:

```bash
acpx codex -s backend 'fix API pagination bug'
acpx codex -s docs 'draft changelog entry for release'
acpx codex --no-wait 'after tests, summarize root causes and next steps'
```

One-shot and automation:

```bash
acpx --format quiet exec 'summarize repo purpose in 3 lines'
acpx --format json codex 'review current branch changes' > events.ndjson
acpx --cwd ~/repos/shop --approve-all codex -s pr-842 \
  'review PR #842 for regressions and propose minimal patch'
```

For more examples including stdin/file prompts, session management, and JSON automation pipelines, see `./references/cli.md`.
