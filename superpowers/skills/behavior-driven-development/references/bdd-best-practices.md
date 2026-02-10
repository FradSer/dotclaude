# Behavior-Driven Development (BDD) Best Practices

Behavior-Driven Development (BDD) is an agile software development process that encourages collaboration among developers, quality assurance testers, and customer representatives in a software project.

## 1. The Core Lifecycle: Discovery, Formulation, Automation

Modern BDD (2024+) emphasizes that BDD is about *conversations* first, automation second.

### Discovery (The "Three Amigos")
Before writing code or tests, the "Three Amigos" (Business/PO, Developer, Tester) meet to discuss the feature.
*   **Goal:** Shared understanding.
*   **Method:** Structured conversations, often using techniques like **Example Mapping**.
*   **Output:** Concrete examples of how the system should behave.

### Formulation (Gherkin)
Convert those examples into structured scenarios using Gherkin syntax (Given/When/Then).
*   **Goal:** Executable specifications / Living Documentation.
*   **Standard:** Write *declarative* scenarios that describe business behavior, not UI implementation details.
*   **Reference:** See [Gherkin Guide](./gherkin-guide.md).

### Automation (TDD & Red-Green-Refactor)
Implement the scenarios using the Red-Green-Refactor cycle.

## 2. The Red-Green-Refactor Cycle

This is the engine of implementation.

### 🔴 RED: Write a Failing Test
*   **The Rule:** No production code is written without a failing test.
*   **The Check:** Run the test. It *must* fail. If it passes, your test is broken or the feature already exists.
*   **Best Practice:** Write small, targeted tests. Focus on one behavior at a time.

### 🟢 GREEN: Make it Pass
*   **The Goal:** Write the *minimal* amount of code to make the test pass.
*   **The Mindset:** "Make it work." Do not optimize yet. Do not over-engineer.
*   **YAGNI:** You Ain't Gonna Need It. Don't add fields or logic not required by the current test.

### 🔵 REFACTOR: Make it Clean
*   **The Goal:** Improve code structure without changing behavior.
*   **The Safety Net:** The green test ensures you don't break functionality while cleaning up.
*   **Actions:** Remove duplication, improve naming, extract methods, apply patterns.

## 3. General Best Practices

*   **Shift Left:** Testing happens *during* development, not after.
*   **Living Documentation:** Your feature files should be readable by business stakeholders and serve as the source of truth.
*   **One Scenario, One Behavior:** Keep scenarios focused.
*   **Integration:** Run BDD scenarios in your CI/CD pipeline.
*   **Test Behavior, Not Implementation:** Tests should survive refactoring. If renaming a private variable breaks a test, the test was too coupled to implementation.

## 4. BDD vs. TDD
*   **TDD** (Test-Driven Development) is a lower-level developer practice (unit tests).
*   **BDD** (Behavior-Driven Development) is a higher-level collaboration practice (acceptance tests).
*   **Usage:** Use BDD to define *what* to build (the requirements). Use TDD to ensure the *implementation* is correct and robust. They work best together.
