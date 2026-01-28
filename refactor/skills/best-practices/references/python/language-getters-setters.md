---
title: Accessors
impact: MEDIUM
impactDescription: keeps code Pythonic and simple
tags: classes, getters, setters, properties
---

## Accessors

**Impact: MEDIUM (Keeps code Pythonic and simple)**

- **Public Attributes**: Use direct access for public data members.
- **Properties**: Use `@property` for lightweight computed attributes or if you need to enforce logic on access.
- **Getters/Setters**: Avoid Java-style `get_foo()`/`set_foo()` methods. They add noise.

**Incorrect:**

```python
class Student:
    def get_score(self):
        return self._score
    
    def set_score(self, score):
        self._score = score
```

**Correct:**

```python
class Student:
    def __init__(self, score):
        self.score = score  # Public attribute
```

**Correct (with validation):**

```python
class Student:
    @property
    def score(self):
        return self._score
    
    @score.setter
    def score(self, value):
        if value < 0:
            raise ValueError
        self._score = value
```

Reference: [Google Python Style Guide - Properties](https://google.github.io/styleguide/pyguide.html#213-properties)