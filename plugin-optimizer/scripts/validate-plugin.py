#!/usr/bin/env python3
"""
Consolidated plugin validator for Claude Code plugins.

Combines 5 validation checks into a single entry point:
- Structure validation (file patterns, naming conventions)
- Manifest validation (plugin.json required fields)
- Frontmatter validation (YAML frontmatter in components)
- Tool invocation validation (anti-pattern detection)
- Token budget validation (progressive disclosure)

Token Budgets (Official Best Practices):
- Level 1 (Metadata): ~100 tokens for name + description - Always loaded at startup
- Level 2 (Instructions): Under 5k tokens for SKILL.md body - Loaded when Skill triggered
- Level 3 (Resources): Effectively unlimited - Loaded as needed via bash

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

# Token budget thresholds (based on official Claude Code Skill authoring best practices)
# Level 1: Metadata - Always loaded (~100 tokens for name + description)
# Level 2: Instructions - When Skill triggered (Under 5k tokens for SKILL.md body)
# Level 3+: Resources - As needed (Effectively unlimited)
METADATA_TARGET = 100      # ~100 tokens for name + description
METADATA_WARNING = 200
SKILL_LINE_TARGET = 500    # Under 500 lines for SKILL.md body
SKILL_LINE_WARNING = 600
SKILL_LINE_CRITICAL = 800
SKILL_BODY_WARNING = 4500  # Warning when approaching 5k limit
SKILL_BODY_MAX = 5000      # Under 5k tokens hard limit (SKILL.md body)

# 官方规范推荐详细文档移入 references/；README.md/CHANGELOG.md 这类纯辅助文件
# 不应出现在 skill 文件夹内（SKILL.md 才是 skill 的入口）
FORBIDDEN_SKILL_AUX_FILES = {"README.md", "CHANGELOG.md"}

# Manifest schema (mirrors https://code.claude.com/docs/en/plugins-reference)
KNOWN_MANIFEST_FIELDS = {
    "$schema",
    "name", "displayName", "version", "description", "author",
    "homepage", "repository", "license", "keywords",
    "skills", "commands", "agents", "hooks",
    "mcpServers", "outputStyles", "themes", "lspServers", "monitors",
    "userConfig", "channels", "dependencies",
}

# Manifest fields that accept a path (string), an array of paths, or an inline object/array
PATH_FIELDS_STRING_OR_ARRAY = {"skills", "commands", "agents", "outputStyles", "themes"}
PATH_FIELDS_WITH_INLINE = {"hooks", "mcpServers", "lspServers", "monitors"}

# Agent frontmatter spec (per upstream plugins-reference#agents)
# Upstream lists: name, description, model, effort, maxTurns, tools, disallowedTools,
# skills, memory, background, isolation. `color` is a project-local convention (not upstream)
# accepted here so we don't flag existing agents, but its value is only checked at SHOULD level.
KNOWN_AGENT_FIELDS = {
    "name", "description",
    "model", "color",
    "effort", "maxTurns", "tools", "disallowedTools",
    "skills", "memory", "background", "isolation",
}
FORBIDDEN_AGENT_FIELDS = {"hooks", "mcpServers", "permissionMode"}

USER_CONFIG_TYPES = {"string", "number", "boolean", "directory", "file"}
MONITOR_WHEN_PREFIXES = ("always", "on-skill-invoke:")

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
    components = {
        "commands": [], "agents": [], "skills": [],
        "monitors": [], "themes": [], "output_styles": [],
    }

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

    monitors_file = plugin_dir / "monitors" / "monitors.json"
    if monitors_file.exists():
        components["monitors"].append(monitors_file)

    themes_dir = plugin_dir / "themes"
    if themes_dir.exists():
        for f in themes_dir.iterdir():
            if f.is_file() and f.suffix == ".json":
                components["themes"].append(f)

    output_styles_dir = plugin_dir / "output-styles"
    if output_styles_dir.exists():
        for f in output_styles_dir.iterdir():
            if f.is_file() and f.suffix == ".md" and f.name != "README.md":
                components["output_styles"].append(f)

    return components


def get_relative_path(file_path: Path, plugin_dir: Path) -> str:
    """Get relative path from plugin directory."""
    try:
        return str(file_path.relative_to(plugin_dir))
    except ValueError:
        return str(file_path)


def _check_skill_folder_contents(skill_dir: Path, plugin_dir: Path, result) -> None:
    """Validate skill folder against official spec.

    The official skill spec is permissive in practice: the skill-creator's own
    skill contains scripts/, references/, assets/, agents/, eval-viewer/, and
    LICENSE.txt; the official PDF example shows reference.md/examples.md/
    FORMS.md alongside scripts/ at the skill root. We therefore do NOT enforce
    a hard subdirectory whitelist. We only flag clearly auxiliary files
    (README.md, CHANGELOG.md) that the spec recommends moving into references/.
    """
    skill_rel = get_relative_path(skill_dir, plugin_dir)

    for child in skill_dir.iterdir():
        if child.is_dir() or not child.is_file():
            continue
        if child.name in FORBIDDEN_SKILL_AUX_FILES:
            result.should(
                f"Auxiliary file in skill folder: {child.name}",
                file=f"{skill_rel}/{child.name}",
                source=child.name,
                suggestion=(
                    "Move README.md/CHANGELOG.md content into references/ — "
                    "SKILL.md is the entry point for a skill"
                ),
            )


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
    for name in ("commands", "agents", "skills", "monitors", "themes", "output-styles", "hooks", "bin"):
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
    NON_SKILL_DIRS = {"references", "scripts", "examples", ".git"}
    skills_dir = plugin_dir / "skills"
    if skills_dir.exists():
        for skill_dir in skills_dir.iterdir():
            if skill_dir.name in NON_SKILL_DIRS:
                continue
            if not skill_dir.is_dir():
                continue
            if not (skill_dir / "SKILL.md").exists():
                result.must(
                    "Missing SKILL.md",
                    file=f"skills/{skill_dir.name}/",
                    suggestion="Create SKILL.md with frontmatter and content"
                )
                continue
            # Check skill folder for clearly auxiliary files (README.md/CHANGELOG.md).
            # Note: non-standard subdirs and loose .md docs are NOT flagged — the
            # official spec is permissive (PDF example shows reference.md/examples.md
            # at skill root; skill-creator itself has agents/ and eval-viewer/).
            # Nested skills (a subdirectory containing its own SKILL.md, e.g.
            # skills/lark/lark-mail/SKILL.md) are a legitimate pattern: they are
            # directories, not files, so the file-only check below skips them.
            _check_skill_folder_contents(skill_dir, plugin_dir, result)

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

    key_line_re_cache: dict[str, re.Pattern] = {}

    def find_key_line(key: str) -> int:
        pattern = key_line_re_cache.setdefault(
            key, re.compile(r'^\s*"' + re.escape(key) + r'"\s*:')
        )
        for i, line in enumerate(lines, 1):
            if pattern.match(line):
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

    # Validate hooks field
    if "hooks" in manifest:
        hooks = manifest["hooks"]
        if isinstance(hooks, str):
            # If the path is the standard default path, suggest removing it
            if hooks == "./hooks/hooks.json":
                result.must(
                    "Duplicate hooks file detected",
                    file=".claude-plugin/plugin.json",
                    source=f'"hooks": "{hooks}"',
                    suggestion="Remove the 'hooks' field from plugin.json. The standard hooks/hooks.json is loaded automatically, so manifest.hooks should only reference additional hook files."
                )
            elif not re.match(r'^\./.*$', hooks):
                result.must(
                    "Invalid hooks path format",
                    file=".claude-plugin/plugin.json",
                    source=f'"hooks": "{hooks}"',
                    suggestion="Use './path/' format for hooks file"
                )
            else:
                hooks_path = plugin_dir / hooks.lstrip("./")
                if not hooks_path.exists():
                    result.must(
                        "Hooks file not found",
                        file=".claude-plugin/plugin.json",
                        source=f'"hooks": "{hooks}"',
                        suggestion=f"Create hooks file at {hooks}"
                    )
                elif verbose:
                    result.ok("Hooks file exists", file=".claude-plugin/plugin.json")
        elif isinstance(hooks, dict):
            if verbose:
                result.ok("Inline hooks configuration valid", file=".claude-plugin/plugin.json")

    # Validate monitors field
    if "monitors" in manifest:
        _validate_monitors(manifest["monitors"], plugin_dir, result, verbose)

    # Validate string-or-array path fields: agents, skills, outputStyles, themes
    for field_name in ("agents", "skills", "outputStyles", "themes"):
        if field_name in manifest:
            _validate_path_field(field_name, manifest[field_name], plugin_dir, result, verbose)

    # Validate mcpServers field (string path or inline object)
    if "mcpServers" in manifest:
        _validate_mcp_servers(manifest["mcpServers"], plugin_dir, result, verbose)

    # Validate lspServers field (string path or inline object)
    if "lspServers" in manifest:
        _validate_lsp_servers(manifest["lspServers"], plugin_dir, result, verbose)

    # Validate userConfig field
    if "userConfig" in manifest:
        _validate_user_config(manifest["userConfig"], result)

    # Validate dependencies field
    if "dependencies" in manifest:
        _validate_dependencies(manifest["dependencies"], result)

    # Validate stand-alone .mcp.json / .lsp.json files even when not declared in manifest
    standalone_mcp = plugin_dir / ".mcp.json"
    if standalone_mcp.exists() and "mcpServers" not in manifest:
        try:
            data = json.loads(standalone_mcp.read_text())
            _validate_mcp_servers_object(data, plugin_dir, result, source_file=".mcp.json")
        except json.JSONDecodeError as e:
            result.must(
                "Invalid JSON in .mcp.json",
                file=".mcp.json",
                line=e.lineno if hasattr(e, "lineno") else 0,
                source=str(e),
                suggestion="Fix JSON syntax error",
            )

    standalone_lsp = plugin_dir / ".lsp.json"
    if standalone_lsp.exists() and "lspServers" not in manifest:
        try:
            data = json.loads(standalone_lsp.read_text())
            _validate_lsp_servers_object(data, result, source_file=".lsp.json")
        except json.JSONDecodeError as e:
            result.must(
                "Invalid JSON in .lsp.json",
                file=".lsp.json",
                line=e.lineno if hasattr(e, "lineno") else 0,
                source=str(e),
                suggestion="Fix JSON syntax error",
            )

    standalone_monitors = plugin_dir / "monitors" / "monitors.json"
    if standalone_monitors.exists() and "monitors" not in manifest:
        _validate_monitors_file(standalone_monitors, result, source_file="monitors/monitors.json")

    # Warn on unknown manifest fields (catches typos like "montiors")
    for key in manifest.keys():
        if key not in KNOWN_MANIFEST_FIELDS:
            result.should(
                f"Unknown manifest field: {key!r}",
                file=".claude-plugin/plugin.json",
                line=find_key_line(key),
                source=f'"{key}": ...',
                suggestion=f"Remove or fix typo. Known fields: {', '.join(sorted(KNOWN_MANIFEST_FIELDS))}",
            )

    return result


def _resolve_manifest_path(plugin_dir: Path, rel_path: str) -> Path:
    """Resolve a './foo' manifest path against plugin_dir without breaking on Windows."""
    return plugin_dir / rel_path[2:] if rel_path.startswith("./") else plugin_dir / rel_path


def _validate_path_field(field_name: str, value, plugin_dir: Path,
                         result: ValidationResult, verbose: bool) -> None:
    """Validate a string|array manifest field that points to component paths."""
    paths = [value] if isinstance(value, str) else value
    if not isinstance(paths, list):
        result.must(
            f"'{field_name}' must be a string or array",
            file=".claude-plugin/plugin.json",
            source=f'"{field_name}": {json.dumps(value)[:60]}...',
            suggestion='Use "./path/" or ["./path1/", "./path2/"]',
        )
        return

    for p in paths:
        if not isinstance(p, str):
            result.must(
                f"'{field_name}' entry must be a string path",
                file=".claude-plugin/plugin.json",
                source=str(p),
            )
            continue
        if not p.startswith("./"):
            result.must(
                f"Invalid {field_name} path format: {p}",
                file=".claude-plugin/plugin.json",
                source=f'"{p}"',
                suggestion="Paths must be relative and start with './'",
            )
            continue
        target = _resolve_manifest_path(plugin_dir, p.rstrip("/"))
        if not target.exists():
            result.must(
                f"{field_name} path not found: {p}",
                file=".claude-plugin/plugin.json",
                source=f'"{p}"',
                suggestion=f"Create {p} or remove from manifest",
            )
        elif verbose:
            result.ok(f"{field_name}: {p}", file=".claude-plugin/plugin.json")


def _validate_monitors(value, plugin_dir: Path, result: ValidationResult, verbose: bool) -> None:
    """Validate the `monitors` manifest field. Accepts a path string, an inline array, or null."""
    if isinstance(value, str):
        if not value.startswith("./"):
            result.must(
                "Invalid monitors path format",
                file=".claude-plugin/plugin.json",
                source=f'"monitors": "{value}"',
                suggestion="Use './path/to/monitors.json'",
            )
            return
        path = _resolve_manifest_path(plugin_dir, value)
        if not path.exists():
            result.must(
                "Monitors file not found",
                file=".claude-plugin/plugin.json",
                source=f'"monitors": "{value}"',
                suggestion=f"Create {value}",
            )
            return
        _validate_monitors_file(path, result, source_file=value)
    elif isinstance(value, list):
        _validate_monitors_array(value, result, source_file=".claude-plugin/plugin.json")
    else:
        result.must(
            "'monitors' must be a path string or array of monitor entries",
            file=".claude-plugin/plugin.json",
            source=f'"monitors": {json.dumps(value)[:60]}...',
        )


def _validate_monitors_file(path: Path, result: ValidationResult, source_file: str) -> None:
    try:
        data = json.loads(path.read_text())
    except json.JSONDecodeError as e:
        result.must(
            f"Invalid JSON in {source_file}",
            file=source_file,
            line=e.lineno if hasattr(e, "lineno") else 0,
            source=str(e),
            suggestion="Fix JSON syntax error",
        )
        return
    if not isinstance(data, list):
        result.must(
            "monitors.json must be a JSON array",
            file=source_file,
            suggestion="Wrap entries in [...]",
        )
        return
    _validate_monitors_array(data, result, source_file=source_file)


def _validate_monitors_array(entries, result: ValidationResult, source_file: str) -> None:
    seen_names = set()
    for idx, entry in enumerate(entries):
        loc = f"{source_file}[{idx}]"
        if not isinstance(entry, dict):
            result.must("Monitor entry must be an object", file=loc)
            continue
        for required in ("name", "command", "description"):
            if required not in entry or not entry[required]:
                result.must(
                    f"Monitor missing '{required}'",
                    file=loc,
                    source=json.dumps(entry)[:80],
                    suggestion=f"Add '{required}' field per https://code.claude.com/docs/en/plugins-reference#monitors",
                )
        name = entry.get("name")
        if isinstance(name, str):
            if name in seen_names:
                result.must(
                    f"Duplicate monitor name: {name!r}",
                    file=loc,
                    suggestion="Each monitor name must be unique within the plugin",
                )
            seen_names.add(name)
        when = entry.get("when")
        if when is not None and isinstance(when, str):
            if not (when == "always" or when.startswith("on-skill-invoke:")):
                result.should(
                    f"Unknown 'when' value: {when!r}",
                    file=loc,
                    source=f'"when": "{when}"',
                    suggestion='Use "always" (default) or "on-skill-invoke:<skill-name>"',
                )


def _validate_mcp_servers(value, plugin_dir: Path, result: ValidationResult, verbose: bool) -> None:
    if isinstance(value, str):
        if not value.startswith("./"):
            result.must(
                "Invalid mcpServers path format",
                file=".claude-plugin/plugin.json",
                source=f'"mcpServers": "{value}"',
                suggestion="Use './path/to/.mcp.json'",
            )
            return
        path = _resolve_manifest_path(plugin_dir, value)
        if not path.exists():
            result.must(
                "mcpServers file not found",
                file=".claude-plugin/plugin.json",
                source=f'"mcpServers": "{value}"',
            )
            return
        try:
            data = json.loads(path.read_text())
        except json.JSONDecodeError as e:
            result.must(f"Invalid JSON in {value}", file=value, source=str(e))
            return
        _validate_mcp_servers_object(data, plugin_dir, result, source_file=value)
    elif isinstance(value, dict):
        _validate_mcp_servers_object(value, plugin_dir, result,
                                      source_file=".claude-plugin/plugin.json")
    else:
        result.must(
            "'mcpServers' must be a path string or inline object",
            file=".claude-plugin/plugin.json",
        )


def _validate_mcp_servers_object(servers, plugin_dir: Path, result: ValidationResult,
                                  source_file: str) -> None:
    if not isinstance(servers, dict):
        result.must("mcpServers must be an object keyed by server name", file=source_file)
        return
    for name, cfg in servers.items():
        loc = f"{source_file}:{name}"
        if not isinstance(cfg, dict):
            result.must(f"MCP server {name!r} config must be an object", file=loc)
            continue
        # http/sse servers use 'url' instead of 'command'; stdio is the implicit default
        transport = cfg.get("type")
        if transport is not None and transport not in ("stdio", "http", "sse"):
            result.must(
                f"MCP server {name!r} has invalid transport: {transport!r}",
                file=loc,
                suggestion="Use one of: stdio (default), http, sse",
            )
            continue
        if transport in ("http", "sse"):
            if "url" not in cfg or not cfg["url"]:
                result.must(
                    f"MCP server {name!r} missing 'url'",
                    file=loc,
                    suggestion="http/sse transports require a 'url' field",
                )
        else:
            if "command" not in cfg or not cfg["command"]:
                result.must(
                    f"MCP server {name!r} missing 'command'",
                    file=loc,
                    suggestion="stdio servers require a 'command' field",
                )


def _validate_lsp_servers(value, plugin_dir: Path, result: ValidationResult, verbose: bool) -> None:
    if isinstance(value, str):
        if not value.startswith("./"):
            result.must(
                "Invalid lspServers path format",
                file=".claude-plugin/plugin.json",
                source=f'"lspServers": "{value}"',
                suggestion="Use './path/to/.lsp.json'",
            )
            return
        path = _resolve_manifest_path(plugin_dir, value)
        if not path.exists():
            result.must(
                "lspServers file not found",
                file=".claude-plugin/plugin.json",
                source=f'"lspServers": "{value}"',
            )
            return
        try:
            data = json.loads(path.read_text())
        except json.JSONDecodeError as e:
            result.must(f"Invalid JSON in {value}", file=value, source=str(e))
            return
        _validate_lsp_servers_object(data, result, source_file=value)
    elif isinstance(value, dict):
        _validate_lsp_servers_object(value, result, source_file=".claude-plugin/plugin.json")
    else:
        result.must(
            "'lspServers' must be a path string or inline object",
            file=".claude-plugin/plugin.json",
        )


def _validate_lsp_servers_object(servers, result: ValidationResult, source_file: str) -> None:
    if not isinstance(servers, dict):
        result.must("lspServers must be an object keyed by language name", file=source_file)
        return
    for name, cfg in servers.items():
        loc = f"{source_file}:{name}"
        if not isinstance(cfg, dict):
            result.must(f"LSP server {name!r} config must be an object", file=loc)
            continue
        if "command" not in cfg or not cfg["command"]:
            result.must(
                f"LSP server {name!r} missing 'command'",
                file=loc,
                suggestion="LSP entries require a 'command' field (binary in PATH)",
            )
        if "extensionToLanguage" not in cfg or not cfg["extensionToLanguage"]:
            result.must(
                f"LSP server {name!r} missing 'extensionToLanguage'",
                file=loc,
                suggestion='Add e.g. "extensionToLanguage": {".go": "go"}',
            )


def _validate_user_config(value, result: ValidationResult) -> None:
    if not isinstance(value, dict):
        result.must(
            "'userConfig' must be an object",
            file=".claude-plugin/plugin.json",
        )
        return
    for key, opt in value.items():
        loc = f".claude-plugin/plugin.json:userConfig.{key}"
        if not isinstance(opt, dict):
            result.must(f"userConfig.{key} must be an object", file=loc)
            continue
        for required in ("type", "title", "description"):
            if required not in opt:
                result.must(
                    f"userConfig.{key} missing '{required}'",
                    file=loc,
                    suggestion=f"Required fields: type, title, description",
                )
        t = opt.get("type")
        if t is not None and t not in USER_CONFIG_TYPES:
            result.must(
                f"userConfig.{key} has invalid type: {t!r}",
                file=loc,
                suggestion=f"Use one of: {', '.join(sorted(USER_CONFIG_TYPES))}",
            )


def _validate_dependencies(value, result: ValidationResult) -> None:
    if not isinstance(value, list):
        result.must(
            "'dependencies' must be an array",
            file=".claude-plugin/plugin.json",
        )
        return
    for idx, dep in enumerate(value):
        loc = f".claude-plugin/plugin.json:dependencies[{idx}]"
        if isinstance(dep, str):
            continue
        if isinstance(dep, dict):
            if "name" not in dep:
                result.must(f"dependencies[{idx}] object missing 'name'", file=loc)
            continue
        result.must(
            f"dependencies[{idx}] must be a string or {{name, version}} object",
            file=loc,
            source=str(dep),
        )


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
        prefix = f"{key}:"
        for i, line in enumerate(lines, 1):
            if i <= fm_end_line and line.startswith(prefix):
                # Reject partial-key matches like 'description:' when looking for 'desc'
                rest = line[len(prefix):]
                if not rest or rest[0] in (" ", "\t", ""):
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

        # Optional: model (upstream does not require it for plugin agents)
        if "model" in fm:
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

        # Optional: color (project-local convention; not in upstream agent field list)
        if "color" in fm:
            color = fm["color"]
            line_num = find_fm_key_line("color")
            valid_colors = ("blue", "cyan", "green", "yellow", "magenta", "red")
            if color not in valid_colors:
                result.should(
                    "Invalid color value",
                    file=rel_path,
                    line=line_num,
                    source=f'color: {color}',
                    suggestion=f"Use: {', '.join(valid_colors)}"
                )
            elif verbose:
                result.ok(f'color: "{color}"', file=rel_path, line=line_num)

        # Forbidden fields per upstream spec — plugin-shipped agents must not declare these
        for forbidden in FORBIDDEN_AGENT_FIELDS:
            if forbidden in fm:
                result.must(
                    f"Forbidden agent field: {forbidden!r}",
                    file=rel_path,
                    line=find_fm_key_line(forbidden),
                    source=f"{forbidden}: {fm[forbidden]}",
                    suggestion=(
                        "Plugin-shipped agents cannot declare hooks, mcpServers, or "
                        "permissionMode (security restriction per plugins-reference#agents)."
                    ),
                )

        # isolation: only "worktree" is valid
        if "isolation" in fm and fm["isolation"] != "worktree":
            result.must(
                "Invalid isolation value",
                file=rel_path,
                line=find_fm_key_line("isolation"),
                source=f"isolation: {fm['isolation']}",
                suggestion='Only "worktree" is supported',
            )

    elif comp_type == "skill":
        # Allowed fields for skills (name, description are required for official best practices)
        # Additional fields like user-invocable, allowed-tools, argument-hint are supported
        # and provide value for command-type skills registered under "commands" in plugin.json
        if "name" not in fm:
            result.must(
                "Missing 'name' in frontmatter",
                file=rel_path,
                suggestion="Add name: skill-name (kebab-case, max 64 chars)"
            )
        else:
            name = fm["name"]
            line_num = find_fm_key_line("name")
            if len(name) > 64:
                result.must(
                    "Name exceeds 64 character limit",
                    file=rel_path,
                    line=line_num,
                    source=f'name: {name}',
                    suggestion="Use max 64 characters for name"
                )
            elif not re.match(r'^[a-z0-9-]+$', name):
                result.should(
                    "Name contains invalid characters",
                    file=rel_path,
                    line=line_num,
                    source=f'name: {name}',
                    suggestion="Use only lowercase letters, numbers, and hyphens"
                )
            elif verbose:
                result.ok(f'name: "{name}"', file=rel_path, line=line_num)

        if "description" not in fm:
            result.must(
                "Missing 'description' in frontmatter",
                file=rel_path,
                suggestion="Add description with trigger phrases (what it does AND when to use it)"
            )
        else:
            desc = fm["description"]
            line_num = find_fm_key_line("description")

            # Check for third-person voice (official requirement)
            first_person_patterns = [
                (r'\bI can\b', "first person 'I can'"),
                (r'\bI will\b', "first person 'I will'"),
                (r'\bYou can\b', "second person 'You can'"),
                (r'\bYou should\b', "second person 'You should'"),
            ]
            for pattern, pattern_name in first_person_patterns:
                if re.search(pattern, desc, re.IGNORECASE):
                    result.should(
                        f"Description uses {pattern_name}",
                        file=rel_path,
                        line=line_num,
                        source=f'description: {desc[:50]}...',
                        suggestion="Use third person: 'Validates...' or 'Processes...' not 'I can...' or 'You can...'"
                    )
                    break

            # Check for trigger phrases (official requirement: describe when to use it)
            trigger_phrases = [
                r'\bUse when\b',
                r'\bUse for\b',
                r'\bwhen the user\b',
                r'\btriggers?\b',
                r'\bactivat(e|ion)\b',
            ]
            has_trigger = any(re.search(pattern, desc, re.IGNORECASE) for pattern in trigger_phrases)

            if not has_trigger:
                result.should(
                    "Description missing trigger phrases (when to use this skill)",
                    file=rel_path,
                    line=line_num,
                    source=f'description: {desc[:50]}...',
                    suggestion="Include both what the skill does AND when to use it. Example: 'Validates plugins. Use when validating plugin structure...'"
                )

            if len(desc.replace(" ", "")) < 10:
                result.should(
                    "Description too short",
                    file=rel_path,
                    line=line_num,
                    source=f'description: {desc}',
                    suggestion="Add more detail about when this skill should be used"
                )
            elif len(desc) > 1024:
                result.must(
                    "Description exceeds 1024 character limit",
                    file=rel_path,
                    line=line_num,
                    source=f'description: {desc[:50]}... ({len(desc)} chars)',
                    suggestion="Use max 1024 characters for description"
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

        # Note: argument-hint and version are optional and supported for skills
        # (see plugin-best-practices SKILL.md frontmatter section)


# =============================================================================
# Check: Tool Invocations
# =============================================================================

def check_tool_invocations(plugin_dir: Path, verbose: bool = False) -> ValidationResult:
    """Detect explicit tool call anti-patterns."""
    result = ValidationResult("tools")

    components = find_components(plugin_dir)
    all_files = components["commands"] + components["agents"] + components["skills"]

    # Anti-pattern regex
    core_tools = re.compile(r'(Use|Call|Using) (the )?`?(Read|Write|Glob|Grep|Edit)`? tool', re.IGNORECASE)
    bash_tool = re.compile(r'(Use|Call|Using) (the )?Bash tool', re.IGNORECASE)
    task_tool = re.compile(r'(Use|Call) (the )?Task tool to launch [a-z-]+', re.IGNORECASE)
    fence_start = re.compile(r'^\s*(```+|~~~+)')

    for file_path in all_files:
        content = file_path.read_text()
        lines = content.split("\n")
        rel_path = get_relative_path(file_path, plugin_dir)
        in_fence = False
        fence_char = ""
        fence_len = 0

        for i, line in enumerate(lines, 1):
            stripped = line.strip()
            if not stripped:
                continue

            fence_match = fence_start.match(stripped)
            if fence_match:
                marker = fence_match.group(1)
                if not in_fence:
                    in_fence = True
                    fence_char = marker[0]
                    fence_len = len(marker)
                elif marker[0] == fence_char and len(marker) >= fence_len:
                    in_fence = False
                    fence_char = ""
                    fence_len = 0
                continue

            if in_fence:
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
        body_lines = skill_result["body_lines"]
        refs = skill_result["reference_tokens"]

        # Build details dict for structured output
        details = {
            "frontmatter": meta,
            "body": body,
            "body_lines": body_lines,
            "refs": refs,
            "files": skill_result["files"]
        }

        # Check line count (official requirement: under 500 lines)
        if body_lines >= SKILL_LINE_CRITICAL:
            result.must(
                f"SKILL.md body too long: {body_lines} lines (max recommended: {SKILL_LINE_TARGET})",
                file=rel_path,
                suggestion=f"MUST move content to references/ - exceed {SKILL_LINE_CRITICAL} lines",
                **details
            )
        elif body_lines >= SKILL_LINE_WARNING:
            result.should(
                f"SKILL.md body approaching limit: {body_lines} lines (recommended: {SKILL_LINE_TARGET})",
                file=rel_path,
                suggestion=f"Consider moving content to references/",
                **details
            )
        elif body_lines > SKILL_LINE_TARGET and verbose:
            result.ok(
                f"SKILL.md body: {body_lines} lines (slightly above {SKILL_LINE_TARGET} target)",
                file=rel_path,
                **details
            )

        # Check token count (official: Under 5k tokens for SKILL.md body)
        if body >= SKILL_BODY_MAX:
            result.must(
                f"Token budget exceeded: {body} tokens (max: {SKILL_BODY_MAX})",
                file=rel_path,
                suggestion=f"MUST move content to references/ - exceed {SKILL_BODY_MAX} tokens",
                **details
            )
        elif body >= SKILL_BODY_WARNING:
            result.should(
                f"Token count approaching limit: {body} tokens (max: {SKILL_BODY_MAX})",
                file=rel_path,
                suggestion=f"Consider moving content to references/ before reaching {SKILL_BODY_MAX} tokens",
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

            # Level 1: Metadata
            result.ok(f"  Level 1 (Metadata): {meta} tokens (always loaded at startup)")
            result.ok(f"    - name + description from YAML frontmatter")

            # Level 2: Instructions
            result.ok(f"  Level 2 (Instructions): {body} tokens ({body_lines} lines, loaded when triggered)")
            result.ok(f"    - SKILL.md body with instructions and guidance")
            if skill_result.get('status') == "CRITICAL":
                result.ok(f"    - Status: EXCEEDS 5k token limit (MUST refactor)")
            elif skill_result.get('status') == "WARNING":
                result.ok(f"    - Status: Approaching 5k token limit (SHOULD consider refactoring)")
            elif body_lines > SKILL_LINE_TARGET:
                result.ok(f"    - Status: Above {SKILL_LINE_TARGET} lines target (MAY consider refactoring)")

            # Level 3: Resources
            result.ok(f"  Level 3 (Resources): {refs} tokens (loaded as needed)")
            result.ok(f"    - Bundled files: {len(ref_files)} reference files")
            for f in ref_files:
                result.ok(f"      - {f['file']}: {f['tokens']} tokens")
            if script_files:
                scripts = skill_result.get("script_tokens", 0)
                result.ok(f"    - Scripts: {scripts} tokens ({len(script_files)} files)")
                for f in script_files:
                    result.ok(f"      - {f['file']}: {f['tokens']} tokens")
            result.ok(f"  Total effective: {skill_result['total_tokens']} tokens")

    return result


def _analyze_skill_tokens(skill_dir: Path) -> dict:
    """Analyze token usage for a single skill."""
    skill_md = skill_dir / "SKILL.md"
    content = skill_md.read_text()
    fm, body, _ = parse_frontmatter(content)

    description = fm.get("description", "")
    name = fm.get("name", "")

    # Official: name + description for metadata tokens
    metadata_text = f"{name} {description}"
    metadata_tokens = count_tokens(metadata_text)
    skill_tokens = count_tokens(body)

    # Count body lines (exclude frontmatter)
    body_lines = len([l for l in body.split("\n") if l.strip()])

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
    if skill_tokens >= SKILL_BODY_MAX:
        status = "CRITICAL"
    elif skill_tokens >= SKILL_BODY_WARNING:
        status = "WARNING"
    elif body_lines > SKILL_LINE_TARGET:
        status = "LINE_HIGH"

    return {
        "status": status,
        "metadata_tokens": metadata_tokens,
        "skill_tokens": skill_tokens,
        "body_lines": body_lines,
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


# ANSI severity styling (only emitted when stdout is a TTY)
_SEVERITY_STYLE = {
    "must":   "\033[1;31m",  # bold red
    "should": "\033[33m",    # yellow
    "may":    "\033[34m",    # blue
    "ok":     "\033[32m",    # green
}
_RESET = "\033[0m"


def _color(text: str, severity: str, enabled: bool) -> str:
    if not enabled:
        return text
    style = _SEVERITY_STYLE.get(severity, "")
    return f"{style}{text}{_RESET}" if style else text


def _format_location(issue: Issue) -> str:
    if not issue.file:
        return ""
    return f"{issue.file}:{issue.line}" if issue.line else issue.file


def print_results(results: list[ValidationResult], plugin_dir: Path, verbose: bool = False):
    """Render validation results in compiler-diagnostic style.

    Layout: `path:line  severity  message`, with optional indented `> source`
    and `help: suggestion` lines beneath. Files with 2+ issues are visually
    grouped by a blank-line separator. Summary is one line.
    """
    color = sys.stdout.isatty()

    bucket = {"must": [], "should": [], "may": [], "ok": []}
    for result in results:
        for issue in result.issues:
            bucket[issue.severity].append(issue)

    components = find_components(plugin_dir)
    comp_parts = [f"commands={len(components['commands'])}",
                  f"agents={len(components['agents'])}",
                  f"skills={len(components['skills'])}"]
    for key, label in (("monitors", "monitors"), ("themes", "themes"),
                       ("output_styles", "output-styles")):
        if components.get(key):
            comp_parts.append(f"{label}={len(components[key])}")

    try:
        rel_target = plugin_dir.relative_to(Path.cwd())
    except ValueError:
        rel_target = plugin_dir

    print(f"{rel_target}  ({', '.join(comp_parts)})")

    diagnostics = bucket["must"] + bucket["should"] + bucket["may"]

    if diagnostics:
        # Sort by file, then severity ordering (must first)
        sev_rank = {"must": 0, "should": 1, "may": 2}
        diagnostics.sort(key=lambda i: (i.file or "", i.line or 0, sev_rank[i.severity]))

        loc_strings = [_format_location(i) or "(no file)" for i in diagnostics]
        max_loc = min(max(len(s) for s in loc_strings), 60)
        max_sev = max(len(i.severity) for i in diagnostics)

        print()
        prev_file = None
        for issue, loc in zip(diagnostics, loc_strings):
            if prev_file is not None and issue.file != prev_file:
                print()
            prev_file = issue.file

            sev_label = _color(issue.severity.ljust(max_sev), issue.severity, color)
            loc_padded = loc.ljust(max_loc) if len(loc) <= max_loc else loc
            print(f"  {loc_padded}  {sev_label}  {issue.message}")

            indent = " " * (2 + max_loc + 2 + max_sev + 2)
            if issue.source:
                snippet = issue.source.replace("\n", " ")
                if len(snippet) > 90:
                    snippet = snippet[:87] + "…"
                print(f"{indent}│ {snippet}")
            if issue.details.get("frontmatter") is not None:
                d = issue.details
                print(f"{indent}tokens: metadata={d['frontmatter']} "
                      f"body={d['body']} ({d.get('body_lines', 0)} lines) "
                      f"refs={d['refs']}  (limit: body<{SKILL_BODY_MAX})")
            if issue.suggestion:
                # Wrap multi-line suggestions cleanly under the same indent
                first, *rest = issue.suggestion.split("\n")
                print(f"{indent}help: {first}")
                for ln in rest:
                    print(f"{indent}      {ln}")

    if verbose and bucket["ok"]:
        print(f"\n{len(bucket['ok'])} passing checks:")
        prev_file = None
        for issue in bucket["ok"]:
            mark = _color("✓", "ok", color)
            line = issue.message
            if issue.file:
                if prev_file and issue.file != prev_file:
                    print()
                prev_file = issue.file
                loc = _format_location(issue)
                line = f"{line}  ({loc})" if loc else line
            print(f"  {mark} {line}")

    counts = [(len(bucket[s]), s) for s in ("must", "should", "may") if bucket[s]]
    print()
    if not counts:
        print(_color("PASSED", "ok", color) + "  no issues")
    elif bucket["must"]:
        parts = ", ".join(_color(f"{n} {s}", s, color) for n, s in counts)
        print(_color("FAILED", "must", color) + f"  {parts}")
    else:
        parts = ", ".join(_color(f"{n} {s}", s, color) for n, s in counts)
        print(_color("PASSED", "should", color) + f"  {parts}")


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