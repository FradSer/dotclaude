# Phase 2: Option Analysis - Detailed Guidance

## Goal

Evaluate different architectural approaches and get user buy-in on the chosen approach.

## Primary Agent Actions

### 1. Research Existing Patterns

Ground your options in codebase reality:

- Search for similar implementations in the codebase
- Look for established architectural patterns (MVC, layered, microservices, etc.)
- Identify libraries and frameworks already in use
- Check for coding conventions and style patterns

### 2. Identify Viable Approaches

Based on codebase exploration, propose 2-3 approaches:

**When to propose alternatives**:

- When there are genuinely different architectural choices
- When trade-offs exist between competing goals (speed vs. maintainability)
- When existing patterns suggest multiple valid paths

**When "No Alternatives" is acceptable**:

- When codebase has one clear established pattern
- When requirements strongly constrain to single approach
- When alternatives would violate project constraints
- **Must explicitly state rationale**: "No alternatives considered because [reason]"

### 3. Present Conversationally

**Don't use formal tables.** Write naturally as if explaining to a colleague:

**Structure**:

1. Lead with your recommended option
2. Explain why it fits best given the requirements and codebase
3. Describe alternative approaches with trade-offs
4. Reference specific files/patterns from the codebase

**Example Presentation**:

```
I recommend using the existing event-driven pattern (like we use in src/notifications/)
because it keeps the payment processing decoupled from order management. This means:
- Payment failures won't block order creation
- Easy to add payment providers later
- Consistent with how we handle other async operations

Alternative approach would be synchronous payment processing (direct API calls in the
order controller). This is simpler to understand but creates tight coupling - if the
payment service is down, orders can't be created at all. This is how the legacy
/checkout endpoint works, and we've had reliability issues with it.
```

### 4. Respect Existing Architecture

Your proposals should:

- Align with established patterns found during exploration
- Use existing libraries and frameworks when possible
- Follow the project's architectural style (monolith, microservices, etc.)
- Reference specific files to show grounding in reality

**Example**: "This follows the same layered approach we use in `src/users/` where
controllers call service classes that handle business logic."

### 5. Get User Approval

Use `AskUserQuestion` to confirm the chosen approach:

**CRITICAL: One Question at a Time**:

- **ALWAYS call `AskUserQuestion` with exactly 1 question** (never use 2-4 questions)
- If you need to clarify multiple aspects, ask them sequentially
- Wait for each answer before proceeding to the next question
- Continue asking single questions until the approach is fully clear and agreed upon

**Simple approval**:

```
Does the event-driven approach sound good, or would you prefer one of the alternatives?
```

**Clarifying trade-offs**:

```
The event-driven approach is more complex to debug but more reliable. The synchronous
approach is simpler but less robust. Which trade-off matters more for this feature?
```

## Key Principle

**Options should be grounded in codebase reality, not abstract possibilities.** Don't propose approaches that would require major architectural changes unless the requirements demand it.


## Common Trade-Off Patterns

**Time vs. Space (Complexity)**
*   **A: Pre-calculation**: Store results in DB. Pros: Fast reads. Cons: Slow writes, data sync issues.
*   **B: On-demand**: Calculate when requested. Pros: Always fresh data, simpler writes. Cons: Slower reads, CPU load.

**Consistency vs. Availability (CAP Theorem)**
*   **A: Strong Consistency**: Use transactions (SQL). Pros: Data always correct. Cons: Potential locking, slower.
*   **B: Eventual Consistency**: Use message queues. Pros: High system availability, fast user response. Cons: UI might show stale data briefly.

**Clean Code vs. Performance**
*   **A: Abstraction**: Use ORM/Layers. Pros: Maintainable, testable. Cons: Runtime overhead.
*   **B: Raw Optimization**: Raw SQL/Inlining. Pros: Max speed. Cons: Hard to read/change.

**Dependency Management**
*   **A: Existing Library**: Use what's in `package.json`. Pros: No new bloat. Cons: Might be older version/missing features.
*   **B: New Library**: Add purpose-built tool. Pros: Solves problem exactly. Cons: Increases bundle size, security surface.

## Output for Phase 3

Proceed to design creation with:

- User-approved approach with clear rationale
- Alternative approaches considered (brief summary)
- Relevant files and patterns to reference in design
- Trade-offs and constraints to keep in mind
- Complete context for creating comprehensive design document
