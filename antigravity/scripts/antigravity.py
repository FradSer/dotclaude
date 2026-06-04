#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = ["google-genai>=1.55.0"]
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
  _worker    Internal: the detached process that performs the interaction.

State lives under ~/.antigravity/runs/<run-id>/:
  meta.json     request metadata + server interaction/environment ids
  status        one word: starting | running | completed | failed
  output.json   structured result
  output.md     human-readable result
  worker.err    worker stderr (diagnostics)
"""

import argparse
import json
import os
import subprocess
import sys
import time
import uuid
from datetime import datetime, timezone
from pathlib import Path

ANTIGRAVITY_AGENT = "antigravity-preview-05-2026"
DEEP_RESEARCH_AGENT = "deep-research-preview-04-2026"
DEEP_RESEARCH_MAX_AGENT = "deep-research-max-preview-04-2026"
DEFAULT_TOOLS = ["code_execution", "google_search", "url_context"]
# Local run states written to the status file.
TERMINAL = {"completed", "failed"}
# Server-side interaction states that mean "still working"; anything else is terminal.
SERVER_ACTIVE = {"queued", "in_progress", "running", "pending"}
POLL_INTERVAL = 10  # seconds between interactions.get() polls
GET_TIMEOUT = 60  # per-get() timeout so a long-poll can't block the deadline check
WORKER_DEADLINE = 7200  # seconds before the worker gives up (deep research is slow)

RUNS_DIR = Path(os.environ.get("ANTIGRAVITY_HOME", Path.home() / ".antigravity")) / "runs"


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


# --- Request building -------------------------------------------------------

def build_environment(network: str, repo: str | None) -> dict:
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


def build_create_kwargs(meta: dict) -> dict:
    # background differs per agent: the deep-research agent REQUIRES background=True
    # (server runs async; the worker polls get() until terminal), while the
    # antigravity agent REJECTS background and runs synchronously (create() blocks
    # until done — fine here since the worker is detached).
    kwargs: dict = {"agent": meta["agent"], "input": meta["prompt"], "store": True}
    if meta["kind"] == "research":
        kwargs["background"] = True
        kwargs["agent_config"] = {"type": "deep-research"}
    else:
        kwargs["tools"] = [{"type": t} for t in meta["tools"]]
        kwargs["environment"] = build_environment(meta["network"], meta.get("repo"))
    return kwargs


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
    return "\n".join(parts)


def summarize_steps(steps) -> tuple[list[str], dict]:
    lines: list[str] = []
    counts: dict[str, int] = {}
    for step in steps or []:
        stype = getattr(step, "type", "unknown")
        counts[stype] = counts.get(stype, 0) + 1
        if stype == "code_execution_call":
            code = getattr(getattr(step, "arguments", None), "code", "") or ""
            lines.append(f"[code] {code.strip().splitlines()[0][:100] if code.strip() else ''}")
        elif stype == "google_search_call":
            queries = getattr(getattr(step, "arguments", None), "queries", []) or []
            lines.append(f"[search] {', '.join(map(str, queries))[:120]}")
        elif stype == "url_context_call":
            urls = getattr(getattr(step, "arguments", None), "urls", []) or []
            lines.append(f"[url] {', '.join(map(str, urls))[:120]}")
    return lines, counts


def extract_result(interaction) -> dict:
    steps = list(getattr(interaction, "steps", []) or [])
    output_text = getattr(interaction, "output_text", None)
    if not output_text:
        for step in reversed(steps):
            if getattr(step, "type", None) == "model_output":
                output_text = text_from_step(step)
                if output_text:
                    break
    step_lines, counts = summarize_steps(steps)
    usage = getattr(interaction, "usage", None)
    return {
        "interaction_id": getattr(interaction, "id", None),
        "environment_id": getattr(interaction, "environment_id", None),
        "status": str(getattr(interaction, "status", "") or ""),
        "output_text": output_text or "",
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
    ]
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
    return "\n".join(lines) + "\n"


# --- Worker (detached) ------------------------------------------------------

def cmd_worker(run_id: str) -> None:
    d = run_dir(run_id)
    meta = json.loads((d / "meta.json").read_text())
    write_status(run_id, "running")
    try:
        from google import genai

        api_key = os.environ.get("GEMINI_API_KEY") or os.environ.get("GOOGLE_API_KEY")
        if not api_key:
            raise RuntimeError("GEMINI_API_KEY is not set")
        client = genai.Client(api_key=api_key)
        meta["started_at"] = now()
        write_json(d / "meta.json", meta)

        interaction = client.interactions.create(**build_create_kwargs(meta))
        iid = getattr(interaction, "id", None)
        meta["interaction_id"] = iid
        meta["environment_id"] = getattr(interaction, "environment_id", None)
        write_json(d / "meta.json", meta)

        # Background (research) returns immediately and must be polled until the
        # server finishes. Synchronous (delegate) create() already returns a
        # terminal interaction, so the loop is skipped. Each get() carries its own
        # timeout: without one the SDK can long-poll and block the deadline check.
        deadline = time.monotonic() + WORKER_DEADLINE
        srv_status = str(getattr(interaction, "status", "") or "")
        while meta["kind"] == "research" and (srv_status in SERVER_ACTIVE or not srv_status):
            if time.monotonic() >= deadline:
                raise TimeoutError(f"worker gave up after {WORKER_DEADLINE}s (last: {srv_status})")
            time.sleep(POLL_INTERVAL)
            try:
                interaction = client.interactions.get(iid, timeout=GET_TIMEOUT)
                srv_status = str(getattr(interaction, "status", "") or "")
            except Exception as poll_exc:  # noqa: BLE001 - transient poll errors must not kill a live run
                (d / "worker.err").open("a").write(f"poll error (retrying): {poll_exc}\n")

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

def start_run(kind: str, prompt: str, agent: str, tools, network: str, repo) -> None:
    if not prompt or not prompt.strip():
        fail("prompt/query is empty")
    run_id = datetime.now().strftime("%Y%m%d-%H%M%S") + "-" + uuid.uuid4().hex[:6]
    d = run_dir(run_id)
    d.mkdir(parents=True, exist_ok=True)
    meta = {
        "run_id": run_id,
        "kind": kind,
        "agent": agent,
        "prompt": prompt,
        "tools": tools,
        "network": network,
        "repo": repo,
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
    print(f"status_file: {d / 'status'}")
    print(f"output_file: {d / 'output.md'}")
    print(f"wait_command: {os.path.abspath(__file__)} wait --run {run_id}")
    print(f"status_command: {os.path.abspath(__file__)} status --run {run_id}")


# --- status / wait ----------------------------------------------------------

def print_status(run_id: str, full: bool) -> None:
    d = run_dir(run_id)
    if not d.exists():
        fail(f"unknown run: {run_id}")
    status = read_status(run_id)
    print(f"status: {status}")
    if status not in TERMINAL:
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


def cmd_wait(run_id: str, interval: int, timeout: int) -> None:
    if not run_dir(run_id).exists():
        fail(f"unknown run: {run_id}")
    deadline = time.monotonic() + timeout
    while True:
        status = read_status(run_id)
        if status in TERMINAL:
            print(f"antigravity run {run_id}: {status}")
            return
        if time.monotonic() >= deadline:
            print(f"antigravity run {run_id}: timeout (still {status})")
            return
        time.sleep(interval)


# --- CLI --------------------------------------------------------------------

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

    pr = sub.add_parser("research", help="run a deep-research query")
    pr.add_argument("--query", required=True)
    pr.add_argument(
        "--max",
        action="store_true",
        help=f"use max mode ({DEEP_RESEARCH_MAX_AGENT}) instead of {DEEP_RESEARCH_AGENT}",
    )

    ps = sub.add_parser("status", help="print run status and result")
    ps.add_argument("--run", required=True)
    ps.add_argument("--full", action="store_true")

    pw = sub.add_parser("wait", help="block until a run reaches a terminal state")
    pw.add_argument("--run", required=True)
    pw.add_argument("--interval", type=int, default=5)
    pw.add_argument("--timeout", type=int, default=900)

    pwk = sub.add_parser("_worker")
    pwk.add_argument("run_id")

    args = p.parse_args()

    if args.cmd == "delegate":
        tools = [t.strip() for t in args.tools.split(",") if t.strip()]
        bad = [t for t in tools if t not in DEFAULT_TOOLS]
        if bad:
            fail(f"unsupported tool(s): {', '.join(bad)} (allowed: {', '.join(DEFAULT_TOOLS)})")
        start_run("delegate", args.prompt, ANTIGRAVITY_AGENT, tools, args.network, args.repo)
    elif args.cmd == "research":
        agent = DEEP_RESEARCH_MAX_AGENT if args.max else DEEP_RESEARCH_AGENT
        start_run("research", args.query, agent, [], "default", None)
    elif args.cmd == "status":
        print_status(args.run, full=args.full)
    elif args.cmd == "wait":
        cmd_wait(args.run, args.interval, args.timeout)
    elif args.cmd == "_worker":
        cmd_worker(args.run_id)


if __name__ == "__main__":
    main()
