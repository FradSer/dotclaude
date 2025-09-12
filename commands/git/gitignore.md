---
allowed-tools: Bash, Read, Write, Edit, Glob, WebFetch
argument-hint: [additional-technologies]
description: Create or update .gitignore file
model: claude-3-5-haiku-20241022
---

Create or update the .gitignore file for this project.

**Process:**
1. **Auto-detect environment:**
   - Detect operating system (macOS, Linux, Windows)
   - Scan project files to identify technologies:
     - Node.js: package.json
     - Python: requirements.txt, pyproject.toml, setup.py
     - Java: pom.xml, build.gradle
     - Xcode/iOS: *.xcodeproj, *.xcworkspace
     - Go: go.mod
     - Rust: Cargo.toml
     - Docker: Dockerfile, docker-compose.yml
   - Report detected OS and technologies

2. **Fetch and generate .gitignore:**
   - Get available templates: `curl -sL https://www.toptal.com/developers/gitignore/api/list`
   - Combine detected OS and technologies (e.g., "macos,node,docker")
   - Add any additional technologies from arguments: $ARGUMENTS
   - Generate .gitignore: `curl -sL https://www.toptal.com/developers/gitignore/api/{params}`
   - Preserve existing custom rules when updating

3. **Verify and report:**
   - Show preview of generated .gitignore
   - Display git status to show newly ignored files
   - Backup existing .gitignore if present

**Usage examples:**
- `/gitignore` - Auto-detect and create .gitignore
- `/gitignore react typescript` - Add React and TypeScript to detected technologies
