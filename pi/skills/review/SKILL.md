---
name: review
description: Reviews code using pi CLI with read-only tools. Delegates the review to pi (dev/pi) with a structured review rubric, running in read-only mode to prevent accidental edits. By default reviews uncommitted working tree changes (git diff HEAD) with pi restricted to the read tool; explicit targets (--branch/--diff/@file/PR) or --explore widen pi to read,grep,find,ls. Use when the user asks to "review code with pi", "pi review", "have pi review", "let pi review", or invokes /pi:review.
user-invocable: true
argument-hint: "[@target] [--branch BRANCH] [--diff RANGE] [--endpoint ENDPOINT] [--model MODEL] [--thinking LEVEL] [--explore] [--with-packages] | --edit-config [--local|--shared|--global] | --list-models"
allowed-tools: ["Task", "Bash(git:*)", "Bash(jq:*)", "Bash(ls:*)", "Bash(find:*)", "Bash(cat:*)", "Bash(mkdir:*)", "Bash(echo:*)", "Bash(command -v:*)", "Bash(mktemp:*)", "Bash(rm:*)", "Bash(mv:*)", "Bash(sed:*)", "Bash(grep:*)", "Bash(head:*)", "Bash(awk:*)", "Bash(tr:*)", "Bash(gh:*)", "Bash(bash:*)", "Bash(vi:*)", "Read", "Grep", "Glob"]
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
3. **`.claude/pi.json`** — project shared defaults, committed
4. **`~/.claude/pi.local.json`** — global user-wide defaults
5. **Built-in defaults** (listed below)

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

Each endpoint key has `provider` (required), optional `baseUrl`, and `models`. Values may reference env vars via `$VAR`. Read the merged settings with the `Reading settings` snippet in `references/settings.md` — it yields `ENDPOINT`, `MODEL`, `THINKING`, `PROVIDER`, `BASE_URL`, `API_KEY`, `WITH_PACKAGES`.

Before parsing review targets, handle the two settings-only flags from `references/settings.md` and stop (do not proceed to review):
- `$ARGUMENTS` is exactly `--edit-config` (with optional scope flag) → open the settings file (see `references/settings.md`).
- `$ARGUMENTS` is exactly `--list-models` → print configured endpoints and models (see `references/settings.md`).

## Argument Parsing

Parse `$ARGUMENTS` to extract the review target and optional flags. The target is everything before the first `--` flag. If no flags are present, the entire argument is the target.

| Flag | Description | Source Priority |
|------|-------------|-----------------|
| `--endpoint` | Endpoint key name (must match a key in settings `endpoints`) | CLI > settings > `defaultEndpoint` |
| `--model` | Model ID to use for this review | CLI > settings > (endpoint's first model) |
| `--thinking` | Thinking level (off/minimal/low/medium/high/xhigh/max) | CLI > settings > `max` |
| `--explore` | Force full read-only exploration tools (`read,grep,find,ls`) even for the default working-tree review. Without this, the default review gets `read` only. | CLI flag |
| `--with-packages` | Load the user's global pi packages/skills/extensions (default is clean mode: off) | CLI > settings `withPackages` > `false` |

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

The pi-agent handles `baseUrl` — it conditionally writes it into the agent-dir `models.json` (pi has no `--base-url` flag) only when it differs from the existing value. The skill just passes the resolved `BASE_URL` to the agent; it does not write models.json itself.

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
7. Otherwise (free-text task description, e.g. `/pi:review "check the auth flow"`), pass the text as the task description and still capture `git diff HEAD` as context so pi reviews your current changes in service of the stated task. Free-text only applies when there is no explicit target and no `@file` reference — leading tokens up to the first `--` flag (so `check auth --explore` → task "check auth").
8. **Tool selection**: default (no target) → `--tools read`. Any explicit target (`--branch`, `--diff`, `@filepath`, PR number) → `--tools read,grep,find,ls`. If `--explore` appears in `$ARGUMENTS` → force `--tools read,grep,find,ls` regardless of target. Never include `bash` — the read-only review must not let pi run `git` or edit files.

### File references (when user specifies @filepath)

When the user passes `@filepath`, pass those file paths directly to pi as `@file.ts` arguments. pi will read them.

## Review Rubric (Embedded in Prompt)

The review prompt given to pi must cover these dimensions. Embed them as part of the task description, not as `--append-system-prompt`. See `references/rubric.md` for the full five-dimension rubric — the TASK prompt in the agent launch embeds a condensed version of it.

## Context Collection

### 1. Pass CLAUDE.md as System Prompt Context

Always pass the CLAUDE.md files as system prompt context so pi understands the project and user conventions. `--append-system-prompt` accepts file paths directly — pi reads them automatically.

**CRITICAL: do not accumulate the flags into a space-joined variable and expand it unquoted.** Under zsh (the default shell on macOS) that expansion is a single argument, so pi receives the literal string `--append-system-prompt /path/CLAUDE.md` as one token and appends it as text instead of reading the file. The pi-agent assembles the command as an array, so the skill only needs to hand the agent the resolved context files:

```bash
# Collect CLAUDE.md paths to pass to the agent as separate --append-system-prompt args
APPEND_PATHS=()
[ -f "$HOME/.claude/CLAUDE.md" ] && APPEND_PATHS+=("$HOME/.claude/CLAUDE.md")
[ -f "CLAUDE.md" ] && APPEND_PATHS+=("CLAUDE.md")
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
TASK_TEXT=""        # free-text task description, if any
FILE_REFS=()        # @file references, one per array element

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

# For a PR number: only when the FIRST token of $ARGUMENTS is all digits
FIRST_TOKEN=$(echo "$ARGUMENTS" | awk '{print $1}')
if [[ "$FIRST_TOKEN" =~ ^[0-9]+$ ]]; then
  HAS_EXPLICIT_TARGET="1"
  gh pr diff "$FIRST_TOKEN" > "$DIFF_FILE"
fi

# For @filepath references (user-named files): explicit target, no diff to capture
if [[ "$ARGUMENTS" == *"@"* ]]; then
  HAS_EXPLICIT_TARGET="1"
  : > "$DIFF_FILE"       # clear: @file reviews pass files, not a diff
  # Read one @ref per line into the array (avoids zsh word-splitting pitfalls)
  FILE_REFS=()
  while IFS= read -r ref; do
    [ -n "$ref" ] && FILE_REFS+=("$ref")
  done < <(echo "$ARGUMENTS" | grep -oE '@[^ ]+' || true)
fi

# Free-text task description: only when there is no explicit target and no @file refs.
# Take the leading tokens up to the first `--` flag, so `check auth --explore` → "check auth",
# and `--model gemini-3.6-pro` → "" (starts with a flag).
if [ -z "$HAS_EXPLICIT_TARGET" ] && [[ "$ARGUMENTS" != *"@"* ]]; then
  TASK_TEXT=$(echo "$ARGUMENTS" | sed -E 's/[[:space:]]*--.*$//' | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')
fi
```

Then build the diff context — this MUST be run as actual commands in the same shell, not left as prose. Collect context file paths into `APPEND_PATHS` (CLAUDE.md files from step 1, plus the diff when present) so the pi-agent emits each as its own `--append-system-prompt` argument:

```bash
# Context files: CLAUDE.md paths (from "Context Collection") plus the diff when non-empty
if [ -s "$DIFF_FILE" ]; then
  APPEND_PATHS+=("$DIFF_FILE")
fi
```

**Empty-diff guard (default target only):** if `git diff HEAD` produces no output and no explicit target was given (`HAS_EXPLICIT_TARGET` empty), the working tree is clean — report "No uncommitted changes to review — the working tree is clean. Use `/pi:review --branch <name>`, `/pi:review --diff <range>`, or `/pi:review <PR>` to review committed code." and stop before invoking pi. Run the guard as a command:

```bash
if [ ! -s "$DIFF_FILE" ] && [ -z "$HAS_EXPLICIT_TARGET" ] && [ -z "$TASK_TEXT" ]; then
  rm -f "$DIFF_FILE"   # clean up temp files created above ($GIT_FILE is created later, after this guard)
  echo "No uncommitted changes to review — the working tree is clean. Use --branch, --diff, or a PR number."
  exit 0
fi
```

## Execution

Do NOT run pi directly. After resolving settings and capturing the review target, launch the dedicated `pi:pi-agent` execution layer with the Task tool. It builds the pi command, runs it in the background, and returns pi's stdout.

**PREREQUISITE:** run the "Reading settings" snippet from `references/settings.md` first — it defines `$PROVIDER`, `$MODEL`, `$API_KEY`, `$THINKING`. Then capture the diff (see "Context Collection") into `$DIFF_FILE`/`$GIT_FILE`, and resolve `$TOOLS`:

```bash
# Tool selection — see "Review Target" resolution logic
# Default (no target): read only, so pi cannot scan the codebase or run git.
# Explicit target or --explore: read,grep,find,ls. Never include bash.
if [[ "$ARGUMENTS" == *"--explore"* ]] || [ -n "$HAS_EXPLICIT_TARGET" ]; then
  TOOLS="read,grep,find,ls"
else
  TOOLS="read"
fi

# Collect git context (status/stat/log/branch) into a temp file, passed like the diff
GIT_FILE=$(mktemp /tmp/pi-review-git.XXXXXX)
{ git status --short; git diff --stat; git log --oneline -20; git branch --show-current; } > "$GIT_FILE"
APPEND_PATHS+=("$GIT_FILE")   # git context is a second append (besides CLAUDE.md + diff)
```

Then launch `pi:pi-agent` with the Task tool, passing:

```
MODE: review
TASK: Review the code in the provided diff${TASK_TEXT:+ (task: $TASK_TEXT)}. Use your tools only to read the files mentioned in the diff for context — do NOT search the rest of the codebase, do NOT run git. Focus on correctness, code quality, security, architecture, and testing. For each issue found, report: file:line: severity (HIGH/MEDIUM/LOW) + description + suggested fix. Group findings by severity. If no issues found, explicitly state that the code looks clean.
PROVIDER: <resolved from settings>
MODEL: <resolved from settings>
ENDPOINT: <resolved endpoint key or empty — lets the pi-agent read credentials from the right endpoint (non-secret)>
THINKING: <resolved, default max>
TOOLS: <$TOOLS — read, or read,grep,find,ls>
WITH_PACKAGES: <true if --with-packages or settings withPackages; empty/false = clean mode>
APPEND_PATHS: <$APPEND_PATHS — CLAUDE.md paths + GIT_FILE + DIFF_FILE; the agent emits each as its own --append-system-prompt>
FILE_REFS: <$FILE_REFS — @file args, one per line; omit if none>
CLEANUP_FILES: <$DIFF_FILE $GIT_FILE — the agent removes them when pi exits>
```

**Do NOT pass `API_KEY` or `BASE_URL`** — the pi-agent reads them from the settings files itself (so the actual key/URL never enters the model's context). The pi-agent emits `--append-system-prompt` for every `APPEND_PATHS` entry, writes `baseUrl` to the agent-dir `models.json` when it resolves one, runs pi in the background with `--no-session --no-context-files --approve` plus default clean mode (`--no-extensions --no-skills` unless `WITH_PACKAGES=true`), and reports pi's stdout — which is the review text.

## Handling Output

### CRITICAL: pi's stdout is the review text

Unlike `/pi:delegate` where pi edits files, review mode uses read-only tools (`read`, or `read,grep,find,ls` with an explicit target) — pi cannot write files or run bash. **Its stdout IS the review output.** The pi-agent returns this stdout; present it to the user.

### On Success (exit code 0)

Present pi's output as the review findings. Format it clearly:

- If pi returned structured findings with severity, present them grouped by severity.
- If pi said "no issues found", report that the code looks clean.
- If stdout is empty but exit was 0, report: "pi completed the review but produced no output. This may indicate the model didn't understand the task. Consider retrying with a more specific prompt."

### On Error (exit code 1+)

Show the error message from the pi-agent's report. Common causes:
- pi not configured (no API key)
- Provider/model not available
- Task interrupted or killed

## Usage Examples

For concrete invocations (working tree, branch, diff range, PR, file, `--explore`,
`--list-models`, `--edit-config`, endpoint/model overrides), read
`references/examples.md`.

## Important Notes

- pi runs with **read-only tools** — it cannot edit files or run bash.
- **Default review is restricted to `--tools read`** — pi can read files mentioned in the diff but cannot `grep`/`find`/`ls` the codebase or run `git`, so it cannot silently review the whole repo. Explicit targets (`--branch`, `--diff`, `@filepath`, PR number) or `--explore` expand it to `read,grep,find,ls`.
- **Default behavior reviews uncommitted working tree changes** (`git diff HEAD`, staged + unstaged). If the working tree is clean, the skill reports it and stops — use `--branch <name>`, `--diff <range>`, or a PR number to review committed code.
- **Never run pi directly — always delegate to `pi:pi-agent`.** The agent is the plugin's single execution path and owns backgrounding, verification, and error handling.
- **CLAUDE.md context is always passed** by pi-agent via `--append-system-prompt` as file paths — `~/.claude/CLAUDE.md` (user global) and `./CLAUDE.md` (project). pi reads them automatically.
- **pi only knows built-in provider names** (`openai`, `anthropic`, `google`, etc.). The settings `endpoints` map is just for user convenience. The pi-agent writes `baseUrl` to the agent-dir `models.json` (default `~/.pi/agent/models.json`, redirectable via `PI_CODING_AGENT_DIR`/`AGENT_DIR`) under the endpoint's `provider` field, then passes `--provider <provider>` to pi.
- No shell `timeout` — reviews can be heavy and should run to completion.
- The review rubric is embedded in the task description, not `--append-system-prompt`, to keep it in pi's context window.
- Git context and diffs go into `--append-system-prompt` as structured context.
- PR review requires `gh` CLI to be installed and authenticated.
- For large codebases, consider targeting a specific branch, diff range, or file to keep the review focused.
- Settings are shared with `/pi:delegate` via the same three-tier file chain (`.claude/pi.local.json` > `.claude/pi.json` > `~/.claude/pi.local.json`). Both skills use the same named-endpoint format (endpoint-first, with a legacy flat-field fallback), so a single config file serves both.
- To configure pi (provider, model, base URL), run `/pi:setup` instead of passing flags manually.