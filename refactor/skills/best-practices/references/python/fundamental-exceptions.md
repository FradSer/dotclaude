---
title: Exceptions
impact: CRITICAL
impactDescription: Prevents unpredictable behavior and silent failures
tags: exceptions, error-handling, assertions
---

## Exceptions

**Impact: CRITICAL (Prevents unpredictable behavior and silent failures)**

Exceptions are the preferred means of reporting errors.

### Guidelines
- **Raising**:
    - Use `raise MyError('message')`.
    - Avoid the 2-arg `raise MyError, 'message'` (removed in Py3, but conceptually dead).
    - Prefer built-in exceptions (`ValueError`, `TypeError`) when they fit.
- **Defining**:
    - Inherit from `Exception`, **not** `BaseException` (which reserves `SystemExit` and `KeyboardInterrupt`).
    - Name ending in `Error`.
- **Catching**:
    - Never catch bare `except:` or `except Exception` unless:
        1. You are re-raising (`raise`).
        2. You are isolating a clear failure domain (e.g., a top-level thread loop).
    - Avoid `try/except` blocks that are too large; this masks unexpected errors.
- **Finally**:
    - `finally` executes *whether or not* an exception is raised.
    - Caution: It does *not* execute if the program is killed by `signal.SIGKILL`.
- **Assertions**:
    - Use `assert` for **internal invariants** only.
    - Do **not** use `assert` for:
        - Data validation (arguments).
        - Expected error conditions (file not found).
    - Reason: `assert` can be disabled with `-O`.

**Incorrect (Catching everything):**
```python
try:
    complex_operation()
except:  # Catches KeyboardInterrupt too!
    pass
```

**Correct (Re-raising):**
```python
try:
    complex_operation()
except Exception:
    logging.exception("Failed")
    raise  # Preserves traceback
```

**Incorrect (Assert for validation):**
```python
def connect(port):
    assert port > 1024  # Bad: Disappears with -O
```

**Correct (Validation):**
```python
def connect(port):
    if port <= 1024:
        raise ValueError("Port must be > 1024")
```

Reference: [Google Python Style Guide - Exceptions](https://google.github.io/styleguide/pyguide.html#24-exceptions)