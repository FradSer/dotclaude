---
title: Packages
impact: CRITICAL
impactDescription: Ensures consistent and unambiguous imports
tags: packages, imports, modules
---

## Packages

**Impact: CRITICAL (Prevents circular dependencies and naming conflicts)**

Import each module using the full pathname location of the module.

### Reasoning
- **Clarity**: `from myproject.utils import helpers` is unambiguous. `from .. import helpers` requires knowing the file structure to understand.
- **Searchability**: Full paths are easy to grep for.
- **Safety**: Avoids accidental import of standard library modules or local variables with the same name.

### Guidelines
- **Full Paths**: Use `from mypackage.subpackage import module`.
- **Exceptions**: Relative imports are generally discouraged, but some projects use them cautiously within highly cohesive sub-packages. However, full paths are always the safe default.

**Incorrect:**

```python
# Assuming we are in doctor/who/
import jodie  # Relative import
```

**Correct:**

```python
from doctor.who import jodie  # Full path
```

Reference: [Google Python Style Guide - Imports](https://google.github.io/styleguide/pyguide.html#22-imports)