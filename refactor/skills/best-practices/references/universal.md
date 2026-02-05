# Universal Code Quality Principles

These principles apply across all programming languages and paradigms. Always follow these guidelines regardless of the specific language you're working with.

## Core Principles

### SOLID Principles
- **Single Responsibility**: Each module/class/function should have one reason to change
- **Open/Closed**: Open for extension, closed for modification
- **Liskov Substitution**: Derived types must be substitutable for their base types
- **Interface Segregation**: No client should depend on methods it doesn't use
- **Dependency Inversion**: Depend on abstractions, not concretions

### DRY (Don't Repeat Yourself)
- Eliminate code duplication
- Extract common patterns into reusable functions/modules
- Create abstractions for repeated logic

### KISS (Keep It Simple, Stupid)
- Prefer simplicity over cleverness
- Avoid unnecessary complexity
- Write code that's easy to understand and maintain

### YAGNI (You Aren't Gonna Need It)
- Don't implement features until they're actually needed
- Avoid speculative generalization
- Focus on current requirements

### Convention over Configuration
- Follow established conventions and defaults
- Minimize configuration where sensible defaults exist

### Law of Demeter (Principle of Least Knowledge)
- Objects should only talk to their immediate friends
- Minimize coupling between components

## Code Quality Attributes

### Readability
- Use clear, descriptive names for variables, functions, and classes
- Avoid abbreviations unless they're standard in the domain
- Maintain consistent formatting and style
- Keep line length reasonable (typically 80-120 characters)

### Maintainability
- Keep functions small and focused (typically < 50 lines)
- Maintain low cyclomatic complexity
- Use meaningful structure and organization
- Write self-documenting code

### Reliability
- Handle errors explicitly and meaningfully
- Validate input at system boundaries (user input, external APIs)
- Trust internal code and framework guarantees
- Avoid defensive programming for scenarios that can't happen

### Testability
- Design for testability from the start
- Use dependency injection for better isolation
- Keep units small and focused
- Minimize global state and side effects

## Code Smells to Avoid

### Structure Smells
- **Long methods**: Break down into smaller, focused functions
- **Large classes**: Split into cohesive, single-responsibility classes
- **Deep nesting**: Use guard clauses and early returns
- **Long parameter lists**: Group related parameters into objects

### Logic Smells
- **Duplicate code**: Extract common patterns
- **Complex conditionals**: Extract into well-named functions
- **Magic numbers**: Use named constants
- **Global state**: Prefer local state and explicit parameters

### Organization Smells
- **Shotgun surgery**: Changes require modifications in many places
- **Divergent change**: A class changes for multiple reasons
- **Feature envy**: A method uses more features of another class than its own

## File and Module Organization

### When to Split Files

Split files based on behavior and responsibility, not arbitrary size limits. Use these signals to identify when splitting is necessary:

#### Signals Requiring File Splitting
- **Multiple Responsibilities**: File handles multiple unrelated concerns or business domains
- **Shotgun Surgery**: Modifications require changes across multiple sections of the same file
- **Divergent Change**: File changes for multiple different reasons
- **Large Class Smell**: Single class or module exceeds cohesion boundaries
- **Domain Boundaries**: File mixes code from different business domains

#### File Size Guidelines

**Functions**:
- Target: < 40-50 lines per function
- Extract methods when logic becomes complex or handles multiple tasks
- Each function should fit on one screen

**Files**:
- Apply Single Responsibility Principle
- File length itself is NOT a primary concern
- Focus on cohesion, coupling, and single responsibility
- A 500-line file with one clear responsibility is better than 5 unfocused 100-line files

**Language-Specific Details**: See language-specific references for file structure conventions (TypeScript, Swift, Go, Python)

### File Organization Strategies

#### Domain-Driven Splitting
For systems spanning multiple business domains:
- Split along domain boundaries (e.g., Accounts, Orders, Products, Shipping)
- Group related functionality within domain folders
- Maintain clear boundaries between domains

#### Incremental Refactoring
- **Small Steps**: Prefer incremental changes over large rewrites
- **Test First**: Ensure tests exist before splitting
- **Track Progress**: Identify and estimate cleanup efforts
- **Monitor Impact**: Measure performance before and after

### When NOT to Split

Avoid splitting in these cases:
- **Tight Coupling**: Types/functions are tightly coupled and always used together
- **Artificial Limits**: Splitting just to meet line count targets
- **Loss of Cohesion**: Splitting would separate related functionality
- **Increased Complexity**: More files would make code harder to understand

## Refactoring Techniques

### Function Extraction
- Extract complex logic into well-named functions
- Each function should do one thing well
- Aim for functions that fit on one screen

### Loop Optimization
- Flatten nested loops where possible
- Extract loop bodies into functions
- Consider functional approaches (map, filter, reduce)

### Conditional Simplification
- Use guard clauses to reduce nesting
- Extract conditions into well-named functions
- Prefer early returns over deep nesting
- Consider polymorphism for complex conditionals

### Abstraction and Encapsulation
- Hide implementation details
- Expose minimal, well-defined interfaces
- Group related data and behavior together

## Comments and Documentation

### When to Comment
- **Why, not what**: Explain business logic and complex decisions
- **Non-obvious implications**: Warning about side effects or constraints
- **Public APIs**: Document interface contracts and usage

### When NOT to Comment
- **Obvious code**: If the code is self-explanatory, don't comment
- **Outdated comments**: Remove or update stale comments
- **Commented-out code**: Delete it (version control keeps history)

## Naming Conventions

### General Rules
- Names should reveal intent
- Use pronounceable names
- Use searchable names
- Avoid encodings and prefixes
- One word per concept

### Context-Specific
- **Functions**: Use verbs (calculate, get, set, is, has)
- **Classes**: Use nouns (User, Product, Service)
- **Booleans**: Use predicates (isValid, hasPermission, canDelete)
- **Constants**: Use descriptive names explaining purpose

## Error Handling

### Universal Patterns
- Fail fast: Detect errors early
- Provide context: Include meaningful error messages
- Don't swallow errors: Handle or propagate, never ignore
- Validate at boundaries: Check input from users and external systems
- Trust internal code: Don't add defensive checks for internal invariants

### What NOT to Do
- Empty catch blocks
- Generic error messages without context
- Catching errors you can't handle
- Using exceptions for control flow

## Performance Considerations

### Premature Optimization
- Focus on correctness and clarity first
- Optimize only after profiling identifies bottlenecks
- Measure before and after optimization

### Universal Patterns
- Avoid unnecessary object creation in loops
- Use appropriate data structures for the task
- Cache expensive computations when appropriate
- Consider algorithmic complexity (Big O)

## Testing Guidelines

### Test Structure
- Arrange-Act-Assert pattern
- One assertion concept per test
- Test behavior, not implementation
- Use descriptive test names

### Test Coverage
- Test happy paths and edge cases
- Test error conditions
- Focus on public interfaces
- Don't test trivial code

## Continuous Improvement

### Regular Refactoring
- Refactor as you go (Boy Scout Rule: leave code better than you found it)
- Address technical debt incrementally
- Don't let small issues accumulate

### Code Review
- Review for design and architecture, not just bugs
- Look for code smells and improvement opportunities
- Ensure code follows project conventions
