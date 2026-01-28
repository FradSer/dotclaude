---
title: Power Features
impact: HIGH
impactDescription: Prevents magic and maintainability issues
tags: metaclasses, reflection, complexity
---

## Power Features

**Impact: HIGH (Prevents magic and maintainability issues)**

Power features include metaclasses, bytecode access, monkey patching, descriptors, and custom `__import__`.

### Guidelines
- **Avoidance**: Avoid these unless strictly necessary. They make code hard to read and break tooling.
- **Metaclasses**:
    - Use only when class definition itself needs validation or modification that cannot be done with a decorator or helper.
    - If you must use one, inherit from `type`.
- **__del__ (Finalizers)**:
    - **Avoid**: Do not use `__del__`.
    - **Reason**: Invocation order during garbage collection is messy. Exceptions in `__del__` are ignored. Reference cycles can prevent collection.
    - **Alternative**: Use explicit `.close()` methods or context managers (`with` statement).
- **Dynamic Access**:
    - Prefer direct attribute access `obj.attr`.
    - Use `getattr(obj, 'attr')` or `setattr` only when the attribute name is dynamic string data.
    - Avoid `__getattribute__` (intercepts *all* reads); use `__getattr__` (intercepts missing reads) if needed.

**Incorrect (Unnecessary Metaclass):**
```python
class Meta(type):
    def __new__(cls, name, bases, dct):
        # Magic happening here
        return super().__new__(cls, name, bases, dct)

class Foo(metaclass=Meta): ...
```

**Incorrect (Using __del__):**
```python
class Database:
    def __del__(self):
        self.connection.close()  # Might not run!
```

**Correct (Context Manager):**
```python
class Database:
    def close(self): ...
    def __enter__(self): return self
    def __exit__(self, exc_type, exc_val, exc_tb):
        self.close()

with Database() as db:
    ...
```

Reference: [Google Python Style Guide - Power Features](https://google.github.io/styleguide/pyguide.html#218-power-features)