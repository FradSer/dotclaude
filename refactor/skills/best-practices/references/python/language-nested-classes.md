---
title: Nested Classes
impact: LOW
impactDescription: Encapsulation
tags: classes, nesting, internal
---

## Nested Classes

**Impact: LOW (Encapsulation)**

Nested classes are fine when the class is an implementation detail of the outer class.
Use them to group related functionality that shouldn't be exposed globally.

**Correct:**

```python
class Outer:
    class _Inner:  # Private inner class
        pass
```

Reference: [Google Python Style Guide - Nested Classes](https://google.github.io/styleguide/pyguide.html#26-nested-classes)