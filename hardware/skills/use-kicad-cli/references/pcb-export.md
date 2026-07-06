# `pcb` — board exports and render

Input is a `.kicad_pcb` file. `pcb drc` is documented separately in `references/checks.md`.

## `pcb export gerbers` — fabrication gerbers (one layer per file)

`kicad-cli pcb export gerbers [-o OUTPUT_DIR] [-l LAYER_LIST] [options] INPUT.kicad_pcb`

`--output` is a **directory**. Preferred over the deprecated singular `gerber`.

Key flags:
- `--layers` / `-l` — comma-separated layers, e.g. `F.Cu,B.Cu,F.SilkS,B.SilkS,F.Mask,B.Mask,Edge.Cuts`
- `--common-layers` — layers added to every output file
- `--precision 5|6` — Gerber coordinate precision
- `--no-x2` (X1 attributes instead of X2), `--no-netlist` (omit netlist attributes), `--no-protel-ext` (don't use Protel filename extensions)
- `--subtract-soldermask`, `--use-drill-file-origin`, `--disable-aperture-macros`
- `--board-plot-params` — use plot params stored in the board file (overrides `--layers`)
- DNP/fab: `--exclude-refdes`, `--exclude-value`, `--include-border-title`, `--sketch-pads-on-fab-layers`, `--hide-DNP-footprints-on-fab-layers`, `--sketch-DNP-footprints-on-fab-layers`, `--crossout-DNP-footprints-on-fab-layers`, `--plot-invisible-text`

```bash
kicad-cli pcb export gerbers -o gerbers/ \
  -l "F.Cu,B.Cu,F.Paste,B.Paste,F.SilkS,B.SilkS,F.Mask,B.Mask,Edge.Cuts" \
  board.kicad_pcb
```

> `pcb export gerber` (singular, single multi-layer file) is **deprecated in 9.0, removed in 10.0**. Use `gerbers`.

## `pcb export drill`

`kicad-cli pcb export drill [-o OUTPUT_DIR] [options] INPUT.kicad_pcb` — `--output` is a directory.

- `--format excellon|gerber` (default `excellon`)
- `--drill-origin absolute|plot`
- `--excellon-units mm|in` (`-u`)
- `--excellon-zeros-format decimal|suppressleading|suppresstrailing|keep`
- `--excellon-oval-format route|alternate`
- `--excellon-mirror-y`, `--excellon-min-header`, `--excellon-separate-th` (separate plated/non-plated holes)
- `--generate-map` + `--map-format pdf|gerberx2|ps|dxf|svg` — also produce a drill map
- `--gerber-precision`

```bash
kicad-cli pcb export drill -o gerbers/ --excellon-separate-th \
  --generate-map --map-format pdf board.kicad_pcb
```

## `pcb export pos` — pick-and-place / position file

`kicad-cli pcb export pos [-o OUTPUT_FILE] [options] INPUT.kicad_pcb` — `--output` is a file.

- `--side front|back|both`
- `--format ascii|csv|gerber`
- `--units in|mm`
- `--smd-only`, `--exclude-fp-th` (exclude through-hole), `--exclude-dnp`
- `--bottom-negate-x`, `--use-drill-file-origin`, `--gerber-board-edge`

```bash
kicad-cli pcb export pos -o board-pos.csv --side both --format csv --units mm --exclude-dnp board.kicad_pcb
```

## `pcb export pdf`

`--output` is a file. Choose a mode:
- `--mode-single` — all selected layers on one page
- `--mode-separate` — one PDF per layer
- `--mode-multipage` — one PDF, one page per layer

Other flags: `--layers`/`-l`, `--mirror`/`-m`, `--negative`/`-n`, `--black-and-white`, `--theme`/`-t`, `--include-border-title`, `--subtract-soldermask`, `--drill-shape-opt`, `--common-layers`, DNP/fab flags, `--plot-invisible-text`.

```bash
kicad-cli pcb export pdf -l "F.Cu,B.Cu,Edge.Cuts" --mode-multipage -o board.pdf board.kicad_pcb
```

## `pcb export svg`

`--layers` is optional (default = all layers). `--mode-single` (single file, `--output` is full path) vs `--mode-multi` (one SVG per layer). Extras: `--page-size-mode 0|1|2`, `--fit-page-to-board`, `--mirror`, `--negative`, `--black-and-white`, `--theme`, `--exclude-drawing-sheet`, `--drill-shape-opt`, `--common-layers`.

## `pcb export dxf`

`--layers` required. `--output-units mm|in` (`--ou`), `--use-contours` (`--uc`), `--use-drill-origin` (`--udo`), `--mode-single`/`--mode-multi`, `--include-border-title`, plus DNP/fab flags.

## 3D model exports

### `pcb export step` — STEP (`--output` is a file)
- `--subst-models` — substitute STEP/IGS models of the same name for VRML models
- `--board-only` — board only, no components; `--no-components` — exclude components
- `--no-dnp` — exclude DNP models; `--no-unspecified` — exclude "unspecified" components
- `--include-tracks`, `--include-pads`, `--include-zones`, `--include-inner-copper`, `--include-silkscreen`, `--include-soldermask` (tracks/zones are "time consuming")
- `--user-origin VAR` (e.g. `25.4x25.4mm`, `1x1in`), `--grid-origin`, `--drill-origin`
- `--min-distance MIN_DIST` (point-merge tolerance, default `0.01mm`)
- `--cut-vias-in-body`, `--no-board-body`, `--fuse-shapes`, `--fill-all-vias`, `--component-filter VAR`, `--net-filter VAR`
- `--no-optimize-step` (parametric curves; smaller, less compatible), `--force`/`-f` (overwrite)

```bash
kicad-cli pcb export step --subst-models --no-dnp --force -o board.step board.kicad_pcb
```

### `pcb export glb` — binary glTF
Same option set as `step` minus `--no-optimize-step`.

### `pcb export vrml`
- `--units mm|m|in|tenths`
- `--models-dir DIR`, `--models-relative` — where component models are written/referenced
- `--no-dnp`, `--no-unspecified`, `--user-origin`, `--force`

### Other mesh/CAD formats
`pcb export brep`, `stl`, `ply`, `gencad`, `xao` exist and share most of the `step`/`glb` 3D options. `gencad` adds `--flip-bottom-pads`/`-f`, `--unique-pins`, `--unique-footprints`, `--use-drill-origin`, `--store-origin-coord`. Confirm obscure flags with `-h` on the target install.

## Assembly / data exchange

### `pcb export ipc2581`
- `--version B|C`, `--units mm|in`, `--precision`, `--compress`
- `--bom-col-int-id`, `--bom-col-mfg-pn`, `--bom-col-mfg`, `--bom-col-dist-pn`, `--bom-col-dist` — map schematic field names to IPC-2581 BOM columns

### `pcb export ipcd356`
`kicad-cli pcb export ipcd356 [-o OUTPUT_FILE] INPUT.kicad_pcb` — IPC-D-356 netlist (minimal options).

### `pcb export odb` — ODB++
- `--compression none|zip|tgz`, `--units mm|in`, `--precision`

## `pcb render` — raytraced PNG/JPEG

Output format from the `--output` extension (`.png`/`.jpg`).

Defaults: `--width 1600`, `--height 900`, `--side top` (also `bottom`/`left`/`right`/`front`/`back`), `--background default` (transparent for PNG, opaque for JPG; force `transparent`/`opaque`), `--quality basic` (`high`/`user`), `--preset follow_plot_settings`, `--zoom 1`.

Camera: `--rotate X,Y,Z`, `--pan X,Y,Z`, `--pivot X,Y,Z`, `--perspective`, `--floor`. Lights: `--light-top/-bottom/-side/-camera COLOR`, `--light-side-elevation ANGLE`.

```bash
kicad-cli pcb render --side top --quality high -w 3000 -o render.png board.kicad_pcb
```
