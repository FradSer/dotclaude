---
description: "Start autonomous research loop on any artifact toward a measurable objective"
argument-hint: "[TAG] --prompt \"...\" --objective \"...\" --edit PATH --score-cmd \"...\" --direction min|max (--max-experiments N | --max-wall-clock 8h) [--readonly PATH]"
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/scripts/setup-autoresearch.sh:*)"]
disable-model-invocation: true
---

# Autoresearch Start

Run the setup script to initialize the research loop:

```!
"${CLAUDE_PLUGIN_ROOT}/scripts/setup-autoresearch.sh" --session-id "${CLAUDE_SESSION_ID}" $ARGUMENTS
```

You are now running as an autonomous researcher. The stop hook is active — every time you try to exit, the same research prompt will be fed back to you. Your previous experiments are visible in git history and results.tsv.

CRITICAL: Once the experiment loop begins, do not stop to ask for permission to continue between experiments. Keep iterating until the configured bound (max experiments or wall-clock budget) is reached — the stop hook enforces it automatically. You are the researcher. The human is asleep.
