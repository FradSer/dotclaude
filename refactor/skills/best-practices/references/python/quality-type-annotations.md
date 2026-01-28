---
title: Type Annotations
impact: HIGH
impactDescription: Comprehensive rules for Python type system usage
tags: typing, generics, style, safety
---

## Type Annotations

**Impact: HIGH (Comprehensive rules for type system usage)**

Follow these rules for Python type annotations.

### General Rules
- **Modern Syntax**: Use built-in types `list[int]`, `dict[str, int]`, `tuple[int]`, `type[int]` (Python 3.9+). Avoid deprecated `typing.List` / `typing.Dict`.
- **Line Breaking**: You can break long annotations.
    ```python
    def my_function(
        long_argument_name: dict[str, list[int]],
        other_argument: str,
    ) -> tuple[int, int]:
        ...
    ```

### Generics and Collections
- **Lists vs Tuples**:
    - Lists are homogeneous: `list[int]`.
    - Tuples can be structural (fixed size/types): `tuple[int, str]`.
    - Or homogeneous variable length: `tuple[int, ...]`.
- **Explicit Parameters**: Must specify properties for generic types. `Sequence` implies `Sequence[Any]`. Prefer `Sequence[int]` or explicit `Sequence[Any]`.
- **Abstract Types**: Prefer `Sequence`, `Mapping`, `Iterable` over concrete `list`, `dict` for arguments.

### Type Variables and Aliases
- **TypeVars**:
    - Naming: `_T` (internal), `T` (public/obvious), `AddableType` (constrained).
    - Constraints: Use `bound=` for class hierarchies.
- **Aliases**: Use `TypeAlias` (Python 3.10+) or simple assignment for complex types.
    ```python
    Vector = list[float]
    def scale(v: Vector, factor: float) -> Vector: ...
    ```
- **AnyStr**: Use `AnyStr` for functions accepting `str` OR `bytes` (returning the same type).
- **ParamSpec**: Use `ParamSpec` (`_P`) for decorators keeping signature.

### None and Optionals
- **Syntax**: Use `type | None` (Python 3.10+) or `Optional[type]`.
- **Arguments**: Use `Optional[T]` (or `T | None`) for arguments that can be `None`, even if they have a default of `None`.
    ```python
    def foo(x: str | None = None): ...
    ```

### Imports for Typing
- **Grouping**: `from typing import Any, List`. Multiple imports per line are explicitly allowed for `typing`.
- **Aliases**: Import strict names. If a collision occurs, alias the import: `from my_module import MyType as OtherType`.
- **Circular Dependencies**: Use `if TYPE_CHECKING:` blocks.
    - Inside the block, import the module.
    - In annotations, use string forward references `"MyClass"`, or `from __future__ import annotations`.

**Incorrect (Circular Import):**
```python
import other_module  # Causes circular import outcome
def func(a: other_module.Type): ...
```

**Correct (Circular Import Solution):**
```python
from typing import TYPE_CHECKING
if TYPE_CHECKING:
    import other_module

def func(a: "other_module.Type"): ...
```

### Legacy Type Comments
Do **not** use `# type: int` comments (deprecated since 3.6). Use annotations.

**Incorrect:**
```python
x = 5  # type: int
```

**Correct:**
```python
x: int = 5
```

Reference: [Google Python Style Guide - Typing](https://google.github.io/styleguide/pyguide.html#319-type-annotations)