---
title: Whitespace
impact: LOW
impactDescription: Readability
tags: whitespace, formatting
---

## Whitespace

**Impact: LOW (Readability)**

Follow PEP 8 whitespace rules.

### Guidelines
- **Parentheses**: No whitespace inside parentheses, brackets, or braces.
- **Punctuation**: No whitespace before commas, semicolons, or colons.
- **Operators**: Surround binary operators with a single space (`=`, `==`, `!=`, `<`, `>`, `and`, `or`).
- **Default Arguments**:
    - **No spaces** around `=` for default values **without** type annotations: `def foo(a=1):`.
    - **Spaces**  around `=` for default values **with** type annotations: `def foo(a: int = 1):`.
- **Alignment**: Do **not** use spaces to vertically align tokens (e.g., aligning `=` signs). It creates a maintenance burden.

**Correct (Defaults):**
```python
def foo(a, b=0): ...
def bar(a: int, b: int = 0): ...
```

**Incorrect (Alignment):**
```python
x       = 1
long_var = 2
```

Reference: [Google Python Style Guide - Whitespace](https://google.github.io/styleguide/pyguide.html#311-whitespace)
