---
name: req-trace-explicit-citation
category: convention
summary: design-v3 REQ-TRACE-01 requires explicit (Req #N)/REQ-NNN citations and a full-set scan
source: docs/retros/retro-2026-07-09-memory-layer-and-agentbook.md
created: 2026-07-09
updated: 2026-07-09
---

# REQ-TRACE-01 (design-v3) enforces explicit citations + full-set scan

## Fact

`docs/retros/checklists/design-v3.md` rewrites REQ-TRACE-01 so that:

1. Requirement IDs are extracted from `_index.md` in either form — `REQ-NNN` **or** a numbered list (`1.`, `#1`, `Requirement #20`, `Item 12`).
2. Every extracted ID must appear as an explicit citation in `bdd-specs.md` — `(Req #N)`, `Req #N`, or `REQ-NNN`. Topical scenario naming alone is FAIL.
3. Architecture-only requirements may live in a Traceability Notes block, but the ID string must still appear verbatim.
4. Every evaluation round runs a full-set scan and returns every missing ID in one rework list. Incremental single-ID fixes that re-enter evaluation are a protocol violation.

## Why

Under design-v1/v2 the mechanical script grepped only `REQ-NNN`. Designs that used a plain numbered requirements list made the script vacuous-PASS, after which independent evaluators improvised progressive stricter standards across rounds. Result: 3 consecutive REWORK rounds on `2026-07-04-superpowers-memory-layer-design` and 5 on `2026-07-06-agentbook-memory-design`, each round finding a *new* gap the previous fix did not address. The authoring-side workaround was already recorded in `docs/memory/pitfall_bdd-specs-explicit-req-tracing.md`; this convention is the evaluator-side half of the same rule, now checklist-enforced.

## How to apply

- When writing or evaluating a design against design-v3+, run the REQ-TRACE-01 full-set scan from the checklist before declaring PASS.
- Prefer `REQ-NNN` in new designs (designing-loops did this and avoided the thrash). Numbered lists remain legal but require `(Req #N)` tags on every covering scenario/feature from draft 1.
- Do not mark REQ-TRACE-01 PASS on topical match. Do not ship a single-ID rework and re-enter evaluation hoping the next round is clean.

## Related

- Checklist: `docs/retros/checklists/design-v3.md` (REQ-TRACE-01)
- Authoring-side pitfall (complement, not duplicate): `docs/memory/pitfall_bdd-specs-explicit-req-tracing.md`
- Driving retro: `docs/retros/retro-2026-07-09-memory-layer-and-agentbook.md`
- Driving plans: `docs/plans/2026-07-04-superpowers-memory-layer-design/`, `docs/plans/2026-07-06-agentbook-memory-design/`
