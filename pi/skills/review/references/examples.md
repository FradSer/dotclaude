# Usage Examples

Concrete invocations for `/pi:review`. Read this when a user needs an example
of a specific flag or target. The authoritative flag semantics are in SKILL.md.

### Review uncommitted working tree changes (default)

```
/pi:review
```

Reviews `git diff HEAD` — all staged and unstaged changes vs the last commit. If the working tree is clean, reports so and stops.

### Review with a specific endpoint

```
/pi:review --endpoint openrouter
```

### Review with a specific model

```
/pi:review --model gemini-3.6-pro
```

### Review a specific branch

```
/pi:review --branch feat/new-widget --endpoint local-proxy --model gemini-3.6-flash-high
```

### Review recent changes

```
/pi:review --diff HEAD~5..HEAD
```

### Review a pull request

```
/pi:review 42
```

### Review a specific file

```
/pi:review @src/core/agent.ts
```

### Let pi freely explore the codebase (default review, expanded tools)

```
/pi:review --explore
```

Overrides the default `read`-only restriction to `read,grep,find,ls` for the working-tree review. pi still cannot edit files or run bash.

### List configured endpoints

```
/pi:review --list-models
```

### Edit project settings

```
/pi:review --edit-config
```
