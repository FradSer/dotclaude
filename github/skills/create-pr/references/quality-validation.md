# Quality Validation Process

## Node.js Projects

Run the following validation commands:

- **Lint**: `npm run lint` or `pnpm lint`
- **Test**: `npm test` or `pnpm test`
- **Build**: `npm run build` or `pnpm build`
- **Type Check**: `npm run type-check` or `pnpm type-check`

Validate package.json changes and check for security vulnerabilities using `npm audit` or `pnpm audit`.

## Python Projects

Run the following validation commands:

- **Format**: `black .` or `ruff format`
- **Lint**: `ruff check .`
- **Test**: `pytest` or `python -m pytest`
- **Type Check**: `mypy .`

Validate requirements and dependencies, and check for security issues using `pip-audit` or similar tools.

## Security Validation

Comprehensive security scanning must include:

- Scan for sensitive files (.env, .key, .pem, credentials.json, etc.)
- Check for hardcoded secrets, passwords, API tokens
- Validate input sanitization in changed files
- Ensure no credentials in commit history
- Use tools like `gitleaks` or `trufflehog` for secret scanning
