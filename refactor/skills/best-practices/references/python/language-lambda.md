---
title: Lambda Functions
impact: LOW
impactDescription: Readability
tags: functions, lambda, callbacks
---

## Lambda Functions

**Impact: LOW (Readability)**

Use `lambda` functions for one-liners. Use local `def` functions for anything else.

### Reasoning
- **Readability**: Lambdas are concise but hard to read if they become complex. Named functions self-document their purpose.
- **Tracebacks**: Named functions appear with their name in stack traces; lambdas appear as `<lambda>`, making debugging harder.

### Guidelines
- **One-Liners**: Use lambdas for simple callbacks (e.g., inside `map()` or `filter()`).
- **Complex Logic**: If a lambda needs multiple expressions or conditions, convert it to a `def`.
- **Late Binding**: Be aware that lambdas capture variables by reference, not value (see example below). Default arguments can be used to capture values at definition time.

**Incorrect (complex lambda):**

```python
f = lambda x: x * 2 if x > 0 else 0
```

**Correct (named function):**

```python
def f(x):
    return x * 2 if x > 0 else 0
```

**Incorrect (late binding bug):**

```python
funcs = [lambda: i for i in range(3)]
# funcs[0]() returns 2, not 0!
```

**Correct (fixing late binding):**

```python
funcs = [lambda i=i: i for i in range(3)]
```

Reference: [Google Python Style Guide - Lambda](https://google.github.io/styleguide/pyguide.html#210-lambda-functions)