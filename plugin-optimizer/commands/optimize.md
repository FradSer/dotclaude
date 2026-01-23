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

**Initial request:** $ARGUMENTS

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
5.  **Check for Commands Directory** (Modern Architecture Assessment):
    -   **CRITICAL**: If a `commands/` directory exists with `.md` files:
        -   Use `AskUserQuestion` tool to ask the user: "This plugin uses the legacy `commands/` structure. Modern best practice recommends using `skills/` for better modularity and self-contained documentation. Would you like to migrate commands to skills structure?"
        -   Options: "Yes, migrate to skills" / "No, keep commands as-is"
        -   If user chooses "Yes", record this decision for Phase 2 (Automated Fixes)
        -   If user chooses "No", skip migration and proceed with validation
    -   **Note**: This check aligns with modern plugin architecture where Skills are preferred over Commands for new functionality
6.  **Execute Validation Suite**: As the Orchestrator, run the following validation scripts directly using the `Bash` tool. Do NOT launch a sub-agent in this phase.
    -   **Structure**: `bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate-file-patterns.sh "$TARGET"`
    -   **Manifest**: `bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate-plugin-json.sh "$TARGET"`
    -   **Components**: `bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate-frontmatter.sh "$TARGET"`
    -   **Anti-Patterns**: `bash ${CLAUDE_PLUGIN_ROOT}/scripts/check-tool-invocations.sh "$TARGET"`
7.  **Review**: Analyze the output of each script to identify all failures and issues. Compile a comprehensive list of problems found.

**Output**: Comprehensive list of validation issues categorized by type (structure, manifest, frontmatter, anti-patterns)

---

## Phase 2: Automated Fixes

**Goal**: Launch the optimizer agent to apply fixes for issues found in Phase 1.

**Actions**:
1.  **Delegate**: Launch the `plugin-optimizer:plugin-optimizer` agent. This must be the first time the sub-agent is launched.
2.  **Context**: Provide the agent with the resolved absolute path and the validation errors from Phase 1.
3.  **Fix Strategy**: Instruct the agent to:
    -   **Commands to Skills Migration** (if user approved in Phase 1):
        -   For each command in `commands/*.md`:
            -   Create corresponding skill directory `skills/<command-name>/`
            -   Transform command `.md` file to `SKILL.md` format with proper frontmatter
            -   Add `user-invocable: true` to SKILL.md frontmatter
            -   Update plugin.json to declare new skills in `commands` field
            -   Document the migration in commit message
    -   **Missing README**: Create basic `README.md` using content from `plugin.json`.
    -   **Missing Frontmatter**: Add default frontmatter to agent/command files.
    -   **Directory Structure**: Create missing standard directories (`commands`, `agents`, `skills`).
    -   **Refactor**: Rename files to kebab-case if needed.
4.  **Verification**: Ask the agent to re-run the specific validation script that failed.
5.  **Reporting**: Log all applied fixes.

**Output**: List of all automated fixes applied with verification results

---

## Phase 3: Redundancy Analysis

**Goal**: Identify content duplication and execute consolidation fixes after user confirmation.

**Actions**:
1.  **Resume Agent**: **CRITICAL**: Use the `resume` parameter with the agent ID from the previous phase to preserve context. DO NOT spawn a new agent.
2.  **Analyze**: Perform **Comprehensive Redundancy Analysis** according to standards in `skills/plugin-best-practices/references/`.
3.  **Consult**: Use `AskUserQuestion` tool when uncertain about classification.
4.  **Report**: Report findings with severity classifications and consolidation recommendations.
5.  **Execute Consolidation**: If the user confirms redundancy removal or content consolidation, perform the file operations immediately.

**Output**: Redundancy analysis report with severity classifications and consolidation actions taken

---

## Phase 4: Quality Review

**Goal**: Validate documentation quality and fix issues (automatically or with confirmation).

**Actions**:
1.  **Validate README**: Verify `README.md` in the plugin directory. Ensure it accurately reflects the plugin's name, description, and installed components (Agents, Commands, Skills).
2.  **Consult**: **MUST** use `AskUserQuestion` tool to confirm with the user before classifying severity if issues are found.
3.  **Apply Fixes**: If the user agrees to the quality improvements (e.g., updating README), apply the changes immediately.

**Output**: Quality assessment report and documentation improvements applied

---

## Phase 5: Version Management

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

**Output**: Updated plugin version number and change rationale

---

## Phase 6: Summary & Report

**Goal**: Generate final optimization report

**Actions**:
1.  **Compliance Checklist**: Summary of all checks.
2.  **Actionable Fixes**: Grouped by Severity (Critical/Warning).
    -   Provide `file:line` and exact `Edit` parameters.
3.  **Redundancy Plan**: Suggestions for consolidating documentation.
4.  **Final Report**: Generate the report using the following strict format:

**Output**: Complete validation report in the specified format with all findings, fixes, and recommendations

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