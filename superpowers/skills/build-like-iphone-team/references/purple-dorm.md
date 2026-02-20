# Purple Dorm: Extreme Isolation

## What is Purple Dorm?

The original iPhone team worked in complete isolation in a building nicknamed "Purple Dorm." They were:
- Physically separated from the rest of Apple
- Shielded from outside influence and market pressures
- Unaware of competitor products
- Even some team members didn't know they were building a phone until announcement day

This extreme isolation allowed them to create something revolutionary without being influenced by:
- "How phones are supposed to be"
- What competitors were doing
- Industry conventions and patterns
- Carrier demands and constraints

## Why Isolation Matters

### Eliminates Noise

When building something revolutionary, outside opinions are distractions. Industry trends, competitor products, "how things are usually done" - all of these constrain thinking.

### Enables First-Principles Thinking

Without knowledge of conventions, you're forced to solve problems from first principles. You don't know "the right way" so you find the best way.

### Protects the Vision

Competing teams and Purple Dorm isolation work together: competing teams develop their approaches in isolation from each other AND from the outside world.

### Focus on Artistry, Not Compromise

The Purple Dorm teams weren't worried about carrier approval, market research, or industry standards. They focused on creating something perfect.

## Applying Purple Dorm Isolation

### For Competing Teams (See internal-competition.md)

When creating competing teams, each team works in isolation from:
- Other competing teams
- Industry context
- Competitor products
- External pressures

### For the Design Process

Even outside of competing teams, apply Purple Dorm principles:

1. **Ignore Industry Patterns** - Don't start with "what everyone does"
2. **Block External Noise** - Don't look at competitor products during ideation
3. **Isolate from Business Pressures** - Design for the user, not the market
4. **Work from First Principles** - Start with fundamental truths, not conventions

## Creating Isolated Agent Teams

Purple Dorm teams use the same structure as internal competition teams, with the added layer of isolation from external context.

### Team Structure

Each Purple Dorm team has:
- Complete isolation (no outside context except what you provide)
- No awareness of other teams
- No knowledge of industry conventions
- Full autonomy to design their approach

### Providing Isolated Context

When spawning a Purple Dorm team, provide ONLY what's necessary:

**Include:**
- The experience specification
- The first-principles analysis
- The problem statement
- Their specific approach philosophy

**Exclude:**
- Industry patterns and conventions
- Competitor products or approaches
- What "everyone" does in this category
- Business constraints and pressures

### Team Lead Agent Template

```yaml
---
name: purple-lead
description: Lead isolated Purple Dorm team to design [approach]. No outside context. Focus on delivering the experience specification through [approach]. Ignore all conventions and patterns.
model: sonnet
color: purple
tools: ["Read", "Write", "Edit", "Grep", "Glob", "Task", "WebSearch"]
---
You are a Purple Dorm team lead for the [project] initiative. Your team is in complete isolation.

## Your Mission

Design the best [approach] for [feature/component].

## Key Constraints

- You have NO context outside what's provided in this message
- You are NOT influenced by industry conventions, competitor products, or "how things are usually done"
- Focus entirely on delivering the experience specification
- Your approach: [evolutionary/revolutionary/essential/full/classic/bold]
- Work in isolation - do NOT look at external references unless specifically needed for technical research

## Your Deliverables

1. Complete design following the approach philosophy
2. Detailed rationale explaining your design decisions
3. Trade-offs and risks identified
4. Implementation-ready output (specs, diagrams, code snippets as needed)

## Team Coordination

Work with your teammates (already spawned) to complete the design. Use SendMessage to coordinate. Report back to the main conversation when your design is complete with a summary of your approach and key decisions.

## Experience Specification

[Insert spec here]

## First-Principles Analysis

[Insert analysis here]

## Approach Philosophy

[Insert approach constraints here]

Begin working independently. Deliver your best work.
```

## Managing Isolation

### During Design

**Do NOT:**
- Share information between teams
- Mention what "industry standard" is
- Reference competitor approaches
- Discuss market trends
- Let teams influence each other

**DO:**
- Let each team work completely independently
- Provide minimal, focused context
- Focus on the experience specification as the only true north

### After Design

Once teams deliver their work:
- Compare approaches side-by-side
- Choose the winner based on experience specification
- Extract insights from both approaches
- THEN consider external factors (implementation risk, team capability)

## The Purple Dorm Mindset

### Questions to Avoid

**Don't ask:**
- "What do competitors do?"
- "What's the industry standard?"
- "What are users used to?"
- "What's the safe choice?"

### Questions to Ask

**DO ask:**
- "What delivers the experience specification best?"
- "What's the simplest way to solve this problem?"
- "What if we ignored all conventions?"
- "What would make this feel magical?"

## Examples

### Example 1: The Original iPhone

**Without Purple Dorm:** The team would have likely:
- Added a physical keyboard (industry standard)
- Used stylus for precision (Palm/PocketPC pattern)
- Focused on enterprise features (BlackBerry model)
- Partnered closely with carriers for requirements

**With Purple Dorm:** They created:
- Multi-touch screen (no keyboard needed)
- Finger-based input (no stylus)
- Consumer-focused experience
- Insisted on full control from carriers

### Example 2: Email Interface

**Without Purple Dorm (industry standard):**
- Sidebar with folders
- List of emails in middle
- Reading pane on right
- Toolbar at top with reply/forward/delete

**Purple Dorm approach:**
- Focus on experience spec: "Instant, fluid reading"
- Minimal interface that gets out of the way
- Swipe gestures for actions
- Conversational threading by default
- Keyboard shortcuts for power users

### Example 3: Search Feature

**Without Purple Dorm (industry standard):**
- Search bar in header
- Results page with list of matches
- Filters on sidebar
- Pagination controls

**Purple Dorm approach:**
- Experience spec: "Find instantly what I need"
- Search in place, results overlay
- AI understands intent from context
- No separate results page needed
- Adaptive as user types

## Isolation vs. Ignorance

Purple Dorm doesn't mean being ignorant of reality. It means:

**Isolate from:**
- Design patterns and conventions (do your own thing)
- Competitor products (don't copy, don't fear)
- Industry trends (don't follow)
- External pressures (carrier demands, business constraints)

**Research:**
- Technical capabilities (what's possible)
- Emerging technologies (what's new)
- User needs (what people actually want)
- Implementation constraints (what's feasible)

The distinction: Isolate from "how it's usually done," but research "what's possible."

## Best Practices

### Do
- Provide minimal, focused context to teams
- Focus on experience specification as the guide
- Let teams work in complete isolation
- Ignore industry conventions during design
- Design from first principles

### Don't
- Share competitor information with teams
- Reference "industry standard" approaches
- Let teams influence each other during design
- Design based on market trends
- Compromise for external pressures

## Quality Checks

For Purple Dorm isolation, verify:

1. [ ] Teams received no external context beyond essentials
2. [ ] No industry patterns or conventions were provided
3. [ ] Competitor products were not referenced
4. [ ] Teams worked completely independently
5. [ ] Design decisions came from first principles, not conventions

## References

See `./internal-competition.md` for setting up competing teams.

See `./first-principles.md` for the thinking patterns that isolation enables.

See `../SKILL.md` for how Purple Dorm integrates into the iPhone brainstorming workflow.

Remember: The Purple Dorm teams didn't know they were building a phone. They were just building something perfect. That isolation allowed iPhone to revolutionize the industry, not iterate on it.