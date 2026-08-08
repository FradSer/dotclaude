#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = ["httpx>=0.27.0"]
# ///
"""UserPromptSubmit hook: auto-describe image file paths mentioned in the prompt.

Reads the hook input from stdin (JSON with a "prompt" field), finds image file
paths that exist on disk, describes each with the configured vision model, and
returns the descriptions in `hookSpecificOutput.additionalContext` so a
non-vision model can answer "what's in /path/to/img.png" without seeing it.

Scope: this hook covers image *file paths* in text. It cannot see or remove
pasted-screenshot image blocks (they are not part of the hook input) — that is
the proxy's job (scripts/vision_proxy.py). Together they give non-vision models
eyes in both scenarios, fully automatically.

Config: reuses the proxy's layered `vision.json` (see vision_proxy.py). The vision
provider is an independent service configured under `vision.*` — never falls
back to ANTHROPIC_* credentials.
"""

from __future__ import annotations

import json
import os
import sys
from pathlib import Path

# Reuse the proxy's image handling (regex + local-file description).
sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "scripts"))
from vision_proxy import Cfg, _find_image_paths, _describe_local_file  # noqa: E402


def _noop() -> None:
    # Exit 0 with no additional context — pass the prompt through untouched.
    print(json.dumps({"hookSpecificOutput": {}}, ensure_ascii=False))


def main() -> None:
    try:
        data = json.load(sys.stdin)
    except (json.JSONDecodeError, OSError):
        return _noop()
    prompt = data.get("prompt") or ""
    # VB_HOOK_ENABLED: env override, then config layer, then default on.
    enabled = os.environ.get("VB_HOOK_ENABLED")
    if enabled is None:
        from vision_proxy import _cfg_raw  # noqa: E402

        v = _cfg_raw("hookEnabled")
        enabled = str(v) if v is not None else "1"
    if str(enabled) != "1" or not prompt:
        return _noop()

    # The vision provider is fully independent (its own baseUrl + apiKey); never
    # fall back to ANTHROPIC_* creds. We need vision config only — reuse the
    # proxy's layered config, but ignore the upstream (may be the proxy itself).
    cfg = Cfg(load_env=True)
    cfg.upstream = ""  # describe-only: no upstream forwarding needed

    if not (cfg.vision_base and cfg.vision_key):
        return _noop()

    descriptions: list[str] = []
    for token in _find_image_paths(prompt):
        try:
            res = _describe_local_file(token, cfg)
        except Exception as exc:  # a vision failure must never block the prompt
            descriptions.append(f"[vb-hook] {token}: description failed ({exc})")
            continue
        if res:
            desc, fpath = res
            descriptions.append(f"[vb-hook] {fpath}:\n{desc}")

    if not descriptions:
        return _noop()

    context = "Image file descriptions (auto-injected):\n" + "\n\n".join(descriptions)
    print(
        json.dumps(
            {
                "hookSpecificOutput": {
                    "hookEventName": "UserPromptSubmit",
                    "additionalContext": context,
                }
            },
            ensure_ascii=False,
        )
    )


if __name__ == "__main__":
    main()
