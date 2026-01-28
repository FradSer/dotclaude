---
title: True/False Evaluations
impact: MEDIUM
impactDescription: Reduces verbosity using Python's truthiness
tags: boolean, truthiness, conditionals
---

## True/False Evaluations

**Impact: MEDIUM (Reduces verbosity using Python's truthiness)**

Use the "implicit" false in boolean contexts.
- Empty sequences (list, strings, etc) are false.
- 0 is false.
- None is false.

Exception: When testing for `None` specifically (e.g. optional arguments), use `if x is None`.

**Correct:**

```python
if not users:
    print('no users')

if i % 10 == 0:
    print('modulo 10')
```

**Incorrect:**

```python
if len(users) == 0:
    print('no users')

if not i % 10:  # Confusing for integers, prefer == 0
    ...
```

Reference: [Google Python Style Guide - True/False Evaluations](https://google.github.io/styleguide/pyguide.html#214-truefalse-evaluations)