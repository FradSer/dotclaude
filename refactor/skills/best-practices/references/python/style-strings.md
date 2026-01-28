---
title: Strings
impact: LOW
impactDescription: Consistency
tags: strings, formatting
---

## Strings

**Impact: LOW (Consistency)**

- **Quotes**: Single `'` or double `"` quotes are fine, but be consistent locally. Prefer double quotes if the string contains a single quote.
- **Formatting**: Use f-strings `f"{variable}"` for general formatting.
- **Multi-line**: Use `"""` for multi-line strings/docstrings. Use `textwrap.dedent()` if indentation is needed in the source code.

### Logging
For logging functions (like `logging.info`), always use `%` placeholders, **not** f-strings. This allows the logger to skip string formatting if the log level is disabled.

**Incorrect (Logging):**
```python
logging.info(f"User {user.id} logged in")  # Eagerly formats even if info is disabled
```

**Correct (Logging):**
```python
logging.info("User %s logged in", user.id)  # Lazy formatting
```

### Error Messages
Error messages should:
1. Precisely match the error condition.
2. Clearly identify interpolated pieces (use quotes or `!r`).
3. Be easy to grep/search for (avoid constructing messages dynamically from too many small pieces).

**Correct:**
```python
raise ValueError(f"Not a probability: {p!r}")
```

Reference: [Google Python Style Guide - Strings](https://google.github.io/styleguide/pyguide.html#310-strings)
