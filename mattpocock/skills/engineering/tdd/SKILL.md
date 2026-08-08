---
name: tdd
description: "BDD-driven test implementation: red-green loop mechanics, seams, mocking, and test quality under BDD Automation. Use when the user wants to write or improve tests during BDD implementation, needs guidance on test structure, or asks about test seams, mocking, or anti-patterns."
---

# BDD-Driven TDD (Automation)

BDD cycles through three phases: **Discovery** (conversations → examples), **Formulation** (Gherkin scenarios), **Automation** (red-green-refactor, driven by BDD). This skill is the **BDD-driven Automation** reference — the how of test implementation, once `/mattpocock:bdd` has defined the what.

When invoked during `/mattpocock:implement` or `/mattpocock:bdd`, use this skill as the test-writing authority. The `/mattpocock:bdd` skill governs the scenario design and Iron Law; this skill governs the test code quality under BDD discipline.

## CRITICAL: BDD scenarios come first

If you reached this skill directly (not via `/mattpocock:bdd` or `/mattpocock:implement`), stop and ask the user: **"Have you defined the Gherkin scenarios for this behavior yet?"**

- If **no** → invoke `/mattpocock:bdd` first to define the scenarios via Discovery → Formulation, then return here for Automation.
- If **yes** → confirm the scenarios are in `.feature` files or equivalent, then proceed with the red-green loop below.

## What a good test is

Tests verify behavior through public interfaces, not implementation details. Code can change entirely; tests shouldn't. A good test reads like a specification — "user can checkout with valid cart" tells you exactly what capability exists — and survives refactors because it doesn't care about internal structure.

See [tests.md](tests.md) for examples and [mocking.md](mocking.md) for mocking guidelines.

## Seams — where tests go

A **seam** is the public boundary you test at: the interface where you observe behavior without reaching inside. Tests live at seams, never against internals.

**Test only at pre-agreed seams.** Before writing any test, write down the seams under test and confirm them with the user. No test is written at an unconfirmed seam. Not everything can be tested — agreeing the seams up front is how testing effort lands on the critical paths and complex logic instead of every edge case.

Ask: "What's the public interface, and which seams should we test?"

When the shape of that interface is itself in question — how deep the module is, where the seam belongs, what the interface should expose — use the `/mattpocock:codebase-design` skill for the vocabulary. It is the shared source of the module, interface, depth, seam, adapter, leverage and locality terms, and it is a reference to consult, not a session to run.

## Anti-patterns

- **Implementation-coupled** — mocks internal collaborators, tests private methods, or verifies through a side channel (querying the database instead of using the interface). The tell: the test breaks when you refactor but behavior hasn't changed.
- **Tautological** — the assertion recomputes the expected value the way the code does (`expect(add(a, b)).toBe(a + b)`, a snapshot derived by hand the same way, a constant asserted equal to itself), so it passes by construction and can never disagree with the code. Expected values must come from an independent source of truth — a known-good literal, a worked example, the spec.
- **Horizontal slicing** — writing all tests first, then all implementation. Bulk tests verify _imagined_ behavior: you test the _shape_ of things rather than user-facing behavior, the tests go insensitive to real changes, and you commit to test structure before understanding the implementation. Work in **vertical slices** instead — one test → one implementation → repeat, each test a **tracer bullet** that responds to what the last cycle taught you.

## Rules of the loop

- **Red before green.** Write the failing test first, then only enough code to pass it. Don't anticipate future tests or add speculative features.
- **One slice at a time.** One seam, one test, one minimal implementation per cycle.
- **Refactoring is not part of the loop.** It belongs to the review stage (see `/mattpocock:code-review`), not the red → green implementation cycle.

## CRITICAL: BDD-Driven — not standalone TDD

This skill is the **Automation** phase of the BDD lifecycle. It always runs under `/mattpocock:bdd` or `/mattpocock:implement` as **BDD-driven TDD**. If invoked directly, see the CRITICAL check at the top of this file — confirm scenarios exist before writing test code.

1. **Discovery** (what behavior matters) — owned by `/mattpocock:bdd` via Gherkin scenarios
2. **Formulation** (scenario as specification) — owned by `/mattpocock:bdd` via `.feature` files
3. **Automation** (this skill) — the red-green loop that makes the scenario pass

## When to invoke

Invoke this skill explicitly when:
- The user asks "how should I test this?" during BDD implementation
- The user asks about mocking, seams, or test structure
- The user writes a test that looks implementation-coupled
- The user asks about mocking strategy at system boundaries
- The user is unsure whether a test is good or tautological

When invoked directly, first check if Gherkin scenarios exist (see the CRITICAL check at the top). If not, redirect to `/mattpocock:bdd` before proceeding with Automation.

The `/mattpocock:bdd` and `/mattpocock:implement` skills load this automatically during the Automation phase — you do not need to invoke it separately in those flows.