---
title: Iterators and Generators
impact: MEDIUM
impactDescription: Improves memory efficiency and performance
tags: iterators, loops, generators
---

## Iterators and Generators

**Impact: MEDIUM (Improves memory efficiency and performance)**

Use iterators and generators (functions using `yield`) for processing large data streams without loading everything into memory.
Prefer generator expressions `(x for x in data)` over list comprehensions `[x for x in data]` when the result is only iterated once.

**Incorrect (loading all lines):**

```python
def get_lines(filename):
    lines = []
    with open(filename) as f:
        for line in f:
            lines.append(line)
    return lines
```

**Correct (streaming lines):**

```python
def get_lines(filename):
    with open(filename) as f:
        yield from f
```

Reference: [Google Python Style Guide - Iterators](https://google.github.io/styleguide/pyguide.html#28-iterators)
