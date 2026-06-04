# Antigravity

Delegate work from Claude Code to **Google Gemini Managed Agents** (the
"Antigravity" agent) running in a remote, isolated sandbox — then read the results
back. A bridge, not an MCP server: Gemini's managed agents do not support being
exposed as MCP/tools during preview, so this plugin calls the **Interactions API**
through a bundled script.

## Commands

| Command | What it does |
|---------|--------------|
| `/antigravity:delegate <task> [flags]` | Run a self-contained task on `antigravity-preview-05-2026` with code execution, Google Search, and URL reading in a remote sandbox. |
| `/antigravity:research <question> [--max]` | Run a deep-research query and get a cited report. Uses `deep-research-preview-04-2026`, or `deep-research-max-preview-04-2026` with `--max`. |

There is one execution mode: the command always waits for the result. Under the
hood the call returns a `run_id` immediately and a detached worker performs the
(synchronous, possibly multi-minute) interaction; the command then uses the Monitor
tool to wait for the run to reach a terminal state before reporting. Because the
worker is detached, the work survives even if the wait is interrupted — resume with
`status --run <id>`.

## Prerequisites

- **`GEMINI_API_KEY`** (or `GOOGLE_API_KEY`) set in the environment.
- **`uv`** on PATH — the script declares `google-genai>=1.55.0` as a PEP 723 inline
  dependency, installed automatically on first run. No manual `pip install`.

## Delegate flags

| Flag | Default | Meaning |
|------|---------|---------|
| `--tools` | `code_execution,google_search,url_context` | Comma list of tools to offer. |
| `--network` | `default` | `default` = sandbox code has open outbound access; `none` = no outbound (search/URL tools still work). |
| `--repo URL` | — | Mount a GitHub repository at `/workspace/repo`. |

## Examples

```
/antigravity:delegate Compute the 200th Fibonacci number and factor it. Show the code.
/antigravity:delegate Summarize today's top Hacker News stories --network none
/antigravity:delegate Find the top 3 open issues and sketch fixes --repo https://github.com/owner/name
/antigravity:research Compare LFP vs NMC EV battery tradeoffs in 2026
```

See `examples/delegate-examples.md` for more, and
`skills/delegate/references/usage.md` for the full API surface, environment options,
state layout, and preview caveats.

## How it works

`scripts/antigravity.py` wraps `client.interactions.create(...)` and always runs it
in a detached worker, writing results under `~/.antigravity/runs/<run-id>/` and
flipping a `status` file when done. The two agents have opposite `background`
requirements (verified live):

- **delegate** (`antigravity-preview-05-2026`) rejects `background`; `create()` runs
  synchronously and the worker blocks on it.
- **research** (`deep-research-*-preview-04-2026`) requires `background=True`;
  `create()` returns immediately and the worker polls `interactions.get(id)` until
  the server reports a terminal status.

The `wait` subcommand polls the `status` file and emits a single terminal line, which
the Monitor tool turns into a notification.

## Preview caveats

The Gemini Managed Agents API is Pre-GA (mid-2026): no SLA, the schema may change.
Only `code_execution` / `google_search` / `url_context` tools are available to
`delegate`. Tokens bill at the underlying model's rates.

## License

MIT
