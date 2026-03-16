---
description: Retrieve code context using DeepWiki, Context7, Exa, and/or git clone
argument-hint: <repo-url-or-library-name> [--method=deepwiki|context7|exa|clone|all]
---

# /code-context:get-context

Fetches code context for a repository or library using up to 4 methods.

## Usage

```
/code-context:get-context <target> [--method=deepwiki|context7|exa|clone|all]
```

- **target**: GitHub URL (`github.com/owner/repo`), library name (`react`), or git URL
- **method**: Which methods to use (default: `all`)

## Examples

```
/code-context:get-context facebook/react
/code-context:get-context next.js --method=context7
/code-context:get-context https://github.com/owner/repo --method=clone
/code-context:get-context fastapi --method=deepwiki,exa
```

## How It Works

Parse the target and method flag, then execute each selected method:

**deepwiki** (GitHub repos only):
1. Call `read_wiki_structure` with the owner/repo slug
2. Call `read_wiki_contents` for the 2-3 most relevant topics
3. Output: architecture overview, component relationships, design decisions

**context7** (libraries and frameworks):
1. Call `resolve-library-id` with the library name
2. Call `query-docs` with the resolved ID and a relevant topic
3. Output: API overview, usage patterns, code examples

**exa** (web-wide code search):
1. Formulate a precise query from the target name
2. Call `get_code_context_exa` with the query
3. Output: real-world usage examples, community patterns

**clone** (direct inspection):
1. Run `git clone <url> /tmp/<repo-name> --depth=1`
2. Read entry points, config files, and core modules
3. Run `rm -rf /tmp/<repo-name>` after inspection
4. Output: implementation details, file structure, key patterns

Present results in sections per method used. If only one method is specified, output directly without section headers.
