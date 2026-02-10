# Cucumber Gherkin Guide

Gherkin is the language used to define test cases in BDD. It is designed to be non-technical and human-readable, describing software behavior without detailing how that behavior is implemented.

## Key Principles

1.  **Declarative, Not Imperative:** Describe *what* the user does, not *how* they do it.
    *   *Bad:* "Given I click the user field, and I type 'Alice', and I click the password field..."
    *   *Good:* "Given I am logged in as 'Alice'"
2.  **Business Language:** Use the domain language (Ubiquitous Language) of the business, not technical terms like "JSON", "Database", or "CSS selector".
3.  **Single Responsibility:** Each scenario should test exactly one rule or behavior.

## Keywords Reference

### Feature
High-level description of a software feature. Groups related scenarios.
```gherkin
Feature: User Login
  As a registered user
  I want to log in
  So that I can access my dashboard
```

### Scenario / Example
A concrete example illustrating a business rule.
```gherkin
Scenario: Successful login
  Given I am on the login page
  When I log in with valid credentials
  Then I should be redirected to the dashboard
```

### Given (Context)
Describes the initial context or state of the system.
*   **Tip:** Use `Background` for Givens shared by all scenarios in a feature.

### When (Action)
Describes the event or action taken by the user or system.
*   **Tip:** There should usually be only one `When` step per scenario to clearly identify the trigger.

### Then (Outcome)
Describes the expected outcome or result.
*   **Tip:** This is where your assertions live.

### And / But
Connects multiple steps of the same type to improve readability.

### Scenario Outline & Examples
Used to run the same scenario with different data inputs.
```gherkin
Scenario Outline: Eating cucumbers
  Given there are <start> cucumbers
  When I eat <eat> cucumbers
  Then I should have <left> cucumbers

  Examples:
    | start | eat | left |
    |  12   |  5  |  7   |
    |  20   |  5  |  15  |
```

## Best Practices Checklist

- [ ] **Golden Rule:** Can a non-technical stakeholder read and understand this?
- [ ] **Independence:** Scenarios must not depend on each other (no shared state between tests).
- [ ] **Brevity:** Keep scenarios short (3-5 steps is ideal).
- [ ] **Data Tables:** Use data tables for setup to avoid repetitive "Given" steps.
- [ ] **Backgrounds:** Use Backgrounds to DRY up repeated setup, but don't hide critical context.
