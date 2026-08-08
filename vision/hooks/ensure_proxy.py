#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# ///
"""SessionStart hook: ensure the vision proxy is running.

The proxy (scripts/vision_proxy.py) is the only layer that can rewrite
pasted-screenshot image blocks before they reach the upstream gateway — a
UserPromptSubmit hook cannot see or remove image blocks from the outbound
messages[]. So for screenshots to work, the proxy must be up when the session
starts. This hook starts it if it is not already running.

Notes:
- It never blocks the session: any failure (missing vision config, proxy crash,
  uv not on PATH) is swallowed and the session proceeds normally.
- It does not (and cannot) change the session's own ANTHROPIC_BASE_URL — that is
  read at process startup. Pointing requests at the proxy must be done at launch
  (see the plugin README).
- VB_HOOK_ENABLED=0 skips the proxy check too.
"""

from __future__ import annotations

import json
import os
import subprocess
import sys
from pathlib import Path

_PROXY = Path(__file__).resolve().parent.parent / "scripts" / "vision_proxy.py"


def _proxy_alive() -> bool:
    """True when `vision_proxy.py status` exits 0 (proxy running)."""
    st = subprocess.run(
        [str(_PROXY), "status"],
        capture_output=True,
        text=True,
        timeout=15,
    )
    return st.returncode == 0


def main() -> int:
    # Drain stdin — SessionStart hook input; not needed here but must be read.
    try:
        sys.stdin.read()
    except Exception:
        pass

    if os.environ.get("VB_HOOK_ENABLED") == "0":
        return 0

    try:
        if _proxy_alive():
            return 0
        # start is detached + idempotent; validates config up front and fails
        # fast with non-zero exit if vision setup is broken.
        subprocess.run(
            [str(_PROXY), "start"],
            capture_output=True,
            text=True,
            timeout=30,
        )
    except Exception:
        pass  # never block the session
    return 0


if __name__ == "__main__":
    sys.exit(main())
