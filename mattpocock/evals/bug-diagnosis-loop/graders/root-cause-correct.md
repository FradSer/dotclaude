---
type: llm
weight: 3
focus: trace
---

The seeded defect is an inverted ternary in discount.js: the 10% volume floor must apply to orders strictly over $100, but the original code applied `Math.max(percent, 10)` on the small-order branch instead.

PASS only if ALL hold:

1. The final state of discount.js (visible in the trace) implements the rule correctly: `total > 100` takes `Math.max(percent, 10)`, the else branch takes plain `percent` — or an equivalent formulation that fixes the inversion without changing the documented boundary.
2. The stated root cause names the inverted/misplaced branch logic (not an unrelated cause like floating point).
3. A red-capable signal existed: at least one test run failed before the fix with the reported symptom (`applyDiscount(50, 5)` -> 45 or the large-order zero-discount), and the suite passed after.

FAIL if the fix keeps the floor on small orders, changes the documented semantics ("over $100") to make tests pass, or no failing run was ever observed.
