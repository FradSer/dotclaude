# Advanced Commit Examples

Complex scenarios and edge cases for conventional commits.

## Revert Commit

When reverting previous commits:

```
revert: let us never again speak of the noodle incident

This reverts commit 676104e and a215868.

Refs: 676104e, a215868
```

## Commit with Multiple Paragraphs and Footers

Complex change with multiple footers:

```
fix: prevent racing of requests

- Add unique request ID generation for each API call
- Track latest request ID in component state
- Dismiss responses that don't match latest request ID
- Remove timeout-based race condition mitigation
- Update request interceptor to include request IDs

Prevents race conditions when rapid requests are made, ensuring
only the most recent response is processed.

The timeout-based approach was unreliable and caused legitimate
slow requests to be incorrectly dismissed.

Reviewed-by: Z
Refs: #123
Closes #456
```

## Commit Without Scope

When scope is not needed:

```
feat: add polish language support

Add Polish translation files and update language selector.
```

## Tips

1. **Keep titles concise**: <50 characters, **all lowercase**, imperative mood, no period at end
2. **Structure the body**: List specific changes as bullets first, then explain why in a paragraph
3. **Bullet points should be specific**: "Add X to Y" not just "Add feature"
4. **Start bullets with verbs**: Add, Remove, Update, Fix, Create, Extract, etc.
5. **Explain motivation**: After bullets, add a paragraph explaining why this matters
6. **Reference issues**: Always link to related issues when applicable
7. **Be specific**: Use scopes to provide context about which part of the codebase changed
8. **Indicate breaking changes**: Always clearly mark breaking changes with "!" or `BREAKING CHANGE:`
