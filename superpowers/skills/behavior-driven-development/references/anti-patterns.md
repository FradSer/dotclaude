# BDD & Testing Anti-Patterns

Avoid these common pitfalls to keep your BDD implementation healthy, maintainable, and valuable.

## 1. Testing Mock Behavior (The "Mockist" Trap)
**The Problem:** Writing tests that verify your mocks work, rather than your code.
**Example:** `expect(mockDatabase.save).toHaveBeenCalled()` without verifying the *result* of the save operation or the state change.
**The Fix:**
*   Test the *outcome*, not the implementation.
*   Use real dependencies where feasible (e.g., in-memory DBs) or contract tests.
*   **Rule:** Mocks are for isolation, not for testing.

## 2. Implementation Leakage
**The Problem:** Scenarios that describe UI mechanics instead of business behavior.
**Example:** "When I click the button with ID 'submit-btn'"
**Why it's bad:** If the UI changes (ID changes to 'login-btn'), the test fails even if the login logic works.
**The Fix:** Write declarative steps: "When I submit the login form". Encapsulate selectors in the automation layer (Page Objects), not the feature file.

## 3. The "Testing Iceberg"
**The Problem:** Having huge UI/End-to-End BDD suites and very few unit tests.
**Why it's bad:** E2E tests are slow, brittle, and hard to debug.
**The Fix:** Follow the **Test Pyramid**.
*   **Base:** Many Unit Tests (TDD)
*   **Middle:** Some Integration/Service Tests
*   **Top:** Few E2E BDD Scenarios (Critical paths only)

## 4. Tests as an Afterthought
**The Problem:** Writing code first, then adding tests later "to get coverage".
**Why it's bad:**
*   You test what you *built*, not what was *required*.
*   You miss edge cases.
*   Code is often harder to test because it wasn't designed with testing in mind.
**The Fix:** **RED phase is mandatory.** Watch the test fail first.

## 5. Partial Mocks / "Frankenstein" Objects
**The Problem:** Mocking only the fields your test "needs", creating objects that don't exist in reality.
**Example:** `const user = { name: "Bob" }` (when a real User also has `id`, `email`, `role`, etc.)
**Why it's bad:** Code that relies on the missing fields will crash in production but pass in tests.
**The Fix:** Use factories or builders to create complete, valid objects for tests.

## 6. The "Universal Logic" in Step Definitions
**The Problem:** Putting complex business logic inside the step definition code.
**The Fix:** Step definitions should be "glue code" only. They should delegate to helper classes, page objects, or API clients.
