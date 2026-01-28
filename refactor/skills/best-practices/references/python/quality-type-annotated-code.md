---
title: Type Annotated Code
impact: HIGH
impactDescription: Enables static analysis and improves documentation
tags: typing, annotations, safety
---

## Type Annotated Code

**Impact: HIGH (Enables static analysis and improves documentation)**

You are strongly encouraged to annotate all new code with type verification in mind.

### Guidelines
- **Public APIs**: Public functions and methods should be fully annotated. This serves as machine-checked documentation.
- **Inference**: Use explicit annotations when type inference is insufficient or for clarity.
- **Legacy Code**: When modifying legacy code, be pragmatic. Annotating is good, but don't feel forced to annotate the entire file if you are only touching one function.

### Reasoning
- **Safety**: Captures bugs (like `None` handling errors) at build time rather than runtime.
- **Clarity**: Reads better than docstrings for input/output types.

**Incorrect:**

```python
def process_items(items):
    return [i.name for i in items]
```

**Correct:**

```python
from typing import Sequence

def process_items(items: Sequence[Item]) -> list[str]:
    return [i.name for i in items]
```

Reference: [Google Python Style Guide - Typing](https://google.github.io/styleguide/pyguide.html#221-type-annotated-code)