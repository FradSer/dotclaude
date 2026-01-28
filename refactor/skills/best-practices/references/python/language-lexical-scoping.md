---
title: Lexical Scoping
impact: HIGH
impactDescription: Prevents variable leakage and closure bugs
tags: scoping, closures, loops
---

## Lexical Scoping

**Impact: HIGH (Prevents variable leakage and closure bugs)**

Python's scope is determined by functions, classes, and modules-not by blocks like `if` or `for`. Variables defined in a loop or `if` block leak into the surrounding function.

Be careful with closures referencing loop variables (late binding issues).

**Incorrect (leaking variable):**

```python
if condition:
    x = 5
print(x)  # Works in Python, but can be confusing
```

**Correct (explicit initialization):**

```python
x = 0
if condition:
    x = 5
print(x)
```

Reference: [Google Python Style Guide - Lexical Scoping](https://google.github.io/styleguide/pyguide.html#215-lexical-scoping)