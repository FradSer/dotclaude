"""Progressive (layered, lazy) configuration resolution for Office plugin scripts.

The goal is "渐进式调用环境变量": never hard-code a key, a model id or an
endpoint, and never demand a value until the moment it is actually needed.
A value is resolved by walking a chain of sources and stopping at the first
hit, so the most specific intent always wins and the least specific (a sane
built-in default) only applies when nothing else spoke up:

    1. an explicit CLI argument            (cli=...)        — caller said so
    2. the process environment             (os.environ)     — the shell/session
    3. a .env file, searched progressively  (see below)      — project secrets
    4. a built-in default                   (default=...)     — last resort

`.env` files are a *fallback* layer, not an override: a value already present
in the real environment is trusted over a file on disk. The files are searched
in this order and the first file found in each location contributes (closer
locations win):

    $PWD/.env                       — the project the user is working in
    $CLAUDE_PLUGIN_ROOT/.env        — shared plugin-level secrets (if set)
    <each dir passed via env_dirs>  — e.g. the script's own directory

Nothing here imports a third-party package, so it drops into any `uv run`
single-file script without adding to its dependency list. Resolution is lazy:
`load()` only touches the disk the first time a value misses the environment,
and `resolve(required=True)` raises a precise, actionable error naming the var
and how to set it — so a script that needs only one key never trips over a
second one it does not use.
"""

from __future__ import annotations

import os
import sys
from pathlib import Path

# Cache of values parsed from .env files, in increasing priority. Populated
# lazily on first miss so importing this module is free.
_dotenv_cache: dict[str, str] | None = None
_dotenv_extra_dirs: list[Path] = []


def register_env_dirs(*dirs: str | os.PathLike[str]) -> None:
    """Add directories (e.g. the script's own dir) to the .env search chain.

    Call this before the first `resolve()` so the directory is considered when
    the cache is built. Directories register at lower priority than $PWD and
    $CLAUDE_PLUGIN_ROOT, in the order given.
    """
    global _dotenv_cache
    for d in dirs:
        p = Path(d).expanduser()
        if p not in _dotenv_extra_dirs:
            _dotenv_extra_dirs.append(p)
    # A new search path invalidates any cache built earlier.
    _dotenv_cache = None


def _parse_dotenv(path: Path) -> dict[str, str]:
    out: dict[str, str] = {}
    try:
        text = path.read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError):
        return out
    for raw in text.splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, value = line.partition("=")
        key = key.strip()
        # Strip an optional `export ` prefix and surrounding quotes.
        if key.startswith("export "):
            key = key[len("export ") :].strip()
        value = value.strip().strip('"').strip("'")
        if key:
            out[key] = value
    return out


def _search_dirs() -> list[Path]:
    """The progressive .env search chain, highest priority last."""
    dirs: list[Path] = []
    # Lowest priority first; later entries overwrite earlier ones in the cache.
    for d in reversed(_dotenv_extra_dirs):
        dirs.append(d)
    plugin_root = os.environ.get("CLAUDE_PLUGIN_ROOT")
    if plugin_root:
        dirs.append(Path(plugin_root))
    dirs.append(Path.cwd())
    return dirs


def _load_dotenv() -> dict[str, str]:
    global _dotenv_cache
    if _dotenv_cache is not None:
        return _dotenv_cache
    merged: dict[str, str] = {}
    seen: set[Path] = set()
    for d in _search_dirs():
        env_file = d / ".env"
        try:
            resolved = env_file.resolve()
        except OSError:
            resolved = env_file
        if resolved in seen or not env_file.is_file():
            continue
        seen.add(resolved)
        merged.update(_parse_dotenv(env_file))  # later dirs win
    _dotenv_cache = merged
    return merged


class MissingConfig(RuntimeError):
    """Raised when a required value is absent from every source."""


def resolve(
    name: str,
    *,
    cli: str | None = None,
    default: str | None = None,
    required: bool = False,
    hint: str | None = None,
) -> str | None:
    """Resolve one config value through the progressive chain.

    Order: explicit `cli` -> os.environ[name] -> .env chain -> `default`.
    Empty strings count as "not set" so an exported-but-blank var falls through.
    With `required=True`, a total miss raises `MissingConfig` carrying `hint`
    (or a generated one) telling the user exactly how to provide it.
    """
    if cli is not None and cli != "":
        return cli

    env_val = os.environ.get(name)
    if env_val:
        return env_val

    file_val = _load_dotenv().get(name)
    if file_val:
        return file_val

    if default is not None:
        return default

    if required:
        msg = hint or (
            f"{name} is not set. Provide it via the command flag, "
            f"`export {name}=...` in your shell, or a `.env` file "
            f"(checked in this order: $PWD/.env, $CLAUDE_PLUGIN_ROOT/.env)."
        )
        raise MissingConfig(msg)

    return None


def resolve_secret(name: str, *, cli: str | None = None, hint: str | None = None) -> str:
    """Resolve a required secret (API key). Always returns a non-empty string
    or raises `MissingConfig` with an actionable hint."""
    value = resolve(name, cli=cli, required=True, hint=hint)
    assert value  # required=True guarantees this
    return value


def fail(message: str, code: int = 1) -> "None":
    """Print an error to stderr and exit. Keeps script call sites terse."""
    print(f"Error: {message}", file=sys.stderr)
    raise SystemExit(code)
