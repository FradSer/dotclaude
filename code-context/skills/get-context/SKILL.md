---
name: get-context
description: Execute this when the user requests code context for a repository or library using DeepWiki, Context7, Exa, and/or git clone.
user-invocable: true
argument-hint: <repo-url-or-library-name> [--method=deepwiki|context7|exa|clone|all]
allowed-tools: ["Bash(git clone:*)", "mcp__plugin_context7_context7__resolve-library-id", "mcp__plugin_context7_context7__query-docs", "mcp__plugin_exa-mcp-server_exa__get_code_context_exa"]
---

# get-context

Fetch code context for $ARGUMENTS using up to 4 methods.

## Phase 0: Explore Local Context

**Goal**: Gather existing local knowledge before reaching out to external sources.

**Actions**:
1. Search the current working directory for files related to the target (package.json, go.mod, pyproject.toml, Cargo.toml, import statements, config files).
2. Grep for existing usages or references to the target library/repo in source files.
3. Read any local docs, README, or CHANGELOG that mention the target.
4. Note current version in use and any existing patterns — this sharpens external queries and avoids redundant lookups.

Skip external methods entirely if local context is already sufficient.

## Phase 1: Parse Input

**Goal**: Determine the target and which methods to execute.

**Actions**:
1. Parse `$ARGUMENTS` to extract the target (GitHub URL, library name, or git URL) and the optional `--method` flag.
2. Default the method to `all` when no `--method` flag is provided.
3. Normalize GitHub shorthand (`owner/repo`) to a full slug for downstream calls.

## Phase 2: Execute Selected Methods

**Goal**: Retrieve code context via each requested method.

**Actions**:

**deepwiki** (GitHub repos only):
1. Call `read_wiki_structure` with the owner/repo slug.
2. Call `read_wiki_contents` for the 2-3 most relevant topics.
3. Collect: architecture overview, component relationships, design decisions.

**context7** (libraries and frameworks):
1. Call `resolve-library-id` with the library name.
2. Call `query-docs` with the resolved ID and a relevant topic.
3. Collect: API overview, usage patterns, code examples.

**exa** (web-wide code search):
1. Formulate a precise query: include language, framework version, and exact identifiers.
2. Call `get_code_context_exa` with the query.
3. Collect: real-world usage examples, community patterns.

**clone** (direct inspection):
1. Run `git clone <url> /tmp/<repo-name> --depth=1`.
2. Read entry points, config files, and core modules.
3. Run `rm -rf /tmp/<repo-name>` after inspection.
4. Collect: implementation details, file structure, key patterns.

## Phase 3: Present Results

**Goal**: Deliver findings in a clear, structured format.

**Actions**:
1. When multiple methods are used, output results in a section per method.
2. When only one method is specified, output results directly without section headers.
