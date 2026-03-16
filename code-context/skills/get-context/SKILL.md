---
name: get-context
description: Execute this when the user requests code context for a repository or library using DeepWiki, Context7, Exa, and/or git clone.
user-invocable: true
argument-hint: [repo-url-or-library-name] [--method=deepwiki|context7|exa|clone|all]
allowed-tools: ["Task"]
---

# get-context

**Launch a `code-context:context-researcher` agent** that executes the full workflow in an isolated context.

**Prompt template**:

```
Execute the code context workflow for: $ARGUMENTS

If the target is empty, read dependency manifests in the current working directory (package.json, go.mod, pyproject.toml, Cargo.toml, etc.) and use detected dependencies as targets.

If a target is provided, parse the optional `--method` flag (default: `all`) and normalize GitHub shorthand (`owner/repo`) to a full slug.
```

**Execute**: Launch `code-context:context-researcher` agent using the prompt template above.
