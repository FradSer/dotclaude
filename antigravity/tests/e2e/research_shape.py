"""Verify the plugin's research request shape without paying for a full run.

Builds the request through the plugin's own prepare_options + build_create_kwargs (the
production path — an earlier version hand-built the meta dict and therefore missed a 400
the real CLI hit), creates the interaction, then cancels it.
"""
import importlib.util
import os
from pathlib import Path

from google import genai

PLUGIN = str(Path(__file__).resolve().parents[2])
spec = importlib.util.spec_from_file_location("ag", f"{PLUGIN}/scripts/antigravity.py")
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

prepared = mod.prepare_options(
    "research",
    {
        "tools": [],
        "network": "default",
        "research_options": {"visualization": "off", "thinking_summaries": "none"},
    },
)
meta = {
    "run_id": "probe",
    "kind": "research",
    "agent": mod.DEEP_RESEARCH_AGENT,
    "prompt": "What is 2+2? One sentence.",
    "background": True,
    **prepared,
}
kwargs = mod.build_create_kwargs(meta)
print("request:", {k: v for k, v in kwargs.items() if k not in ("input", "store")})
assert "system_instruction" not in kwargs, "research must not send system_instruction"

client = genai.Client(
    vertexai=True,
    project=os.environ["ANTIGRAVITY_PROJECT"],
    location=os.environ["ANTIGRAVITY_LOCATION"],
)
interaction = client.interactions.create(**kwargs, timeout=120)
print("created:", interaction.id, "status:", interaction.status)
cancelled = client.interactions.cancel(interaction.id, timeout=60)
print("cancelled:", cancelled.status)
print("RESEARCH_SHAPE_DONE")