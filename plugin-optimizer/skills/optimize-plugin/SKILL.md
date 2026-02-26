---
name: optimize-plugin
description: Executes plugin validation and optimization workflows. This skill should be used when the user asks to "validate a plugin", "optimize plugin", "check plugin quality", "review plugin structure", or mentions plugin optimization and validation tasks.
argument-hint: <plugin-path>
user-invocable: true
allowed-tools: ["Read", "Glob", "Bash(realpath *)", "Bash(bash:*)", "Task", "AskUserQuestion", "TaskCreate", "TaskUpdate"]
---

# Plugin Optimization

Execute plugin validation and optimization workflow. **Target:** $ARGUMENTS

## Background Knowledge

### Tool Invocation Patterns

| Tool | Style | Correct Format |
|------|-------|----------------|
| Read, Write, Glob, Grep, Edit | Implicit | "Find files matching...", "Read each file..." |
| Bash | Implicit | "Run `git status`" |
| Task | Implicit | "Launch `plugin-name:agent-name` agent" |
| Skill | **Explicit** | "**Load `plugin-name:skill-name` skill** using the Skill tool" |
| AskUserQuestion | **Explicit** | "Use `AskUserQuestion` tool to [action]" |
| TaskCreate | **Explicit** | "**Use TaskCreate tool** to track" |

**Qualified Names**: Plugin components MUST use `plugin-name:component-name` format.

**Progressive Disclosure**: Skills package domain expertise—turning general agents into knowledgeable specialists. Progressive disclosure protects context: metadata (~50 tokens) -> SKILL.md (~500 tokens) -> references (2000+ tokens, MUST only access when specifically needed).

### Component Template Validation

Components MUST conform to templates in `${CLAUDE_PLUGIN_ROOT}/examples/`.

**Agent Template Requirements**:
- Frontmatter: `name`, `description`, `color`, `allowed-tools`
- System Prompt: Second person ("You are..."), descriptive voice (NOT directive)
- Structure: **Knowledge Base** + **Core Responsibilities** + **Approach** sections

**Instruction-Type Skill Requirements** (user-invocable: true):
- Frontmatter: `name`, `description`, `user-invocable: true`, `allowed-tools`
- Voice: Imperative ("Load...", "Create...", "Execute...")
- **MANDATORY Phase Format**: `## Phase N: [Phase Name]` with **Goal** and **Actions** subsections
- Optional Pre-Phases: `## Background Knowledge`, `## Initialization`, `## Context`

**Knowledge-Type Skill Requirements** (user-invocable: false):
- Frontmatter: `name`, `description`, `user-invocable: false`
- Voice: Declarative ("is", "are", "provides")
- Structure: Topic-based sections ("## Core Concepts", "## Best Practices")

**Type Classification Quick Reference**:

| Component Type | user-invocable | Voice | Structure | Declared in |
|----------------|----------------|-------|-----------|-------------|
| Agent | N/A | Descriptive (You are...) | Knowledge Base + Core Responsibilities + Approach | `agents` |
| Instruction Skill | `true` | Imperative (Load...) | Phase-based (Goal + Actions) | `commands` |
| Knowledge Skill | `false` | Declarative (is/are...) | Topic-based (concepts/patterns) | `skills` |

**Manifest Cross-Validation**: Instruction-type MUST be in `plugin.json` `commands` array; Knowledge-type MUST be in `plugin.json` `skills` array.

## Phase 1: Discovery & Validation

**Goal**: Validate structure and detect issues. Orchestrator MUST NOT apply fixes.

**Actions**:
1. Resolve path with `realpath` and verify existence
2. Validate `.claude-plugin/plugin.json` exists
3. Find component directories: `commands/`, `agents/`, `skills/`, `hooks/`
4. Validate components against `${CLAUDE_PLUGIN_ROOT}/examples/` templates
5. Assess architecture: if `commands/` exists with `.md` files, use `AskUserQuestion` tool to ask about migrating to skills structure
6. Run validation: `python3 ${CLAUDE_PLUGIN_ROOT}/scripts/validate-plugin.py "$TARGET"`
   - Options: `--check=structure,manifest,frontmatter,tools,tokens`
   - JSON output: `--json`
   - Verbose: `-v, --verbose`
7. Compile issues by severity (Critical, Warning, Info)

## Phase 2: Agent-Based Optimization

**Goal**: Launch agent to apply ALL fixes. Orchestrator does NOT make fixes directly.

**Condition**: Always execute.

**Actions**:
1. Launch `plugin-optimizer:plugin-optimizer` agent with the following prompt content:
   - Target plugin path (absolute path from Phase 1)
   - Validation console output (issues list from Phase 1)
   - Template validation results
   - User decisions (migration choice if applicable)
   - INSTRUCTION: Analyze the validation output to identify issues
2. Agent autonomously applies fixes (MUST use `AskUserQuestion` tool before applying template fixes, presenting violations with specific examples and before/after comparison)
3. Agent increments version in `.claude-plugin/plugin.json` after fixes:
   - Patch (x.y.Z+1): Bug fixes
   - Minor (x.Y+1.0): New components
   - Major (X+1.0.0): Breaking changes
4. Wait for agent to complete

**Path Reference Rules**:
- Same directory: Use relative paths (`./reference.md`)
- Outside directory: Use `${CLAUDE_PLUGIN_ROOT}` paths
- Component templates: See `${CLAUDE_PLUGIN_ROOT}/examples/`

**Redundancy & Efficiency**:
- Redundancy: Allow strategic repetition of critical content (MUST/SHOULD requirements). Favor concise restatement.
- Efficiency: Agent detects if tasks need Agent Teams (Parallelizable > 5 files, Multi-domain).

## Phase 3: Verification & Deliverables

**Goal**: Verify fixes, generate report, and update documentation.

**Actions**:
1. Execute validation script: `python3 ${CLAUDE_PLUGIN_ROOT}/scripts/validate-plugin.py "$TARGET"`
2. Analyze results: compare with Phase 1 findings, confirm critical issues resolved
3. If critical issues remain, resume agent execution
4. Generate final validation report using template below
5. Update `README.md` to reflect current state (metadata, directory structure, usage instructions; do not append version history log)

## Validation Report Template

```markdown
## Plugin Validation Report

### Plugin: [name]
Location: [absolute-path]
Version: [old] -> [new]

### Summary
[2-3 sentences with key statistics]

### Phase 1: Issues Detected
#### Critical ([count])
- `file/path` - [Issue description]

#### Warnings ([count])
- `file/path` - [Issue description]

### Phase 2: Fixes Applied
#### Structure Fixes
- [Fix description]

#### Template Conformance
- **Agents**: [Count] validated, [count] fixed
- **Instruction-type Skills**: [Count] validated, [count] fixed
- **Knowledge-type Skills**: [Count] validated, [count] fixed

#### Redundancy Fixes
- [Consolidations applied]

### Phase 3: Verification Results
- Structure validation: [PASS/FAIL]
- Manifest validation: [PASS/FAIL]
- Component validation: [PASS/FAIL]
- Tool patterns validation: [PASS/FAIL]
- Token budgets validation: [PASS/FAIL]

### Token Budget Analysis
- Skills analyzed: [count]
- Tier 1 (Metadata ~50): [OK count], [WARNING count]
- Tier 2 (SKILL.md ~500): [OK count], [WARNING count], [CRITICAL count]
- Tier 3 (References 2000+ typical): [total tokens]

### Component Inventory
- Commands: [count] found, [count] valid
- Agents: [count] found, [count] valid
- Skills: [count] found, [count] valid

### Remaining Issues
[Issues that couldn't be auto-fixed with explanations]

### Overall Assessment
[PASS/FAIL] - [Detailed reasoning]
```