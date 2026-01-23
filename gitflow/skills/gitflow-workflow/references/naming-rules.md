# Branch Naming Rules

## General rules

1. Use kebab-case (lowercase with hyphens).
2. Be descriptive but concise.
3. Avoid spaces and special characters (use only hyphens).
4. Always include the exact branch type prefix.

## Examples

Good:
- `feature/user-authentication`
- `hotfix/payment-gateway-timeout`
- `release/1.2.0`

Bad:
- `feature/userAuth` (camelCase)
- `feature/user_authentication` (snake_case)
- `feature/User-Authentication` (PascalCase)
- `feature/user authentication` (spaces)

## Name Normalization Procedure

When normalizing branch names from user input:

1. Strip the branch type prefix if present (e.g., `feature/`, `hotfix/`, `release/`)
2. Convert to kebab-case (lowercase with hyphens)
3. Assign to the appropriate variable (`$FEATURE_NAME`, `$HOTFIX_NAME`, `$RELEASE_VERSION`)

Example transformations:
- `feature/userAuth` → `user-auth`
- `User-Authentication` → `user-authentication`
- `hotfix/payment_gateway` → `payment-gateway`
- `v1.2.3` → `1.2.3` (for releases)
