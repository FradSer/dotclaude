# Hardware Plugin

Hardware and EDA toolkit for Claude Code. Drives the KiCad CLI for schematic/PCB export and design checks, and OpenSCAD for parametric 3D/2D part design and fabrication outputs.

**Version**: 0.2.0

## Installation

```bash
claude plugin install hardware@frad-dotclaude
```

## Overview

The Hardware Plugin gives Claude the domain knowledge to drive EDA and mechanical-design tooling from the command line. It covers two domains: KiCad for PCB/schematic outputs and checks, and OpenSCAD for parametric 3D/2D part design.

## Skills

### `/hardware:use-kicad-cli`

Drives `kicad-cli` (KiCad 9.0) to export schematics and PCBs, produce fabrication outputs, and run design checks. Registered as a slash command and auto-loaded when Claude detects KiCad CLI work.

**When triggered:**
- Export gerbers, drill, or pick-and-place files
- Generate a BOM or netlist
- Run ERC or DRC, including gating a CI build on violations
- Export a STEP/3D model, PDF, or SVG
- Upgrade KiCad symbol/footprint libraries
- Run a KiCad job set

**Key rules it enforces:**
- The macOS binary is not on PATH (`/Applications/KiCad/KiCad.app/Contents/MacOS/kicad-cli`)
- Checks need `--exit-code-violations` or they silently pass (exit `5` = violations found)
- `--output` is a directory for some commands, a file for others
- Use `pcb export gerbers` (plural); the singular `gerber` is deprecated

### `/hardware:use-openscad`

Writes OpenSCAD code and drives the `openscad` CLI to produce STL/3MF/AMF, DXF/SVG, and PNG outputs from parametric `.scad` models. Slash command and auto-loaded when Claude detects OpenSCAD or 3D-modeling work.

**When triggered:**
- Design a 3D-printable part or a laser-cut 2D plate
- Export STL/3MF for 3D printing
- Render a preview PNG of a CAD model
- Batch-render parametric variants via `-D` variables
- Convert between mesh formats (e.g. STL to 3MF)

**Key rules it enforces:**
- STL/3MF/AMF export MUST use `--render` (else preview-grade non-manifold output)
- The macOS binary is at `/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD` (not on PATH)
- `-D 'var=val'` overrides top-level variables; string values need shell quoting
- `use` libraries, never `include` them (avoid top-level geometry leaking)
- Scan stderr after mesh export — OpenSCAD prints manifold warnings even on exit 0

## Reference Materials

### use-kicad-cli

| File | Description |
|------|-------------|
| `references/setup.md` | Locating the binary cross-platform, headless/CI setup, `version`, global options, gotchas |
| `references/pcb-export.md` | Every `pcb export` subcommand plus `pcb render` |
| `references/sch-export.md` | `sch export` pdf/svg/dxf/ps/hpgl, netlist, bom, python-bom |
| `references/checks.md` | `pcb drc` / `sch erc`: flags, severity, exit codes, JSON caveat, CI gating |
| `references/sym-fp-jobset.md` | `sym` and `fp` export/upgrade, and `jobset run` |
| `references/workflows.md` | End-to-end recipes (fab package, CI checks, schematic PDF, STEP model, job set) |

### use-openscad

| File | Description |
|------|-------------|
| `references/language.md` | OpenSCAD syntax: modules/functions, variables and scope, control flow, CSG, primitives, transforms, extrusion, import/include/use |
| `references/cli.md` | Full `openscad` CLI: output and format flags, `-D` variables, rendering modes, image/camera options, diagnostics, `--enable` features, headless notes |
| `references/design.md` | Printability heuristics (walls, overhangs, clearance, manifold) and 2D laser-cut rules |
| `references/workflows.md` | End-to-end recipes (parametric STL, 2D DXF, preview PNG, batch variants, mesh conversion, stderr validation) |

## Usage Examples

```bash
# Generate the full fabrication package for a board
/hardware:use-kicad-cli Generate gerbers, drill, pick-and-place, and BOM for board.kicad_pcb

# Wire ERC + DRC into CI and fail on violations
/hardware:use-kicad-cli Add a CI step that runs ERC and DRC and fails on violations

# Export a 3D model
/hardware:use-kicad-cli Export a STEP model of this board, skipping DNP parts

# Design a 3D-printable part and export STL
/hardware:use-openscad Design a parametric bracket and export STL at 60x40x25

# Render a preview PNG of a CAD model
/hardware:use-openscad Render a preview PNG of bracket.scad

# Batch-render parametric variants
/hardware:use-openscad Export STL for hole_r = 2,3,4,5
```

## Requirements

- KiCad 9.0 (`kicad-cli`) — for `use-kicad-cli`
- OpenSCAD 2021.01 or later (`openscad`) — for `use-openscad`

## References

- [KiCad CLI Documentation (9.0)](https://docs.kicad.org/9.0/en/cli/cli.html)
- [OpenSCAD Documentation](https://openscad.org/documentation.html)
- [OpenSCAD User Manual (Wikibooks)](https://en.wikibooks.org/wiki/OpenSCAD_User_Manual)
- [openscad-agent](https://github.com/iancanderson/openscad-agent) — reference skill bundle whose binary-resolution and validation patterns this skill mirrors

## Author

Frad LEE (fradser@gmail.com)

## License

MIT
