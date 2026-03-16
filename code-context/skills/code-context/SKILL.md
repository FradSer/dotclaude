---
name: code-context
description: This skill should be used when the user asks to "understand a codebase", "get code context", "research a library", "explore a repository", "find code examples", "look up documentation", or wants to understand how a specific project or library works before making changes.
user-invocable: false
---

# Code Context Retrieval

This skill provides 4 methods for retrieving code context. Select methods based on the target: public GitHub repos, library docs, code search, or direct inspection.

## Token Isolation (Critical)

Never run any external lookup in the main context. Always spawn Task agents:

- **DeepWiki**: Agent calls `read_wiki_structure` / `read_wiki_contents` / `ask_question`, extracts architecture summary and key relationships, returns concise overview.
- **Context7**: Agent calls `resolve-library-id` then `query-docs`, extracts the minimum viable API surface and usage examples, returns copyable snippets with version notes.
- **Exa**: Agent calls `get_code_context_exa`, extracts minimum viable snippets, deduplicates near-identical results (mirrors, forks, repeated StackOverflow answers), returns copyable snippets + brief explanation.
- **Git clone**: Agent clones to `/tmp/`, reads entry points and core modules, runs `rm -rf` cleanup, returns file structure summary and key patterns.

Main context stays clean regardless of search volume. Only final summaries return to the caller.

## Method 1: DeepWiki (AI-powered repo documentation)

Best for: Well-known public GitHub repositories where you need architecture overview, component explanations, or high-level understanding fast.

**Tools**: `read_wiki_structure`, `read_wiki_contents`, `ask_question`

**Process**:
1. Call `read_wiki_structure` with the owner/repo (e.g., `"facebook/react"`) to get topic list
2. Call `read_wiki_contents` for relevant topics, or `ask_question` for targeted queries
3. Use when you need: architecture diagrams, component relationships, design decisions

**Strengths**: Zero setup, instant AI-summarized documentation, good for onboarding to unfamiliar repos.

**Limitations**: Only works for public GitHub repos; coverage varies by project popularity.

## Method 2: Context7 (library documentation)

Best for: Getting up-to-date API docs, usage examples, and version-specific documentation for npm/pip packages and frameworks.

**Tools**: `resolve-library-id`, `query-docs`

**Process**:
1. Call `resolve-library-id` with the library name (e.g., `"react"`, `"fastapi"`) to get the canonical ID
2. When the user specifies a version (e.g., `"react@18"`), select the matching version from the `versions` list returned by `resolve-library-id` and append it to the library ID path (e.g., `/facebook/react/18.3.1`)
3. Call `query-docs` with `libraryId` and `query` — these are the only two parameters

**Query tips**: Be specific -- `"useCallback dependency array"` beats `"react hooks"`. Include the framework version when known.

**Version pinning**: Encode version into the library ID path (e.g., `/vercel/next.js/v14.3.0-canary.87`), not as a separate parameter. Use the `versions` list from `resolve-library-id` to pick the correct slug.

**Strengths**: Always current docs, supports version pinning, covers thousands of libraries, excellent for API reference.

**Limitations**: Requires the library to be indexed; less useful for internal/private packages.

## Method 3: Exa Code Search (web-wide code examples)

Best for: Finding real-world usage patterns, StackOverflow-style answers, GitHub Gist examples, and code snippets from across the web.

**Tool**: `get_code_context_exa`

**Setup**: Works without an API key (free tier with rate limits). For higher limits, set the `EXA_API_KEY` environment variable.

**Process**:
1. Call `get_code_context_exa` with a precise query
2. Set `tokensNum` based on need: 3000 for quick examples, 8000 for comprehensive patterns
3. Verify publication dates on results; prefer recent sources

**Query writing guidance**:
- Include the language or framework: `"TypeScript React"` not just `"React"`
- Include the version when relevant: `"Next.js 14 app router"`
- Use exact identifiers: `"useServerAction"` not `"server action hook"`
- Add the pattern type: `"example"`, `"error handling"`, `"migration guide"`
- Example: `"TypeScript Next.js 14 app router server action error handling example"`

**Strengths**: Finds diverse real-world examples, not limited to official docs, surfaces community solutions.

**Limitations**: Results may be outdated; always check publication dates and verify against official docs.

## Method 4: Git Clone (direct code inspection)

Best for: Private repositories, detailed implementation review, running local analysis, or when other methods lack depth.

**Process**:
1. Run `git clone <repo-url> /tmp/<repo-name> --depth=1` to fetch the code
2. Read key files: entry points, configuration, core modules
3. Use Glob to map structure; use Grep to search patterns
4. Clean up when done: `rm -rf /tmp/<repo-name>`

**Strengths**: Full code access, works with private repos (with credentials), enables static analysis tools.

**Limitations**: Requires network access and disk space; slow for large repos; credentials needed for private repos.

## Method Selection Guide

| Scenario | Primary Method | Fallback |
|----------|---------------|----------|
| "How does X library work?" | Context7 | DeepWiki |
| "Understand the architecture of Y repo" | DeepWiki | Git Clone |
| "Find examples of Z pattern" | Exa | Context7 |
| "Inspect private/internal repo" | Git Clone | - |
| "What changed in v3 of library?" | Context7 | Exa |
| "How are modules connected?" | DeepWiki | Git Clone |

## Combining Methods

For comprehensive context, combine methods:
1. DeepWiki for architecture overview
2. Context7 for specific API details
3. Exa for community usage patterns
4. Git Clone for implementation details when needed

Always prefer non-destructive read-only operations. When cloning, use `/tmp` and clean up after.
