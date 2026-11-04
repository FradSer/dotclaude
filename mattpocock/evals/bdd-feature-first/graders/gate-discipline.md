---
type: llm
weight: 2
---

PASS only if ALL of the following hold (cite evidence from the trace or files):

1. A Gherkin spec (`features/volume-discount.feature`) was written before the test code and implementation were finalized.
2. The implementation was driven by a red-green loop: a `node --test` run FAILED before the discount logic existed or was corrected, and a later `node --test` run passed.
3. Boundary of "$100" was handled deliberately: the chosen reading (strictly over vs at-or-over) is stated somewhere visible (scenario names, comments, or the final summary), not left ambiguous.
4. The run did not stall: where the skill required asking the user, the agent stated the question and a default inline instead of ending the turn waiting for an answer.

FAIL if the tests were written all at once before any implementation (horizontal slicing) with no failing run in between, or if the feature file is missing/empty.
