---
title: Comments and Docstrings
impact: HIGH
impactDescription: Documentation and maintainability
tags: comments, docstrings, documentation
---

## Comments and Docstrings

**Impact: HIGH (Documentation and maintainability)**

- **Docstrings**: Use `"""Triple double quotes"""` for modules, classes, and functions.
- **Comments**: Use `#` for implementation comments.

### Docstrings
- **Modules**: First line is summary.
- **Classes**: Describe the class. List public attributes in an `Attributes:` section.
- **Functions**: First line is summary. Details follow. Use `Args:`, `Returns:`, `Raises:` sections.

**Correct (Function):**
```python
def fetch_user(user_id):
    """Fetches a user by ID.

    Args:
        user_id: The ID of the user.

    Returns:
        The User object.
    
    Raises:
        ValueError: If user_id is invalid.
    """
```

**Correct (Class):**
```python
class SampleClass:
    """Summary of class here.

    Attributes:
        likes_spam: A boolean indicating if we like SPAM or not.
    """
    def __init__(self, likes_spam: bool = False):
        """Initializes the instance.
        
        Args:
            likes_spam: Defines if instance exhibits this preference.
        """
        self.likes_spam = likes_spam
```

### Block and Inline Comments
- **Placement**: Place comments near the code they explain.
- **Spacing**: Inline comments should be at least **2 spaces** away from the code.
- **Content**: Explain **why**, not **what**. Assume the reader knows Python.

**Correct:**
```python
if i & (i-1) == 0:  # True if i is 0 or a power of 2.
```

**Incorrect (Redundant):**
```python
x = x + 1  # Increment x
```

### Punctuation and Grammar
Comments should be readable as narrative text. Pay attention to punctuation and spelling.

Reference: [Google Python Style Guide - Comments](https://google.github.io/styleguide/pyguide.html#38-comments-and-docstrings)