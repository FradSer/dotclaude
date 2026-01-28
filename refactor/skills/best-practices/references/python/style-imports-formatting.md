---
title: Imports Formatting
impact: LOW
impactDescription: Improves readability and organization
tags: imports, formatting, sorting
---

## Imports Formatting

**Impact: LOW (Improves readability and organization)**

Imports should be on separate lines and grouped/sorted specifically.

### Formatting
- **One per line**: `import os` and `import sys` on separate lines.
- **Exceptions**: `from typing import Any, List` (multiple items allowed).

### Grouping and Sorting
Place imports at the top of the file in the following order (grouped):
1.  **Future**: `from __future__ import annotations`
2.  **Standard Library**: `import os`, `import sys`
3.  **Third Party**: `import requests`, `import tensorflow`
4.  **Local Application**: `from myproject import models`

**Sorting**: Alphabetical within each group (lexicographically ignoring case).

**Correct:**
```python
from __future__ import annotations

import collections
import sys

from absl import app
import tensorflow as tf

from myproject.backend import huxley
```

**Incorrect:**
```python
import os, sys  # Should be separate lines
```

Reference: [Google Python Style Guide - Imports formatting](https://google.github.io/styleguide/pyguide.html#313-imports-formatting)