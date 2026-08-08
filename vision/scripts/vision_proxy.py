#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = ["httpx>=0.27.0"]
# ///
"""Vision helper — describe images for non-vision models.

Two entry points share one config and one describe engine:

- The UserPromptSubmit hook (`hooks/bridge_file_paths.py`) imports the describe
  functions here to auto-describe image file paths mentioned in prompts.
- The `describe` subcommand describes a single local image on demand.

The on-demand describe goes to an independent vision provider (OpenAI-compatible
endpoint) configured under the three-layer `vision.json` — never the Claude Code
gateway credentials.

Why no proxy: pasted screenshots (image blocks) were previously bridged by a
transparent local proxy that replaced image blocks with vision-described text.
That layer is removed — non-vision models (deepseek) cannot receive pasted
screenshots; use a vision-capable model or describe the file path instead.

Configuration is read from three layers of `vision.json` files (process env
still wins over all of them; see the _load_config docstring):

    port                     unused (kept for config compatibility)
    baseUrl                  vision provider base URL (OpenAI-compatible).
    model                    comma-separated fallback chain of vision models
                             (default "gemini-3.1-flash-image,gemini-3-flash-agent").
    apiKey                   key for the vision provider (required).
    describeFilePaths        also describe image file paths in text (default true).
    maxImageBytes            refuse to describe image files larger than this
                             (default 20971520 / 20 MiB).

Legacy flat `VB_*` env vars still work as overrides (VB_PORT, VB_VISION_BASE_URL,
VB_VISION_MODEL, VB_VISION_API_KEY, VB_VISION_PROMPT, VB_DESCRIBE_FILE_PATHS,
VB_MAX_IMAGE_BYTES).

Legacy keys `visionBaseUrl`, `visionModel`, `visionApiKey`, `visionPrompt`,
`vision.baseUrl`, `vision.model`, `vision.apiKey`, `vision.prompt` still work for
backward compatibility.

Subcommands:
    describe PATH    describe a single local image (standalone utility)
    doctor           verify configuration and the vision endpoint
"""

from __future__ import annotations

import argparse
import base64
import json
import mimetypes
import os
import re
import sys
from pathlib import Path

import httpx

# --- progressive config resolution (env -> layered vision.json -> default) --- #
#
# Config lives in `vision.json` files, read from three layers mirroring Claude
# Code's settings, later layers overriding earlier ones (highest priority last):
#
#   1. ~/.claude/vision.json           — global, user-wide
#   2. <project>/.claude/vision.json   — per-project, checked in
#   3. <project>/.claude/vision.local.json  — per-project, gitignored
#
# Each file is a nested JSON object:
#   {
#     "vision":        { "model": "...", "prompt": "...", "apiKey": "...",
#                        "baseUrl": "..." },
#     "maxImageBytes": 20971520,
#     "describeFilePaths": true,
#     "port": 8731
#   }
#
# Legacy flat `VB_*` env vars still work and win over every JSON layer.
_CONFIG: dict | None = None


def _load_config() -> dict:
    """Read the three vision config layers into one merged dict (deep merge)."""
    global _CONFIG
    if _CONFIG is not None:
        return _CONFIG
    merged: dict = {}

    def expand(value):
        """Resolve `$VAR` and `${VAR}` strings against the process environment.
        Handles embedded vars too (e.g. \"http://$BASE_URL/path\")."""
        if isinstance(value, str):
            import re
            result = value
            for match in re.finditer(r'\$\{?(\w+)\}?', value):
                var_name = match.group(1)
                var_value = os.environ.get(var_name, "")
                result = result.replace(match.group(0), var_value)
            return result
        if isinstance(value, dict):
            return {k: expand(v) for k, v in value.items()}
        if isinstance(value, list):
            return [expand(v) for v in value]
        return value

    def merge_file(path: Path) -> None:
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            return
        if not isinstance(data, dict):
            return
        data = expand(data)
        # Deep-merge nested dicts so a layer can override one vision sub-key.
        for key, value in data.items():
            if isinstance(value, dict) and isinstance(merged.get(key), dict):
                merged[key].update(value)
            else:
                merged[key] = value

    # Lowest priority first; later files override earlier ones.
    merge_file(Path.home() / ".claude" / "vision.json")
    merge_file(Path.home() / ".claude" / "vision.local.json")
    for d in [Path.cwd(), *Path.cwd().parents]:
        if (d / ".claude").is_dir():
            merge_file(d / ".claude" / "vision.json")
            merge_file(d / ".claude" / "vision.local.json")
            break

    _CONFIG = merged
    return merged


def _env(name: str, default: str | None = None) -> str | None:
    """Legacy env lookup; kept for VB_* compatibility (env always wins)."""
    val = os.environ.get(name)
    if val:
        return val
    return default


def _cfg_raw(path: str):
    """Dotted-path lookup into the layered vision.json (e.g. "vision.baseUrl")."""
    node: object = _load_config()
    for part in path.split("."):
        if not isinstance(node, dict):
            return None
        node = node.get(part)
    return node


def _cfg_str(path: str) -> str | None:
    val = _cfg_raw(path)
    if isinstance(val, (str, int, float, bool)):
        return str(val)
    return None


def _cfg_int(path: str) -> int | None:
    val = _cfg_raw(path)
    if isinstance(val, int):
        return val
    if isinstance(val, str) and val.strip().isdigit():
        return int(val)
    return None


def _cfg_bool(path: str) -> bool | None:
    val = _cfg_raw(path)
    if isinstance(val, bool):
        return val
    if isinstance(val, str):
        return val.strip().lower() in ("1", "true", "yes")
    return None


class Cfg:
    """Snapshot of the runtime configuration."""

    def __init__(self, *, load_env: bool = True) -> None:
        if not load_env:
            # Unit-test / describe-only path: everything must be explicit.
            self.vision_base = ""
            self.vision_model = ""
            self.vision_key = ""
            self.vision_prompt = ""
            self.describe_file_paths = False
            self.max_image_bytes = 20 * 1024 * 1024
            return
        # Vision provider is an independent OpenAI-compatible endpoint. Flat keys
        # preferred; dotted fallback for backward compatibility.
        self.vision_base = (
            _env("VB_VISION_BASE_URL")
            or _cfg_str("baseUrl") or _cfg_str("visionBaseUrl") or _cfg_str("vision.baseUrl")
            or ""
        ).rstrip("/")
        self.vision_model = (
            _env("VB_VISION_MODEL")
            or _cfg_str("model") or _cfg_str("visionModel") or _cfg_str("vision.model")
            or "gemini-3.1-flash-image,gemini-3-flash-agent"
        )
        self.vision_key = (
            _env("VB_VISION_API_KEY")
            or _cfg_str("apiKey") or _cfg_str("visionApiKey") or _cfg_str("vision.apiKey")
            or ""
        )
        self.vision_prompt = (
            "Describe this image faithfully and concretely: subject, layout, "
            "any text, and details relevant to the surrounding conversation. "
            "Reply in the same language as the conversation."
        )
        dfp_env = _env("VB_DESCRIBE_FILE_PATHS")
        self.describe_file_paths = (
            (dfp_env.strip().lower() in ("1", "true", "yes"))
            if dfp_env is not None
            else (_cfg_bool("describeFilePaths") if _cfg_raw("describeFilePaths") is not None else True)
        )
        self.max_image_bytes = int(
            _env("VB_MAX_IMAGE_BYTES") or str(_cfg_int("maxImageBytes") or 20 * 1024 * 1024)
        )

    def errors(self) -> list[str]:
        errs: list[str] = []
        if not self.vision_base:
            errs.append("No vision endpoint: set baseUrl.")
        if not self.vision_key:
            errs.append("No vision key: set apiKey.")
        if not self.vision_model:
            errs.append("No vision model: set model.")
        return errs

    @property
    def vision_models(self) -> list[str]:
        """The vision model fallback chain (comma-separated), in order."""
        return [m.strip() for m in self.vision_model.split(",") if m.strip()]


# --- vision description ------------------------------------------------------- #
# Match image paths. A path must lead with a path separator (/ . ~ or a drive
# letter); the (?:^|[\s("'\[]) prefix consumes the delimiter so prose like
# "what is in" is never matched. Allows spaces and balanced parens inside the
# path. Use _find_image_paths() — it returns capture group 1 (the path only).
# Paths may contain at most ONE space (a common "file name.png" form). This
# keeps "a b.png" matched while not swallowing "and/or" between two paths.
_IMAGE_PATH_RE = re.compile(
    r"(?:^|[\s(\[,'\"])"
    r"((?:~/|\.{1,2}/|/|[A-Za-z]:[\\/])[\w./\\~()-]*(?: [\w./\\~()-]+)?"
    r"\.(?:png|jpe?g|gif|webp|bmp))",
    re.IGNORECASE,
)


def _find_image_paths(text: str) -> list[str]:
    """Extract image-file path candidates from text (capture-group aware)."""
    return [m.group(1) for m in _IMAGE_PATH_RE.finditer(text)]


def _mime_for(path: Path, fallback: str) -> str:
    mime = mimetypes.guess_type(str(path))[0]
    return mime or fallback


def describe_image(data: str, media_type: str, cfg: Cfg, index: int = 1, total: int = 1) -> str:
    """Describe one base64 image via the vision endpoint (OpenAI-compatible).

    Tries each model in the `cfg.vision_models` chain in order; the first that
    returns a description wins. A gateway can rate-limit or cool down a model,
    so a fallback chain keeps describing alive.
    """
    if not media_type.startswith("image/"):
        media_type = f"image/{media_type.lstrip('.')}" if media_type else "image/png"
    base = cfg.vision_base.rstrip("/")
    # Accept both "host:port/v1" (OpenAI_BASE_URL style) and "host:port".
    url = f"{base}/v1/chat/completions" if not base.endswith("/v1") else f"{base}/chat/completions"
    headers = {"Authorization": f"Bearer {cfg.vision_key}", "Content-Type": "application/json"}
    models = cfg.vision_models
    last_err: Exception | None = None
    for model in models:
        payload = {
            "model": model,
            "messages": [
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": cfg.vision_prompt},
                        {"type": "image_url", "image_url": {"url": f"data:{media_type};base64,{data}"}},
                    ],
                }
            ],
        }
        try:
            with httpx.Client(timeout=120) as client:
                resp = client.post(url, json=payload, headers=headers)
            resp.raise_for_status()
            body = resp.json()
            content = body.get("choices", [{}])[0].get("message", {}).get("content", "")
            if content:
                label = f"[Image {index}/{total} ({media_type}, described by {model})]"
                return f"{label}\n{content}"
            last_err = RuntimeError(f"vision model returned no text: {body!r}")
        except Exception as exc:  # try the next model in the chain
            last_err = exc
            continue
    raise RuntimeError(f"all vision models failed ({', '.join(models)}): {last_err}")


def _describe_local_file(path_str: str, cfg: Cfg) -> tuple[str, str] | None:
    """Describe a local image file by path; return (text, file_path) or None."""
    try:
        p = Path(path_str).expanduser()
    except (OSError, RuntimeError):
        return None
    if not p.is_file():
        return None
    if p.stat().st_size > cfg.max_image_bytes:
        return None
    mime = _mime_for(p, "image/png")
    if not mime.startswith("image/"):
        return None
    try:
        data = base64.b64encode(p.read_bytes()).decode()
    except OSError:
        return None
    text = describe_image(data, mime, cfg)
    return text, str(p)


def cmd_describe(path: str, prompt: str | None) -> int:
    cfg = Cfg(load_env=True)
    if prompt:
        cfg.vision_prompt = prompt
    if not cfg.vision_base:
        print("Error: no vision endpoint — set baseUrl in vision.json.", file=sys.stderr)
        return 1
    if not cfg.vision_key:
        print("Error: no vision key — set apiKey in vision.json.", file=sys.stderr)
        return 1
    p = Path(path).expanduser()
    if not p.is_file():
        print(f"Error: file not found: {path}", file=sys.stderr)
        return 1
    if p.stat().st_size > cfg.max_image_bytes:
        print(f"Error: file too large ({p.stat().st_size} bytes > {cfg.max_image_bytes} maxImageBytes).", file=sys.stderr)
        return 1
    mime = _mime_for(p, "image/png")
    data = base64.b64encode(p.read_bytes()).decode()
    print(describe_image(data, mime, cfg))
    return 0


def cmd_doctor() -> int:
    cfg = Cfg()
    print("== Vision config ==")
    for key, val in {
        "baseUrl": cfg.vision_base or "(unset)",
        "model": cfg.vision_model,
        "apiKey": ("set" if cfg.vision_key else "(unset)"),
        "describeFilePaths": cfg.describe_file_paths,
    }.items():
        print(f"  {key} = {val}")
    errs = cfg.errors()
    ok = True
    if errs:
        ok = False
        print("Errors:")
        for e in errs:
            print(f"  - {e}")
    if ok:
        print("Configuration: OK")
        if cfg.vision_base:
            base = cfg.vision_base.rstrip("/")
            vurl = f"{base}/v1/chat/completions" if not base.endswith("/v1") else f"{base}/chat/completions"
            print(f"  vision POST {vurl} ...")
            # Probe each model in the fallback chain; one success is enough.
            models = cfg.vision_models
            tried = 0
            for model in models:
                try:
                    with httpx.Client(timeout=10) as c:
                        r = c.post(
                            vurl,
                            json={"model": model, "messages": [{"role": "user", "content": "ping"}]},
                            headers={"Authorization": f"Bearer {cfg.vision_key}"},
                        )
                    tried += 1
                    print(f"    {model}: HTTP {r.status_code}")
                    if r.status_code == 200:
                        ok = True
                        break
                    ok = False
                except Exception as exc:
                    tried += 1
                    print(f"    {model}: failed: {exc}")
                    ok = False
            if not models:
                print("    (no models configured)")
                ok = False
            elif not tried:
                print("    (probe skipped)")
    return 0 if ok else 1


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(prog="vision_proxy", description="Vision helper (describe + doctor)")
    sub = ap.add_subparsers(dest="cmd", required=True)
    sub.add_parser("doctor")
    p_desc = sub.add_parser("describe")
    p_desc.add_argument("path")
    p_desc.add_argument("--prompt", default=None)
    args = ap.parse_args(argv)

    if args.cmd == "doctor":
        return cmd_doctor()
    if args.cmd == "describe":
        return cmd_describe(args.path, args.prompt)
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
