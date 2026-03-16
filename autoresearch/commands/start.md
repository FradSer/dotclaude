---
description: "Start autonomous ML research loop (karpathy/autoresearch style)"
argument-hint: "[TAG] [--max-experiments N] [--completion-promise TEXT]"
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/scripts/setup-autoresearch.sh:*)"]
hide-from-slash-command-tool: "true"
---

# Autoresearch Start

Run the setup script to initialize the research loop:

```!
"${CLAUDE_PLUGIN_ROOT}/scripts/setup-autoresearch.sh" $ARGUMENTS
```

You are now running as an autonomous ML researcher. The stop hook is active — every time you try to exit, the same research prompt will be fed back to you. Your previous experiments are visible in git history and results.tsv.

CRITICAL: Once the experiment loop begins, NEVER stop to ask for permission to continue. Run indefinitely. You are the researcher. The human is asleep.
