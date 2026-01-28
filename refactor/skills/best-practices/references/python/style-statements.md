---
title: Statements
impact: LOW
impactDescription: Readability
tags: formatting, statements
---

## Statements

**Impact: LOW (Readability)**

Usually one statement per line.
exception: Simple short `if` bodies can be on same line, but never if it contains `try/except`.

**Correct:**

```python
if foo: bar(foo)  # Acceptable for simple statements

if foo:
    bar(foo)  # Preferred
```

**Incorrect:**

```python
if foo: bar(foo); baz(foo)  # Multiple statements

try: something()
except: handle()  # Never use one-line try/except
```

Reference: [Google Python Style Guide - Statements](https://google.github.io/styleguide/pyguide.html#217-statements)
