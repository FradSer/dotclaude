"""Re-render a run's artefacts from its stored interaction (free: no new API work).

Usage: ag-render-check.py <run-id> [--write]

Fetches the stored interaction, re-runs the plugin's extraction, and prints the citation
count. With --write it rewrites output.json/output.md, which is how a run recorded by an
older version of the plugin picks up rendering fixes.
"""
import importlib.util
import json
import os
import sys
from pathlib import Path

from google import genai

PLUGIN = str(Path(__file__).resolve().parents[2])
spec = importlib.util.spec_from_file_location("ag", f"{PLUGIN}/scripts/antigravity.py")
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

run_id = sys.argv[1]
write = "--write" in sys.argv[2:]
d = Path.home() / ".antigravity/runs" / run_id
meta = json.loads((d / "meta.json").read_text())
iid = meta["interaction_id"]

auth = mod.resolve_auth()
client = genai.Client(**auth["client_kwargs"])
interaction = client.interactions.get(iid, timeout=60)
result = mod.extract_result(interaction)
print(f"run={run_id} status={result['status']} citations={len(result['citations'])}")
print(f"steps={result['step_counts']} tokens={(result.get('usage') or {}).get('total_tokens')}")

if write:
    mod.write_json(d / "output.json", result)
    (d / "output.md").write_text(mod.render_markdown(meta, result))
    print("rewrote output.json and output.md")
print("RENDER_CHECK_DONE")