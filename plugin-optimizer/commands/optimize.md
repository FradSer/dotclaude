---
description: Validate and optimize Claude Code plugin structure and quality
argument-hint: <plugin-path>
allowed-tools: ["Read", "Glob", "Grep", "Bash(bash:*)", "Task", "TodoWrite", "AskUserQuestion"]
---

# Plugin Optimization

**Launch the `plugin-optimizer` agent** to execute the following optimization workflow.

## Optimization Workflow

You are the Orchestrator. Guide the Agent through these strict phases to ensure a comprehensive audit.

**Before starting, use TodoWrite tool to create task list for these phases (use imperative form for content, present continuous for activeForm):**

1. Initialize and validate plugin structure
2. Execute automated validation scripts
3. Present findings and get user priorities
4. Perform redundancy analysis
5. Validate README best practices
6. Generate final optimization report

### Phase 1: Initialization
1.  **Context**: User input is `$ARGUMENTS`.
2.  **Resolution**:Use `realpath` to resolve the absolute path to the plugin by treating `$ARGUMENTS` as a path and resolving to absolute path.
3.  **Validation**: Ensure the resolved path exists.
4.  **Structure Check**: Verify the plugin has a valid structure:
    - Check for `.claude-plugin/plugin.json` manifest file (required)
    - Verify standard component directories and files:
      - `commands/` directory for slash commands (optional)
      - `agents/` directory for agent definitions (optional)
      - `skills/` directory for skill directories (optional)
      - `hooks/hooks.json` for hooks configuration (optional)
      - `.mcp.json` for MCP server configuration (optional)
    - Confirm this is a valid plugin directory (must have manifest at minimum)
    - If structure is invalid, report the issue and stop the workflow

### Phase 2: Automated Validation
Instruct the agent to **IMMEDIATELY EXECUTE** the following scripts.
**IMPORTANT**: Use the resolved absolute path from Phase 1 (referred to as `TARGET` below) as the argument for these commands.
1.  **Structure Validation**: Run `bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate-file-patterns.sh "$TARGET"` to validate file patterns and directory structure.
2.  **Manifest Validation**: Run `bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate-plugin-json.sh "$TARGET"` to validate the plugin manifest configuration.
3.  **Component Validation**: Run `bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate-frontmatter.sh "$TARGET"` to validate frontmatter in all component files. The script automatically finds and validates:
    - All `.md` files directly in `agents/` directory
    - All `.md` files directly in `commands/` directory
    - `SKILL.md` files directly in `skills/*/` subdirectories
    - **Excludes**: `README.md`, and all files in subdirectories (references/, examples/, scripts/, assets/, templates/, docs/, tests/, etc.)
4.  **Anti-Pattern Detection**: Run `bash ${CLAUDE_PLUGIN_ROOT}/scripts/check-tool-invocations.sh "$TARGET"` to detect anti-patterns in tool invocations.

### Phase 3: Interactive Triage
**STOP and Consult:**
Instruct the agent to use the `AskUserQuestion` tool to present the initial findings.
-   Ask the user which categories of issues they want to prioritize (e.g., "Structure only", "Tool Patterns", "Full Report").
-   *Do not proceed to deep analysis until the user confirms.*

### Phase 4: Deep Analysis (Redundancy) - CRITICAL CHECK
**Action**: Resume the previous agent.
**CRITICAL**: You **MUST** use the `resume` parameter with the agent ID from the previous phase to preserve context. DO NOT spawn a new agent.

Instruct the resumed agent to perform **Comprehensive Redundancy Analysis**:

**IMPORTANT**: Content redundancy is a CRITICAL quality issue that wastes context window, creates maintenance burden, and violates progressive disclosure principles. This phase is NOT optional.

1.  **Scan for Duplicate Content**:
    -   Check all markdown files in the plugin for duplicated text blocks (>3 consecutive lines)
    -   **Specifically check**:
        -   Agent system prompts vs skill content (agents should be 30-50 lines max, detailed knowledge in skills)
        -   Duplicate templates across reference files (e.g., system prompt templates)
        -   Workflow descriptions appearing in multiple places (README, commands, agents)
        -   Example blocks repeated across files
        -   Output format specifications duplicated in multiple locations
    -   **Exclude from redundancy checks**: README.md files (user-facing docs can summarize plugin content)

2.  **Distinguish Progressive Disclosure from True Redundancy**:
    -   **Progressive Disclosure (ACCEPTABLE)**: Same concept at different detail levels
        -   Example: Brief feature list in README + detailed explanation in skill
        -   Example: Command overview + agent execution details
    -   **True Redundancy (PROBLEMATIC)**: Identical or near-identical content
        -   Example: 128-line agent system prompt duplicating skill knowledge
        -   Example: Exact same template in multiple reference files
        -   Example: Identical workflow steps in multiple components
    -   **When uncertain**: Use `AskUserQuestion` tool to confirm with the user

3.  **Classify by Severity**:
    -   **Critical**: Agent system prompts >80 lines, exact template duplication, major workflow duplication
    -   **Warning**: Moderate text overlap (50-80% similarity), redundant examples
    -   **Info**: Minor overlap with clear purpose difference

4.  **Provide Consolidation Recommendations**:
    -   For bloated agents: Suggest reducing to role-specific content (~35 lines), moving knowledge to skills
    -   For duplicate templates: Identify canonical location, suggest cross-references
    -   For workflow duplication: Recommend single source of truth with references

### Phase 5: README Best Practices Validation
Instruct the agent to validate all `README.md` files in the plugin against best practices. If issues are found, **MUST** use `AskUserQuestion` tool to confirm with the user before classifying severity.

### Phase 6: Reporting & Handoff
Generate the final **Optimization Report**:
1.  **Compliance Checklist**: Summary of all checks.
2.  **Actionable Fixes**: Grouped by Severity (Critical/Warning).
    -   Provide `file:line` and exact `Edit` parameters.
3.  **Redundancy Plan**: Suggestions for consolidating documentation.

---
**Advisor Note**: Remind the agent that it is the domain expert, but YOU hold the checklist. Ensure every phase is completed.
