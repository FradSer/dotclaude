# Issue Structure Requirements

## Title

- Maximum 70 characters
- Imperative mood, no emojis
- Optional prefix: `[Bug]`, `[Feature]`, `[Epic]`

## Labels

- Priority: `priority:high`, `priority:medium`, `priority:low`
- Type: `bug`, `feature`, `enhancement`, `documentation`

## Body Template

### Bug Report

```markdown
## Description
Clear description of the bug

## Steps to Reproduce
1. Go to '...'
2. Click on '...'
3. See error

## Expected Behavior
What should happen

## Environment
- OS:
- Version:
```

### Feature Request

```markdown
## Problem
What problem does this solve

## Proposed Solution
What you want to happen

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2
```

### Epic

```markdown
## Overview
High-level description and business value

## Child Issues
- #123 - Issue title
- #124 - Issue title

## Success Metrics
How to measure success
```

## Issue Forms (YAML)

When project uses YAML forms, detect and follow the schema:

```yaml
name: Bug Report
title: "[Bug]: "
labels: ["bug"]
body:
  - type: textarea
    id: description
    attributes:
      label: Description
    validations:
      required: true
```

## Auto-Closing Keywords

| Keyword | Example | Behavior |
|---------|---------|----------|
| Closes | `Closes #123` | PR merges → issue closes |
| Fixes | `Fixes #123` | PR merges → issue closes |
| Resolves | `Resolves #123` | PR merges → issue closes |

**Rules:**
- PR-scoped issues: use auto-close keywords
- Epic issues: do NOT use auto-close (use manual linking)

## Template Compliance

When project has issue templates:
1. List: `gh issue create --list`
2. Select appropriate template
3. Fill all required fields
4. Maintain template structure
