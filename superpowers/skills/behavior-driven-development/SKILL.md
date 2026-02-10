---
name: behavior-driven-development
description: Apply BDD principles: specific requirements (Gherkin), Red-Green-Refactor cycle, and best practices for reliable software delivery.
user-invocable: true
version: 3.0.0
---

# Behavior-Driven Development (BDD) Skill

This skill provides a comprehensive guide to applying Behavior-Driven Development principles to your coding tasks. BDD is not just about tools; it's a methodology for shared understanding and high-quality implementation.

## How to Use This Skill

When the user asks for a feature, bug fix, or refactor, apply the following mindset:

1.  **Understand Behavior First:** Do not start coding until you know *what* the system should do.
2.  **Define Scenarios:** Create or ask for concrete examples (Gherkin) of the expected behavior.
3.  **Drive Implementation with Tests:** Use the Red-Green-Refactor cycle.

## Core Concepts

### 1. The BDD Cycle
The process flows from requirements to code:
*   **Discovery:** Clarify requirements through examples (The "Three Amigos").
*   **Formulation:** Write these examples as specific scenarios (Given/When/Then).
*   **Automation:** Implement using TDD.

See [BDD Best Practices](./references/bdd-best-practices.md) for a detailed guide.

### 2. Writing Scenarios (Gherkin)
Scenarios are your "Executable Specifications".
*   Keep them declarative (business focus).
*   Avoid technical jargon and UI details.
*   One behavior per scenario.

See [Cucumber Gherkin Guide](./references/gherkin-guide.md) for syntax and tips.

### 3. Red-Green-Refactor (TDD)
The engine of implementation:
1.  🔴 **RED:** Write a failing test for the scenario (or a unit thereof).
2.  🟢 **GREEN:** Write the minimal code to pass the test.
3.  🔵 **REFACTOR:** Clean up the code while keeping tests passing.

### 4. Avoiding Pitfalls
*   Don't test mocks; test behavior.
*   Don't write tests *after* the code.
*   Don't put logic in your test glue code.

See [Anti-Patterns](./references/anti-patterns.md) for what to avoid.

## Quick Reference: The Iron Law

> **"No production code is written without a failing test first."**

If you write code before the test:
1.  You don't know if the test is capable of failing (false positives).
2.  You are biased by your implementation.
3.  You are writing legacy code from day one.
