# Go Code Standards

Language-specific guidelines for Go projects following Go idioms and best practices. Always apply [universal.md](universal.md) principles in addition to these language-specific rules.

## Code Style

### Formatting
- Use `gofmt` or `goimports` for automatic formatting
- Go has a canonical style - follow it
- No arguments about formatting - the tooling decides

### Naming Conventions
- **Packages**: short, lowercase, single-word names (`http`, `json`, `user`)
- **Exported names**: Start with capital letter (`UserService`, `GetUser`)
- **Unexported names**: Start with lowercase letter (`userCache`, `validateEmail`)
- **Interfaces**: Noun or Agent noun (`Reader`, `Writer`, `Handler`)
- **Single-method interfaces**: Method name + `-er` suffix (`Reader`, `Closer`)

### Example
```go
package user

// Exported type
type User struct {
    ID   string
    Name string
}

// Exported function
func GetUser(id string) (*User, error) {
    return findUser(id)
}

// Unexported function
func findUser(id string) (*User, error) {
    // Implementation
    return nil, nil
}

// Interface following naming convention
type UserFinder interface {
    FindUser(id string) (*User, error)
}
```

## Error Handling

### Return Errors, Don't Panic
- Return errors as the last return value
- Check errors immediately
- Don't ignore errors (use `_` only when justified)
- Panic only for programming errors or initialization failures

### Example
```go
// Good - explicit error handling
func ReadConfig(path string) (*Config, error) {
    data, err := os.ReadFile(path)
    if err != nil {
        return nil, fmt.Errorf("read config: %w", err)
    }

    var config Config
    if err := json.Unmarshal(data, &config); err != nil {
        return nil, fmt.Errorf("parse config: %w", err)
    }

    return &config, nil
}

// Bad - ignoring errors
func badReadConfig(path string) *Config {
    data, _ := os.ReadFile(path)  // Don't do this!
    var config Config
    json.Unmarshal(data, &config)
    return &config
}
```

### Error Wrapping (Go 1.13+)
- Use `%w` verb with `fmt.Errorf` to wrap errors
- Use `errors.Is()` and `errors.As()` to check wrapped errors
- Add context when wrapping errors

### Example
```go
import "errors"

var ErrNotFound = errors.New("not found")

func GetUser(id string) (*User, error) {
    user, err := db.FindUser(id)
    if err != nil {
        if errors.Is(err, sql.ErrNoRows) {
            return nil, ErrNotFound
        }
        return nil, fmt.Errorf("get user %s: %w", id, err)
    }
    return user, nil
}

// Checking errors
user, err := GetUser("123")
if errors.Is(err, ErrNotFound) {
    // Handle not found case
}
```

## Functions and Methods

### Receiver Types
- Use pointer receivers when:
  - Method modifies the receiver
  - Receiver is large struct
  - Consistency (if one method uses pointer, use for all)
- Use value receivers for:
  - Small, immutable types
  - Types that are copied anyway

### Example
```go
// Pointer receiver - modifies state
func (u *User) SetName(name string) {
    u.Name = name
}

// Value receiver - no modification
func (u User) FullName() string {
    return u.FirstName + " " + u.LastName
}
```

### Multiple Return Values
- Use multiple return values to return result and error
- Name return values only when it improves clarity
- Avoid named returns in complex functions

### Example
```go
// Clear without named returns
func Divide(a, b float64) (float64, error) {
    if b == 0 {
        return 0, errors.New("division by zero")
    }
    return a / b, nil
}

// Named returns for clarity (use sparingly)
func SplitName(full string) (first, last string) {
    parts := strings.Split(full, " ")
    if len(parts) > 0 {
        first = parts[0]
    }
    if len(parts) > 1 {
        last = parts[1]
    }
    return
}
```

## Interfaces

### Accept Interfaces, Return Structs
- Accept interfaces as parameters (flexible)
- Return concrete types (clear API)
- Define interfaces where they're used, not where they're implemented

### Example
```go
// Define interface in consumer package
type UserStore interface {
    GetUser(id string) (*User, error)
    SaveUser(user *User) error
}

// Accept interface
func ProcessUser(store UserStore, id string) error {
    user, err := store.GetUser(id)
    if err != nil {
        return err
    }
    // Process user
    return store.SaveUser(user)
}

// Return concrete type
func NewUserCache() *UserCache {
    return &UserCache{
        data: make(map[string]*User),
    }
}
```

### Small Interfaces
- Prefer small, focused interfaces
- Single-method interfaces are common and idiomatic
- Compose larger interfaces from smaller ones

## Concurrency

### Goroutines and Channels
- Use goroutines for concurrent operations
- Use channels to communicate between goroutines
- Always ensure goroutines exit (avoid leaks)
- Use `sync.WaitGroup` or channels to wait for completion

### Example
```go
func ProcessItems(items []Item) []Result {
    results := make(chan Result, len(items))

    for _, item := range items {
        go func(item Item) {
            results <- processItem(item)
        }(item)  // Pass item to avoid closure capture issue
    }

    // Collect results
    output := make([]Result, 0, len(items))
    for i := 0; i < len(items); i++ {
        output = append(output, <-results)
    }

    return output
}
```

### Context for Cancellation
- Use `context.Context` for cancellation and deadlines
- Pass context as first parameter
- Respect context cancellation

### Example
```go
func FetchData(ctx context.Context, url string) ([]byte, error) {
    req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
    if err != nil {
        return nil, err
    }

    resp, err := http.DefaultClient.Do(req)
    if err != nil {
        return nil, err
    }
    defer resp.Body.Close()

    return io.ReadAll(resp.Body)
}
```

## Package Organization

### Package Structure
- Group related functionality
- Keep packages focused and cohesive
- Avoid circular dependencies
- Use internal packages for implementation details

### Example Structure
```
myapp/
├── cmd/
│   └── myapp/
│       └── main.go
├── internal/
│   ├── user/
│   │   ├── user.go
│   │   ├── store.go
│   │   └── handler.go
│   └── auth/
│       └── auth.go
└── pkg/
    └── api/
        └── client.go
```

### Import Organization
- Standard library first
- Third-party packages second
- Local packages last
- Use `goimports` to organize automatically

## Testing

### Table-Driven Tests
- Use table-driven tests for multiple test cases
- Name test cases clearly
- Test both success and error paths

### Example
```go
func TestAdd(t *testing.T) {
    tests := []struct {
        name     string
        a, b     int
        expected int
    }{
        {"positive numbers", 2, 3, 5},
        {"negative numbers", -2, -3, -5},
        {"mixed signs", 5, -3, 2},
        {"with zero", 5, 0, 5},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            result := Add(tt.a, tt.b)
            if result != tt.expected {
                t.Errorf("Add(%d, %d) = %d; want %d",
                    tt.a, tt.b, result, tt.expected)
            }
        })
    }
}
```

### Test Helpers
- Use `t.Helper()` to mark helper functions
- Create test fixtures for complex setup

## Common Patterns

### Constructor Functions
- Use `New` or `NewType` for constructors
- Return pointers to structs
- Initialize all fields

### Example
```go
func NewUser(id, name string) *User {
    return &User{
        ID:        id,
        Name:      name,
        CreatedAt: time.Now(),
    }
}
```

### Options Pattern
- Use functional options for flexible configuration
- Good for types with many optional parameters

### Example
```go
type Server struct {
    port    int
    timeout time.Duration
}

type Option func(*Server)

func WithPort(port int) Option {
    return func(s *Server) {
        s.port = port
    }
}

func WithTimeout(timeout time.Duration) Option {
    return func(s *Server) {
        s.timeout = timeout
    }
}

func NewServer(opts ...Option) *Server {
    s := &Server{
        port:    8080,
        timeout: 30 * time.Second,
    }

    for _, opt := range opts {
        opt(s)
    }

    return s
}

// Usage
server := NewServer(
    WithPort(9000),
    WithTimeout(60 * time.Second),
)
```

## Memory and Performance

### Slice Capacity
- Pre-allocate slices when size is known
- Use `make` with capacity to avoid reallocations

### Example
```go
// Good - pre-allocate
items := make([]Item, 0, 100)
for i := 0; i < 100; i++ {
    items = append(items, Item{ID: i})
}

// Less efficient
items := []Item{}
for i := 0; i < 100; i++ {
    items = append(items, Item{ID: i})
}
```

### String Building
- Use `strings.Builder` for efficient string concatenation
- Avoid `+` operator in loops

### Example
```go
var b strings.Builder
for _, word := range words {
    b.WriteString(word)
    b.WriteString(" ")
}
result := b.String()
```

## Documentation

### Godoc Comments
- Start with the name being documented
- Write complete sentences
- Use examples when helpful

### Example
```go
// User represents a user in the system.
type User struct {
    ID   string
    Name string
}

// GetUser retrieves a user by ID.
// It returns ErrNotFound if the user doesn't exist.
func GetUser(id string) (*User, error) {
    // Implementation
    return nil, nil
}
```

## Tools and Linting

### Essential Tools
- `go fmt` / `gofmt`: Format code
- `goimports`: Organize imports
- `go vet`: Static analysis
- `golangci-lint`: Comprehensive linting
- `go mod`: Dependency management

### Run Before Commit
```bash
go fmt ./...
goimports -w .
go vet ./...
golangci-lint run
go test ./...
```

## Project-Specific Standards

Always check the project's `CLAUDE.md` file for additional project-specific standards that override or extend these guidelines.
