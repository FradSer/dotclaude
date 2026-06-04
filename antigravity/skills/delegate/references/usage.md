# Antigravity / Gemini Managed Agents — reference

Background detail for the `delegate` and `research` skills. The wrapper script is
`scripts/antigravity.py`; it talks to the Gemini **Interactions API** via the
`google-genai` SDK (declared as a PEP 723 inline dependency, installed on first
`uv run`).

## Authentication

Set `GEMINI_API_KEY` (or `GOOGLE_API_KEY`) in the environment. No OAuth or service
account is needed. The script aborts with a clear error if neither is present.

## The underlying call

The two agents have **opposite** `background` requirements (verified against the
live API):

```python
from google import genai
client = genai.Client(api_key=os.environ["GEMINI_API_KEY"])

# delegate: antigravity agent — background MUST be omitted; create() blocks until done
interaction = client.interactions.create(
    agent="antigravity-preview-05-2026",
    input="<prompt>",
    tools=[{"type": "code_execution"}, {"type": "google_search"}, {"type": "url_context"}],
    environment={"type": "remote"},   # omit "network" = open; "disabled" = no outbound
    store=True,
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
detached worker and the caller waits via the `wait` subcommand. The delegate worker
blocks on the synchronous `create()`; the research worker polls `get()` until the
server reports a terminal status. The detached worker survives an interrupted wait,
so a run is always resumable via `status`.

## Agents

| Agent | Use |
|-------|-----|
| `antigravity-preview-05-2026` | General task agent (Gemini 3.5 Flash). Code execution, search, URL reading in a sandbox. Used by `delegate`. |
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
- The sandbox has a ~7-day TTL and persists `/workspace` across turns when its
  `environment_id` is reused. The script reports the `environment_id` in the result.

## Multi-turn (manual)

To continue in the same sandbox with prior context, a follow-up call would pass the
previous `environment_id` to `environment=` and `previous_interaction_id=` to the
create call. The current skills do not expose this; use the printed ids if you need to
script a follow-up by hand.

## State layout

Each run lives under `~/.antigravity/runs/<run-id>/` (override the base with
`ANTIGRAVITY_HOME`):

- `meta.json` — request + resolved `interaction_id` / `environment_id`
- `status` — `starting` | `running` | `completed` | `failed`
- `output.json` — structured result (output text, step counts, tool trace, usage)
- `output.md` — rendered, human-readable result
- `worker.err` — worker stderr for diagnostics

## Subcommands

```
antigravity.py delegate --prompt "..." [--tools ...] [--network default|none] [--repo URL]
antigravity.py research --query "..." [--max]
antigravity.py wait    --run <id> [--interval 5] [--timeout 900]
antigravity.py status  --run <id> [--full]
```

## Preview caveats

Pre-GA as of mid-2026: no SLA, schema may change. `background` is required by the
deep-research agent and rejected by the antigravity agent (so the worker branches on
kind). `store=True` is sent on both. The `usage` namespace is flagged experimental by
the SDK. Token usage is billed at the underlying model's rates.
