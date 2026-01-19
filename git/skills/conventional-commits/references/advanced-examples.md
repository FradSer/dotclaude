# Advanced Commit Examples

## Revert

```
revert: let us never again speak of the noodle incident

This reverts commit 676104e and a215868.

Refs: 676104e, a215868
```

## Multiple Footers

```
fix: prevent racing of requests

- Add unique request ID generation for each API call
- Track latest request ID in component state
- Dismiss responses that don't match latest request ID

Prevents race conditions when rapid requests are made, ensuring
only the most recent response is processed.

Reviewed-by: Z
Refs: #123
Closes #456
```

## Without Scope

```
feat: add polish language support

Add Polish translation files and update language selector.
```
