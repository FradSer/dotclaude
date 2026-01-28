---
title: Properties
impact: MEDIUM
impactDescription: Encapsulation ensuring cheap access
tags: properties, performance, api-design
---

## Properties

**Impact: MEDIUM (Encapsulation ensuring cheap access)**

Use `@property` for data descriptors.
**Critical**: Property access must be cheap (computationally). Users expect `obj.x` to be fast. If it performs I/O or heavy calculation, use a method `obj.calculate_x()` instead.

**Incorrect (expensive property):**

```python
class Database:
    @property
    def connection(self):
        # Connects to DB! Slow!
        return connect_db()
```

**Correct (method for expensive op):**

```python
class Database:
    def connect(self):
        return connect_db()
```

Reference: [Google Python Style Guide - Properties](https://google.github.io/styleguide/pyguide.html#213-properties)