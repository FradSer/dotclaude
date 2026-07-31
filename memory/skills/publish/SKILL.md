---
name: publish
description: This skill should be used when the user asks to "publish a memory", "promote a memory to public", "make this memory shareable", "发布记忆", "公开某条记忆", "move memory to repo", or wants to promote a single private Tier A fact to public AND immediately create its Tier B copy. One-shot promotion: sets `visibility: public` on the Tier A file and runs the a-to-b translation so the fact lands in `docs/memory/`. Refuses on redacted (secret-bearing) files.
user-invocable: true
argument-hint: <tier-a-file>
allowed-tools: ["Read", "Write", "Glob", "Grep", "Bash(${CLAUDE_PLUGIN_ROOT}/lib/memory-lib.sh:*)", "Bash(${CLAUDE_PLUGIN_ROOT}/lib/classify.sh:*)", "Bash(${CLAUDE_PLUGIN_ROOT}/../superpowers/lib/docs-index.sh:*)"]
---

# Publish a Memory (Tier A -> public + Tier B)

Promote a single private Tier A fact to public in one shot: set `visibility: public` on the Tier A file so future `/memory:sync` runs carry it, AND immediately create the Tier B copy (the a-to-b translation). This is the deliberate, per-fact gate for what crosses the private/public boundary — the opposite of bulk auto-sync.

## When To Use

Trigger on requests to publish / promote / make-public a specific Tier A memory. Arg `<tier-a-file>` is a path or the `name:` slug of a Tier A file.

## Workflow

### Phase 1 — Locate the Tier A file

Source `lib/memory-lib.sh` and `lib/classify.sh`. Resolve `MEM_A=$(tier_a_dir "$(pwd)")`. Find the file: if the arg is a path, use it; if it's a slug, glob `$MEM_A/*.md` for one whose `name:` frontmatter matches. If not found, report and stop.

### Phase 2 — Classify

Run `read_visibility "$file"`. If it returns `redacted`, REFUSE — the file is secret-bearing (name or body matches the denylist). Report that the user must manually redact the secrets first, then re-run. Do not proceed.

### Phase 3 — Set visibility: public

Run `set_visibility "$file" public` (from `lib/classify.sh`). This updates the Tier A file's frontmatter in place.

### Phase 4 — Create the Tier B copy (a-to-b translation)

Run the same translation as `/memory:sync a-to-b` for this single file:
1. Derive `docs/memory/<category>_<slug>.md` (map `metadata.type`→`category`: `feedback`→`pitfall`, `project`→`decision`, `reference`/`user`→`preference`).
2. Translate frontmatter (`name`, `category`, `summary`←`description`, `source`←Tier A origin project, `created`/`updated`←today).
3. Translate body to `## Fact`/`## Why`/`## How to apply`/`## Related`.
4. Write the Tier B file under `$(repo_root)/docs/memory/`.
5. `bash ${CLAUDE_PLUGIN_ROOT}/../superpowers/lib/docs-index.sh upsert memory docs/memory/<file> --category <cat> --summary "<summary>"`.

### Phase 5 — Report

State: the Tier A file's new `visibility: public`, the created Tier B file path, and the `docs/README.md` row upsert. If the Tier B file already existed, report it as an update and which side won (Tier A `metadata.modified` vs Tier B `updated` — see `references/sync-rules.md`).

## Hard Rules

- CRITICAL: Never publish a `redacted` fact. `read_visibility` must return `public` (or `private`, which you then flip) before writing the Tier B copy — never `redacted`.
- CRITICAL: Never run `git add`/`git commit` for committing — invoke `/git:commit` via the Skill tool when asked.
- The Tier A file is edited in place (it lives outside the repo, no commit); the Tier B file is a new repo file (commit via `/git:commit`).
