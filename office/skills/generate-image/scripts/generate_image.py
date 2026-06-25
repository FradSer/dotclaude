#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = ["openai>=1.100.0"]
# ///
"""Generate (or edit) images via any OpenAI-compatible image endpoint.

A single `openai` SDK call covers every backend: the default base URL points
at Google's Gemini OpenAI-compatibility endpoint (so `gemini-3-pro-image`
works out of the box), and pointing `--base-url` at OpenAI proper, DashScope,
or a self-hosted gateway switches backends without any code change. Model,
base URL, and API key are each resolved progressively (see
lib/progressive_env.py) — flag → env → `.env` → built-in default.

Usage:
    generate_image.py "a red bicycle leaning on a brick wall, golden hour"
    generate_image.py "isometric office, soft light" -o office.png --aspect-ratio 16:9
    generate_image.py "make the sky a dramatic sunset" -i input.png -o edited.png
    generate_image.py "a red bicycle" --base-url https://api.openai.com/v1 --model gpt-image-2 -o oai.png

Configuration (each resolved progressively — flag, then env, then .env, then default):
    GEMINI_API_KEY | OPENAI_API_KEY   required  — API key for the chosen endpoint
    IMAGE_BASE_URL  | OPENAI_BASE_URL default   — Gemini compat endpoint if unset
    GEMINI_IMAGE_MODEL | IMAGE_MODEL   default  — `pro` alias (gemini-3-pro-image)
"""

import argparse
import base64
import mimetypes
import sys
import urllib.request
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

from progressive_env import fail, register_env_dirs, resolve  # noqa: E402

# Let a .env sitting next to this skill participate as the lowest-priority layer.
register_env_dirs(Path(__file__).resolve().parent, Path(__file__).resolve().parents[1])

from openai import APIError, OpenAI  # noqa: E402

# Friendly aliases -> exact model ids. The default base URL is Google's
# OpenAI-compatibility endpoint, so the defaults are Gemini image ids. An
# unrecognized value passes through unchanged, so `gpt-image-2` (or any future
# id) works via --model / GEMINI_IMAGE_MODEL with no code change.
MODELS = {
    "pro": "gemini-3-pro-image",        # highest quality (GA)
    "flash": "gemini-2.5-flash-image",  # faster / cheaper drafts
}
DEFAULT_MODEL = "pro"
# The Gemini OpenAI-compatibility endpoint — used when nothing else specifies
# a base URL, so existing Gemini users keep working without any config change.
DEFAULT_BASE_URL = "https://generativelanguage.googleapis.com/v1beta/openai/"
GEMINI_DEFAULT_HOST = "generativelanguage.googleapis.com"
ASPECT_RATIOS = ["1:1", "2:3", "3:2", "3:4", "4:3", "4:5", "5:4", "9:16", "16:9", "21:9"]
QUALITIES = ["low", "medium", "high", "auto"]


def save_images(data_items, out_base: Path, count: int) -> list[Path]:
    """Write each returned image to disk. Handles both `b64_json` (decoded
    inline) and `url` (downloaded) response formats. One file per item; when
    multiple are expected, names are suffixed `_1`, `_2`, ..."""
    saved: list[Path] = []
    items = list(data_items)
    for i, item in enumerate(items):
        b64 = getattr(item, "b64_json", None)
        url = getattr(item, "url", None)
        if b64:
            data = base64.b64decode(b64)
        elif url:
            print(f"  Fetching: {url}", file=sys.stderr)
            with urllib.request.urlopen(url, timeout=120) as r:  # noqa: S310 — url comes from the API response
                data = r.read()
        else:
            continue
        if count == 1:
            dest = out_base
        else:
            dest = out_base.with_name(f"{out_base.stem}_{i + 1}{out_base.suffix}")
        dest.write_bytes(data)
        print(f"  Saved: {dest}", file=sys.stderr)
        saved.append(dest)
    return saved


def is_gemini_endpoint(base_url: str) -> bool:
    return GEMINI_DEFAULT_HOST in base_url


def main() -> int:
    ap = argparse.ArgumentParser(description="Generate or edit images via any OpenAI-compatible image endpoint.")
    ap.add_argument("prompt", help="What to draw, or how to edit the input image(s).")
    ap.add_argument("-o", "--output", default="generated.png", help="Output path (default: generated.png)")
    ap.add_argument("-i", "--input", action="append", default=[], metavar="IMG",
                    help="Reference/input image to edit or compose (repeatable).")
    ap.add_argument("--aspect-ratio", choices=ASPECT_RATIOS,
                    help="Force an aspect ratio (Gemini endpoint only; passed via extra_body). OpenAI endpoints ignore this.")
    ap.add_argument("--size", help="Output size as a free string (e.g. 1024x1024, 1536x1536, auto). Default: auto.")
    ap.add_argument("--count", type=int, default=1, help="Number of images to request (default: 1).")
    ap.add_argument("--model", help="Model: pro|flash alias, or a full id like gpt-image-2 (else GEMINI_IMAGE_MODEL/IMAGE_MODEL). Default: pro.")
    ap.add_argument("--quality", choices=QUALITIES, help="OpenAI-endpoint quality tier (low/medium/high/auto). Gemini endpoint ignores this.")
    ap.add_argument("--response-format", choices=["b64_json", "url", "none"],
                    help="How the endpoint returns the image: b64_json (default), url (downloaded to disk), or none (let the endpoint pick). Some compatible gateways reject this param — use 'none' there.")
    ap.add_argument("--base-url", help="OpenAI-compatible base URL (else IMAGE_BASE_URL/OPENAI_BASE_URL). Default: Gemini compat endpoint.")
    ap.add_argument("--api-key", help="Override the API key (else GEMINI_API_KEY/OPENAI_API_KEY).")
    args = ap.parse_args()

    # API key: accept the legacy Gemini name first (existing .env/export), then
    # the OpenAI generic name. Either works for either endpoint — a key is just
    # a key, the endpoint decides what it honors.
    api_key = (resolve("GEMINI_API_KEY", cli=args.api_key)
               or resolve("OPENAI_API_KEY")
               or resolve("IMAGE_API_KEY"))
    if not api_key:
        return fail(
            "No API key set. For the default Gemini endpoint, set GEMINI_API_KEY "
            "(get one at https://aistudio.google.com/app/apikey). For an OpenAI-compatible "
            "endpoint, set OPENAI_API_KEY. Provide via the --api-key flag, `export`, or a .env file."
        ) or 1

    base_url = resolve("IMAGE_BASE_URL", cli=args.base_url) or resolve("OPENAI_BASE_URL")
    if not base_url:
        base_url = DEFAULT_BASE_URL

    model_sel = (resolve("GEMINI_IMAGE_MODEL", cli=args.model)
                 or resolve("IMAGE_MODEL", default=DEFAULT_MODEL))
    model = MODELS.get(model_sel, model_sel)  # expand alias; pass a raw id through

    quality = resolve("OPENAI_IMAGE_QUALITY", cli=args.quality)
    response_format = resolve("IMAGE_RESPONSE_FORMAT", cli=args.response_format, default="b64_json")
    # "none" means: do not send response_format at all, let the endpoint default.
    rf_kwarg = {} if response_format == "none" else {"response_format": response_format}

    for img in args.input:
        if not Path(img).is_file():
            return fail(f"input image not found: {img}") or 1

    client = OpenAI(api_key=api_key, base_url=base_url)

    size = args.size or "auto"
    detail = f"{args.aspect_ratio or 'no aspect'} | {size} | x{args.count}"
    print(f"Generating with {model} @ {base_url} ({detail})...", file=sys.stderr)

    out_base = Path(args.output)
    saved: list[Path] = []

    if args.input:
        # Edit path. /images/edits is an OpenAI-endpoint capability; the Gemini
        # compatibility layer does not document it, so refuse there rather than
        # emit a confusing 404.
        if is_gemini_endpoint(base_url):
            return fail(
                "The Gemini OpenAI-compatibility endpoint does not support /images/edits. "
                "Point --base-url at an OpenAI-compatible endpoint that does (e.g. "
                "https://api.openai.com/v1), or drop -i to generate from scratch."
            ) or 1
        if len(args.input) > 1:
            print("  Note: OpenAI /images/edits accepts a single image; using the first of "
                  f"{len(args.input)} supplied.", file=sys.stderr)
        image_bytes = Path(args.input[0]).read_bytes()
        try:
            resp = client.images.edit(
                model=model,
                image=image_bytes,
                prompt=args.prompt,
                n=max(1, args.count),
                size=size,
                **rf_kwarg,
                **({"quality": quality} if quality else {}),
            )
        except APIError as e:
            return fail(f"endpoint rejected the edit: {e}") or 1
        except ValueError as e:
            # Some gateways return a non-JSON body (e.g. an HTML SPA fallback
            # page) for an unsupported image endpoint — surface that cleanly
            # instead of a raw JSONDecodeError traceback.
            return fail(
                "endpoint returned a non-JSON response (the image endpoint may "
                f"not be enabled at this base URL): {e}"
            ) or 1
    else:
        # Generate path. aspect_ratio is Gemini-specific and travels via
        # extra_body; quality is OpenAI-specific. Each is sent only when set,
        # so the other endpoint just never sees it.
        kwargs: dict = {}
        if args.aspect_ratio:
            kwargs["extra_body"] = {"aspect_ratio": args.aspect_ratio}
        if quality:
            kwargs["quality"] = quality
        try:
            resp = client.images.generate(
                model=model,
                prompt=args.prompt,
                n=max(1, args.count),
                size=size,
                **rf_kwarg,
                **kwargs,
            )
        except APIError as e:
            return fail(f"endpoint rejected the request: {e}") or 1
        except ValueError as e:
            return fail(
                "endpoint returned a non-JSON response (the image endpoint may "
                f"not be enabled at this base URL): {e}"
            ) or 1

    saved = save_images(getattr(resp, "data", None) or [], out_base, max(1, args.count))

    if not saved:
        return fail("no image returned (the prompt may have been blocked by safety filters, or the endpoint rejected the request)") or 1
    print(f"Done: {len(saved)} image(s).", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
