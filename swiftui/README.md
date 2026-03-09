# SwiftUI Plugin

SwiftUI code review with modern API best practices.

**Version**: 0.2.0

**Original Source**: [SwiftUI Agent Skill](https://github.com/twostraws/SwiftUI-Agent-Skill) by Paul Hudson

## Installation

```bash
claude plugin install swiftui@frad-dotclaude
```

## Overview

The SwiftUI Plugin provides comprehensive code review for SwiftUI applications, ensuring adherence to modern Swift development standards and best practices. This plugin is based on the work of Paul Hudson (twostraws) and is continuously updated for the latest SwiftUI APIs.

## Commands

### `/swiftui-review`

Comprehensive SwiftUI code review skill for best practices on modern APIs, maintainability, and performance.

**When triggered:**
- User requests SwiftUI code review
- Reading, writing, or reviewing SwiftUI projects
- Checking for deprecated API usage
- Validating accessibility compliance

**Review process:**
1. Check for deprecated API using `references/api.md`
2. Check that views, modifiers, and animations are optimal via `references/views.md`
3. Validate data flow configuration using `references/data.md`
4. Ensure navigation is updated and performant via `references/navigation.md`
5. Verify design follows Apple HIG via `references/design.md`
6. Validate accessibility compliance via `references/accessibility.md`
7. Ensure efficient code execution via `references/performance.md`
8. Quick Swift code validation via `references/swift.md`
9. Final code hygiene check via `references/hygiene.md`

**Output format:**
```
### Filename.swift

**Line X: Rule name**

```swift
// Before
code before fix

// After
code after fix
```

### Summary

1. **Category (priority):** Issue description
```

## Core Standards

- **iOS 26** is the default deployment target for new apps
- **Swift 6.2** or later with modern Swift concurrency
- Avoid UIKit unless explicitly requested
- No third-party frameworks without approval
- One type per Swift file
- Feature-based folder structure

## Reference Materials

The plugin includes detailed reference guides:

| File | Description |
|------|-------------|
| `references/api.md` | Modern API usage and deprecated code replacements |
| `references/views.md` | View structure, composition, and animation |
| `references/data.md` | Data flow, shared state, and property wrappers |
| `references/navigation.md` | NavigationStack/NavigationSplitView, alerts, sheets |
| `references/design.md` | Apple Human Interface Guidelines compliance |
| `references/accessibility.md` | Dynamic Type, VoiceOver, Reduce Motion |
| `references/performance.md` | Performance optimization |
| `references/swift.md` | Modern Swift and Swift Concurrency |
| `references/hygiene.md` | Code maintainability and cleanliness |

## Usage Examples

```bash
# Review a specific file
/swiftui-review Review ContentView.swift

# Check for deprecated API
/swiftui-review Check for deprecated SwiftUI APIs in this project

# Accessibility audit
/swiftui-review Audit accessibility compliance

# Full project review
/swiftui-review Review the entire SwiftUI project
```

## Requirements

- SwiftUI project (iOS 17+)
- Swift 5.9+
- Xcode 15+

## References

- [SwiftUI Agent Skill (Original)](https://github.com/twostraws/SwiftUI-Agent-Skill) by Paul Hudson
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines)

## Author

Frad LEE (fradser@gmail.com)

Based on work by Paul Hudson (twostraws)

## License

MIT
