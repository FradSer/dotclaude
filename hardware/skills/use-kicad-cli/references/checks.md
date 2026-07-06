# `pcb drc` and `sch erc` — design checks (and CI gating)

Both checks **exit 0 by default even when violations exist** — they only write a report. To gate on violations you MUST pass `--exit-code-violations`.

## Exit codes (verified, identical in 8.0 and 9.0)

With `--exit-code-violations`:
- `0` — no violations
- `5` — violations found

Other non-zero codes indicate tool/IO errors, not violations. So in CI: `5` = violations, any other non-zero = a real failure to investigate.

## `sch erc` — electrical rule check

`kicad-cli sch erc [-o OUTPUT_FILE] [options] INPUT.kicad_sch`

- `--format report|json` (default `report`)
- `--units mm|in|mils` (default `mm`)
- `--severity-error`, `--severity-warning`, `--severity-exclusions` (each includes only that category; combinable), `--severity-all` (all three)
- `--exit-code-violations`
- `--define-var`
- Default output (no `-o`): input name with `.rpt` or `.json`

```bash
kicad-cli sch erc --severity-error --exit-code-violations -o erc.rpt board.kicad_sch
```

## `pcb drc` — design rule check

`kicad-cli pcb drc [-o OUTPUT_FILE] [options] INPUT.kicad_pcb`

- `--format report|json` (default `report`)
- `--units mm|in|mils` (default `mm`)
- `--all-track-errors` — report all track errors, not just the first per item
- `--schematic-parity` — also test schematic/board parity (the schematic must be present alongside the board)
- `--severity-*` flags and `--exit-code-violations` as for ERC
- Default output (no `-o`): input name with `.rpt` or `.json`

```bash
kicad-cli pcb drc --severity-all --schematic-parity --exit-code-violations -o drc.rpt board.kicad_pcb
```

## JSON output caveat

`--format json` is supported, but the JSON schema/field names are **not** documented officially. Do not hardcode field names — generate a sample (`--format json`) and inspect it before parsing. Empirically it contains arrays of violations with severity, description, and coordinates, but treat that as unverified.

## CI gating pattern

Capture each exit code without aborting the script, then decide:

```bash
set +e
kicad-cli sch erc --severity-error --exit-code-violations -o erc.rpt board.kicad_sch; erc=$?
kicad-cli pcb drc --severity-error --schematic-parity --exit-code-violations -o drc.rpt board.kicad_pcb; drc=$?
set -e
if [ "$erc" -eq 5 ] || [ "$drc" -eq 5 ]; then
  echo "ERC/DRC violations found"; cat erc.rpt drc.rpt; exit 1
fi
[ "$erc" -ne 0 ] && exit "$erc"   # non-5 non-zero = tool error
[ "$drc" -ne 0 ] && exit "$drc"
```

In GitHub Actions, run inside the official image so KiCad is present:
`docker run --rm -v "$PWD":/project -w /project kicad/kicad:9.0 ./run-checks.sh`
