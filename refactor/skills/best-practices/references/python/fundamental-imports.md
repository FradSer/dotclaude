---
title: Imports
impact: CRITICAL
impactDescription: Ensures clear dependency declarations and prevents namespace collisions
tags: modules, namespaces, dependenc-management
---

## Imports

**Impact: CRITICAL (Ensures clear dependency declarations and prevents namespace collisions)**

Use `import` statements for packages and modules only, not for individual types, classes, or functions.

### Reasoning
- **Namespace Management**: Importing modules (`import x` or `from x import y`) keeps the namespace clean. `x.MyClass` clearly indicates where `MyClass` comes from.
- **Collisions**: Importing individual classes (`from x import MyClass`) often leads to naming collisions and makes circular imports more likely.

### Guidelines
- **Use**: `import x` for packages/modules.
- **Use**: `from x import y` where `y` is a module.
- **Avoid**: `from x import y` where `y` is a class/function (except for `typing`, `collections.abc`, or standard abbreviations like `numpy as np`).
- **Relative Imports**: Avoid relative imports (`from . import x`). Use the full package name (`from mypackage import x`) to avoid confusion and double-importing.
- **Aliases**: Use `as` only for standard abbreviations (e.g., `import pandas as pd`) or to fix naming conflicts.

**Incorrect (importing class directly):**

```python
from sound.effects.echo import EchoFilter
EchoFilter(...)
```

**Correct (importing module):**

```python
from sound.effects import echo
echo.EchoFilter(...)
```

**Correct (typing exception):**

```python
from typing import List, Optional
```

Reference: [Google Python Style Guide - Imports](https://google.github.io/styleguide/pyguide.html#22-imports)