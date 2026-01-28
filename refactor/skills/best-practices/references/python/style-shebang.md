---
title: Shebang
impact: LOW
impactDescription: Execution
tags: scripts, shebang
---

## Shebang

**Impact: LOW (Execution)**

Use a shebang line only for executable scripts. Use `#!/usr/bin/env python3`.

**Correct (for scripts):**

```python
#!/usr/bin/env python3
import sys
...
```

Reference: [Google Python Style Guide - Shebang Line](https://google.github.io/styleguide/pyguide.html#312-shebang-line)