# Designing Agents

Agents are autonomous subprocesses with isolated context. Combine a **Persona** (System Prompt) with **Capabilities** (Tools/Skills) to solve problems.

## Anatomy of a Robust Agent

### Persona (System Prompt)
Engineer the system prompt for reliability.

*   **Role Definition**: State "You are a [Role]. Your goal is [Goal]."
*   **Tone & Style**: Specify "Be concise." "Show your work." "Ask for confirmation before destructive actions."
*   **Constraints**: Define "Never edit files outside `/src`." "Always run tests after changes."

**CO-STAR Framework**:
*   **C**ontext: Background info.
*   **O**bjective: What to achieve.
*   **S**tyle: Tone/Format.
*   **T**one: Attitude.
*   **A**udience: Who is this for?
*   **R**esponse: Format of output.

### Tool Selection (Capabilities)
Adhere to the **Principle of Least Privilege**.
*   Give an agent *only* the tools it needs.
*   **Rationale**:
    *   **Safety**: A "Reader" agent shouldn't have `rm`.
    *   **Focus**: Fewer tools = less confusion.
    *   **Performance**: Smaller system prompt.

### Cognitive Load Management
*   **Scratchpads**: Encourage the agent to "think out loud" inside `<thinking>` blocks.
*   **Checklists**: Give the agent a checklist in its prompt to track progress.

## Agent Types in Plugins

| Type | Purpose | Tools | Example |
|------|---------|-------|---------|
| **Router** | Triage and redirect | None (or Task) | "Help Desk" |
| **Executor** | Do the work | Edit, Bash, Write | "Code Refactorer" |
| **Researcher** | Find info | Read, Search, Glob | "Log Analyzer" |
| **Verifier** | Quality Assurance | Bash (test), Read | "PR Reviewer" |

## Best Practices

1.  **Examples are Key**: Include 2-4 `<example>` blocks in the agent description. This is "Few-Shot Prompting" for the router. It teaches Claude *exactly* when to pick this agent.
2.  **Fail Fast**: Instruct agents to stop and report if prerequisites aren't met.
3.  **Hooks for Safety**: Use `PreToolUse` hooks to validate commands (e.g., preventing `git push --force` in a junior-dev agent). See `./references/components/hooks.md` for configuration.