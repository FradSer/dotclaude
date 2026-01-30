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
from typing import NamedTuple

# Token budget thresholds
METADATA_BUDGET = 50
METADATA_WARNING = 100
SKILL_BUDGET = 500
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


# Severity Levels
# MUST/MUST NOT → Critical violations that block proceeding (exit code 1/2)
# SHOULD/SHOULD NOT → Recommended fixes for quality (warnings)
# MAY → Optional improvements (info)
# OK → Passing checks (verbose confirmations, not counted as issues)

class Issue(NamedTuple):
    severity: str  # "must", "should", "may", "ok"
    check: str     # Which validator found this
    message: str
    file: str = ""
    line: int = 0


class ValidationResult:
    def __init__(self, check_name: str):
        self.check = check_name
        self.issues: list[Issue] = []
        self.passed = True

    def must(self, msg: str, file: str = "", line: int = 0):
        """MUST violation - absolute requirement not met."""
        self.issues.append(Issue("must", self.check, msg, file, line))
        self.passed = False

    def should(self, msg: str, file: str = "", line: int = 0):
        """SHOULD violation - recommended practice not followed."""
        self.issues.append(Issue("should", self.check, msg, file, line))

    def may(self, msg: str, file: str = "", line: int = 0):
        """MAY - optional improvement suggestion."""
        self.issues.append(Issue("may", self.check, msg, file, line))

    def ok(self, msg: str, file: str = "", line: int = 0):
        """OK - passing check confirmation (verbose only)."""
        self.issues.append(Issue("ok", self.check, msg, file, line))

    # Aliases for backwards compatibility
    def error(self, msg: str, file: str = "", line: int = 0):
        self.must(msg, file, line)

    def warning(self, msg: str, file: str = "", line: int = 0):
        self.should(msg, file, line)

    def info(self, msg: str, file: str = "", line: int = 0):
        self.may(msg, file, line)


def parse_frontmatter(content: str) -> tuple[dict, str]:
    """Extract YAML frontmatter and body from markdown content."""
    if not content.startswith("---"):
        return {}, content

    parts = content.split("---", 2)
    if len(parts) < 3:
        return {}, content

    fm_text = parts[1].strip()
    body = parts[2].strip()

    frontmatter = {}
    current_key = None
    multiline_value = []

    for line in fm_text.split("\n"):
        # Check for new key
        if re.match(r'^[a-zA-Z_-]+:', line):
            # Save previous multiline value
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

    # Handle final multiline value
    if current_key and multiline_value:
        frontmatter[current_key] = " ".join(multiline_value)

    return frontmatter, body


def find_components(plugin_dir: Path) -> dict[str, list[Path]]:
    """Find all component files in a plugin directory."""
    components = {"commands": [], "agents": [], "skills": []}

    # Commands: commands/*.md (maxdepth 1)
    cmd_dir = plugin_dir / "commands"
    if cmd_dir.exists():
        for f in cmd_dir.iterdir():
            if f.is_file() and f.suffix == ".md" and f.name != "README.md":
                components["commands"].append(f)

    # Agents: agents/*.md (maxdepth 1)
    agent_dir = plugin_dir / "agents"
    if agent_dir.exists():
        for f in agent_dir.iterdir():
            if f.is_file() and f.suffix == ".md" and f.name != "README.md":
                components["agents"].append(f)

    # Skills: skills/*/SKILL.md (mindepth 2, maxdepth 2)
    skills_dir = plugin_dir / "skills"
    if skills_dir.exists():
        for skill_dir in skills_dir.iterdir():
            if skill_dir.is_dir():
                skill_md = skill_dir / "SKILL.md"
                if skill_md.exists():
                    components["skills"].append(skill_md)

    return components


# =============================================================================
# Check: Structure (from validate-file-patterns.sh)
# =============================================================================

def check_structure(plugin_dir: Path, verbose: bool = False) -> ValidationResult:
    """Validate file patterns and directory structure."""
    result = ValidationResult("structure")

    # Check manifest location
    manifest = plugin_dir / ".claude-plugin" / "plugin.json"
    if not manifest.exists():
        result.must("plugin.json not in .claude-plugin/ directory")
    elif verbose:
        result.ok("plugin.json in correct location")

    # Check for misplaced components
    claude_plugin = plugin_dir / ".claude-plugin"
    for name in ("commands", "agents", "skills"):
        if (claude_plugin / name).exists():
            result.must(f"{name}/ inside .claude-plugin/ (move to plugin root)")

    # Check kebab-case naming
    components = find_components(plugin_dir)

    for comp_type, files in components.items():
        for f in files:
            if comp_type == "skills":
                name = f.parent.name
            else:
                name = f.stem
            if not re.match(r'^[a-z0-9]+(-[a-z0-9]+)*$', name):
                result.should(f"{comp_type.rstrip('s')} name not kebab-case: {name}", str(f))

    # Check skills have SKILL.md
    skills_dir = plugin_dir / "skills"
    if skills_dir.exists():
        for skill_dir in skills_dir.iterdir():
            if skill_dir.is_dir() and not (skill_dir / "SKILL.md").exists():
                result.must(f"Missing SKILL.md in skills/{skill_dir.name}/")

    # Check for portable paths in hooks.json and .mcp.json
    for config_file in ["hooks/hooks.json", ".mcp.json"]:
        config_path = plugin_dir / config_file
        if config_path.exists():
            content = config_path.read_text()
            if re.search(r'"/[^$].*\.(sh|py|js)"', content):
                result.should(f"Hardcoded paths in {config_file} (use ${{CLAUDE_PLUGIN_ROOT}})")

    # Check for large SKILL.md files
    for skill_md in components["skills"]:
        size = skill_md.stat().st_size
        if size > 30000:
            result.should("SKILL.md >30KB (use references/ for progressive disclosure)", str(skill_md))

    # Warn about generic directory names
    for generic in ("utils", "misc", "temp", "helpers"):
        if (plugin_dir / generic).exists():
            result.should(f"Generic directory name: {generic}/")

    # Info about README
    if not (plugin_dir / "README.md").exists():
        result.may("Add README.md for documentation")

    return result


# =============================================================================
# Check: Manifest (from validate-plugin-json.sh)
# =============================================================================

def check_manifest(plugin_dir: Path, verbose: bool = False) -> ValidationResult:
    """Validate plugin.json manifest structure and required fields."""
    result = ValidationResult("manifest")

    manifest_path = plugin_dir / ".claude-plugin" / "plugin.json"
    if not manifest_path.exists():
        result.must(f"plugin.json not found")
        return result

    try:
        content = manifest_path.read_text()
        manifest = json.loads(content)
    except json.JSONDecodeError as e:
        result.must(f"Invalid JSON: {e}")
        return result

    # Required: name
    if "name" not in manifest:
        result.must("Missing 'name' field")
    else:
        name = manifest["name"]
        if not re.match(r'^[a-z0-9]+(-[a-z0-9]+)*$', name):
            result.should(f"Name '{name}' not kebab-case")
        elif verbose:
            result.ok(f"name: {name}")

    # Required: description
    if "description" not in manifest:
        result.should("Missing 'description' field")
    elif verbose:
        result.ok("description present")

    # Required: author.name
    if "author" not in manifest:
        result.must("Missing 'author' field")
    elif not isinstance(manifest["author"], dict) or "name" not in manifest["author"]:
        result.must("Missing 'author.name' field")
    elif verbose:
        result.ok("author.name present")

    # Optional: version (semver)
    if "version" in manifest:
        version = manifest["version"]
        if not re.match(r'^\d+\.\d+\.\d+$', version):
            result.should(f"Version '{version}' not semver (X.Y.Z)")
        elif verbose:
            result.ok(f"version: {version}")
    else:
        result.may("Add 'version' field for release tracking")

    # Optional: keywords
    if "keywords" not in manifest:
        result.may("Add 'keywords' for discoverability")
    elif verbose:
        result.ok("keywords present")

    # Validate commands field
    if "commands" in manifest:
        commands = manifest["commands"]
        if not commands:
            result.must("'commands' array is empty")
        else:
            for cmd_path in commands:
                # Check format: must start with ./ and end with /
                if not re.match(r'^\./.*/$', cmd_path):
                    result.must(f"Invalid path format: {cmd_path} (use './path/')")
                    continue

                # Check directory exists
                clean_path = cmd_path.rstrip("/")
                full_path = plugin_dir / clean_path
                if not full_path.is_dir():
                    result.must(f"Path not found: {cmd_path}")
                elif not (full_path / "SKILL.md").exists():
                    result.must(f"Missing SKILL.md in {cmd_path}")
                elif verbose:
                    result.ok(f"Verified: {cmd_path}")

            # Check for undeclared user-invocable skills
            skills_dir = plugin_dir / "skills"
            if skills_dir.exists():
                declared = set(commands)
                for skill_dir in skills_dir.iterdir():
                    if skill_dir.is_dir() and (skill_dir / "SKILL.md").exists():
                        skill_path = f"./skills/{skill_dir.name}/"
                        if skill_path not in declared:
                            # Check if user-invocable
                            content = (skill_dir / "SKILL.md").read_text()
                            fm, _ = parse_frontmatter(content)
                            if fm.get("user-invocable", "").lower() == "true":
                                result.must(f"Undeclared user-invocable skill: {skill_path}")

    return result


# =============================================================================
# Check: Frontmatter (from validate-frontmatter.sh)
# =============================================================================

def check_frontmatter(plugin_dir: Path, verbose: bool = False) -> ValidationResult:
    """Validate YAML frontmatter in component files."""
    result = ValidationResult("frontmatter")

    components = find_components(plugin_dir)

    for comp_type, files in components.items():
        for file_path in files:
            _validate_single_frontmatter(file_path, comp_type.rstrip("s"), result, verbose)

    return result


def _validate_single_frontmatter(file_path: Path, comp_type: str, result: ValidationResult, verbose: bool):
    """Validate frontmatter for a single file."""
    content = file_path.read_text()
    lines = content.split("\n")
    fm, body = parse_frontmatter(content)

    if not fm:
        result.must(
            f"No YAML frontmatter found\n"
            f"    Issue: Component file MUST have YAML frontmatter (--- delimited block at start)\n"
            f"    Suggestion: Add frontmatter with required fields",
            str(file_path)
        )
        return

    # Check for tabs in frontmatter
    if "---" in content:
        fm_section = content.split("---")[1] if len(content.split("---")) > 1 else ""
        if "\t" in fm_section:
            # Find line with tab
            for i, line in enumerate(lines, 1):
                if "\t" in line and i < lines.index("---", 1) + 1 if "---" in lines[1:] else 999:
                    result.must(
                        f"Line {i}: \"{line}\"\n"
                        f"    Issue: YAML MUST NOT use tabs for indentation\n"
                        f"    Suggestion: Replace tabs with spaces",
                        str(file_path), i
                    )
                    break

    # Type-specific validation
    if comp_type == "command":
        if "description" not in fm:
            result.must(
                f"Missing 'description' field in frontmatter\n"
                f"    Issue: Command MUST have 'description' field\n"
                f"    Suggestion: Add description: \"Short description of what this command does\"",
                str(file_path)
            )
        elif verbose:
            result.ok(f"description: \"{fm['description']}\"", str(file_path))

        # Check allowed-tools for unrestricted Bash
        if "allowed-tools" in fm:
            allowed = fm["allowed-tools"]
            if "Bash" in allowed and "Bash(" not in allowed:
                result.must(
                    f"allowed-tools contains unrestricted Bash: \"{allowed}\"\n"
                    f"    Issue: MUST NOT use bare 'Bash' in allowed-tools\n"
                    f"    Suggestion: Use filtered Bash like Bash(git:*), Bash(npm:*)",
                    str(file_path)
                )

    elif comp_type == "agent":
        # Required: name
        if "name" not in fm:
            result.must(
                f"Missing 'name' field in frontmatter\n"
                f"    Issue: Agent MUST have 'name' field\n"
                f"    Suggestion: Add name: agent-name (kebab-case, 3-50 chars)",
                str(file_path)
            )
        else:
            name = fm["name"]
            if not re.match(r'^[a-z0-9]([a-z0-9-]{1,48}[a-z0-9])?$', name):
                result.must(
                    f"Invalid name: \"{name}\"\n"
                    f"    Issue: Agent name MUST be 3-50 chars, kebab-case, no leading/trailing hyphens\n"
                    f"    Suggestion: Use lowercase letters, numbers, and hyphens only",
                    str(file_path)
                )
            elif verbose:
                result.ok(f"name: \"{name}\"", str(file_path))

        # Required: description
        if "description" not in fm:
            result.must(
                f"Missing 'description' field in frontmatter\n"
                f"    Issue: Agent MUST have 'description' field\n"
                f"    Suggestion: Add description with trigger conditions and examples",
                str(file_path)
            )

        # Required: model
        if "model" not in fm:
            result.must(
                f"Missing 'model' field in frontmatter\n"
                f"    Issue: Agent MUST have 'model' field\n"
                f"    Suggestion: Add model: inherit (or sonnet|opus|haiku)",
                str(file_path)
            )
        else:
            model = fm["model"]
            if model not in ("inherit", "sonnet", "opus", "haiku"):
                result.must(
                    f"Invalid model: \"{model}\"\n"
                    f"    Issue: Model MUST be one of: inherit, sonnet, opus, haiku\n"
                    f"    Suggestion: Use 'inherit' to use parent model, or specify explicitly",
                    str(file_path)
                )
            elif verbose:
                result.ok(f"model: \"{model}\"", str(file_path))

        # Required: color
        if "color" not in fm:
            result.must(
                f"Missing 'color' field in frontmatter\n"
                f"    Issue: Agent MUST have 'color' field\n"
                f"    Suggestion: Add color: blue (or cyan|green|yellow|magenta|red)",
                str(file_path)
            )
        else:
            color = fm["color"]
            if color not in ("blue", "cyan", "green", "yellow", "magenta", "red"):
                result.must(
                    f"Invalid color: \"{color}\"\n"
                    f"    Issue: Color MUST be one of: blue, cyan, green, yellow, magenta, red\n"
                    f"    Suggestion: Choose a color that reflects the agent's purpose",
                    str(file_path)
                )
            elif verbose:
                result.ok(f"color: \"{color}\"", str(file_path))

    elif comp_type == "skill":
        # Required: name
        if "name" not in fm:
            result.must(
                f"Missing 'name' field in frontmatter\n"
                f"    Issue: Skill MUST have 'name' field\n"
                f"    Suggestion: Add name: skill-name (kebab-case)",
                str(file_path)
            )
        elif verbose:
            result.ok(f"name: \"{fm['name']}\"", str(file_path))

        # Required: description
        if "description" not in fm:
            result.must(
                f"Missing 'description' field in frontmatter\n"
                f"    Issue: Skill MUST have 'description' field\n"
                f"    Suggestion: Add description with trigger phrases",
                str(file_path)
            )
        else:
            desc = fm["description"]
            if len(desc.replace(" ", "")) < 10:
                result.should(
                    f"Description too short: \"{desc}\"\n"
                    f"    Issue: Description SHOULD be at least 10 characters\n"
                    f"    Suggestion: Add more detail about when this skill should be used",
                    str(file_path)
                )
            elif verbose:
                result.ok(f"description: \"{desc[:50]}...\"" if len(desc) > 50 else f"description: \"{desc}\"", str(file_path))

        # Check body for second-person patterns
        body_lines = body.split("\n")
        second_person_pattern = re.compile(r'\bYou (should|must|can|need to)\b')
        for i, line in enumerate(body_lines, 1):
            if second_person_pattern.search(line):
                # Calculate actual line number in file (after frontmatter)
                fm_end_line = content.count("\n", 0, content.find("---", 3) + 3) + 1 if "---" in content[3:] else 0
                actual_line = fm_end_line + i
                result.should(
                    f"Line {actual_line}: \"{line.strip()}\"\n"
                    f"    Issue: Skill body SHOULD use imperative form, not second person\n"
                    f"    Suggestion: Change 'You should...' to direct imperative like 'Parse the file...'",
                    str(file_path), actual_line
                )


# =============================================================================
# Check: Tool Invocations (from check-tool-invocations.sh)
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

        for i, line in enumerate(lines, 1):
            stripped = line.strip()
            if not stripped:
                continue

            # Core tools
            if core_tools.search(line):
                result.should(
                    f"Line {i}: \"{stripped}\"\n"
                    f"    Issue: SHOULD NOT explicitly mention core tools (Read/Write/Glob/Grep/Edit)\n"
                    f"    Suggestion: Describe the action directly without mentioning tool names",
                    str(file_path), i
                )

            # Bash tool (exclude allowed patterns)
            if bash_tool.search(line) and "Bash(" not in line and "!`" not in line:
                result.should(
                    f"Line {i}: \"{stripped}\"\n"
                    f"    Issue: SHOULD NOT explicitly mention Bash tool\n"
                    f"    Suggestion: Use inline execution `command` or describe the command directly",
                    str(file_path), i
                )

            # Task tool specific pattern
            if task_tool.search(line):
                result.should(
                    f"Line {i}: \"{stripped}\"\n"
                    f"    Issue: SHOULD NOT use 'Use Task tool to launch'\n"
                    f"    Suggestion: Use 'Launch [agent-name] agent' instead",
                    str(file_path), i
                )

        # Check frontmatter for unrestricted Bash
        fm, _ = parse_frontmatter(content)
        if "allowed-tools" in fm:
            allowed = fm["allowed-tools"]
            if isinstance(allowed, str) and "Bash" in allowed and "Bash(" not in allowed:
                result.must(
                    f"Unrestricted Bash in allowed-tools: \"{allowed}\"\n"
                    f"    Issue: MUST NOT use bare 'Bash' in allowed-tools\n"
                    f"    Suggestion: Use filtered Bash like Bash(git:*), Bash(npm:*)",
                    str(file_path)
                )

    return result


# =============================================================================
# Check: Tokens (from count-tokens.py)
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

    critical_count = 0
    warning_count = 0

    for skill_dir in sorted(skills):
        skill_result = _analyze_skill_tokens(skill_dir, verbose)

        if skill_result["status"] == "CRITICAL":
            critical_count += 1
            result.must(
                f"{skill_dir.name}: {skill_result['skill_tokens']} tokens (limit: {SKILL_CRITICAL}, refactor to references/)",
                str(skill_dir / "SKILL.md")
            )
        elif skill_result["status"] == "WARNING":
            warning_count += 1
            result.should(
                f"{skill_dir.name}: {skill_result['skill_tokens']} tokens (threshold: {SKILL_WARNING})",
                str(skill_dir / "SKILL.md")
            )

        # Show detailed breakdown in verbose mode
        if verbose:
            meta = skill_result["metadata_tokens"]
            body = skill_result["skill_tokens"]
            refs = skill_result["reference_tokens"]
            scripts = skill_result.get("script_tokens", 0)
            total = skill_result["total_tokens"]

            # Count files by type
            ref_files = [f for f in skill_result.get("files", []) if f["type"] == "reference"]
            script_files = [f for f in skill_result.get("files", []) if f["type"] == "script"]

            # Determine status message
            if body > SKILL_CRITICAL:
                status_msg = f"MUST refactor: body {body} tokens exceeds {SKILL_CRITICAL} limit"
            elif body > SKILL_WARNING:
                status_msg = f"SHOULD optimize: body {body} tokens exceeds {SKILL_WARNING} threshold"
            elif body > SKILL_BUDGET:
                status_msg = f"MAY optimize: body {body} tokens exceeds ~{SKILL_BUDGET} target"
            else:
                status_msg = f"OK: body {body} tokens within ~{SKILL_BUDGET} target"

            result.ok(f"Skill: {skill_dir.name}")
            result.ok(f"  Metadata (description): {meta} tokens")
            result.ok(f"  Body (SKILL.md excluding frontmatter): {body} tokens")
            result.ok(f"  References: {refs} tokens ({len(ref_files)} files)")
            for f in ref_files:
                result.ok(f"    - {f['file']}: {f['tokens']} tokens")
            result.ok(f"  Scripts: {scripts} tokens ({len(script_files)} files)")
            for f in script_files:
                result.ok(f"    - {f['file']}: {f['tokens']} tokens")
            result.ok(f"  Total: {total} tokens")
            result.ok(f"  Status: {status_msg}")

        # Info for above-target skills (non-verbose)
        if not verbose and skill_result["status"] == "OK":
            for w in skill_result.get("warnings", []):
                if "above" in w.lower() and "target" in w.lower():
                    result.may(
                        f"{skill_dir.name}: {skill_result['skill_tokens']} tokens (target: ~500)",
                        str(skill_dir / "SKILL.md")
                    )
                    break

    if critical_count > 0:
        result.passed = False

    return result


def _analyze_skill_tokens(skill_dir: Path, verbose: bool) -> dict:
    """Analyze token usage for a single skill."""
    skill_md = skill_dir / "SKILL.md"
    content = skill_md.read_text()
    fm, body = parse_frontmatter(content)

    # Metadata (description field)
    description = fm.get("description", "")
    metadata_tokens = count_tokens(description)

    # SKILL.md body
    skill_tokens = count_tokens(body)

    # Reference files
    reference_tokens = 0
    files = [{"file": "SKILL.md", "tokens": skill_tokens, "type": "skill"}]
    seen_files = set()

    # Count references/*.md
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

    # Count *.md in skill root (except SKILL.md)
    for f in skill_dir.glob("*.md"):
        if f.name != "SKILL.md":
            abs_path = f.resolve()
            if abs_path not in seen_files:
                seen_files.add(abs_path)
                tokens = count_tokens(f.read_text())
                reference_tokens += tokens
                files.append({
                    "file": f.name,
                    "tokens": tokens,
                    "type": "reference"
                })

    # Count script files in scripts/
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

    # Determine status
    status = "OK"
    warnings = []

    if skill_tokens > SKILL_CRITICAL:
        status = "CRITICAL"
        warnings.append(f"SKILL.md body: {skill_tokens} tokens critically exceeds {SKILL_CRITICAL} limit, must refactor content to references/")
    elif skill_tokens > SKILL_WARNING:
        status = "WARNING"
        warnings.append(f"SKILL.md body: {skill_tokens} tokens exceeds {SKILL_WARNING} warning threshold, consider moving content to references/")
    elif skill_tokens > SKILL_BUDGET:
        warnings.append(f"SKILL.md body: {skill_tokens} tokens above {SKILL_BUDGET} target")

    if metadata_tokens > METADATA_WARNING:
        warnings.append(f"Metadata description: {metadata_tokens} tokens exceeds ~{METADATA_BUDGET} recommended budget")

    return {
        "status": status,
        "metadata_tokens": metadata_tokens,
        "skill_tokens": skill_tokens,
        "reference_tokens": reference_tokens,
        "script_tokens": script_tokens,
        "total_tokens": total_tokens,
        "files": files,
        "warnings": warnings,
    }


# =============================================================================
# Main orchestrator
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
            check_fn = CHECKS[check_name]
            result = check_fn(plugin_dir, verbose)
            results.append(result)
    return results


def print_results(results: list[ValidationResult], plugin_dir: Path, verbose: bool = False):
    """Print validation results with MUST/SHOULD/MAY severity levels."""
    total_must = 0
    total_should = 0
    total_may = 0

    # Group all issues by severity for phase-aligned output
    all_must = []
    all_should = []
    all_may = []
    all_ok = []

    for result in results:
        for issue in result.issues:
            if issue.severity == "must":
                all_must.append(issue)
                total_must += 1
            elif issue.severity == "should":
                all_should.append(issue)
                total_should += 1
            elif issue.severity == "may":
                all_may.append(issue)
                total_may += 1
            elif issue.severity == "ok":
                all_ok.append(issue)

    # Phase 1 Output: Discovery & Validation Results
    print("\n" + "=" * 60)
    print("Phase 1: Discovery & Validation")
    print("=" * 60)
    print(f"Target: {plugin_dir}")
    print(f"Checks: {', '.join(r.check for r in results)}")

    # Component inventory
    components = find_components(plugin_dir)
    print(f"\nComponents Found:")
    print(f"  Commands: {len(components['commands'])}")
    print(f"  Agents:   {len(components['agents'])}")
    print(f"  Skills:   {len(components['skills'])}")

    # MUST violations (Critical - blocks proceeding)
    if all_must:
        print(f"\n[MUST] Critical Issues ({len(all_must)})")
        print("-" * 40)
        for issue in all_must:
            loc = _format_location(issue)
            print(f"  {issue.message}{loc}")
        print("\n  These issues MUST be fixed before proceeding to Phase 2.")

    # SHOULD violations (Recommended fixes)
    if all_should:
        print(f"\n[SHOULD] Recommended Fixes ({len(all_should)})")
        print("-" * 40)
        for issue in all_should:
            loc = _format_location(issue)
            print(f"  {issue.message}{loc}")
        print("\n  These issues SHOULD be addressed for quality.")

    # MAY items (Optional improvements - always show if present)
    if all_may:
        print(f"\n[MAY] Optional Improvements ({len(all_may)})")
        print("-" * 40)
        for issue in all_may:
            loc = _format_location(issue)
            print(f"  {issue.message}{loc}")

    # OK items (Verbose confirmations only)
    if verbose and all_ok:
        print(f"\n[OK] Passing Checks ({len(all_ok)})")
        print("-" * 40)
        for issue in all_ok:
            loc = _format_location(issue)
            print(f"  {issue.message}{loc}")

    # Summary aligned with SKILL.md workflow
    print("\n" + "=" * 60)
    print("Validation Summary")
    print("=" * 60)
    print(f"  MUST violations:   {total_must}")
    print(f"  SHOULD violations: {total_should}")
    print(f"  MAY improvements:  {total_may}")

    # Phase transition guidance
    print("\n" + "-" * 60)
    if total_must > 0:
        print("Result: FAILED")
        print("\nPhase 2 Blocked: MUST violations detected.")
        print("Required Actions:")
        print("  1. Fix all MUST violations listed above")
        print("  2. Re-run validation to verify fixes")
        print("  3. Proceed to Phase 2 only after MUST count reaches 0")
    elif total_should > 0:
        print("Result: PASSED (with recommendations)")
        print("\nPhase 2 Ready: No MUST violations.")
        print("Recommendations:")
        print("  - Address SHOULD items during Phase 2 optimization")
        print("  - Launch plugin-optimizer agent with issue list")
    else:
        print("Result: PASSED")
        print("\nPhase 2 Assessment: No critical issues detected.")
        if total_may > 0:
            print(f"  {total_may} optional improvement(s) noted")
        print("  Plugin structure follows best practices.")


def _format_location(issue: Issue) -> str:
    """Format file location for display."""
    if not issue.file:
        return ""
    loc = f"\n    → {issue.file}"
    if issue.line:
        loc += f":{issue.line}"
    return loc


def output_json(results: list[ValidationResult], plugin_dir: Path):
    """Output results as JSON with severity levels."""
    output = {
        "plugin": str(plugin_dir),
        "results": [],
        "summary": {
            "must": 0,
            "should": 0,
            "may": 0,
            "passed": True,
            "phase2_ready": True
        }
    }

    for result in results:
        check_output = {
            "check": result.check,
            "passed": result.passed,
            "issues": [
                {
                    "severity": i.severity,
                    "message": i.message,
                    "file": i.file,
                    "line": i.line,
                }
                for i in result.issues
                if i.severity != "ok"  # Exclude OK confirmations from JSON
            ]
        }
        output["results"].append(check_output)

        for i in result.issues:
            if i.severity == "must":
                output["summary"]["must"] += 1
                output["summary"]["passed"] = False
                output["summary"]["phase2_ready"] = False
            elif i.severity == "should":
                output["summary"]["should"] += 1
            elif i.severity == "may":
                output["summary"]["may"] += 1

    print(json.dumps(output, indent=2))


def main():
    parser = argparse.ArgumentParser(
        description="Validate Claude Code plugin structure and content",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__
    )
    parser.add_argument("plugin_path", help="Path to plugin directory")
    parser.add_argument(
        "--check",
        help="Comma-separated list of checks to run (structure,manifest,frontmatter,tools,tokens) or 'all'",
        default="all"
    )
    parser.add_argument("--json", action="store_true", help="Output results as JSON")
    parser.add_argument("-v", "--verbose", action="store_true", help="Verbose output")

    args = parser.parse_args()

    # Resolve plugin path
    plugin_dir = Path(args.plugin_path).resolve()
    if not plugin_dir.exists():
        print(f"Error: Plugin directory not found: {plugin_dir}")
        sys.exit(1)
    if not plugin_dir.is_dir():
        print(f"Error: Path is not a directory: {plugin_dir}")
        sys.exit(1)

    # Parse checks
    if args.check == "all":
        checks = CHECK_ORDER
    else:
        checks = [c.strip() for c in args.check.split(",")]
        invalid = [c for c in checks if c not in CHECKS]
        if invalid:
            print(f"Error: Unknown checks: {', '.join(invalid)}")
            print(f"Available checks: {', '.join(CHECK_ORDER)}")
            sys.exit(1)

    if not args.json:
        print("Plugin Validator")
        if "tokens" in checks:
            print(f"Token method: {TOKEN_METHOD}")

    # Run checks
    results = run_all_checks(plugin_dir, checks, args.verbose)

    # Output results
    if args.json:
        output_json(results, plugin_dir)
    else:
        print_results(results, plugin_dir, args.verbose)

    # Determine exit code based on severity
    has_critical_tokens = any(
        r.check == "tokens" and not r.passed
        for r in results
    )
    has_must_violations = any(not r.passed for r in results)

    if has_critical_tokens:
        sys.exit(2)  # Critical: token budget exceeded (MUST refactor)
    elif has_must_violations:
        sys.exit(1)  # Failed: MUST violations detected
    else:
        sys.exit(0)  # Passed: ready for Phase 2


if __name__ == "__main__":
    main()
