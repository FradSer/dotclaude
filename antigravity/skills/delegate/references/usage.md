# Antigravity / Gemini Managed Agents — reference

Background detail for the `delegate` and `research` skills. The wrapper script is
`scripts/antigravity.py`; it talks to the Gemini **Interactions API** via the
`google-genai` SDK (declared as a PEP 723 inline dependency, installed on first
`uv run`).

## Authentication

The script resolves one of two credential paths from the environment; `auto`
prefers Vertex whenever it is fully configured, so an ambient API key cannot
silently redirect a run (and its billing) onto the Developer API.

| `ANTIGRAVITY_AUTH` | Requires | Client |
|---|---|---|
| `vertex` | `application_default_credentials.json` (or `GOOGLE_APPLICATION_CREDENTIALS`) + project + location | `genai.Client(vertexai=True, project=..., location=...)` |
| `api-key` | `GEMINI_API_KEY` or `GOOGLE_API_KEY` | `genai.Client(api_key=...)` |
| `auto` (default) | Vertex when complete, else a key | whichever matched |

Project and location resolve as `ANTIGRAVITY_PROJECT` then `GOOGLE_CLOUD_PROJECT`
then `GCLOUD_PROJECT`, and `ANTIGRAVITY_LOCATION` then `GOOGLE_CLOUD_LOCATION`.

With Vertex the SDK mints an OAuth bearer token from ADC and sends
`x-goog-user-project`, so no API key is involved. A forced path that is incomplete
aborts before a run directory is created, naming exactly what is missing; with no
credentials at all the script prints both setup paths.

## The underlying call

The two agents have **opposite** `background` requirements, and Vertex
inverts the delegate rule (all verified against the live API):

```python
from google import genai

# vertex: ADC + project + location. Interactions route to
# https://{location}-aiplatform.googleapis.com/v1beta1/projects/{p}/locations/{l}/interactions
client = genai.Client(vertexai=True, project="<project>", location="global")

# api-key: Gemini Developer API
client = genai.Client(api_key=os.environ["GEMINI_API_KEY"])

# delegate: antigravity agent — background MUST be omitted on the Developer API and
# REQUIRED on Vertex (a synchronous agent call fails with 400 "Agent interactions
# must set background to true"); on Vertex the worker polls get() instead.
interaction = client.interactions.create(
    agent="antigravity-preview-05-2026",
    input="<prompt>",
    tools=[{"type": "code_execution"}, {"type": "google_search"}, {"type": "url_context"}],
    environment={"type": "remote"},   # omit "network" = open; "disabled" = no outbound
    store=True,
    timeout=7200,   # SECONDS; only sent on the synchronous path (the SDK default is 60s) — far too short for sandbox work
)
print(interaction.output_text)

# research: deep-research agent — background=True is REQUIRED; returns immediately,
# then poll client.interactions.get(id, timeout=...) until status is terminal
interaction = client.interactions.create(
    agent="deep-research-preview-04-2026",
    input="<question>",
    agent_config={"type": "deep-research"},
    background=True,
    store=True,
)
```

Execution model (single mode per kind): `delegate` and `research` both spawn a
detached worker and the caller waits via the `wait` subcommand. A synchronous
`create()` (delegate on the Developer API) blocks inside the worker, which therefore
makes no `get()` polls; a background `create()` (research on both paths, delegate on
Vertex) returns immediately and the worker polls `get()` until the server reports a
terminal status. The detached worker survives an interrupted wait,
so a run is always resumable via `status`.

## Interaction status

`interaction.status` is one of seven values (google-genai `Interaction.status` Literal):

- **Active (keep polling):** `in_progress`, `requires_action`
- **Terminal:** `completed` (the only success), `failed`, `cancelled`, `incomplete`, `budget_exceeded`

There is no `done` flag or `is_terminal()` helper — callers compare the string. The
worker polls until the status is in the terminal set, treating an empty status or any
unrecognized value as "still working" (the worker deadline bounds a real hang), so a
new active state the SDK adds is never mistaken for a finished run. Only `completed`
maps to a local `completed` status; every other terminal state is recorded as `failed`
with the server status in the error.

## Agents

| Agent | Use |
|-------|-----|
| `antigravity-preview-05-2026` | General task agent. Code execution, search, URL reading in a sandbox. Used by `delegate`. |
| `deep-research-preview-04-2026` | Deep-research agent; manages its own browsing. Default for `research`, with `agent_config={"type": "deep-research"}`. |
| `deep-research-max-preview-04-2026` | Max-mode deep research (slower, higher effort). Used by `research --max`. |

## Tools (delegate, preview)

- `code_execution` — Python / Bash / Node in `/workspace`.
- `google_search` — web search via Google infra (works even with `--network none`).
- `url_context` — fetch and read URLs (also unaffected by `--network none`).

Not available in preview: function calling, MCP servers, file search, computer use,
Google Maps, structured output / `response_format`.

## Environment & network

- `--network default` — sandbox code has open outbound access (e.g. `pip install`);
  implemented by **omitting** the `network` field (the SDK `Network` enum is
  `"disabled" | {allowlist: [...]}`, and omission means allow-all).
- `--network none` — sandbox code has no outbound access (`network="disabled"`),
  the safest option; search and URL tools still work because they run on Google infra.
- `--repo URL` — mounts a GitHub repository at `/workspace/repo` via
  `environment.sources`.
- `--environment-id ID` — reuse an existing sandbox environment (from a previous run).
  **Sent as the bare id string**, the only shape that actually reuses: a config object
  carrying the id (with either `id` or `environment_id`) is accepted by the server and then
  provisions a fresh sandbox, so files silently disappear while the run looks healthy.
  Verified live — the bare id came back unchanged and a file written in the earlier sandbox
  was still readable. Because the field *is* the environment, `--environment-id` cannot be
  combined with `--repo` or `--network none`; the script rejects that combination instead of
  dropping the options.
- `--previous-interaction-id ID` — continue from a previous interaction **and** its sandbox.
  Managed-agent chaining requires `previous_interaction_id` and `environment` in one request,
  so when only the interaction id is given the worker reads that interaction's
  `environment_id` and reuses it (`worker.err` records a lookup failure, and the run then
  proceeds in a fresh sandbox). Chaining onto an `in_progress` interaction returns
  `400 Bad Request`.
- The sandbox TTL is unverified; it may persist for days but this is not guaranteed by the API.
  The script reports the `environment_id` in the result.

## Multi-turn

To continue in the same sandbox with prior context, use the `--environment-id` and
`--previous-interaction-id` flags:

```bash
antigravity.py delegate --prompt "follow-up question" \
  --environment-id <env-id> \
  --previous-interaction-id <interaction-id>
```

The script reports both ids in the result output. Chaining a managed-agent turn requires
`previous_interaction_id` **and** `environment` in the same request, so when only
`--previous-interaction-id` is given the worker reads that interaction's
`environment_id` and reuses it — otherwise the history would carry over into a fresh
sandbox with none of the files. A lookup failure is recorded in `worker.err` and the run
proceeds with a new sandbox. Chaining onto an interaction that is still `in_progress`
returns `400 Bad Request` from the API.

## Request options

Everything the Interactions API exposes for cost, model, and steering is forwarded:

| Flag | Effect on the request |
|---|---|
| `--max-tokens N` | `agent_config.max_total_tokens` (AntigravityAgentConfig only) |
| `--model M` | `agent_config.model` |
| `--system TEXT` | `system_instruction`; `""` omits it. **Delegate only** — the deep-research agent rejects the parameter, so `research` refuses `--system`. |
| `--tier T` | `service_tier`: `standard` / `flex` / `priority` / `deferred` |
| `--label k=v` | `labels` |
| `--image PATH` | inline base64 image part in `input` |
| `--json` | `response_format` with `application/json` |

Verified against the live API: `max_total_tokens`, `model`, `system_instruction`,
`labels`, `service_tier`, image input, and JSON output are all accepted and effective
(a JSON run returned parseable keys; an image run described the image).

Two constraints worth knowing:

- **`response_mime_type` is not sent.** Setting it alone, or alongside
  `response_format`, is rejected with "responseFormat must be set when responseMimeType
  is set"; `response_format` alone is the working form.
- **Deep research has no cost cap.** `DeepResearchAgentConfig` carries only
  `collaborative_planning`, `visualization`, `thinking_summaries` and
  `enable_bigquery_tool`, so `--max-tokens` / `--model` are not offered on `research` —
  and it accepts no `system_instruction` either, so `--system` is refused there.

## Sources

Grounded answers attach `url_citation` annotations to their text (a live research report
carried 43, deduping to 9 unique sources) and refer to them inline as `[cite: N]`.
The plugin renders them under `## Sources` in `output.md`, exposes them as `citations` in
`output.json`, and records the count in the header — without them every inline marker
points at nothing. A run recorded by an older version can be re-rendered from its stored
interaction without any new API work.

## Waiting, progress, and retention

The worker polls `interactions.get(id)` for the authoritative status and, in parallel,
consumes `get(id, stream=True)` to append `progress.log` (`step.start`, `step.delta`,
`interaction.completed`), reconnecting from `last_event_id`. Streaming is best-effort:
a stream that cannot be consumed only costs progress lines. `status --progress` shows
the tail.

`requires_action` is not "still working": it means the agent paused for a client-side
function call. The plugin registers no custom functions, so such a run fails immediately
with that explanation instead of polling until the worker deadline.

`store=True` is sent on both kinds because background execution, chaining, and streaming
all read the stored interaction back. Retention is **55 days (paid tier) / 1 day (free
tier)**; `cleanup [--remote]` deletes stored interactions and prunes local run
directories.

The interaction lifecycle matters for `cleanup`:

- `delete` is refused for a just-created interaction (`400 ... cannot be deleted in its
  current state`) and a settled one refuses to `cancel` (`409`), so cleanup targets runs
  that finished days ago, not minutes ago.
- A `404` on delete means the interaction is already gone (retention, or an earlier
  cleanup). That counts as done and the run directory is pruned — otherwise the directory
  would be kept forever, retrying a delete that can never succeed.
- Any other failure (including a transport error) keeps the run directory and its
  interaction id, so the delete can be retried. Both paths were verified live.

## State layout

Each run lives under `~/.antigravity/runs/<run-id>/` (override the base with
`ANTIGRAVITY_HOME`):

- `meta.json` — request + resolved `interaction_id` / `environment_id`
- `status` — `starting` | `running` | `completed` | `failed`
- `output.json` — structured result (output text, step counts, tool trace, usage)
- `output.md` — rendered, human-readable result
- `progress.log` — streamed progress lines (best-effort, bounded)
- `worker.err` — worker stderr for diagnostics

## Subcommands

```
antigravity.py delegate --prompt "..." [--tools ...] [--network default|none] [--repo URL]
                              [--max-tokens N] [--model M] [--system TEXT] [--tier T]
                              [--label k=v] [--image PATH] [--json]
antigravity.py research --query "..." [--max] [--collaborative-planning]
                              [--visualization off|auto] [--thinking-summaries auto|none]
                              [--bigquery] [--system TEXT] [--tier T] [--label k=v]
antigravity.py wait    --run <id> [--interval 5] [--timeout 900]
antigravity.py status  --run <id> [--full] [--progress]
antigravity.py cleanup [--older-than-days 7] [--remote] [--dry-run]
```

## Preview caveats

The Interactions API is **GA** (June 2026); the agents are preview, so there is no SLA
and the schema may change. `background` is not a per-agent constant: the deep-research
agent requires it on both credential paths, while the antigravity agent rejects it on the
Developer API but **requires** it on Vertex — the worker branches on kind and endpoint.
The `usage` namespace is flagged experimental by the SDK, and token usage bills at the
underlying model's rates.

Documents list a newer `antigravity-preview-09-2026` agent, but it returns
`404 Agent not found` on the live API and the newest released `google-genai` does not
list it either, so the pinned `-05-2026` id is the one that works. `mcp_server` is
documented as a tool type but Google states remote MCP is unavailable for Gemini 3.

Timeout gotcha: the SDK's default per-request timeout is **60 seconds**, and the
per-request `timeout=` kwarg is in **seconds** while `HttpOptions.timeout` is in
**milliseconds** (opposite units). A synchronous `create()` blocks until the agent
finishes, so the delegate worker passes an explicit multi-hour `timeout=` to keep
long sandbox runs from aborting at the 60s default; the background research worker
returns immediately and polls `get(..., timeout=...)` instead.
