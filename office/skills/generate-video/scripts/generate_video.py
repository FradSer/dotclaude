#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = ["requests>=2.31.0"]
# ///
"""Generate video with ByteDance Seedance on Volcengine Ark (火山方舟).

Submits an async generation task, polls until it succeeds, and downloads the
result. Supports pure text-to-video and image-to-video, where reference images
are attached with a role (`first_frame`, `last_frame`, or `reference_image`) —
the same contract the RayNeo seedance-video-gen scripts use, wrapped as a
reusable CLI with progressive configuration (see lib/progressive_env.py).

Usage:
    generate_video.py "a paper plane glides over a city at dawn, cinematic"
    generate_video.py "gentle breathing motion, keep the line-art style" --first-frame panel.png
    generate_video.py "morph the start frame into the end frame" \
        --first-frame a.png --last-frame b.png --duration 10 --resolution 1080p
    generate_video.py "orbit the product" --image hero.png:reference_image -o demo.mp4

Configuration (each resolved progressively — flag, then env, then .env, then default):
    ARK_API_KEY     required  — Volcengine Ark key (https://console.volcengine.com/ark)
    SEEDANCE_MODEL  default doubao-seedance-2-0-260128 — set this to switch model versions
    ARK_BASE_URL    default https://ark.cn-beijing.volces.com/api/v3 — e.g. an int'l region
"""

import argparse
import base64
import sys
import time
from pathlib import Path

# --- locate the shared progressive-env helper (office/lib/progressive_env.py) ---
_LIB = None
for _base in Path(__file__).resolve().parents:
    if (_base / "lib" / "progressive_env.py").is_file():
        _LIB = _base / "lib"
        break
if _LIB is None and (_root := __import__("os").environ.get("CLAUDE_PLUGIN_ROOT")):
    if (Path(_root) / "lib" / "progressive_env.py").is_file():
        _LIB = Path(_root) / "lib"
if _LIB is None:
    sys.exit("Error: could not locate office/lib/progressive_env.py")
sys.path.insert(0, str(_LIB))

from progressive_env import MissingConfig, fail, register_env_dirs, resolve, resolve_secret  # noqa: E402

register_env_dirs(Path(__file__).resolve().parent, Path(__file__).resolve().parents[1])

import requests  # noqa: E402

# Friendly aliases -> exact Ark model ids. An unrecognized value passes through
# unchanged, so a newer id works via --model / SEEDANCE_MODEL with no code change.
MODELS = {
    "pro": "doubao-seedance-2-0-260128",        # full quality, up to 1080p
    "fast": "doubao-seedance-2-0-fast-260128",  # cheaper / faster, 720p max
    "mini": "doubao-seedance-2-0-mini-260615",  # lightest / cheapest
}
DEFAULT_MODEL = "pro"
DEFAULT_BASE_URL = "https://ark.cn-beijing.volces.com/api/v3"
ROLES = {"first_frame", "last_frame", "reference_image"}
POLL_INTERVAL = 10


def encode_image(path: str) -> str:
    data = base64.b64encode(Path(path).read_bytes()).decode()
    ext = Path(path).suffix.lstrip(".").lower() or "png"
    if ext == "jpg":
        ext = "jpeg"
    return f"data:image/{ext};base64,{data}"


def build_content(prompt: str, images: list[tuple[str, str]]) -> list[dict]:
    content: list[dict] = [{"type": "text", "text": prompt}]
    for path, role in images:
        content.append({
            "type": "image_url",
            "image_url": {"url": encode_image(path)},
            "role": role,
        })
    return content


def create_task(session, base_url, payload) -> str:
    resp = session.post(f"{base_url}/contents/generations/tasks", json=payload)
    if resp.status_code >= 400:
        fail(f"task creation failed ({resp.status_code}): {resp.text}")
    resp.raise_for_status()
    return resp.json()["id"]


def poll_task(session, base_url, task_id) -> dict:
    while True:
        resp = session.get(f"{base_url}/contents/generations/tasks/{task_id}")
        resp.raise_for_status()
        result = resp.json()
        status = result.get("status", "unknown")
        print(f"  Status: {status}", file=sys.stderr)
        if status == "succeeded":
            return result
        if status in ("failed", "cancelled", "expired"):
            fail(f"task {status}: {result.get('error') or result}")
        time.sleep(POLL_INTERVAL)


def download(url: str, output: Path) -> None:
    resp = requests.get(url, timeout=300)
    resp.raise_for_status()
    output.write_bytes(resp.content)
    print(f"  Saved: {output}", file=sys.stderr)


def collect_images(args) -> list[tuple[str, str]]:
    images: list[tuple[str, str]] = []
    if args.first_frame:
        images.append((args.first_frame, "first_frame"))
    if args.last_frame:
        images.append((args.last_frame, "last_frame"))
    for spec in args.image:
        path, _, role = spec.partition(":")
        role = role or "reference_image"
        if role not in ROLES:
            fail(f"unknown image role '{role}' (choose from: {', '.join(sorted(ROLES))})")
        images.append((path, role))
    for path, _ in images:
        if not Path(path).is_file():
            fail(f"image not found: {path}")
    return images


def main() -> int:
    ap = argparse.ArgumentParser(description="Generate video with Seedance on Volcengine Ark.")
    ap.add_argument("prompt", help="Text prompt describing the shot / motion.")
    ap.add_argument("-o", "--output", default="output.mp4", help="Output path (default: output.mp4)")
    ap.add_argument("--first-frame", metavar="IMG", help="Start-frame image (image-to-video).")
    ap.add_argument("--last-frame", metavar="IMG", help="End-frame image (morph start->end).")
    ap.add_argument("--image", action="append", default=[], metavar="PATH[:ROLE]",
                    help="Reference image as PATH or PATH:ROLE (role in first_frame|last_frame|reference_image). Repeatable.")
    ap.add_argument("--ratio", default="16:9", help="Aspect ratio, e.g. 16:9, 9:16, 1:1 (default: 16:9).")
    ap.add_argument("--duration", type=int, default=5, help="Clip length in seconds (default: 5).")
    ap.add_argument("--resolution", default="720p", help="480p | 720p | 1080p (default: 720p).")
    ap.add_argument("--watermark", action="store_true", help="Keep the provider watermark (off by default).")
    ap.add_argument("--no-audio", dest="audio", action="store_false",
                    help="Disable native audio (Seedance 2.0 generates synced audio by default).")
    ap.add_argument("--seed", type=int, help="Seed for reproducible output (optional).")
    ap.add_argument("--model", help="Model: pro|fast|mini alias, or a full id (else SEEDANCE_MODEL). Default: pro.")
    ap.add_argument("--api-key", help="Override the API key (else ARK_API_KEY).")
    args = ap.parse_args()

    try:
        api_key = resolve_secret(
            "ARK_API_KEY",
            cli=args.api_key,
            hint="ARK_API_KEY is not set. Create one at https://console.volcengine.com/ark, "
                 "then `export ARK_API_KEY=...` or add it to a .env file.",
        )
    except MissingConfig as e:
        return fail(str(e)) or 1

    model_sel = resolve("SEEDANCE_MODEL", cli=args.model, default=DEFAULT_MODEL)
    model = MODELS.get(model_sel, model_sel)  # expand alias; pass a raw id through
    base_url = resolve("ARK_BASE_URL", default=DEFAULT_BASE_URL).rstrip("/")

    images = collect_images(args)
    payload = {
        "model": model,
        "content": build_content(args.prompt, images),
        "ratio": args.ratio,
        "duration": args.duration,
        "resolution": args.resolution,
        "watermark": args.watermark,
        "generate_audio": args.audio,
    }
    if args.seed is not None:
        payload["seed"] = args.seed

    session = requests.Session()
    session.headers.update({"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"})

    mode = "image-to-video" if images else "text-to-video"
    print(f"Creating {mode} task with {model} ({args.resolution}, {args.duration}s, {args.ratio})...", file=sys.stderr)
    task_id = create_task(session, base_url, payload)
    print(f"  Task: {task_id}", file=sys.stderr)

    result = poll_task(session, base_url, task_id)
    video_url = (result.get("content") or {}).get("video_url")
    if not video_url:
        return fail(f"task succeeded but no video_url in response: {result}") or 1

    download(video_url, Path(args.output))
    print("Done.", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
