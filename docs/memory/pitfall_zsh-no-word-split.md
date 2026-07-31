---
name: zsh-no-word-split
category: pitfall
summary: zsh does not word-split unquoted `$var` in `for`/command-substitution (unlike bash/POSIX); iterate newline-separated data via `while IFS= read -r` when a script may be sourced from zsh.
source: memory plugin audit (dotclaude/memory/lib/classify.sh)
created: 2026-07-31
updated: 2026-07-31
---

# zsh does not word-split unquoted variables

## Fact

zsh, by default, does **not** word-split unquoted variables. `for pat in $LIST` (where LIST is space-separated) iterates once with the whole string as a single element in zsh, but iterates per-word in bash. Same for `$(printf '%s\n' $LIST)` — zsh passes the un-split string as a single argument to printf. The script shebang (`#!/bin/bash`) does not help when the file is `source`d from a zsh session, because the session shell wins.

## Why

This is a deliberate zsh design choice (safer than POSIX word-splitting), but it silently breaks any shell function that relies on `for x in $WORDS`. The function appears to work (returns a value) but always takes the fall-through path because the single "word" never matches any pattern. Hit this in `dotclaude/memory/lib/classify.sh` `is_secret_filename`: the secret-denylist loop (`for pat in $SECRET_PATTERNS`) never matched `password`, so `frad-nas-kicad-password.md` was classified `public` instead of `redacted` — a secret-leak bug that only manifested under zsh.

## How to apply

For any list a script iterates, store it **newline-separated** and walk with:

```bash
while IFS= read -r pat; do
  case "$value" in *"$pat"*) ... ;; esac
done <<<"$LIST"
```

That form is portable across bash and zsh (per-line `read` does not depend on word-splitting). Applied in `classify.sh` (2026-07-31): `SECRET_PATTERNS` is now newline-separated. When testing shell functions, run under both `bash` and `zsh` — a function sourced from the session shell uses the session's word-splitting rules, not the shebang's.

## Related

- `dotclaude/memory/lib/classify.sh` `is_secret_filename` — where this was hit and fixed (2026-07-31)
- `pitfall_bsd-grep-dash-dash-option.md` — the other shell-portability trap hit building the same plugin
