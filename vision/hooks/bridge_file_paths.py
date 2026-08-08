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
the proxy's job (scripts/vb_proxy.py). Together they give non-vision models
eyes in both scenarios, fully automatically.

Config (same progressive env resolution as the proxy; see vb_proxy.py):
    VB_HOOK_ENABLED       set to "0" to disable the hook's work (default "1")
    VB_VISION_BASE_URL    vision endpoint base URL (else VB_UPSTREAM_URL)
    VB_VISION_MODEL       vision model served by the gateway
    VB_VISION_API_KEY     key (else ANTHROPIC_AUTH_TOKEN / ANTHROPIC_API_KEY)
    VB_VISION_PROMPT      instruction sent with each image
    VB_MAX_IMAGE_BYTES    skip image files larger than this (default 20 MiB)
"""

from __future__ import annotations

import json
import os
import sys
from pathlib import Path

# Reuse the proxy's image handling (regex + local-file description).
sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "scripts"))
from vb_proxy import Cfg, _IMAGE_PATH_RE, _describe_local_file  # noqa: E402


def _noop() -> None:
    # Exit 0 with no additional context — pass the prompt through untouched.
    print(json.dumps({"hookSpecificOutput": {}}, ensure_ascii=False))


def main() -> None:
    try:
        data = json.load(sys.stdin)
    except (json.JSONDecodeError, OSError):
        return _noop()
    prompt = data.get("prompt") or ""
    if os.environ.get("VB_HOOK_ENABLED", "1") != "1" or not prompt:
        return _noop()

    # Build a describe-only config (never fall back to ANTHROPIC_BASE_URL, which
    # may already be the proxy itself).
    cfg = Cfg(load_env=False)
    cfg.vision_base = (
        os.environ.get("VB_VISION_BASE_URL") or os.environ.get("VB_UPSTREAM_URL") or ""
    ).rstrip("/")
    cfg.vision_model = os.environ.get("VB_VISION_MODEL") or "gemini-3.1-flash-image"
    cfg.vision_key = (
        os.environ.get("VB_VISION_API_KEY")
        or os.environ.get("ANTHROPIC_AUTH_TOKEN")
        or os.environ.get("ANTHROPIC_API_KEY")
        or ""
    )
    cfg.vision_prompt = (
        os.environ.get("VB_VISION_PROMPT")
        or "Describe this image faithfully and concretely: subject, layout, "
        "any text, and details relevant to the surrounding conversation."
    )
    cfg.describe_file_paths = True
    cfg.max_image_bytes = int(os.environ.get("VB_MAX_IMAGE_BYTES", str(20 * 1024 * 1024)))

    if not (cfg.vision_base and cfg.vision_key):
        return _noop()

    descriptions: list[str] = []
    for token in _IMAGE_PATH_RE.findall(prompt):
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
