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

Introduce a request id and a reference to latest request. Dismiss
incoming responses other than from latest request.

Remove timeouts which were used to mitigate the racing issue but are
obsolete now.

Reviewed-by: Z
Refs: #123
Closes #456
```

## Commit Without Scope

When scope is not needed:

```
feat: add Polish language

Add Polish translation files and update language selector.
```

## Tips

1. **Keep titles concise**: <50 characters, lowercase, imperative mood
2. **Explain "why" in body**: The code shows "how", the message explains "why"
3. **Use bullet points**: For multiple related changes
4. **Reference issues**: Always link to related issues when applicable
5. **Be specific**: Use scopes to provide context about which part of the codebase changed
6. **Indicate breaking changes**: Always clearly mark breaking changes with `!` or `BREAKING CHANGE:`
