# `sym`, `fp`, and `jobset`

## `sym` — symbols (input: a `.kicad_sym` library)

### `sym export svg`
`kicad-cli sym export svg [-o OUTPUT_DIR] [options] INPUT.kicad_sym` — `--output` is a directory.
- `--symbol NAME` — export one symbol (else all in the library)
- `--theme`, `--black-and-white`, `--include-hidden-pins`, `--include-hidden-fields`

```bash
kicad-cli sym export svg -o sym_svg/ --include-hidden-pins mylib.kicad_sym
```

### `sym upgrade`
`kicad-cli sym upgrade [-o OUTPUT_FILE] [--force] INPUT` — convert a library to the current KiCad format. Accepts KiCad `.kicad_sym`, pre-6.0 `.lib`, Altium `.SchLib`/`.IntLib`, CADSTAR `.lib`, EAGLE `.lbr`, EasyEDA. `--force` re-saves even if already current.

## `fp` — footprints (input: a `.pretty` directory)

### `fp export svg`
`kicad-cli fp export svg [-o OUTPUT_DIR] [options] INPUT.pretty` — `--output` is a directory.
- `--footprint NAME` — export one footprint (else all)
- `--layers`, `--theme`, `--black-and-white`, DNP/fab flags

```bash
kicad-cli fp export svg -o fp_svg/ --footprint R_0805 mylib.pretty
```

### `fp upgrade`
`kicad-cli fp upgrade [-o OUTPUT_DIR] [--force] INPUT` — convert a footprint library to the current format. Accepts KiCad `.pretty`, pre-5.0 `.mod`/`.emp`, Altium `.PcbLib`/`.IntLib`, CADSTAR `.cpa`, EAGLE `.lbr`, EasyEDA, GEDA/PCB `.fp`.

## `jobset run` — reproducible batch outputs (KiCad 9)

A job set (`.kicad_jobset`) bundles many export/check steps, authored in the KiCad GUI. `jobset run` regenerates every configured output in one call — the recommended way to run reproducible multi-output pipelines in 9.0.

`kicad-cli jobset run [--stop-on-error] [-f JOB_FILE] [-o OUTPUT] INPUT_FILE`
- `--file`/`-f` — the `.kicad_jobset` file
- `--output`/`-o` — destination ID/description defined in the job set
- `--stop-on-error` — halt on the first failing job
- `INPUT_FILE` is the project (`.kicad_pro`)

```bash
kicad-cli jobset run --stop-on-error --file fabrication.kicad_jobset board.kicad_pro
```
