# Printability and 2D design rules

Heuristics for FDM 3D printing and laser cutting. Treat as defaults — confirm against the target machine/material.

## FDM 3D printing

- **Minimum wall thickness:** 0.4 mm (2 nozzle-width shells).
- **Overhangs:** up to 45° printable without supports; over 45° needs supports or reorientation.
- **Bridges:** up to ~10 mm span printable without supports; longer bridges sag.
- **All parts connected:** every solid must touch the bed or a supported layer — floating islands fail.
- **Clearance for fits:** 0.2–0.5 mm for moving/press fits; tighten for snap fits, loosen for sliding fits.
- **Manifold required:** the exported mesh must be a valid 2-manifold — each edge connects exactly two facets. Non-manifold geometry slicers refuse or print wrong. Scan stderr after export (see `references/workflows.md`).
- **Hole tolerances:** vertical holes print slightly small; size up by ~0.2 mm or drill after printing. Horizontal holes (along XY) are more accurate.
- **Small features:** pins below ~1 mm and text below ~6 mm often don't print cleanly on FDM.

## Orientation and supports

- Prefer orienting the model so the flattest face is down and overhangs are minimized.
- Rotate so critical dimensional surfaces are vertical (XY plane prints more accurately than Z).
- Use `rotate([rx,ry,rz])` at the top of the model to bake orientation in.

## 2D for laser cutting

- Design in 2D (`square`, `circle`, `polygon`, `text`, `offset`) — export DXF or SVG.
- **Kerf:** the laser removes ~0.1 mm of material; offset cut lines outward by half the kerf for press fits, or account for it in hole sizes.
- **Line width:** use hairline (0.0 mm or single-color) paths; OpenSCAD exports geometry, not stroke — keep cuts as single closed paths.
- **Tabs/slots:** for press-fit assemblies, add small tabs and matching slots; typical tab height ≈ material thickness.
- **Hole clearance:** laser holes cut slightly oversized; design nominal or slightly undersize.
- **Multiple paths:** in `polygon`, the first path is the outer outline, subsequent paths are holes — cut order and layer assignment are set in the laser software, not OpenSCAD.

## Parametric design conventions

- Put all tunable dimensions at the top of the file as variables, so `-D` can override them at the CLI.
- Initialize every `-D`-overridable variable in the `.scad` (e.g. `w = 40;`) — a `-D` override only binds if the variable is declared at top level.
- Use descriptive names (`wall_t`, `hole_r`, `tab_h`) and sensible defaults.
- Add `$fn` at the top for smooth curves, or per-cylinder for control. High `$fn` (e.g. 128) on `minkowski` is slow.

## File naming for iteration

When iterating on a design, use zero-padded versioned filenames so you can diff previews visually: `box_001.scad`, `box_002.scad`, `box_001.png`, `box_002.png`. The agent can read both PNGs to compare iterations.
