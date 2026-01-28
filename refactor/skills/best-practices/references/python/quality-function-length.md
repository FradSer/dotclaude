---
title: Function Length
impact: MEDIUM
impactDescription: Improves readability and testability
tags: functions, complexity, refactoring
---

## Function Length

**Impact: MEDIUM (Improves readability and testability)**

Keep functions small and focused on a single task. While there is no hard limit, prefer functions under 40 lines.

### Reasoning
- **Readability**: Small functions fit on one screen and are easier to understand at a glance.
- **Testability**: Functions that do one thing are easier to unit test than functions that do many things.
- **Reuse**: Small, focused functions are more likely to be reusable in other contexts.

### Guidelines
- **Splitting**: If a function exceeds 40 lines, consider identifying blocks of code that perform specific sub-tasks and extracting them into helper functions.
- **Overhead**: Don't break up functions just for the sake of line count if it adds unnecessary complexity (e.g., many tiny functions with 1 line). Structure should follow logic.

**Incorrect (long, doing too much):**

```python
def process_data(data):
    # Validating data
    if not data:
        return
    # ... many lines of validation ...
    
    # transforming data
    # ... many lines of transformation ...
    
    # saving data
    # ... many lines of IO ...
```

**Correct (broken down):**

```python
def process_data(data):
    if not validate(data):
        return
    
    transformed = transform(data)
    save(transformed)
```

Reference: [Google Python Style Guide - Function Length](https://google.github.io/styleguide/pyguide.html#315-function-length)