# Advanced Commit Examples

## Revert

```
revert: let us never again speak of the noodle incident

- Revert commit 676104e implementing feature X
- Revert commit a215868 updating component Y

The original implementation caused critical production issues.

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

- Add Polish translation files (pl.json)
- Update language selector dropdown to include Polish

Expands accessibility for Polish-speaking users.
```
