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

### Theme System Usage
- All UI uses Material Design 3 modifiers: `.materialCard()`, `.materialButton()`, `.materialInteractive()`
- Spacing follows `Theme.Spacing` constants (8pt grid system)
- Theme switching triggers automatic view refresh via `@StateObject ThemeManager`

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
- **THEME SYSTEM**: All SwiftUI previews fixed with proper AppColorTheme environment injection
- **MATERIAL DESIGN**: All materialCard modifiers corrected with proper parameter usage
