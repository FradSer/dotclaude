---
name: review
description: Reviews code using pi CLI with read-only tools. Delegates the review to pi (dev/pi) with a structured review rubric, running in read-only mode to prevent accidental edits. By default reviews uncommitted working tree changes (git diff HEAD) with pi restricted to the read tool; explicit targets (--branch/--diff/@file/PR) or --explore widen pi to read,grep,find,ls. Use when the user asks to "review code with pi", "pi review", "have pi review", "let pi review", or invokes /pi:review.
user-invocable: true
argument-hint: "[@target] [--branch BRANCH] [--diff RANGE] [--endpoint ENDPOINT] [--model MODEL] [--thinking LEVEL] [--explore] | --edit-config [--local|--shared|--global] | --list-models"
allowed-tools: ["Bash(git:*)", "Bash(jq:*)", "Bash(ls:*)", "Bash(find:*)", "Bash(cat:*)", "Bash(mkdir:*)", "Bash(echo:*)", "Bash(command:*)", "Bash(mktemp:*)", "Bash(rm:*)", "Bash(pi:*)", "Read", "Grep", "Glob"]
---
# CRITICAL: pi Code Review

This skill delegates a code review to the `pi` CLI tool (`@earendil-works/pi-coding-agent`). pi runs with **read-only tools** to prevent accidental edits — it analyzes code and returns findings as text.

**CRITICAL: The default review target is the uncommitted working tree (`git diff HEAD`), and pi must NOT be able to explore the whole codebase or run git itself.** pi's `--tools` flag is a hard allowlist — only listed tools are registered (pi's built-in tools are `read, grep, find, ls, bash, edit, write`; there is no standalone `git` tool, but `bash` can run `git diff`). By default restrict pi to `read` only so it can inspect files mentioned in the diff but cannot `find`/`grep`/`ls` the repo or run `bash`/`git`. Only expand to `read,grep,find,ls` when an explicit target (`--branch`, `--diff`, PR number) or `--explore` requires it.

## Before Execution: Check Installation

```bash
command -v pi >/dev/null 2>&1
```

If not installed, tell the user and stop.

## Persistent Settings

User preferences persist across invocations via JSON files. The resolution chain (highest priority first):

1. **CLI flag** (from `$ARGUMENTS`)
2. **`.claude/pi.local.json`** — project-specific overrides, gitignored
3. **`~/.claude/pi.local.json`** — global user-wide defaults
4. **Built-in defaults** (listed below)

Settings files use the format below. Load `references/settings.md` for the full format, reading logic, `--edit-config`, and `--list-models`:

```json
{
  "endpoints": {
    "my-proxy": {
      "provider": "openai",
      "baseUrl": "http://10.10.0.195:8317/v1",
      "models": ["gemini-3.6-flash-high", "gemini-3.6-pro"]
    }
  },
  "defaultEndpoint": "my-proxy",
  "defaultModel": "gemini-3.6-flash-high"
}
```

Each endpoint key has `provider` (required), optional `baseUrl`, and `models`. Values may reference env vars via `$VAR`. Read the merged settings with the `Reading settings` snippet in `references/settings.md` — it yields `ENDPOINT`, `MODEL`, `THINKING`, `PROVIDER`, `BASE_URL`, `API_KEY`.

Before parsing review targets, handle the two settings-only flags from `references/settings.md` and stop (do not proceed to review):
- `$ARGUMENTS` is exactly `--edit-config` (with optional scope flag) → open the settings file (see `references/settings.md`).
- `$ARGUMENTS` is exactly `--list-models` → print configured endpoints and models (see `references/settings.md`).

## Argument Parsing

Parse `$ARGUMENTS` to extract the review target and optional flags. The target is everything before the first `--` flag. If no flags are present, the entire argument is the target.

| Flag | Description | Source Priority |
|------|-------------|-----------------|
| `--endpoint` | Endpoint key name (must match a key in settings `endpoints`) | CLI > settings > `defaultEndpoint` |
| `--model` | Model ID to use for this review | CLI > settings > (endpoint's first model) |
| `--thinking` | Thinking level (off/minimal/low/medium/high/xhigh/max) | CLI > settings > `low` |
| `--explore` | Force full read-only exploration tools (`read,grep,find,ls`) even for the default working-tree review. Without this, the default review gets `read` only. | CLI flag |

### Resolution order per flag

For each flag, resolve the value by checking CLI flag first, then settings file, then built-in default:

1. Parse `$ARGUMENTS` for that flag. If present, use it.
2. Otherwise, read from `$CONFIG` (the merged settings). If non-null/non-empty, use it.
3. Otherwise, use the built-in default.

### Endpoint resolution

1. If `--endpoint` is specified, use it as the key into `endpoints` config.
2. If `--model` is specified without `--endpoint`, scan all endpoints for a model matching the ID — use the first match's endpoint.
3. Otherwise, use `defaultEndpoint` from settings.
4. If the resolved model is empty, use the first model in the resolved endpoint's model list.
5. Resolve the pi provider from the endpoint's `provider` field (default `openai`).

### Base URL resolution

If the resolved endpoint has a `baseUrl`, write it to `~/.pi/agent/models.json` for the resolved provider before running pi:

```bash
if [ -n "$BASE_URL" ]; then
  mkdir -p "$HOME/.pi/agent"
  EXISTING=$(cat "$HOME/.pi/agent/models.json" 2>/dev/null || echo '{}')
  echo "$EXISTING" | jq --arg provider "$PROVIDER" \
    --arg baseUrl "$BASE_URL" \
    '.providers[$provider] = (.providers[$provider] // {}) |
     .providers[$provider].baseUrl = $baseUrl' \
    > "$HOME/.pi/agent/models.json.tmp" && \
    mv "$HOME/.pi/agent/models.json.tmp" "$HOME/.pi/agent/models.json"
fi
```

## Review Target

Determine what to review from the parsed arguments. The target can be:

| Pattern | What it reviews | pi tools |
|---------|----------------|---------|
| No target (default) | `git diff HEAD` — uncommitted working tree changes (staged + unstaged) | `read` only |
| `--branch <name>` | `git diff main...<branch>` | `read,grep,find,ls` |
| `--diff <range>` | `git diff <range>` | `read,grep,find,ls` |
| `@filepath` | Specific file(s) | `read,grep,find,ls` |
| PR number | `gh pr diff <n>` | `read,grep,find,ls` |
| `--explore` (any target) | Overrides the tool set to full read-only exploration | `read,grep,find,ls` |

### Resolution logic

1. **CRITICAL: Do NOT use `@.`** — pi does not support passing a directory path as `@.`. It will error with `EISDIR`.
2. **By default (no target), review uncommitted working tree changes** — capture `git diff HEAD` (staged + unstaged vs HEAD) and pass it to pi. If the diff is empty, report that the working tree is clean and stop. Restrict pi to `--tools read` so it cannot scan the codebase or run git.
3. Only pass `@filepath` references when the user explicitly names specific files (target starts with `@`).
4. If the target is a number (e.g. `42`), treat it as a GitHub PR number — fetch the diff with `gh pr diff <n>`.
5. If the target starts with `--branch`, extract the branch name and capture `git diff main...<branch>`.
6. If the target starts with `--diff`, extract the range and capture `git diff <range>`.
7. Otherwise (free-text task description, e.g. `/pi:review "check the auth flow"`), pass the text as the task description and still capture `git diff HEAD` as context so pi reviews your current changes in service of the stated task.
8. **Tool selection**: default (no target) → `--tools read`. Any explicit target (`--branch`, `--diff`, `@filepath`, PR number) → `--tools read,grep,find,ls`. If `--explore` appears in `$ARGUMENTS` → force `--tools read,grep,find,ls` regardless of target. Never include `bash` — the read-only review must not let pi run `git` or edit files.

### File references (when user specifies @filepath)

When the user passes `@filepath`, pass those file paths directly to pi as `@file.ts` arguments. pi will read them.

## Review Rubric (Embedded in Prompt)

The review prompt given to pi must cover these dimensions. Embed them as part of the task description, not as `--append-system-prompt`:

### 1. Correctness & Logic
- Does the code do what it intends? Any off-by-one, race conditions, null pointer, or type errors?
- Are error paths handled (not just the happy path)?
- Are async operations properly awaited or chained?

### 2. Code Quality & Maintainability
- Naming: do names reveal intent? (Mysterious Name)
- Duplication: is the same logic repeated? (Duplicated Code)
- Coupling: does a module reach into another's internals? (Feature Envy)
- Abstraction: is there speculative generality or missing domain types? (Speculative Generality, Primitive Obsession)
- Size: are functions/classes too large? Do they do one thing?

### 3. Security
- Are user inputs validated/sanitized?
- Any hardcoded secrets, tokens, or credentials?
- Any injection vectors (SQL, command, path traversal)?

### 4. Architecture & Design
- Does the change follow the project's established patterns?
- Does it introduce unnecessary dependencies?
- Is the change scoped appropriately (not shotgun surgery)?

### 5. Testing
- Are there tests for the changed code?
- Do tests cover edge cases and error paths?

## Context Collection

### 1. Pass CLAUDE.md as System Prompt Context

Always pass the CLAUDE.md files as system prompt context so pi understands the project and user conventions. `--append-system-prompt` accepts file paths directly — pi reads them automatically.

```bash
# Build CLAUDE.md context — pass file paths, pi reads them
CLAUDE_CONTEXT=""
if [ -f "$HOME/.claude/CLAUDE.md" ]; then
  CLAUDE_CONTEXT="$CLAUDE_CONTEXT --append-system-prompt $HOME/.claude/CLAUDE.md"
fi
if [ -f "CLAUDE.md" ]; then
  CLAUDE_CONTEXT="$CLAUDE_CONTEXT --append-system-prompt CLAUDE.md"
fi
```

### 2. Git Context

```bash
git status --short
git diff --stat
git log --oneline -20
git branch --show-current
```

### 3. Capture the diff

Capture the diff for the resolved target into a temp file, then pass its path via `--append-system-prompt` (pi reads file paths directly):

```bash
DIFF_FILE=$(mktemp /tmp/pi-review-diff.XXXXXX)
HAS_EXPLICIT_TARGET=""

# No target (default): uncommitted working tree changes (staged + unstaged vs HEAD)
git diff HEAD > "$DIFF_FILE"

# For --branch <name>: diff against main
if [[ "$ARGUMENTS" == *"--branch"* ]]; then
  HAS_EXPLICIT_TARGET="1"
  BRANCH_NAME=$(echo "$ARGUMENTS" | sed -n 's/.*--branch[= ]\([^ ]*\).*/\1/p')
  git diff main...${BRANCH_NAME//\"/} > "$DIFF_FILE"
fi

# For --diff <range>
if [[ "$ARGUMENTS" == *"--diff"* ]]; then
  HAS_EXPLICIT_TARGET="1"
  RANGE=$(echo "$ARGUMENTS" | sed -n 's/.*--diff[= ]\([^ ]*\).*/\1/p')
  git diff "${RANGE//\"/}" > "$DIFF_FILE"
fi

# For a PR number (numeric target, not a flag)
if [[ "$ARGUMENTS" =~ ^[0-9]+(\ |$) ]] || [[ "$ARGUMENTS" =~ \ [0-9]+$ ]]; then
  HAS_EXPLICIT_TARGET="1"
  PR_NUM=$(echo "$ARGUMENTS" | grep -oE '[0-9]+' | head -1)
  gh pr diff "$PR_NUM" > "$DIFF_FILE"
fi

# For @filepath references (user-named files): explicit target, no diff to capture
if [[ "$ARGUMENTS" == *"@"* ]]; then
  HAS_EXPLICIT_TARGET="1"
fi
```

Then build `DIFF_CONTEXT="--append-system-prompt $DIFF_FILE"` and include it in the pi command alongside the git context.

**Empty-diff guard (default target only):** if `git diff HEAD` produces no output and no explicit target was given, the working tree is clean — report "No uncommitted changes to review — the working tree is clean. Use `/pi:review --branch <name>`, `/pi:review --diff <range>`, or `/pi:review <PR>` to review committed code." and stop before invoking pi.

## Execution

Always use `Bash` with `run_in_background` — pi -p is a single-shot command, not a continuous stream. **Do not add a shell `timeout`** — reviews can be heavy. **Do not use Monitor.**

```bash
# Build CLAUDE.md context — pass file paths, pi reads them
CLAUDE_CONTEXT=""
if [ -f "$HOME/.claude/CLAUDE.md" ]; then
  CLAUDE_CONTEXT="$CLAUDE_CONTEXT --append-system-prompt $HOME/.claude/CLAUDE.md"
fi
if [ -f "CLAUDE.md" ]; then
  CLAUDE_CONTEXT="$CLAUDE_CONTEXT --append-system-prompt CLAUDE.md"
fi

# Tool selection — see "Review Target" resolution logic
# Default (no target): read only, so pi cannot scan the codebase or run git.
# Explicit target or --explore: read,grep,find,ls. Never include bash.
if [[ "$ARGUMENTS" == *"--explore"* ]] || [ -n "$HAS_EXPLICIT_TARGET" ]; then
  TOOLS="read,grep,find,ls"
else
  TOOLS="read"
fi

# Build the pi review command with resolved variables
# $DIFF_CONTEXT carries the captured diff (see "Capture the diff"); empty when no diff applies
# Do NOT pass @file references unless the user explicitly named files
PI_CMD="pi -p --provider $PROVIDER --model $MODEL${API_KEY:+ --api-key $API_KEY} --thinking ${THINKING:-low} --tools $TOOLS --no-session --no-context-files --approve $CLAUDE_CONTEXT $DIFF_CONTEXT --append-system-prompt \"Git context: ...\" \"Review the code in the provided diff. Use your tools only to read the files mentioned in the diff for context — do NOT search the rest of the codebase, do NOT run git. Focus on correctness, code quality, security, architecture, and testing. For each issue found, report: file:line: severity (HIGH/MEDIUM/LOW) + description + suggested fix. Group findings by severity. If no issues found, explicitly state that the code looks clean.\""

# Run in background — no timeout; clean up the temp diff when pi exits
bash -c "$PI_CMD 2>&1; rm -f '$DIFF_FILE'" &
```

## Handling Output

### CRITICAL: pi's stdout is the review text

Unlike `/pi:delegate` where pi edits files, review mode uses read-only tools (`read`, or `read,grep,find,ls` with an explicit target) — pi cannot write files or run bash. **Its stdout IS the review output.** Capture it and present it to the user.

### On Success (exit code 0)

Present pi's output as the review findings. Format it clearly:

- If pi returned structured findings with severity, present them grouped by severity.
- If pi said "no issues found", report that the code looks clean.
- If stdout is empty but exit was 0, report: "pi completed the review but produced no output. This may indicate the model didn't understand the task. Consider retrying with a more specific prompt."

### On Error (exit code 1+)

Show the error message from stderr. Common causes:
- pi not configured (no API key)
- Provider/model not available
- Task interrupted or killed

## Usage Examples

### Review uncommitted working tree changes (default)

```
/pi:review
```

Reviews `git diff HEAD` — all staged and unstaged changes vs the last commit. If the working tree is clean, reports so and stops.

### Review with a specific endpoint

```
/pi:review --endpoint openrouter
```

### Review with a specific model

```
/pi:review --model gemini-3.6-pro
```

### Review a specific branch

```
/pi:review --branch feat/new-widget --endpoint local-proxy --model gemini-3.6-flash-high
```

### Review recent changes

```
/pi:review --diff HEAD~5..HEAD
```

### Review a pull request

```
/pi:review 42
```

### Review a specific file

```
/pi:review @src/core/agent.ts
```

### Let pi freely explore the codebase (default review, expanded tools)

```
/pi:review --explore
```

Overrides the default `read`-only restriction to `read,grep,find,ls` for the working-tree review. pi still cannot edit files or run bash.

### List configured endpoints

```
/pi:review --list-models
```

### Edit project settings

```
/pi:review --edit-config
```

## Important Notes

- pi runs with **read-only tools** — it cannot edit files or run bash.
- **Default review is restricted to `--tools read`** — pi can read files mentioned in the diff but cannot `grep`/`find`/`ls` the codebase or run `git`, so it cannot silently review the whole repo. Explicit targets (`--branch`, `--diff`, `@filepath`, PR number) or `--explore` expand it to `read,grep,find,ls`.
- **Default behavior reviews uncommitted working tree changes** (`git diff HEAD`, staged + unstaged). If the working tree is clean, the skill reports it and stops — use `--branch <name>`, `--diff <range>`, or a PR number to review committed code.
- **CLAUDE.md context is always passed** via `--append-system-prompt` as file paths — `~/.claude/CLAUDE.md` (user global) and `./CLAUDE.md` (project). pi reads them automatically.
- **pi only knows built-in provider names** (`openai`, `anthropic`, `google`, etc.). The settings `endpoints` map is just for user convenience. The skill writes `baseUrl` to `~/.pi/agent/models.json` under the endpoint's `provider` field, then passes `--provider <provider>` to pi.
- No shell `timeout` — reviews can be heavy and should run to completion.
- The review rubric is embedded in the task description, not `--append-system-prompt`, to keep it in pi's context window.
- Git context and diffs go into `--append-system-prompt` as structured context.
- PR review requires `gh` CLI to be installed and authenticated.
- For large codebases, consider targeting a specific branch, diff range, or file to keep the review focused.
- Settings are shared with `/pi:delegate` via the same file chain (`.claude/pi.local.json`, `~/.claude/pi.local.json`). Both skills read the same files, but each uses its own format — you can keep both in the same file.
- To configure pi (provider, model, base URL), run `/pi:setup` instead of passing flags manually.