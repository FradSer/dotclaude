---
title: Linting
impact: HIGH
impactDescription: Catches errors early and enforces standards
tags: linting, best-practices, tools
---

## Linting

**Impact: HIGH (Catches bugs early and enforces style)**

Run a linter (like Pylint or Flake8) on your code.

### Reasoning
- **Consistency**: Linters catch trivial style issues, letting humans focus on architecture during code review.
- **Bugs**: Linters often catch real bugs like undefined variables or unused imports.

### Guidelines
- **Suppressions**: If a lint warning is a false positive, suppress it locally.
- **Scope**: Suppress the warning on the specific line or block involved, not the whole file.
- **Comments**: Always add a comment explaining *why* the suppression is needed immediately after the suppression.

**Correct:**

```python
# pylint: disable=invalid-name
x = 5  # x is a valid name here despite standard rules
```

**Incorrect (suppressing everything):**

```python
# pylint: disable=all
```

Reference: [Google Python Style Guide - Lint](https://google.github.io/styleguide/pyguide.html#21-lint)