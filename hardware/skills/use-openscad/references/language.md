# OpenSCAD language reference

OpenSCAD is functional — variables are constants within a scope, modules build geometry, functions return values. See `references/cli.md` for the compiler.

## Modules and functions

```openscad
function name(p1=default1, p2=default2) = expression;   // returns a value
module name(p1=default1) { ...actions... }              // returns geometry
name(args);                  // instantiate module as object (ends with ;)
name(args) { children }      // instantiate as operator wrapping children

// Operator modules access wrapped geometry via children()
children();                  // all children
children(i);                 // one child
children([start:step:end]);  // range
$children;                   // count

// Recursion (ternary to terminate; tail-recursive up to ~1,000,000)
function factorial(n, acc=1) = n<=1 ? acc : factorial(n-1, n*acc);

// Function literals require 2021.01+
func = function(x) x*x;
echo(func(5));
```

## Variables and scope

- **Immutable within a scope.** Reassigning in the same scope replaces the earlier assignment at its original position (the first is never executed; a warning is emitted). Last-value-wins.
- Braces create inner scopes; inner assignments do **not** leak outward.
- Use `is_undef(x)`, not `x == undef`.
- Special variables `$fn` / `$fa` / `$fs` / `$t` are dynamic.
- `-D var=val` from the CLI overrides top-level program values — this is the primary parametric interface (see `references/cli.md`).

## Control flow (at module scope)

```openscad
for (i = [0 : 1 : 10]) translate([i*5,0,0]) cube(1);   // builds a tree, not a loop
for (i = [0:10], j = [0:10]) ...                        // nested shorthand
intersection_for (i = [0:30:360]) rotate(i) ...;        // for() but intersect instead of union
if (cond) { ... } else if (cond2) { ... } else { ... }
let (a=1, b=a*2) ...                                    // 2019.05+, sequential; replaces assign()
cond ? val1 : val2                                       // ternary
```

> `--enable lazy-union` changes `for()` and module semantics — only enable deliberately.

## CSG booleans

```openscad
union()        { ... }              // sum (logical OR); mandatory to group difference()'s first child
difference()   { A; B; C; }         // A minus (B and C); B/C must fully overlap the removed surface
intersection() { ... }              // common volume (logical AND)
render(convexity=10) { ... }        // force CGAL eval; only affects OpenCSG preview, can slow it
```

- 2D and 3D cannot be mixed in one boolean.
- Coincident faces in unions cause artifacts — use a small epsilon (e.g. `0.01`).

## Primitives (3D)

```openscad
cube([x,y,z], center=false);   cube(5);                  // default [1,1,1], center=false
cylinder(h=1, r=1, center=false, $fn=0,$fa=12,$fs=2);    // or r1/r2, or d/d1/d2
sphere(r=1, $fn=0,$fa=12,$fs=2);                          // or d=
polyhedron(points=[[x,y,z],...], faces=[[i,j,k],...], convexity=1);
```

`polyhedron` faces: points listed **clockwise viewed from outside** (left-hand rule). Debug winding via View → Thrown Together (F12) — mis-oriented faces show pink.

## 2D primitives (extrudable)

```openscad
circle(r=1, $fn=0,$fa=12,$fs=2);   circle(d=20);
square([x,y], center=false);       square(10);
polygon(points=[[x,y],...], paths=[[i,j,k],...], convexity=1);   // paths omitted = all points in order; multiple paths = first outer, rest holes
text("OpenSCAD", size=10, font="Liberation Sans", halign="left", valign="baseline", spacing=1, $fn=0);
// text direction: "ltr"|"rtl"|"ttb"|"btt"; custom fonts: use <path/font.ttf>
```

## Transforms

```openscad
translate([x,y,z]) ...
rotate(a=deg, v=[x,y,z]) ...        // single angle around axis v
rotate([rx,ry,rz]) ...              // X then Y then Z; rotate(45) = around Z
scale([sx,sy,sz]) ...;  mirror([nx,ny,nz]) ...;  resize([x,y,z], auto=...) ...
color("red", alpha=1.0) ...;  color([r,g,b]) ...;  color("#rrggbb") ...
multmatrix(m=[[c,-s,0,tx],[s,c,0,ty],[0,0,1,tz],[0,0,0,1]]) ...
offset(r=1) ...                     // radial, rounded corners; +out/-in
offset(delta=3, chamfer=false) ...  // fixed distance, sharp/chamfered
hull() { ... }                      // convex hull; 2D then linear_extrude is cheaper than 3D hull
minkowski() { ... }                 // Minkowski sum; SLOW at high $fn, union() compound inputs first
```

## Extrusion and projection

```openscad
linear_extrude(height=5, center=false, twist=0, scale=1.0, slices=..., convexity=10, $fn=...) { 2D }
rotate_extrude(angle=360, start=0, convexity=2, $fn=...) { 2D }   // 2D must be entirely right (or left) of Y-axis
projection(cut=false) { 3D }    // project 3D children onto XY → 2D (for DXF/SVG). cut=true = slice at z=0 only.
```

`projection(cut=...)` is confirmed in the 3D-to-2D Projection docs and the official cheat sheet.

## import / surface / include / use

```openscad
import("part.stl", convexity=3);            // 3D: STL/OFF/OBJ/AMF/3MF; 2D: DXF/SVG/PDF
import("plate.dxf", layer="cut");           // layer filter for DXF/SVG
surface(file="h.dat", center=false, invert=false, convexity=5);   // heightmap from text/PNG
include <lib.scad>     // literal copy-paste (carries top-level geometry + variables; confuses line numbers)
use <lib.scad>         // no top-level geometry executed; functions/modules available; PREFERRED for libraries
```

**Always `use` libraries, never `include` them** — `include` runs top-level geometry and leaks variables into the caller.

## Idiomatic examples

**Parametric box with bolt holes:**
```openscad
module box(w=40, d=30, h=20, t=2, hole_r=1.6, $fn=40) {
  difference() {
    cube([w, d, h], center=true);
    translate([0,0,t]) cube([w-2*t, d-2*t, h], center=true);
    for (x=[-1,1], y=[-1,1])
      translate([x*(w/2-5), y*(d/2-5), 0])
        cylinder(h=h+1, r=hole_r, center=true);
  }
}
box();
```

**2D plate for laser cutting (DXF):**
```openscad
$fn=64;
difference() {
  offset(r=2) square([80, 50], center=true);   // rounded outer
  for (x=[-30,0,30]) translate([x,0]) circle(r=2.5);
}
```
