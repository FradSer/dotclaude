---
title: Naming
impact: MEDIUM
impactDescription: Readability and consistency
tags: naming, conventions, style
---

## Naming

**Impact: MEDIUM (Readability and consistency)**

Use descriptive names. Avoid abbreviations unless they are standard and unambiguous.

### Names to Avoid
- **Single Character**: Avoid `a`, `b`, `x` except for:
  - Counters/Iterators: `i`, `j`, `k`, `v` (value)
  - `e` in `except` blocks
  - `f` in `with open(...) as f`
- **Dashes**: Never use dashes in package/module names.
- **Dunder**: Avoid `__double_leading_and_trailing_underscore__` (reserved by Python).
- **Type**: Avoid including type in name (e.g., `id_to_name_dict`).

### Conventions
- **Internal**: Use single underscore prefix `_private_var`.
- **Private**: Avoid double underscore prefix `__private_var` (name mangling) unless truly necessary to avoid subclass formatting collisions. Prefer single underscore.
- **File Naming**: usage `lower_with_under.py`. No dashes.
- **Tests**: `test_<method_under_test>_<state>`.

### Guidelines Table

| Type | Public | Internal |
|------|--------|----------|
| **Packages/Modules** | `lower_with_under` | `_lower_with_under` |
| **Classes** | `CapWords` | `_CapWords` |
| **Exceptions** | `CapWords` | |
| **Functions/Methods** | `lower_with_under()` | `_lower_with_under()` |
| **Constants** | `CAPS_WITH_UNDER` | `_CAPS_WITH_UNDER` |
| **Variables** | `lower_with_under` | `_lower_with_under` |

### Special Cases
- **Math Notation**: Short names matching reference papers are allowed if the source is cited in comments.

**Correct:**

```python
class UserAccount:
    def __init__(self, account_id):
        self._account_id = account_id  # Internal
    
    def get_id(self):
        return self._account_id

MAX_RETRIES = 3
```

**Incorrect:**

```python
class user_account:
    def GetId(self):
        return self.AccountID
```

Reference: [Google Python Style Guide - Naming](https://google.github.io/styleguide/pyguide.html#316-naming)