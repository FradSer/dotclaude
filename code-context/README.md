# Code Context Plugin

**Version:** 0.2.0

5 methods to retrieve code context: DeepWiki, Context7, Exa, git clone, and web search+fetch.

## Installation

```bash
claude plugin install code-context@frad-dotclaude
```

## Overview

Code Context provides 5 complementary methods for retrieving code context from different sources. It isolates external lookups in agent contexts to keep the main conversation clean, returning only synthesized summaries.

## Methods

### 1. DeepWiki (AI-powered repo documentation)

Best for: Public GitHub repositories requiring architecture overview, component explanations, or high-level understanding.

**MCP Tools:** `read_wiki_structure`, `read_wiki_contents`, `ask_question`

**Process:**
1. Call `read_wiki_structure` with owner/repo (e.g., `"facebook/react"`)
2. Call `read_wiki_contents` for relevant topics, or `ask_question` for targeted queries

**Strengths:** Zero setup, instant AI-summarized documentation.

**Limitations:** Only works for public GitHub repos; coverage varies by popularity.

---

### 2. Context7 (library documentation)

Best for: Getting up-to-date API docs, usage examples, and version-specific documentation for npm/pip packages.

**MCP Tools:** `resolve-library-id`, `query-docs`

**Process:**
1. Call `resolve-library-id` with library name (e.g., `"react"`, `"fastapi"`)
2. Call `query-docs` with `libraryId` and query

**Version pinning:** Encode version into library ID path: `/facebook/react/18.3.1`

**Strengths:** Always current docs, supports version pinning, covers thousands of libraries.

**Limitations:** Requires the library to be indexed; less useful for internal packages.

---

### 3. Exa Code Search (web-wide code examples)

Best for: Finding real-world usage patterns, StackOverflow answers, GitHub Gist examples.

**MCP Tool:** `get_code_context_exa`

**Setup:** Works without API key (free tier). Set `EXA_API_KEY` for higher limits.

**Query tips:**
- Include language: `"TypeScript React"`
- Include version: `"Next.js 14 app router"`
- Use exact identifiers: `"useServerAction"`
- Add pattern type: `"example"`, `"error handling"`

**Strengths:** Finds diverse real-world examples beyond official docs.

**Limitations:** Results may be outdated; verify publication dates.

---

### 4. Git Clone (direct code inspection)

Best for: Private repositories, detailed implementation review, or when other methods lack depth.

**Process:**
1. `git clone <repo-url> /tmp/<repo-name> --depth=1`
2. Read key files: entry points, configuration, core modules
3. Use Glob/Grep to analyze structure and patterns
4. Clean up: `rm -rf /tmp/<repo-name>`

**Strengths:** Full code access, works with private repos.

**Limitations:** Requires network/disk space; slow for large repos.

---

### 5. Web Search + Fetch (post-clone enrichment)

Best for: Enriching clone findings with changelogs, issue discussions, migration guides.

**Tools:** `WebSearch`, `WebFetch`

**When to use:** After completing Method 4. Gives you the *why* and *what changed*.

**Query patterns:**
- Changelogs: `"<repo> CHANGELOG v<version>"`
- Design rationale: `"<repo> <concept> why OR rationale site:github.com"`
- Migration: `"<repo> migrate from <old> to <new>"`

**Strengths:** Surfaces context never in source code.

**Limitations:** Results may be stale; always validate against actual code.

---

## Usage

### Command: /get-context

User-invoked command to retrieve code context.

```bash
# Get context for a library
/get-context react

# Get context for a repository
/get-context facebook/react

# Specify method
/get-context react --method=context7
/get-context facebook/react --method=deepwiki

# Auto-detect from local dependencies
/get-context
```

### Agent: @context-researcher

Spawns isolated lookup agent that executes the full workflow.

```bash
@context-researcher How does Zustand manage state under the hood?
```

The agent explores local context first, selects methods based on gaps, executes lookups, and returns a synthesized summary.

### Skill: code-context

Internal knowledge skill loaded by the context-researcher agent. Provides method selection guidance and query standards.

## Method Selection Guide

| Scenario | Primary | Fallback |
|----------|---------|----------|
| "How does X library work?" | Context7 | DeepWiki |
| "Understand Y repo architecture" | DeepWiki | Git Clone |
| "Find examples of Z pattern" | Exa | Context7 |
| "Inspect private/internal repo" | Git Clone | - |
| "What changed in v3?" | Context7 | Exa |
| "How are modules connected?" | DeepWiki | Git Clone |
| "Why was this design decision?" | Git Clone → Web Search | DeepWiki |

## Structure

```
code-context/
├── .claude-plugin/
│   └── plugin.json              # Manifest (skills: [./skills/code-context], commands: [./skills/get-context])
├── agents/
│   └── context-researcher.md    # Isolated research agent
├── skills/
│   ├── code-context/            # Knowledge skill (internal)
│   │   └── SKILL.md            # Method selection guide
│   └── get-context/             # User-invocable command
│       └── SKILL.md            # Command workflow
├── .mcp.json                    # MCP server configuration
└── README.md
```

## MCP Servers Required

The plugin uses these MCP servers (configured in `.mcp.json`):

- **deepwiki-code-context**: Repo documentation and architecture
- **context7-code-context**: Library documentation lookup
- **exa-code-context**: Web-wide code search

## Prerequisites

- Claude Code CLI
- MCP servers configured (see `.mcp.json`)
- Network access for external lookups

## Best Practices

- **Local first**: Always check local context (package.json, imports) before external lookups
- **Isolated execution**: External lookups run in agent context to keep main conversation clean
- **Combine methods**: For comprehensive context, use DeepWiki → Context7 → Exa → Clone
- **Verify sources**: Cross-reference fetched content against actual code

## License

MIT

## Author

Frad LEE (fradser@gmail.com)
