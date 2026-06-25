#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = ["google-genai>=1.51.0", "openai>=1.100.0", "httpx>=0.27.0"]
# ///
"""Generate (or edit) images via one of two explicit backends.

Backends are NOT auto-detected — pick one with `--backend` (or `IMAGE_BACKEND`):
  gemini  : Google's native Gemini API via `google-genai`. Full feature set —
            aspect_ratio, image_size tiers (1K/2K/4K), and multi-image
            edit/compose. Use GEMINI_API_KEY / GEMINI_IMAGE_MODEL.
  openai  : Any OpenAI-compatible image endpoint (OpenAI official, DashScope,
            self-hosted gateways, ...). Use OPENAI_API_KEY / OPENAI_BASE_URL /
            OPENAI_IMAGE_MODEL. Supports gpt-image-2, dall-e-3, etc.

Usage:
    generate_image.py --backend gemini "a red bicycle" -o out.png --aspect-ratio 16:9 --size 2K
    generate_image.py --backend gemini "swap sky to sunset" -i in.png -o edited.png
    generate_image.py --backend openai "a red bicycle" --base-url https://api.tu-zi.com/v1 \
        --model gpt-image-2 --size 1024x1024 --response-format url -o out.png

Configuration (each resolved progressively — flag, then env, then .env, then default):
    IMAGE_BACKEND               required  — `gemini` or `openai` (no default)
    GEMINI_API_KEY | GOOGLE_API_KEY   gemini only
    GEMINI_IMAGE_MODEL               gemini default `pro`
    OPENAI_API_KEY | IMAGE_API_KEY   openai only
    OPENAI_BASE_URL | IMAGE_BASE_URL openai (no default — must point at an endpoint)
    OPENAI_IMAGE_MODEL | IMAGE_MODEL openai (no default — must name a model)
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

# Friendly aliases -> exact model ids, per backend. An unrecognized value passes
# through unchanged, so a raw id (gpt-image-2, gemini-3-pro-image, ...) works via
# --model / *_IMAGE_MODEL with no code change.
GEMINI_MODELS = {
    "pro": "gemini-3-pro-image",        # highest quality (GA)
    "flash": "gemini-2.5-flash-image",  # faster / cheaper drafts
}
GEMINI_DEFAULT_MODEL = "pro"
GEMINI_SIZES = {"1K", "2K", "4K"}
ASPECT_RATIOS = ["1:1", "2:3", "3:2", "3:4", "4:3", "4:5", "5:4", "9:16", "16:9", "21:9"]
QUALITIES = ["low", "medium", "high", "auto"]


# --------------------------------------------------------------------------- #
# Gemini backend (native google-genai SDK)
# --------------------------------------------------------------------------- #
def run_gemini(args) -> int:
    from google import genai  # noqa: E402
    from google.genai import types  # noqa: E402

    # Accept either GEMINI_API_KEY or GOOGLE_API_KEY (both honored by the SDK).
    api_key = resolve("GEMINI_API_KEY", cli=args.api_key) or resolve("GOOGLE_API_KEY")
    if not api_key:
        return fail(
            "GEMINI_API_KEY is not set for the gemini backend. Get one at "
            "https://aistudio.google.com/app/apikey, then `export GEMINI_API_KEY=...` "
            "(or GOOGLE_API_KEY), or add it to a .env file."
        ) or 1

    model_sel = resolve("GEMINI_IMAGE_MODEL", cli=args.model, default=GEMINI_DEFAULT_MODEL)
    model = GEMINI_MODELS.get(model_sel, model_sel)

    if args.size and args.size not in GEMINI_SIZES:
        return fail(f"--size for the gemini backend must be one of {sorted(GEMINI_SIZES)} (got {args.size!r}).") or 1

    for img in args.input:
        if not Path(img).is_file():
            return fail(f"input image not found: {img}") or 1

    # aspect_ratio + image_size steer the output via ImageConfig; omit both to
    # let the model pick (matching the reference generator's default).
    image_config = None
    if args.aspect_ratio or args.size:
        kwargs = {}
        if args.aspect_ratio:
            kwargs["aspect_ratio"] = args.aspect_ratio
        if args.size:
            kwargs["image_size"] = args.size
        image_config = types.ImageConfig(**kwargs)
    config = types.GenerateContentConfig(
        response_modalities=["IMAGE", "TEXT"],
        image_config=image_config,
    )

    def build_parts(prompt: str, input_images: list[str]) -> list[types.Part]:
        parts: list[types.Part] = [types.Part.from_text(text=prompt)]
        for path in input_images:
            data = Path(path).read_bytes()
            mime = mimetypes.guess_type(path)[0] or "image/png"
            parts.append(types.Part.from_bytes(data=data, mime_type=mime))
        return parts

    client = genai.Client(api_key=api_key)
    contents = [types.Content(role="user", parts=build_parts(args.prompt, args.input))]

    detail = f"{args.aspect_ratio or 'auto'} | {args.size or 'auto'} | x{args.count}"
    print(f"Generating with {model} [gemini] ({detail})...", file=sys.stderr)

    def save_first_image(response, dest: Path) -> Path | None:
        """Write the first image part of a response to `dest` (extension fixed
        to the returned mime type). Gemini yields one image per call, so
        multiple outputs come from multiple calls."""
        for candidate in response.candidates or []:
            for part in candidate.content.parts or []:
                inline = getattr(part, "inline_data", None)
                if inline and inline.data:
                    ext = mimetypes.guess_extension(inline.mime_type) or ".png"
                    out = dest.with_suffix(ext)
                    out.write_bytes(inline.data)
                    print(f"  Saved: {out}", file=sys.stderr)
                    return out
                if getattr(part, "text", None):
                    print(f"  Note: {part.text.strip()[:200]}", file=sys.stderr)
        return None

    # Gemini 3 Pro Image yields one image per call, so loop for multiple candidates.
    out_base = Path(args.output)
    saved: list[Path] = []
    for i in range(max(1, args.count)):
        dest = out_base if args.count == 1 else out_base.with_name(
            f"{out_base.stem}_{i + 1}{out_base.suffix}"
        )
        response = client.models.generate_content(model=model, contents=contents, config=config)
        if result := save_first_image(response, dest):
            saved.append(result)

    if not saved:
        return fail("no image returned (the prompt may have been blocked by safety filters)") or 1
    print(f"Done: {len(saved)} image(s).", file=sys.stderr)
    return 0


# --------------------------------------------------------------------------- #
# OpenAI-compatible backend (openai SDK)
# --------------------------------------------------------------------------- #
def save_images_openai(data_items, out_base: Path, count: int) -> list[Path]:
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
            with urllib.request.urlopen(url, timeout=180) as r:  # noqa: S310 — url comes from the API response
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


def run_openai(args) -> int:
    from openai import APIError, OpenAI  # noqa: E402

    api_key = (resolve("OPENAI_API_KEY", cli=args.api_key)
               or resolve("IMAGE_API_KEY"))
    if not api_key:
        return fail(
            "OPENAI_API_KEY is not set for the openai backend. `export OPENAI_API_KEY=...`, "
            "add it to a .env file, or pass --api-key."
        ) or 1

    base_url = resolve("IMAGE_BASE_URL", cli=args.base_url) or resolve("OPENAI_BASE_URL")
    if not base_url:
        return fail(
            "No base URL set for the openai backend. Pass --base-url (e.g. "
            "https://api.openai.com/v1) or `export OPENAI_BASE_URL=...`."
        ) or 1

    model_sel = resolve("OPENAI_IMAGE_MODEL", cli=args.model) or resolve("IMAGE_MODEL")
    if not model_sel:
        return fail(
            "No model set for the openai backend. Pass --model (e.g. gpt-image-2) "
            "or `export OPENAI_IMAGE_MODEL=...`."
        ) or 1
    model = model_sel  # openai backend: no alias expansion, raw id passes through

    quality = resolve("OPENAI_IMAGE_QUALITY", cli=args.quality)
    response_format = resolve("IMAGE_RESPONSE_FORMAT", cli=args.response_format, default="b64_json")
    # "none" means: do not send response_format at all, let the endpoint default.
    rf_kwarg = {} if response_format == "none" else {"response_format": response_format}

    for img in args.input:
        if not Path(img).is_file():
            return fail(f"input image not found: {img}") or 1

    client = OpenAI(
        api_key=api_key,
        base_url=base_url,
        timeout=180.0,
        # Some OpenAI-compatible gateways mishandle HTTP/2 on long image
        # requests (~60s generations) — force HTTP/1.1, matching what curl
        # uses successfully against these endpoints.
        http_client=__import__("httpx").Client(http1=True, http2=False, timeout=180.0),
    )

    size = args.size or "auto"
    detail = f"{args.aspect_ratio or 'no aspect'} | {size} | x{args.count}"
    print(f"Generating with {model} @ {base_url} [openai] ({detail})...", file=sys.stderr)

    out_base = Path(args.output)
    count = max(1, args.count)

    if args.input:
        # /images/edits accepts a single image; first one wins if repeated.
        if len(args.input) > 1:
            print("  Note: OpenAI /images/edits accepts a single image; using the first of "
                  f"{len(args.input)} supplied.", file=sys.stderr)
        image_bytes = Path(args.input[0]).read_bytes()
        try:
            resp = client.images.edit(
                model=model,
                image=image_bytes,
                prompt=args.prompt,
                n=count,
                size=size,
                **rf_kwarg,
                **({"quality": quality} if quality else {}),
            )
        except APIError as e:
            return fail(f"endpoint rejected the edit: {e}") or 1
        except ValueError as e:
            # Some gateways return a non-JSON body (e.g. an HTML SPA fallback)
            # for an unsupported image endpoint — surface that cleanly.
            return fail(
                "endpoint returned a non-JSON response (the image endpoint may "
                f"not be enabled at this base URL): {e}"
            ) or 1
    else:
        # aspect_ratio travels via extra_body (honored by Gemini's OpenAI-compat
        # endpoint; ignored by OpenAI proper). quality is OpenAI-specific. Each
        # is sent only when set, so the other endpoint just never sees it.
        kwargs: dict = {}
        if args.aspect_ratio:
            kwargs["extra_body"] = {"aspect_ratio": args.aspect_ratio}
        if quality:
            kwargs["quality"] = quality
        try:
            resp = client.images.generate(
                model=model,
                prompt=args.prompt,
                n=count,
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

    saved = save_images_openai(getattr(resp, "data", None) or [], out_base, count)

    if not saved:
        return fail("no image returned (the prompt may have been blocked by safety filters, or the endpoint rejected the request)") or 1
    print(f"Done: {len(saved)} image(s).", file=sys.stderr)
    return 0


# --------------------------------------------------------------------------- #
# Entry
# --------------------------------------------------------------------------- #
def main() -> int:
    ap = argparse.ArgumentParser(description="Generate or edit images via the gemini or openai backend.")
    ap.add_argument("prompt", help="What to draw, or how to edit the input image(s).")
    ap.add_argument("-o", "--output", default="generated.png", help="Output path (default: generated.png)")
    ap.add_argument("-i", "--input", action="append", default=[], metavar="IMG",
                    help="Reference/input image to edit or compose (repeatable).")
    ap.add_argument("--backend", choices=["gemini", "openai"],
                    help="Backend: gemini (native Google API) or openai (OpenAI-compatible endpoint). No default — also via IMAGE_BACKEND.")
    ap.add_argument("--aspect-ratio", choices=ASPECT_RATIOS,
                    help="Force an aspect ratio. gemini: via image_config. openai: via extra_body (Gemini-compat endpoints only).")
    ap.add_argument("--size",
                    help="Output size. gemini: 1K/2K/4K. openai: free string (1024x1024, auto, ...). Default: auto / model decides.")
    ap.add_argument("--count", type=int, default=1, help="Number of images to request (default: 1).")
    ap.add_argument("--model", help="Model id or alias (else GEMINI_IMAGE_MODEL / OPENAI_IMAGE_MODEL). gemini: pro|flash|raw id. openai: raw id (e.g. gpt-image-2).")
    ap.add_argument("--quality", choices=QUALITIES, help="openai backend only (low/medium/high/auto). Also via OPENAI_IMAGE_QUALITY.")
    ap.add_argument("--response-format", choices=["b64_json", "url", "none"],
                    help="openai backend only: b64_json (default), url (downloaded to disk), or none (omit param). Also via IMAGE_RESPONSE_FORMAT.")
    ap.add_argument("--base-url", help="openai backend only: OpenAI-compatible base URL. Also via IMAGE_BASE_URL/OPENAI_BASE_URL.")
    ap.add_argument("--api-key", help="Override the API key (else GEMINI_API_KEY for gemini, OPENAI_API_KEY for openai).")
    args = ap.parse_args()

    # No default backend — the user must opt into one. Resolved from the flag or
    # IMAGE_BACKEND; if neither is set, fail with guidance rather than guess.
    backend = resolve("IMAGE_BACKEND", cli=args.backend)
    if backend is None:
        return fail(
            "No backend selected. Pass --backend gemini or --backend openai "
            "(or `export IMAGE_BACKEND=gemini|openai`)."
        ) or 1

    if backend == "gemini":
        return run_gemini(args)
    return run_openai(args)


if __name__ == "__main__":
    raise SystemExit(main())
