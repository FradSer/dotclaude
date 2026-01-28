---
title: Mutable Global State
impact: CRITICAL
impactDescription: Prevents side effects and unpredictable application state
tags: global-state, encapsulation, mutability
---

## Mutable Global State

**Impact: CRITICAL (Prevents side effects and unpredictable application state)**

Avoid mutable global state.

### Reasoning
- **Encapsulation**: Global state breaks encapsulation, making it hard to instantiate multiple independent copies of a component (e.g., multiple database connections).
- **Import Side Effects**: Assignments to global variables happen at import time, which can lead to confusing behavior and side effects just by importing a module.

### Guidelines
- **Constants**: Module-level constants are permitted and encouraged. Use `UPPER_CASE_WITH_UNDERSCORES`.
- **Exceptions**: If mutable global state is absolutely necessary, declare it at the module level or as a class attribute with an internal name (prepend `_`). Access it via public functions.
- **Documentation**: Always explain *why* mutable global state is being used in a comment.

**Incorrect:**

```python
# Mutable public global
current_user = None

def set_user(user):
    global current_user
    current_user = user
```

**Correct:**

```python
# Constant
MAX_RETRY_COUNT = 3

# Internal mutable state (if absolutely necessary)
_current_user = None

def get_current_user():
    return _current_user
```

Reference: [Google Python Style Guide - Global State](https://google.github.io/styleguide/pyguide.html#25-global-variables)