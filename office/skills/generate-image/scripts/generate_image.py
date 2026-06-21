#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = ["google-genai>=1.51.0"]
# ///
"""Generate (or edit) images with Google's Gemini 3 Pro Image model.

The model is multimodal: a text prompt plus zero or more reference images go in,
one or more generated images come back in the response parts. This is the same
call the RayNeo storyboard generator uses, wrapped as a reusable CLI with
progressive configuration (see lib/progressive_env.py).

Usage:
    generate_image.py "a red bicycle leaning on a brick wall, golden hour"
    generate_image.py "isometric office, soft light" -o office.png --aspect-ratio 16:9 --size 2K
    generate_image.py "make the sky a dramatic sunset" -i input.png -o edited.png
    generate_image.py "blend these into one scene" -i a.png -i b.png -o blend.png --count 2

Configuration (each resolved progressively — flag, then env, then .env, then default):
    GEMINI_API_KEY     required  — Google AI Studio key (https://aistudio.google.com/app/apikey)
    GEMINI_IMAGE_MODEL default gemini-3-pro-image — override to pin a preview/newer id
"""

import argparse
import mimetypes
import sys
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

from google import genai  # noqa: E402
from google.genai import types  # noqa: E402

# Friendly aliases -> exact model ids. An unrecognized value passes through
# unchanged, so a newer id works via --model / GEMINI_IMAGE_MODEL with no code change.
MODELS = {
    "pro": "gemini-3-pro-image",        # highest quality
    "flash": "gemini-3.1-flash-image",  # faster / cheaper ("Nano Banana 2")
}
DEFAULT_MODEL = "pro"
ASPECT_RATIOS = ["1:1", "2:3", "3:2", "3:4", "4:3", "4:5", "5:4", "9:16", "16:9", "21:9"]
IMAGE_SIZES = ["1K", "2K", "4K"]


def build_parts(prompt: str, input_images: list[str]) -> list[types.Part]:
    parts: list[types.Part] = [types.Part.from_text(text=prompt)]
    for path in input_images:
        data = Path(path).read_bytes()
        mime = mimetypes.guess_type(path)[0] or "image/png"
        parts.append(types.Part.from_bytes(data=data, mime_type=mime))
    return parts


def build_config(aspect_ratio: str | None, size: str | None) -> types.GenerateContentConfig:
    image_config = None
    if aspect_ratio or size:
        # Only construct ImageConfig when the user asked to steer it; otherwise
        # let the model pick, matching the reference generator's default.
        kwargs = {}
        if aspect_ratio:
            kwargs["aspect_ratio"] = aspect_ratio
        if size:
            kwargs["image_size"] = size
        image_config = types.ImageConfig(**kwargs)
    return types.GenerateContentConfig(
        response_modalities=["IMAGE", "TEXT"],
        image_config=image_config,
    )


def save_first_image(response, dest: Path) -> Path | None:
    """Write the first image part of a response to `dest` (extension fixed to
    the returned mime type). Gemini 3 Pro Image returns one image per call, so
    multiple outputs come from multiple calls, not from one multi-image response."""
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


def main() -> int:
    ap = argparse.ArgumentParser(description="Generate or edit images with Gemini 3 Pro Image.")
    ap.add_argument("prompt", help="What to draw, or how to edit the input image(s).")
    ap.add_argument("-o", "--output", default="generated.png", help="Output path (default: generated.png)")
    ap.add_argument("-i", "--input", action="append", default=[], metavar="IMG",
                    help="Reference/input image to edit or compose (repeatable).")
    ap.add_argument("--aspect-ratio", choices=ASPECT_RATIOS, help="Force an aspect ratio (default: model decides).")
    ap.add_argument("--size", choices=IMAGE_SIZES, help="Output resolution tier (default: model decides).")
    ap.add_argument("--count", type=int, default=1, help="Number of images to request (default: 1).")
    ap.add_argument("--model", help="Model: pro|flash alias, or a full id (else GEMINI_IMAGE_MODEL). Default: pro.")
    ap.add_argument("--api-key", help="Override the API key (else GEMINI_API_KEY).")
    args = ap.parse_args()

    # Accept either GEMINI_API_KEY or GOOGLE_API_KEY (both are honored by the SDK).
    api_key = resolve("GEMINI_API_KEY", cli=args.api_key) or resolve("GOOGLE_API_KEY")
    if not api_key:
        return fail(
            "GEMINI_API_KEY is not set. Get one at https://aistudio.google.com/app/apikey, "
            "then `export GEMINI_API_KEY=...` (or GOOGLE_API_KEY), or add it to a .env file."
        ) or 1

    model_sel = resolve("GEMINI_IMAGE_MODEL", cli=args.model, default=DEFAULT_MODEL)
    model = MODELS.get(model_sel, model_sel)  # expand alias; pass a raw id through

    for img in args.input:
        if not Path(img).is_file():
            return fail(f"input image not found: {img}") or 1

    client = genai.Client(api_key=api_key)
    contents = [types.Content(role="user", parts=build_parts(args.prompt, args.input))]
    config = build_config(args.aspect_ratio, args.size)

    detail = f"{args.aspect_ratio or 'auto'} | {args.size or 'auto'} | x{args.count}"
    print(f"Generating with {model} ({detail})...", file=sys.stderr)

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


if __name__ == "__main__":
    raise SystemExit(main())
