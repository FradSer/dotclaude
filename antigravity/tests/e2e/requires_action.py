"""E2E: a real `requires_action` must fail the wait fast instead of polling to the deadline.

Registers a custom function on the antigravity agent (which the plugin never does) so the
interaction genuinely pauses waiting for a client-side call, then drives the plugin's own
wait_for_terminal against it.
"""
import importlib.util
import os
import tempfile
import time
from pathlib import Path

from google import genai

PLUGIN = str(Path(__file__).resolve().parents[2])
spec = importlib.util.spec_from_file_location("ag", f"{PLUGIN}/scripts/antigravity.py")
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

client = genai.Client(
    vertexai=True,
    project=os.environ["ANTIGRAVITY_PROJECT"],
    location=os.environ["ANTIGRAVITY_LOCATION"],
)
weather = {
    "type": "function",
    "name": "get_weather",
    "description": "Get the weather for a location.",
    "parameters": {"type": "object", "properties": {"location": {"type": "string"}}, "required": ["location"]},
}
interaction = client.interactions.create(
    agent=mod.ANTIGRAVITY_AGENT,
    background=True,
    environment="remote",
    input="Call the get_weather function for Tokyo, then report the temperature.",
    tools=[weather],
    timeout=120,
)
status = interaction.status
for _ in range(24):
    if status != "in_progress":
        break
    time.sleep(5)
    status = client.interactions.get(interaction.id, timeout=60).status
print(f"settled={status}")

if status != "requires_action":
    print("REQUIRES_ACTION_INCONCLUSIVE")
else:
    with tempfile.TemporaryDirectory() as tmp:
        try:
            mod.wait_for_terminal(client, interaction.id, Path(tmp), time.monotonic() + 60)
            print("REQUIRES_ACTION_FAIL (returned instead of failing fast)")
        except RuntimeError as exc:
            print(f"REQUIRES_ACTION_PASS {str(exc)[:60]}")

# Best-effort tidy-up: a just-created interaction is often still too fresh to delete, and a
# settled one refuses to cancel, so either outcome is acceptable here.
try:
    client.interactions.cancel(interaction.id, timeout=60)
except Exception:  # noqa: BLE001
    pass
try:
    client.interactions.delete(id=interaction.id, timeout=60)
    print("cleanup=deleted")
except Exception as exc:  # noqa: BLE001
    print(f"cleanup=left-for-retention ({type(exc).__name__})")