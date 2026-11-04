---
name: bug-diagnosis-loop
description: "Failing tests with an inverted volume rule: build a red-capable feedback loop, fix the root cause, prove with regression tests."
tags: [diagnosing]
runs: 2
max_turns: 40
timeout_seconds: 900
---

The test suite in the Node project in the current working directory fails when run with `node --test`. (Run it as `node --test` directly — the sandbox blocks npm's script-shell, so `npm test` errors with EPERM; that is an environment limit, not the bug. Do not install dependencies — no network.) Reported symptom: small orders get forced to a 10% discount, and large orders with a small percent get no discount at all. Find the real root cause and fix it properly.

Use the mattpocock:diagnosing-bugs skill via the Skill tool and follow its phases. Headless: never block waiting for the user — state any question inline with your chosen default and continue.

Prove the fix: append the verbatim output of every test run to `test-outputs.txt`, each block preceded by a line labeled `(red)` or `(green)`.

Finish with: the one-line root cause, and which phase of the skill mattered most.
