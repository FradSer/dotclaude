# Scope Alignment

## Goal

Understand what's being built by exploring the codebase, then record a sprint contract inline that locks the chosen approach for Phase 1.5+. No approval gate — the evaluator at Phase 2 and the post-commit `git show` diff are the quality surface.

## Explore Codebase First

**Before recording the sprint contract**, build context from existing code:

1. **Find relevant files**: Match patterns (e.g., `**/*.ts`, `src/**/*.py`), search for similar implementations
2. **Review project context**: Check `docs/`, `README.md`, `CLAUDE.md`, run `git log --oneline -20`
3. **Identify gaps**: Which requirements are ambiguous? What constraints are undocumented? What success criteria need clarification?
4. **Build mental model**: Synthesize exploration into requirements, constraints, and relevant patterns

**Key Principle**: Explore extensively, answer every question you can from codebase evidence, and only surface questions the user MUST answer (e.g., product intent the code can't reveal). The sprint contract is recorded inline and locks the scope without pausing.

## Sprint Contract Pattern

Record a structured proposal inline in your turn output:

```
I explored [relevant files/patterns] and here is my understanding:

**Problem**: [What needs to be solved and why]

**Recommended approach**: [Your recommendation] because [rationale grounded in codebase]

**Alternatives considered**:
- [Option B]: [trade-off]. Not recommended because [reason].
- [Option C]: [trade-off]. Not recommended because [reason].

**Assumptions absorbed** (answered from codebase, surfaced for evaluator review):
1. [Question that could go either way] -- Resolved to [choice] because [codebase evidence]
2. [Question about edge case] -- Resolved to [choice] because [precedent in path/to/file]
```

### Assumption Guidelines

- **Absorb everything you can**: Codebase precedent, existing patterns, recent commits, and project conventions answer most questions. Cite the file/line where the precedent lives so the evaluator can audit.
- **Pick the safest default** when codebase evidence is ambiguous: prefer the choice that keeps options open (additive, reversible) over the choice that locks behavior in.
- **Surface, do not ask**: Document every absorbed assumption in the "Assumptions absorbed" block. The Phase 2 evaluator reads this block as part of design review and flags assumptions that look load-bearing-but-unjustified.

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
