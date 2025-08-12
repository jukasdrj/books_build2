# Books Reading Tracker

A comprehensive SwiftUI application for tracking your personal book library with advanced CSV import capabilities and real-time Live Activities support.

## 🌟 Features

### Core Reading Tracking
- **Personal Library Management**: Track books with detailed metadata, ratings, and reading status
- **Reading Goals**: Set and monitor yearly reading targets with visual progress
- **Cultural Diversity Tracking**: Monitor diversity across gender, ethnicity, and language with standardized ISO codes
- **Comprehensive Search**: Find books by title, author, genre, or ISBN with real-time filtering
- **Visual Analytics**: Beautiful charts showing reading patterns and genre breakdowns

### Advanced CSV Import System
- **Background Processing**: Import large libraries without blocking the UI
- **Live Activities**: Real-time progress in Dynamic Island and Lock Screen (iOS 16.1+)
- **Smart Book Matching**: ISBN lookup with fallback to title/author search
- **Concurrent Processing**: 5x faster imports with parallel API calls
- **State Persistence**: Resume interrupted imports after app crashes or termination
- **Cultural Data Integration**: Streamlined diversity tracking with standardized selectors

### User Experience
- **Dynamic Theming**: Multiple themes with system integration
- **Accessibility**: Full VoiceOver support and accessibility compliance
- **Haptic Feedback**: Contextual feedback for user interactions
- **Responsive Design**: Optimized for all iPhone and iPad screen sizes

## 📱 System Requirements

- **iOS 16.0+** (iOS 16.1+ for Live Activities)
- **iPhone/iPad** with sufficient storage for your book library
- **Network Connection** for book metadata fetching during imports

### Live Activities Support
- **iPhone 14 Pro/Pro Max**: Full Dynamic Island experience
- **Other iOS 16.1+ devices**: Lock Screen Live Activities
- **Pre-iOS 16.1 devices**: Traditional progress indicators

## 🚀 Quick Start

### Basic Usage
1. **Add Books**: Tap "+" to add books manually or via barcode scanning
2. **Import Library**: Use CSV import for existing Goodreads libraries
3. **Track Progress**: Update reading status and ratings as you read
4. **Monitor Goals**: Set yearly reading goals and track progress

### CSV Import
1. **Prepare File**: Export your library from Goodreads or create a CSV with book data
2. **Select File**: Choose your CSV file in the Import tab
3. **Map Columns**: Map CSV columns to book fields (title, author, ISBN, etc.)
4. **Start Import**: Begin background processing with Live Activities
5. **Monitor Progress**: Watch real-time updates in Dynamic Island or Lock Screen
6. **Review Results**: Handle any ambiguous matches after completion

## 📊 Project Architecture

### Phase 1: Background Import System ✅
- **BackgroundImportCoordinator**: Orchestrates the entire import workflow
- **ImportStateManager**: Handles state persistence and recovery
- **BackgroundTaskManager**: Manages iOS background execution
- **CSVImportService**: Core import logic with concurrent processing
- **Smart Retry Logic**: Exponential backoff and circuit breaker patterns

### Phase 2: Live Activities ✅
- **BooksWidgets Extension**: Widget extension target for Live Activities
- **LiveActivityManager**: Manages Live Activity lifecycle and updates
- **Dynamic Island Integration**: Compact, expanded, and minimal layouts
- **Lock Screen Widgets**: Detailed progress with statistics
- **Real-time Updates**: Progress updates every 2 seconds during import

### Core Services
- **BookSearchService**: ISBN and metadata lookup with multiple providers
- **DataMigrationManager**: Handles schema changes and data migration
- **PerformanceMonitor**: Tracks import performance and optimization
- **HapticFeedbackManager**: Contextual haptic feedback

### UI Components
- **Unified Book Components**: Consistent book display across views
- **Cultural Selection Pickers**: Standardized diversity tracking interface
- **Import Progress Indicators**: Real-time progress visualization
- **Theme System**: Dynamic theming with multiple variants

## 🛠 Technical Implementation

### Concurrency & Performance
- **Swift 6 Compliant**: Full concurrency safety with actor isolation
- **Actor-Based Design**: Thread-safe state management throughout
- **Concurrent Processing**: Parallel ISBN lookups with configurable limits
- **Memory Optimization**: Efficient resource usage with automatic cleanup

### Data Management
- **SwiftData Integration**: Modern Core Data replacement with type safety
- **State Persistence**: Complete import state recovery capabilities
- **Migration Support**: Seamless schema evolution
- **Performance Monitoring**: Detailed metrics and optimization tracking

### Background Processing
- **iOS Background Tasks**: Proper background execution with BGTaskScheduler
- **State Recovery**: Full resume capability after app termination
- **Progress Tracking**: Real-time updates with 2-second intervals
- **Battery Optimization**: Efficient processing with minimal power impact

## 📁 Project Structure

```
books/
├── App/
│   └── booksApp.swift                          # Main app entry point
├── Models/
│   ├── UserBook.swift                          # Core book model
│   ├── BookMetadata.swift                      # Metadata structures
│   ├── ImportModels.swift                      # Import data models
│   └── CulturalSelections.swift                # Diversity tracking models
├── Services/
│   ├── BackgroundImportCoordinator.swift       # Import orchestration
│   ├── LiveActivityManager.swift               # Live Activities management
│   ├── CSVImportService.swift                  # Core import logic
│   ├── ImportStateManager.swift                # State persistence
│   ├── BackgroundTaskManager.swift             # iOS background tasks
│   ├── BookSearchService.swift                 # Book metadata lookup
│   └── [Additional Services]
├── Views/
│   ├── Main/
│   │   ├── ContentView.swift                   # Main navigation
│   │   ├── LibraryView.swift                   # Library display
│   │   └── [Additional Main Views]
│   ├── Import/
│   │   ├── CSVImportView.swift                 # Import interface
│   │   └── [Import Components]
│   └── Components/
│       ├── BackgroundImportProgressIndicator.swift
│       ├── ImportCompletionBanner.swift
│       ├── CulturalSelectionPickers.swift
│       └── [Shared Components]
└── [Additional Directories]

BooksWidgets/                                   # Live Activities Extension
├── BooksWidgetsBundle.swift                    # Widget bundle entry
├── CSVImportLiveActivity.swift                 # Live Activity implementation
├── ActivityAttributes.swift                   # Shared data models
├── EnhancedLiveActivityViews.swift             # Enhanced UI components
└── [Configuration Files]
```

## 📋 CSV Import Format

The application supports flexible CSV formats with column mapping. Common Goodreads export columns:

### Required Fields
- **Title**: Book title (required)
- **Author**: Primary author (required)

### Optional Fields
- **ISBN/ISBN13**: For metadata lookup
- **Rating**: Your rating (1-5 stars)
- **Date Read**: Completion date
- **Bookshelves**: Reading status/categories
- **Review**: Personal notes
- **Pages**: Page count
- **Publication Year**: Original publication date
- **Publisher**: Publishing house
- **Genres**: Book categories

### Cultural Diversity Fields (Optional)
- **Author Gender**: Author's gender identification
- **Author Ethnicity**: Author's ethnic background
- **Language**: Book's primary language (ISO 639-1 codes)

## 🎯 Reading Goals & Analytics

### Goal Setting
- Set yearly reading targets (number of books or pages)
- Track progress with visual indicators
- Historical goal performance

### Analytics Dashboard
- **Reading Patterns**: Monthly reading trends
- **Genre Distribution**: Visual breakdown of reading preferences
- **Cultural Diversity**: Track diversity across multiple dimensions
- **Progress Metrics**: Completion rates and reading velocity

## 🌍 Cultural Diversity Tracking

### Standardized Categories
- **Gender Identity**: Using standardized options with "Prefer not to say"
- **Ethnic Background**: Comprehensive ethnic categories
- **Languages**: ISO 639-1 language codes for consistent tracking

### Privacy & Sensitivity
- Optional tracking with clear privacy controls
- Respectful categorization following best practices
- User control over data visibility and sharing

## 🔧 Setup & Configuration

### Development Setup
1. **Clone Repository**: Get the latest code
2. **Open in Xcode**: Requires Xcode 15+ for Swift 6 support
3. **Configure Certificates**: Set up development team and signing
4. **Build Dependencies**: Automatic package resolution
5. **Run Tests**: Execute test suite to verify setup

### Widget Extension Setup (Manual)
Due to Xcode project complexity, the BooksWidgets extension requires manual setup:

1. **Add Widget Extension Target** in Xcode
2. **Configure App Groups** for data sharing
3. **Set Proper Entitlements** for Live Activities
4. **Copy Widget Files** from BooksWidgets directory
5. **Test on Physical Device** (Live Activities require hardware)

Detailed instructions available in `/BooksWidgets/WidgetExtensionSetup.md`

## 📱 Live Activities Experience

### Dynamic Island (iPhone 14 Pro/Pro Max)
- **Compact Leading**: Circular progress indicator
- **Compact Trailing**: Book count display
- **Expanded View**: Detailed progress with current book information
- **Minimal View**: Simple progress ring

### Lock Screen (All iOS 16.1+ Devices)
- **File Name Header** with progress percentage
- **Linear Progress Bar** with custom styling
- **Current Step Description** showing import phase
- **Statistics Badges** for success/duplicate/failure counts
- **Current Book Section** with title and author being processed

### Real-Time Updates
- Progress updates every 2 seconds during active import
- Current book title and author display
- Live statistics tracking (imported, duplicates, failures)
- Completion summary with final results

## 📖 User Guide

### Getting Started
1. **First Launch**: The app creates your personal library database
2. **Add Your First Book**: Try the manual add or barcode scanner
3. **Set Reading Goals**: Configure yearly targets in Settings
4. **Customize Themes**: Choose from multiple visual themes

### CSV Import Workflow
1. **Prepare Your Data**: Export from Goodreads or prepare custom CSV
2. **Access Import Tab**: Navigate to Import section
3. **Select CSV File**: Choose your file from Files app
4. **Preview Data**: Review first few rows
5. **Map Columns**: Match CSV columns to book fields
6. **Configure Options**: Set import preferences
7. **Start Background Import**: Begin processing with Live Activities
8. **Monitor Progress**: Watch Dynamic Island or Lock Screen updates
9. **Handle Reviews**: Address any ambiguous matches
10. **Celebrate**: Your library is imported!

### Tips for Best Results
- **Clean Data**: Remove duplicate entries before import
- **Include ISBNs**: Better metadata matching with ISBN-13 codes
- **Check Dates**: Ensure date formats are consistent
- **Review Mappings**: Double-check column mappings before import
- **Physical Device**: Use actual iPhone/iPad for Live Activities testing

## 🧪 Testing

### Test Coverage
- **Unit Tests**: Core services and business logic
- **Integration Tests**: Component interaction testing
- **UI Tests**: Critical user workflows
- **Performance Tests**: Import speed and memory usage
- **Accessibility Tests**: VoiceOver and accessibility compliance

### Live Activities Testing
- **Physical Device Required**: Live Activities don't work in simulator
- **iOS 16.1+ Testing**: Verify compatibility across devices
- **Background Scenarios**: Test app backgrounding during import
- **Error Handling**: Verify graceful failure modes
- **Permission Testing**: Test with Live Activities disabled

## 🚀 Future Roadmap

### Phase 3: Advanced Features (Planned)
- **Smart Retry System**: AI-powered import optimization
- **Cloud Sync**: Multi-device library synchronization
- **Enhanced Analytics**: Advanced reading insights
- **Social Features**: Reading challenges and sharing
- **Library Reset**: Complete library management tools

### Potential Enhancements
- **Reading Timer**: Track reading sessions
- **Book Recommendations**: AI-powered suggestions
- **Library Statistics**: Advanced analytics dashboard
- **Export Capabilities**: Multiple format support
- **Backup & Restore**: Complete data portability

## 🤝 Contributing

### Development Guidelines
- **Swift 6 Compliance**: All code must be concurrency-safe
- **Test Coverage**: Maintain >80% test coverage
- **Documentation**: Document all public APIs
- **Accessibility**: Ensure VoiceOver compatibility
- **Performance**: Profile and optimize critical paths

### Code Style
- SwiftUI best practices
- Actor-based concurrency patterns
- Comprehensive error handling
- Clean architecture principles

## 📄 License

This project is licensed under the terms specified in the LICENSE file.

## 🏆 Acknowledgments

- **Apple Developer Documentation**: iOS development best practices
- **SwiftUI Community**: UI patterns and components
- **ActivityKit Framework**: Live Activities implementation
- **ISBN APIs**: Book metadata providers
- **Open Source Community**: Various utility libraries

---

**Current Version**: 2.0 (Phase 2 Complete - Live Activities)  
**Last Updated**: August 2024  
**Minimum iOS**: 16.0 (16.1 for Live Activities)