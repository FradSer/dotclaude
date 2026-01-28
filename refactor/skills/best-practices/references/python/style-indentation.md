---
title: Indentation
impact: CRITICAL
impactDescription: Python syntax requirement
tags: indentation, whitespace, formatting
---

## Indentation

**Impact: CRITICAL (Python syntax requirement)**

- **Indent**: Use 4 spaces per indentation level.
- **Tabs**: Never use tabs.

### Line Continuation
Vertical alignment (align with opening delimiter) or hanging indent (4 spaces extra) are both acceptable.

**Correct (Vertical Alignment):**

```python
foo = long_function_name(var_one, var_two,
                         var_three, var_four)
```

**Correct (Hanging Indent):**

```python
def long_function_name(
        var_one, var_two, var_three,
        var_four):
    print(var_one)
```

**Incorrect (Argument on first line with hanging indent):**

```python
# Arguments on first line forbidden when not vertically aligned 
foo = long_function_name(var_one, var_two,
    var_three, var_four)
```

Reference: [Google Python Style Guide - Indentation](https://google.github.io/styleguide/pyguide.html#34-indentation)
