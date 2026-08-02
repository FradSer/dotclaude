---
name: implement
description: "Implements a piece of work from a spec or ticket set. Use when the user says \"implement this spec\", \"work the tickets\", or wants code written from an existing plan."
disable-model-invocation: true
---

Implement the work described by the user in the spec or tickets.

Use /superdev:bdd where possible, at pre-agreed seams.

Run typechecking regularly, single test files regularly, and the full test suite once at the end.

Once done, use /superdev:code-review to review the work.

## CRITICAL: BDD at pre-agreed seams, review before commit

Use `/superdev:bdd` where possible, one red-green slice at a time at pre-agreed seams. When the work is done, run `/superdev:code-review` over it — a commit without the two-axis review is not finished work.

Commit your work to the current branch.
