# Productivity

General workflow tools, not code-specific.

## User-invoked

Reachable only when you type the skill name (Claude Code: `disable-model-invocation: true` — the model will not auto-invoke them; another skill cannot reach them either).

- **[grill-me](./grill-me/SKILL.md)** — Get relentlessly interviewed about a plan or design until every branch of the decision tree is resolved.
- **[handoff](./handoff/SKILL.md)** — Compact the current conversation into a handoff document so another agent can continue the work.
- **[teach](./teach/SKILL.md)** — Teach the user a new skill or concept over multiple sessions, using the current directory as a stateful teaching workspace.
- **[to-questionnaire](./to-questionnaire/SKILL.md)** — Turn a decision you can't fully answer into a Markdown questionnaire for the one person who can — filled in async, or together over a meeting.
- **[wait-what](./wait-what/SKILL.md)** — Fire this the moment a message doesn't land. The agent re-pitches it with the context you're missing, in plain English, using your `CONTEXT.md` vocabulary.
- **[writing-great-skills](./writing-great-skills/SKILL.md)** — Reference for writing and editing skills well: the vocabulary and principles that make a skill predictable.

## Model-invoked

Model- or user-reachable (rich trigger phrasing so the model can reach for them).

- **[grilling](./grilling/SKILL.md)** — Interview the user relentlessly about a plan, decision, or idea until every branch of the decision tree is resolved.
- **[writing-for-agents](./writing-for-agents/SKILL.md)** — Reference for writing any document an agent consumes — a skill, `AGENTS.md`/`CLAUDE.md`, a doc reached by a pointer.
