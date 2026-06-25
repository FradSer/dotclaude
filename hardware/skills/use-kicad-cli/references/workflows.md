# End-to-end workflows

Resolve the binary once (see `references/setup.md`):
```bash
KCLI=$(command -v kicad-cli || echo /Applications/KiCad/KiCad.app/Contents/MacOS/kicad-cli)
```

Protect KiCad field variables like `${QUANTITY}` with **single quotes** so the shell does not expand them.

## A. Full fabrication package (gerbers + drill + pick-and-place + BOM)

```bash
mkdir -p fab/gerbers
"$KCLI" pcb export gerbers -o fab/gerbers/ \
  -l "F.Cu,B.Cu,F.Paste,B.Paste,F.SilkS,B.SilkS,F.Mask,B.Mask,Edge.Cuts" \
  board.kicad_pcb
"$KCLI" pcb export drill -o fab/gerbers/ --excellon-separate-th \
  --generate-map --map-format pdf board.kicad_pcb
"$KCLI" pcb export pos -o fab/board-pos.csv --side both --format csv --units mm \
  --exclude-dnp board.kicad_pcb
"$KCLI" sch export bom -o fab/bom.csv \
  --fields 'Reference,Value,Footprint,${QUANTITY}' --group-by Value \
  --exclude-dnp board.kicad_sch
```

## B. ERC + DRC in CI, fail on violations

See `references/checks.md` for the full gating pattern. Core idea: pass `--exit-code-violations`, treat exit `5` as violations.

```bash
set +e
"$KCLI" sch erc --severity-error --exit-code-violations -o erc.rpt board.kicad_sch; erc=$?
"$KCLI" pcb drc --severity-error --schematic-parity --exit-code-violations -o drc.rpt board.kicad_pcb; drc=$?
set -e
{ [ "$erc" -eq 5 ] || [ "$drc" -eq 5 ]; } && { echo "violations:"; cat erc.rpt drc.rpt; exit 1; }
```

Run inside the official image in GitHub Actions:
`docker run --rm -v "$PWD":/project -w /project kicad/kicad:9.0 ./run-checks.sh`

## C. Schematic to PDF (with revision stamped in)

```bash
"$KCLI" sch export pdf -o schematic.pdf -D REV=B board.kicad_sch
```

## D. STEP 3D model (substitute STEP component models, skip DNP)

```bash
"$KCLI" pcb export step --subst-models --no-dnp --force -o board.step board.kicad_pcb
```

## E. Reproducible multi-output build via a job set

```bash
"$KCLI" jobset run --stop-on-error --file fabrication.kicad_jobset board.kicad_pro
```
Author the `.kicad_jobset` once in the KiCad GUI; this regenerates every configured output in one call.
