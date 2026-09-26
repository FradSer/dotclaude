# E2E harness

Live verification against the real API. Not part of the unit suite (`../test_antigravity.py`)
because every run costs tokens and needs credentials.

```bash
ANTIGRAVITY_PROJECT=... ANTIGRAVITY_LOCATION=... bash tests/e2e/run.sh
```

What it does:

- **Preflight** — waits for `aiplatform.googleapis.com` and `oauth2.googleapis.com` to answer
  before asserting anything. This machine reaches Google through a TUN + fake-IP proxy that
  drops connections intermittently, and without the preflight a red run would be
  indistinguishable from a code defect. Agent runs are retried once on transport errors for
  the same reason; anything else fails immediately.
- **T1–T6** — sandbox code execution, extracted output integrity (`2**64` must not be split
  across steps), the tool trace, streamed progress, the cost/model/tier/label/JSON options in
  one request, image input, multi-part output spanning a tool call, and sandbox reuse both
  explicit (`--environment-id`) and chained (`--previous-interaction-id`). The reuse cases
  read a file written by the earlier run, so conversation history cannot fake a pass.
- **T7** — failure propagation on a bad API key plus CLI validation exits.
- **T8** — research request shape via create + `interactions.cancel`, so the deep-research
  path is checked without paying for a full report.
- **T9–T12** — cleanup pruning (dry-run, local, and `--remote` with a real server-side
  delete), citation extraction re-rendered from a stored interaction (free), and a real
  `requires_action` fail-fast triggered by a custom function tool.

Cost: the agent-running cases spend roughly 60–80k tokens per pass. T8–T12 are free or
near-free, which is why the expensive assertions are limited to one request each.

Helper probes: `research_shape.py`, `render_check.py`, `requires_action.py`. Every one takes
its plugin path from its own location, so nothing depends on a machine-specific path.

`render_check.py <run-id> [--write]` re-extracts a run from its stored interaction — free, and
the way a run recorded by an older plugin version picks up rendering fixes.