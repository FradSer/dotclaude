# Hardware Plugin

Hardware and EDA toolkit for Claude Code. The first skill drives the KiCad command-line interface for schematic/PCB export, fabrication outputs, and design checks.

**Version**: 0.1.0

## Installation

```bash
claude plugin install hardware@frad-dotclaude
```

## Overview

The Hardware Plugin gives Claude the domain knowledge to drive electronic design automation (EDA) tooling from the command line. It is built to grow — `use-kicad-cli` is the first skill, covering the full `kicad-cli` (KiCad 9.0) surface with the deepest detail on the fabrication and CI workflows engineers run most.

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

## Reference Materials

| File | Description |
|------|-------------|
| `references/setup.md` | Locating the binary cross-platform, headless/CI setup, `version`, global options, gotchas |
| `references/pcb-export.md` | Every `pcb export` subcommand plus `pcb render` |
| `references/sch-export.md` | `sch export` pdf/svg/dxf/ps/hpgl, netlist, bom, python-bom |
| `references/checks.md` | `pcb drc` / `sch erc`: flags, severity, exit codes, JSON caveat, CI gating |
| `references/sym-fp-jobset.md` | `sym` and `fp` export/upgrade, and `jobset run` |
| `references/workflows.md` | End-to-end recipes (fab package, CI checks, schematic PDF, STEP model, job set) |

## Usage Examples

```bash
# Generate the full fabrication package for a board
/hardware:use-kicad-cli Generate gerbers, drill, pick-and-place, and BOM for board.kicad_pcb

# Wire ERC + DRC into CI and fail on violations
/hardware:use-kicad-cli Add a CI step that runs ERC and DRC and fails on violations

# Export a 3D model
/hardware:use-kicad-cli Export a STEP model of this board, skipping DNP parts
```

## Requirements

- KiCad 9.0 (`kicad-cli`)

## References

- [KiCad CLI Documentation (9.0)](https://docs.kicad.org/9.0/en/cli/cli.html)

## Author

Frad LEE (fradser@gmail.com)

## License

MIT
