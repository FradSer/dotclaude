---
title: Default Arguments
impact: CRITICAL
impactDescription: Prevents shared state bugs
tags: functions, arguments, mutability
---

## Default Arguments

**Impact: CRITICAL (Prevents shared state bugs)**

Do not use mutable objects as default values in function definitions.

### Reasoning
- **Module Load Time**: Default argument values are evaluated *once* when the module is loaded, not every time the function is called.
- **Shared State**: If you use a mutable default (like `[]` or `{}`), that same object is shared across *all* calls to the function. Modifying it in one call affects future calls.

### Guidelines
- **Immutables**: Use `None`, `0`, `""`, `()`, or named tuples as defaults.
- **Pattern**: If you need a mutable default, use `None` in the signature and initialize inside the function.

**Incorrect:**

```python
def append_to(value, target=[]):
    target.append(value)
    return target
```

**Correct:**

```python
def append_to(value, target=None):
    if target is None:
        target = []
    target.append(value)
    return target
```

Reference: [Google Python Style Guide - Default Arguments](https://google.github.io/styleguide/pyguide.html#212-default-argument-values)
