---
title: Line Length
impact: MEDIUM
impactDescription: Readability
tags: formatting, line-length
---

## Line Length

**Impact: MEDIUM (Readability)**

Maximum line length is **80 characters**.

### Exceptions
- **Long Imports**: Module path imports can exceed 80 characters.
- **URLs**: Comments containing long URLs.
- **Strings**: Long string literals that cannot be broken (like in modules that don't allow implicit concatenation).

### Guidelines
- **Breaking**: Use parentheses `()` for implicit line joining. This is preferred over backslashes `\`.
- **Operators**: Break *before* binary operators (mathematical style), not after.

**Correct:**

```python
if (width == 0 and height == 0 and
    color == 'red' and emphasis == 'strong'):
```

**Incorrect:**

```python
if (width == 0 and height == 0 and
    color == 'red' and emphasis == 'strong'):  # > 80 chars
```

Reference: [Google Python Style Guide - Line Length](https://google.github.io/styleguide/pyguide.html#32-line-length)