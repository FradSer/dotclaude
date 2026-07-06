---
name: bdd-specs-explicit-req-tracing
category: pitfall
summary: bdd-specs.md needs explicit (Req #N) tags per scenario, not just topical naming
source: docs/plans/2026-07-06-agentbook-memory-design/
created: 2026-07-07
updated: 2026-07-07
---

Writing `bdd-specs.md` scenarios with topically-matching titles (e.g. a scenario named after what it tests, with the covered requirement only inferable by reading its content) survived 4 evaluator rounds before REQ-TRACE-01 was raised to demand explicit `(Req #N)` tags on every covering scenario/feature title — even though `_index.md` used a plain numbered requirements list (not the `REQ-NNN` format the checklist's own literal mechanical script checks for), and two earlier shipped designs in this repo (`2026-07-04-superpowers-memory-layer-design`, `2026-07-04-docs-index-design`) had passed REQ-TRACE-01 on topical-match reasoning alone.

**Why:** The evaluator's REQ-TRACE-01 verdict is not stable across independent rounds for non-`REQ-NNN` designs — one round accepted "the design's own Traceability Notes section cross-references every architecture-only requirement by number, and every behavioral requirement has an obviously-matching scenario" as sufficient; the very next round rejected the identical content, requiring literal `(Req #N)` citations on every scenario/feature title instead, quoting a "must be explicitly traceable by ID, not inferred by topic" standard that does not appear verbatim in the checklist file itself. Whichever reading is "correct," writing to the stricter one from the first draft avoids a full extra round-trip (in this design's case, this alone cost round 5 out of 6 total rounds).

**How to apply:** When brainstorming's Phase 2 writes `bdd-specs.md` against a numbered (non-`REQ-NNN`) `_index.md` requirements list, tag every Scenario/Scenario Outline/Feature title with an explicit `(Req #N)` marker (or `(Req #N, #M)` for a scenario covering more than one) from the first draft — do not rely on topical naming or a prose Traceability Notes section alone, even for architecture-only/non-functional requirements that have no natural Given/When/Then shape (cite those by ID in a Traceability Notes block, but still cite them). Before spawning the evaluator, grep `bdd-specs.md` for `Req #[0-9]+` and diff the resulting set against every requirement number in `_index.md` — any gap should be closed before the first evaluator round, not discovered by it.
