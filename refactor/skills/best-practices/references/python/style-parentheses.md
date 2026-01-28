---
title: Parentheses
impact: LOW
impactDescription: Readability
tags: formatting, style
---

## Parentheses

**Impact: LOW (Readability)**

Use parentheses sparingly.
- **Required**: Tuples (sometimes), calls, grouping expressions.
- **Optional**: Avoid them in `if`, `while`, `return` unless needed for order of operations or line continuation.

**Correct:**

```python
if x > 5:
    return x
```

**Incorrect (redundant):**

```python
if (x > 5):
    return (x)
```

Reference: [Google Python Style Guide - Parentheses](https://google.github.io/styleguide/pyguide.html#23-parentheses)
