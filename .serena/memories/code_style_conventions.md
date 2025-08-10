# Code Style & Conventions

## SwiftUI Conventions
### View Structure
- Use `struct` for all SwiftUI views
- Implement `View` protocol with `var body: some View`
- Prefer composition over inheritance
- Keep view bodies concise - extract complex logic to computed properties or methods

### State Management
- Use `@StateObject` for view models and managers
- Use `@State` for simple local view state
- Use `@Binding` for two-way data flow
- SwiftData: Use `modelContext.fetch()` in navigation destinations instead of `@Query`

### Navigation Patterns
- Centralized navigation destinations at ContentView level
- Value-based routing: `NavigationLink(value: item)`
- Avoid multiple `navigationDestination` declarations per NavigationStack

## Material Design 3 System
### Required Modifiers
- `.materialCard()` for all card-like components
- `.materialButton(style: .filled/.tonal/.outlined)` for buttons  
- `.materialInteractive()` for interactive elements
- Use `Theme.Spacing` constants for all spacing (8pt grid system)

### Theme Usage
- All colors through theme system: `theme.colors.primary`
- No hardcoded colors or spacing values
- Support both light and dark modes automatically

## SwiftData Best Practices
### Model Conventions
- Use `@Model` decorator on classes
- Implement `Hashable` with unique identifiers
- Use optionals appropriately for nullable fields
- Include proper migration strategies

### Data Access
- Prefer `modelContext.fetch()` over `@Query` in navigation contexts
- Use proper error handling for data operations
- Implement validation methods for user input

## File Organization
### Naming Conventions
- Views: `SomethingView.swift`
- Models: Descriptive names like `UserBook.swift`
- Services: `SomethingService.swift`
- Extensions: `Type+Extensions.swift`

### Code Organization
- Group related functionality in extensions
- Use `// MARK: -` comments for section organization
- Keep files focused on single responsibility

## Testing Conventions
### Unit Tests
- Test file naming: `FeatureTests.swift`
- Use descriptive test method names: `testBookImportWithValidISBN()`
- Follow Arrange-Act-Assert pattern
- Mock external dependencies

### UI Tests  
- Focus on critical user workflows
- Use accessibility identifiers for reliable element selection
- Test both happy path and error scenarios