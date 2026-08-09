---
name: bdd-specs-explicit-req-tracing
category: pitfall
summary: bdd-specs.md needs (Req #N) tags per scenario, not topical naming
source: docs/orphaned-designs.md (agentbook 设计要点)
created: 2026-07-07
updated: 2026-08-09
---

# bdd-specs.md needs explicit (Req #N) tags per scenario

## Fact

Scenarios with topically-matching titles (the covered requirement only inferable by reading content) survived 4 evaluator rounds before REQ-TRACE-01 demanded explicit `(Req #N)` tags on every covering scenario/feature title — even though `_index.md` used a plain numbered requirements list, and two earlier shipped designs had passed REQ-TRACE-01 on topical-match reasoning alone.

## Why

The evaluator's REQ-TRACE-01 verdict is not stable across independent rounds for non-`REQ-NNN` designs — one round accepted topical match + Traceability Notes, the next rejected the identical content requiring literal `(Req #N)` citations. Writing to the stricter standard from draft 1 avoids a full extra round-trip (cost round 5 of 6).

## How to apply

- From the first draft, tag every Scenario/Scenario Outline/Feature title with an explicit `(Req #N)` marker (or `(Req #N, #M)` when covering more than one)
- Do not rely on topical naming or a prose Traceability Notes block alone, even for architecture-only requirements with no Given/When/Then shape — cite those by ID in a Traceability Notes block, but still cite them
- Before spawning the evaluator, grep `bdd-specs.md` for `Req #[0-9]+` and diff against every requirement number in `_index.md` — close any gap before the first evaluator round

## Related

- Complement (evaluator-side): `docs/memory/convention_req-trace-explicit-citation.md`
- Checklist: `docs/retros/checklists/design-v1.md` (REQ-TRACE-01)
