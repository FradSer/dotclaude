---
title: Conditionals
impact: LOW
impactDescription: Readability
tags: conditionals, boolean, truthiness
---

## Conditionals

**Impact: LOW (Readability)**

### Guidelines
- **Truthiness**: Use implicit `if x:` for empty lists, strings, etc. (See [True/False Evaluations](language-true-false.md)).
- **None**: Always compare `None` with `is` or `is not`.
- **Ternary**: Use `x = a if cond else b` for simple cases. Avoid nested ternaries.

### Reasoning
- **Readability**: Explicit comparisons (`if len(x) > 0`) are verbose. Pythonic convention relies on truthiness.
- **Safety**: `if x:` handles `None` safely (evaluates to False), whereas `len(x)` would crash if `x` is `None`.

**Correct:**

```python
if not users:
    print('no users')

if user is None:
    print('Not logged in')
```

**Incorrect:**

```python
if len(users) == 0:
    print('no users')

if not user: # Ambiguous if user implies "logged in user object"
    ...
```

Reference: [Google Python Style Guide - Conditional Expressions](https://google.github.io/styleguide/pyguide.html#211-conditional-expressions)
