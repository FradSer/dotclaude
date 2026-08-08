# Testing Anti-Patterns

A test can pass and still verify nothing. This reference lists the ways that happens, so a passing test suite isn't mistaken for evidence of correctness.

## Mocking the Thing Under Test

If the test mocks the exact function or method whose behavior is in question, the test can only ever prove the mock was called — not that the real implementation does the right thing. Mock the *collaborators* of the unit under test (the database call, the network request, the clock), never the unit itself.

| Symptom | Fix |
|---|---|
| Test asserts `mockAuthenticate.calledWith(...)` and nothing else | Call the real `authenticate()` against a real or fake-but-faithful collaborator and assert on its return value / side effect |
| Test mocks the repository method that the task is implementing | Use an in-memory or test-double repository that behaves like the real one, not a mock of the method being written |

## Testing Implementation Details Instead of Behavior

A test that asserts on private internals, call counts to helper functions, or the exact sequence of internal steps breaks every time the implementation is refactored — even when the observable behavior is unchanged. This punishes REFACTOR-step cleanup and creates pressure to skip it.

| Symptom | Fix |
|---|---|
| Test asserts `helperFn` was called exactly twice | Assert on the caller's return value or externally observable side effect instead |
| Test reaches into a private field to check intermediate state | Assert on the public API's output for a given input |

## Over-Mocking Collapses the Test to a Tautology

When every collaborator is mocked to return canned values that exactly match what the assertion expects, the test verifies that the mocks were configured correctly — a tautology — not that the code under test does anything with them. A rule of thumb: if you can't state a way the test could fail short of a syntax error, it's testing the mocks, not the code.

## Mocking Something You Don't Understand

Do not mock a dependency's interface from memory or guesswork. An incorrect mock (wrong return shape, wrong error type, wrong async behavior) makes the test pass against a fictional version of the dependency, hiding real integration bugs until production. Read the real dependency's interface/contract before mocking it, or prefer a real instance / official test double when one exists.

## Trivial or Vacuous Assertions

A test with no assertion, or an assertion that is always true (`assert true`, `expect(x).toBeDefined()` on a value that's always defined), passes regardless of behavior. This is functionally equivalent to no test at all, but it inflates coverage numbers and gives false confidence. Every test must assert a specific, falsifiable expected value.

## Relationship to the Iron Law

All of the above can slip through the Red step if the failing-test check is shallow — a test can "fail" for the wrong reason (e.g. a mock isn't wired up yet) and still be vacuous once the wiring is in place. Verifying RED means confirming the failure message describes the *missing behavior*, not just that the test runner reported non-zero.
