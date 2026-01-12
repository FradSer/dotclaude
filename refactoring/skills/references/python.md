# Python Code Standards

Language-specific guidelines for Python projects following PEP standards. Always apply [universal.md](universal.md) principles in addition to these language-specific rules.

## Code Style (PEP 8)

### Indentation and Line Length
- Use 4 spaces per indentation level (never tabs)
- Maximum line length: 79 characters for code, 72 for docstrings/comments
- Use parentheses for line continuation over backslashes

### Naming Conventions
- **Modules**: `lowercase_with_underscores`
- **Classes**: `CapitalizedWords` (PascalCase)
- **Functions/Variables**: `lowercase_with_underscores` (snake_case)
- **Constants**: `UPPER_CASE_WITH_UNDERSCORES`
- **Private**: prefix with single underscore `_private_method`

### Example
```python
# Module: user_service.py

MAX_RETRY_COUNT = 3  # Constant

class UserService:  # Class
    def __init__(self):
        self._connection = None  # Private attribute

    def get_user_by_id(self, user_id: str) -> User:  # Method
        """Retrieve user by ID."""
        return self._fetch_user(user_id)

    def _fetch_user(self, user_id: str) -> User:  # Private method
        # Implementation
        pass
```

## Type Hints (PEP 484)

### Function Signatures
- Add type hints for function parameters and return values
- Use `Optional[T]` for nullable types
- Use `Union[T1, T2]` for multiple possible types
- Use `typing` module for complex types

### Example
```python
from typing import Optional, List, Dict, Union

def get_user(user_id: str) -> Optional[User]:
    """Get user by ID, returns None if not found."""
    pass

def process_items(items: List[str]) -> Dict[str, int]:
    """Count occurrences of each item."""
    return {item: items.count(item) for item in set(items)}

def handle_value(value: Union[int, str]) -> str:
    """Convert value to string."""
    return str(value)
```

## Documentation (PEP 257)

### Docstrings
- Use triple double quotes: `"""Docstring"""`
- One-line docstrings for simple functions
- Multi-line docstrings for complex functions with detailed description

### Example
```python
def simple_function(x: int) -> int:
    """Double the input value."""
    return x * 2

def complex_function(data: List[Dict[str, any]]) -> Dict[str, List[str]]:
    """
    Process data and group by category.

    Args:
        data: List of dictionaries containing 'category' and 'value' keys

    Returns:
        Dictionary mapping categories to lists of values

    Raises:
        ValueError: If data format is invalid
    """
    pass
```

## Module Organization

### Import Order (PEP 8)
1. Standard library imports
2. Related third-party imports
3. Local application imports
- Separate each group with a blank line
- Sort imports alphabetically within each group

### Example
```python
# Standard library
import os
import sys
from pathlib import Path

# Third-party
import numpy as np
import pandas as pd
from flask import Flask, request

# Local application
from .models import User
from .utils import validate_email
```

## Functions and Methods

### Function Design
- Keep functions small and focused
- Use descriptive names (verbs for actions)
- Default arguments should be immutable
- Use `*args` and `**kwargs` sparingly

### Example
```python
# Good - immutable default
def create_list(items: Optional[List[str]] = None) -> List[str]:
    if items is None:
        items = []
    return items

# Bad - mutable default
def bad_create_list(items: List[str] = []) -> List[str]:  # Don't do this!
    return items
```

## Error Handling

### Exception Handling
- Catch specific exceptions, not bare `except:`
- Use context managers for resource management
- Raise exceptions with meaningful messages
- Use custom exceptions for application-specific errors

### Example
```python
# Good - specific exceptions
try:
    with open('file.txt', 'r') as f:
        data = f.read()
except FileNotFoundError:
    print("File not found")
except PermissionError:
    print("Permission denied")

# Bad - bare except
try:
    risky_operation()
except:  # Don't do this!
    pass
```

### Context Managers
- Use context managers (`with` statement) for resources
- Implement `__enter__` and `__exit__` for custom context managers
- Use `contextlib` for simple context managers

## Data Structures

### List Comprehensions
- Use list comprehensions for simple transformations
- Use generator expressions for large datasets
- Don't nest comprehensions too deeply

### Example
```python
# Good - clear comprehension
squares = [x**2 for x in range(10) if x % 2 == 0]

# Good - generator for memory efficiency
sum_of_squares = sum(x**2 for x in range(1000000))

# Bad - too complex
nested = [[y for y in range(x)] for x in range(10) if x % 2 == 0]
```

### Dictionaries
- Use dict comprehensions
- Use `get()` method with defaults
- Use `setdefault()` or `defaultdict` for initialization

### Example
```python
from collections import defaultdict

# Dict comprehension
squares = {x: x**2 for x in range(10)}

# Safe access with default
value = my_dict.get('key', default_value)

# Grouping with defaultdict
groups = defaultdict(list)
for item in items:
    groups[item.category].append(item)
```

## Classes

### Class Design
- Use dataclasses for simple data containers (Python 3.7+)
- Implement `__str__` and `__repr__` for debugging
- Use properties for computed attributes
- Prefer composition over inheritance

### Example
```python
from dataclasses import dataclass

@dataclass
class User:
    """User data container."""
    id: str
    name: str
    email: str

    @property
    def display_name(self) -> str:
        """Get display name."""
        return f"{self.name} <{self.email}>"
```

### Magic Methods
- Implement comparison methods when needed (`__eq__`, `__lt__`, etc.)
- Use `@functools.total_ordering` to generate comparison methods
- Implement `__len__`, `__getitem__` for container-like classes

## Dependency Management

### Package Management
- Use `uv` for dependency management and virtual environments
- Pin dependencies in `requirements.txt` or `pyproject.toml`
- Separate dev dependencies from production

### Virtual Environments
```bash
# Using uv
uv venv
source .venv/bin/activate  # or `.venv\Scripts\activate` on Windows
uv pip install -r requirements.txt
```

## Testing

### Test Structure
- Use `pytest` for testing
- Name test files `test_*.py` or `*_test.py`
- Name test functions `test_*`
- Use fixtures for setup/teardown

### Example
```python
import pytest

@pytest.fixture
def sample_user():
    """Create a sample user for testing."""
    return User(id="1", name="Test User", email="test@example.com")

def test_user_display_name(sample_user):
    """Test user display name generation."""
    assert sample_user.display_name == "Test User <test@example.com>"
```

## Modern Python Features

### f-Strings (Python 3.6+)
- Use f-strings for string formatting
- More readable than `%` formatting or `.format()`

### Example
```python
name = "Alice"
age = 30

# Good - f-string
message = f"{name} is {age} years old"

# Avoid
message = "%s is %d years old" % (name, age)
message = "{} is {} years old".format(name, age)
```

### Type Hints and Union Types (Python 3.10+)
```python
# Python 3.10+ syntax
def process(value: int | str) -> str:
    return str(value)

# Python 3.9+ for generic types
def get_items() -> list[str]:
    return ["item1", "item2"]
```

### Pattern Matching (Python 3.10+)
```python
match status:
    case 200:
        print("Success")
    case 404:
        print("Not found")
    case _:
        print("Unknown status")
```

## Performance Considerations

### Iteration
- Use generators for large datasets
- Use `itertools` for efficient iteration patterns
- Avoid repeatedly accessing list/dict methods in loops

### Example
```python
from itertools import islice

# Good - generator
def read_large_file(file_path):
    with open(file_path) as f:
        for line in f:  # Generator, memory efficient
            yield line.strip()

# Use itertools for efficient slicing
first_10 = list(islice(read_large_file('data.txt'), 10))
```

## Common Pitfalls

### Mutable Default Arguments
- Never use mutable objects as default arguments
- Use `None` and create the mutable object inside the function

### Late Binding Closures
- Be aware of late binding in closures
- Use default arguments to capture values

### Example
```python
# Problem - late binding
functions = [lambda x: x + i for i in range(5)]
# All lambdas will use i=4

# Solution - use default argument
functions = [lambda x, i=i: x + i for i in range(5)]
```

## Code Quality Tools

### Linting and Formatting
- Use `ruff` or `pylint` for linting
- Use `black` for auto-formatting
- Use `mypy` for static type checking
- Use `isort` for import sorting

### Configuration
```toml
# pyproject.toml
[tool.black]
line-length = 88
target-version = ['py310']

[tool.isort]
profile = "black"

[tool.mypy]
python_version = "3.10"
strict = true
```

## Project-Specific Standards

Always check the project's `CLAUDE.md` file for additional project-specific standards that override or extend these guidelines.
