# Tool Design Philosophy

Designing Claude's action space is an art informed by model capabilities. This reference captures principles for shaping tools that work with Claude's strengths.

## Core Principle: Shape Tools to Model Abilities

The central question: What tools would YOU want if solving this problem, given YOUR skills?

| Your Ability | Tool You'd Want |
|--------------|-----------------|
| Manual calculation only | Paper |
| Know calculator operations | Calculator |
| Can write and execute code | Computer |

Apply this to Claude: design tools that match what the model can actually do well.

**Model Strengths → Tool Shapes**:
| Claude Strength | Effective Tool Shape |
|-----------------|----------------------|
| Pattern matching in text | Skills with progressive disclosure |
| Autonomous reasoning | Isolated agents with focused scope |
| Building context through exploration | Search tools + reference files (not pre-loaded context) |
| Following structured instructions | Commands with clear phases |
| Synthesizing information | Subagents that return summaries |

**Anti-pattern**: Forcing Claude through a tool designed for a different capability profile leads to friction, confusion, and poor results.

## The High Bar for New Tools

Claude Code has ~20 tools. Each new tool is another option the model must consider during reasoning.

**Decision hierarchy** (try in order):

1. **Existing tools + skill?** → Use progressive disclosure (preferred)
2. **Structured output or UI integration needed?** → Dedicated tool
3. **Isolated decision-making needed?** → Subagent with restricted tools
4. **External data or action needed?** → MCP server

**Example - Claude Code Guide**: Instead of adding a "documentation search" tool, we built a subagent with instructions on searching docs well. Same capability, no new tool.

## Model Capability Evolution

Claude models improve continuously. Tools that help today may constrain tomorrow.

### Case Study: TodoWrite → Task

| Phase | Tool | Rationale |
|-------|------|-----------|
| Initial | TodoWrite + reminders | Model forgot goals; reminders every 5 turns |
| Improvement | TodoWrite only | Model got better at tracking |
| Current | Task | Opus 4.5 found todo lists limiting; needed subagent coordination |

**Lesson**: As models improve, they need less scaffolding. Revisit assumptions regularly.

### Evolution Signals

Watch for these patterns in model outputs:

| Signal | Action |
|--------|--------|
| Model ignores or works around a tool | Simplify or remove |
| Model sticks to list instead of adapting | Remove rigid structure |
| Model uses subagents more effectively | Enable coordination patterns |
| Model finds context independently | Reduce pre-loaded context |

## Iterative Design Process

Tool design is empirical, not theoretical. "See like an agent."

### The Design Loop

```
Observe → Identify Friction → Iterate → Validate
    ↑                                      ↓
    ←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←
```

1. **Observe** - Read model outputs when it uses your tool
2. **Identify friction** - Where does the model struggle?
   - Confusion about when to call
   - Wrong parameters
   - Unexpected paths taken
   - Verbose explanations before action
3. **Iterate** - Adjust tool SHAPE, not just content
   - Combine or split tools
   - Change parameter structure
   - Add or remove restrictions
4. **Validate** - Does the model call this tool correctly and confidently?

### Friction Patterns

| Friction | Root Cause | Fix |
|----------|------------|-----|
| Model explains before calling | Tool purpose unclear | Sharpen description |
| Model calls wrong tool first | Similar tools overlap | Consolidate or differentiate |
| Model uses verbose params | Parameter structure unnatural | Simplify schema |
| Model forgets tool exists | Not in natural workflow | Add trigger to skill |
| Model calls tool excessively | Tool too broad | Narrow scope |

## AskUserQuestion: A Design Journey

The evolution of elicitation (asking questions) demonstrates iterative design:

### Attempt 1: Modify ExitPlanTool
Added question array parameter to existing tool.

**Problem**: Confused model - was it asking for plan approval OR asking questions? What if answers conflicted with plan?

### Attempt 2: Custom Output Format
Modified output instructions for special markdown format.

**Problem**: Model inconsistent - appended extra sentences, omitted options, used wrong format.

### Attempt 3: Dedicated AskUserQuestion Tool
Created tool that:
- Blocks agent loop until user answers
- Shows modal UI
- Enforces structured output
- Can be called at any point

**Result**: Model understood and used it well.

**Lesson**: Even the best-designed tool fails if the model doesn't understand how to call it. Dedicated tools with clear boundaries work better than overloading existing tools.

## Progressive Disclosure: Adding Without Adding

Progressive disclosure lets you add functionality without adding tools.

### Pattern

```
Level 1: Metadata (always loaded) → "When to use me"
Level 2: SKILL.md (loaded on trigger) → "What I can do"
Level 3: References (loaded on demand) → "How to do it"
```

### When to Use

| Need | Traditional Approach | Progressive Disclosure |
|------|---------------------|------------------------|
| Add domain knowledge | New tool | Skill with references |
| Complex capability | Multi-tool workflow | Skill + existing tools |
| Optional features | Tool parameters | Reference files |
| Evolving content | Tool updates | Update skill/reference |

### Benefits

- No new tool = no new reasoning option
- Model discovers capability when needed
- Unlimited detail without context bloat
- Easy to update without code changes

## Search: From RAG to Agent-Driven

Claude's context-building evolved from passive to active:

| Era | Approach | Model Role |
|-----|----------|------------|
| RAG | Vector DB retrieves context | Passive recipient |
| Current | Grep/Glob tools + skills | Active builder |

**Key insight**: Claude became good at building its own context when given the right tools.

Skills formalized this through progressive disclosure - nested search across files to find exact context needed.

## Design Checklist

Before finalizing any tool or skill:

- [ ] Does this match a model strength?
- [ ] Have I tried using existing tools first?
- [ ] Can I use progressive disclosure instead?
- [ ] Is the tool shape natural for the model?
- [ ] Have I tested with actual model outputs?
- [ ] What happens when models improve - will this constrain?

## Summary Principles

1. **Tools match abilities** - design for what Claude does well
2. **High bar for new tools** - each tool adds reasoning complexity
3. **Evolution awareness** - today's helper may be tomorrow's constraint
4. **Iterate empirically** - read outputs, identify friction, adjust shape
5. **Progressive disclosure** - add capability without adding tools
6. **Active context building** - give Claude tools to find what it needs