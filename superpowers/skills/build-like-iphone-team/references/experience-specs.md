# Experience-Driven Specifications

## What is Experience-Driven Specs?

Experience specifications describe how a product should FEEL in human moments, not what metrics it should achieve. The original iPhone was spec'd as "a device you can use in the bathroom to check email" - a human moment that translated to 60fps scrolling performance.

## The iPhone Example

**Technical spec:** "Scroll at 60 frames per second"
**Experience spec:** "Reading email in the bathroom"

The difference:
- Technical spec is about measurement
- Experience spec is about a moment, a feeling, a human reality

From the experience moment, engineers worked backwards to derive the technical requirements.

## Why Experience Specs Matter

### Focus on What Matters

Metrics can be achieved without delivering a good experience:
- You can have 60fps scrolling that still feels janky
- You can have sub-100ms latency that still feels sluggish
- You can have 5-star ratings on features nobody uses

Experience specs ground the work in what actually matters to humans.

### Enable First-Principles Innovation

When you start from experience, you're not constrained by existing solutions. You can invent entirely new ways to deliver the feeling.

### Drive the Right Technical Decisions

The experience spec drives all technical decisions. Every choice is evaluated against "does this help deliver the feeling?"

## Creating Experience Specifications

### Step 1: Identify the Moments

When does this product matter most? What are the critical human moments?

**Example questions:**
- When would someone use this in their real life?
- What's the highest-stakes moment for this product?
- When does failure matter most?
- What's the ideal emotional state during use?

**Moments might include:**
- First use (onboarding)
- Critical task (completing purchase, sending important message)
- Emergency use (finding doctor, calling for help)
- Daily routine (checking notifications, quick action)

### Step 2: Describe the Moment Vividly

Write the moment as a story. Make it concrete. Include sensory details.

**Template:**

```
The Moment: [Descriptive name]

Context:
- When: [Specific situation]
- Where: [Physical or digital environment]
- Who: [User type/state]
- What: [What they're trying to accomplish]

Experience:
- Feeling: [What they should feel]
- Pace: [Rushed, calm, focused, relaxed]
- Friction: [None, minimal, acceptable, challenging]
- Outcome: [What success feels like]
```

### Step 3: Extract the "Feel"

From the moment description, extract the core feeling words.

**Common experience feels:**
- Instant
- Fluid
- Magical
- Invisible
- Confident
- Calm
- Excited
- Surprised
- Supported
- Empowered

**Example:**
- Reading email in the bathroom -> Fluid, instant, effortless
- Submitting tax forms -> Confident, supported, guided
- Finding a restaurant nearby -> Excited, adventurous, trusted

### Step 4: Translate Feel to Technical Constraints

For each feeling, derive technical requirements.

**Translation Guide:**

| Experience Feel | Technical Translation | Example |
|----------------|---------------------|---------|
| Instant | Latency <100ms for visible actions | Button clicks respond within 100ms |
| Fluid | 60fps for all animations | Scrolling, transitions, loading |
| Magical | "Just works" without setup | Auto-detect, smart defaults |
| Invisible | No cognitive load required | No menus to learn, patterns to discover |
| Confident | Clear feedback, no ambiguity | Status indicators, confirmation cues |
| Calm | No urgency, no time pressure | No countdowns, no flashing warnings |
| Excited | Delightful moments of surprise | Micro-interactions, animations |
| Surprised | Exceeds expectations in unexpected ways | Smarter than expected |

## Experience Specification Template

```markdown
# Experience Specification: [Feature/Product]

## Human Moments

### Moment 1: [Name]

**Context:**
- When: [Specific situation]
- Where: [Environment]
- Who: [User type]
- What: [Goal]

**Experience:**
- Feeling: [Primary emotion/state]
- Pace: [Speed/rhythm]
- Friction: [Expected difficulty]
- Outcome: [What success feels like]

### Moment 2: [Name]

[Repeat for each critical moment]

## Core Experience Feelings

[Extracted from moments - the key feelings to deliver]

1. [Feeling 1]
2. [Feeling 2]
3. [Feeling 3]

## Technical Constraints Derived

### From [Feeling 1]:

- [Constraint 1]
- [Constraint 2]

### From [Feeling 2]:

- [Constraint 1]
- [Constraint 2]

## Anti-Patterns

What MUST NOT happen (would break the experience):

1. [Anti-pattern 1]
2. [Anti-pattern 2]

## Success Criteria

How we know the experience is delivered:

1. [Criterion 1]
2. [Criterion 2]
```

## Examples

### Example 1: Mobile Payment App

**Moments:**
1. Paying for coffee in a rush at 7:55 AM
2. Splitting a bill with friends at dinner
3. Returning a purchase that was wrong

**Feelings:** Instant, confident, frictionless

**Constraints:**
- Payment complete in <3 seconds (rushed moment)
- Clear confirmation that payment went through (confidence)
- One-tap to split bill (frictionless)
- One-tap refund request (wrong purchase moment)

**Anti-patterns:**
- Any extra screen or confirmation beyond the minimum
- Unclear whether payment succeeded
- Having to type anything to split bill

### Example 2: Developer Documentation

**Moments:**
1. Debugging at 11 PM with deadline tomorrow
2. Learning a new framework on weekend
3. Looking up API details during code review

**Feelings:** Confident, supported, instantly findable

**Constraints:**
- Answer found in <10 seconds (deadline moment)
- Examples copy-paste runnable (learning moment)
- API signature visible without clicking (code review moment)

**Anti-patterns:**
- Walls of text without examples
- Having to scroll past ads or navigation to find answer
- Examples that don't match real-world use

### Example 3: Fitness Tracking

**Moments:**
1. Starting a workout when tired after work
2. Checking progress mid-workout
3. Reviewing weekly achievements on Sunday

**Feelings:** Supported, motivated, proud

**Constraints:**
- Start workout in 1 tap (tired moment)
- Progress visible at a glance (mid-workout)
- Celebratory feedback for achievements (proud moment)

**Anti-patterns:**
- Multiple steps to start workout
- Have to pause workout to check progress
- Dull or perfunctory achievement celebration

## Validating Experience Specs

### The "5-Why" Test

For each constraint derived from a feeling, ask "why" 5 times to ensure it traces back to the human moment.

**Example:**
- Constraint: Payment in <3 seconds
- Why? Because it's the 7:55 AM rush moment
- Why does that matter? User needs to not be late
- Why does 3 seconds matter? Any longer creates anxiety
- Why does anxiety matter? It breaks the "confident" feeling
- Why does confidence matter? Because payments are high-stakes

### The "Anti-Metric" Test

Identify what metrics would NOT be achieved even if the experience is perfect.

**Example payment app:**
- Perfect experience: 3-second payment, confident feel
- NOT optimized for: Most features, most integrations, most customizability
- Those metrics would actually HURT the experience

### The "Competitor Test"

If a competitor delivered the experience perfectly with different technical choices, would we recognize it as the same experience?

**Example:**
- If competitor delivered 3-second payment with NFC and we used QR codes
- Both deliver "instant, confident, frictionless"
- Technical choice doesn't matter if experience is achieved

## Experience-Driven Design Process

1. **Write the moments** - Concrete human scenarios
2. **Extract the feelings** - Core emotional states
3. **Derive constraints** - Technical requirements from feelings
4. **Design to constraints** - Everything must satisfy the experience
5. **Test against moments** - Validate with real human moments

## Common Pitfalls

### Mistake: Specifying Features Instead of Feelings

**Bad:** "One-click payment"
**Good:** "Instant feeling of completion"

One-click might not be the best way to achieve instant. Spec the feeling, not the implementation.

### Mistake: Including Business Goals

**Bad:** "Increase conversion rate"
**Good:** "User feels confident completing purchase"

Conversion is a metric. Confidence is an experience. Focus on the experience that drives the metric.

### Mistake: Ignoring Failure States

Experience specs must include what happens when things go wrong. How should it feel when payment fails?

**Add failure moments:**
- Moment: Payment declined
- Feeling: Clear, calm, guided (not panicked, confused)

### Mistake: Too Many Feelings

Focus on 2-3 core feelings. Diluting across many feelings results in none being achieved well.

## References

See `../SKILL.md` for how experience specs integrate into the iPhone brainstorming workflow.

Remember: The iPhone wasn't spec'd as "a phone with these features." It was spec'd as a device you could use in the bathroom. The features came from the experience, not the other way around.