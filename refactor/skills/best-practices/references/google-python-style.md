# Google Python Style Guide

Reference: [Google Python Style Guide](https://google.github.io/styleguide/pyguide.html)

This document summarizes the core principles of the Google Python Style Guide. For complete details, consult the official guide.

## Python Language Rules

### Lint
- Run `pylint` over your code.
- Suppress warnings if needed but add an explanation.
- Unused argument warnings can be suppressed by deleting the variables at the start of the function (e.g., `del beans, eggs`).

### Imports
- **Use `import x`** for packages and modules.
- **Use `from x import y`** where `x` is the package prefix and `y` is the module name.
- **Use `from x import y as z`** only if:
  - Two modules named `y` are to be imported.
  - `y` conflicts with a top-level name.
  - `y` is an inconveniently long name.
  - `y` is too generic in the context (e.g., `from storage.file_system import options as fs_options`).
- **Do not use relative names in imports.** Even if the module is in the same package, use the full package name.

### Exceptions
- Make use of built-in exception classes when applicable.
- Do not use `assert` statements for validating argument values of a public API.
- Exceptions must not break the program flow blindly; catch specific exceptions.

## Python Style Rules

### Line Length
- **Maximum line length is 80 characters.**
- **Exceptions:**
  - Long import statements.
  - URLs, pathnames, or long flags in comments.
  - Module-level constants (urls, pathnames) that are inconvenient to split.
  - Pylint disable comments.
- **Do not use backslash** for explicit line continuation. Use implicit line joining inside parentheses, brackets, and braces.

### Indentation
- Indent code blocks with **4 spaces**.
- **Never use tabs**.
- Closing brackets can be on a separate line, indented to match the opening bracket line.

### Blank Lines
- **Two blank lines** between top-level definitions (function or class).
- **One blank line** between method definitions and between the class docstring and the first method.
- Use single blank lines within functions/methods as appropriate.

### Whitespace
- No whitespace inside parentheses, brackets, or braces.
- No whitespace before a comma, semicolon, or colon. Do use whitespace after them (except at end of line).

### Comments and Docstrings
- **Docstrings**:
  - A docstring is mandatory for every module, class, and function exported by a module.
  - One-line docstrings: `"""Do X and return Y."""`
  - Multi-line docstrings:
    ```python
    """Summary of changes.

    Longer description of the changes.

    Args:
        arg1: Description of arg1.
        arg2: Description of arg2.

    Returns:
        Description of return value.

    Raises:
        ValueError: If arg1 is invalid.
    """
    ```
- **Comments**:
  - Use comments to explain **why** code is doing something, not **what** it is doing.
  - Keep comments up-to-date.

### Strings
- Use f-strings, `%` formatting, or `.format()` method for formatting strings.
- Be consistent with your choice of string quote character (single `'` or double `"`).
- Multi-line strings can use triple double quotes `"""`.

### Naming
| Type | Public | Internal |
|------|--------|----------|
| **Packages** | `lower_with_under` | |
| **Modules** | `lower_with_under` | `_lower_with_under` |
| **Classes** | `CapWords` | `_CapWords` |
| **Exceptions** | `CapWords` | |
| **Functions** | `lower_with_under()` | `_lower_with_under()` |
| **Global/Class Constants** | `CAPS_WITH_UNDER` | `_CAPS_WITH_UNDER` |
| **Global/Class Variables** | `lower_with_under` | `_lower_with_under` |
| **Instance Variables** | `lower_with_under` | `_lower_with_under` |
| **Method Names** | `lower_with_under()` | `_lower_with_under()` |
| **Function/Method Parameters** | `lower_with_under` | |
| **Local Variables** | `lower_with_under` | |

- **Avoid**:
  - Single character names (except for counters/iterators like `i`, `j`, `k`, `v`, `e`, `f`).
  - Dashes (`-`) in package/module names.
  - `__double_leading_and_trailing_underscore__`.
  - Names that include the type (e.g., `id_to_name_dict`).

### Type Annotations
- Strongly encouraged for public APIs.
- Use `typing` module (or standard collection types in newer Python).
- Follow PEP 484.
