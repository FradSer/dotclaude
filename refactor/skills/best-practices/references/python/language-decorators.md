---
title: Decorators
impact: MEDIUM
impactDescription: Ensures decorators are obvious and behave correctly
tags: decorators, functions, classes
---

## Decorators

**Impact: MEDIUM (Ensures decorators are obvious and behave correctly)**

Use decorators judiciously when there is a clear advantage. Avoid `staticmethod` and limit `classmethod`.

### Reasoning
- **Pros**: Elegantly specifies transformations (caching, access control, instrumentation) eliminating repetitive code.
- **Cons**: Decorators execute at *import time* (for top-level objects). Failures here are hard to debug. They can also obscure the function's signature and behavior ("magic").

### Guidelines
- **Naming**: Decorators should follow function naming (`lower_with_under`).
- **Dependencies**: Avoid external dependencies (DB, network) in the decorator's setup code (import time).
- **Correctness**: Use `functools.wraps` in your decorator to preserve the original function's metadata (docstring, name).
- **Classmethod**: Use only for alternative constructors or modifying process-wide state.
- **Staticmethod**: Avoid. Use module-level functions instead.

**Incorrect (modifying class needlessly):**

```python
class Foo:
    @classmethod
    def bar(cls, x):
        return x + 1
```

**Correct:**

```python
def bar(x):
    return x + 1
```

Reference: [Google Python Style Guide - Decorators](https://google.github.io/styleguide/pyguide.html#217-function-and-method-decorators)