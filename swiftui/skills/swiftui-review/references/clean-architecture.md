# Clean Architecture

Clean Architecture separates code into layers: Presentation → Domain ← Data. Dependencies point inward.


## Presentation Layer

- ViewModels must use `@Observable` (not `ObservableObject`) and be marked `@MainActor`.
- Views must be purely declarative – no business logic, no direct API calls, no database access.
- ViewModels must call Use Cases from Domain, never directly access repositories or network clients.
- Use `@State` for view-local UI state only (sheet presentation, focus), not domain data.
- Inject dependencies through initializers, never use singletons like `NetworkManager.shared`.
- ViewModels should expose `private(set)` state – views read, ViewModels write.


## Domain Layer

- Entities must be pure Swift with no framework imports (no `import SwiftUI`, no `import SwiftData`).
- Mark entities as `Sendable` when passed across concurrency boundaries.
- Never add `Codable` to domain entities – use separate DTOs in Data layer.
- Use Cases must encapsulate single operations: `GetProductsUseCase`, `AddToCartUseCase`.
- Repository protocols belong in Domain, implementations in Data (dependency inversion).
- Domain layer must have zero dependencies on other layers.


## Data Layer

- Repository implementations must map between DTOs and Domain entities.
- Never expose DTOs to Domain or Presentation layers.
- If using SwiftData, never mark `@Model` classes as `Sendable` – this causes runtime crashes.
- All SwiftData `ModelContext` operations must be on `@MainActor`.
- Repository implementations using SwiftData must be marked `@MainActor`.
- Keep SwiftData models in Data layer, separate from Domain entities.


## Common Violations

Flag these architectural violations:

- ViewModel calling API client directly instead of Use Case
- Domain entities importing SwiftUI or SwiftData
- SwiftData `@Model` classes marked as `Sendable`
- Repository implementations in Presentation layer
- Business logic in Views or ViewModels instead of Use Cases
- Singletons (`.shared`) used for testable dependencies
- DTOs exposed to Presentation layer
- Domain entities with `Codable` conformance


## Dependency Injection

- Create all dependencies at app entry point (Composition Root in `@main` struct).
- Use `@Environment` to pass dependencies down view hierarchy.
- Inject protocols, not concrete types, to enable mocking in tests.
