# CLAUDE.md

## Project Overview

SwiftUI iOS book reading tracker app with cultural diversity tracking. Uses SwiftData for persistence with iOS 26 Liquid Glass design system.

### Current Status
- ✅ **Build Status**: Successfully builds and runs (iPhone 16 Pro, iOS 18.0)
- ✅ **iOS 26 Foundation**: Complete with UnifiedThemeStore (5 MD3 + 6 Liquid Glass themes)
- 🚀 **Next Phase**: Core Experience Migration (SearchView, LibraryView, ContentView)

## Development Commands

### Building and Testing
- **Build**: `build_sim({ projectPath: "books.xcodeproj", scheme: "books", simulatorName: "iPhone 16" })`
- **Run**: `build_run_sim({ projectPath: "books.xcodeproj", scheme: "books", simulatorName: "iPhone 16" })`
- **Test**: `test_sim({ projectPath: "books.xcodeproj", scheme: "books", simulatorName: "iPhone 16" })`

### Project Structure
- **Main project**: `books_build2/books.xcodeproj`
- **Targets**: `books` (main app), `booksTests`, `booksUITests`

### SwiftLens Tools
- `swift_get_symbols_overview("file_path")` - Quick file structure
- `swift_analyze_files(["file_path"])` - Comprehensive analysis
- `swift_replace_symbol_body("file_path", "symbol", "new_body")` - Targeted edits
- `swift_validate_file("file_path")` - Syntax validation

### Search Infrastructure
CloudFlare Workers proxy at `https://books-api-proxy.jukasdrj.workers.dev` with Google Books API → ISBNdb → Open Library fallback.

## Architecture

### Core Models (SwiftData)
- **UserBook**: Personal book data with reading status, ratings, cultural metadata
- **BookMetadata**: Book information from APIs with cultural diversity fields

### App Structure
- **Entry**: `booksApp.swift` - SwiftData ModelContainer setup
- **Root**: `ContentView.swift` - 3-tab navigation (Library, Search, Reading Insights)
- **Theme**: **UnifiedThemeStore** - 11 theme variants (5 MD3 + 6 Liquid Glass)
- **Navigation**: Modern NavigationStack with value-based routing

### Key Services
- **BookSearchService**: CloudFlare proxy integration
- **CSVImportService**: Goodreads import with validation
- **UnifiedThemeStore**: Theme management
- **KeychainService**: Secure data storage

## Development Patterns

### Swift 6 & iOS 26 Compliance
- **Concurrency**: `@MainActor` UI, `async/await`, proper Sendable conformance
- **Design System**: Liquid Glass materials with 5 glass levels (ultraThin → chrome)
- **Modification Workflow**: `swift_get_symbols_overview` → analyze → modify → `swift_validate_file`
- **Navigation**: Modern NavigationStack with value-based routing
- **Security**: KeychainService for sensitive data, HTTPS-only APIs

### Design Components
- **Glass Modifiers**: `.liquidGlassCard()`, `.liquidGlassButton()`, `.liquidGlassVibrancy()`
- **Card Layout**: Fixed 140x260 dimensions
- **Cultural Diversity**: Author demographics, language, regional tracking

## File Organization

### Key Entry Points
- **App Entry**: `books/App/booksApp.swift`
- **Root Content**: `books/Views/Main/ContentView.swift`
- **Theme System**: `books/Theme/ThemeSystemBridge.swift`
- **Data Models**: `books/Models/UserBook.swift`, `books/Models/BookMetadata.swift`

### Views Structure
- `Views/Main/`: Primary screens (ContentView, LibraryView, SearchView, ReadingInsightsView)
- `Views/Detail/`: Detail screens (BookDetailsView, EditBookView)
- `Views/Components/`: Reusable UI components
- `Views/Import/`: CSV import flow
- `Services/`: API integration, import services
- `Theme/`: iOS 26 Liquid Glass system

## Cultural Diversity Features

Strong focus on cultural diversity tracking:
- **Author Demographics**: Nationality, gender (Female, Male, Non-binary, Other, Not specified)
- **Language & Translation**: Original language and translation info
- **Regional Categorization**: Africa, Asia, Europe, Americas
- **Visual Analytics**: Diversity patterns and progress


# important-instruction-reminders
Do what has been asked; nothing more, nothing less.
NEVER create files unless they're absolutely necessary for achieving your goal.
ALWAYS prefer editing an existing file to creating a new one.
NEVER proactively create documentation files (*.md) or README files. Only create documentation files if explicitly requested by the User.