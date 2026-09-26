#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = ["google-genai>=2.25.0"]
# ///
"""Bridge Claude Code to Gemini Managed Agents (Interactions API).

Delegates a task or deep-research query to a remote Gemini sandbox agent,
runs it in a detached worker, and exposes status/wait for polling.

Subcommands:
  delegate   Run a task on antigravity-preview-05-2026 in a remote sandbox.
  research   Run a deep-research query (deep-research-preview-04-2026, or
             deep-research-max-preview-04-2026 with --max).
  status     Print the current status and (if finished) the result of a run.
  wait       Block until a run reaches a terminal state, print one line, exit.
  cleanup    Prune finished run directories (and their stored interactions).
  _worker    Internal: the detached process that performs the interaction.

Authentication (two paths, both first-class):
  vertex   Vertex AI, authenticated with a bearer token minted from Application
           Default Credentials. Needs a project and a location.
  api-key  Gemini Developer API with GEMINI_API_KEY or GOOGLE_API_KEY.
  ANTIGRAVITY_AUTH=auto (default) prefers vertex when it is fully configured and
  otherwise falls back to api-key; force a path with vertex or api-key. Project
  and location come from ANTIGRAVITY_PROJECT / ANTIGRAVITY_LOCATION, then from
  GOOGLE_CLOUD_PROJECT (or GCLOUD_PROJECT) and GOOGLE_CLOUD_LOCATION.

Cost and steering options (delegate):
  --max-tokens N   Cap total tokens (input + output + thinking) through
                   agent_config.max_total_tokens. An Antigravity interaction is an
                   autonomous loop, so this is the only real guard on its cost.
  --model M        Underlying model (the agent's own default is Gemini 3.8 Flash).
  --system TEXT    System instruction. "" disables the built-in default, which
                   forbids claiming content that no tool actually retrieved.
  --tier T         service_tier: standard | flex | priority | deferred (flex is
                   the cheap tier for long, non-urgent runs).
  --label k=v      Label the interaction (repeatable).
  --image PATH     Attach a png/jpeg/webp/heic image as inline base64.
  --json           Ask for application/json output through response_format.
  --previous-interaction-id ID
                   Chain a turn. The previous sandbox is reused when
                   --environment-id is not also given, because managed-agent
                   chaining requires the environment in the same request.

Deep research exposes no token cap: its agent_config carries only
collaborative_planning, visualization, thinking_summaries and enable_bigquery_tool,
so a research run cannot be bounded the way a delegate run can.

State lives under ~/.antigravity/runs/<run-id>/:
  meta.json     request metadata + server interaction/environment ids
  status        one word: starting | running | completed | failed
  output.json   structured result
  output.md     human-readable result
  progress.log  streamed progress lines (best-effort, appended by the worker)
  worker.err    worker stderr (diagnostics)
"""

import argparse
import base64
import json
import os
import shutil
import signal
import subprocess
import sys
import threading
import time
import uuid
from datetime import datetime, timezone
from pathlib import Path

ANTIGRAVITY_AGENT = "antigravity-preview-05-2026"
DEEP_RESEARCH_AGENT = "deep-research-preview-04-2026"
DEEP_RESEARCH_MAX_AGENT = "deep-research-max-preview-04-2026"
DEFAULT_TOOLS = ["code_execution", "google_search", "url_context"]
SERVICE_TIERS = ("standard", "flex", "priority", "deferred")
IMAGE_MIME_TYPES = {
    ".png": "image/png",
    ".jpg": "image/jpeg",
    ".jpeg": "image/jpeg",
    ".webp": "image/webp",
    ".heic": "image/heic",
}
# Delegated work is read back as fact, so the agent is told not to invent what it did
# not retrieve. Live runs showed it answering from memory and quoting a page it never
# fetched, which is worse than an honest failure.
DEFAULT_SYSTEM_INSTRUCTION = (
    "Use the tools you are given to obtain facts. Never state or quote content you did not "
    "actually retrieve with a tool, and never describe a failed or empty tool result as if "
    "it succeeded. If a tool fails, say so plainly."
)
# progress.log is best-effort UI data: bounded so a multi-hour run cannot grow it without
# limit. When the cap is hit the older half is dropped.
MAX_PROGRESS_LINES = 400
MAX_STREAM_RECONNECTS = 5
MAX_CONSECUTIVE_POLL_ERRORS = 10
POLL_INTERVAL = 10  # seconds between interactions.get() polls
# Local run states written to the status file.
TERMINAL = {"completed", "failed"}
# Server-side TERMINAL interaction states, from the google-genai Interaction.status
# Literal: in_progress, requires_action, completed, failed, cancelled, incomplete,
# budget_exceeded. Only "completed" is success. Poll until the status lands in this
# set; treat everything else — the active states in_progress / requires_action, an
# empty status, or any future status the SDK adds — as "still working", so a new or
# unrecognized active state is never mistaken for a finished run. The deadline below
# bounds a genuine hang.
SERVER_TERMINAL = {"completed", "failed", "cancelled", "incomplete", "budget_exceeded"}
GET_TIMEOUT = 60  # per-get() timeout so a long-poll can't block the deadline check
WORKER_DEADLINE = 7200  # seconds before the worker gives up (deep research is slow)
# A run may sit non-terminal without a worker pid only briefly: the worker is spawned
# immediately and writes its pid before touching the network. Past this window the run
# is treated as dead rather than left "running" forever.
WORKER_START_GRACE = 120  # seconds

RUNS_DIR = Path(os.environ.get("ANTIGRAVITY_HOME", Path.home() / ".antigravity")) / "runs"


# --- Credential resolution --------------------------------------------------

AUTH_ENV = "ANTIGRAVITY_AUTH"
AUTH_CHOICES = ("auto", "vertex", "api-key")
VERTEX_PROJECT_ENV = "ANTIGRAVITY_PROJECT"
VERTEX_LOCATION_ENV = "ANTIGRAVITY_LOCATION"
API_KEY_ENVS = ("GEMINI_API_KEY", "GOOGLE_API_KEY")
DEFAULT_ADC_PATH = Path.home() / ".config" / "gcloud" / "application_default_credentials.json"


class AuthConfigError(RuntimeError):
    """No usable credential path could be resolved from the environment."""


def vertex_project() -> str | None:
    for name in (VERTEX_PROJECT_ENV, "GOOGLE_CLOUD_PROJECT", "GCLOUD_PROJECT"):
        value = (os.environ.get(name) or "").strip()
        if value:
            return value
    return None


def vertex_location() -> str | None:
    for name in (VERTEX_LOCATION_ENV, "GOOGLE_CLOUD_LOCATION"):
        value = (os.environ.get(name) or "").strip()
        if value:
            return value
    return None


def developer_api_key() -> str | None:
    for name in API_KEY_ENVS:
        value = (os.environ.get(name) or "").strip()
        if value:
            return value
    return None


def adc_path() -> Path:
    override = (os.environ.get("GOOGLE_APPLICATION_CREDENTIALS") or "").strip()
    return Path(override) if override else DEFAULT_ADC_PATH


def adc_available() -> bool:
    return adc_path().is_file()


def _vertex_requirements_error(project: str | None, location: str | None) -> str:
    missing = []
    if not project:
        missing.append(f"a project ({VERTEX_PROJECT_ENV} or GOOGLE_CLOUD_PROJECT)")
    if not location:
        missing.append(f"a location ({VERTEX_LOCATION_ENV} or GOOGLE_CLOUD_LOCATION)")
    if not adc_available():
        missing.append(
            "Application Default Credentials"
            f" (run `gcloud auth application-default login`, or set GOOGLE_APPLICATION_CREDENTIALS; looked at {adc_path()})"
        )
    return "vertex mode is missing " + "; ".join(missing) + "."


def _no_credentials_error() -> str:
    return (
        "no credentials configured. Pick one path:\n"
        "  vertex  — Vertex AI via ADC: run `gcloud auth application-default login`, then set\n"
        f"            {VERTEX_PROJECT_ENV} (or GOOGLE_CLOUD_PROJECT) and {VERTEX_LOCATION_ENV} (or GOOGLE_CLOUD_LOCATION)\n"
        "  api-key — Gemini Developer API: set GEMINI_API_KEY or GOOGLE_API_KEY\n"
        f"Force one with {AUTH_ENV}=vertex or {AUTH_ENV}=api-key."
    )


def resolve_auth() -> dict:
    """Resolve which credential path to use, or explain what is missing.

    Auto prefers vertex when ADC, a project, and a location are all present: an
    environment set up that way has deliberately opted into Vertex, and an ambient
    API key must not silently redirect the run (and its billing) elsewhere.
    """
    requested = (os.environ.get(AUTH_ENV) or "auto").strip().lower() or "auto"
    if requested not in AUTH_CHOICES:
        raise AuthConfigError(
            f"{AUTH_ENV} must be one of {', '.join(AUTH_CHOICES)} (got {requested!r})."
        )

    project, location, key = vertex_project(), vertex_location(), developer_api_key()
    vertex_ready = bool(project and location and adc_available())

    if requested == "vertex":
        if not vertex_ready:
            raise AuthConfigError(_vertex_requirements_error(project, location))
        mode = "vertex"
    elif requested == "api-key":
        if not key:
            raise AuthConfigError(f"{AUTH_ENV}=api-key needs GEMINI_API_KEY or GOOGLE_API_KEY to be set.")
        mode = "api-key"
    elif vertex_ready:
        mode = "vertex"
    elif key:
        mode = "api-key"
    else:
        raise AuthConfigError(_no_credentials_error())

    if mode == "vertex":
        return {
            "mode": "vertex",
            "label": f"Vertex AI ({project}/{location}, ADC)",
            "client_kwargs": {"vertexai": True, "project": project, "location": location},
            # Vertex rejects synchronous agent interactions with
            # 400 "Agent interactions must set background to true.", so this path
            # always goes through background + get() polling.
            "background": True,
        }
    return {
        "mode": "api-key",
        "label": "Gemini Developer API (API key)",
        "client_kwargs": {"api_key": key},
        "background": False,
    }


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def run_dir(run_id: str) -> Path:
    return RUNS_DIR / run_id


def write_status(run_id: str, status: str) -> None:
    (run_dir(run_id) / "status").write_text(status + "\n")


def read_status(run_id: str) -> str:
    f = run_dir(run_id) / "status"
    return f.read_text().strip() if f.exists() else "missing"


def write_json(path: Path, data: dict) -> None:
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False, default=str))


def fail(msg: str, code: int = 1) -> "NoReturn":  # type: ignore[name-defined]
    print(f"error: {msg}", file=sys.stderr)
    raise SystemExit(code)


def write_pid(run_id: str) -> None:
    (run_dir(run_id) / "worker.pid").write_text(str(os.getpid()) + "\n")


def read_pid(run_id: str) -> int | None:
    f = run_dir(run_id) / "worker.pid"
    if not f.exists():
        return None
    try:
        return int(f.read_text().strip())
    except ValueError:
        return None


def is_pid_alive(pid: int) -> bool:
    if pid <= 0:
        return False
    try:
        os.kill(pid, 0)
        return True
    except ProcessLookupError:
        return False
    except PermissionError:
        return True  # process exists but we can't signal it


def pid_command_line(pid: int) -> str | None:
    """The command line of a pid, or None when it cannot be read.

    None means "unknown", never "dead". `ps` is missing on some platforms, and a
    readable command line must never be invented.
    """
    try:
        completed = subprocess.run(
            ["ps", "-o", "command=", "-p", str(pid)],
            capture_output=True,
            text=True,
            timeout=5,
        )
    except (OSError, subprocess.SubprocessError):
        return None
    line = completed.stdout.strip()
    return line or None


def is_worker_alive(run_id: str, pid: int) -> bool:
    """Whether `pid` is still this run's worker.

    A live pid is not proof of a live worker: after a crash, a system sleep, or a power
    loss the pid recorded in worker.pid can be recycled by any unrelated process, which
    would leave the run looking "running" until the heat death of the run directory. The
    worker is spawned as `<python> <script> _worker <run_id>`, so the run id appearing in
    the command line is a positive identity check. When the command line cannot be read
    the pid is trusted: waiting on a live run beats reporting it as failed.
    """
    if not is_pid_alive(pid):
        return False
    command = pid_command_line(pid)
    if command is None:
        return True
    return run_id in command


def run_age_seconds(d: Path) -> float | None:
    """Seconds since the run was created, or None when that cannot be determined."""
    try:
        created = json.loads((d / "meta.json").read_text()).get("created_at")
        if not isinstance(created, str) or not created:
            return None
        return max(0.0, (datetime.now(timezone.utc) - datetime.fromisoformat(created)).total_seconds())
    except (OSError, ValueError, json.JSONDecodeError):
        return None


def worker_failure(run_id: str, d: Path) -> str | None:
    """Why a non-terminal run has no live worker, or None while it still does."""
    pid = read_pid(run_id)
    if pid is not None:
        return None if is_worker_alive(run_id, pid) else "worker process died"
    age = run_age_seconds(d)
    if age is not None and age > WORKER_START_GRACE:
        return "worker never started"
    return None


# --- Request building -------------------------------------------------------

class OptionError(RuntimeError):
    """A command-line option cannot be turned into a valid API request."""


def parse_labels(pairs) -> dict | None:
    if not pairs:
        return None
    labels: dict[str, str] = {}
    for pair in pairs:
        key, sep, value = str(pair).partition("=")
        key = key.strip()
        if not sep or not key:
            raise OptionError(f"--label needs key=value (got {pair!r})")
        labels[key] = value.strip()
    return labels


def image_mime_type(path: str) -> str:
    suffix = Path(path).suffix.lower()
    mime = IMAGE_MIME_TYPES.get(suffix)
    if not mime:
        raise OptionError(
            f"unsupported image type {suffix or path!r} (allowed: {', '.join(sorted(IMAGE_MIME_TYPES))})"
        )
    return mime


def load_images(paths) -> list[dict]:
    """Inline base64 image parts; the agent accepts text and image input only."""
    parts: list[dict] = []
    for raw in paths:
        path = Path(str(raw)).expanduser()
        if not path.is_file():
            raise OptionError(f"image not found: {path}")
        mime = image_mime_type(str(path))
        try:
            data = base64.b64encode(path.read_bytes()).decode("ascii")
        except OSError as exc:
            raise OptionError(f"cannot read image {path}: {exc}") from exc
        parts.append({"type": "image", "data": data, "mime_type": mime})
    return parts


def build_input(meta: dict, images_loader=load_images) -> str | list[dict]:
    images = list(meta.get("images") or [])
    if not images:
        return meta["prompt"]
    return [{"type": "text", "text": meta["prompt"]}, *images_loader(images)]


def build_response_format(json_output: bool) -> dict | None:
    """Structured-output request, or None.

    response_mime_type alone is rejected live ("responseFormat must be set when
    responseMimeType is set") and sending the pair is rejected too, so response_format
    is the working form: a live run returned parseable JSON with the requested keys.
    """
    if not json_output:
        return None
    return {"type": "text", "mime_type": "application/json"}


def build_agent_config(
    kind: str,
    model: str | None,
    max_tokens: int | None,
    research_options: dict | None = None,
) -> dict | None:
    """agent_config for this run, or None when nothing is configured.

    The two agents take different config types: only AntigravityAgentConfig accepts
    model and max_total_tokens, while DeepResearchAgentConfig accepts its own research
    options and nothing that bounds cost. Deep research therefore cannot be capped.
    """
    if kind == "research":
        if model is not None or max_tokens is not None:
            raise OptionError("deep research has no --model or --max-tokens option")
        options = {key: value for key, value in (research_options or {}).items() if value is not None}
        return {"type": "deep-research", **options}
    config: dict = {"type": "antigravity"}
    if model:
        config["model"] = model
    if max_tokens:
        config["max_total_tokens"] = max_tokens
    return config if len(config) > 1 else None


def build_environment(network: str, repo: str | None, environment_id: str | None):
    """The `environment` request value: a reused id (bare string) or a config object.

    Reuse is the documented bare-string form (`"env_abc123"`), and it is the only shape
    that actually preserves the sandbox files: a config object carrying the id was accepted
    by the server and then provisioned a fresh sandbox (verified live), which looks exactly
    like success while silently losing every file. prepare_options therefore refuses to
    combine reuse with --repo or --network, rather than dropping them without a word.
    """
    if environment_id:
        return environment_id
    env: dict = {"type": "remote"}
    # Network enum (SDK): "disabled" blocks all outbound; omitting the field allows
    # all outbound. google_search / url_context route through Google infra and are
    # unaffected either way — this only gates code_execution outbound traffic.
    if network == "none":
        env["network"] = "disabled"
    if repo:
        env["sources"] = [
            {"type": "repository", "source": repo, "target": "/workspace/repo"}
        ]
    return env


def build_create_kwargs(meta: dict, images_loader=load_images) -> dict:
    # background is decided on two axes, both recorded in meta["background"] by
    # start_run: the deep-research agent REQUIRES background=True on every path
    # (server runs async; the worker polls get() until terminal), while the
    # antigravity agent REJECTS background on the Developer API (create() runs
    # synchronously) but REQUIRES it on Vertex. When background is off, create()
    # blocks until the agent finishes (minutes for real work) while the SDK's
    # default per-request timeout is only 60s — so bound it at the worker deadline
    # instead: long enough for genuine work, finite so a hung server can't leave a
    # zombie worker.
    kwargs: dict = {"agent": meta["agent"], "input": build_input(meta, images_loader), "store": True}
    # store=True is required: background execution, previous_interaction_id chaining, and
    # progress streaming all read the stored interaction back. The cost is that the
    # interaction is retained server-side (paid tier 55 days, free tier 1 day).
    if meta.get("system_instruction"):
        kwargs["system_instruction"] = meta["system_instruction"]
    if meta.get("service_tier"):
        kwargs["service_tier"] = meta["service_tier"]
    if meta.get("labels"):
        kwargs["labels"] = meta["labels"]
    if meta.get("response_format"):
        kwargs["response_format"] = meta["response_format"]
    if meta.get("agent_config"):
        kwargs["agent_config"] = meta["agent_config"]
    elif meta["kind"] == "research":
        # Research always carries its config even if meta was written by an older version
        # or hand-edited: the deep-research agent takes no tools and reads its options here.
        kwargs["agent_config"] = {"type": "deep-research"}
    if meta["kind"] != "research":
        kwargs["tools"] = [{"type": t} for t in meta["tools"]]
        kwargs["environment"] = build_environment(meta["network"], meta.get("repo"), meta.get("environment_id"))
        if meta.get("previous_interaction_id"):
            kwargs["previous_interaction_id"] = meta["previous_interaction_id"]
    # meta["background"] carries the delegate decision (Vertex forces it); research
    # is asynchronous on every path, so it is asserted here as well rather than
    # trusted to a single field.
    background = meta["kind"] == "research" or bool(meta.get("background"))
    if background:
        kwargs["background"] = True
    else:
        kwargs["timeout"] = WORKER_DEADLINE
    return kwargs


# --- Progress and waiting ---------------------------------------------------

def append_progress(d: Path, line: str) -> None:
    """Append one progress line, keeping the log bounded and never raising.

    Progress is best-effort UI data, never the source of truth for run state, so a
    write failure must not fail a run.
    """
    if not line:
        return
    path = d / "progress.log"
    try:
        stamp = datetime.now(timezone.utc).strftime("%H:%M:%S")
        with path.open("a") as f:
            f.write(f"{stamp} {line}\n")
        lines = path.read_text().splitlines()
        if len(lines) > MAX_PROGRESS_LINES:
            path.write_text("\n".join(lines[-(MAX_PROGRESS_LINES // 2) :]) + "\n")
    except OSError:
        return


def describe_event(event) -> str:
    """One readable progress line for an SSE event, or the event type when unknown."""
    event_type = str(getattr(event, "event_type", "") or "")
    if event_type == "step.start":
        step = getattr(event, "step", None)
        step_type = _first_text(getattr(step, "type", None)) if step is not None else ""
        name = _first_text(getattr(step, "name", None)) if step is not None else ""
        return f"step.start {' '.join(part for part in (step_type, name) if part)}".strip()
    if event_type == "step.delta":
        delta = getattr(event, "delta", None)
        text = _first_text(getattr(delta, "text", None)) if delta is not None else ""
        return f"delta {text[:120]}" if text else "delta"
    return event_type


def stream_progress(client, interaction_id: str, d: Path, stop: "threading.Event") -> None:
    """Follow SSE progress until the interaction completes or `stop` is set.

    Never raises: polling decides run state, so a stream that cannot be consumed
    (unsupported endpoint, dropped connection, auth quirk) only costs progress lines.
    Reconnects resume from last_event_id, as the API documents.
    """
    last_event_id = None
    attempts = 0
    while not stop.is_set() and attempts <= MAX_STREAM_RECONNECTS:
        try:
            stream = client.interactions.get(
                interaction_id, stream=True, last_event_id=last_event_id, timeout=GET_TIMEOUT
            )
            for event in stream:
                if stop.is_set():
                    return
                event_id = getattr(event, "event_id", None)
                if event_id:
                    last_event_id = event_id
                append_progress(d, describe_event(event))
                if str(getattr(event, "event_type", "") or "") == "interaction.completed":
                    return
            attempts += 1
        except Exception:  # noqa: BLE001 - progress must never break a run
            attempts += 1
            if stop.wait(1):
                return


def terminal_status_blocker(status: str) -> str | None:
    """Why a non-terminal server status cannot be served by this plugin.

    requires_action means the agent paused for a client-side function call. The plugin
    registers no custom functions (built-in tools, including the filesystem, are served
    by the environment), so such a run can never progress and must fail instead of
    polling until the worker deadline.
    """
    if status == "requires_action":
        return (
            "the agent is waiting on a client-side function call, and this plugin registers no "
            "custom functions; re-run with built-in tools only, or serve the call with the SDK"
        )
    return None


def wait_for_terminal(client, interaction_id: str, d: Path, deadline: float):
    """Wait for a background interaction and return the authoritative interaction.

    Polling decides the outcome; the SSE stream only feeds progress.log, so a broken or
    unsupported stream cannot change the result.
    """
    stop = threading.Event()
    streamer = threading.Thread(
        target=stream_progress, args=(client, interaction_id, d, stop), name="progress", daemon=True
    )
    streamer.start()
    try:
        interaction = client.interactions.get(interaction_id, timeout=GET_TIMEOUT)
        status = str(getattr(interaction, "status", "") or "")
        consecutive_poll_errors = 0
        while status not in SERVER_TERMINAL:
            blocker = terminal_status_blocker(status)
            if blocker:
                raise RuntimeError(blocker)
            if time.monotonic() >= deadline:
                raise TimeoutError(f"worker gave up after {WORKER_DEADLINE}s (last: {status})")
            time.sleep(POLL_INTERVAL)
            try:
                interaction = client.interactions.get(interaction_id, timeout=GET_TIMEOUT)
                status = str(getattr(interaction, "status", "") or "")
                consecutive_poll_errors = 0
            except Exception as poll_exc:  # noqa: BLE001 - classified below
                consecutive_poll_errors += 1
                with (d / "worker.err").open("a") as f:
                    f.write(
                        f"poll error ({consecutive_poll_errors}/{MAX_CONSECUTIVE_POLL_ERRORS}): {poll_exc}\n"
                    )
                # Permanent errors (4xx except 408/409) stop immediately; 5xx, 408, 409
                # and 429 are retried up to the cap.
                error_str = str(poll_exc).lower()
                is_permanent = any(
                    code in error_str for code in ["400", "401", "403", "404", "405", "422"]
                )
                if is_permanent or consecutive_poll_errors >= MAX_CONSECUTIVE_POLL_ERRORS:
                    raise RuntimeError(
                        f"poll failed permanently after {consecutive_poll_errors} attempts: {poll_exc}"
                    )
        return interaction
    finally:
        stop.set()
        streamer.join(timeout=5)


# --- Result extraction ------------------------------------------------------

def text_from_step(step) -> str:
    content = getattr(step, "content", None)
    if content is None:
        return ""
    parts = []
    items = content if isinstance(content, list) else [content]
    for c in items:
        t = getattr(c, "text", None)
        if t:
            parts.append(t)
            continue
        for p in getattr(c, "parts", []) or []:
            pt = getattr(p, "text", None)
            if pt:
                parts.append(pt)
    # Text parts are fragments of one message (the SDK concatenates them the same
    # way), so no separator is inserted between them.
    return "".join(parts)


def _argument(args, key: str):
    """Read one field of a step's arguments, whether it is a model or a plain dict."""
    if args is None:
        return None
    if isinstance(args, dict):
        return args.get(key)
    return getattr(args, key, None)


def _first_text(*values) -> str:
    for value in values:
        if isinstance(value, str) and value.strip():
            return value.strip()
    return ""


def summarize_steps(steps) -> tuple[list[str], dict]:
    lines: list[str] = []
    counts: dict[str, int] = {}
    for step in steps or []:
        stype = getattr(step, "type", "unknown")
        counts[stype] = counts.get(stype, 0) + 1
        args = getattr(step, "arguments", None)
        if stype == "code_execution_call":
            code = _first_text(_argument(args, "code"))
            lines.append(f"[code] {code.splitlines()[0][:100] if code else ''}")
        elif stype == "google_search_call":
            queries = _argument(args, "queries") or []
            lines.append(f"[search] {', '.join(map(str, queries))[:120]}")
        elif stype == "url_context_call":
            urls = _argument(args, "urls") or []
            lines.append(f"[url] {', '.join(map(str, urls))[:120]}")
        elif stype == "function_call":
            # Vertex reports every tool as a generic function_call: the tool name sits
            # in step.name and the readable description inside arguments. The per-tool
            # *_call types above cover the Developer API.
            detail = _first_text(
                _argument(args, "toolSummary"),
                _argument(args, "CommandLine"),
                _argument(args, "command_line"),
                _argument(args, "explanation"),
            )
            name = _first_text(getattr(step, "name", None)) or "?"
            lines.append(f"[{name}] {detail[:120]}")
    return lines, counts


def extract_citations(steps) -> list[dict]:
    """URL citations the model attached to its answer, in first-appearance order.

    Text content carries `annotations` (`url_citation` with title and url) that the
    report's inline `[cite: N]` markers refer to. Dropping them leaves every marker
    pointing at nothing, which is worse than not showing the markers at all.
    """
    citations: list[dict] = []
    seen: set[str] = set()
    for step in steps or []:
        if getattr(step, "type", None) != "model_output":
            continue
        content = getattr(step, "content", None)
        if not isinstance(content, list):
            continue
        for item in content:
            for annotation in _argument(item, "annotations") or []:
                if _first_text(_argument(annotation, "type")) != "url_citation":
                    continue
                url = _first_text(_argument(annotation, "url"))
                if not url or url in seen:
                    continue
                seen.add(url)
                # Titles arrive with embedded newlines ("Page name\nsite.com"), which
                # would break the markdown link text.
                title = " ".join((_first_text(_argument(annotation, "title")) or url).split())
                citations.append({"title": title, "url": url})
    return citations


def extract_result(interaction) -> dict:
    steps = list(getattr(interaction, "steps", []) or [])
    # model_output steps are streaming fragments of one message, so they concatenate
    # with NO separator: joining with "\n\n" corrupts any text split between steps
    # (observed live: "184467440737095516" + "16" became two numbers). After streaming a
    # message as deltas the server re-sends the completed message, so a segment equal
    # to the text accumulated since the last non-model_output step is dropped. The
    # comparison is strict equality, never a suffix match: a suffix test would silently
    # discard a genuine fragment that happens to match the tail (it ate the final "16").
    #
    # Reconstruction is kept over the SDK's interaction.output_text because that helper
    # stops at the first non-model_output step (see its _populate_output_helpers) and so
    # drops the beginning of a multi-part report: in real run 20260604-214750-d109c0
    # (2.13M tokens, 2 model_output segments), output_text contained only the LAST
    # segment (the report started at §4.2).
    segments: list[str] = []
    collected = ""
    group = ""  # text accumulated since the last non-model_output step
    for step in steps:
        if getattr(step, "type", None) != "model_output":
            group = ""
            continue
        t = text_from_step(step)
        if not t or (group and t == group):
            continue
        segments.append(t)
        collected += t
        group += t
    output_text = collected
    step_lines, counts = summarize_steps(steps)
    usage = getattr(interaction, "usage", None)
    return {
        "interaction_id": getattr(interaction, "id", None),
        "environment_id": getattr(interaction, "environment_id", None),
        "status": str(getattr(interaction, "status", "") or ""),
        "output_text": output_text or "",
        "citations": extract_citations(steps),
        "step_counts": counts,
        "step_trace": step_lines,
        "usage": {
            "total_input_tokens": getattr(usage, "total_input_tokens", None),
            "total_output_tokens": getattr(usage, "total_output_tokens", None),
            "total_tokens": getattr(usage, "total_tokens", None),
        }
        if usage
        else None,
    }


def render_markdown(meta: dict, result: dict) -> str:
    lines = [
        f"# Antigravity {meta['kind']} result",
        "",
        f"- run id: `{meta['run_id']}`",
        f"- agent: `{meta['agent']}`",
        f"- interaction id: `{result.get('interaction_id')}`",
        f"- environment id: `{result.get('environment_id')}`",
        f"- status: {result.get('status')}",
        f"- auth: {meta.get('auth_label') or meta.get('auth') or 'unknown'}",
    ]
    # The request options decide what a run cost and what it was allowed to do, so they
    # belong in the artefact the caller reads back.
    if meta.get("agent_config"):
        lines.append(f"- agent config: `{json.dumps(meta['agent_config'], sort_keys=True)}`")
    if meta.get("service_tier"):
        lines.append(f"- service tier: {meta['service_tier']}")
    if meta.get("labels"):
        lines.append(f"- labels: `{json.dumps(meta['labels'], sort_keys=True)}`")
    if meta.get("images"):
        lines.append(f"- images: {len(meta['images'])}")
    if meta.get("response_format"):
        lines.append(f"- response format: {meta['response_format'].get('mime_type')}")
    if meta.get("previous_interaction_id"):
        lines.append(f"- previous interaction: `{meta['previous_interaction_id']}`")
    citations = result.get("citations") or []
    if citations:
        lines.append(f"- sources: {len(citations)}")
    counts = result.get("step_counts") or {}
    if counts:
        lines.append(f"- steps: {', '.join(f'{k}={v}' for k, v in counts.items())}")
    usage = result.get("usage") or {}
    if usage.get("total_tokens"):
        lines.append(f"- tokens: {usage.get('total_tokens')}")
    trace = result.get("step_trace") or []
    if trace:
        lines += ["", "## Tool trace", ""]
        lines += [f"- {t}" for t in trace]
    lines += ["", "## Output", "", result.get("output_text") or "(no text output)"]
    # The report cites sources inline by number; without the list those markers are dead.
    if citations:
        lines += ["", "## Sources", ""]
        for citation in citations:
            lines.append(f"- [{citation['title']}]({citation['url']})")
    return "\n".join(lines) + "\n"


# --- Worker (detached) ------------------------------------------------------

def resolve_chain_environment(client, meta: dict, d: Path) -> None:
    """Reuse the previous turn's sandbox when chaining without an explicit environment.

    Managed-agent chaining requires previous_interaction_id and environment in the same
    request, and reusing the recorded environment is what preserves the sandbox files.
    A failed lookup is recorded and the run continues with a fresh sandbox.
    """
    if not meta.get("previous_interaction_id") or meta.get("environment_id"):
        return
    try:
        previous = client.interactions.get(meta["previous_interaction_id"], timeout=GET_TIMEOUT)
    except Exception as exc:  # noqa: BLE001 - chaining still works with a fresh sandbox
        with (d / "worker.err").open("a") as f:
            f.write(f"could not read the previous interaction's environment: {exc}\n")
        return
    environment_id = getattr(previous, "environment_id", None)
    if environment_id:
        meta["environment_id"] = environment_id


def cmd_worker(run_id: str) -> None:
    d = run_dir(run_id)
    meta = json.loads((d / "meta.json").read_text())
    write_status(run_id, "running")
    write_pid(run_id)
    try:
        from google import genai

        # The worker is a separate process, so resolve again here. Resolving inside
        # the try block means a misconfigured environment is recorded as a failed
        # run (with the reason in worker.err) rather than dying silently.
        auth = resolve_auth()
        client = genai.Client(**auth["client_kwargs"])
        meta["auth"] = auth["mode"]
        meta["auth_label"] = auth["label"]
        meta["started_at"] = now()
        write_json(d / "meta.json", meta)

        resolve_chain_environment(client, meta, d)
        interaction = client.interactions.create(**build_create_kwargs(meta))
        iid = getattr(interaction, "id", None)
        meta["interaction_id"] = iid
        meta["environment_id"] = getattr(interaction, "environment_id", None) or meta.get("environment_id")
        write_json(d / "meta.json", meta)

        # A background interaction returns immediately and must be waited on (research on
        # every path, plus delegate on Vertex). A synchronous create() already returns a
        # terminal interaction, so nothing is awaited. wait_for_terminal polls for truth
        # and streams progress best-effort.
        srv_status = str(getattr(interaction, "status", "") or "")
        if (meta["kind"] == "research" or meta.get("background")) and srv_status not in SERVER_TERMINAL:
            deadline = time.monotonic() + WORKER_DEADLINE
            interaction = wait_for_terminal(client, iid, d, deadline)
            srv_status = str(getattr(interaction, "status", "") or "")
        blocker = terminal_status_blocker(srv_status)
        if blocker:
            raise RuntimeError(blocker)

        result = extract_result(interaction)
        if srv_status != "completed":
            result["error"] = f"interaction ended with status: {srv_status}"
        meta["environment_id"] = result.get("environment_id") or meta.get("environment_id")
        meta["finished_at"] = now()
        write_json(d / "meta.json", meta)
        write_json(d / "output.json", result)
        (d / "output.md").write_text(render_markdown(meta, result))
        write_status(run_id, "completed" if srv_status == "completed" else "failed")
    except Exception as exc:  # noqa: BLE001 - worker must record any failure
        err = {"status": "failed", "error": str(exc), "type": type(exc).__name__}
        write_json(d / "output.json", err)
        (d / "output.md").write_text(
            f"# Antigravity {meta.get('kind')} failed\n\n```\n{exc}\n```\n"
        )
        write_status(run_id, "failed")
        raise SystemExit(1)


# --- Create (delegate / research) -------------------------------------------

def prepare_options(kind: str, options: dict) -> dict:
    """Validate the command-line options and freeze what the worker needs.

    Everything that can be rejected without the network is rejected here, so a bad flag
    fails before a run directory or a worker exists.
    """
    max_tokens = options.get("max_tokens")
    if max_tokens is not None and max_tokens <= 0:
        raise OptionError("--max-tokens must be a positive integer")
    if options.get("environment_id") and (options.get("repo") or options.get("network") == "none"):
        raise OptionError(
            "--environment-id cannot be combined with --repo or --network none: the API expresses "
            "sandbox reuse as a bare environment id, so those options would be silently ignored"
        )
    if kind == "research" and options.get("system"):
        # The deep-research agent rejects system_instruction outright (400 "not supported for
        # the deep-research-preview-04-2026 agent"). Folding the text into the query would
        # silently change what the report is about, so the option is refused instead.
        raise OptionError(
            "deep research has no system instruction (the API rejects the parameter): put the "
            "guidance in --query instead"
        )
    images = [str(path) for path in (options.get("images") or [])]
    for path in images:
        if not Path(path).expanduser().is_file():
            raise OptionError(f"image not found: {path}")
        image_mime_type(path)
    return {
        "tools": options["tools"],
        "network": options["network"],
        "repo": options.get("repo"),
        "environment_id": options.get("environment_id"),
        "previous_interaction_id": options.get("previous_interaction_id"),
        "agent_config": build_agent_config(
            kind, options.get("model"), max_tokens, options.get("research_options")
        ),
        # The default keeps the agent honest about what it actually retrieved; an explicit
        # "" turns it off and any other value replaces it. Deep research supports no system
        # instruction at all, so it never carries one.
        "system_instruction": (
            None
            if kind == "research"
            else (DEFAULT_SYSTEM_INSTRUCTION if options.get("system") is None else options["system"])
        ),
        "service_tier": options.get("service_tier"),
        "labels": parse_labels(options.get("labels") or []),
        "images": images or None,
        "response_format": build_response_format(bool(options.get("json_output"))),
    }


def start_run(kind: str, prompt: str, agent: str, options: dict) -> None:
    """Record a run and spawn its detached worker.

    `options` carries everything the request needs (tools, network, repo, environment and
    chain ids, plus the cost and steering knobs), so adding a request option never changes
    this signature.
    """
    if not prompt or not prompt.strip():
        fail("prompt/query is empty")
    # Validate the request options before touching the filesystem: a bad flag must not
    # leave a half-created run directory behind.
    try:
        prepared = prepare_options(kind, options)
    except OptionError as exc:
        fail(str(exc))
    # Resolve credentials up front: fail fast with guidance, before creating a run
    # directory or spawning a worker, and record which path this run used.
    try:
        auth = resolve_auth()
    except AuthConfigError as exc:
        fail(str(exc))
    run_id = datetime.now().strftime("%Y%m%d-%H%M%S") + "-" + uuid.uuid4().hex[:6]
    d = run_dir(run_id)
    d.mkdir(parents=True, exist_ok=True)
    meta = {
        "run_id": run_id,
        "kind": kind,
        "agent": agent,
        "prompt": prompt,
        "tools": prepared["tools"],
        "network": prepared["network"],
        "repo": prepared["repo"],
        "environment_id": prepared["environment_id"],
        "previous_interaction_id": prepared["previous_interaction_id"],
        "auth": auth["mode"],
        "auth_label": auth["label"],
        "background": kind == "research" or auth["background"],
        "agent_config": prepared["agent_config"],
        "system_instruction": prepared["system_instruction"],
        "service_tier": prepared["service_tier"],
        "labels": prepared["labels"],
        # Image paths are recorded, not their bytes: the worker reads and encodes them at
        # request time so meta.json stays small.
        "images": prepared["images"],
        "response_format": prepared["response_format"],
        "created_at": now(),
    }
    write_json(d / "meta.json", meta)
    write_status(run_id, "starting")

    # Always run the interaction in a detached worker so the work survives the
    # caller exiting (sync foreground calls otherwise hit caller timeouts: the
    # API blocks until the agent finishes its full loop, which can take minutes).
    # The caller waits via the `wait` subcommand (e.g. through the Monitor tool).
    with open(d / "worker.err", "w") as errf:
        subprocess.Popen(
            [sys.executable, os.path.abspath(__file__), "_worker", run_id],
            stdout=subprocess.DEVNULL,
            stderr=errf,
            stdin=subprocess.DEVNULL,
            start_new_session=True,
        )
    print(f"run_id: {run_id}")
    print(f"auth: {auth['label']}")
    if meta["agent_config"]:
        print(f"agent_config: {json.dumps(meta['agent_config'], sort_keys=True)}")
    if meta["images"]:
        print(f"images: {len(meta['images'])}")
    if meta["service_tier"]:
        print(f"service_tier: {meta['service_tier']}")
    if meta["labels"]:
        print(f"labels: {json.dumps(meta['labels'], sort_keys=True)}")
    print(f"status_file: {d / 'status'}")
    print(f"output_file: {d / 'output.md'}")
    print(f"wait_command: {os.path.abspath(__file__)} wait --run {run_id}")
    print(f"status_command: {os.path.abspath(__file__)} status --run {run_id}")


# --- status / wait ----------------------------------------------------------

def print_progress(d: Path, limit: int = 20) -> None:
    path = d / "progress.log"
    if not path.exists():
        return
    lines = path.read_text().splitlines()[-limit:]
    if lines:
        print(f"progress ({len(lines)} lines):")
        for line in lines:
            print(f"  {line}")


def print_status(run_id: str, full: bool, progress: bool = False) -> None:
    d = run_dir(run_id)
    if not d.exists():
        fail(f"unknown run: {run_id}")
    status = read_status(run_id)
    print(f"status: {status}")
    meta_file = d / "meta.json"
    if meta_file.exists():
        try:
            auth_label = json.loads(meta_file.read_text()).get("auth_label")
        except (OSError, json.JSONDecodeError):
            auth_label = None
        if auth_label:
            print(f"auth: {auth_label}")
    # The progress tail is useful both while a run is going and afterwards (it is the
    # record of which tools ran), so it is not gated on the run being non-terminal.
    if progress:
        print_progress(d)
    if status not in TERMINAL:
        failure = worker_failure(run_id, d)
        if failure:
            print(f"({failure} — marking as failed)")
            write_status(run_id, "failed")
            return
        print("(still running — poll again or use `wait`)")
        return
    out = d / "output.json"
    if not out.exists():
        print("(terminal but no output recorded)")
        return
    result = json.loads(out.read_text())
    if status == "failed":
        print(f"error: {result.get('error')}")
        return
    if full:
        print((d / "output.md").read_text())
    else:
        print(f"output_file: {d / 'output.md'}")
        text = result.get("output_text") or ""
        print(text[:2000])
        if result.get("citations"):
            print(f"sources: {len(result['citations'])} (listed in {d / 'output.md'})")


def cmd_wait(run_id: str, interval: int, timeout: int) -> None:
    if not run_dir(run_id).exists():
        fail(f"unknown run: {run_id}")
    deadline = time.monotonic() + timeout
    while True:
        status = read_status(run_id)
        if status in TERMINAL:
            print(f"antigravity run {run_id}: {status}")
            return
        # A dead worker must end the wait instead of blocking until the timeout: the
        # caller treats a returned line as authoritative.
        failure = worker_failure(run_id, run_dir(run_id))
        if failure:
            print(f"antigravity run {run_id}: failed ({failure})")
            write_status(run_id, "failed")
            return
        if time.monotonic() >= deadline:
            print(f"antigravity run {run_id}: timeout (still {status})")
            return
        time.sleep(interval)


# --- cleanup ----------------------------------------------------------------

def run_finished_timestamp(d: Path) -> float | None:
    """When a run finished, from meta.json finished_at (falling back to the status file)."""
    try:
        finished = json.loads((d / "meta.json").read_text()).get("finished_at")
        if isinstance(finished, str) and finished:
            return datetime.fromisoformat(finished).timestamp()
    except (OSError, ValueError, json.JSONDecodeError):
        pass
    try:
        return (d / "status").stat().st_mtime
    except OSError:
        return None


def prunable_runs(older_than_days: float, now_ts: float | None = None) -> list[tuple[str, str | None]]:
    """(run_id, interaction_id) for terminal runs older than the threshold.

    A run that is still going is never a candidate, and a run whose age cannot be
    determined is kept: pruning is housekeeping, so an unreadable directory must never
    turn into data loss.
    """
    cutoff = (time.time() if now_ts is None else now_ts) - older_than_days * 86400
    selected: list[tuple[str, str | None]] = []
    if not RUNS_DIR.is_dir():
        return selected
    for d in sorted(RUNS_DIR.iterdir()):
        if not d.is_dir() or read_status(d.name) not in TERMINAL:
            continue
        finished = run_finished_timestamp(d)
        if finished is None or finished > cutoff:
            continue
        interaction_id = None
        try:
            raw = json.loads((d / "meta.json").read_text()).get("interaction_id")
            interaction_id = raw if isinstance(raw, str) and raw else None
        except (OSError, json.JSONDecodeError):
            interaction_id = None
        selected.append((d.name, interaction_id))
    return selected


def interaction_missing(exc: Exception) -> bool:
    """Whether a delete failed only because the interaction is already gone.

    A 404 means someone (or a shorter retention window) removed it already; counting that
    as a failure would keep the run directory forever and retry a delete that can never
    succeed. A refusal such as "cannot be deleted in its current state" is different: the
    interaction still exists and may become deletable later, so the run is kept.
    """
    text = str(exc).lower()
    return "404" in text or "not found" in text


def cmd_cleanup(
    older_than_days: float,
    dry_run: bool,
    remote: bool,
    client=None,
) -> None:
    """Prune finished run directories, and with --remote also delete stored interactions.

    The interaction is deleted before the directory, so a failed remote delete keeps the
    local record (and its interaction id) available for a retry. A client may be injected
    for tests; otherwise one is built from the resolved credentials.
    """
    candidates = prunable_runs(older_than_days)
    if not candidates:
        print(f"nothing to clean (no finished run older than {older_than_days:g} days)")
        return
    if remote and not dry_run and client is None:
        try:
            auth = resolve_auth()
        except AuthConfigError as exc:
            fail(str(exc))
        from google import genai

        client = genai.Client(**auth["client_kwargs"])
    deleted = 0
    failed: list[str] = []
    for run_id, interaction_id in candidates:
        if dry_run:
            note = " + stored interaction" if remote and interaction_id else ""
            print(f"would remove {run_id}{note}")
            continue
        if remote and interaction_id and client is not None:
            try:
                client.interactions.delete(id=interaction_id, timeout=GET_TIMEOUT)
                deleted += 1
            except Exception as exc:  # noqa: BLE001 - classified below
                if interaction_missing(exc):
                    deleted += 1
                else:
                    print(f"keeping {run_id}: could not delete interaction {interaction_id}: {exc}")
                    failed.append(run_id)
                    continue
        shutil.rmtree(run_dir(run_id), ignore_errors=True)
        print(f"removed {run_id}")
    removed = len(candidates) - len(failed)
    if dry_run:
        print(f"cleanup: would remove {removed}, kept {len(failed)}")
        return
    suffix = f", deleted {deleted} interactions" if remote else ""
    print(f"cleanup: removed {removed}, kept {len(failed)}{suffix}")


# --- CLI --------------------------------------------------------------------


def add_common_options(parser: argparse.ArgumentParser) -> None:
    """Cost and steering options shared by delegate and research.

    --model and --max-tokens are deliberately absent: DeepResearchAgentConfig accepts
    neither, so offering them on research would promise a cap it cannot honour.
    """
    parser.add_argument(
        "--system",
        default=None,
        help="system instruction; an empty string disables the built-in anti-fabrication default",
    )
    parser.add_argument("--tier", choices=SERVICE_TIERS, default=None, help="service tier (flex is the cheap one)")
    parser.add_argument(
        "--label", action="append", default=[], metavar="KEY=VALUE", help="label the interaction (repeatable)"
    )


def main() -> None:
    p = argparse.ArgumentParser(prog="antigravity", description=__doc__)
    sub = p.add_subparsers(dest="cmd", required=True)

    pd = sub.add_parser("delegate", help="run a task in a remote Gemini sandbox")
    pd.add_argument("--prompt", required=True)
    pd.add_argument(
        "--tools",
        default=",".join(DEFAULT_TOOLS),
        help="comma list: code_execution,google_search,url_context",
    )
    pd.add_argument("--network", choices=["default", "none"], default="default")
    pd.add_argument("--repo", default=None, help="GitHub URL to mount at /workspace/repo")
    pd.add_argument("--environment-id", default=None, help="Reuse an existing sandbox environment")
    pd.add_argument("--previous-interaction-id", default=None, help="Continue from a previous interaction")
    pd.add_argument("--max-tokens", type=int, default=None, help="cap total tokens (input + output + thinking)")
    pd.add_argument("--model", default=None, help="underlying model, e.g. gemini-3.8-flash")
    pd.add_argument("--image", action="append", default=[], metavar="PATH", help="attach an image (repeatable)")
    pd.add_argument("--json", action="store_true", dest="json_output", help="ask for application/json output")
    add_common_options(pd)

    pr = sub.add_parser("research", help="run a deep-research query")
    pr.add_argument("--query", required=True)
    pr.add_argument(
        "--max",
        action="store_true",
        help=f"use max mode ({DEEP_RESEARCH_MAX_AGENT}) instead of {DEEP_RESEARCH_AGENT}",
    )
    pr.add_argument("--collaborative-planning", action="store_true", help="plan with the user first")
    pr.add_argument("--visualization", choices=["off", "auto"], default=None, help="include charts when useful")
    pr.add_argument("--thinking-summaries", choices=["auto", "none"], default=None)
    pr.add_argument("--bigquery", action="store_true", help="enable the BigQuery tool")
    add_common_options(pr)

    ps = sub.add_parser("status", help="print run status and result")
    ps.add_argument("--run", required=True)
    ps.add_argument("--full", action="store_true")
    ps.add_argument("--progress", action="store_true", help="include the streamed progress tail while running")

    pw = sub.add_parser("wait", help="block until a run reaches a terminal state")
    pw.add_argument("--run", required=True)
    pw.add_argument("--interval", type=int, default=5)
    pw.add_argument("--timeout", type=int, default=900)

    pc = sub.add_parser("cleanup", help="prune finished run directories")
    pc.add_argument("--older-than-days", type=float, default=7.0)
    pc.add_argument("--remote", action="store_true", help="also delete the stored interactions")
    pc.add_argument("--dry-run", action="store_true", help="list what would be removed")

    pwk = sub.add_parser("_worker")
    pwk.add_argument("run_id")

    args = p.parse_args()

    if args.cmd == "delegate":
        tools = [t.strip() for t in args.tools.split(",") if t.strip()]
        bad = [t for t in tools if t not in DEFAULT_TOOLS]
        if bad:
            fail(f"unsupported tool(s): {', '.join(bad)} (allowed: {', '.join(DEFAULT_TOOLS)})")
        start_run(
            "delegate",
            args.prompt,
            ANTIGRAVITY_AGENT,
            {
                "tools": tools,
                "network": args.network,
                "repo": args.repo,
                "environment_id": args.environment_id,
                "previous_interaction_id": args.previous_interaction_id,
                "max_tokens": args.max_tokens,
                "model": args.model,
                "images": args.image,
                "json_output": args.json_output,
                "system": args.system,
                "service_tier": args.tier,
                "labels": args.label,
            },
        )
    elif args.cmd == "research":
        start_run(
            "research",
            args.query,
            DEEP_RESEARCH_MAX_AGENT if args.max else DEEP_RESEARCH_AGENT,
            {
                "tools": [],
                "network": "default",
                "research_options": {
                    "collaborative_planning": True if args.collaborative_planning else None,
                    "visualization": args.visualization,
                    "thinking_summaries": args.thinking_summaries,
                    "enable_bigquery_tool": True if args.bigquery else None,
                },
                "system": args.system,
                "service_tier": args.tier,
                "labels": args.label,
            },
        )
    elif args.cmd == "status":
        print_status(args.run, full=args.full, progress=args.progress)
    elif args.cmd == "wait":
        cmd_wait(args.run, args.interval, args.timeout)
    elif args.cmd == "cleanup":
        cmd_cleanup(args.older_than_days, args.dry_run, args.remote)
    elif args.cmd == "_worker":
        cmd_worker(args.run_id)


if __name__ == "__main__":
    main()
