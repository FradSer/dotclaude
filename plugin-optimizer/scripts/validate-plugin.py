#!/usr/bin/env python3
"""
Consolidated plugin validator for Claude Code plugins.

Combines 5 validation checks into a single entry point:
- Structure validation (file patterns, naming conventions)
- Manifest validation (plugin.json required fields)
- Frontmatter validation (YAML frontmatter in components)
- Tool invocation validation (anti-pattern detection)
- Token budget validation (progressive disclosure)

Severity Levels:
- MUST: Absolute requirements - plugin will not function correctly
- SHOULD: Recommended practices - affects quality and maintainability
- MAY: Optional improvements - nice-to-have enhancements

Usage:
    python3 validate-plugin.py <plugin-path>                    # Run all validators
    python3 validate-plugin.py <plugin-path> --check=tokens     # Run specific validator
    python3 validate-plugin.py <plugin-path> --check=manifest,frontmatter
    python3 validate-plugin.py <plugin-path> --json             # JSON output
    python3 validate-plugin.py <plugin-path> -v                 # Verbose output

Exit codes:
    0 - Passed (no MUST violations, ready for Phase 2)
    1 - Failed (MUST violations detected, Phase 2 blocked)
    2 - Critical (token budget exceeded, MUST refactor)
"""

import argparse
import json
import re
import sys
from pathlib import Path
from dataclasses import dataclass, field
from typing import Optional

# Token budget thresholds (based on plugin-best-practices skill)
METADATA_BUDGET = 50      # ~50 tokens for description
METADATA_WARNING = 100
SKILL_BUDGET = 500        # ~500 tokens target for SKILL.md body
SKILL_WARNING = 800
SKILL_CRITICAL = 2500

# Try tiktoken for accurate counting
try:
    import tiktoken
    ENCODER = tiktoken.get_encoding("cl100k_base")
    def count_tokens(text: str) -> int:
        return len(ENCODER.encode(text))
    TOKEN_METHOD = "tiktoken"
except ImportError:
    def count_tokens(text: str) -> int:
        return len(text) // 4
    TOKEN_METHOD = "approximation"


@dataclass
class Issue:
    """Structured issue with location and source context."""
    severity: str           # "must", "should", "may", "ok"
    check: str              # Which validator found this
    message: str            # Brief issue description
    file: str = ""          # File path
    line: int = 0           # Line number (1-indexed)
    source: str = ""        # Original source text that caused issue
    suggestion: str = ""    # How to fix
    details: dict = field(default_factory=dict)  # Additional structured data


class ValidationResult:
    def __init__(self, check_name: str):
        self.check = check_name
        self.issues: list[Issue] = []
        self.passed = True

    def add(self, severity: str, message: str, file: str = "", line: int = 0,
            source: str = "", suggestion: str = "", **details):
        """Add an issue with full context."""
        issue = Issue(
            severity=severity,
            check=self.check,
            message=message,
            file=file,
            line=line,
            source=source,
            suggestion=suggestion,
            details=details
        )
        self.issues.append(issue)
        if severity == "must":
            self.passed = False

    def must(self, message: str, **kwargs):
        self.add("must", message, **kwargs)

    def should(self, message: str, **kwargs):
        self.add("should", message, **kwargs)

    def may(self, message: str, **kwargs):
        self.add("may", message, **kwargs)

    def ok(self, message: str, **kwargs):
        self.add("ok", message, **kwargs)


def parse_frontmatter(content: str) -> tuple[dict, str, int]:
    """Extract YAML frontmatter, body, and frontmatter end line from markdown.

    Returns:
        (frontmatter_dict, body_text, frontmatter_end_line)
    """
    if not content.startswith("---"):
        return {}, content, 0

    parts = content.split("---", 2)
    if len(parts) < 3:
        return {}, content, 0

    fm_text = parts[1].strip()
    body = parts[2].strip()

    # Calculate line number where frontmatter ends
    fm_end_line = content.count("\n", 0, content.find("---", 3) + 3) + 1

    frontmatter = {}
    current_key = None
    multiline_value = []

    for line in fm_text.split("\n"):
        if re.match(r'^[a-zA-Z_-]+:', line):
            if current_key and multiline_value:
                frontmatter[current_key] = " ".join(multiline_value)
                multiline_value = []

            key, _, value = line.partition(":")
            current_key = key.strip()
            value = value.strip().strip('"').strip("'")

            if value in ("|", ">"):
                multiline_value = []
            elif value:
                frontmatter[current_key] = value
                current_key = None
        elif current_key and (line.startswith("  ") or line.startswith("\t")):
            multiline_value.append(line.strip())

    if current_key and multiline_value:
        frontmatter[current_key] = " ".join(multiline_value)

    return frontmatter, body, fm_end_line


def find_components(plugin_dir: Path) -> dict[str, list[Path]]:
    """Find all component files in a plugin directory."""
    components = {"commands": [], "agents": [], "skills": []}

    cmd_dir = plugin_dir / "commands"
    if cmd_dir.exists():
        for f in cmd_dir.iterdir():
            if f.is_file() and f.suffix == ".md" and f.name != "README.md":
                components["commands"].append(f)

    agent_dir = plugin_dir / "agents"
    if agent_dir.exists():
        for f in agent_dir.iterdir():
            if f.is_file() and f.suffix == ".md" and f.name != "README.md":
                components["agents"].append(f)

    skills_dir = plugin_dir / "skills"
    if skills_dir.exists():
        for skill_dir in skills_dir.iterdir():
            if skill_dir.is_dir():
                skill_md = skill_dir / "SKILL.md"
                if skill_md.exists():
                    components["skills"].append(skill_md)

    return components


def get_relative_path(file_path: Path, plugin_dir: Path) -> str:
    """Get relative path from plugin directory."""
    try:
        return str(file_path.relative_to(plugin_dir))
    except ValueError:
        return str(file_path)


# =============================================================================
# Check: Structure
# =============================================================================

def check_structure(plugin_dir: Path, verbose: bool = False) -> ValidationResult:
    """Validate file patterns and directory structure."""
    result = ValidationResult("structure")

    manifest = plugin_dir / ".claude-plugin" / "plugin.json"
    if not manifest.exists():
        result.must(
            "plugin.json not found in .claude-plugin/",
            suggestion="Create .claude-plugin/plugin.json with required fields"
        )
    elif verbose:
        result.ok("plugin.json location correct", file=str(manifest))

    # Check for misplaced components
    claude_plugin = plugin_dir / ".claude-plugin"
    for name in ("commands", "agents", "skills"):
        misplaced = claude_plugin / name
        if misplaced.exists():
            result.must(
                f"{name}/ inside .claude-plugin/",
                file=str(misplaced),
                suggestion=f"Move to plugin root: {plugin_dir / name}"
            )

    # Check kebab-case naming
    components = find_components(plugin_dir)
    for comp_type, files in components.items():
        for f in files:
            name = f.parent.name if comp_type == "skills" else f.stem
            if not re.match(r'^[a-z0-9]+(-[a-z0-9]+)*$', name):
                result.should(
                    f"{comp_type.rstrip('s')} name not kebab-case",
                    file=get_relative_path(f, plugin_dir),
                    source=name,
                    suggestion="Use lowercase letters, numbers, hyphens only"
                )

    # Check skills have SKILL.md
    skills_dir = plugin_dir / "skills"
    if skills_dir.exists():
        for skill_dir in skills_dir.iterdir():
            if skill_dir.is_dir() and not (skill_dir / "SKILL.md").exists():
                result.must(
                    "Missing SKILL.md",
                    file=f"skills/{skill_dir.name}/",
                    suggestion="Create SKILL.md with frontmatter and content"
                )

    # Check for hardcoded paths in config files
    for config_file in ["hooks/hooks.json", ".mcp.json"]:
        config_path = plugin_dir / config_file
        if config_path.exists():
            content = config_path.read_text()
            lines = content.split("\n")
            for i, line in enumerate(lines, 1):
                if re.search(r'"/[^$].*\.(sh|py|js)"', line):
                    result.should(
                        "Hardcoded absolute path",
                        file=config_file,
                        line=i,
                        source=line.strip(),
                        suggestion="Use ${CLAUDE_PLUGIN_ROOT}/path/to/script"
                    )

    # Warn about generic directory names
    for generic in ("utils", "misc", "temp", "helpers"):
        if (plugin_dir / generic).exists():
            result.should(
                f"Generic directory name: {generic}/",
                suggestion="Use descriptive names like 'scripts/', 'references/'"
            )

    if not (plugin_dir / "README.md").exists():
        result.may("No README.md", suggestion="Add README.md for documentation")

    return result


# =============================================================================
# Check: Manifest
# =============================================================================

def check_manifest(plugin_dir: Path, verbose: bool = False) -> ValidationResult:
    """Validate plugin.json manifest structure and required fields."""
    result = ValidationResult("manifest")

    manifest_path = plugin_dir / ".claude-plugin" / "plugin.json"
    if not manifest_path.exists():
        result.must("plugin.json not found")
        return result

    try:
        content = manifest_path.read_text()
        manifest = json.loads(content)
    except json.JSONDecodeError as e:
        result.must(
            "Invalid JSON syntax",
            file=".claude-plugin/plugin.json",
            line=e.lineno if hasattr(e, 'lineno') else 0,
            source=str(e),
            suggestion="Fix JSON syntax error"
        )
        return result

    lines = content.split("\n")

    def find_key_line(key: str) -> int:
        for i, line in enumerate(lines, 1):
            if f'"{key}"' in line:
                return i
        return 0

    # Required: name
    if "name" not in manifest:
        result.must(
            "Missing 'name' field",
            file=".claude-plugin/plugin.json",
            suggestion='Add "name": "plugin-name"'
        )
    else:
        name = manifest["name"]
        line_num = find_key_line("name")
        if not re.match(r'^[a-z0-9]+(-[a-z0-9]+)*$', name):
            result.should(
                "Plugin name not kebab-case",
                file=".claude-plugin/plugin.json",
                line=line_num,
                source=f'"name": "{name}"',
                suggestion="Use lowercase letters, numbers, hyphens only"
            )
        elif verbose:
            result.ok(f"name: {name}", file=".claude-plugin/plugin.json", line=line_num)

    # Required: description
    if "description" not in manifest:
        result.should(
            "Missing 'description' field",
            file=".claude-plugin/plugin.json",
            suggestion='Add "description": "Brief plugin description"'
        )
    elif verbose:
        result.ok("description present", file=".claude-plugin/plugin.json")

    # Required: author.name
    if "author" not in manifest:
        result.must(
            "Missing 'author' field",
            file=".claude-plugin/plugin.json",
            suggestion='Add "author": {"name": "Your Name", "email": "email@example.com"}'
        )
    elif not isinstance(manifest["author"], dict) or "name" not in manifest["author"]:
        line_num = find_key_line("author")
        result.must(
            "Missing 'author.name' field",
            file=".claude-plugin/plugin.json",
            line=line_num,
            source=f'"author": {json.dumps(manifest.get("author"))}',
            suggestion='Use "author": {"name": "Your Name"}'
        )
    elif verbose:
        result.ok("author.name present", file=".claude-plugin/plugin.json")

    # Optional: version (semver)
    if "version" in manifest:
        version = manifest["version"]
        line_num = find_key_line("version")
        if not re.match(r'^\d+\.\d+\.\d+$', version):
            result.should(
                "Version not semver format",
                file=".claude-plugin/plugin.json",
                line=line_num,
                source=f'"version": "{version}"',
                suggestion="Use X.Y.Z format (e.g., 1.0.0)"
            )
        elif verbose:
            result.ok(f"version: {version}", file=".claude-plugin/plugin.json", line=line_num)
    else:
        result.may(
            "No 'version' field",
            file=".claude-plugin/plugin.json",
            suggestion='Add "version": "1.0.0" for release tracking'
        )

    # Optional: keywords
    if "keywords" not in manifest:
        result.may(
            "No 'keywords' field",
            file=".claude-plugin/plugin.json",
            suggestion='Add "keywords": ["keyword1", "keyword2"] for discoverability'
        )
    elif verbose:
        result.ok("keywords present", file=".claude-plugin/plugin.json")

    # Validate commands field
    if "commands" in manifest:
        commands = manifest["commands"]
        if not commands:
            result.must(
                "'commands' array is empty",
                file=".claude-plugin/plugin.json",
                suggestion="Add command paths or remove empty array"
            )
        else:
            for cmd_path in commands:
                if not re.match(r'^\./.*/$', cmd_path):
                    result.must(
                        f"Invalid path format: {cmd_path}",
                        file=".claude-plugin/plugin.json",
                        source=f'"commands": [..., "{cmd_path}", ...]',
                        suggestion="Use './path/' format with trailing slash"
                    )
                    continue

                clean_path = cmd_path.rstrip("/")
                full_path = plugin_dir / clean_path
                if not full_path.is_dir():
                    result.must(
                        f"Command path not found",
                        file=".claude-plugin/plugin.json",
                        source=f'"{cmd_path}"',
                        suggestion=f"Create directory {cmd_path}"
                    )
                elif not (full_path / "SKILL.md").exists():
                    result.must(
                        f"Missing SKILL.md in command",
                        file=cmd_path,
                        suggestion="Create SKILL.md with frontmatter"
                    )
                elif verbose:
                    result.ok(f"Verified: {cmd_path}", file=".claude-plugin/plugin.json")

            # Check for undeclared user-invocable skills
            skills_dir = plugin_dir / "skills"
            if skills_dir.exists():
                declared = set(commands)
                for skill_dir in skills_dir.iterdir():
                    if skill_dir.is_dir() and (skill_dir / "SKILL.md").exists():
                        skill_path = f"./skills/{skill_dir.name}/"
                        if skill_path not in declared:
                            content = (skill_dir / "SKILL.md").read_text()
                            fm, _, _ = parse_frontmatter(content)
                            if fm.get("user-invocable", "").lower() == "true":
                                result.must(
                                    "Undeclared user-invocable skill",
                                    file=f"skills/{skill_dir.name}/SKILL.md",
                                    source=f'user-invocable: true',
                                    suggestion=f'Add "{skill_path}" to "commands" array in plugin.json'
                                )

    return result


# =============================================================================
# Check: Frontmatter
# =============================================================================

def check_frontmatter(plugin_dir: Path, verbose: bool = False) -> ValidationResult:
    """Validate YAML frontmatter in component files."""
    result = ValidationResult("frontmatter")

    components = find_components(plugin_dir)

    for comp_type, files in components.items():
        for file_path in files:
            _validate_single_frontmatter(file_path, comp_type.rstrip("s"), result, plugin_dir, verbose)

    return result


def _validate_single_frontmatter(file_path: Path, comp_type: str, result: ValidationResult,
                                  plugin_dir: Path, verbose: bool):
    """Validate frontmatter for a single file."""
    content = file_path.read_text()
    lines = content.split("\n")
    rel_path = get_relative_path(file_path, plugin_dir)
    fm, body, fm_end_line = parse_frontmatter(content)

    if not fm:
        result.must(
            "No YAML frontmatter found",
            file=rel_path,
            line=1,
            suggestion="Add frontmatter block: ---\\nname: ...\\ndescription: ...\\n---"
        )
        return

    # Check for tabs in frontmatter
    for i, line in enumerate(lines, 1):
        if i <= fm_end_line and "\t" in line:
            result.must(
                "Tab character in YAML frontmatter",
                file=rel_path,
                line=i,
                source=line,
                suggestion="Replace tabs with spaces"
            )
            break

    def find_fm_key_line(key: str) -> int:
        for i, line in enumerate(lines, 1):
            if i <= fm_end_line and line.startswith(f"{key}:"):
                return i
        return 0

    # Type-specific validation
    if comp_type == "command":
        if "description" not in fm:
            result.must(
                "Missing 'description' in frontmatter",
                file=rel_path,
                suggestion='Add description: "Short description"'
            )
        elif verbose:
            result.ok(
                f'description: "{fm["description"]}"',
                file=rel_path,
                line=find_fm_key_line("description")
            )

        if "allowed-tools" in fm:
            allowed = fm["allowed-tools"]
            line_num = find_fm_key_line("allowed-tools")
            if "Bash" in allowed and "Bash(" not in allowed:
                result.must(
                    "Unrestricted Bash in allowed-tools",
                    file=rel_path,
                    line=line_num,
                    source=f'allowed-tools: {allowed}',
                    suggestion="Use filtered Bash: Bash(git:*), Bash(npm:*)"
                )

    elif comp_type == "agent":
        # Required: name
        if "name" not in fm:
            result.must(
                "Missing 'name' in frontmatter",
                file=rel_path,
                suggestion="Add name: agent-name (kebab-case, 3-50 chars)"
            )
        else:
            name = fm["name"]
            line_num = find_fm_key_line("name")
            if not re.match(r'^[a-z0-9]([a-z0-9-]{1,48}[a-z0-9])?$', name):
                result.must(
                    "Invalid agent name format",
                    file=rel_path,
                    line=line_num,
                    source=f'name: {name}',
                    suggestion="Use 3-50 chars, kebab-case, no leading/trailing hyphens"
                )
            elif verbose:
                result.ok(f'name: "{name}"', file=rel_path, line=line_num)

        if "description" not in fm:
            result.must(
                "Missing 'description' in frontmatter",
                file=rel_path,
                suggestion="Add description with trigger conditions and <example> blocks"
            )

        # Required: model
        if "model" not in fm:
            result.must(
                "Missing 'model' in frontmatter",
                file=rel_path,
                suggestion="Add model: inherit (or sonnet|opus|haiku)"
            )
        else:
            model = fm["model"]
            line_num = find_fm_key_line("model")
            if model not in ("inherit", "sonnet", "opus", "haiku"):
                result.must(
                    "Invalid model value",
                    file=rel_path,
                    line=line_num,
                    source=f'model: {model}',
                    suggestion="Use: inherit, sonnet, opus, or haiku"
                )
            elif verbose:
                result.ok(f'model: "{model}"', file=rel_path, line=line_num)

        # Required: color
        if "color" not in fm:
            result.must(
                "Missing 'color' in frontmatter",
                file=rel_path,
                suggestion="Add color: blue (or cyan|green|yellow|magenta|red)"
            )
        else:
            color = fm["color"]
            line_num = find_fm_key_line("color")
            valid_colors = ("blue", "cyan", "green", "yellow", "magenta", "red")
            if color not in valid_colors:
                result.must(
                    "Invalid color value",
                    file=rel_path,
                    line=line_num,
                    source=f'color: {color}',
                    suggestion=f"Use: {', '.join(valid_colors)}"
                )
            elif verbose:
                result.ok(f'color: "{color}"', file=rel_path, line=line_num)

    elif comp_type == "skill":
        if "name" not in fm:
            result.must(
                "Missing 'name' in frontmatter",
                file=rel_path,
                suggestion="Add name: skill-name (kebab-case)"
            )
        elif verbose:
            result.ok(f'name: "{fm["name"]}"', file=rel_path, line=find_fm_key_line("name"))

        if "description" not in fm:
            result.must(
                "Missing 'description' in frontmatter",
                file=rel_path,
                suggestion="Add description with trigger phrases"
            )
        else:
            desc = fm["description"]
            if len(desc.replace(" ", "")) < 10:
                result.should(
                    "Description too short",
                    file=rel_path,
                    line=find_fm_key_line("description"),
                    source=f'description: {desc}',
                    suggestion="Add more detail about when this skill should be used"
                )
            elif verbose:
                preview = desc[:50] + "..." if len(desc) > 50 else desc
                result.ok(f'description: "{preview}"', file=rel_path)

        # Check body for second-person patterns
        body_lines = body.split("\n")
        second_person_pattern = re.compile(r'\bYou (should|must|can|need to)\b')
        for i, line in enumerate(body_lines, 1):
            if second_person_pattern.search(line):
                actual_line = fm_end_line + i
                result.should(
                    "Second-person voice in skill body",
                    file=rel_path,
                    line=actual_line,
                    source=line.strip(),
                    suggestion="Use imperative form: 'Parse the file...' instead of 'You should...'"
                )


# =============================================================================
# Check: Tool Invocations
# =============================================================================

def check_tool_invocations(plugin_dir: Path, verbose: bool = False) -> ValidationResult:
    """Detect explicit tool call anti-patterns."""
    result = ValidationResult("tools")

    components = find_components(plugin_dir)
    all_files = components["commands"] + components["agents"] + components["skills"]

    # Anti-pattern regex
    core_tools = re.compile(r'(Use|Call|Using) (the )?(Read|Write|Glob|Grep|Edit) tool', re.IGNORECASE)
    bash_tool = re.compile(r'(Use|Call|Using) (the )?Bash tool', re.IGNORECASE)
    task_tool = re.compile(r'(Use|Call) (the )?Task tool to launch [a-z-]+', re.IGNORECASE)

    for file_path in all_files:
        content = file_path.read_text()
        lines = content.split("\n")
        rel_path = get_relative_path(file_path, plugin_dir)

        for i, line in enumerate(lines, 1):
            stripped = line.strip()
            if not stripped:
                continue

            if core_tools.search(line):
                result.should(
                    "Explicit core tool reference",
                    file=rel_path,
                    line=i,
                    source=stripped,
                    suggestion="Describe action directly: 'Find files...' not 'Use Glob tool...'"
                )

            if bash_tool.search(line) and "Bash(" not in line and "!`" not in line:
                result.should(
                    "Explicit Bash tool reference",
                    file=rel_path,
                    line=i,
                    source=stripped,
                    suggestion="Use: Run `command` or describe command directly"
                )

            if task_tool.search(line):
                result.should(
                    "Explicit Task tool reference",
                    file=rel_path,
                    line=i,
                    source=stripped,
                    suggestion="Use: Launch `agent-name` agent"
                )

        # Check frontmatter for unrestricted Bash
        fm, _, _ = parse_frontmatter(content)
        if "allowed-tools" in fm:
            allowed = fm["allowed-tools"]
            if isinstance(allowed, str) and "Bash" in allowed and "Bash(" not in allowed:
                result.must(
                    "Unrestricted Bash in allowed-tools",
                    file=rel_path,
                    source=f'allowed-tools: {allowed}',
                    suggestion="Use filtered: Bash(git:*), Bash(npm:*)"
                )

    return result


# =============================================================================
# Check: Tokens
# =============================================================================

def check_tokens(plugin_dir: Path, verbose: bool = False) -> ValidationResult:
    """Validate token budgets for progressive disclosure."""
    result = ValidationResult("tokens")

    skills_dir = plugin_dir / "skills"
    if not skills_dir.exists():
        result.may("No skills/ directory")
        return result

    skills = []
    for skill_dir in skills_dir.iterdir():
        if skill_dir.is_dir() and (skill_dir / "SKILL.md").exists():
            skills.append(skill_dir)

    if not skills:
        result.may("No skills found")
        return result

    for skill_dir in sorted(skills):
        skill_result = _analyze_skill_tokens(skill_dir)
        rel_path = f"skills/{skill_dir.name}/SKILL.md"

        meta = skill_result["metadata_tokens"]
        body = skill_result["skill_tokens"]
        refs = skill_result["reference_tokens"]
        excess = body - SKILL_BUDGET

        # Build details dict for structured output
        details = {
            "frontmatter": meta,
            "body": body,
            "refs": refs,
            "files": skill_result["files"]
        }

        if skill_result["status"] == "CRITICAL":
            result.must(
                f"Token budget exceeded: {body} tokens",
                file=rel_path,
                suggestion=f"MUST move {excess}+ tokens to references/",
                **details
            )
        elif skill_result["status"] == "WARNING":
            result.should(
                f"Token count high: {body} tokens",
                file=rel_path,
                suggestion=f"Move {excess}+ tokens to references/",
                **details
            )
        elif body > SKILL_BUDGET:
            result.may(
                f"Token count above target: {body} tokens",
                file=rel_path,
                suggestion=f"Consider moving {excess} tokens to references/",
                **details
            )
        elif verbose:
            result.ok(
                f"Token count OK: {body} tokens",
                file=rel_path,
                **details
            )

        # Additional verbose output for file breakdown
        if verbose:
            ref_files = [f for f in skill_result.get("files", []) if f["type"] == "reference"]
            script_files = [f for f in skill_result.get("files", []) if f["type"] == "script"]

            result.ok(f"  Frontmatter: {meta} tokens (target: ~{METADATA_BUDGET})")
            result.ok(f"  Body: {body} tokens (target: ~{SKILL_BUDGET})")
            result.ok(f"  References: {refs} tokens ({len(ref_files)} files)")
            for f in ref_files:
                result.ok(f"    - {f['file']}: {f['tokens']} tokens")
            if script_files:
                scripts = skill_result.get("script_tokens", 0)
                result.ok(f"  Scripts: {scripts} tokens ({len(script_files)} files)")
                for f in script_files:
                    result.ok(f"    - {f['file']}: {f['tokens']} tokens")
            result.ok(f"  Total: {skill_result['total_tokens']} tokens")

    return result


def _analyze_skill_tokens(skill_dir: Path) -> dict:
    """Analyze token usage for a single skill."""
    skill_md = skill_dir / "SKILL.md"
    content = skill_md.read_text()
    fm, body, _ = parse_frontmatter(content)

    description = fm.get("description", "")
    metadata_tokens = count_tokens(description)
    skill_tokens = count_tokens(body)

    reference_tokens = 0
    files = [{"file": "SKILL.md", "tokens": skill_tokens, "type": "skill"}]
    seen_files = set()

    ref_dir = skill_dir / "references"
    if ref_dir.exists():
        for f in ref_dir.glob("**/*.md"):
            abs_path = f.resolve()
            if abs_path not in seen_files:
                seen_files.add(abs_path)
                tokens = count_tokens(f.read_text())
                reference_tokens += tokens
                files.append({
                    "file": str(f.relative_to(skill_dir)),
                    "tokens": tokens,
                    "type": "reference"
                })

    for f in skill_dir.glob("*.md"):
        if f.name != "SKILL.md":
            abs_path = f.resolve()
            if abs_path not in seen_files:
                seen_files.add(abs_path)
                tokens = count_tokens(f.read_text())
                reference_tokens += tokens
                files.append({"file": f.name, "tokens": tokens, "type": "reference"})

    script_tokens = 0
    scripts_dir = skill_dir / "scripts"
    if scripts_dir.exists():
        for f in scripts_dir.glob("**/*"):
            if f.is_file() and f.suffix in [".py", ".sh", ".js", ".ts"]:
                tokens = count_tokens(f.read_text())
                script_tokens += tokens
                files.append({
                    "file": str(f.relative_to(skill_dir)),
                    "tokens": tokens,
                    "type": "script"
                })

    total_tokens = metadata_tokens + skill_tokens + reference_tokens + script_tokens

    status = "OK"
    if skill_tokens > SKILL_CRITICAL:
        status = "CRITICAL"
    elif skill_tokens > SKILL_WARNING:
        status = "WARNING"

    return {
        "status": status,
        "metadata_tokens": metadata_tokens,
        "skill_tokens": skill_tokens,
        "reference_tokens": reference_tokens,
        "script_tokens": script_tokens,
        "total_tokens": total_tokens,
        "files": files,
    }


# =============================================================================
# Output Formatting
# =============================================================================

CHECKS = {
    "structure": check_structure,
    "manifest": check_manifest,
    "frontmatter": check_frontmatter,
    "tools": check_tool_invocations,
    "tokens": check_tokens,
}

CHECK_ORDER = ["structure", "manifest", "frontmatter", "tools", "tokens"]


def run_all_checks(plugin_dir: Path, checks: list[str], verbose: bool = False) -> list[ValidationResult]:
    """Run specified validation checks in order."""
    results = []
    for check_name in CHECK_ORDER:
        if check_name in checks:
            result = CHECKS[check_name](plugin_dir, verbose)
            results.append(result)
    return results


def print_results(results: list[ValidationResult], plugin_dir: Path, verbose: bool = False):
    """Print validation results with structured formatting."""
    all_issues = {"must": [], "should": [], "may": [], "ok": []}

    for result in results:
        for issue in result.issues:
            all_issues[issue.severity].append(issue)

    # Header
    print("\n" + "=" * 70)
    print("PLUGIN VALIDATION REPORT")
    print("=" * 70)
    print(f"Target:  {plugin_dir}")
    print(f"Checks:  {', '.join(r.check for r in results)}")

    components = find_components(plugin_dir)
    print(f"\nComponents:")
    print(f"  Commands: {len(components['commands'])}")
    print(f"  Agents:   {len(components['agents'])}")
    print(f"  Skills:   {len(components['skills'])}")

    # Issues by severity
    def print_issue(issue: Issue, indent: str = ""):
        """Print a single issue with structured format."""
        # Location line
        loc = f"{issue.file}" if issue.file else "(no file)"
        if issue.line:
            loc += f":{issue.line}"
        print(f"{indent}┌─ {loc}")

        # Message
        print(f"{indent}│  Issue: {issue.message}")

        # Source text (if available)
        if issue.source:
            src = issue.source[:80] + "..." if len(issue.source) > 80 else issue.source
            print(f"{indent}│  Source: {src}")

        # Token details (if available)
        if issue.details.get("frontmatter") is not None:
            fm = issue.details["frontmatter"]
            body = issue.details["body"]
            refs = issue.details["refs"]
            print(f"{indent}│  Tokens: frontmatter={fm}, body={body}, refs={refs}")
            print(f"{indent}│  Target: frontmatter≈{METADATA_BUDGET}, body≈{SKILL_BUDGET}, refs≥2000")

        # Suggestion
        if issue.suggestion:
            print(f"{indent}│  Fix: {issue.suggestion}")

        print(f"{indent}└─")

    # MUST violations
    if all_issues["must"]:
        print(f"\n{'─' * 70}")
        print(f"[MUST] Critical Issues ({len(all_issues['must'])})")
        print(f"{'─' * 70}")
        for issue in all_issues["must"]:
            print_issue(issue, "  ")
        print("\n  ⚠ These issues MUST be fixed before proceeding.")

    # SHOULD violations
    if all_issues["should"]:
        print(f"\n{'─' * 70}")
        print(f"[SHOULD] Recommended Fixes ({len(all_issues['should'])})")
        print(f"{'─' * 70}")
        for issue in all_issues["should"]:
            print_issue(issue, "  ")
        print("\n  ℹ These issues SHOULD be addressed for quality.")

    # MAY improvements
    if all_issues["may"]:
        print(f"\n{'─' * 70}")
        print(f"[MAY] Optional Improvements ({len(all_issues['may'])})")
        print(f"{'─' * 70}")
        for issue in all_issues["may"]:
            print_issue(issue, "  ")

    # OK items (verbose only)
    if verbose and all_issues["ok"]:
        print(f"\n{'─' * 70}")
        print(f"[OK] Passing Checks ({len(all_issues['ok'])})")
        print(f"{'─' * 70}")
        for issue in all_issues["ok"]:
            msg = issue.message
            if issue.file:
                msg += f" ({issue.file}"
                if issue.line:
                    msg += f":{issue.line}"
                msg += ")"
            print(f"  ✓ {msg}")

    # Summary
    print(f"\n{'=' * 70}")
    print("SUMMARY")
    print(f"{'=' * 70}")
    print(f"  MUST violations:   {len(all_issues['must'])}")
    print(f"  SHOULD violations: {len(all_issues['should'])}")
    print(f"  MAY improvements:  {len(all_issues['may'])}")

    print(f"\n{'─' * 70}")
    if all_issues["must"]:
        print("Result: FAILED")
        print("\nPhase 2 Blocked: Fix all MUST violations and re-run validation.")
    elif all_issues["should"]:
        print("Result: PASSED (with recommendations)")
        print("\nPhase 2 Ready: Address SHOULD items during optimization.")
    else:
        print("Result: PASSED")
        print("\nPlugin follows best practices.")
        if all_issues["may"]:
            print(f"  {len(all_issues['may'])} optional improvement(s) noted.")


def output_json(results: list[ValidationResult], plugin_dir: Path):
    """Output results as JSON."""
    output = {
        "plugin": str(plugin_dir),
        "results": [],
        "summary": {"must": 0, "should": 0, "may": 0, "passed": True}
    }

    for result in results:
        check_output = {
            "check": result.check,
            "passed": result.passed,
            "issues": []
        }
        for i in result.issues:
            if i.severity == "ok":
                continue
            check_output["issues"].append({
                "severity": i.severity,
                "message": i.message,
                "file": i.file,
                "line": i.line,
                "source": i.source,
                "suggestion": i.suggestion,
                "details": i.details if i.details else None
            })
            output["summary"][i.severity] = output["summary"].get(i.severity, 0) + 1
            if i.severity == "must":
                output["summary"]["passed"] = False

        output["results"].append(check_output)

    print(json.dumps(output, indent=2, default=str))


def main():
    parser = argparse.ArgumentParser(
        description="Validate Claude Code plugin structure and content",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__
    )
    parser.add_argument("plugin_path", help="Path to plugin directory")
    parser.add_argument(
        "--check",
        help="Comma-separated checks (structure,manifest,frontmatter,tools,tokens) or 'all'",
        default="all"
    )
    parser.add_argument("--json", action="store_true", help="Output as JSON")
    parser.add_argument("-v", "--verbose", action="store_true", help="Verbose output")

    args = parser.parse_args()

    plugin_dir = Path(args.plugin_path).resolve()
    if not plugin_dir.exists():
        print(f"Error: Plugin directory not found: {plugin_dir}")
        sys.exit(1)
    if not plugin_dir.is_dir():
        print(f"Error: Path is not a directory: {plugin_dir}")
        sys.exit(1)

    if args.check == "all":
        checks = CHECK_ORDER
    else:
        checks = [c.strip() for c in args.check.split(",")]
        invalid = [c for c in checks if c not in CHECKS]
        if invalid:
            print(f"Error: Unknown checks: {', '.join(invalid)}")
            print(f"Available: {', '.join(CHECK_ORDER)}")
            sys.exit(1)

    if not args.json:
        print("Plugin Validator")
        if "tokens" in checks:
            print(f"Token method: {TOKEN_METHOD}")

    results = run_all_checks(plugin_dir, checks, args.verbose)

    if args.json:
        output_json(results, plugin_dir)
    else:
        print_results(results, plugin_dir, args.verbose)

    # Exit codes
    has_critical = any(r.check == "tokens" and not r.passed for r in results)
    has_must = any(not r.passed for r in results)

    if has_critical:
        sys.exit(2)
    elif has_must:
        sys.exit(1)
    else:
        sys.exit(0)


if __name__ == "__main__":
    main()
