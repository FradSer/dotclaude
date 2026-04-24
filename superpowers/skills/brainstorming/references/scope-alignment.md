# Scope Alignment

## Goal

Understand what's being built by exploring the codebase, align on approach via sprint contract, and get user approval.

## Explore Codebase First

**Before asking any questions**, build context from existing code:

1. **Find relevant files**: Match patterns (e.g., `**/*.ts`, `src/**/*.py`), search for similar implementations
2. **Review project context**: Check `docs/`, `README.md`, `CLAUDE.md`, run `git log --oneline -20`
3. **Identify gaps**: Which requirements are ambiguous? What constraints are undocumented? What success criteria need clarification?
4. **Build mental model**: Synthesize exploration into requirements, constraints, and relevant patterns

**Key Principle**: Explore extensively before asking. Questions should fill gaps that codebase exploration cannot answer.

## Sprint Contract Pattern

Instead of asking questions one at a time, present a structured proposal:

```
I explored [relevant files/patterns] and here is my understanding:

**Problem**: [What needs to be solved and why]

**Recommended approach**: [Your recommendation] because [rationale grounded in codebase]

**Alternatives considered**:
- [Option B]: [trade-off]. Not recommended because [reason].
- [Option C]: [trade-off]. Not recommended because [reason].

**Key questions** (need your input):
1. [Question about scope/constraint] -- Options: A) ..., B) ..., C) ...
2. [Question about edge case] -- Options: A) ..., B) ...
```

### Question Guidelines

- **Batch independent questions** into the sprint contract (scope, constraints, edge cases that don't depend on each other)
- **Sequence dependent questions**: If answer to Q1 changes Q2, ask Q1 first, then Q2 in the next round
- **Prefer multiple choice** with 2-4 options to reduce cognitive load
- **Ground in codebase**: "I found [pattern X] in [file]. Should this follow the same approach?"

### Example Sprint Contract

```
I explored src/notifications/ and src/users/ and here is my understanding:

**Problem**: The payment system needs async processing to avoid blocking order creation.

**Recommended approach**: Event-driven pattern (like src/notifications/) because it
keeps payment decoupled from orders, handles failures gracefully, and follows existing
codebase conventions.

**Alternatives considered**:
- Synchronous API calls (like legacy /checkout): Simpler but tight coupling -- if
  payment service is down, orders fail. We've had reliability issues with this approach.

**Key questions**:
1. Should we support multiple payment providers? Options: A) Single provider now,
   B) Provider abstraction from the start
2. What's the retry policy for failed payments? Options: A) 3 retries with exponential
   backoff, B) Dead letter queue for manual review, C) Both
```

## When "No Alternatives" is Acceptable

- Codebase has one clear established pattern
- Requirements strongly constrain to single approach
- Alternatives would violate project constraints
- **Must explicitly state rationale**: "No alternatives considered because [reason]"

## Common Trade-Off Patterns

**Time vs. Space**
- Pre-calculation (fast reads, slow writes, sync issues) vs. On-demand (fresh data, simpler writes, slower reads)

**Consistency vs. Availability**
- Strong consistency (transactions, locking) vs. Eventual consistency (queues, fast response, briefly stale UI)

**Clean Code vs. Performance**
- Abstraction (ORM/layers, maintainable) vs. Raw optimization (raw SQL, fast, hard to change)

**Dependency Management**
- Existing library (no bloat, possibly older) vs. New library (purpose-built, increases surface)

## Anti-Patterns to Avoid

- **The "Lazy" Question**: "How should I implement this?" -- Explore and propose options instead.
- **The "Abstract" Question**: "What are the non-functional requirements?" -- Ask specific: "Do we need >1000 req/sec based on the current load balancer?"
- **Skipping exploration**: Asking before reading code wastes user time and produces ungrounded proposals.
