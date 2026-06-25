---
name: use-kicad-cli
description: Drives the KiCad command-line interface (`kicad-cli`, version 9.0) to export schematics and PCBs, produce fabrication outputs, and run design checks. This skill should be used when the user asks to export gerbers, drill, or pick-and-place files, generate a BOM or netlist, run ERC or DRC (including in CI), export a STEP/3D model or PDF/SVG, upgrade KiCad symbol/footprint libraries, or run a KiCad job set. Invoked via "/hardware:use-kicad-cli".
user-invocable: true
license: MIT
metadata:
  version: "1.0"
---

# Use kicad-cli

Generate fabrication, documentation, and 3D outputs from KiCad projects, and run electrical/design rule checks, by driving `kicad-cli` — KiCad 9.0's command-line tool. It has six command groups: `sch` (schematic), `pcb` (board), `sym` (symbols), `fp` (footprints), `jobset` (batch job sets), and `version`.

## Process

1. Identify which artifact the user wants (fabrication files, BOM, a check, a 3D model, a PDF, a library upgrade) and map it to a command group with the table below.
2. Locate and verify the binary before running anything (see "Locating the binary"). Run `kicad-cli version` first to confirm it works.
3. Load the matching reference file and use its exact flags. Do not invent flags — when unsure, run `kicad-cli <group> <command> -h`.
4. Build the command, create any output directory first, then run it. Report the produced files (and, for checks, the exit code plus report path).

## CRITICAL operating rules

- **macOS binary is not on PATH.** On macOS it lives at `/Applications/KiCad/KiCad.app/Contents/MacOS/kicad-cli`. On Linux `kicad-cli` is on PATH; on Windows it is `kicad-cli.exe` in the KiCad `bin` folder. MUST confirm with `kicad-cli version` before building a pipeline.
- **Checks silently pass without `--exit-code-violations`.** `pcb drc` and `sch erc` exit `0` by default even when violations exist — they only write a report. MUST pass `--exit-code-violations` to get exit `5` when violations are found. In CI, treat exit `5` as "violations found"; other non-zero codes are tool/IO errors. See `references/checks.md`.
- **`--output` is a directory for some commands, a file for others.** Directory: `pcb export gerbers`, `pcb export drill`, `*/export svg` (multi-file). File: `pcb export pdf`, `pcb export step`, `pcb export pos`, single-file exports. Create the directory first; never assume deep auto-creation.
- **Use `pcb export gerbers` (plural).** The singular `pcb export gerber` is deprecated in 9.0 and removed in 10.0.
- **Stamp variables with `--define-var KEY=VALUE`** (`-D`) to override project text variables (e.g. `${REV}`) at export time instead of editing the board. Protect KiCad field variables like `${QUANTITY}` with single quotes in the shell so they are not expanded.
- **Never hardcode the DRC/ERC JSON schema.** `--format json` is supported but its field names are not officially documented — generate a sample and inspect it before parsing.
- **CI without a display:** `kicad-cli` generally runs headless, but some operations expect an X display. The robust pattern is the official `kicad/kicad:9.0` Docker image, or `Xvfb :99 -ac -nolisten tcp &` then `export DISPLAY=:99`. See `references/setup.md`.

## Command map

| User wants | Command | Reference |
|---|---|---|
| Gerbers / drill / pick-and-place | `pcb export gerbers` / `drill` / `pos` | `references/pcb-export.md` |
| Board PDF / SVG / DXF | `pcb export pdf` / `svg` / `dxf` | `references/pcb-export.md` |
| 3D model (STEP/GLB/VRML/…) | `pcb export step` / `glb` / `vrml` | `references/pcb-export.md` |
| IPC-2581 / IPC-D-356 / ODB++ | `pcb export ipc2581` / `ipcd356` / `odb` | `references/pcb-export.md` |
| Board render (PNG/JPEG) | `pcb render` | `references/pcb-export.md` |
| Schematic PDF / SVG / DXF / PS / HPGL | `sch export <fmt>` | `references/sch-export.md` |
| BOM / netlist | `sch export bom` / `netlist` | `references/sch-export.md` |
| Design / electrical rule check | `pcb drc` / `sch erc` | `references/checks.md` |
| Symbol/footprint SVG or library upgrade | `sym ...` / `fp ...` | `references/sym-fp-jobset.md` |
| Reproducible batch of outputs | `jobset run` | `references/sym-fp-jobset.md` |
| End-to-end recipes | — | `references/workflows.md` |

## Locating the binary

Try, in order: `kicad-cli` on PATH; macOS `/Applications/KiCad/KiCad.app/Contents/MacOS/kicad-cli`; Windows `C:\Program Files\KiCad\9.0\bin\kicad-cli.exe`. Assign the resolved path to a shell variable and reuse it:

```bash
KCLI=$(command -v kicad-cli || echo /Applications/KiCad/KiCad.app/Contents/MacOS/kicad-cli)
"$KCLI" version
```

If none works, tell the user KiCad 9.0 is not installed or ask for the install path.

## References

- `references/setup.md` — locating the binary cross-platform, headless/CI setup, `version`, global options (`--define-var`, `--output` semantics), gotchas.
- `references/pcb-export.md` — every `pcb export` subcommand (gerbers, drill, pos, pdf, svg, dxf, step, glb, vrml, ipc2581, ipcd356, odb, others) plus `pcb render`.
- `references/sch-export.md` — `sch export` pdf/svg/dxf/ps/hpgl, netlist, bom, python-bom.
- `references/checks.md` — `pcb drc` and `sch erc`: flags, severity, exit codes, JSON caveat, CI gating.
- `references/sym-fp-jobset.md` — `sym` and `fp` export/upgrade, and `jobset run`.
- `references/workflows.md` — end-to-end recipes (fab package, CI checks, schematic PDF, STEP model, job set).
