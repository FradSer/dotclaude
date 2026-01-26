#!/usr/bin/env python3
"""
Token counter for validating skill token budgets.

Progressive Disclosure Token Budgets:
- Tier 1: Metadata (description) → ~50 tokens (loaded during skill discovery)
- Tier 2: SKILL.md body → ~500 tokens target (loaded when skill invoked)
- Tier 3: References → 2000+ tokens typical (loaded only when specifically needed)

Token targets are recommendations for optimal context usage:
- Exceeding ~500 tokens in SKILL.md triggers warnings but not errors
- Critical information should be included even if it causes moderate overages
- Only token counts >800 trigger warnings; >2500 are critical errors

The three-tier approach enables equipping agents with hundreds of skills
without overwhelming context windows.

Usage:
    python count-tokens.py <path>              # Count tokens in a file
    python count-tokens.py <skill-dir>         # Analyze a skill directory
    python count-tokens.py <plugin-dir> --all  # Analyze all skills in plugin
"""

import sys
import os
import re
import json
from pathlib import Path

# Token budget thresholds (progressive disclosure)
# Tier 1: Metadata - loaded during skill discovery
METADATA_BUDGET = 50  # Target for optimal discovery
METADATA_WARNING = 100  # Warning threshold

# Tier 2: SKILL.md - loaded when skill invoked
SKILL_BUDGET = 500  # Target for optimal context usage (not a hard limit)
SKILL_WARNING = 800  # Warning threshold - acceptable for critical content
SKILL_CRITICAL = 2500  # Critical threshold - must refactor if exceeded

# Tier 3: References - loaded only when specifically needed
# 2000+ tokens is typical/expected (detailed content belongs here)

# Try to use tiktoken for accurate counting, fall back to approximation
try:
    import tiktoken
    ENCODER = tiktoken.get_encoding("cl100k_base")  # Claude-compatible encoding

    def count_tokens(text: str) -> int:
        return len(ENCODER.encode(text))

    TOKEN_METHOD = "tiktoken (cl100k_base)"
except ImportError:
    def count_tokens(text: str) -> int:
        """Approximate token count: ~4 chars per token for code/markdown."""
        return len(text) // 4

    TOKEN_METHOD = "approximation (~4 chars/token)"


def extract_frontmatter(content: str) -> tuple[dict, str]:
    """Extract YAML frontmatter and body from markdown."""
    if not content.startswith("---"):
        return {}, content

    parts = content.split("---", 2)
    if len(parts) < 3:
        return {}, content

    frontmatter_text = parts[1].strip()
    body = parts[2].strip()

    # Simple YAML parsing for description
    frontmatter = {}
    for line in frontmatter_text.split("\n"):
        if ":" in line:
            key, _, value = line.partition(":")
            key = key.strip()
            value = value.strip().strip('"').strip("'")
            if key == "description":
                # Handle multiline descriptions
                if value == "|" or value == ">":
                    # Find all indented lines after description:
                    desc_lines = []
                    in_desc = False
                    for l in frontmatter_text.split("\n"):
                        if l.strip().startswith("description:"):
                            in_desc = True
                            continue
                        if in_desc:
                            if l.startswith("  ") or l.startswith("\t"):
                                desc_lines.append(l.strip())
                            elif l.strip() and not l.startswith(" "):
                                break
                    value = " ".join(desc_lines)
                frontmatter["description"] = value
            else:
                frontmatter[key] = value

    return frontmatter, body


def analyze_skill(skill_dir: Path) -> dict:
    """Analyze a skill directory for token usage."""
    result = {
        "path": str(skill_dir),
        "name": skill_dir.name,
        "metadata_tokens": 0,
        "skill_tokens": 0,
        "reference_tokens": 0,
        "total_tokens": 0,
        "files": [],
        "status": "OK",
        "warnings": [],
    }

    skill_md = skill_dir / "SKILL.md"
    if not skill_md.exists():
        result["status"] = "ERROR"
        result["warnings"].append("SKILL.md not found")
        return result

    content = skill_md.read_text()
    frontmatter, body = extract_frontmatter(content)

    # Count metadata tokens (description)
    description = frontmatter.get("description", "")
    result["metadata_tokens"] = count_tokens(description)

    # Count SKILL.md body tokens
    result["skill_tokens"] = count_tokens(body)

    result["files"].append({
        "file": "SKILL.md",
        "tokens": result["skill_tokens"],
        "type": "skill",
    })

    # Count reference files
    seen_files = set()
    ref_dirs = [skill_dir, skill_dir / "references"]
    for ref_dir in ref_dirs:
        if not ref_dir.exists():
            continue
        for f in ref_dir.glob("**/*.md"):
            if f.name == "SKILL.md":
                continue
            # Avoid counting same file twice
            abs_path = f.resolve()
            if abs_path in seen_files:
                continue
            seen_files.add(abs_path)

            tokens = count_tokens(f.read_text())
            result["reference_tokens"] += tokens
            result["files"].append({
                "file": str(f.relative_to(skill_dir)),
                "tokens": tokens,
                "type": "reference",
            })

    # Count script files
    scripts_dir = skill_dir / "scripts"
    if scripts_dir.exists():
        for f in scripts_dir.glob("**/*"):
            if f.is_file() and f.suffix in [".py", ".sh", ".js", ".ts"]:
                tokens = count_tokens(f.read_text())
                result["files"].append({
                    "file": str(f.relative_to(skill_dir)),
                    "tokens": tokens,
                    "type": "script",
                })

    result["total_tokens"] = (
        result["metadata_tokens"] +
        result["skill_tokens"] +
        result["reference_tokens"]
    )

    # Validate against progressive disclosure budgets
    # Tier 1: Metadata
    if result["metadata_tokens"] > METADATA_WARNING:
        result["warnings"].append(
            f"Tier 1 (Metadata): {result['metadata_tokens']} tokens exceeds ~{METADATA_BUDGET} budget"
        )

    # Tier 2: SKILL.md
    if result["skill_tokens"] > SKILL_CRITICAL:
        result["status"] = "CRITICAL"
        result["warnings"].append(
            f"Tier 2 (SKILL.md): {result['skill_tokens']} tokens critically exceeds {SKILL_CRITICAL} limit - MUST refactor to references/"
        )
    elif result["skill_tokens"] > SKILL_WARNING:
        result["status"] = "WARNING"
        result["warnings"].append(
            f"Tier 2 (SKILL.md): {result['skill_tokens']} tokens exceeds {SKILL_WARNING} warning threshold - consider moving content to references/"
        )
    elif result["skill_tokens"] > SKILL_BUDGET:
        # Above target but below warning - note it but don't change status
        result["warnings"].append(
            f"Tier 2 (SKILL.md): {result['skill_tokens']} tokens above {SKILL_BUDGET} target (acceptable if content is critical)"
        )

    # Tier 3: References - 2000+ is expected and good (progressive disclosure working)
    if result["reference_tokens"] > 0 and result["reference_tokens"] < 500 and result["skill_tokens"] > SKILL_BUDGET:
        result["warnings"].append(
            f"Tier 3 (References): Only {result['reference_tokens']} tokens - consider moving more content from SKILL.md"
        )

    return result


def find_skills(plugin_dir: Path) -> list[Path]:
    """Find all skill directories in a plugin."""
    skills_dir = plugin_dir / "skills"
    if not skills_dir.exists():
        return []

    skills = []
    for item in skills_dir.iterdir():
        if item.is_dir() and (item / "SKILL.md").exists():
            skills.append(item)
    return skills


def print_result(result: dict, verbose: bool = False):
    """Print analysis result."""
    status_icons = {"OK": "OK", "WARNING": "Warning", "CRITICAL": "Error", "ERROR": "Error"}
    icon = status_icons.get(result["status"], "?")

    # Determine status indicators for each tier
    t1_status = "OK" if result["metadata_tokens"] <= METADATA_WARNING else "Warning"
    t2_status = "OK" if result["skill_tokens"] <= SKILL_BUDGET else ("Error" if result["skill_tokens"] > SKILL_CRITICAL else "Warning")
    t3_status = "OK"  # References: no upper limit, 2000+ is typical

    print(f"\n{icon} {result['name']}")
    print(f"  Path: {result['path']}")
    print(f"  Tier 1 (Metadata):   {result['metadata_tokens']:>6} tokens  (target: ~{METADATA_BUDGET}) {t1_status}")
    print(f"  Tier 2 (SKILL.md):   {result['skill_tokens']:>6} tokens  (target: ~{SKILL_BUDGET}) {t2_status}")
    print(f"  Tier 3 (References): {result['reference_tokens']:>6} tokens  (2000+ typical) {t3_status}")
    print(f"  Total:               {result['total_tokens']:>6} tokens")

    if result["warnings"]:
        print("  Issues:")
        for w in result["warnings"]:
            print(f"    - {w}")

    if verbose and result["files"]:
        print("  Files:")
        for f in result["files"]:
            print(f"    - {f['file']}: {f['tokens']} tokens ({f['type']})")


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)

    path = Path(sys.argv[1]).resolve()
    analyze_all = "--all" in sys.argv
    verbose = "-v" in sys.argv or "--verbose" in sys.argv
    output_json = "--json" in sys.argv

    print(f"Token Counter (method: {TOKEN_METHOD})")
    print("=" * 60)

    results = []

    if path.is_file():
        # Single file
        content = path.read_text()
        tokens = count_tokens(content)
        print(f"\nFile: {path}")
        print(f"Tokens: {tokens}")
        if output_json:
            print(json.dumps({"file": str(path), "tokens": tokens}))
        sys.exit(0)

    if (path / "SKILL.md").exists():
        # Single skill directory
        result = analyze_skill(path)
        results.append(result)
    elif analyze_all or (path / "skills").exists():
        # Plugin directory
        skills = find_skills(path)
        if not skills:
            print(f"No skills found in {path}")
            sys.exit(1)
        for skill_dir in sorted(skills):
            result = analyze_skill(skill_dir)
            results.append(result)
    else:
        print(f"Error: {path} is not a skill directory or plugin")
        sys.exit(1)

    if output_json:
        print(json.dumps(results, indent=2))
    else:
        for result in results:
            print_result(result, verbose)

        # Summary
        print("\n" + "=" * 60)
        print("Token Budget Validation Summary")
        print("=" * 60)
        total_skills = len(results)
        ok = sum(1 for r in results if r["status"] == "OK")
        warnings = sum(1 for r in results if r["status"] == "WARNING")
        critical = sum(1 for r in results if r["status"] in ["CRITICAL", "ERROR"])

        # Count skills above target but below warning threshold
        above_target = sum(1 for r in results if r["skill_tokens"] > SKILL_BUDGET and r["skill_tokens"] <= SKILL_WARNING)

        print(f"  Analyzed: {total_skills} skill(s)")
        print(f"  Within targets: {ok}")
        print(f"  Above target (acceptable): {above_target}")
        print(f"  Warnings: {warnings}")
        print(f"  Errors: {critical}")
        print()

        # Overall assessment and guidance
        if critical > 0:
            print("Result: Failed - Critical issues detected")
            print()
            print("Required Actions:")
            print("  1. Review skills with Error status above")
            print("  2. SKILL.md files exceeding 2500 tokens MUST be refactored")
            print("  3. Move detailed content to references/ subdirectory")
            print("  4. Keep only core instructions in SKILL.md")
            print("  5. Re-run validation after fixes")
            print()
            print("Context sizes >2500 tokens severely impact performance.")
            sys.exit(2)
        elif warnings > 0:
            print("Result: Attention Needed - Optimization recommended")
            print()
            print("Recommended Actions:")
            print("  1. Review skills with Warning status above")
            print("  2. SKILL.md files exceeding 800 tokens should be optimized")
            print("  3. Consider moving non-critical content to references/")
            print("  4. Ensure progressive disclosure is working effectively")
            print()
            print("Plugin is functional but optimization would improve performance.")
            sys.exit(1)
        elif above_target > 0:
            print("Result: Passed - Within acceptable range")
            print()
            print(f"{above_target} skill(s) exceed the ~500 token target but remain below")
            print("the 800 token warning threshold. This is acceptable when content")
            print("is essential for task execution.")
            print()
            print("Next Steps:")
            print("  - No action required - validation passed")
            print("  - Token budgets are within acceptable limits")
            print("  - Optional: Review if any content can be moved to references/")
        else:
            print("Result: Passed - All skills within optimal targets")
            print()
            print("All SKILL.md files are at or below the ~500 token target.")
            print("Progressive disclosure is working optimally.")
            print()
            print("Next Steps:")
            print("  - Validation passed successfully")
            print("  - No optimization needed")
            print("  - Ready to proceed")



if __name__ == "__main__":
    main()
