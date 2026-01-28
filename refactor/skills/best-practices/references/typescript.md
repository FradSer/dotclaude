# TypeScript / JavaScript Code Standards

## Module System

### ES Modules
- Use ES modules (`import`/`export`) over CommonJS
- Organize imports in logical groups:
  1. External dependencies
  2. Internal absolute imports
  3. Relative imports
- Remove unused imports

### Example
```typescript
// External dependencies
import React from 'react'
import { useState } from 'react'

// Internal absolute imports
import { Button } from '@/components/Button'
import { useAuth } from '@/hooks/useAuth'

// Relative imports
import { helper } from './utils'
```

## Functions

### Function Declarations vs Arrow Functions
- **Prefer `function` keyword** for top-level functions
- **Use arrow functions** for:
  - Callbacks and inline functions
  - Methods that need lexical `this`
  - Array methods (map, filter, reduce)

### Example
```typescript
// Top-level function - use function keyword
function calculateTotal(items: Item[]): number {
  return items.reduce((sum, item) => sum + item.price, 0)
}

// Arrow functions for callbacks
const filtered = items.filter(item => item.isActive)

// Arrow functions for lexical this
class Component {
  handleClick = () => {
    // 'this' is lexically bound
  }
}
```

## Type Annotations

### Explicit Return Types
- Add explicit return type annotations for **top-level functions**
- TypeScript can infer types for simple functions, but explicit types improve readability and catch errors

### Example
```typescript
// Good - explicit return type
function getUser(id: string): Promise<User> {
  return api.fetchUser(id)
}

// Acceptable - simple inline functions can rely on inference
const double = (n: number) => n * 2
```

### Type vs Interface
- Use `type` for unions, intersections, and primitives
- Use `interface` for object shapes that may be extended
- Be consistent within a file or module

### Generic Types
- Use generic types for reusable components and functions
- Provide default types when appropriate
- Avoid overly complex generic constraints

## React Patterns

For comprehensive performance and best practice rules, see [`react.md`](react/react.md).

### Component Props
- Always define explicit Props types
- Use `interface` for component props
- Destructure props in function signature when simple

### Example
```typescript
interface ButtonProps {
  label: string
  onClick: () => void
  disabled?: boolean
}

function Button({ label, onClick, disabled = false }: ButtonProps) {
  return (
    <button onClick={onClick} disabled={disabled}>
      {label}
    </button>
  )
}
```

### Hooks
- Follow React hooks rules (don't call in loops/conditions)
- Extract custom hooks for reusable logic
- Prefix custom hooks with `use`

### State Management
- Use appropriate state management:
  - `useState` for simple component state
  - `useReducer` for complex state logic
  - Context for shared state
  - External libraries (Redux, Zustand) for app-wide state

## Error Handling

### Async/Await over Promises
- Prefer `async/await` over promise chains for readability
- Handle errors with try/catch blocks **only when you can recover**
- Don't catch errors just to log and rethrow

### Example
```typescript
// Good - specific error handling
async function fetchData(): Promise<Data> {
  const response = await fetch('/api/data')
  if (!response.ok) {
    throw new Error(`HTTP ${response.status}: ${response.statusText}`)
  }
  return response.json()
}

// Avoid - empty catch or just logging
async function badExample() {
  try {
    await fetchData()
  } catch (error) {
    console.log(error) // Don't just log and swallow
  }
}
```

### Error Boundaries (React)
- Use Error Boundaries for catching rendering errors
- Provide fallback UI for better user experience

## TypeScript-Specific

### Strict Mode
- Enable strict mode in `tsconfig.json`
- Avoid `any` type - use `unknown` when type is truly unknown
- Use type guards to narrow types

### Type Guards
```typescript
function isString(value: unknown): value is string {
  return typeof value === 'string'
}

function process(value: unknown) {
  if (isString(value)) {
    // value is now typed as string
    console.log(value.toUpperCase())
  }
}
```

### Null Safety
- Use optional chaining (`?.`) for safe property access
- Use nullish coalescing (`??`) for default values
- Avoid "!" (non-null assertion) unless absolutely certain

### Example
```typescript
// Good - safe access
const username = user?.profile?.name ?? 'Anonymous'

// Avoid - non-null assertion (unless you're certain)
const username = user!.profile!.name
```

## Naming Conventions

### Variables and Functions
- Use camelCase: `getUserName`, `isValid`
- Use descriptive names over abbreviations

### Types and Interfaces
- Use PascalCase: `User`, `ButtonProps`
- Suffix interfaces with Props when appropriate: `ButtonProps`, `UserCardProps`

### Constants
- Use UPPER_SNAKE_CASE for true constants: `MAX_RETRY_COUNT`, `API_BASE_URL`
- Use camelCase for configuration objects

### Files
- Use kebab-case for file names: `user-profile.ts`, `api-client.ts`
- Match file name to primary export: `Button.tsx` exports `Button` component

## Code Organization

### File Structure
- One primary export per file
- Group related code together
- Keep files focused and reasonably sized

### Barrel Exports
- Use index files for clean imports: `@/components` instead of `@/components/Button/Button`
- Don't overuse - can impact tree-shaking

## Modern JavaScript/TypeScript Features

### Destructuring
- Use destructuring for object and array access
- Use rest/spread operators appropriately

### Optional Chaining and Nullish Coalescing
- Use `?.` for safe property access
- Use `??` for default values (not `||` which treats 0 and '' as falsy)

### Template Literals
- Use template literals for string interpolation
- Use tagged templates for complex formatting

### Array Methods
- Use `map`, `filter`, `reduce` over manual loops when appropriate
- Chain methods for readability

### Example
```typescript
// Good - functional approach
const activeUserNames = users
  .filter(user => user.isActive)
  .map(user => user.name)
  .sort()
```

## Performance Considerations

### React Optimization
- Use `React.memo` for expensive components
- Use `useMemo` for expensive calculations
- Use `useCallback` for stable function references
- **Don't over-optimize** - measure first

### Avoid Premature Optimization
- Write clear code first
- Optimize only when performance issues are identified
- Use profiling tools to identify bottlenecks

## Testing

### Test Structure
- Use descriptive test names
- Follow Arrange-Act-Assert pattern
- Test behavior, not implementation

### React Testing
- Test user interactions, not implementation details
- Use Testing Library queries in order of preference:
  1. getByRole
  2. getByLabelText
  3. getByPlaceholderText
  4. getByText
  5. getByTestId (last resort)

## Project-Specific Standards

Always check the project's `CLAUDE.md` file for additional project-specific standards that override or extend these guidelines.
