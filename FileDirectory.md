# File Directory

## Root Structure

The Books Reading Tracker project is organized into several main directories with comprehensive documentation and modular architecture supporting cultural diversity tracking and reading analytics.

---

## 📚 Documentation Files (Root Level)

### **Documentation.md**
- **Purpose**: Comprehensive project documentation including features, architecture, UX pathways, and design philosophy
- **Contains**: Core features overview, technical stack, data models, integration points, and future expansion plans
- **Usage**: Primary reference for developers and stakeholders

### **FileDirectory.md**
- **Purpose**: This file - complete directory structure documentation
- **Contains**: Detailed description of each file's responsibility and architectural relationships
- **Usage**: Navigate codebase efficiently and understand file organization

### **Roadmap.md**
- **Purpose**: Development planning and feature prioritization
- **Contains**: Completed features, in-progress work, short/medium/long-term goals, success metrics
- **Usage**: Guide development priorities and track project milestones

### **Accomplished.md**
- **Purpose**: Session-by-session development log and accomplishments tracking
- **Contains**: Detailed change logs, reasons for modifications, testing results, and context for future sessions
- **Usage**: Maintain development context and track progress over time

### **TODO.md**
- **Purpose**: Current development priorities and task tracking
- **Contains**: Active tasks, completed items, and immediate development focus areas
- **Usage**: Guide current development session priorities and track completion status

### **alex.md**
- **Purpose**: AI assistant memory and project-specific notes
- **Contains**: Learning notes, user preferences, and development patterns
- **Usage**: Maintain AI assistant context across sessions

---

## 🏗️ Main Application Code (/books/)

### **Application Entry Point**

#### **booksApp.swift**
- **Purpose**: SwiftUI App entry point with SwiftData ModelContainer configuration
- **Responsibility**: Initialize data persistence layer with migration handling and error recovery
- **Key Features**: Automatic fallback to in-memory storage if persistence fails
- **Dependencies**: SwiftData ModelContainer, UserBook and BookMetadata models

#### **ContentView.swift**
- **Purpose**: Main app navigation and tab bar structure
- **Responsibility**: Coordinate between 4 main app sections (Library, Wishlist, Search, Stats)
- **Recent Changes**: Removed Cultural Diversity tab, consolidated functionality into Stats view
- **Key Features**: Tab-based navigation with theme integration and accessibility support
- **Architecture**: NavigationStack wrappers for each tab with proper state management

---

### **📖 Data Models (/books/Models/)**

#### **BookMetadata.swift**
- **Purpose**: Core book information and cultural diversity tracking
- **Responsibility**: Store comprehensive book details from Google Books API plus enhanced cultural metadata
- **Key Features**: 
  - SwiftData @Model with unique Google Books ID
  - Cultural tracking (author gender, ethnicity, cultural region, indigenous voices)
  - Enhanced reading experience data (difficulty, content warnings, awards)
  - Array storage via comma-separated strings for SwiftData compatibility
  - Comprehensive validation methods
- **Relationships**: One-to-many with UserBook (one book can have multiple user instances)
- **Enums**: BookFormat, AuthorGender, CulturalRegion, ReadingDifficulty

#### **UserBook.swift**
- **Purpose**: User-specific reading tracking and personal book management
- **Responsibility**: Store reading status, progress, ratings, notes, and personal metadata
- **Key Features**:
  - Automatic date tracking for reading status changes
  - Enhanced progress tracking with current page and percentage calculation
  - Reading session logging with pace analytics
  - Cultural goal contribution tracking
  - Social features support (recommendations, discussions)
  - Comprehensive validation with non-fatal error handling
- **Relationships**: Many-to-one with BookMetadata (multiple users can track same book)
- **Nested Types**: ReadingSession struct, ReadingStatus enum

---

### **🎨 Theme and Design System**

#### **Theme.swift**
- **Purpose**: Material Design 3 implementation with comprehensive theming
- **Responsibility**: Define app-wide design tokens, colors, typography, spacing, and animations
- **Key Features**: Dark/light mode support, cultural color schemes, accessibility compliance
- **Usage**: Used throughout app via Theme.Color, Theme.Typography, Theme.Spacing, Theme.Animation

#### **Color+Extensions.swift**
- **Purpose**: Programmatic adaptive color system with dark/light mode support
- **Responsibility**: Provide computed color properties that adapt to system color scheme
- **Key Features**: Cultural region colors, interactive state colors, proper contrast ratios
- **Recent Refactor**: Removed Asset Catalog dependencies, implemented programmatic adaptive colors
- **Architecture**: Extension of SwiftUI Color with Color.theme.* accessor pattern

#### **SharedModifiers.swift**
- **Purpose**: Reusable SwiftUI view modifiers for consistent styling
- **Responsibility**: Provide common styling patterns used across multiple views
- **Key Features**: Enhanced loading states, error views, progress indicators, card styles
- **Recent Additions**: EnhancedLoadingView, EnhancedErrorView, ShimmerModifier

---

### **🔍 Views - Core Functionality**

#### **LibraryView.swift**
- **Purpose**: Main library display with user's book collection
- **Responsibility**: Show owned books with filtering, sorting, and management capabilities
- **Key Features**: Grid/list toggle, status filtering, search functionality, book management
- **Recent Enhancements**: Pull-to-refresh functionality, enhanced haptic feedback, loading states
- **Components Used**: BookCardView, BookRowView, FilterControls

#### **WishlistView.swift**
- **Purpose**: Wishlist management for future reading
- **Responsibility**: Display and manage books marked for future reading
- **Key Features**: Priority sorting, cultural goal tracking, quick add-to-library
- **Related Components**: `WishlistComponents.swift` (Contains supporting UI elements for the wishlist view to keep the main view file clean)

#### **SearchView.swift**
- **Purpose**: Google Books API integration and book discovery
- **Responsibility**: Search external book database and add books to personal library
- **Key Features**: 
  - Comprehensive search interface with Material Design 3 styling
  - Enhanced loading states with professional animations
  - Real-time search with responsive UI and proper loading states
  - Enhanced SearchResultRow component with shimmer effects
  - User-friendly error handling with retry functionality
  - Full dark mode support with adaptive colors
  - Accessibility compliance with VoiceOver support
  - Integration with BookSearchService for API calls
- **Recent Enhancements**: EnhancedLoadingView, shimmer effects, haptic feedback integration
- **API Integration**: Google Books API with proper error handling and retry logic
- **Components**: SearchResultRow with loading states and enhanced animations
- **Navigation**: Integrates with SearchResultDetailView for book details

#### **SearchResultDetailView.swift**
- **Purpose**: Detailed view for books from search results with action capabilities
- **Responsibility**: Display book details and provide add-to-library/wishlist functionality
- **Key Features**: 
  - Enhanced action buttons with loading states
  - Success toast notifications with elegant animations
  - Comprehensive haptic feedback (light, medium, success, error)
  - Auto-dismiss functionality with smooth navigation
  - Status indicators for existing books
  - Duplicate detection integration
- **Recent Enhancements**: SuccessToast component, loading button states, haptic integration
- **Components**: SuccessToast, enhanced action buttons, status indicators

#### **StatsView.swift**
- **Purpose**: Reading analytics and progress visualization with integrated cultural diversity
- **Responsibility**: Display reading statistics, goal tracking, progress charts, and cultural diversity metrics
- **Key Features**: 
  - Monthly progress, genre breakdown, reading pace analytics
  - Integrated Cultural Diversity Section showing cultural analytics
  - Cultural progress overview with region exploration tracking
  - Language diversity statistics and author diversity metrics
  - Diverse voices tracking (Indigenous, Marginalized, Translated works)
- **Recent Integration**: Cultural diversity analytics moved from standalone tab
- **Chart Dependencies**: Uses chart views from Charts/ subfolder

---

### **📱 Component Views**

#### **BookCardView.swift**
- **Purpose**: Card-style book display component for grid layouts
- **Responsibility**: Compact book representation with cover, title, author, and status
- **Key Features**: Material Design 3 elevation, accessibility labels, cultural badges, rating display
- **Usage**: Used in LibraryView grid mode, search results, recommendations

#### **BookRowView.swift**
- **Purpose**: Row-style book display component for list layouts
- **Responsibility**: Horizontal book layout with detailed information
- **Key Features**: Status badges, progress indicators, quick actions, accessibility support
- **Usage**: Used in LibraryView list mode, WishlistView, search results

#### **BookDetailsView.swift**
- **Purpose**: Detailed book information and management screen
- **Responsibility**: Full book display with editing capabilities and comprehensive metadata
- **Key Features**: Full description, cultural information, reading progress, note taking

#### **EditBookView.swift**
- **Purpose**: Book information editing interface
- **Responsibility**: Allow users to modify book metadata and personal information
- **Key Features**: Form validation, cultural metadata editing, image selection

#### **BookCoverImage.swift**
- **Purpose**: Intelligent book cover image loading and caching
- **Responsibility**: Load, cache, and display book cover images with proper error handling
- **Key Features**: Automatic retry, shimmer loading states, placeholder handling, memory management
- **Dependencies**: ImageCache.swift for caching logic

---

### **🔧 Supporting Components**

#### **shared_components.swift**
- **Purpose**: Collection of reusable UI components used across multiple views
- **Responsibility**: Provide consistent interface elements (buttons, badges, form fields)
- **Key Components**: StatusBadge, RatingView, FormField, BookListItem, AddBookView
- **Usage**: Imported and used throughout the app for UI consistency

#### **WishlistComponents.swift**
- **Purpose**: Contains supporting UI elements for the `WishlistView`
- **Responsibility**: Holds smaller, reusable views and components specific to the wishlist feature. This separation improves organization and keeps the main `WishlistView.swift` file focused on layout and primary logic.
- **Usage**: Components are imported and used within `WishlistView.swift`

#### **SupportingViews.swift**
- **Purpose**: Additional supporting views and utility components
- **Responsibility**: Provide specialized views that support main functionality
- **Usage**: Helper views, modal presentations, confirmation dialogs

---

### **🔍 Specialized Features**

#### **barcode_scanner.swift**
- **Purpose**: ISBN barcode scanning functionality
- **Responsibility**: Camera integration for scanning book barcodes to quickly add books
- **Key Features**: AVFoundation camera integration, ISBN detection, automatic book lookup
- **Permissions**: Requires camera access permissions

#### **duplicate_detection.swift**
- **Purpose**: Prevent duplicate books in user's library
- **Responsibility**: Detect potential duplicates when adding new books
- **Key Features**: Fuzzy matching on title/author, ISBN comparison, user confirmation dialogs
- **Integration**: Used in SearchResultDetailView for duplicate checking

#### **PageInputView.swift**
- **Purpose**: Reading progress input interface
- **Responsibility**: Allow users to update current page and reading progress
- **Key Features**: Page validation, progress calculation, session tracking

---

### **🌐 API and Data Services**

#### **BookSearchService.swift**
- **Purpose**: Google Books API integration service
- **Responsibility**: Handle external API calls for book search and metadata retrieval
- **Key Features**: Error handling, rate limiting, response parsing, metadata enhancement
- **Architecture**: Service layer pattern with async/await support

#### **ImageCache.swift**
- **Purpose**: Image caching and memory management
- **Responsibility**: Efficiently cache book cover images with automatic cleanup
- **Key Features**: NSCache-based storage, memory pressure handling, automatic retry logic
- **Performance**: Optimized for large collections with memory efficiency

#### **DataMigrationManager.swift**
- **Purpose**: Handle SwiftData schema migrations and data updates
- **Responsibility**: Safely migrate user data between app versions
- **Key Features**: Non-destructive migrations, validation, error recovery

---

### **📊 Analytics and Charts (/books/Charts/)**

#### **GenreBreakdownChartView.swift**
- **Purpose**: Visual representation of reading genres
- **Responsibility**: Create pie charts and bar charts showing genre distribution
- **Key Features**: Interactive charts, color-coded genres, percentage calculations
- **Dependencies**: Swift Charts framework

#### **MonthlyReadsChartView.swift**
- **Purpose**: Monthly reading progress visualization
- **Responsibility**: Show reading trends over time with goal tracking
- **Key Features**: Line charts, goal indicators, trend analysis
- **Usage**: Used in StatsView for progress tracking

---

### **📄 Documentation and Specifications (/books/Markdown/)**

#### **data_model_specification.txt**
- **Purpose**: Technical specification for data models and relationships
- **Contents**: Detailed field definitions, validation rules, relationship mappings
- **Usage**: Reference for developers working with data layer

#### **use-swiftdata.txt**
- **Purpose**: SwiftData implementation guidelines and best practices
- **Contents**: Usage patterns, relationship handling, migration strategies
- **Usage**: Guide for SwiftData-specific implementation details

---

### **⚙️ Configuration Files**

#### **Info.plist**
- **Purpose**: App configuration and permissions
- **Contents**: Bundle information, required device capabilities, permission descriptions
- **Key Settings**: Camera usage permissions, URL schemes, app display name

#### **books.entitlements**
- **Purpose**: App capabilities and entitlements
- **Contents**: CloudKit container configuration, app groups, background modes
- **Usage**: Required for iCloud sync and background processing

---

## 🧪 Testing Infrastructure

### **Unit Tests (/booksTests/)**

#### **booksTests.swift**
- **Purpose**: Basic app functionality tests
- **Coverage**: Core functionality validation, smoke tests

#### **BookSearchServiceTests.swift**
- **Purpose**: API integration testing
- **Coverage**: Google Books API calls, error handling, response parsing

#### **ModelContainerTests.swift**
- **Purpose**: SwiftData model and persistence testing
-- **Coverage**: Model creation, relationships, validation, migration

#### **ViewTests.swift**
- **Purpose**: SwiftUI view testing
- **Coverage**: View rendering, user interactions, accessibility
- **Recent Additions**: Enhanced loading states testing, cultural diversity view testing

#### **IntegrationTests.swift**
- **Purpose**: End-to-end feature testing
- **Coverage**: Complete user workflows, data flow validation

#### **AppLaunchTests.swift**
- **Purpose**: App startup and initialization testing
- **Coverage**: Launch performance, initial state validation

### **UI Tests (/booksUITests/)**

#### **booksUITests.swift**
- **Purpose**: Automated UI testing
- **Coverage**: User interface interactions, navigation flows
- **Recent Additions**: Dark mode testing, pull-to-refresh testing, toast notification testing

#### **booksUITestsLaunchTests.swift**
- **Purpose**: Launch and startup UI testing
- **Coverage**: App launch performance, initial screen validation

---

## 🔧 Build and Project Configuration

### **books.xcodeproj/**
- **Purpose**: Xcode project configuration
- **Contents**: Build settings, target configurations, dependencies
- **Key Files**: 
  - `books.xcscheme` - Build and run schemes
  - Project settings and configurations

---

## 📁 File Organization Principles

### **Naming Conventions**
- **Views**: Descriptive names ending with "View" (e.g., LibraryView.swift)
- **Models**: Noun-based names describing data entities (e.g., BookMetadata.swift)
- **Services**: Action-based names ending with "Service" (e.g., BookSearchService.swift)
- **Components**: Descriptive component names (e.g., BookCardView.swift)

### **Directory Structure Logic**
- **Flat structure** in main /books/ directory for core views and components
- **Specialized subdirectories** for related functionality (Models/, Charts/, Markdown/)
- **Test separation** with dedicated test directories
- **Documentation** at root level for easy access

### **Dependency Management**
- **Internal dependencies**: Views depend on models, services, and theme system
- **External dependencies**: Minimal external dependencies (SwiftUI, SwiftData, Charts)
- **Service layer**: Clean separation between UI and data/API layers

### **Code Organization Best Practices**
- **Single responsibility**: Each file has a clear, focused purpose
- **Modular design**: Reusable components and services
- **Theme consistency**: Centralized theme system used throughout
- **Accessibility first**: Comprehensive accessibility support in all views
- **Error handling**: Consistent error handling patterns across the app
- **Loading states**: Professional loading animations and user feedback throughout

---

## 🚀 Development Guidelines

### **Adding New Files**
1. **Follow naming conventions** outlined above
2. **Place in appropriate directory** based on functionality
3. **Update this FileDirectory.md** with new file descriptions
4. **Include proper imports** and follow established patterns
5. **Add accessibility support** from the start
6. **Include documentation** and inline comments

### **Modifying Existing Files**
1. **Understand current responsibility** from this directory
2. **Maintain single responsibility principle**
3. **Update related tests** when changing functionality
4. **Consider impact** on dependent files
5. **Update documentation** if behavior changes

### **Performance Considerations**
- **Image loading**: Use BookCoverImage.swift and ImageCache.swift for optimal performance
- **Data queries**: Leverage SwiftData's optimized queries in model files
- **View updates**: Use proper state management to minimize unnecessary re-renders
- **Memory management**: Follow patterns established in existing files
- **Loading states**: Implement proper loading feedback for user experience

### **Recent Architecture Improvements**
- **Navigation Simplification**: Reduced from 5 tabs to 4 tabs for cleaner user experience
- **Enhanced Loading States**: Professional animations and feedback throughout the app
- **Integrated Analytics**: Cultural diversity features consolidated into Stats view
- **Comprehensive Feedback**: Visual, haptic, and navigational feedback for all user actions
- **Modern iOS Patterns**: Pull-to-refresh, toast notifications, and proper loading states

This file directory serves as the primary navigation guide for the Books Reading Tracker codebase, ensuring developers can quickly understand the project structure and locate relevant code while understanding the recent architectural improvements and enhancements.