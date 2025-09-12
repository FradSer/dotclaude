Create or update .gitignore file

Requirements:
- Automatically detect project type and operating system
- Use toptal.com/developers/gitignore API for templates
- Generate appropriate .gitignore based on detected technologies
- Preserve existing custom rules when updating

Instructions:
1. **Detect project environment:**
   - Check operating system (macOS, Linux, Windows)
   - Scan for project files to identify technologies:
     - Node.js: package.json
     - Python: requirements.txt, pyproject.toml, setup.py
     - Java: pom.xml, build.gradle
     - Xcode/iOS: *.xcodeproj, *.xcworkspace
     - Go: go.mod
     - Rust: Cargo.toml
     - Docker: Dockerfile, docker-compose.yml
   - Report detected OS and technologies to user

2. **Fetch available templates:**
   - Use: `curl -sL https://www.toptal.com/developers/gitignore/api/list`
   - Show user available template options

3. **Handle existing .gitignore:**
   - Extract custom rules (non-template lines)
   - Preserve user-added content

4. **Generate new .gitignore:**
   - Combine OS and detected technologies (e.g., "macos,node,docker")
   - Use: `curl -sL https://www.toptal.com/developers/gitignore/api/{params}`
   - Append preserved custom rules with clear section header

5. **Verify results:**
   - Show preview of generated .gitignore
   - Display current git status to show newly ignored files
   - Inform user about backup location and customization options
