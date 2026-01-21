Based on the provided web content (which is a 404 error page containing the documentation's site configuration and navigation structure), here is the organized structure and content summary of the **Claude Code** documentation.

# Claude Code Documentation

Claude Code is an agentic coding assistant designed by Anthropic for professional developers. It operates primarily as a CLI tool but integrates across various platforms and environments.

## Table of Contents

### 1. Getting Started
*   **Overview**: Introduction to Claude Code and its capabilities.
*   **Quickstart**: Initial setup and your first commands.
*   **Common Workflows**: Best practices for daily development tasks.
*   **Changelog**: Latest updates and version history.

### 2. Platforms & Integrations
*   **CLI**: The primary interface for terminal-based coding.
*   **Claude Code on the Web**: Browser-based access at `claude.ai/code`.
*   **Desktop & IDEs**:
    *   Visual Studio Code (VS Code)
    *   JetBrains IDEs
    *   Desktop App
    *   Chrome Extension (Beta)
*   **CI/CD & Collaboration**:
    *   GitHub Actions
    *   GitLab CI/CD
    *   Slack Integration

### 3. Core Features & Customization
*   **Sub-agents**: How Claude manages complex tasks using specialized sub-processes.
*   **Model Context Protocol (MCP)**: Connecting Claude to external tools and local stdio servers.
*   **Plugins & Skills**:
    *   Discovering and using official plugins.
    *   Creating and distributing private plugin marketplaces.
*   **Hooks**: Using `hooks-guide` and a `plugins-reference` for lifecycle management.
*   **Headless Mode**: Running Claude Code without interactive input.

### 4. Configuration & Reference
*   **Settings**:
    *   Fine-grained control using specifiers.
    *   Auto-updater permission options.
*   **Terminal & Model Config**: Customizing the appearance, memory usage, and the status line.
*   **CLI Reference**:
    *   **Interactive Mode**: Real-time pair programming.
    *   **Slash Commands**: Quick commands (e.g., `/checkpoint`).
    *   **Checkpointing**: Version control and state management within the tool.

### 5. Deployment & Administration
*   **LLM Providers**:
    *   Amazon Bedrock
    *   Google Vertex AI
    *   Microsoft Azure Foundry
*   **Infrastructure**: Network configuration, LLM gateways, Devcontainers, and Sandboxing.
*   **Enterprise Management**: IAM, security protocols, data usage policies, and cost monitoring.

---

## Documentation Excerpts & Technical Details

### Model Context Protocol (MCP)
Claude Code supports MCP to extend its capabilities.
*   **Local Stdio Servers**: You can add local servers to provide Claude with access to your local environment tools.

### Plugin Marketplaces
The documentation includes guides on how to **create and distribute a plugin marketplace**, specifically covering the use of **private repositories** for organization-wide tools.

### Fine-Grained Configuration
Users can manage settings with high precision.
*   **Specifiers**: Use specifiers for fine-grained control over how Claude interacts with specific files or directories.
*   **Terminal Config**: Includes support for custom status lines and memory management settings.

### Security & Privacy
*   **Data Usage**: Detailed documentation on how code and interactions are handled.
*   **Trust Center**: Anthropic provides a dedicated trust center and transparency reports for enterprise users.

### Useful Links (from Documentation)
*   **Platform**: [platform.claude.com](https://platform.claude.com/)
*   **Support**: [support.claude.com](https://support.claude.com/)
*   **Status**: [status.anthropic.com](https://status.anthropic.com/)

---
*Note: The content above is synthesized from the site's `docsConfig` and navigation metadata provided in the source.*