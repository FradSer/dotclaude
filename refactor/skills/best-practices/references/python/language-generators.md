---
title: Generators
impact: MEDIUM-HIGH
impactDescription: Improves memory efficiency for large datasets
tags: generators, iterators, memory, performance
---

## Generators

**Impact: MEDIUM-HIGH (Improves memory efficiency for large datasets)**

Use generators as needed. A generator function returns an iterator that yields a value each time it executes a yield statement.

### Reasoning
- **Pros**: Simpler code (state is preserved automatically). Much lower memory usage for large sequences (lazy evaluation).
- **Cons**: Local variables in the generator are not garbage collected until the generator is fully consumed or destroyed.

### Guidelines
- **Docstrings**: Use "Yields:" rather than "Returns:" in the docstring.
- **Cleanup**: If the generator manages an expensive resource (like a database connection), wrap it in a context manager (or use `try/finally` inside the generator) to ensure proper cleanup if the iteration is stopped early.

**Incorrect (eagerly building a list):**

```python
def get_squares(n):
    # Builds the entire list in memory
    result = []
    for i in range(n):
        result.append(i * i)
    return result

# Consumes memory proportional to 'n'
squares = get_squares(1000000)
for square in squares:
    process(square)
```

**Correct (using a generator):**

```python
def get_squares(n):
    # Yields one value at a time
    for i in range(n):
        yield i * i

# Memory efficient, consumes one value at a time
for square in get_squares(1000000):
    process(square)
```

Reference: [PEP 255 – Simple Generators](https://peps.python.org/pep-0255/)