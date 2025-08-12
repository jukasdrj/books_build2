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
- **CSVImportService**: Goodreads CSV import with smart fallback strategies and Phase 3A data validation
- **BackgroundImportCoordinator**: Singleton coordinator for managing background imports without UI bouncing
- **DataValidationService**: ISBN checksum verification, date parsing, and data quality scoring
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

## Background Processing Implementation

### Phase 1: Background CSV Import System (✅ COMPLETED)

#### Core Components Implemented

**1. BackgroundTaskManager** (`/Services/BackgroundTaskManager.swift`)
- iOS background task lifecycle management with BGTaskScheduler integration
- Automatic background task request when app enters background during import
- 30+ seconds background execution time with intelligent time monitoring
- Background task expiration handling with state preservation
- Notification system for coordinating with other services
- Full integration with app delegate lifecycle methods

**2. ImportStateManager** (`/Services/ImportStateManager.swift`)
- Persistent state storage using UserDefaults with JSON encoding
- Complete import session preservation including:
  - Import progress and statistics
  - Column mappings configuration
  - Queue states (primary/fallback queues)
  - Processed book IDs to prevent duplicates
  - Current queue phase tracking
- Automatic stale state detection (24-hour expiration)
- Resume capability detection with detailed import info
- App termination and background expiration handlers
- Thread-safe state updates with @MainActor isolation

**3. BackgroundImportCoordinator** (`/Services/BackgroundImportCoordinator.swift`)
- Coordinates background imports with library integration
- @Observable architecture for seamless UI updates
- Automatic detection of existing imports on app launch
- Review queue management for ambiguous matches
- Progress monitoring with 2-second update intervals
- Integration with CSVImportService for actual import processing

**4. LiveActivityManager** (`/Services/LiveActivityManager.swift`)
- Complete architecture prepared for Phase 2 Live Activities
- ActivityKit integration with CSVImportActivityAttributes
- Support for iOS 16.1+ with fallback for older versions
- UnifiedLiveActivityManager for cross-version compatibility
- Ready for Widget Extension integration

#### UI Components Implemented

**1. BackgroundImportProgressIndicator** (`/Views/Components/BackgroundImportProgressIndicator.swift`)
- Minimal, non-intrusive progress indicator
- Tap-to-expand detail view with comprehensive statistics
- Real-time progress updates with animated transitions
- Integration with BackgroundImportCoordinator

**2. ImportCompletionBanner** (`/Views/Components/ImportCompletionBanner.swift`)
- Auto-appearing completion notification
- Review modal for books needing attention
- 10-second auto-dismiss with manual dismiss option
- Material Design 3 styled cards and animations

#### Integration Points

**1. App Delegate Integration** (`/App/booksApp.swift`)
```swift
- applicationDidEnterBackground: Triggers background task
- applicationDidBecomeActive: Ends background task
- applicationWillTerminate: Saves critical state
- didFinishLaunching: Registers background tasks
```

**2. Info.plist Configuration**
```xml
<key>UIBackgroundModes</key>
<array>
    <string>background-processing</string>
    <string>background-fetch</string>
</array>
```

**3. CSV Import Flow Enhancement** (`/Views/Import/CSVImportView.swift`)
- Automatic background import initiation
- Resume dialog for interrupted imports
- Direct-to-library navigation after import start
- Integration with BackgroundImportCoordinator

#### Test Coverage

**BackgroundProcessingResumeTests** (`/booksTests/BackgroundProcessingResumeTests.swift`)
- 14 comprehensive test cases covering:
  - App backgrounding scenarios
  - Background time limit handling
  - Performance optimizations
  - Import resume functionality
  - State persistence across app lifecycle
  - Memory warning handling
  - ImportStateManager integration
  - User data preservation during resume

### Phase 2: Live Activities & Dynamic Island (🔄 READY TO IMPLEMENT)

#### Pre-Implementation Checklist

**✅ Completed Prerequisites:**
- LiveActivityManager architecture in place
- ActivityAttributes structure defined
- Content state model implemented
- Unified manager for version compatibility
- Background task integration ready

**📋 Required for Phase 2:**

1. **Xcode Project Configuration**
   - [ ] Add Push Notifications capability
   - [ ] Add NSSupportsLiveActivities = YES to Info.plist
   - [ ] Create Widget Extension target
   - [ ] Configure app group for data sharing

2. **Widget Extension Implementation**
   - [ ] Create ActivityConfiguration for CSV import
   - [ ] Design compact Live Activity view
   - [ ] Design expanded Live Activity view
   - [ ] Implement Dynamic Island layouts (compact, minimal, expanded)
   - [ ] Handle different presentation sizes

3. **Integration Tasks**
   - [ ] Connect LiveActivityManager to CSVImportService
   - [ ] Update ImportProgress to trigger Live Activity updates
   - [ ] Implement activity lifecycle management
   - [ ] Add user permission requests and handling
   - [ ] Create settings for Live Activity preferences

4. **UI/UX Enhancements**
   - [ ] Design Live Activity visual style matching app theme
   - [ ] Create progress visualization for Dynamic Island
   - [ ] Add tap interactions for Live Activity
   - [ ] Implement completion animations

5. **Testing Requirements**
   - [ ] Physical device testing (Live Activities don't work in simulator)
   - [ ] Background state transition testing
   - [ ] Activity update frequency optimization
   - [ ] Different file size scenarios
   - [ ] Permission denial handling

#### Architecture Readiness Assessment

**✅ Strong Foundation:**
- Actor-based concurrency model ready for Live Activity updates
- Progress tracking infrastructure supports real-time updates
- State persistence ensures continuity across app states
- Notification system ready for Live Activity triggers

**✅ Code Quality:**
- Swift 6 compliant with proper Sendable conformance
- Thread-safe architecture with @MainActor isolation
- Comprehensive error handling and recovery
- Well-tested background processing logic

**✅ Performance Optimized:**
- Efficient state updates minimize battery impact
- Throttled progress updates prevent excessive refreshes
- Background task coordination prevents resource conflicts
- Memory-efficient state persistence

## Implementation Timeline

### Phase 1: Background Import System (✅ Completed - 2024)
- Background task management with iOS BGTaskScheduler
- State persistence and resume capabilities
- UI components for progress indication
- Comprehensive test coverage
- Full integration with existing CSV import flow

### Phase 2: Live Activities (🔄 Ready to Implement)
- LiveActivityManager architecture prepared
- Widget Extension pending creation
- Dynamic Island layouts to be designed
- Physical device testing required

### Phase 3A: Smart Data Validation (✅ Completed - 2024)
- Comprehensive DataValidationService with ISBN checksum verification
- Advanced date parsing and author name standardization
- Data quality scoring and issue tracking
- Enhanced CSV parsing with validation integration
- Real-time quality analysis in import preview
- Reading progress and book details automatically set based on CSV status

### Phase 3B: Enhanced Smart Features (📋 Future)
- Machine learning for book matching
- Predictive duplicate detection using patterns
- Import analytics dashboard with success/failure tracking
- Smart import suggestions based on user reading patterns
- Cloud sync capabilities

## Recent Fixes (2024)

### Phase 3A Implementation & Critical Bug Fixes
- **Fixed**: Data quality percentages showing as literal "(Int(score * 100))%" instead of actual values
- **Fixed**: Network connection error "nw_connection_copy_connected_local_endpoint_block_invoke [C223]" blocking all imports
- **Fixed**: Live Activities blocking imports on simulator with graceful fallback
- **Fixed**: Session ID access errors in BackgroundImportCoordinator
- **Fixed**: Swift 6 concurrency issues in BackgroundTaskManager and RateLimiter
- **Fixed**: Bouncing library view caused by multiple BackgroundImportCoordinator instances
- **Enhanced**: Reading progress and book details now automatically set based on CSV import status

### UI/UX Improvements
- **Removed**: Unnecessary column detection from CSV import screen (simplified workflow)
- **Removed**: Refresh button from library view (automatic updates make it redundant)
- **Removed**: Duplicate collection filters while preserving well-designed FilterToggleRow components
- **Fixed**: Library reset now properly returns to empty state (commented out sample data auto-population)
- **Fixed**: String interpolation bugs in DataQualityIndicator percentage display

### Architecture Enhancements
- **Implemented**: Singleton BackgroundImportCoordinator pattern to prevent multiple instances
- **Added**: Conditional monitoring loops with proper exit conditions
- **Enhanced**: CSV import with reading progress calculation from API page counts
- **Added**: Support for dateStarted and readingProgress fields in import models
- **Fixed**: Async/await method signature mismatches in coordinator calls

### Memory Management & Performance
- **Fixed**: PerformanceMonitor retain cycles with weak references in actors
- **Fixed**: Timer property made `nonisolated(unsafe)` for safe deallocation
- **Fixed**: All Task blocks use `[weak self]` capture lists
- **Fixed**: Monitoring loop resource cleanup and single-instance guards

### Build Issues
- **Fixed**: Unnecessary `await` on synchronous `getRecommendedConcurrency()` call
- **Fixed**: Main actor isolation errors in deinit methods
- **Fixed**: Switch statement exhaustiveness for new BookField cases

# important-instruction-reminders
Do what has been asked; nothing more, nothing less.
NEVER create files unless they're absolutely necessary for achieving your goal.
ALWAYS prefer editing an existing file to creating a new one.
NEVER proactively create documentation files (*.md) or README files. Only create documentation files if explicitly requested by the User.