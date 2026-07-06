# `sch` — schematic exports

Input is a `.kicad_sch` file. `sch erc` is documented in `references/checks.md`.

## `sch export pdf` — all sheets in one PDF (`--output` is a file)

- `--pages`/`-p` — comma-separated page list; blank = all pages
- `--black-and-white`/`-b`, `--no-background-color`/`-n`, `--exclude-drawing-sheet`/`-e`
- `--theme`, `--drawing-sheet`, `--default-font`, `--define-var`
- `--exclude-pdf-property-popups`, `--exclude-pdf-hierarchical-links`, `--exclude-pdf-metadata`

```bash
kicad-cli sch export pdf -o schematic.pdf -D REV=B board.kicad_sch
```

## `sch export svg` / `dxf` / `ps` — one file per sheet (`--output` is a directory)

Shared flags: `--theme`, `--black-and-white`/`-b`, `--exclude-drawing-sheet`/`-e`, `--default-font`, `--pages`/`-p`, `--drawing-sheet`, `--define-var`. `svg` and `ps` add `--no-background-color`/`-n`.

```bash
kicad-cli sch export svg -o svg_out/ board.kicad_sch
```

## `sch export hpgl` — pen-plotter HPGL (one file per sheet)

Adds `--pen-size`/`-p` and `--origin`/`-r` (`0`|`1`|`2`|`3`).

## `sch export netlist`

`--format`/`-f`: `kicadsexpr` (default), `kicadxml`, `cadstar`, `orcadpcb2`, `spice`, `spicemodel`, `pads`, `allegro`. `--output` is a file.

```bash
kicad-cli sch export netlist --format spice -o board.cir board.kicad_sch
```

## `sch export bom`

`--output` is a file (typically `.csv`).

- `--fields` — ordered field list. Default `Reference,Value,Footprint,${QUANTITY},${DNP}`. Supports field variables like `${QUANTITY}`, `${DNP}`.
- `--labels` — column headers. Default `Refs,Value,Footprint,Qty,DNP`.
- `--group-by` — group references whose listed field values match
- `--sort-field` (default `Reference`), `--sort-asc`
- `--filter`, `--exclude-dnp`, `--include-excluded-from-bom`
- Delimiters: `--field-delimiter` (default `,`), `--string-delimiter`, `--ref-delimiter`, `--ref-range-delimiter`, `--keep-tabs`, `--keep-line-breaks`
- `--preset` / `--format-preset` — use a named BOM/format preset stored in the schematic

Single-quote the field list so the shell does not expand `${QUANTITY}`/`${DNP}` — KiCad must receive them literally:

```bash
kicad-cli sch export bom -o bom.csv \
  --fields 'Reference,Value,Footprint,${QUANTITY}' \
  --labels 'Refs,Value,Footprint,Qty' \
  --group-by Value --exclude-dnp board.kicad_sch
```

## `sch export python-bom` — legacy XML intermediate netlist

`kicad-cli sch export python-bom [-o OUTPUT_FILE] INPUT.kicad_sch` — produces the XML intermediate netlist consumed by legacy Python BOM scripts. Prefer `sch export bom` for new work.
