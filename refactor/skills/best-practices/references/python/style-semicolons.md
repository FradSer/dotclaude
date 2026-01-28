---
title: Semicolons
impact: LOW
impactDescription: Pythonic style
tags: semicolons, formatting
---

## Semicolons

**Impact: LOW (Pythonic style)**

Do not use semicolons to terminate lines. Do not use semicolons to put two statements on the same line.

**Incorrect:**

```python
x = 5; print(x)
```

**Correct:**

```python
x = 5
print(x)
```

Reference: [Google Python Style Guide - Semicolons](https://google.github.io/styleguide/pyguide.html#21-semicolons)