---
name: behavior-driven-development
description: Applies behavior-driven development principles including Gherkin scenarios and test-driven development. This skill should be used when the user asks to implement features, fix bugs, or when writing executable specifications and tests before writing production code.
user-invocable: false
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

See `./references/bdd-best-practices.md` for a detailed guide.

### 2. Writing Scenarios (Gherkin)
Scenarios are your "Executable Specifications".
*   Keep them declarative (business focus).
*   Avoid technical jargon and UI details.
*   One behavior per scenario.
*   Use `bdd-specs.md` as the planning-stage scenario inventory in the superpowers workflow. During brainstorming and plan writing, keep the reviewed Given/When/Then scenarios in `docs/plans/.../bdd-specs.md` so design review, task decomposition, and sprint contracts all read from the same source.
*   **Store executable scenarios in .feature files, NOT as code comments** - once implementation begins, translate the scenarios that will be automated into `.feature` files or the framework-native executable test format. `bdd-specs.md` is for design and planning; `.feature` files are for automation and living documentation.

See `./references/gherkin-guide.md` for syntax and storage structure.

### 3. Red-Green-Refactor (TDD)
The engine of implementation:
1.  **RED:** Write a failing test for the scenario (or a unit thereof).
2.  **GREEN:** Write the minimal code to pass the test.
3.  **REFACTOR:** Clean up the code while keeping tests passing.

## CRITICAL: The Iron Law

> **"No production code is written without a failing test first."**

The Red step MUST verify the test fails for the right reason (run the test and read the failure output) before writing any implementation. Skipping or rationalizing this step produces:

1.  Tests that pass spuriously — you cannot tell if they are capable of failing.
2.  Implementation-biased tests — they reflect the code that was written, not the behavior under contract.
3.  Legacy code from day one — no behavioral safety net catches future regressions.

## References

- `./references/bdd-best-practices.md` - BDD methodology, discovery, formulation, and automation
- `./references/gherkin-guide.md` - Gherkin scenario syntax, storage structure, and examples
