# SwiftUI Plugin

SwiftUI Clean Architecture reviewer for iOS/macOS development.

## Overview

The SwiftUI Plugin provides specialized architecture review for SwiftUI applications following Clean Architecture + MVVM patterns. It ensures strict adherence to modern Swift development standards and 2024-2025 best practices.

## Agent

### `swiftui-clean-architecture-reviewer`

Expert Clean Architecture reviewer specializing in SwiftUI applications following 2024-2025 best practices.

**What it does:**
- Reviews SwiftUI code implementations for Clean Architecture compliance
- Identifies architectural violations
- Provides actionable improvement recommendations
- Enforces MVVM patterns with modern Swift standards
- Ensures proper layer separation and dependency rules

**Focus areas:**
- **4-Layer Clean Architecture Structure**:
  - Presentation Layer (@Observable ViewModels + SwiftUI Views)
  - Use Cases (business logic coordination)
  - Domain Models (pure business entities)
  - Data/Infrastructure (repositories and data sources)

**Architecture principles enforced:**
- Dependency Inversion: Inner layers don't depend on outer layers
- Single Responsibility: Each component has one clear purpose
- Interface Segregation: Protocols define minimal required interfaces
- Dependency Injection: Dependencies injected via initializers
- Testability: All business logic testable in isolation

**Model:** Opus

**Color:** Red

**When triggered:**
- Can be invoked manually: `@swiftui-clean-architecture-reviewer Review this SwiftUI code`
- Used automatically in architecture reviews

**Review process:**
1. Analyzes SwiftUI code structure
2. Checks layer separation and dependencies
3. Verifies MVVM pattern implementation
4. Reviews ViewModel @Observable usage
5. Checks @MainActor isolation
6. Validates dependency injection
7. Identifies architectural violations
8. Provides specific improvement recommendations

**Example usage:**
```
@swiftui-clean-architecture-reviewer Review the authentication module in AuthView.swift
```

**Key checks:**
- Presentation Layer uses @Observable (not ObservableObject)
- ViewModels are @MainActor isolated
- Use Cases contain business logic coordination
- Domain Models are pure Swift structs/classes
- Data layer implements repository pattern
- Dependencies flow inward (Dependency Inversion)
- No business logic in Views
- Proper error handling and state management

## Installation

This plugin is included in the Claude Code repository. The agent is automatically available when using Claude Code.

## Best Practices

### Using the Reviewer

**For new SwiftUI features:**
```swift
// Ask for architecture review before implementing
@swiftui-clean-architecture-reviewer Review this feature design
```

**For existing code:**
```swift
// Review existing implementations
@swiftui-clean-architecture-reviewer Review src/features/Auth/
```

**For architecture decisions:**
```swift
// Get architecture guidance
@swiftui-clean-architecture-reviewer How should I structure this feature?
```

### Architecture Guidelines

**Presentation Layer (ViewModels + Views):**
- Use `@Observable` macro (not `ObservableObject`)
- Mark ViewModels with `@MainActor`
- Views should be pure SwiftUI without business logic
- Use dependency injection for ViewModels

**Use Cases:**
- Contain business logic coordination
- Are independent of framework details
- Can be tested in isolation
- Define clear input/output protocols

**Domain Models:**
- Pure Swift types (structs/classes)
- No framework dependencies
- Represent business concepts
- Are platform-agnostic

**Data/Infrastructure:**
- Implement repository pattern
- Handle data persistence
- Manage network requests
- Provide data to Use Cases via protocols

## Workflow Integration

### Feature Development Workflow:
```bash
# Design feature architecture
@swiftui-clean-architecture-reviewer Review this feature design

# Implement feature
# ...

# Review implementation
@swiftui-clean-architecture-reviewer Review src/features/NewFeature/
```

### Code Review Workflow:
```bash
# Review existing code
@swiftui-clean-architecture-reviewer Review src/features/Auth/

# Address architectural issues
# Re-review after fixes
```

### Architecture Refactoring:
```bash
# Review entire module
@swiftui-clean-architecture-reviewer Review src/features/

# Refactor based on recommendations
# Re-review to verify improvements
```

## Requirements

- SwiftUI project (iOS 17+ or macOS 14+)
- Swift 5.9+ for @Observable support
- Clean Architecture understanding
- MVVM pattern familiarity

## Troubleshooting

### Agent doesn't understand SwiftUI code

**Issue**: Reviewer doesn't recognize SwiftUI patterns

**Solution**:
- Ensure code follows standard SwiftUI patterns
- Use modern SwiftUI features (@Observable, @MainActor)
- Check if code is properly structured
- Provide more context about the codebase

### Too many architectural violations

**Issue**: Agent finds many violations in existing code

**Solution**:
- This is normal for legacy code
- Address violations incrementally
- Focus on critical violations first
- Use agent guidance to refactor gradually

### Recommendations are too strict

**Issue**: Agent recommendations seem overly strict

**Solution**:
- Clean Architecture has strict rules by design
- Review recommendations carefully
- Some violations may be acceptable trade-offs
- Discuss with team about architecture standards

## Tips

- **Review early**: Catch architectural issues during design
- **Use modern SwiftUI**: @Observable and @MainActor are best practices
- **Follow dependency rules**: Dependencies must flow inward
- **Keep Views simple**: Business logic belongs in ViewModels/Use Cases
- **Test Use Cases**: Business logic should be testable in isolation

## References

- [Clean Architecture by Robert C. Martin](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [SwiftUI @Observable Documentation](https://developer.apple.com/documentation/observation)
- [MVVM Pattern in SwiftUI](https://www.hackingwithswift.com/books/ios-swiftui/introducing-mvvm-into-your-swiftui-project)

## Author

Frad LEE (fradser@gmail.com)

## Version

1.0.0
