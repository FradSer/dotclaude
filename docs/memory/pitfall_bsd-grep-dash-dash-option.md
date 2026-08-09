---
name: bsd-grep-dash-dash-option
category: pitfall
summary: BSD grep parses `-`-prefixed patterns as options; use `grep --`
source: memory 插件早期 classify.sh（已随 dc6ff604 简化删除）
created: 2026-07-31
updated: 2026-08-09
---

# BSD grep treats `-`-prefixed patterns as long options

## Fact

BSD grep (macOS default) parses a pattern beginning with `-` as a long option, so `grep -qx '---'` fails with `unrecognized option \`---'` instead of matching the literal `---` frontmatter fence. GNU grep is lenient and matches silently; BSD grep is strict and exits 2 with a usage error.

## Why

A `grep -qx '---'` call looks correct (quotes around the pattern), but quotes do not stop option parsing — `grep` still sees the leading `-`. The failure prints to stderr but the script continues, so the bug is invisible unless stderr is read or the mutated file is tested. Inside `if ! grep -qx '---' ...`, the option-error exit (non-zero) flips to true via `!`, so a file that *has* frontmatter gets misrouted into the "no frontmatter" branch — prepending a duplicate `---\nvisibility:\n---` block and clobbering the file. Hit in memory 插件早期的 `classify.sh` `set_visibility`: every file with frontmatter was corrupted on the first publish call.

## How to apply

Any `grep` whose pattern may begin with `-` must use `--` to terminate option parsing:

```bash
grep -qx -- '---'          # correct
grep -qx -e '---'          # equivalent — -e explicitly marks the pattern
```

Patterns starting with `^` (`grep -q '^visibility:'`) are safe — `^` is not `-`. When writing grep in a `if !` guard, also test the mutated output, not just the exit code — a stderr usage error is indistinguishable from a non-match to the `if`.

## Related

- `pitfall_zsh-no-word-split.md` — the other shell-portability trap hit building the same plugin
