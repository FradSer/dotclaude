# Branch Naming Rules

General rules for branch naming across all GitFlow workflows.

## General Rules

1. Use kebab-case (lowercase with hyphens)
2. Be descriptive but concise
3. Avoid special characters except hyphens
4. Match branch type prefix exactly

## Examples

**Good:**
- `feature/user-authentication`
- `bugfix/login-error-handling`
- `hotfix/payment-gateway-timeout`
- `release/v1.2.0`

**Bad:**
- `feature/userAuth` (camelCase)
- `feature/user_authentication` (snake_case)
- `feature/User-Authentication` (PascalCase)
- `feature/user authentication` (spaces)
