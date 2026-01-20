---
name: init-config
description: Generate CLAUDE.md with AI-driven environment detection and advanced configuration options
argument-hint: []
allowed-tools: ["Read", "Write", "AskUserQuestion", "WebSearch", "Bash(which:*)", "Bash(test:*)", "Bash(mkdir:*)", "Bash(cp:*)", "Bash(wc:*)", "Bash(grep:*)", "Bash(chmod:*)", "Bash(echo:*)", "Bash(node:*)", "Bash(npm:*)", "Bash(pnpm:*)", "Bash(python:*)", "Bash(python3:*)", "Bash(pip:*)", "Bash(uv:*)", "Bash(cargo:*)", "Bash(go:*)", "Bash(java:*)", "Bash(docker:*)", "Bash(git:*)"]
---

You are an expert DevOps engineer tasked with generating personalized configuration files for AI development assistants.

## Phase 1: Environment Discovery
Your first goal is to understand the user's preferred technology stack without asking basic questions.

1. **Investigate the Environment**
   - Use the **Bash** tool to detect installed languages and tools.
   - **Do NOT** just check for Node/Python. Look for a wide range: Rust (cargo), Go, Java, Docker, etc.
   - *Tip*: Checking versions (e.g., `python3 --version`, `cargo --version`) is a good way to verify existence.

2. **Formulate Recommendations**
   - Based on your findings, decide which "Technology Stack" configurations should be included.
   - If you find `pnpm`, recommend Node.js+pnpm.
   - If you find `cargo`, recommend Rust best practices.

## Phase 2: TDD Preference
1. **Ask TDD Preference**
   - Use the **AskUserQuestion** tool to ask if TDD should be included.
   - **Header**: "TDD Mode"
   - **Question**: "Should the configuration include Test-Driven Development (TDD) requirements?"
   - **Options**:
     - `{"label": "Include TDD (Recommended)", "description": "Add mandatory TDD workflow: RED → GREEN → REFACTOR"}`
     - `{"label": "Exclude TDD", "description": "Generate configuration without TDD requirements"}`

2. **Select Template**
   - If "Include TDD": Use `${CLAUDE_PLUGIN_ROOT}/assets/claude-template.md`
   - If "Exclude TDD": Use `${CLAUDE_PLUGIN_ROOT}/assets/claude-template-no-tdd.md`

## Phase 3: Technology Stack Selection
1. **Present Options**
   - Use the **AskUserQuestion** tool with `multiSelect: true`.
   - **Header**: "Tech Stack"
   - **Question**: "Which technology stacks should be included in your configuration?"
   - **Options**: Dynamically generate options based on your Phase 1 discovery.
     - Example: If you found Go, create: `{"label": "Golang", "description": "Add Go best practices (Recommended)"}`
     - Always mark discovered tools as "Recommended".
     - Add a "Generic/Base Only" option for a clean setup.

## Phase 4: Best Practices Research
1. **Ask About Web Search**
   - Use the **AskUserQuestion** tool.
   - **Header**: "Research"
   - **Question**: "Search for latest best practices for selected technologies?"
   - **Options**:
     - `{"label": "Search and append (Recommended)", "description": "Find 2026 best practices and add brief summaries"}`
     - `{"label": "Skip search", "description": "Use only base template"}`

2. **Execute Web Searches** (if user selected "Search and append"):
   - For each selected technology stack:
     - Use **WebSearch** tool with query: `"[Technology] development best practices 2026"`
     - Extract 2-3 key sentences from search results
     - Store these summaries to append after each tech stack section

## Phase 5: Assembly & Generation
1. **Read Base Template**
   - Use the **Read** tool to read the selected template (from Phase 2).

2. **Generate Tech Stack Sections**
   - For each selected tech stack:
     - Synthesize a high-quality configuration section on-the-fly
     - Focus on: Package management, Documentation standards, Code quality guidelines
     - **If web search was enabled**: Append the 2-3 sentence summary under the tech stack section with a header `### Latest Best Practices (2026)`

3. **Assemble Final Content**
   - Start with base template content
   - Add `## Technology Stack` header
   - Append all generated tech stack sections
   - Include search summaries if web search was enabled

## Phase 6: Length Validation
1. **Validate Length**
   - Write the assembled content to a temporary location
   - Use **Bash** to run: `${CLAUDE_PLUGIN_ROOT}/scripts/validate-length.sh [temp-file-path]`
   - Capture the exit code and output

2. **Handle Validation Results**
   - **Exit code 0** (ACCEPTABLE or OPTIMAL): Proceed to Phase 7
   - **Exit code 3 or 4** (TOO_LONG or EXCESSIVE):
     - Use **AskUserQuestion** tool:
       - **Header**: "Length"
       - **Question**: "The configuration exceeds best practice length. How should I proceed?"
       - **Options**:
         - `{"label": "Auto-trim recommended", "description": "Remove less critical sections automatically"}`
         - `{"label": "Keep as-is", "description": "Proceed with current length"}`
         - `{"label": "Manual review", "description": "Show sections and let me choose what to remove"}`
     - If "Auto-trim": Remove web search summaries first, then trim example sections
     - If "Manual review": Present section list and wait for user selection
   - **Exit code 2** (TOO_SHORT): Show info message but proceed

## Phase 7: Multi-file Sync
1. **Ask About Sync**
   - Use the **AskUserQuestion** tool with `multiSelect: true`.
   - **Header**: "Sync"
   - **Question**: "Which additional AI configuration files should be synchronized?"
   - **Options**:
     - `{"label": "GEMINI.md", "description": "Sync to Google Gemini configuration"}`
     - `{"label": "AGENTS.md", "description": "Sync to general agents configuration"}`
     - `{"label": "None", "description": "Only generate CLAUDE.md"}`

2. **Process Each Selected File**
   - For each selected file (GEMINI.md / AGENTS.md):
     - Check if `$HOME/.claude/[FILENAME]` exists using **Bash** (`test -f`)
     - **If exists**:
       - Backup: `cp $HOME/.claude/[FILENAME] $HOME/.claude/[FILENAME].bak`
       - **Read** the existing file content
       - **Merge**: Template-priority strategy:
         - Use assembled CLAUDE.md content as base
         - Parse existing file for unique sections (sections with headers not in CLAUDE.md)
         - Append unique sections to the end
       - **Write** merged content to `$HOME/.claude/[FILENAME]`
     - **If not exists**:
       - **Write** CLAUDE.md content directly to `$HOME/.claude/[FILENAME]`

## Phase 8: Write CLAUDE.md
1. **Final Write**
   - Check if `$HOME/.claude/CLAUDE.md` exists using **Bash** (`test -f`)
   - If exists: Backup using **Bash** (`cp $HOME/.claude/CLAUDE.md $HOME/.claude/CLAUDE.md.bak`)
   - Ensure directory exists: **Bash** (`mkdir -p $HOME/.claude`)
   - Use **Write** tool to write assembled content to `$HOME/.claude/CLAUDE.md`

2. **Report Success**
   - List what was included:
     - TDD mode: Included/Excluded
     - Technology stacks: List each one
     - Web search: Enabled/Disabled
     - Word count and validation status
     - Synced files: GEMINI.md, AGENTS.md, or none
   - Show file locations and backup locations if applicable

## Best Practices
- **Progressive workflow**: Each phase builds on previous results
- **User control**: Always ask before making significant decisions
- **Validation**: Check length before writing to ensure quality
- **Safety**: Always backup existing files before overwriting
- **Template-priority merge**: Maintain consistency across AI configs while preserving unique user content
