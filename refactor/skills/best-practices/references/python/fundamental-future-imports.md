---
title: Future Imports
impact: CRITICAL
impactDescription: Ensures code compatibility across Python versions
tags: compatibility, future-imports, versioning
---

## Future Imports

**Impact: CRITICAL (Enables modern Python semantics and easier upgrades)**

Use `from __future__ import` statements to enable modern language features in older Python versions.

### Reasoning
- **Pros**: Allows using newer, cleaner syntax (like `annotations`) immediately. Makes future upgrades to newer Python versions seamless because the code is already compliant.
- **Cons**: None (zero runtime cost after parsing).

### Guidelines
- **Placement**: Must be the very first line of code in the file (after docstrings).
- **Common Uses**:
    - `from __future__ import annotations` (Postponed evaluation of type hints; standard in 3.10+).
    - `from __future__ import generator_stop` (Enables straightforward generator termination).

**Correct:**

```python
from __future__ import annotations

def process(data: list[str]) -> None:
    pass
```

**Incorrect (if running on older python versions without the import):**

```python
# SyntaxError or runtime error on older Python
def process(data: list[str]) -> None:
    pass
```

Reference: [Python __future__](https://docs.python.org/3/library/__future__.html)