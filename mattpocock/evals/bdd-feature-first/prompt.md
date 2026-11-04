---
name: bdd-feature-first
description: "BDD lifecycle on a clean repo: Gherkin spec first, automated with the native runner, red before green."
tags: [bdd]
runs: 2
max_turns: 40
timeout_seconds: 1200
---

Load the mattpocock:bdd skill using the Skill tool and follow it on the Node project in the current working directory.

New behavior to specify and implement: "volume discount: orders over $100 get 10% off".

Constraints for this run:
- Run tests with `node --test` invoked DIRECTLY (the sandbox blocks npm's script-shell spawn, so `npm test` fails with EPERM — do not diagnose that, just use `node --test` and treat it as the project's runner). Do NOT install dependencies — the sandbox has no network.
- Write the Gherkin spec to `features/volume-discount.feature`.
- Append the complete verbatim output of EVERY test run to `test-outputs.txt`, each block preceded by a line `RUN <n> (red)` or `RUN <n> (green)` as appropriate.
- Headless: never block waiting for the user. Where the skill says to ask, state the question and your chosen default inline, then proceed.

Finish with a one-paragraph summary of the cycle you ran.
