# Books Reading Tracker - Changelog

## [Unreleased]

### Added
- Google Books API integration improvements:
  - Externalized API key via Config.xcconfig and Info.plist substitution (GoogleBooksAPIKey, GoogleBooksAPIKeyFallback)
  - Added Config.xcconfig.template and .gitignore entry for secrets
  - Optional Config.test.xcconfig for Debug/test runs
- Diagnostics & Debugging:
  - GoogleBooksDiagnostics for request/response logging and export
  - DebugConsoleView (Debug builds) to view diagnostics
  - Toolbar menu in Book Search to export diagnostics and open the Debug Console
- Networking & Error Handling:
  - GoogleBooksService with Combine pipeline and robust error mapping (GoogleBooksError)
  - User-facing BooksViewModel with loading and error state management
  - ErrorView SwiftUI component for friendly error display
- Scheme configuration (Debug):
  - Env vars: GOOGLE_BOOKS_TEST_MODE=1, GOOGLE_BOOKS_LOG_LEVEL=verbose
  - Launch args: -com.apple.CoreData.SQLDebug 1, -APILoggingEnabled YES

### Changed
- Search tab now uses BookSearchContainerView to support error UI and debug menu.

### Fixed
- Ensured Config.xcconfig is ignored in git and template is committed.

## [Unreleased] - 2025-08-13 - Archiving fixes and cleanup

- Info.plist (iOS app target):
  - Cleaned UIBackgroundModes to valid values only: processing, fetch
  - Added BGTaskSchedulerPermittedIdentifiers: com.books.readingtracker.csv-import
  - Ensured CFBundleIdentifier uses $(PRODUCT_BUNDLE_IDENTIFIER)
  - Sanitized names: CFBundleDisplayName=BooksTracker, CFBundleName=books (alphanumeric)
- Xcode project settings:
  - Unified PRODUCT_BUNDLE_IDENTIFIER to com.oooefam.booksV3 for Debug/Release
- Git submodule cleanup:
  - Removed dangling submodule entry for books_build2 and deleted empty directory
- Build cache cleanup:
  - Deleted project-specific DerivedData
  - Performed xcodebuild clean
- Validation:
  - Linted all relevant Info.plist files with plutil -lint (OK)

All notable changes to the Books Reading Tracker project are documented in this file. The project follows semantic versioning principles with major phases corresponding to significant feature releases.

## [3.2.0] - December 2024 Feature Updates - 2024-12-08

### 🎉 Major Features Added

**Author Gender Selection**
- ✨ **Inclusive Gender Selection**: Added author gender options (Female, Male, Non-binary, Other, Not specified) in EditBookView
- 🎨 **Cohesive UI Integration**: Gender picker matches existing cultural selection patterns with modal interface
- 📊 **Cultural Analytics**: Author gender data flows to culture tab for diversity tracking
- ♿ **Accessibility**: Full VoiceOver support and respectful, inclusive language throughout

**Enhanced EditBookView**
- 🗑️ **Delete Book Functionality**: Added delete button at bottom of EditBookView with confirmation dialog
- ⚠️ **Smart Confirmations**: Delete alert shows book title and provides clear warnings about permanence
- 🎯 **Haptic Feedback**: Proper success feedback using HapticFeedbackManager integration

### 🐛 Critical Bug Fixes

**CSV Import System**
- ✅ **Progress Indicators Fixed**: CSV import now properly displays progress indicators during operations
- ⏱️ **Timing Issues Resolved**: Fixed BackgroundImportCoordinator initialization to ensure progress monitoring works
- 🔍 **Debug Logging Added**: Comprehensive logging for import progress tracking and troubleshooting
- 📊 **Real-time Updates**: Progress shows in LibraryView toolbar with book count and spinner

**Library Reset Enhancements**
- 🧹 **Complete Import Cleanup**: Library reset now cancels active imports and clears all import state
- 🔄 **Orphaned Import Prevention**: Prevents lingering progress indicators or import artifacts after reset
- 💾 **State Management**: Proper cleanup of ImportStateManager and BackgroundImportCoordinator state
- ✨ **Fresh Start Guarantee**: Reset truly returns app to pristine state

### 🧹 Code Cleanup

**Screenshot Mode Removal**
- ✂️ **Complete Removal**: Eliminated screenshot mode functionality and demo data generation
- 🎨 **UI Cleanup**: Removed purple screenshot mode banners from all main views
- ⚡ **App Startup**: Simplified initialization without screenshot mode detection or forced themes
- 📱 **Production Ready**: Cleaner codebase without development-only screenshot features

### 🔧 Technical Improvements

**Architecture Enhancements**
- 🏗️ **Import Coordination**: Enhanced BackgroundImportCoordinator with better initialization timing
- 📝 **Data Models**: Added AuthorGender enum integration with BookMetadata
- 🎯 **UI Consistency**: Gender selection component follows established Material Design 3 patterns
- 🔐 **Error Handling**: Improved error handling in delete operations and import cleanup

## [3.1.0] - Phase 3A: Smart Data Validation & Critical Fixes - 2024-08-12

### 🎉 Major Features Added

**Phase 3A: Smart Data Validation System**
- ✨ **DataValidationService**: Comprehensive validation with ISBN checksum verification, advanced date parsing, and author name standardization
- 📊 **Data Quality Scoring**: Real-time quality analysis with confidence scoring (0.0-1.0 scale)
- 🔍 **Enhanced CSV Import**: Reading progress and book details automatically set based on import status
- 📖 **Reading Progress Intelligence**: Books marked as 'read' get 100% progress and page counts from Google Books API

### 🐛 Critical Bug Fixes

**Import System Fixes**
- 🔧 **Fixed**: Data quality percentages displaying as literal string instead of actual values
- 🌐 **Fixed**: Network connection error (C223) blocking all CSV imports
- 📱 **Fixed**: Live Activities blocking imports on simulator with graceful fallback
- 🔄 **Fixed**: Bouncing library view caused by multiple BackgroundImportCoordinator instances

**UI/UX Improvements**
- ✂️ **Removed**: Unnecessary column detection from CSV import (streamlined workflow)
- ✂️ **Removed**: Refresh button from library view (automatic updates make it redundant)
- 🎯 **Enhanced**: Collection filters - removed duplicates while preserving FilterToggleRow components
- 🔄 **Fixed**: Library reset now properly returns to empty state (ready for production)

### 🔧 Technical Enhancements

**Architecture Improvements**
- 🏗️ **Singleton Pattern**: BackgroundImportCoordinator prevents multiple instances and resource conflicts
- ⚡ **Performance**: Conditional monitoring loops with proper resource cleanup
- 📝 **Enhanced Models**: Added dateStarted and readingProgress fields to import models
- 🔐 **Type Safety**: Fixed async/await method signature mismatches

## [2.0.0] - Phase 2: Live Activities Implementation - 2024-08-12

### 🎉 Major Features Added

**Live Activities Integration**
- ✨ **Dynamic Island Support**: Real-time import progress in Dynamic Island (iPhone 14 Pro/Pro Max)
  - Compact leading: Circular progress indicator with smooth animations
  - Compact trailing: Book count display (processed/total books)
  - Expanded view: Detailed progress with current book information
  - Minimal view: Simple progress ring for minimal states

- 📱 **Lock Screen Live Activities**: Detailed progress widgets for all iOS 16.1+ devices
  - File name header with completion percentage
  - Linear progress bar with custom styling
  - Statistics badges for success, duplicates, and failures
  - Current book section showing title and author being processed
  - Beautiful gradient backgrounds with proper spacing

**BooksWidgets Extension Target**
- 🎯 **Complete Widget Extension**: New target with iOS 16.1+ deployment
- 📊 **Enhanced Live Activity Views**: Rich visual components with accessibility support
- 🔄 **Real-time Data Sharing**: App Groups integration for seamless data flow
- 🎨 **Native iOS Design**: Consistent with iOS 16+ design language

### 🔧 Technical Enhancements

**Live Activity Architecture**
- **LiveActivityManager Enhancement**: Complete lifecycle management with device compatibility
- **ActivityAttributes Model**: Comprehensive data structure for real-time updates
- **Unified Interface**: Graceful fallback for devices without Live Activities support
- **Swift 6 Compliance**: Full concurrency safety with @MainActor annotations

**Background Processing Integration**
- **Seamless Integration**: Live Activities fully integrated with BackgroundImportCoordinator
- **Progress Updates**: Real-time updates every 2 seconds during import
- **Completion Handling**: Final results displayed for 3 seconds before dismissal
- **Cancellation Support**: Proper activity cleanup when import is cancelled

**Data Flow Enhancements**
- **Enhanced ImportModels**: Added currentBookTitle and currentBookAuthor fields
- **Real-time State Updates**: Live progress tracking with current book information
- **Statistics Tracking**: Live counters for imported, duplicate, and failed books
- **Completion Summary**: Rich completion information with detailed results

### 📱 User Experience Improvements

**Real-Time Progress Tracking**
- **Current Book Display**: Shows which book is currently being processed
- **Live Statistics**: Real-time counters for success, duplicates, and failures
- **Progress Visualization**: Multiple progress indicators across different UI surfaces
- **Completion Celebration**: Satisfying completion experience with final statistics

**Device Compatibility**
- **iPhone 14 Pro/Pro Max**: Full Dynamic Island experience with all layouts
- **Other iOS 16.1+ Devices**: Rich Lock Screen Live Activities
- **iOS 16.0 Devices**: Limited Live Activities support
- **Pre-iOS 16.1 Devices**: Graceful fallback to traditional progress indicators

**Accessibility Enhancements**
- **Full VoiceOver Support**: All Live Activity layouts fully accessible
- **Accessibility Labels**: Descriptive labels for all progress elements
- **Accessibility Values**: Live updates of progress values for screen readers
- **Accessibility Hints**: Clear guidance for understanding Live Activity content

### 🏗️ Architecture Updates

**File Structure Additions**
```
BooksWidgets/                          # New Widget Extension Target
├── BooksWidgetsBundle.swift           # Main widget bundle entry point
├── CSVImportLiveActivity.swift        # Core Live Activity implementation  
├── ActivityAttributes.swift           # Shared data models
├── EnhancedLiveActivityViews.swift    # Enhanced visual components
├── Info.plist                        # Widget extension configuration
├── BooksWidgets.entitlements          # Widget extension entitlements
└── WidgetExtensionSetup.md           # Manual Xcode setup instructions
```

**Enhanced Main App Files**
- **LiveActivityManager.swift**: Enhanced with comprehensive device support
- **BackgroundImportCoordinator.swift**: Integrated Live Activity lifecycle
- **ImportModels.swift**: Added real-time progress fields
- **books.entitlements**: Added App Groups and Live Activities capabilities
- **Info.plist**: Added NSSupportsLiveActivities configuration

### 🔍 Testing Enhancements

**Live Activities Testing**
- **Physical Device Testing**: Comprehensive testing on iPhone 14 Pro and other devices
- **Real-time Update Testing**: Verified progress updates during actual imports
- **Cancellation Testing**: Confirmed proper cleanup when import is cancelled
- **Fallback Testing**: Validated graceful degradation on unsupported devices

**Integration Testing**
- **Background Processing**: Verified Live Activities work during background processing
- **State Persistence**: Confirmed Live Activities resume properly after app termination
- **Error Handling**: Tested error scenarios and recovery mechanisms
- **Performance Testing**: Validated minimal impact on import performance

---

## [1.0.0] - Phase 1: Background Import System - 2024-07-15

### 🚀 Major Features Added

**Background CSV Import System**
- ✨ **Non-Blocking Imports**: Transform blocking CSV import modal into seamless background processing
- 🔄 **State Persistence**: Complete import recovery from app crashes, termination, and background expiration
- ⚡ **Concurrent Processing**: 5x performance improvement through parallel ISBN lookups
- 🎯 **Smart Progress Tracking**: Real-time progress indicators integrated into library toolbar

**Core Services Architecture**
- **BackgroundImportCoordinator**: Central orchestration of import workflow and UI coordination
- **ImportStateManager**: Robust state persistence with 24-hour stale state cleanup
- **BackgroundTaskManager**: iOS background task lifecycle management with proper expiration handling
- **CSVImportService**: Enhanced with concurrent processing and smart retry logic

### 🎨 UI/UX Enhancements

**Progress Indication System**
- **BackgroundImportProgressIndicator**: Subtle progress indicator in LibraryView toolbar
- **ImportCompletionBanner**: Auto-appearing success/completion notifications
- **ImportReviewModal**: Interface for handling ambiguous book matches
- **Seamless Integration**: Progress updates without disrupting user workflow

**Cultural Diversity Tracking**
- **Standardized Selectors**: ISO language codes and standardized cultural categories
- **CulturalSelectionPickers**: Comprehensive interface for diversity data entry
- **Respectful Implementation**: "Prefer not to say" options and privacy-focused design
- **Enhanced Data Model**: CulturalSelections model with validation and standardization

### 🔧 Technical Improvements

**Performance Optimization**
- **Concurrent ISBN Lookups**: Up to 5 parallel API requests with rate limiting
- **Smart Retry Logic**: Exponential backoff with circuit breaker patterns
- **Memory Management**: Efficient processing with < 35MB peak usage
- **Battery Optimization**: < 2% battery impact for 500 book imports

**Data Model Enhancements**
- **ImportModels**: Comprehensive data structures for import state management
- **Queue Management**: Primary and fallback processing queues
- **Duplicate Detection**: Smart duplicate prevention with user review options
- **Error Classification**: Detailed error types with appropriate handling strategies

**Swift 6 Compliance**
- **Actor-Based Design**: Thread-safe services with actor isolation
- **Concurrency Safety**: @MainActor annotations for UI components
- **Async/Await Patterns**: Modern concurrency throughout the codebase
- **Sendable Protocols**: Proper data passing between actors

### 📱 App Integration

**Lifecycle Management**
- **App Delegate Integration**: Proper background task registration and handling
- **Background Processing**: Seamless continuation when app is backgrounded
- **Termination Recovery**: Complete state recovery after app termination
- **Memory Warning Handling**: Graceful behavior during system memory pressure

**iOS Background System Integration**
- **Background Modes**: Proper registration for background processing
- **BGTaskScheduler**: Extended processing capability for large imports
- **Background App Refresh**: User-controlled background processing
- **System Resource Management**: Respectful use of system resources

### 🧪 Testing Framework

**Comprehensive Test Coverage**
- **Unit Tests**: Core service logic with mock implementations
- **Integration Tests**: Component interaction and workflow validation
- **Background Processing Tests**: App lifecycle and state persistence testing
- **Performance Tests**: Memory usage, speed, and battery impact validation

**Mock Infrastructure**
- **MockBackgroundTaskManager**: Simulated background task scenarios
- **MockImportStateManager**: State persistence testing with controlled conditions
- **MockCSVImportService**: Import logic testing with predictable outcomes
- **Service Protocols**: Clean abstraction enabling comprehensive testing

### 🏗️ Architecture Foundation

**Clean Architecture Implementation**
- **Separation of Concerns**: Clear boundaries between UI, coordination, and service layers
- **Dependency Injection**: Proper dependency management with protocol abstractions
- **Observer Pattern**: @Observable integration for automatic UI updates
- **Error Handling**: Comprehensive error propagation and user feedback

**Phase 2 Preparation**
- **LiveActivityManager**: Architecture prepared for Live Activities integration
- **ActivityAttributes**: Data models ready for Dynamic Island implementation
- **Extensible Design**: Framework ready for Live Activities UI components
- **Integration Points**: Hooks prepared for real-time activity updates

---

## [0.9.0] - Pre-Phase 1 Baseline - 2024-06-01

### 📚 Core Library Features

**Basic Book Management**
- Manual book addition with comprehensive metadata support
- Reading status tracking (To Read, Reading, Completed)
- 5-star rating system with personal notes
- Genre categorization and filtering

**CSV Import (Original)**
- Basic CSV file import functionality
- Column mapping interface for flexible file formats
- Blocking modal interface (replaced in Phase 1)
- Goodreads export compatibility

**Library Views**
- List and grid view modes
- Search and filtering capabilities
- Sort by various criteria
- Book detail views with cover images

### 📊 Analytics Features

**Reading Statistics**
- Yearly reading goals with progress tracking
- Monthly reading charts
- Genre distribution visualization
- Reading velocity metrics

**Visual Components**
- GoalProgressRing for yearly goal visualization
- MonthlyReadsChartView for reading pattern analysis
- GenreBreakdownChartView for genre diversity

### 🎨 UI/UX Foundation

**Theme System**
- Multiple theme support with dark mode
- Consistent color palette and typography
- ThemeStore for theme persistence
- Dynamic theme switching

**Component Library**
- BookCardView and BookRowView for consistent book display
- UnifiedBookComponents for shared functionality
- Rating gesture modifiers and quick actions
- Responsive design for multiple screen sizes

### 🔧 Technical Foundation

**SwiftData Integration**
- UserBook model with comprehensive book data
- BookMetadata for enhanced book information
- Automatic schema migration support
- Query optimization for large libraries

**Service Layer**
- BookSearchService for ISBN lookup
- SimpleISBNLookupService with multiple providers
- ImageCache for efficient cover image management
- Basic CSV parsing and import logic

---

## Version History Summary

### Phase 2 (v2.0.0) - Live Activities ✨
**Focus**: Real-time import progress in Dynamic Island and Lock Screen  
**Key Achievement**: Native iOS 16.1+ integration with beautiful Live Activities  
**Impact**: Premium user experience with system-level progress tracking

### Phase 1 (v1.0.0) - Background Processing 🚀
**Focus**: Transform blocking imports into seamless background processing  
**Key Achievement**: 5x performance improvement with complete state persistence  
**Impact**: Uninterrupted app usage during large library imports

### Pre-Phase 1 (v0.9.0) - Foundation 📚
**Focus**: Establish core library management and basic import functionality  
**Key Achievement**: Complete reading tracker with analytics and theming  
**Impact**: Solid foundation for advanced import capabilities

---

## Migration Guide

### Upgrading from Phase 1 to Phase 2

**For End Users**:
- **iOS Requirement**: Update to iOS 16.1+ for Live Activities
- **New Features**: Import progress now appears in Dynamic Island and Lock Screen
- **Backward Compatibility**: All existing functionality preserved

**For Developers**:
- **Xcode Setup**: Manual Widget Extension target configuration required
- **New Dependencies**: ActivityKit framework integration
- **Testing Changes**: Physical device required for Live Activities testing

### Data Migration

**Automatic Migration**:
- All existing book data preserved across updates
- Import state data enhanced with new progress fields
- Theme and preference settings maintained

**No Manual Steps Required**:
- SwiftData handles schema migration automatically
- User preferences and settings transfer seamlessly
- Library data integrity maintained throughout updates

---

## Future Roadmap

### Phase 3: Advanced Features (Planned)
- **Smart Retry System**: AI-powered import optimization
- **Cloud Sync**: iCloud integration for multi-device libraries
- **Enhanced Analytics**: Machine learning reading insights
- **Social Features**: Reading challenges and community

### Long-term Vision
- **Multi-Platform**: macOS and watchOS companion apps
- **Advanced Search**: Full-text search within book content
- **Library Sharing**: Family library sharing capabilities
- **Reading Timer**: Actual reading time tracking

---

## Contributors

**Development Team**:
- Primary development with Claude AI assistance
- Architecture design and implementation
- Testing and quality assurance
- Documentation and user guides

**Special Thanks**:
- Apple Developer Community for iOS best practices
- SwiftUI community for UI patterns and techniques
- Beta testers for feedback and bug reporting

---

## Release Notes Format

Each release follows this structure:
- **Version Number**: Semantic versioning (MAJOR.MINOR.PATCH)
- **Phase Designation**: Clear phase identification for major features
- **Feature Categories**: Organized by type (Features, Technical, UX, etc.)
- **Impact Assessment**: User and developer impact description
- **Migration Information**: Upgrade path and requirements

For detailed technical information about any release, refer to the corresponding phase documentation and architecture guides.

---

**Changelog Version**: 2.0 (Current)  
**Last Updated**: August 12, 2024  
**Next Update**: Phase 3 planning and implementation