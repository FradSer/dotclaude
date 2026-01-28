---
title: TODOs
impact: LOW
impactDescription: Improves code maintainability and tracking
tags: comments, maintenance, todo
---

## TODOs

**Impact: LOW (Improves code maintainability and tracking)**

Use `TODO` comments for temporary code, a short-term solution, or good-enough but not perfect code.

### proper Format
Google Style Guide standard format is:
`# TODO(username): description`

However, linking to an issue tracker is often superior for long-term tracking:
`# TODO(username): https://crbug.com/123 - Description`

### Guidelines
- **Presence**: TODOs should include the string `TODO` in all caps, followed by the name, email address, or other identifier of the person with the best context about the problem referenced by the TODO.
- **Hyphens**: A hyphen is optional between the identifier and the link/explanation.
- **Purpose**: It is not a commitment that the person named will fix the TODO. It is a contact point for future developers.

**Correct:**

```python
# TODO(kl@gmail.com): Use a "*" here for string repetition.
# TODO(Zeke): Change this to use relations.
# TODO(bug/123): remove this after the bug is fixed.
```

Reference: [Google Python Style Guide - TODO Comments](https://google.github.io/styleguide/pyguide.html#318-comments)