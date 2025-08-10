# Technical Architecture & Stack

## Core Technologies
- **SwiftUI**: Primary UI framework with declarative programming
- **SwiftData**: Core Data successor for persistence (@Model decorators)
- **NavigationStack**: Modern navigation with value-based routing
- **Async/Await**: Modern concurrency for API calls and data operations

## Data Models
### UserBook (Primary Model)
- User's personal book data with reading status, progress, ratings
- Cultural metadata and reading sessions tracking
- Implements Hashable for stable navigation
- Uses `modelContext.fetch()` instead of `@Query` in navigation destinations

### BookMetadata (Secondary Model)
- Book information from Google Books API
- Cultural diversity fields (author nationality, original language, region)
- Cached book cover URLs and publication details

## Architecture Patterns
### Navigation Pattern
- Consolidated NavigationStack with centralized routing at ContentView level
- Value-based navigation: `NavigationLink(value: book)` → `navigationDestination(for: UserBook.self)`
- Eliminates multiple navigationDestination warnings

### Material Design 3 System
- Custom modifiers: `.materialCard()`, `.materialButton()`, `.materialInteractive()`
- Theme.Spacing constants following 8pt grid system
- Multi-theme support with instant switching

### Services Architecture
- **BookSearchService**: Google Books API integration
- **CSVImportService**: Goodreads import with smart fallback strategies
- **ImageCache**: In-memory book cover caching
- **HapticFeedbackManager**: Tactile feedback system

## Project Structure
```
books/
├── App/                    # App entry point
├── Models/                 # SwiftData models
├── Views/                  # UI components
│   ├── Main/              # Primary screens
│   ├── Detail/            # Detail screens
│   ├── Components/        # Reusable components
│   └── Import/           # CSV import flow
├── Services/              # API & data services  
├── Theme/                 # Theming system
├── Utilities/            # Helper functions
└── Extensions/           # Swift extensions
```