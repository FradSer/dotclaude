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

Credentials — the plugin supports **two paths**, resolved from the environment by
`scripts/antigravity.py`:

| `ANTIGRAVITY_AUTH` | Credential | Endpoint |
|---|---|---|
| `vertex` | Application Default Credentials (ADC) + project + location | Vertex AI (`aiplatform.googleapis.com`) |
| `api-key` | `GEMINI_API_KEY` or `GOOGLE_API_KEY` | Gemini Developer API |
| `auto` (default) | Vertex when ADC + project + location are all set, otherwise the API key | whichever matched |

Vertex setup:

```bash
gcloud auth application-default login
export ANTIGRAVITY_PROJECT="your-project"      # or GOOGLE_CLOUD_PROJECT / GCLOUD_PROJECT
export ANTIGRAVITY_LOCATION="global"          # or GOOGLE_CLOUD_LOCATION
```

`auto` prefers Vertex when it is fully configured so that an ambient API key cannot
silently move a run (and its billing) onto the Developer API. Force either path with
`ANTIGRAVITY_AUTH=vertex` or `ANTIGRAVITY_AUTH=api-key`; the resolved path is printed
on start and recorded in `meta.json` as `auth` / `auth_label`.

- **`uv`** on PATH — the script declares `google-genai>=2.25.0` as a PEP 723 inline
  dependency, installed automatically on first run. No manual `pip install`.

## Delegate flags

| Flag | Default | Meaning |
|------|---------|---------|
| `--tools` | `code_execution,google_search,url_context` | Comma list of tools to offer. |
| `--network` | `default` | `default` = sandbox code has open outbound access; `none` = no outbound (search/URL tools still work). |
| `--repo URL` | — | Mount a GitHub repository at `/workspace/repo`. |
| `--max-tokens N` | — | Cap total tokens (input + output + thinking) via `agent_config.max_total_tokens`. An Antigravity interaction is an autonomous loop, so this is the only real guard on its cost. |
| `--model M` | agent default (Gemini 3.8 Flash) | Underlying model. |
| `--system TEXT` | built-in anti-fabrication instruction | Replace the system instruction; `--system ""` disables it. |
| `--tier T` | — | `service_tier`: `standard`, `flex` (cheap tier for long non-urgent runs), `priority`, `deferred`. |
| `--label k=v` | — | Label the interaction (repeatable). |
| `--image PATH` | — | Attach a png/jpeg/webp/heic image as inline base64 (repeatable). |
| `--json` | — | Ask for `application/json` output through `response_format`. |
| `--environment-id ID` | — | Reuse an existing sandbox, preserving its files. Sent as the bare id: the config-object form silently provisions a new sandbox. Cannot be combined with `--repo` or `--network none`. |
| `--previous-interaction-id ID` | — | Chain a turn. The previous sandbox is reused when `--environment-id` is not also given, because managed-agent chaining requires both in one request. |

## Research flags

`--max` (higher-effort agent), `--collaborative-planning`, `--visualization {off,auto}`,
`--thinking-summaries {auto,none}`, `--bigquery`, plus `--system`, `--tier` and `--label`.

**Deep research cannot be capped.** `DeepResearchAgentConfig` accepts only the research
options above — there is no `max_total_tokens` or model field — so `--max-tokens` and
`--model` exist on `delegate` only. Budget research by choosing a narrower question, not
by trusting a cap.

## Watching a run

`status --run <id> --progress` prints the tail of `progress.log`, which the worker fills
from the interaction's server-sent event stream (`step.start`, `step.delta`,
`interaction.completed`). Streaming is best-effort: polling is what decides the run's
state, so a stream that cannot be connected only costs progress lines.

`cleanup [--older-than-days N] [--remote] [--dry-run]` prunes finished run directories;
`--remote` also deletes the stored interactions (which is why the local record is kept
when a remote delete fails: it retains the interaction id for a retry).

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
flipping a `status` file when done. The two agents have opposite `background` requirements, and Vertex inverts the
delegate rule (all verified live):

- **delegate** (`antigravity-preview-05-2026`) — on the Developer API it rejects
  `background` and `create()` runs synchronously; on Vertex it *requires*
  `background=true`, so the plugin polls `get()` there instead.
- **research** (`deep-research-*-preview-04-2026`) requires `background=True` on both
  paths; `create()` returns immediately and the worker polls `interactions.get(id)`
  until the server reports a terminal status.

The `wait` subcommand polls the `status` file and emits a single terminal line, which
the Monitor tool turns into a notification. Polling is authoritative; the SSE stream is
consumed only to fill `progress.log`.

## Data retention and cost

The Interactions API is **GA** (since June 2026); the *agents* are still preview
(their ids carry `-preview-`). Requests are stored (`store=true`), which is required
for background execution, `previous_interaction_id` chaining, and progress streaming.
Stored interactions are retained **55 days on the paid tier and 1 day on the free
tier**; `cleanup --remote` or the AI Studio logs page can delete them sooner.

Cost is real and open-ended: a delegate run is thousands of tokens and a research run
can be millions. Use `--max-tokens` on delegate, `--tier flex` for long non-urgent work,
and accept that research has no cap.

## Preview caveats

The managed agents are preview: no SLA, the schema may change. `delegate` gets the
built-in `code_execution` / `google_search` / `url_context` tools plus the sandbox
filesystem (enabled by `environment`); the agent can also answer from its own knowledge
instead of calling a tool, which is why the plugin sends an anti-fabrication system
instruction by default. Documents list `antigravity-preview-09-2026` as a newer agent
and `mcp_server` as a tool type, but as of this commit the former returns
`404 Agent not found` and the latter is documented as unavailable for Gemini 3.

## License

MIT
