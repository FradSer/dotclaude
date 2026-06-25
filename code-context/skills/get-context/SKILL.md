---
name: get-context
description: Execute this when the user requests code context for a repository, library, or any natural-language code/technology question using DeepWiki, Context7, Exa, git clone, and/or web search+fetch.
user-invocable: true
argument-hint: "<query | repo-slug | library-name> [more targets...] [--method=deepwiki,context7,exa,clone,web,all]"
allowed-tools: ["Task"]
---

# get-context

Launch a `code-context:context-researcher` agent that executes the full workflow in an isolated context. The input is **arbitrary**: a natural-language question, a repo slug, a library name, or several of these at once.

## Argument parsing

1. **Split `$ARGUMENTS`** into positional targets and the optional `--method` flag.
   - `--method=` accepts a comma-separated list from `deepwiki,context7,exa,clone,web,all`. Default: `all`.
   - Quoted strings are one target: `"对比 zustand vs jotai 状态管理"` is a single natural-language query.
   - Multiple positional tokens are multiple targets: `facebook/react zustand` = two targets.
2. **Classify each target**:
   - GitHub slug (`owner/repo`) or git URL → repo target (DeepWiki / clone).
   - Bare name matching a known package ecosystem (`react`, `fastapi`, `next`) or with a version hint (`react@18`) → library target (Context7).
   - Anything else (a question, a comparison, a concept) → natural-language target (Exa / web search).
3. **Empty input**: read dependency manifests in the current working directory (`package.json`, `go.mod`, `pyproject.toml`, `Cargo.toml`) and use detected dependencies as targets.

## Prompt template

Pass the parsed targets and method list to the agent verbatim — do not pre-resolve them in the main context.

```
Code context request.

Targets (classify each as repo / library / natural-language query):
<positional targets, one per line; or "auto-detect from local dependency manifests" if empty>

Methods to use (in priority order; "all" = let agent choose per target):
<comma-separated method list, default "all">

Local context already known: <one line on what the cwd already contains, or "none">
```

## Execute

Launch `code-context:context-researcher` using the prompt template above. The agent returns a synthesized summary; the main context stays clean regardless of lookup volume.
