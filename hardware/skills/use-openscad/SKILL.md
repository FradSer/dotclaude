---
name: use-openscad
description: Writes OpenSCAD code and drives the `openscad` command-line compiler to produce STL/3MF/AMF/DXF/SVG/PNG outputs from parametric `.scad` models. This skill should be used when the user asks to design a 3D-printable part, generate a laser-cut 2D plate, render a preview image of a CAD model, export STL for 3D printing, batch-render parametric variants, or convert between mesh formats. Invoked via "/hardware:use-openscad".
user-invocable: true
license: MIT
metadata:
  version: "1.0"
---

# Use OpenSCAD

Design parametric 3D and 2D parts in OpenSCAD and compile them to fabrication outputs with the `openscad` CLI. OpenSCAD is a functional code-based CAD language — modules and functions, CSG booleans, extrusion — ideal for an agent to write and iterate.

## Process

1. Understand what the user wants (a printable part, a laser-cut plate, a preview image, a mesh conversion) and pick the target format (STL/3MF/AMF for 3D printing, DXF/SVG for 2D cutting, PNG for preview).
2. Locate and verify the binary (see "Locating the binary"). Run `openscad --version` first to confirm it works.
3. Author the `.scad` model using `references/language.md` for syntax. Make dimensions `-D` variables when the user wants parametric control from the command line.
4. Compile with the right flags from `references/cli.md`. Use `references/workflows.md` for end-to-end recipes and `references/design.md` for printability rules.
5. After STL/3MF export, scan stderr for manifold warnings (see CRITICAL rules) before declaring success.

## CRITICAL operating rules

- **Mesh exports (STL/3MF/AMF/DXF/SVG) always get full CGAL geometry — `--render` is NOT needed for them.** `--render` only affects PNG image export (without it, PNG uses OpenCSG preview). A plain `openscad -o out.stl model.scad` produces a complete mesh. For STL, explicitly pass `--export-format binstl` (ASCII is the current default; binary is the planned future default). After export, scan stderr for manifold warnings — see below.
- **macOS binary is not on PATH.** It lives at `/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD`. On Linux try `openscad` or `openscad-nightly`; on Windows invoke `openscad.com` (the wrapper, not `openscad.exe`). MUST confirm with `openscad --version` before building a pipeline.
- **Exit codes are not officially documented.** Empirically non-zero on compile/parse error, zero on success even with warnings; `--hardwarnings` makes the first warning fatal. Do NOT assume — for CI gating, run with `--hardwarnings` and treat any non-zero exit as failure. When unsure of a flag, run `openscad --help` and read the actual list.
- **Variables are immutable within a scope.** Reassigning in the same scope replaces-at-origin (the first assignment is never executed, a warning is emitted); braces create inner scopes that do not leak outward. Use `is_undef(x)`, not `x == undef`. `-D var=val` constants from the CLI override top-level program values.
- **`use` libraries, do not `include` them.** `include <lib.scad>` is literal copy-paste that runs top-level geometry and confuses error line numbers; `use <lib.scad>` suppresses top-level geometry and exposes only functions/modules. Use `use` for any library file.
- **String `-D` values need shell quoting.** `-D 'mode="parts"'` (bash) — the inner quotes are part of the OpenSCAD expression. Numeric `-D w=60` needs no quotes.
- **Scan stderr after mesh export.** Capture `2>&1` and grep for `manifold`, `self-intersect`, `degenerate`, `warning` — OpenSCAD prints mesh problems to stderr even when the exit code is zero. See `references/workflows.md`.

## Command map

| User wants | Flags | Reference |
|---|---|---|
| STL for 3D printing | `--export-format binstl -o out.stl` | `references/cli.md` |
| 3MF / AMF | `-o out.3mf` | `references/cli.md` |
| 2D DXF / SVG (laser cut) | `-o out.dxf` | `references/cli.md` |
| Preview PNG | `--preview --imgsize W,H --viewall --autocenter` (`--render` for accurate non-preview) | `references/cli.md` |
| Parametric variants | `-D var=val` (repeatable) | `references/cli.md` |
| Batch render | shell loop over `-D` values | `references/workflows.md` |
| Mesh conversion (STL→3MF) | `import()` in a re-export `.scad` | `references/workflows.md` |
| Language syntax | modules, functions, CSG, extrusion | `references/language.md` |
| Printability rules | walls, overhangs, clearance | `references/design.md` |

## Locating the binary

```bash
OPENSCAD="/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD"
if [[ ! -x "$OPENSCAD" ]]; then
  command -v openscad >/dev/null && OPENSCAD="openscad" || OPENSCAD="openscad-nightly"
fi
"$OPENSCAD" --version
```

If none works, tell the user OpenSCAD is not installed or ask for the install path.

## References

- `references/language.md` — OpenSCAD syntax: modules/functions, variables and scope, control flow, CSG booleans, primitives, transforms, extrusion and projection, import/include/use.
- `references/cli.md` — full `openscad` CLI: output and format flags, `-D` variables, rendering modes, image/camera options, diagnostics, `--enable` features, headless notes.
- `references/design.md` — printability heuristics (min wall, overhangs, bridges, clearance, manifold) and 2D-for-laser rules.
- `references/workflows.md` — end-to-end recipes (parametric STL, 2D DXF, preview PNG, batch variants, mesh conversion, stderr validation).
