---
# Copy this file to .claude/refactor.local.md and customize

enabled: true

# Default rule application mode
# - all: Apply all applicable rules automatically (no interaction)
# - selected: Always show interactive rule selection
# - weighted: Apply rules based on configured weights
default_mode: all

# Rule categories configuration
rule_categories:
  # Next.js performance patterns
  nextjs:
    async: true      # Eliminating waterfalls (CRITICAL impact)
    bundle: true     # Bundle size optimization (CRITICAL impact)
    server: true     # Server-side performance (HIGH impact)
    client: true     # Client-side data fetching (MEDIUM-HIGH impact)
    rerender: true   # Re-render optimization (MEDIUM impact)
    rendering: true  # Rendering performance (MEDIUM impact)
    js: true         # JavaScript micro-optimizations (LOW-MEDIUM impact)
    advanced: true   # Advanced patterns (LOW impact)
  
  # Language-specific best practices
  languages:
    typescript: true   # TypeScript/JavaScript best practices
    python: true       # Python best practices
    go: true          # Go best practices
    swift: true       # Swift best practices
    universal: true   # Universal principles (SOLID, DRY, KISS, etc.)

# Rule weighting strategy
# - impact-based: Prioritize by impact level (CRITICAL > HIGH > MEDIUM > LOW)
# - equal: All enabled rules have equal priority
# - custom: Use custom_weights for specific rule priorities
weighting_strategy: impact-based

# Custom weights for specific rules (when weighting_strategy is "custom")
# Format: "category:rule-id": weight_number
custom_weights: {}

# Disabled patterns (never apply these rules)
# Format: ["category:rule-id", "category:rule-id"]
disabled_patterns: []
---

# Refactor Plugin Configuration

This configuration file controls which refactoring rules are applied and how they are prioritized.

## Usage

1. Copy this file to `.claude/refactor.local.md` in your project root
2. Customize the settings according to your preferences
3. Run `/refactor-config` for interactive setup, or edit manually

## Configuration Options

- **enabled**: Enable/disable refactoring for this project
- **default_mode**: How rules are applied by default
- **rule_categories**: Enable/disable specific rule categories
- **weighting_strategy**: How to prioritize rules
- **custom_weights**: Override weights for specific rules
- **disabled_patterns**: List of patterns to never apply

## Notes

- This file is gitignored and won't be committed
- Changes take effect immediately (no restart needed)
- Use `/refactor-config` command for interactive setup
