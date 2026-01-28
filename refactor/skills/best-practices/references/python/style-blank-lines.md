---
title: Blank Lines
impact: LOW
impactDescription: Improves readability
tags: whitespace, formatting, layout
---

## Blank Lines

**Impact: LOW (Improves readability)**

- **Top-level**: Two blank lines between top-level definitions (functions, classes).
- **Methods**: One blank line between method definitions inside a class.
- **Inside functions**: Use blank lines sparingly to separate logical sections.

**Correct:**

```python
class Foo:
    def method1(self):
        pass

    def method2(self):
        pass


def top_level_func():
    pass
```

Reference: [Google Python Style Guide - Blank Lines](https://google.github.io/styleguide/pyguide.html#34-blank-lines)