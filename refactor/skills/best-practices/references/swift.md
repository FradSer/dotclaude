# Swift Code Standards

## Code Style

### Naming Conventions
- **Types**: `UpperCamelCase` (classes, structs, enums, protocols)
- **Properties/Methods**: `lowerCamelCase`
- **Constants**: `lowerCamelCase` (not UPPER_CASE)
- **Enum cases**: `lowerCamelCase`
- **Acronyms**: Treat as words (`urlString`, not `uRLString`)

### Example
```swift
struct UserProfile {
    let userID: String
    let firstName: String
    var isActive: Bool

    func sendMessage(to recipient: User) {
        // Implementation
    }
}

enum NetworkError {
    case invalidURL
    case requestFailed
    case decodingError
}
```

## Type System

### Use Type Inference
- Let Swift infer types when clear from context
- Add explicit types when it improves readability
- Always specify types for public APIs

### Example
```swift
// Good - inference is clear
let name = "Alice"
let count = 42
let items = [1, 2, 3, 4, 5]

// Good - explicit type improves clarity
let timeout: TimeInterval = 30
var delegate: UserDelegate?

// Public API - always explicit
public func fetchUser(id: String) -> User? {
    // Implementation
    return nil
}
```

### Optionals
- Use optionals to represent absence of value
- Prefer optional binding (`if let`, `guard let`) over force unwrapping
- Use optional chaining for safe property access
- Use nil coalescing (`??`) for default values

### Example
```swift
// Good - optional binding
if let user = fetchUser(id: "123") {
    print(user.name)
}

// Good - guard for early exit
guard let user = fetchUser(id: "123") else {
    return
}

// Good - optional chaining
let emailLength = user?.email?.count

// Good - nil coalescing
let displayName = user?.name ?? "Anonymous"

// Avoid - force unwrapping (unless truly certain)
let user = fetchUser(id: "123")!  // Dangerous!
```

## Error Handling

### Throwing Functions
- Use `throws` for recoverable errors
- Create custom error types as enums
- Provide meaningful error messages

### Example
```swift
enum ValidationError: Error {
    case emptyField(String)
    case invalidFormat(String)
    case tooShort(minimum: Int)
}

func validateEmail(_ email: String) throws {
    guard !email.isEmpty else {
        throw ValidationError.emptyField("email")
    }

    guard email.contains("@") else {
        throw ValidationError.invalidFormat("email must contain @")
    }
}

// Using throwing functions
do {
    try validateEmail(userEmail)
    print("Email is valid")
} catch ValidationError.emptyField(let field) {
    print("\(field) cannot be empty")
} catch ValidationError.invalidFormat(let message) {
    print(message)
} catch {
    print("Unknown error: \(error)")
}
```

### Result Type
- Use `Result<Success, Failure>` for asynchronous operations
- Combine with `async/await` when appropriate

### Example
```swift
func fetchData() -> Result<Data, NetworkError> {
    // Implementation
    return .failure(.invalidURL)
}

// Using Result
switch fetchData() {
case .success(let data):
    print("Received \(data.count) bytes")
case .failure(let error):
    print("Error: \(error)")
}
```

## Properties

### Computed Properties
- Use computed properties for derived values
- Keep computed properties simple and fast
- Use stored properties for cached values

### Example
```swift
struct Rectangle {
    var width: Double
    var height: Double

    // Computed property
    var area: Double {
        width * height
    }

    // Computed property with getter and setter
    var aspectRatio: Double {
        get { width / height }
        set { width = height * newValue }
    }
}
```

### Property Observers
- Use `willSet` and `didSet` for side effects
- Don't use for complex logic

### Example
```swift
class ViewModel {
    var isLoading: Bool = false {
        didSet {
            if isLoading {
                showLoadingIndicator()
            } else {
                hideLoadingIndicator()
            }
        }
    }
}
```

## Functions and Methods

### Parameter Labels
- Use clear parameter labels
- Omit first parameter label when it reads naturally
- Use `_` to skip labels when appropriate

### Example
```swift
// Good - clear labels
func move(from start: Point, to end: Point) {
    // Implementation
}

// Good - natural reading without first label
func remove(_ element: Element) {
    // Implementation
}

// Usage reads naturally
move(from: pointA, to: pointB)
remove(element)
```

### Default Parameters
- Use default parameters for optional configuration
- Place parameters with defaults at the end

### Example
```swift
func createButton(
    title: String,
    style: ButtonStyle = .primary,
    action: @escaping () -> Void
) -> Button {
    // Implementation
}

// Usage
createButton(title: "Save") { save() }
```

## Protocols and Extensions

### Protocol-Oriented Programming
- Favor protocols and protocol extensions over inheritance
- Use protocols for abstraction
- Provide default implementations in extensions

### Example
```swift
protocol Fetchable {
    associatedtype DataType
    func fetch() async throws -> DataType
}

extension Fetchable {
    // Default implementation
    func fetchWithRetry(attempts: Int = 3) async throws -> DataType {
        for attempt in 1...attempts {
            do {
                return try await fetch()
            } catch {
                if attempt == attempts { throw error }
            }
        }
        fatalError("Unreachable")
    }
}

struct UserService: Fetchable {
    func fetch() async throws -> [User] {
        // Implementation
        return []
    }
}
```

### Extensions for Organization
- Use extensions to organize code by functionality
- Mark with `// MARK:` comments

### Example
```swift
class UserViewController {
    // Properties and initialization
}

// MARK: - UITableViewDataSource
extension UserViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
}

// MARK: - UITableViewDelegate
extension UserViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Handle selection
    }
}
```

## SwiftUI Specific

### View Composition
- Keep views small and focused
- Extract subviews for reusability
- Use `@ViewBuilder` for custom container views

### Example
```swift
struct UserProfileView: View {
    let user: User

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HeaderView(user: user)
            DetailsView(user: user)
            ActionButtons(user: user)
        }
    }
}

// Extracted subview
struct HeaderView: View {
    let user: User

    var body: some View {
        HStack {
            AsyncImage(url: user.avatarURL)
                .frame(width: 60, height: 60)
                .clipShape(Circle())

            VStack(alignment: .leading) {
                Text(user.name)
                    .font(.headline)
                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}
```

### State Management
- Use `@State` for view-local state
- Use `@Binding` to pass mutable state to child views
- Use `@StateObject` for view-owned observable objects
- Use `@ObservedObject` for externally-owned observable objects
- Use `@EnvironmentObject` for shared state across view hierarchy

### Example
```swift
class UserViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var isLoading = false

    func fetchUsers() async {
        isLoading = true
        // Fetch users
        isLoading = false
    }
}

struct UserListView: View {
    @StateObject private var viewModel = UserViewModel()
    @State private var searchText = ""

    var body: some View {
        NavigationView {
            List(filteredUsers) { user in
                UserRow(user: user)
            }
            .searchable(text: $searchText)
            .task {
                await viewModel.fetchUsers()
            }
        }
    }

    var filteredUsers: [User] {
        guard !searchText.isEmpty else { return viewModel.users }
        return viewModel.users.filter { $0.name.contains(searchText) }
    }
}

struct UserRow: View {
    let user: User
    @State private var isExpanded = false

    var body: some View {
        VStack {
            Text(user.name)
                .onTapGesture {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }

            if isExpanded {
                Text(user.details)
            }
        }
    }
}
```

## Concurrency (async/await)

### Async Functions
- Use `async/await` for asynchronous operations
- Mark functions with `async` when they perform async work
- Use `await` to call async functions

### Example
```swift
func fetchUser(id: String) async throws -> User {
    let url = URL(string: "https://api.example.com/users/\(id)")!
    let (data, _) = try await URLSession.shared.data(from: url)
    return try JSONDecoder().decode(User.self, from: data)
}

// Usage
Task {
    do {
        let user = try await fetchUser(id: "123")
        print(user.name)
    } catch {
        print("Error: \(error)")
    }
}
```

### Actors
- Use actors for thread-safe mutable state
- Actor methods are implicitly async

### Example
```swift
actor UserCache {
    private var cache: [String: User] = [:]

    func getUser(id: String) -> User? {
        cache[id]
    }

    func setUser(_ user: User) {
        cache[user.id] = user
    }
}

// Usage
let cache = UserCache()
await cache.setUser(user)
let cached = await cache.getUser(id: "123")
```

## Memory Management

### Weak and Unowned References
- Use `weak` for optional references that can become nil
- Use `unowned` for non-optional references that won't become nil
- Use `[weak self]` or `[unowned self]` in closures to avoid retain cycles

### Example
```swift
class UserViewController {
    var onComplete: (() -> Void)?

    func fetchData() {
        NetworkService.shared.fetchUsers { [weak self] users in
            guard let self = self else { return }
            self.users = users
            self.tableView.reloadData()
        }
    }
}
```

## Collection Operations

### Higher-Order Functions
- Use `map`, `filter`, `reduce`, `compactMap`, etc.
- Chain operations for clarity
- Avoid deeply nested operations

### Example
```swift
// Good - clear chain of operations
let activeUserNames = users
    .filter { $0.isActive }
    .map { $0.name }
    .sorted()

// Compact map for optional filtering
let validEmails = users
    .compactMap { $0.email }
    .filter { $0.contains("@") }
```

## Testing

### Unit Tests
- Use XCTest framework
- Name tests descriptively: `test_methodName_scenario_expectedResult`
- Use `Given-When-Then` pattern

### Example
```swift
class UserServiceTests: XCTestCase {
    func test_fetchUser_withValidID_returnsUser() async throws {
        // Given
        let service = UserService()
        let userID = "123"

        // When
        let user = try await service.fetchUser(id: userID)

        // Then
        XCTAssertEqual(user.id, userID)
        XCTAssertFalse(user.name.isEmpty)
    }

    func test_fetchUser_withInvalidID_throwsError() async {
        // Given
        let service = UserService()

        // When/Then
        do {
            _ = try await service.fetchUser(id: "invalid")
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
    }
}
```

## Documentation

### DocC Comments
- Use triple-slash `///` for documentation
- Include summary, parameters, returns, and throws

### Example
```swift
/// Fetches a user from the API.
///
/// This function retrieves user data by ID and decodes it into a User object.
///
/// - Parameter id: The unique identifier for the user.
/// - Returns: A User object with the user's data.
/// - Throws: `NetworkError.invalidURL` if the URL is malformed,
///           `NetworkError.decodingError` if the response can't be decoded.
func fetchUser(id: String) async throws -> User {
    // Implementation
}
```

## Code Organization

### File Structure
- One type per file (generally)
- Group related types in the same file when tightly coupled
- Use folders to organize by feature or layer

### MARK Comments
- Use `// MARK: -` to organize code sections
- Standard sections: Properties, Initialization, Public Methods, Private Methods

### Example
```swift
class UserViewController: UIViewController {
    // MARK: - Properties

    private var users: [User] = []

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // MARK: - Public Methods

    func refreshData() {
        // Implementation
    }

    // MARK: - Private Methods

    private func setupUI() {
        // Implementation
    }
}
```

## Project-Specific Standards

Always check the project's `CLAUDE.md` file for additional project-specific standards that override or extend these guidelines.
