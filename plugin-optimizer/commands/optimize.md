---
description: Validate and optimize Claude Code plugin structure and quality
argument-hint: <plugin-path>
allowed-tools: ["Read", "Glob", "Grep", "Bash(bash:*)", "Task", "TodoWrite", "AskUserQuestion"]
---

# Plugin Optimization

You are the Orchestrator. Guide the Agent through these strict phases to ensure a comprehensive audit and optimization of the target plugin.

## Core Principles

-   **Strict Phases**: Follow the phases sequentially. Do not skip steps.
-   **User Confirmation**: Ask for user input and confirmation where specified.
-   **Use TodoWrite**: Track all progress throughout the workflow.
-   **Resolve Path First**: Always ensure you are working with the absolute path of the target plugin.

---

## Phase 1: Discovery & Validation

**Goal**: Validate plugin structure and detect issues. No fixes are applied in this phase.

**Actions**:
1.  **Context**: User input is `$ARGUMENTS`.
2.  **Resolution**: Use `realpath` to resolve the absolute path to the plugin by treating `$ARGUMENTS` as a path.
3.  **Validation**: Ensure the resolved path exists.
4.  **Validate Directory Structure**:
    -   Check for `.claude-plugin/plugin.json` manifest file (required)
    -   Use Glob to find component directories
    -   Check standard locations:
        -   `commands/` for slash commands
        -   `agents/` for agent definitions
        -   `skills/` for skill directories
        -   `hooks/hooks.json` for hooks
    -   Verify auto-discovery works
    -   Report any missing directories or files (do NOT create them in this phase)
5.  **Execute Validation Suite**: As the Orchestrator, run the following validation scripts directly using the `Bash` tool. Do NOT launch a sub-agent in this phase.
    -   **Structure**: `bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate-file-patterns.sh "$TARGET"`
    -   **Manifest**: `bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate-plugin-json.sh "$TARGET"`
    -   **Components**: `bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate-frontmatter.sh "$TARGET"`
    -   **Anti-Patterns**: `bash ${CLAUDE_PLUGIN_ROOT}/scripts/check-tool-invocations.sh "$TARGET"`
6.  **Review**: Analyze the output of each script to identify all failures and issues. Compile a comprehensive list of problems found.

---

## Phase 2: Automated Fixes

**Goal**: Launch the optimizer agent to apply fixes for issues found in Phase 1.

**Actions**:
1.  **Delegate**: Launch the `plugin-optimizer:plugin-optimizer` agent. This must be the first time the sub-agent is launched.
2.  **Context**: Provide the agent with the resolved absolute path and the validation errors from Phase 1.
3.  **Fix Strategy**: Instruct the agent to:
    -   **Missing README**: Create basic `README.md` using content from `plugin.json`.
    -   **Missing Frontmatter**: Add default frontmatter to agent/command files.
    -   **Directory Structure**: Create missing standard directories (`commands`, `agents`, `skills`).
    -   **Refactor**: Rename files to kebab-case if needed.
4.  **Verification**: Ask the agent to re-run the specific validation script that failed.
5.  **Reporting**: Log all applied fixes.

---

## Phase 3: Interactive Triage

**Goal**: Consult user on uncertain issues and execute fixes immediately upon confirmation.

**Actions**:
1.  **Consult**: Use `AskUserQuestion` tool to present the initial findings.
2.  **Prioritize**: Ask the user which categories of issues they want to prioritize (e.g., "Structure only", "Tool Patterns", "Full Report").
3.  **CRITICAL**: Do not proceed to deep analysis until the user confirms.
4.  **Execute Fixes**: If the user authorizes specific fixes for the prioritized issues, execute them immediately.

---

## Phase 4: Redundancy Analysis

**Goal**: Identify content duplication and execute consolidation fixes after user confirmation.

**Actions**:
1.  **Resume Agent**: **CRITICAL**: Use the `resume` parameter with the agent ID from the previous phase to preserve context. DO NOT spawn a new agent.
2.  **Analyze**: Perform **Comprehensive Redundancy Analysis** according to standards in `skills/plugin-best-practices/references/`.
3.  **Consult**: Use `AskUserQuestion` tool when uncertain about classification.
4.  **Report**: Report findings with severity classifications and consolidation recommendations.
5.  **Execute Consolidation**: If the user confirms redundancy removal or content consolidation, perform the file operations immediately.

---

## Phase 5: Quality Review

**Goal**: Validate documentation quality and fix issues (automatically or with confirmation).

**Actions**:
1.  **Validate README**: Verify `README.md` in the plugin directory. Ensure it accurately reflects the plugin's name, description, and installed components (Agents, Commands, Skills).
2.  **Consult**: **MUST** use `AskUserQuestion` tool to confirm with the user before classifying severity if issues are found.
3.  **Apply Fixes**: If the user agrees to the quality improvements (e.g., updating README), apply the changes immediately.

---

## Phase 6: Version Management

**Goal**: Update plugin version based on optimization changes

**Actions**:
1.  **Assess Changes**: Review the extent of changes made during the `Automated Fixes` and other phases.
2.  **Determine Increment**:
    -   **Patch Update (+0.0.1)**: For minor fixes (e.g., formatting, small documentation updates, frontmatter tweaks).
    -   **Minor Update (+0.1.0)**: For significant changes (e.g., directory restructuring, logic fixes, major redundancy removal).
3.  **Update Version**:
    -   Read the current version from `.claude-plugin/plugin.json`.
    -   Calculate the new version based on the increment.
    -   Update the `version` field in `.claude-plugin/plugin.json`.
4.  **Log**: Record the version change for the final report.

---

## Phase 7: Summary & Report

**Goal**: Generate final optimization report

**Actions**:
1.  **Compliance Checklist**: Summary of all checks.
2.  **Actionable Fixes**: Grouped by Severity (Critical/Warning).
    -   Provide `file:line` and exact `Edit` parameters.
3.  **Redundancy Plan**: Suggestions for consolidating documentation.
4.  **Final Report**: Generate the report using the following strict format:

**Output Format**:

```markdown
## Plugin Validation Report

### Plugin: [name]
Location: [path]

### Summary
[Overall assessment - pass/fail with key stats]

### Issues by Severity
#### Critical ([count])
- `file/path` - [Issue] - [Fix]

#### Warnings ([count])
- `file/path` - [Issue] - [Recommendation]

### Component Inventory
- Commands: [count] found, [count] valid
- Agents: [count] found, [count] valid
- Skills: [count] found, [count] valid
- Hooks: [present/not present], [valid/invalid]
- MCP Servers: [count] configured

### Positive Findings
- [What's done well]

### Recommendations
1. [Priority recommendation]
2. [Additional recommendation]

### Overall Assessment
[PASS/FAIL] - [Reasoning]
```