#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = ["httpx>=0.27.0"]
# ///
"""Vision Bridge proxy — give non-vision models eyes via a gateway vision model.

Claude Code sends Anthropic Messages API requests to this proxy
(ANTHROPIC_BASE_URL pointing here). When the active model cannot see images
(a "non-vision" model, matched by nonVisionModels) and the request body
contains image blocks, the proxy describes each image with a vision-capable
model from an independent vision provider (model by default), replaces
the image block with the resulting text, and streams the request upstream. All
other requests pass through byte-for-byte.

Why a proxy and not a hook: a UserPromptSubmit hook cannot see or remove image
blocks from the outbound messages[] — the only interception point is the layer
ANTHROPIC_BASE_URL points at. Verified 2026-08 against the Claude Code hooks,
env-vars and LLM-gateway-protocol documentation (see the plugin README).

Configuration is read from three layers of `vision.json` files (process env
still wins over all of them; see the _load_config docstring):

    port                     listen port                          (default 8731)
    baseUrl                 upstream gateway base URL. If unset, ANTHROPIC_BASE_URL
                             at request time is used; when the proxy is itself the
                             ANTHROPIC_BASE_URL, this MUST be set explicitly.
    nonVisionModels          list or comma-separated string; replaced by `blockedModels`.
                             deprecated, kept for backward compatibility.
    blockedModels           list or comma-separated string; a request whose model
                             matches any is bridged (default ["deepseek"]). An
                             explicit empty list disables bridging.
    visionBaseUrl           INDEPENDENT vision provider base URL. Deprecated:
                             now uses `baseUrl` (the upstream gateway).
    model                   comma-separated fallback chain of vision models
                             (default "gemini-3.1-flash-image,gemini-3-flash-agent").
    apiKey                  key for the vision provider (required).
    prompt                  deprecated (built-in).
    describeFilePaths        also describe image file paths in text (default true).
    hookEnabled              false disables the UserPromptSubmit hook (default true).
    maxImageBytes            refuse to describe image files larger than this
                             (default 20971520 / 20 MiB).

Legacy flat `VB_*` env vars still work as overrides (VB_PORT, VB_UPSTREAM_URL,
VB_NON_VISION_MODELS, VB_VISION_BASE_URL, VB_VISION_MODEL, VB_VISION_API_KEY,
VB_VISION_PROMPT, VB_DESCRIBE_FILE_PATHS, VB_MAX_IMAGE_BYTES).

Legacy keys `upstreamUrl`, `upstream.url`, `visionBaseUrl`, `visionModel`,
`visionApiKey`, `visionPrompt`, `vision.baseUrl`, `vision.model`,
`vision.apiKey`, `vision.prompt` still work for backward compatibility.

Subcommands:
    serve            run the proxy in the foreground (the worker for `start`)
    start [--port N] detach a serve process, write a PID file, log to ~/.vb
    stop             terminate the process recorded in the PID file
    status           report whether the proxy is running
    doctor           verify configuration, upstream and vision endpoints
    describe PATH    describe a single local image (standalone utility)
"""

from __future__ import annotations

import argparse
import base64
import json
import mimetypes
import os
import re
import signal
import subprocess
import sys
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlparse

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
#     "upstream":      { "url": "http://gateway:8317" },
#     "nonVisionModels": ["deepseek"],                  // or "deepseek" string
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

    def __init__(self, *, port: int | None = None, load_env: bool = True) -> None:
        if not load_env:
            # Unit-test / describe-only path: everything must be explicit.
            self.port = port or 8731
            self.upstream = ""
            self.non_vision = []
            self.vision_base = ""
            self.vision_model = ""
            self.vision_key = ""
            self.vision_prompt = ""
            self.describe_file_paths = False
            self.max_image_bytes = 20 * 1024 * 1024
            return
        self.port = int(port or _env("VB_PORT") or _cfg_int("port") or 8731)
        self.upstream = (
            _env("VB_UPSTREAM_URL")
            or _cfg_str("baseUrl") or _cfg_str("upstreamUrl") or _cfg_str("upstream.url")
            or _env("ANTHROPIC_BASE_URL") or ""
        ).rstrip("/")
        # Strip trailing /v1 — the proxy appends its own path including /v1/
        if self.upstream.endswith("/v1"):
            self.upstream = self.upstream[:-3]

        # blockedModels: list or comma-separated string. Models matching any
        # substring are bridged (described via vision endpoint). An explicit
        # empty list disables bridging; absent falls back to ["deepseek"].
        bm = _cfg_raw("blockedModels") or _cfg_raw("nonVisionModels")
        if bm is not None:
            if isinstance(bm, list):
                self.non_vision = [str(s).strip() for s in bm if str(s).strip()]
            else:
                self.non_vision = [s.strip() for s in str(bm).split(",") if s.strip()]
        else:
            self.non_vision = ["deepseek"]

        # Vision provider reuses the upstream gateway. Flat keys preferred;
        # dotted fallback for backward compatibility.
        self.vision_base = self.upstream or ""
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

    @property
    def listens(self) -> tuple[str, int]:
        return "127.0.0.1", self.port

    def should_bridge(self, model: str) -> bool:
        """Blacklist match: bridge when the model matches any configured substring."""
        if not self.non_vision or not model:
            return False
        m = model.lower()
        return any(sub.lower() in m for sub in self.non_vision)

    def loop_detected(self) -> bool:
        """True when the configured upstream is this proxy itself."""
        try:
            up = urlparse(self.upstream)
        except ValueError:
            return False
        if not up.hostname:
            return False
        host, port = up.hostname, up.port or 80
        return host in ("127.0.0.1", "localhost", "::1") and port == self.port

    def errors(self) -> list[str]:
        errs: list[str] = []
        if not self.upstream:
            errs.append("baseUrl (or ANTHROPIC_BASE_URL) is not set — no upstream to forward to.")
        elif self.loop_detected():
            errs.append(
                f"baseUrl points at this proxy ({self.upstream}). "
                "Set baseUrl to the real gateway (the value ANTHROPIC_BASE_URL had before the proxy)."
            )
        # Vision config only matters when bridging is enabled; a passthrough-only
        # setup (nonVisionModels: []) must be able to start without it.
        if self.non_vision:
            if not self.vision_base:
                errs.append("No vision endpoint: set baseUrl (upstream gateway).")
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
    so a fallback chain keeps bridging alive.
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


# --- request rewriting -------------------------------------------------------- #
def rewrite_body(body: dict, cfg: Cfg) -> tuple[dict, list[dict]]:
    """Replace image blocks with vision-described text. Returns (body, audit list)."""
    audit: list[dict] = []
    model = body.get("model", "")
    if not cfg.should_bridge(model):
        return body, audit
    messages = body.get("messages", [])
    for msg in messages:
        content = msg.get("content")
        if isinstance(content, str):
            if cfg.describe_file_paths:
                descs: list[str] = []
                for token in _find_image_paths(content):
                    res = _describe_local_file(token, cfg)
                    if res:
                        desc, fpath = res
                        audit.append({"type": "file", "path": fpath})
                        descs.append(desc)
                if descs:
                    msg["content"] = content + "\n\n" + "\n\n".join(descs)
            continue
        if not isinstance(content, list):
            continue
        msg["content"] = _rewrite_content_list(content, cfg, audit)
    return body, audit


def _rewrite_content_list(
    blocks: list, cfg: Cfg, audit: list[dict], label: str = ""
) -> list:
    """Rewrite image blocks in a nested content list (e.g. inside tool_result)."""
    out: list = []
    image_no = 0
    image_count = sum(1 for b in blocks if isinstance(b, dict) and b.get("type") == "image")
    for block in blocks:
        if not isinstance(block, dict):
            out.append(block)
            continue
        if block.get("type") == "image":
            image_no += 1
            try:
                src = block.get("source", {})
                data = src.get("data", "")
                media = src.get("media_type", "image/png")
                text = describe_image(data, media, cfg, index=image_no, total=image_count)
                audit.append({"type": "image", "media_type": media, "replaced_with": len(text), "in": label or "message"})
                out.append({"type": "text", "text": text})
            except Exception as exc:
                audit.append({"type": "image", "error": str(exc)})
                out.append(
                    {"type": "text", "text": f"[Image block: description failed ({exc}) — image was removed.]"}
                )
            continue
        if block.get("type") == "text" and cfg.describe_file_paths:
            out.append(block)
            text = block.get("text", "")
            for token in _find_image_paths(text):
                res = _describe_local_file(token, cfg)
                if res:
                    desc, fpath = res
                    audit.append({"type": "file", "path": fpath})
                    out.append({"type": "text", "text": desc})
            continue
        if block.get("type") == "tool_result":
            inner = block.get("content")
            if isinstance(inner, list):
                block = dict(block)
                block["content"] = _rewrite_content_list(inner, cfg, audit, label="tool_result")
            out.append(block)
            continue
        out.append(block)
    return out


# --- HTTP server -------------------------------------------------------------- #
class ProxyHandler(BaseHTTPRequestHandler):
    cfg: Cfg  # set by the server factory

    protocol_version = "HTTP/1.1"
    server_version = "VisionBridge/0.1"

    def log_message(self, fmt: str, *args):  # quiet by default
        if os.environ.get("VB_DEBUG"):
            sys.stderr.write("[vb] " + (fmt % args) + "\n")

    def _do(self) -> None:
        if self.path == "/__health":
            self._send(200, "application/json", json.dumps({"ok": True}).encode())
            return
        upstream = self.cfg.upstream
        if not upstream:
            self._send(500, "application/json", json.dumps({"error": "no upstream configured"}).encode())
            return
        body_bytes = self.rfile.read(int(self.headers.get("Content-Length") or 0))
        path = self.path
        body = None
        headers_out = dict(self.headers.items())
        # Case-insensitive: Node/undici clients (Claude Code) send lowercase headers.
        content_type = self.headers.get_content_type()

        # Only Messages POST bodies are candidates for image rewriting.
        if self.command == "POST" and content_type.startswith("application/json") and body_bytes:
            try:
                body = json.loads(body_bytes.decode("utf-8"))
            except (UnicodeDecodeError, json.JSONDecodeError):
                body = None
            if body is not None:
                body, audit = rewrite_body(body, self.cfg)
                if audit:
                    new_bytes = json.dumps(body).encode()
                    # Content-Length changes; strip so the upstream trusts the new body.
                    headers_out.pop("Content-Length", None)
                    headers_out.pop("content-length", None)
                    body_bytes = new_bytes
                    sys.stderr.write(f"[vb] bridged {len(audit)} image(s) for model {body.get('model')!r}\n")
                    for item in audit:
                        sys.stderr.write(f"[vb]   {item}\n")

        stream = body.get("stream", False) if isinstance(body, dict) else False
        headers_out.setdefault("Content-Length", str(len(body_bytes)))
        # The upstream must see its own host, not the proxy's.
        headers_out["Host"] = urlparse(upstream).netloc
        url = f"{upstream}{path}"
        try:
            with httpx.Client(timeout=300) as client:
                with client.stream(
                    self.command, url, content=body_bytes, headers=headers_out
                ) as up:
                    ctype = up.headers.get("content-type", "")
                    is_stream = "text/event-stream" in ctype or stream
                    # content-encoding must be dropped: httpx already decodes the
                    # body, so forwarding the header would make the client gunzip
                    # already-decoded bytes.
                    skip = {"content-length", "transfer-encoding", "connection", "host", "content-encoding"}
                    if is_stream:
                        self.send_response(up.status_code)
                        for key, value in up.headers.items():
                            if key.lower() in skip:
                                continue
                            self.send_header(key, value)
                        self.send_header("Transfer-Encoding", "chunked")
                        self.end_headers()
                        for chunk in up.iter_bytes():
                            if not chunk:
                                continue
                            self.wfile.write(f"{len(chunk):X}\r\n".encode("ascii") + chunk + b"\r\n")
                            self.wfile.flush()
                        self.wfile.write(b"0\r\n\r\n")
                        self.wfile.flush()
                    else:
                        payload = up.read()
                        self.send_response(up.status_code)
                        for key, value in up.headers.items():
                            if key.lower() in skip:
                                continue
                            self.send_header(key, value)
                        self.send_header("Content-Length", str(len(payload)))
                        self.end_headers()
                        self.wfile.write(payload)
        except Exception as exc:
            sys.stderr.write(f"[vb] forward error: {exc}\n")
            try:
                self._send(502, "application/json", json.dumps({"type": "error", "error": {"type": "api_error", "message": f"vision-bridge forward error: {exc}"}}).encode())
            except Exception:
                pass

    def _send(self, code: int, ctype: str, data: bytes) -> None:
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    do_GET = do_POST = do_PUT = do_PATCH = do_DELETE = _do


def serve(port: int, cfg: Cfg | None = None) -> None:
    cfg = cfg or Cfg()
    errs = cfg.errors()
    if errs:
        for e in errs:
            print(f"Error: {e}", file=sys.stderr)
        raise SystemExit(1)

    class QuietServer(ThreadingHTTPServer):
        def handle_error(self, request, client_address):
            # Client aborts (broken pipe / connection reset) are normal for
            # streaming; don't log a scary traceback for them.
            typ = sys.exc_info()[0]
            if typ is not None and issubclass(typ, (BrokenPipeError, ConnectionResetError, ConnectionAbortedError)):
                return
            super().handle_error(request, client_address)

    server = QuietServer(cfg.listens, ProxyHandler)
    ProxyHandler.cfg = cfg
    print(f"[vb] listening on {cfg.listens[0]}:{cfg.listens[1]} -> {cfg.upstream}", flush=True)
    print(f"[vb] bridging models matching: {cfg.non_vision or '(disabled)'}; vision model {cfg.vision_model}", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass


# --- process management ------------------------------------------------------- #
def _runtime_dir() -> Path:
    d = Path.home() / ".vb"
    d.mkdir(parents=True, exist_ok=True)
    return d


def _pid_file() -> Path:
    return _runtime_dir() / "proxy.pid"


def _log_file() -> Path:
    return _runtime_dir() / "proxy.log"


def _pid_alive(pid: int) -> bool:
    try:
        os.kill(pid, 0)
        return True
    except ProcessLookupError:
        return False
    except PermissionError:
        return True  # running, just not ours to signal


def cmd_start(port: int) -> int:
    # Refuse to clobber a running proxy.
    pid_file = _pid_file()
    if pid_file.is_file():
        old_pid = int(pid_file.read_text().strip())
        if _pid_alive(old_pid):
            print(f"[vb] already running (pid {old_pid}). Stop it first, or the PID file is stale.")
            return 1
        pid_file.unlink(missing_ok=True)
    # Validate config before spawning so a bad setup fails fast in the foreground.
    errs = Cfg(port=port).errors()
    if errs:
        for e in errs:
            print(f"Error: {e}", file=sys.stderr)
        print("Run `vision_proxy.py doctor` for details.", file=sys.stderr)
        return 1
    # Inherit env so VB_* and ANTHROPIC_* resolve inside the child.
    env = dict(os.environ)
    argv = [sys.executable, str(Path(__file__).resolve()), "serve"]
    if port is not None:
        argv += ["--port", str(port)]
    pid = subprocess.Popen(
        argv,
        env=env,
        stdout=open(_log_file(), "a"),
        stderr=subprocess.STDOUT,
        start_new_session=True,
    ).pid
    _pid_file().write_text(str(pid))
    # Give the child a moment to bind the port, then confirm it survived.
    time.sleep(0.5)
    if not _pid_alive(pid):
        print(f"[vb] started pid {pid} but it exited immediately. Check {_log_file()}.")
        return 1
    print(f"[vb] started pid {pid} on 127.0.0.1:{port or 8731}")
    print(f"[vb] log: {_log_file()}")
    return 0


def cmd_stop() -> int:
    pid_file = _pid_file()
    if not pid_file.is_file():
        print("[vb] not running (no pid file)")
        return 1
    pid = int(pid_file.read_text().strip())
    try:
        os.kill(pid, signal.SIGTERM)
        print(f"[vb] stopped pid {pid}")
    except ProcessLookupError:
        print(f"[vb] pid {pid} already gone")
    except PermissionError:
        print(f"[vb] no permission to signal pid {pid}")
        return 1
    pid_file.unlink(missing_ok=True)
    return 0


def cmd_status() -> int:
    pid_file = _pid_file()
    if pid_file.is_file():
        pid = int(pid_file.read_text().strip())
        try:
            os.kill(pid, 0)
            print(f"[vb] running (pid {pid})")
            return 0
        except ProcessLookupError:
            print("[vb] pid file exists but process is gone")
            return 1
    print("[vb] not running")
    return 1


def cmd_doctor() -> int:
    cfg = Cfg()
    print("== Vision Bridge config ==")
    for key, val in {
        "port": cfg.port,
        "baseUrl": cfg.upstream or "(unset)",
        "blockedModels": cfg.non_vision or "(bridging disabled)",
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
        upstream_key = os.environ.get("ANTHROPIC_AUTH_TOKEN") or os.environ.get("ANTHROPIC_API_KEY") or ""
        if cfg.upstream:
            print(f"  upstream POST {cfg.upstream}/v1/messages (Anthropic) ...")
            try:
                with httpx.Client(timeout=10) as c:
                    r = c.post(
                        f"{cfg.upstream}/v1/messages",
                        json={"model": "ping", "max_tokens": 1, "messages": [{"role": "user", "content": "ping"}]},
                        headers={"Authorization": f"Bearer {upstream_key}", "anthropic-version": "2023-06-01"},
                    )
                print(f"    HTTP {r.status_code}")
                ok = ok and r.status_code in (200, 400)  # 400 = reachable, model rejected
            except Exception as exc:
                print(f"    failed: {exc}")
                ok = False
        if cfg.vision_base:
            base = cfg.vision_base.rstrip("/")
            vurl = f"{base}/v1/chat/completions" if not base.endswith("/v1") else f"{base}/chat/completions"
            print(f"  vision POST {vurl} ...")
            try:
                with httpx.Client(timeout=10) as c:
                    r = c.post(
                        vurl,
                        json={"model": cfg.vision_model, "messages": [{"role": "user", "content": "ping"}]},
                        headers={"Authorization": f"Bearer {cfg.vision_key}"},
                    )
                print(f"    HTTP {r.status_code}")
                ok = ok and r.status_code == 200
            except Exception as exc:
                print(f"    failed: {exc}")
                ok = False
    return 0 if ok else 1


def cmd_describe(path: str, prompt: str | None) -> int:
    # Use the full layered config so vision.* (independent provider) applies.
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


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(prog="vision_proxy", description="Vision Bridge proxy")
    sub = ap.add_subparsers(dest="cmd", required=True)
    sub.add_parser("serve").add_argument("--port", type=int, default=None)
    p_start = sub.add_parser("start")
    p_start.add_argument("--port", type=int, default=None)
    sub.add_parser("stop")
    sub.add_parser("status")
    sub.add_parser("doctor")
    p_desc = sub.add_parser("describe")
    p_desc.add_argument("path")
    p_desc.add_argument("--prompt", default=None)
    args = ap.parse_args(argv)

    if args.cmd == "serve":
        _serve_with_port(args.port)
        return 0
    if args.cmd == "start":
        return cmd_start(args.port)
    if args.cmd == "stop":
        return cmd_stop()
    if args.cmd == "status":
        return cmd_status()
    if args.cmd == "doctor":
        return cmd_doctor()
    if args.cmd == "describe":
        return cmd_describe(args.path, args.prompt)
    return 2


def _serve_with_port(port: int | None) -> None:
    cfg = Cfg(port=port)
    serve(cfg.port, cfg)


if __name__ == "__main__":
    raise SystemExit(main())
