#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = ["httpx>=0.27.0"]
# ///
"""Vision Bridge proxy — give non-vision models eyes via a gateway vision model.

Claude Code sends Anthropic Messages API requests to this proxy
(ANTHROPIC_BASE_URL pointing here). When the active model cannot see images
(a "non-vision" model, matched by VB_NON_VISION_MODELS) and the request body
contains image blocks, the proxy describes each image with a vision-capable
model on the upstream gateway (gemini-3.1-flash-image by default), replaces the
image block with the resulting text, and streams the request upstream. All
other requests pass through byte-for-byte.

Why a proxy and not a hook: a UserPromptSubmit hook cannot see or remove image
blocks from the outbound messages[] — the only interception point is the layer
ANTHROPIC_BASE_URL points at. Verified 2026-08 against the Claude Code hooks,
env-vars and LLM-gateway-protocol documentation (see the plugin README).

Configuration (each resolved progressively — process env, then `.vb.env` files
searched as script dir, cwd, and home (home wins), then default):

    VB_PORT                 listen port                              (default 8731)
    VB_UPSTREAM_URL         upstream gateway base URL. If unset, the value of
                            ANTHROPIC_BASE_URL at the moment the request is
                            handled is used. When the proxy itself is the
                            ANTHROPIC_BASE_URL, this MUST be set explicitly.
    VB_NON_VISION_MODELS    comma-separated substrings; a request whose model
                            contains any substring is bridged (default: deepseek).
                            Empty string disables bridging entirely.
    VB_VISION_BASE_URL      vision endpoint base URL (default: VB_UPSTREAM_URL).
    VB_VISION_MODEL         vision model served by the gateway (default:
                            gemini-3.1-flash-image).
    VB_VISION_API_KEY       key for the vision endpoint (default:
                            ANTHROPIC_AUTH_TOKEN, else ANTHROPIC_API_KEY).
    VB_VISION_PROMPT        instruction sent with each image (default: describe
                            the image faithfully, in the conversation language).
    VB_DESCRIBE_FILE_PATHS  also describe image file paths found in text blocks
                            that exist on disk (default: 1).
    VB_MAX_IMAGE_BYTES      refuse to describe an image file larger than this
                            (default: 20971520 / 20 MiB).

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

# --- progressive config resolution (env -> .env -> default) ------------------ #
_DOTENV: dict[str, str] | None = None


def _load_dotenv() -> dict[str, str]:
    global _DOTENV
    if _DOTENV is not None:
        return _DOTENV
    merged: dict[str, str] = {}
    for d in (Path(__file__).resolve().parent, Path.cwd(), Path.home()):
        env_file = d / ".vb.env"
        if env_file.is_file():
            for raw in env_file.read_text(encoding="utf-8").splitlines():
                line = raw.strip()
                if not line or line.startswith("#") or "=" not in line:
                    continue
                key, _, value = line.partition("=")
                merged[key.strip()] = value.strip().strip('"').strip("'")
    _DOTENV = merged
    return merged


def _env(name: str, default: str | None = None) -> str | None:
    val = os.environ.get(name)
    if val:
        return val
    val = _load_dotenv().get(name)
    if val:
        return val
    return default


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
        self.port = int(port or _env("VB_PORT", "8731") or 8731)
        self.upstream = (_env("VB_UPSTREAM_URL") or _env("ANTHROPIC_BASE_URL") or "").rstrip("/")
        # An explicitly-set empty string disables bridging (fall back to the
        # default only when the variable is absent entirely).
        non_vision_raw = os.environ.get("VB_NON_VISION_MODELS")
        if non_vision_raw is None:
            non_vision_raw = _load_dotenv().get("VB_NON_VISION_MODELS")
        self.non_vision = [
            s.strip()
            for s in (non_vision_raw if non_vision_raw is not None else "deepseek").split(",")
            if s.strip()
        ]
        self.vision_base = (_env("VB_VISION_BASE_URL") or self.upstream or "").rstrip("/")
        self.vision_model = _env("VB_VISION_MODEL", "gemini-3.1-flash-image") or "gemini-3.1-flash-image"
        self.vision_key = _env("VB_VISION_API_KEY") or _env("ANTHROPIC_AUTH_TOKEN") or _env("ANTHROPIC_API_KEY") or ""
        self.vision_prompt = (
            _env(
                "VB_VISION_PROMPT",
                "Describe this image faithfully and concretely: subject, layout, "
                "any text, and details relevant to the surrounding conversation. "
                "Reply in the same language as the conversation.",
            )
            or ""
        )
        self.describe_file_paths = (_env("VB_DESCRIBE_FILE_PATHS", "1") or "1") == "1"
        self.max_image_bytes = int(_env("VB_MAX_IMAGE_BYTES", str(20 * 1024 * 1024)) or str(20 * 1024 * 1024))

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
            errs.append("VB_UPSTREAM_URL (or ANTHROPIC_BASE_URL) is not set — no upstream to forward to.")
        elif self.loop_detected():
            errs.append(
                f"VB_UPSTREAM_URL points at this proxy ({self.upstream}). "
                "Set VB_UPSTREAM_URL to the real gateway (the value ANTHROPIC_BASE_URL had before the proxy)."
            )
        # Vision config only matters when bridging is enabled; a passthrough-only
        # setup (VB_NON_VISION_MODELS="") must be able to start without it.
        if self.non_vision:
            if not self.vision_base:
                errs.append("No vision endpoint: set VB_VISION_BASE_URL or VB_UPSTREAM_URL.")
            if not self.vision_key:
                errs.append("No vision key: set VB_VISION_API_KEY, ANTHROPIC_AUTH_TOKEN, or ANTHROPIC_API_KEY.")
            if not self.vision_model:
                errs.append("No vision model: set VB_VISION_MODEL.")
        return errs


# --- vision description ------------------------------------------------------- #
_IMAGE_PATH_RE = re.compile(r"[\w./\\~-]+\.(?:png|jpe?g|gif|webp|bmp)", re.IGNORECASE)


def _mime_for(path: Path, fallback: str) -> str:
    mime = mimetypes.guess_type(str(path))[0]
    return mime or fallback


def describe_image(data: str, media_type: str, cfg: Cfg, index: int = 1, total: int = 1) -> str:
    """Describe one base64 image via the vision endpoint (OpenAI-compatible)."""
    if not media_type.startswith("image/"):
        media_type = f"image/{media_type.lstrip('.')}" if media_type else "image/png"
    url = f"{cfg.vision_base}/v1/chat/completions"
    payload = {
        "model": cfg.vision_model,
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
    headers = {"Authorization": f"Bearer {cfg.vision_key}", "Content-Type": "application/json"}
    with httpx.Client(timeout=120) as client:
        resp = client.post(url, json=payload, headers=headers)
    resp.raise_for_status()
    body = resp.json()
    content = body.get("choices", [{}])[0].get("message", {}).get("content", "")
    if not content:
        raise RuntimeError(f"vision model returned no text: {body!r}")
    label = f"[Image {index}/{total} ({media_type}, described by {cfg.vision_model})]"
    return f"{label}\n{content}"


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
                for token in _IMAGE_PATH_RE.findall(content):
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
        new_content: list = []
        image_no = 0
        image_count = sum(1 for b in content if isinstance(b, dict) and b.get("type") == "image")
        for block in content:
            if not isinstance(block, dict):
                new_content.append(block)
                continue
            if block.get("type") == "image":
                image_no += 1
                try:
                    src = block.get("source", {})
                    data = src.get("data", "")
                    media = src.get("media_type", "image/png")
                    text = describe_image(data, media, cfg, index=image_no, total=image_count)
                    audit.append({"type": "image", "media_type": media, "replaced_with": len(text)})
                    new_content.append({"type": "text", "text": text})
                except Exception as exc:  # never drop the request on a vision failure
                    audit.append({"type": "image", "error": str(exc)})
                    new_content.append(
                        {"type": "text", "text": f"[Image block: description failed ({exc}) — image was removed.]"}
                    )
                continue
            if block.get("type") == "text" and cfg.describe_file_paths:
                new_content.append(block)
                text = block.get("text", "")
                for token in _IMAGE_PATH_RE.findall(text):
                    res = _describe_local_file(token, cfg)
                    if res:
                        desc, fpath = res
                        audit.append({"type": "file", "path": fpath})
                        new_content.append({"type": "text", "text": desc})
                continue
            new_content.append(block)
        msg["content"] = new_content
    return body, audit


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
        print("Run `vb_proxy.py doctor` for details.", file=sys.stderr)
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
        "VB_PORT": cfg.port,
        "VB_UPSTREAM_URL": cfg.upstream or "(unset)",
        "VB_NON_VISION_MODELS": cfg.non_vision or "(bridging disabled)",
        "VB_VISION_BASE_URL": cfg.vision_base or "(unset)",
        "VB_VISION_MODEL": cfg.vision_model,
        "VB_VISION_API_KEY": ("set" if cfg.vision_key else "(unset)"),
        "VB_DESCRIBE_FILE_PATHS": cfg.describe_file_paths,
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
        print(f"  upstream POST {cfg.upstream}/v1/messages (Anthropic) ...")
        try:
            with httpx.Client(timeout=10) as c:
                r = c.post(
                    f"{cfg.upstream}/v1/messages",
                    json={"model": "ping", "max_tokens": 1, "messages": [{"role": "user", "content": "ping"}]},
                    headers={"Authorization": f"Bearer {cfg.vision_key}", "anthropic-version": "2023-06-01"},
                )
            print(f"    HTTP {r.status_code}")
            ok = ok and r.status_code in (200, 400)  # 400 = reachable, model rejected
        except Exception as exc:
            print(f"    failed: {exc}")
            ok = False
        print(f"  vision POST {cfg.vision_base}/v1/chat/completions ...")
        try:
            with httpx.Client(timeout=10) as c:
                r = c.post(
                    f"{cfg.vision_base}/v1/chat/completions",
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
    cfg = Cfg(load_env=False)
    cfg.vision_base = _env("VB_VISION_BASE_URL") or _env("VB_UPSTREAM_URL") or ""
    cfg.vision_model = _env("VB_VISION_MODEL", "gemini-3.1-flash-image") or "gemini-3.1-flash-image"
    cfg.vision_key = _env("VB_VISION_API_KEY") or _env("ANTHROPIC_AUTH_TOKEN") or _env("ANTHROPIC_API_KEY") or ""
    cfg.vision_prompt = prompt or _env("VB_VISION_PROMPT") or "Describe this image faithfully and concretely."
    cfg.vision_base = cfg.vision_base.rstrip("/")
    if not cfg.vision_base:
        print("Error: no vision endpoint — set VB_VISION_BASE_URL or VB_UPSTREAM_URL.", file=sys.stderr)
        return 1
    if not cfg.vision_key:
        print("Error: no vision key — set VB_VISION_API_KEY, ANTHROPIC_AUTH_TOKEN, or ANTHROPIC_API_KEY.", file=sys.stderr)
        return 1
    p = Path(path).expanduser()
    if not p.is_file():
        print(f"Error: file not found: {path}", file=sys.stderr)
        return 1
    max_bytes = int(_env("VB_MAX_IMAGE_BYTES", str(20 * 1024 * 1024)) or str(20 * 1024 * 1024))
    if p.stat().st_size > max_bytes:
        print(f"Error: file too large ({p.stat().st_size} bytes > {max_bytes} VB_MAX_IMAGE_BYTES).", file=sys.stderr)
        return 1
    mime = _mime_for(p, "image/png")
    data = base64.b64encode(p.read_bytes()).decode()
    print(describe_image(data, mime, cfg))
    return 0


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(prog="vb_proxy", description="Vision Bridge proxy")
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
