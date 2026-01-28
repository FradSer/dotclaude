---
title: Comprehensions
impact: MEDIUM
impactDescription: Pythonic and concise data manipulation
tags: comprehensions, readability
---

## Comprehensions

**Impact: MEDIUM (Pythonic and concise data manipulation)**

Use list/dict/set comprehensions for simple transformations.

### Reasoning
- **Pros**: Concise and readable for simple mapping/filtering operations. Faster than explicit for-loops in many cases.
- **Cons**: Can become incomprehensible if too complex (multiple loops, complex conditions).

### Guidelines
- **Limit**: Avoid comprehensions with multiple `for` clauses or multiple `if` conditions. Use a loop instead.
- **Lines**: If it doesn't fit on one line, it might be too complex (though breaking across lines is allowed for readability).

**Correct:**

```python
result = [x * 2 for x in data if x > 0]
```

**Incorrect (too complex):**

```python
result = [(x, y) for x in data if x > 0 for y in options if y != x]
```

Reference: [Google Python Style Guide - Comprehensions](https://google.github.io/styleguide/pyguide.html#27-comprehensions-expressions)
