# Setup, invocation, and cross-cutting options

## Locating the `kicad-cli` binary

| Platform | Path | On PATH? |
|---|---|---|
| macOS | `/Applications/KiCad/KiCad.app/Contents/MacOS/kicad-cli` | No — bundled in the app |
| Linux | `kicad-cli` (e.g. `/usr/bin/kicad-cli`) | Yes after a normal install; included in `kicad/kicad` Docker images |
| Windows | `C:\Program Files\KiCad\9.0\bin\kicad-cli.exe` | Usually not |

Only the macOS path is quoted verbatim from the official 9.0 docs; the Linux/Windows paths are standard install conventions.

Resolve the binary once and reuse it:

```bash
KCLI=$(command -v kicad-cli || echo /Applications/KiCad/KiCad.app/Contents/MacOS/kicad-cli)
"$KCLI" version          # confirm it runs; prints e.g. 9.0.x
```

## `version`

`kicad-cli version [--format VAR]`
- `--format plain` (default) — version number, e.g. `9.0.x`
- `--format commit` — git commit hash
- `--format about` — full version plus library/system info

## General invocation

`kicad-cli <group> <command> [<subcommand>] [options] INPUT_FILE`

Append `-h`/`--help` at any level to see the exact flags for the installed version:
`kicad-cli pcb -h`, `kicad-cli pcb export gerbers -h`. When a flag is uncertain, check `-h` rather than guessing.

## Cross-cutting options

- **`--define-var KEY=VALUE`** (`-D`) — override project text variables (e.g. `${REV}`, `${COMPANY}`, `${ISSUE_DATE}`) at export time. Repeatable. Useful for stamping a revision/date into plots without editing the board. In the shell, single-quote any `${...}` that KiCad must expand (e.g. BOM field variables) so the shell does not expand it first.
- **`--drawing-sheet PATH`** — use a specific drawing sheet (title block) for visual exports.
- **`--output` (`-o`) semantics differ by command:**
  - **Directory:** `pcb export gerbers`, `pcb export drill`, `sch export svg/dxf/ps/hpgl`, `fp export svg`, `sym export svg`, any "one file per layer/sheet" export.
  - **File:** `pcb export pdf`, `pcb export step/glb/vrml/...`, `pcb export pos`, `sch export pdf/netlist/bom`, single-file exports.
  - Create the output directory first (`mkdir -p`); do not assume deep auto-creation.

## Headless / CI without a display

The official 9.0 docs state no display requirement, and `kicad-cli` generally runs headless on servers (STEP export has been headless since KiCad 7). But some operations can still expect an X display, so the robust CI patterns are:

- Run inside the official image: `docker run --rm -v "$PWD":/project -w /project kicad/kicad:9.0 <command>`
- Or start a virtual framebuffer:
  ```bash
  Xvfb :99 -ac -nolisten tcp &
  export DISPLAY=:99
  ```

This `Xvfb`/`DISPLAY=:99` pattern is community/Docker best practice, not an official 9.0 guarantee — but it is the safe default for CI.
