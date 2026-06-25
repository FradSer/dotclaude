# End-to-end workflows

Resolve the binary once (see `references/cli.md`):
```bash
OPENSCAD="/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD"
if [[ ! -x "$OPENSCAD" ]]; then
  command -v openscad >/dev/null && OPENSCAD="openscad" || OPENSCAD="openscad-nightly"
fi
"$OPENSCAD" --version
```

## A. Parametric box STL with CLI variables

`box.scad` defines the module and a default instantiation; `-D` overrides the top-level variables:
```openscad
// box.scad
w = 40; d = 30; h = 20; t = 2; hole_r = 1.6;   // initialized — -D overrides bind
module box(w,d,h,t,hole_r,$fn=40) {
  difference() {
    cube([w, d, h], center=true);
    translate([0,0,t]) cube([w-2*t, d-2*t, h], center=true);
    for (x=[-1,1], y=[-1,1])
      translate([x*(w/2-5), y*(d/2-5), 0])
        cylinder(h=h+1, r=hole_r, center=true);
  }
}
box(w=w, d=d, h=h, t=t, hole_r=hole_r);
```
```bash
"$OPENSCAD" --export-format binstl \
  -D 'w=60' -D 'd=40' -D 'h=25' -D 't=2' \
  -o box_60x40x25.stl box.scad
```
Each `-D` is a separate flag. String values need shell quoting (`-D 'mode="parts"'`); numeric values do not.

## B. 2D DXF of a laser-cut plate

```openscad
// plate.scad
$fn = 64;
difference() {
  offset(r=2) square([80, 50], center=true);   // rounded outer
  for (x=[-30,0,30]) translate([x,0]) circle(r=2.5);
}
```
```bash
"$OPENSCAD" -o plate.dxf plate.scad          # 2D → DXF
"$OPENSCAD" -o plate.png --imgsize=1024,768 --viewall --autocenter plate.scad   # preview (add --render for accurate non-preview)
```

## C. Preview PNG of a model

Gimbal camera (7-tuple): `translate x,y,z, rotate x,y,z, distance`:
```bash
"$OPENSCAD" -o preview.png --preview --imgsize=1280,960 \
  --camera=0,0,0,25,0,35,500 --projection=ortho \
  --colorscheme=Cornfield --viewall --autocenter model.scad
```
Vector camera (6-tuple): `eye x,y,z, center x,y,z`:
```bash
"$OPENSCAD" -o preview.png --imgsize=1280,960 \
  --camera=80,-80,60,0,0,0 model.scad
```
For an accurate (non-preview) PNG, replace `--preview` with `--render` (only PNG image export needs `--render`; mesh exports never do).

## D. Batch-render parametric variants

```bash
for v in 2 3 4 5; do
  "$OPENSCAD" --export-format binstl \
    -D "hole_r=${v}.0" \
    -o "bracket_hole${v}.stl" bracket.scad
done
```
Parallel + sharded animation (2025.08+):
```bash
"$OPENSCAD" --animate=60 --animate_sharding=0/4 -o frame_%04d.png gear.scad
```

## E. Convert STL → 3MF

Re-export by importing the STL in a small `.scad`:
```openscad
// reexport.scad
import("input.stl", convexity=3);
```
```bash
"$OPENSCAD" -o output.3mf \
  -O export-3mf/unit=millimeter -O export-3mf/color-mode=model \
  reexport.scad
```

## F. Validate mesh after export (stderr scan)

OpenSCAD prints mesh problems to stderr even when the exit code is zero. Capture and grep:
```bash
set +e
out=$("$OPENSCAD" --export-format binstl -o part.stl part.scad 2>&1)
rc=$?
set -e
if [ "$rc" -ne 0 ]; then echo "openscad failed (exit $rc)"; echo "$out"; exit "$rc"; fi
if echo "$out" | grep -qiE 'not.*manifold|non-manifold|self-intersect|degenerate|warning'; then
  echo "mesh validation WARNING:"; echo "$out" | grep -iE 'manifold|self-intersect|degenerate|warning'
  exit 1
fi
echo "part.stl: OK"
```
For CI gating, also pass `--hardwarnings` so any warning makes the exit code non-zero.
