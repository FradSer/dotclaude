---
name: git-config
description: This skill should be used when analyzing project structure, generating git configuration, creating `.claude/git.local.md`, determining commit scopes, or setting up project-specific git settings.
version: 0.1.0
---

## Overview

This skill provides expertise in analyzing project structure and generating appropriate git configuration for conventional commits. It automatically determines project scopes based on directory structure, git history, and technology stack.

## Capabilities

- Analyzes project structure (all directories)
- Examines git history for existing scopes
- Determines project size (small vs large)
- Generates scopes using appropriate strategy
- Creates `.claude/git.local.md` configuration file
- Interactive confirmation via AskUserQuestion

## Workflow

### Step 1: Analyze Project Structure
1. Analyze all directories in the project root
2. Identify top-level directories and their purposes
3. Count total files and directories to determine project size

### Step 2: Analyze Git History
1. Extract commit messages from git history (last 100 commits, or all if fewer)
2. Parse conventional commit format: `type(scope): description`
3. Extract all unique scopes from commit history
4. Count frequency of each scope

### Step 3: Determine Project Size
- **Small project**: < 50 files or < 10 top-level directories
- **Large project**: ≥ 50 files or ≥ 10 top-level directories

### Step 4: Generate Scopes

**Strategy 1: From Git History (Preferred)**
If scopes are found in commit history:
- Use most frequently used scopes
- Add any missing important directories/modules
- Preserve existing conventions

**Example:**
```
Git history shows: api (15), ui (12), auth (8), db (5)
Generated scopes: api, ui, auth, db
```

**Strategy 2: Directory-Based (Small Projects)**
For small projects without git history:
- Analyze top-level directories
- Use directory names as scopes
- Normalize: lowercase, kebab-case, remove special characters

**Example:**
```
Directories: src/api/, src/ui/, lib/auth/, config/
Generated scopes: api, ui, auth, config
```

**Strategy 3: Technology Module-Based (Large Projects)**
For large projects without git history:
- Identify technology stack (package.json, requirements.txt, Cargo.toml, etc.)
- Identify major functional areas
- Use module/domain names as scopes

**Example:**
```
Technology: Node.js, React, PostgreSQL
Functional areas: authentication, payment, inventory, reporting
Generated scopes: auth, payment, inventory, reporting, api, db
```

### Step 5: Interactive Confirmation
1. Use AskUserQuestion to present generated scopes:
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
2. Allow user to:
   - Select which scopes to keep
   - Add custom scopes if needed
3. Parse user selection to get final scope list

### Step 6: Generate Configuration File
1. Create `.claude/git.local.md` with:
   - `enabled: true`
   - `scopes:` list from user confirmation
   - `types:` standard types (feat, fix, docs, refactor, test, chore, perf, style, build, ci)
   - `branch_prefixes:` standard prefixes (feature, fix, hotfix, refactor, docs)
2. Use Write tool to create the file
3. Inform user that configuration has been created

## Configuration File Format

The generated `.claude/git.local.md` follows this structure:

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

1. **Review generated scopes**: Always review and adjust scopes to match your project structure
2. **Keep scopes focused**: 5-10 scopes is usually optimal
3. **Use consistent naming**: Lowercase, kebab-case, descriptive
4. **Update as needed**: Manually edit `.claude/git.local.md` if project structure changes significantly

## Additional Resources

- **`examples/git.local.md`** - Configuration file template
