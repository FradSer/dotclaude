---
name: git-config
description: This skill should be used when analyzing project structure, generating git configuration, creating `.claude/git.local.md`, determining commit scopes, or setting up project-specific git settings.
version: 0.2.0
---

## Workflow

1. **Analyze project structure**: Identify top-level directories and their purposes
2. **Analyze git history**: Extract scopes from commit titles only (last 100 commits, or all if fewer), parse `type(scope): description` format
3. **Generate scopes** using appropriate strategy:
   - **From git history** (preferred): Use most frequent scopes, add missing important directories
     ```
     Git history shows: api (15), ui (12), auth (8), db (5)
     Generated scopes: api, ui, auth, db
     ```
   - **Directory-based**: Use top-level directory names to supplement git history, normalize to lowercase kebab-case
     ```
     Directories: src/api/, src/ui/, lib/auth/, config/
     Generated scopes: api, ui, auth, config
     ```
4. **Interactive confirmation**: Use AskUserQuestion with multiSelect to let user select scopes and add custom ones
   ```json
   {
     "questions": [{
       "question": "Review and confirm the generated scopes for conventional commits",
       "header": "Configure Git Scopes",
       "multiSelect": true,
       "options": [
         {"label": "api", "description": "API endpoints and routes"},
         {"label": "ui", "description": "User interface components"},
         {"label": "auth", "description": "Authentication and authorization"}
       ]
     }]
   }
   ```
5. **Generate config file**: Create `.claude/git.local.md` with confirmed scopes, standard types, and branch prefixes

## Configuration Format

```markdown
---
enabled: true
scopes:
  - api
  - ui
  - auth
  - db
types:
  - feat
  - fix
  - docs
  - refactor
  - test
  - chore
  - perf
  - style
  - build
  - ci
branch_prefixes:
  feature: feature/*
  fix: fix/*
  hotfix: hotfix/*
  refactor: refactor/*
  docs: docs/*
---
```

## Best Practices

- Review and adjust scopes to match project structure
- Keep 5-10 scopes optimal
- Use lowercase, kebab-case naming
- Update config manually if project structure changes significantly

## Reference

- `examples/git.local.md` - Configuration template
