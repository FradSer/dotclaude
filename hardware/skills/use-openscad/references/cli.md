# `openscad` CLI reference

Sources: the in-repo man page (`doc/openscad.1.in`) and the Wikibooks CLI page (2021.01 + 2025.08.17). The man page lags the running binary — run `openscad --help` to confirm any flag.

## Output and format

| Flag | Arg | Description |
|---|---|---|
| `-o`, `--o` | `<file>` | Export to `<file>`; extension picks format. GUI not started. Use `-` for stdout, `null` to evaluate-only (echo to stderr). Repeatable. |
| `--export-format` | `<fmt>` | Override format. STL: `asciistl` (current default) or `binstl` (planned future default — set explicitly in scripts). Also any supported extension. |
| `-O`, `--O` | `section/key=value` | Exporter settings. `--help-export` lists all. e.g. `export-pdf/paper-size=a3`, `export-3mf/color-mode=model`, `export-3mf/unit=millimeter`. |
| `-s` / `-x` | — | **Deprecated** STL/DXF output — use `-o`. |

Extension → format: `stl, off, amf, 3mf, csg, dxf, svg, png, echo, ast, term, nef3, nefdbg` (man page); Wikibooks adds `obj, wrl, pdf, param, pov`. Debug: AST (re-serialized parse), CSG (evaluated language form), TERM (CSG to OpenCSG).

## Variables and customizer (parametric interface)

| Flag | Arg | Description |
|---|---|---|
| `-D`, `--D` | `var=val` | Define a constant. `val` is an arbitrary OpenSCAD expression. Repeatable. **Shell-quoting required for strings:** `-D 'mode="parts"'` (bash) / `-D "mode=""parts"""` (cmd). A `-D` var assigned to another program var must be initialized in the `.scad` first. **Overrides top-level program values at export.** |
| `-p`, `--p` | `<file>` | Customizer parameter file. |
| `-P`, `--P` | `<name>` | Customizer parameter set. |

## Rendering modes and image output

| Flag | Arg | Description |
|---|---|---|
| `--render` | (none / `arg` in 2025.08) | Force full CGAL geometry eval for **image export** (PNG). Mesh exports (STL/3MF/AMF/DXF/SVG) always perform full geometry evaluation regardless of this flag — `--render` is not needed for them. |
| `--preview` | `=throwntogether` | OpenCSG preview (F5). `throwntogether` = quick non-GL render. |
| `--imgsize` | `=W,H` | PNG pixel dimensions. |
| `--camera` | `=tx,ty,tz,rx,ry,rz,dist` | **Gimbal** camera (Euler + translation + distance) — 7 values. |
| `--camera` | `=ex,ey,ez,cx,cy,cz` | **Vector** camera (eye position + look-at center; no up vector) — 6 values. |
| `--projection` | `=o\|ortho\|p\|perspective` | Projection mode. |
| `--viewall` | — | Fit whole design in frame. |
| `--autocenter` | — | Center design in frame. |
| `--colorscheme` | `<name>` | Cornfield (default), Sunset, Metallic, Starnight, BeforeDawn, Nature, DeepOcean, Solarized, Tomorrow, Tomorrow Night, Monotone. (2025.08 adds Daylight Gem, Nocturnal Gem, ClearSky.) |
| `--view` | `=axes\|crosshairs\|edges\|scales\|wireframe` | View overlays (wireframe in 2021.01 only). |
| `--animate` | `=N` | Export N animated frames as PNG. |
| `--animate_sharding` | `=shard/num_shards` | (2025.08) Parallelize animation across cores/machines. |
| `--csglimit` | `=n` | Cap CSG elements in OpenCSG preview. |
| `--backend` | `CGAL\|Manifold` | (2025.08) 3D backend; Manifold is new/fast. |

## Diagnostics and info

| Flag | Arg | Description |
|---|---|---|
| `--hardwarnings` | — | Stop on first warning (non-zero exit). |
| `--check-parameters` | `=true\|false` | Parameter checking for user modules/functions. |
| `--check-parameter-ranges` | `=true\|false` | Range check for builtin modules. |
| `--summary` | `all\|cache\|time\|camera\|geometry\|bounding-box\|area` | Render statistics. |
| `--summary-file` | `<file>\|-` | Summary as JSON to file (or stdout with `-`). |
| `--trace-depth` | `=n` | (2025.08) Max trace messages. |
| `--trace-usermodule-parameters` | `=true\|false` | (2025.08) |
| `--debug` | `all\|<files>` | Debug info for source files. |
| `-q`, `--quiet` | — | Only print errors. |
| `-h`, `--help` | — | Basic usage. |
| `--help-export` | — | List `-O` settings. |
| `-v`, `--version` | — | Version. |
| `--info` | — | Build/library/OpenGL info. |

## Experimental features (`--enable`, `-j`)

`--enable <feature>` or `--enable all`. Features (2025.08): `roof, input-driver-dbus, lazy-union, vertex-object-renderers-indexing, textmetrics, import-function, predictible-output`. (2021.01 subset adds `vertex-object-renderers*` variants.)

- **`lazy-union`** changes `for()` and module semantics — only enable deliberately.
- **Manifold** backend is via `--backend Manifold`, not `--enable`.

## Make integration

`-d <deps>` writes Makefile-syntax dependencies; `-m <cmd>` invokes `make_cmd missing_file` for missing files. Only useful together.

## Headless rendering

- **Modern OpenSCAD (2024+):** renders PNG headlessly on Linux **without Xvfb** via EGL (issues #1798, #3857, #4613 all closed).
- **Older OpenSCAD (pre-2022-ish):** needed an X server; wrap with `xvfb-run -a openscad ...`.
- **macOS:** binary at `/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD`; some versions hit a Qt "cocoa" plugin error fixed by a wrapper script. Homebrew snapshot: `brew install openscad@snapshot`.
- **Windows:** invoke `openscad.com` (the wrapper), not `openscad.exe`, to avoid the CLI/GUI output issue.

## Exit codes (unverified)

Exit-code behavior is **not documented** in the man page, the Wikibooks CLI page, or the FAQ. Empirically: non-zero on compile/parse error; zero on success even with warnings; `--hardwarnings` makes the first warning fatal (non-zero). For CI gating, run with `--hardwarnings` and treat any non-zero exit as failure; do not assume success from a zero exit alone.
