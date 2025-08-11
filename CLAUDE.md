# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a SwiftUI iOS book reading tracker app with cultural diversity tracking features. The app uses SwiftData for persistence and follows Material Design 3 patterns with a multi-theme system. The main project is located in `books_build2/`.

## Development Commands

### Building and Testing
- **Build**: Use Xcode's standard build (⌘+B) or Product → Build
- **Run**: Use Xcode's run (⌘+R) or Product → Run  
- **Test**: Use Xcode's test (⌘+U) or Product → Test
- **Unit Tests**: Run `booksTests` target for model and service tests
- **UI Tests**: Run `booksUITests` target for interface tests

### Xcode Project Structure
- Main project: `books_build2/books.xcodeproj`
- Scheme: `books.xcscheme` (configured for Debug/Release builds)
- Three targets: `books` (main app), `booksTests`, `booksUITests`

## Architecture

### Core Data Models (SwiftData)
- **UserBook**: User's personal book data with reading status, progress, ratings, and cultural metadata
- **BookMetadata**: Book information from Google Books API with cultural diversity fields
- Both models use SwiftData `@Model` and implement proper migration strategies

### App Structure
- **Main Entry**: `booksApp.swift` - Configures SwiftData ModelContainer with migration handling
- **Root View**: `ContentView.swift` - 4-tab TabView (Library, Search, Stats, Culture) with consolidated NavigationStack
- **Theme System**: Multi-theme Material Design 3 system with 5 variants (Purple Boho, Forest Sage, Ocean Blues, Sunset Warmth, Monochrome)

### Key Services
- **BookSearchService**: Google Books API integration with async/await
- **CSVImportService**: Goodreads CSV import with smart fallback strategies
- **ImageCache**: In-memory book cover caching
- **HapticFeedbackManager**: Tactile feedback for user interactions

### Navigation Pattern
- Uses NavigationStack with consolidated `navigationDestination` declarations at ContentView level
- Navigation uses value-based routing: `NavigationLink(value: book)` → `navigationDestination(for: UserBook.self)`
- Eliminates multiple navigationDestination warnings by centralizing routing

## Development Patterns

### Swift 6 Concurrency Architecture
- **Data Models**: Use `@unchecked Sendable` for SwiftData models (thread safety handled by SwiftData)
- **UI Classes**: `@MainActor` isolation for ObservableObject types (ThemeStore)
- **Service Layer**: Proper async/await patterns with structured concurrency
- **Error Handling**: Comprehensive error propagation with typed error enums
- **Background Tasks**: Safe Task.detached usage to avoid actor isolation issues

### Material Design 3 Theme System
- **Comprehensive MD3 Implementation**: Full Material Design 3 component system with proper elevation, typography, and interaction patterns
- **Button Styles**: `.materialButton(style: .filled/.tonal/.outlined/.text/.destructive/.success, size: .small/.medium/.large)`
- **Card System**: `.materialCard(elevation: CGFloat)` with proper shadows and theming
- **Interactive Feedback**: `.materialInteractive(pressedScale: CGFloat, pressedOpacity: Double)` for tactile responses
- **Spacing System**: 8pt grid (xs=4, sm=8, md=16, lg=24, xl=32, xxl=48, xxxl=64)
- **Typography Scale**: Complete Material Design 3 typography with `.displayLarge()`, `.headlineMedium()`, `.bodyLarge()`, etc.
- **Theme Variants**: 5 complete themes (Purple Boho, Forest Sage, Ocean Blues, Sunset Warmth, Monochrome)
- **Accessibility**: Full VoiceOver support, reduce motion compliance, and dynamic type scaling
- **Visual Consistency**: Unified corner radius, elevation, and animation systems across all components

### SwiftData Best Practices
- Navigation destination views use `modelContext.fetch()` instead of `@Query` to prevent update conflicts
- Models implement `Hashable` using unique identifiers for stable navigation
- Migration handling includes fallback strategies for schema changes

### Import System
- 5-step CSV import flow: Select → Preview → Map → Import → Complete
- Smart column detection for Goodreads format
- Fallback strategies: ISBN lookup → Title/Author search → CSV data preservation

### UI Components
- Fixed card dimensions (140x260) for uniform grid layout
- Golden star ratings with amber colors
- Cultural diversity badges with theme-appropriate colors
- Purple boho aesthetic as default theme

## File Organization

### Views Hierarchy
- `Views/Main/`: Primary app screens (ContentView, LibraryView, SearchView, StatsView)
- `Views/Detail/`: Detail screens (BookDetailsView, EditBookView, SearchResultDetailView)
- `Views/Components/`: Reusable UI components (BookCardView, BookCoverImage, filters)
- `Views/Import/`: CSV import flow screens

### Supporting Code
- `Models/`: SwiftData models and import data structures
- `Services/`: API integration, caching, import services
- `Theme/`: Comprehensive theming system with variants
- `Utilities/`: Helper functions, CSV parsing, duplicate detection
- `Extensions/`: Color extensions and utility extensions

## Testing Strategy

The app includes comprehensive test coverage:
- **Model Tests**: SwiftData model behavior and migration
- **Service Tests**: API integration, import services, caching
- **UI Tests**: Navigation flows, theme switching, import workflows
- **Integration Tests**: End-to-end user workflows

## Cultural Diversity Features

This app has a strong focus on tracking cultural diversity in reading:
- Author nationality and cultural background tracking
- Original language and translation information
- Regional categorization (Africa, Asia, Europe, Americas, etc.)
- Visual analytics for diversity patterns
- Cultural goal setting and progress tracking

## Known Implementation Details

- Uses SwiftData with custom ModelConfiguration for proper migration
- Implements value-based navigation to avoid SwiftUI navigation conflicts  
- Material Design 3 component system with comprehensive theming
- Smart import system with multiple fallback strategies for book data
- Consolidated navigation architecture to eliminate warnings
- Multi-theme system with instant switching and persistence
- **BUILD STATUS**: ✅ Successfully builds for iPhone 16 simulator (arm64-apple-ios18.0-simulator)
- **SWIFT 6 COMPLIANCE**: ✅ Full Swift 6 concurrency model with Sendable conformance
- **THREAD SAFETY**: All data models properly isolated with `@unchecked Sendable`
- **CONCURRENCY**: Modern async/await patterns throughout with proper actor isolation
- **THEME SYSTEM**: All SwiftUI previews fixed with proper AppColorTheme environment injection
- **MATERIAL DESIGN 3**: ✅ Comprehensive MD3 system restored with full button styles and interactions
- **CSV IMPORT**: ✅ ISBN cleaning logic fixed - removes leading `=` characters from Goodreads exports

## Background Processing (Phase 1 - Implemented)

### CSV Import Background Capabilities
- **BackgroundTaskManager**: Manages iOS background task lifecycle with 30+ seconds runtime
- **ImportStateManager**: Persists import state across app lifecycle, handles resume/recovery
- **Background-aware Import**: CSV import continues when app is backgrounded
- **State Persistence**: Complete import state saved to UserDefaults with automatic cleanup
- **Resume Dialogs**: Users prompted to resume interrupted imports on app launch
- **Info.plist**: Background processing and fetch capabilities enabled

### Live Activities Foundation (Phase 2 - Prepared)
- **LiveActivityManager**: Complete architecture for Dynamic Island integration
- Ready for Widget Extension and Live Activity implementation

## Recent Fixes (2024)

### Library Reset Issues
- **Fixed**: ThemeStore environment object properly passed using `@Environment(\.themeStore)`
- **Fixed**: Hold-to-confirm button progression with proper state advancement
- **Fixed**: SF Symbol `chart.line.downtrend` replaced with `chart.line.downtrend.xyaxis`

### Memory Management
- **Fixed**: PerformanceMonitor retain cycles with weak references in actors
- **Fixed**: Timer property made `nonisolated(unsafe)` for safe deallocation
- **Fixed**: All Task blocks use `[weak self]` capture lists

### Build Issues
- **Fixed**: Unnecessary `await` on synchronous `getRecommendedConcurrency()` call
- **Fixed**: Main actor isolation errors in deinit methods

# important-instruction-reminders
Do what has been asked; nothing more, nothing less.
NEVER create files unless they're absolutely necessary for achieving your goal.
ALWAYS prefer editing an existing file to creating a new one.
NEVER proactively create documentation files (*.md) or README files. Only create documentation files if explicitly requested by the User.