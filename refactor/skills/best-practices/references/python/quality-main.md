---
title: Main Function
impact: MEDIUM
impactDescription: Prevents code execution on import
tags: modules, script, entry-point
---

## Main Function

**Impact: HIGH (Prevents accidental execution on import)**

Even for scripts, define a `main()` function and call it only when the module is executed directly.

### Reasoning
- **Importability**: If code is at the top level, importing the module (e.g., for testing) will execute it.
- **Testing**: A `main()` function can be imported and unit-tested directly.

### Guidelines
- **Check**: Use `if __name__ == "__main__":` to guard the execution.
- **Structure**: Put the main logic in `main()`, not in the global scope.

**Incorrect:**

```python
# script.py
# Code at top level
print("Running")
do_work()
```

**Correct:**

```python
# script.py
def main():
    print("Running")
    do_work()

if __name__ == '__main__':
    main()
```

Reference: [Google Python Style Guide - Main](https://google.github.io/styleguide/pyguide.html#317-main)