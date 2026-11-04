---
name: tdd-direct-gate
description: Directly invoking tdd without Gherkin scenarios must trigger its CRITICAL check and route through bdd before any test code.
tags: [bdd, tdd, gate]
runs: 2
max_turns: 40
timeout_seconds: 900
---

Load the mattpocock:tdd skill using the Skill tool. The user asks you to write tests directly for this new behavior in the Node project in the current working directory: "volume discount: orders over $100 get 10% off". No `.feature` files or Gherkin scenarios exist yet.

Follow the skill's CRITICAL check exactly. Headless: you cannot wait on the user, so state the question the check requires you to ask, then follow the skill's prescribed path.

If the prescribed path leads you to implement the behavior: run tests with `node --test` invoked DIRECTLY (the sandbox blocks npm's script-shell so `npm test` gives EPERM — that is an environment limit, not a bug to chase; no installing dependencies, no network), and append the complete verbatim output of EVERY test run to `test-outputs.txt`, each block preceded by a line `RUN <n> (red)` or `RUN <n> (green)`.
