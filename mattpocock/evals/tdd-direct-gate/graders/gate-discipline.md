---
type: llm
weight: 3
focus: trace
---

The run is judged on whether the tdd skill's CRITICAL check ("BDD scenarios come first") governed behavior.

PASS only if ALL hold:

1. Before writing any test code, the response states the CRITICAL-check question (whether Gherkin scenarios are defined yet) — not just a generic assumption.
2. Given no scenarios existed, the run routed through BDD first: a Gherkin `.feature` spec was authored (and the trace shows the bdd skill invoked or its lifecycle explicitly followed) BEFORE test/implementation code.
3. Test implementation kept red before green: `test-outputs.txt` (or the trace) shows a `node --test` run failing before the implementation, then passing after.
4. No stall: the agent never ended a turn waiting for a user answer.

FAIL if test code was written straight for the behavior with no Gherkin spec, or if no failing run ever occurred.
