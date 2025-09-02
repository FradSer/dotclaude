# Git Flow Release Management

Smart release workflow that detects current branch state and manages semantic versioning automatically.

## AI Instructions for Release Management

### Branch Detection & Action Logic

**Check current branch and execute appropriate workflow:**

```bash
# Get current branch
CURRENT_BRANCH=$(git branch --show-current)

if [[ $CURRENT_BRANCH =~ ^release/([0-9]+\.[0-9]+\.[0-9]+)$ ]]; then
    # On release branch - proceed to finish workflow
    VERSION=${BASH_REMATCH[1]}
    echo "On release branch: $CURRENT_BRANCH"
    echo "Proceeding to finish release $VERSION"
else
    # Not on release branch - start new release
    echo "Not on release branch. Starting new release..."
fi
```

### Workflow A: Start New Release (when not on release/x.x.x)

1. **Prepare repository**:
```bash
git status
git fetch origin
git checkout develop
git pull origin develop
```

2. **Analyze changes for semantic versioning**:
```bash
# Get last tag
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
echo "Last release: $LAST_TAG"

# Analyze commits since last release
git log --oneline $LAST_TAG..develop --grep="BREAKING CHANGE" --grep="feat!" --grep="fix!" | wc -l
BREAKING_CHANGES=$?

git log --oneline $LAST_TAG..develop --grep="feat:" --grep="^feat(" | wc -l
NEW_FEATURES=$?

git log --oneline $LAST_TAG..develop --grep="fix:" --grep="^fix(" | wc -l
BUG_FIXES=$?

# Determine version bump
if [ $BREAKING_CHANGES -gt 0 ]; then
    BUMP_TYPE="major"
elif [ $NEW_FEATURES -gt 0 ]; then
    BUMP_TYPE="minor"
else
    BUMP_TYPE="patch"
fi

echo "Detected changes: $BREAKING_CHANGES breaking, $NEW_FEATURES features, $BUG_FIXES fixes"
echo "Recommended version bump: $BUMP_TYPE"
```

3. **Calculate new version**:
```bash
# Extract current version numbers
if [[ $LAST_TAG =~ v?([0-9]+)\.([0-9]+)\.([0-9]+) ]]; then
    MAJOR=${BASH_REMATCH[1]}
    MINOR=${BASH_REMATCH[2]}
    PATCH=${BASH_REMATCH[3]}
else
    MAJOR=0; MINOR=0; PATCH=0
fi

# Calculate new version
case $BUMP_TYPE in
    "major") NEW_VERSION="$((MAJOR + 1)).0.0" ;;
    "minor") NEW_VERSION="$MAJOR.$((MINOR + 1)).0" ;;
    "patch") NEW_VERSION="$MAJOR.$MINOR.$((PATCH + 1))" ;;
esac

echo "New version: $NEW_VERSION"
```

4. **Start release branch**:
```bash
git flow release start $NEW_VERSION
git flow release publish $NEW_VERSION
```

5. **Update version files and changelog**:
```bash
# Update package files (detect project type)
if [ -f "package.json" ]; then
    npm version $NEW_VERSION --no-git-tag-version
    npm install  # Sync lockfile
elif [ -f "pyproject.toml" ]; then
    # Update pyproject.toml version
    sed -i '' "s/^version = .*/version = \"$NEW_VERSION\"/" pyproject.toml
    uv sync
elif [ -f "setup.py" ]; then
    # Update setup.py version
    sed -i '' "s/version=['\"][^'\"]*['\"]/version='$NEW_VERSION'/" setup.py
    pip install -e .
elif [ -f "Cargo.toml" ]; then
    # Update Cargo.toml version
    sed -i '' "s/^version = .*/version = \"$NEW_VERSION\"/" Cargo.toml
    cargo build
fi

# Update CHANGELOG.md if exists
if [ -f "CHANGELOG.md" ]; then
    DATE=$(date +%Y-%m-%d)
    # Move Unreleased items to new version section
    sed -i '' "/## \[Unreleased\]/a\\
\\
## [$NEW_VERSION] - $DATE" CHANGELOG.md
fi

git add .
git commit -m "chore: bump version to $NEW_VERSION and update changelog"
git push origin release/$NEW_VERSION
```

### Workflow B: Finish Release (when on release/x.x.x)

1. **Extract version from branch name**:
```bash
CURRENT_BRANCH=$(git branch --show-current)
VERSION=${CURRENT_BRANCH#release/}
echo "Finishing release: $VERSION"
```

2. **Update dependencies and sync**:
```bash
# Detect project type and sync dependencies
if [ -f "package.json" ]; then
    echo "Node.js project detected"
    if command -v pnpm &> /dev/null; then
        pnpm install
    else
        npm install
    fi
elif [ -f "pyproject.toml" ]; then
    echo "Python project with pyproject.toml detected"
    uv sync
elif [ -f "requirements.txt" ] || [ -f "setup.py" ]; then
    echo "Python project detected"
    if command -v uv &> /dev/null; then
        uv pip sync requirements.txt
    else
        pip install -r requirements.txt
    fi
elif [ -f "Cargo.toml" ]; then
    echo "Rust project detected"
    cargo build
elif [ -f "go.mod" ]; then
    echo "Go project detected"
    go mod tidy
fi
```

3. **Update changelog for current release**:
```bash
if [ -f "CHANGELOG.md" ]; then
    DATE=$(date +%Y-%m-%d)
    # Ensure current version is properly dated
    sed -i '' "s/## \[$VERSION\] - TBD/## [$VERSION] - $DATE/" CHANGELOG.md
    
    # Add git log entries if changelog section is empty
    if ! grep -A 10 "## \[$VERSION\]" CHANGELOG.md | grep -q "###"; then
        echo "Adding changelog entries from git log..."
        # This would need manual curation in practice
        git log --oneline $(git describe --tags --abbrev=0 HEAD^)..HEAD >> /tmp/release_notes
        echo "Review and update CHANGELOG.md with proper formatting"
    fi
fi
```

4. **Final verification**:
```bash
git status
# Run tests if test command exists
if [ -f "package.json" ] && jq -e '.scripts.test' package.json > /dev/null; then
    npm test
elif [ -f "pyproject.toml" ]; then
    if command -v pytest &> /dev/null; then
        pytest
    fi
elif [ -f "Cargo.toml" ]; then
    cargo test
fi
```

5. **Finish release**:
```bash
git add .
git commit -m "chore: finalize release $VERSION" || true
git flow release finish $VERSION
# Tag message: "Release $VERSION"

# Push everything
git push origin main
git push origin develop  
git push origin --tags
```

6. **Create GitHub release**:
```bash
if command -v gh &> /dev/null; then
    if [ -f "CHANGELOG.md" ]; then
        # Extract changelog section for this version
        awk "/## \[$VERSION\]/,/## \[/{if(/## \[/ && !/## \[$VERSION\]/) exit; print}" CHANGELOG.md > /tmp/release_notes.md
        gh release create v$VERSION --title "Release $VERSION" --notes-file /tmp/release_notes.md
    else
        gh release create v$VERSION --title "Release $VERSION" --generate-notes
    fi
fi
```

## Complete Workflow Script

```bash
#!/bin/bash
set -e

CURRENT_BRANCH=$(git branch --show-current)

if [[ $CURRENT_BRANCH =~ ^release/([0-9]+\.[0-9]+\.[0-9]+)$ ]]; then
    # Finish existing release
    VERSION=${BASH_REMATCH[1]}
    echo "🔄 Finishing release $VERSION..."
    
    # Sync dependencies
    [[ -f "package.json" ]] && (command -v pnpm >/dev/null && pnpm install || npm install)
    [[ -f "pyproject.toml" ]] && uv sync
    [[ -f "Cargo.toml" ]] && cargo build
    
    # Update changelog
    if [[ -f "CHANGELOG.md" ]]; then
        DATE=$(date +%Y-%m-%d)
        sed -i '' "s/## \[$VERSION\] - TBD/## [$VERSION] - $DATE/" CHANGELOG.md
    fi
    
    # Final checks and finish
    git add . && git commit -m "chore: finalize release $VERSION" || true
    git flow release finish $VERSION
    git push origin main develop --tags
    
    # Create GitHub release
    command -v gh >/dev/null && gh release create v$VERSION --title "Release $VERSION" --generate-notes
    
else
    # Start new release
    echo "🚀 Starting new release..."
    
    git checkout develop && git pull origin develop
    
    # Semantic version analysis
    LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
    
    # Analyze commits for version bump
    if git log $LAST_TAG..develop --grep="BREAKING CHANGE\|feat!\|fix!" --oneline | grep -q .; then
        BUMP="major"
    elif git log $LAST_TAG..develop --grep="^feat" --oneline | grep -q .; then
        BUMP="minor"  
    else
        BUMP="patch"
    fi
    
    # Calculate new version
    if [[ $LAST_TAG =~ v?([0-9]+)\.([0-9]+)\.([0-9]+) ]]; then
        case $BUMP in
            "major") NEW_VERSION="$((${BASH_REMATCH[1]} + 1)).0.0" ;;
            "minor") NEW_VERSION="${BASH_REMATCH[1]}.$((${BASH_REMATCH[2]} + 1)).0" ;;
            "patch") NEW_VERSION="${BASH_REMATCH[1]}.${BASH_REMATCH[2]}.$((${BASH_REMATCH[3]} + 1))" ;;
        esac
    else
        NEW_VERSION="1.0.0"
    fi
    
    echo "📦 New version: $NEW_VERSION ($BUMP bump from $LAST_TAG)"
    
    # Start release
    git flow release start $NEW_VERSION
    git flow release publish $NEW_VERSION
    
    # Update version files
    [[ -f "package.json" ]] && npm version $NEW_VERSION --no-git-tag-version
    [[ -f "pyproject.toml" ]] && sed -i '' "s/^version = .*/version = \"$NEW_VERSION\"/" pyproject.toml
    
    # Update changelog
    if [[ -f "CHANGELOG.md" ]]; then
        sed -i '' "/## \[Unreleased\]/a\\
\\
## [$NEW_VERSION] - TBD" CHANGELOG.md
    fi
    
    git add . && git commit -m "chore: bump version to $NEW_VERSION"
    git push origin release/$NEW_VERSION
    
    echo "✅ Release $NEW_VERSION started. Make final changes, then run this script again to finish."
fi
```

## Project Type Support

- **Node.js**: `package.json` + `npm`/`pnpm`
- **Python**: `pyproject.toml` + `uv` or `setup.py` + `pip`
- **Rust**: `Cargo.toml` + `cargo`
- **Go**: `go.mod` + `go mod tidy`

## Error Handling

- Script exits on any command failure (`set -e`)
- Graceful handling of missing tags (defaults to v0.0.0)
- Automatic detection of package managers
- Fallback to basic git operations if tools unavailable

## Best Practices

- Keep release branches short-lived
- Always sync dependencies before finishing
- Use conventional commits for automatic version detection
- Test thoroughly on release branch before finishing
- Coordinate release timing with team