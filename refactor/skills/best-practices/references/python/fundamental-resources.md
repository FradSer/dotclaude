---
title: Reading Resources
impact: MEDIUM
impactDescription: Ensures correct file access across different environments
tags: resources, packages, importlib
---

## Files and Resources

**Impact: CRITICAL (Ensures resources are located and closed correctly)**

Explicitly close files and sockets after use. Prefer `importlib.resources` for reading data files inside packages.

### Reasoning
- **Resource Leaks**: Failing to close files can exhaust file descriptors, crashing the application. Python's Garbage Collector (GC) *might* close them, but you cannot rely on it (especially in other Python implementations like PyPy).
- **Path reliability**: relying on `__file__` or `os.getcwd()` is fragile when code is zipped or installed in odd locations. `importlib.resources` handles this abstractly.

### Guidelines
- **Context Managers**: Always use `with open(...)` to ensure cleanup even if exceptions occur.
- **Data Files**: Use `importlib.resources.read_text(package, filename)` instead of path hacking.

**Incorrect:**

```python
import os
# Breaks if package is zipped or installed in a non-standard way
path = os.path.join(os.path.dirname(__file__), 'data.txt')
with open(path) as f:
    data = f.read()
```

**Correct:**

```python
from importlib import resources

# Access resource within the current package
with resources.open_text('my_package', 'data.txt') as f:
    data = f.read()
```

Reference: [Google Python Style Guide - Files and Sockets](https://google.github.io/styleguide/pyguide.html#219-files-and-sockets)