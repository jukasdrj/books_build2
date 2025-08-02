# File Directory

## Root Structure

The Books Reading Tracker project is organized into several main directories with comprehensive documentation and modular architecture supporting cultural diversity tracking and reading analytics.

---

## 📚 Documentation Files (Root Level)

### **ProjectSummary.md**
- **Purpose**: A consolidated summary of the project. It contains the project's core concept, architecture, key files, and development patterns. This is the primary source for quick context.

### **Documentation.md, Roadmap.md, Accomplished.md**
- **Purpose**: Complete project documentation, feature roadmap, and development history.
- **Usage**: Comprehensive project information and planning.

### **FileDirectory.md**
- **Purpose**: This file - complete directory structure documentation.
- **Contains**: Detailed description of each file's responsibility and architectural relationships.
- **Usage**: Navigate codebase efficiently and understand file organization.

### **TODO.md**
- **Purpose**: Current development priorities and task tracking.
- **Contains**: Active tasks, completed items, and immediate development focus areas.
- **Usage**: Guide current development session priorities and track completion status.

### **alex.md**
- **Purpose**: AI assistant memory and project-specific notes.
- **Contains**: Learning notes, user preferences, and development patterns.
- **Usage**: Maintain AI assistant context across sessions.

---

## 🏗️ Main Application Code (/books/)

### **Application Entry Point (/books/App/)**

#### **/books/App/booksApp.swift**
- **Purpose**: SwiftUI App entry point with SwiftData ModelContainer configuration.
- **Responsibility**: Initialize data persistence layer with migration handling and error recovery.

---

### **📖 Data Models (/books/Models/)**

#### **/books/Models/BookMetadata.swift**
- **Purpose**: Core book information and cultural diversity tracking.
- **Responsibility**: Store comprehensive book details from Google Books API plus enhanced cultural metadata.
- **Key Features**: Hashable conformance for navigation, extensive cultural tracking fields, SwiftData @Model with array handling.

#### **/books/Models/UserBook.swift**
- **Purpose**: User-specific reading tracking and personal book management.
- **Responsibility**: Store reading status, progress, ratings, notes, and personal metadata.

---

### **🎨 Theme and Design System (/books/Theme/ & /books/Extensions/)**

#### **/books/Theme/Theme.swift**
- **Purpose**: Material Design 3 implementation with comprehensive theming.
- **Responsibility**: Define app-wide design tokens, colors, typography, spacing, and animations.
- **Key Features**: MD3 typography tokens, accessibility-aware animations, component styling system.

#### **/books/Extensions/Color+Extensions.swift**
- **Purpose**: Programmatic adaptive color system with dark/light mode support.
- **Responsibility**: Provide computed color properties that adapt to system color scheme.
- **Key Features**: Cultural region colors, status colors, adaptive contrast for accessibility.

#### **/books/Theme/SharedModifiers.swift**
- **Purpose**: Reusable SwiftUI view modifiers for consistent styling.
- **Responsibility**: Provide common styling patterns used across multiple views.

---

### **🔍 Views (/books/Views/)**

#### **Main Views (/books/Views/Main/)**

- **ContentView.swift**: Main app navigation and tab bar structure with NavigationStack for each tab.
- **LibraryView.swift**: Main library display with user's book collection, grid/list layouts, filtering, pull-to-refresh.
- **WishlistView.swift**: Wishlist management for future reading.
- **SearchView.swift**: Google Books API integration and book discovery with NavigationLink-based navigation, enhanced accessibility.
- **StatsView.swift**: Reading analytics and progress visualization with integrated cultural diversity.
- **CulturalDiversityView.swift**: Dedicated cultural diversity tracking and analytics.

#### **Detail Views (/books/Views/Detail/)**

- **BookDetailsView.swift**: Detailed book information and management screen for library books.
- **EditBookView.swift**: Book information editing interface with read-only metadata fields and proper text selection.
- **SearchResultDetailView.swift**: Detailed view for books from search results with duplicate detection, navigation improvements.
- **AuthorSearchResultsView.swift**: View to display results for author searches.

#### **Component Views (/books/Views/Components/)**

- **BookCardView.swift**: Card-style book display component for grid layouts.
- **BookRowView.swift**: Row-style book display component for list layouts.
- **BookCoverImage.swift**: Intelligent book cover image loading and caching with shimmer effects.
- **PageInputView.swift**: Reading progress input interface.
- **SupportingViews.swift**: Additional supporting views and utility components.
- **shared_components.swift**: Collection of reusable UI components.

#### **Forms (/books/Views/Forms/)**
- **Purpose**: Form-specific views and components (directory created for future expansion).

---

### **🔧 Services & Utilities**

#### **Services (/books/Services/)**
- **BookSearchService.swift**: Google Books API integration service with async/await pattern.
- **ImageCache.swift**: Image caching and memory management for book covers.
- **DataMigrationManager.swift**: Handle SwiftData schema migrations and data updates.

#### **Utilities (/books/Utilities/)**
- **barcode_scanner.swift**: ISBN barcode scanning functionality.
- **duplicate_detection.swift**: DuplicateDetectionService for preventing duplicate books in user's library with sophisticated matching logic.

---

### **📊 Analytics and Charts (/books/Charts/)**

- **GenreBreakdownChartView.swift**: Visual representation of reading genres using SwiftUI Charts.
- **MonthlyReadsChartView.swift**: Monthly reading progress visualization.

---

### **🧪 Testing Infrastructure (/booksTests/ & /booksUITests/)**

- The `booksTests` and `booksUITests` directories contain all the unit, integration, and UI tests for the application.
- Comprehensive test coverage for models, services, views, and user workflows.
- **Updated**: Modern UI testing approach using `XCUIDevice.shared.userInterfaceStyle` for dark mode testing.
- **Enhanced**: Accessibility identifiers for stable UI test targeting.

---

### **⚙️ Configuration Files**

- **Info.plist**: App configuration and permissions with production-ready network security settings.
- **books.entitlements**: App capabilities and entitlements.

---

### **📄 Additional Documentation (/books/Markdown/)**

- **data_model_specification.txt**: SwiftData model specifications and relationships.
- **use-swiftdata.txt**: SwiftData implementation guidelines and patterns.

---

## 📁 File Organization Principles

- **Hierarchical Structure**: Clear separation between Views (Main/Detail/Components), Models, Services, Utilities, Theme, and Extensions.
- **Modular Design**: Each directory serves a specific architectural purpose.
- **Scalability**: Structure supports easy addition of new features and components.
- **Separation of Concerns**: Business logic, UI components, data models, and utilities are clearly separated.
- **Navigation Patterns**: Uses modern SwiftUI navigation with NavigationStack and value-based NavigationLink.
- **Accessibility First**: All components designed with VoiceOver, Dynamic Type, and reduced motion support.
- **Security Focused**: Network security hardened with domain whitelisting instead of arbitrary loads.

---

## 🎯 Recent HIG Compliance & Polish Improvements

### **Typography System**
- **Migrated** from fixed font sizes to Material Design 3 typography tokens
- **Enhanced** with Dynamic Type support and accessibility scaling
- **Consistent** use of `.titleMedium()`, `.bodyMedium()`, `.labelSmall()` view modifiers

### **Accessibility Enhancements**
- **Implemented** proper VoiceOver labels and hints throughout the app
- **Added** minimum 44pt touch targets for all interactive elements
- **Replaced** disabled form fields with read-only text selection enabled
- **Enhanced** with accessibility identifiers for stable UI testing

### **Motion & Haptic Improvements**
- **Respects** Reduce Motion accessibility setting in all animations
- **Conditional** haptic feedback that doesn't interfere with VoiceOver
- **Smooth** animations with accessibility-aware timing

### **Navigation Polish**
- **Removed** inappropriate tab bar hiding for better consistency
- **Enhanced** navigation with proper inline titles on detail views
- **Improved** empty state navigation flow between tabs

### **Security Hardening**
- **Replaced** `NSAllowsArbitraryLoads` with domain-specific exceptions
- **Whitelisted** only necessary domains (books.googleapis.com)
- **Added** future-ready photo library permission descriptions

### **Testing Infrastructure**
- **Updated** UI tests to use modern `XCUIDevice.shared.userInterfaceStyle` API
- **Added** accessibility identifiers for robust test targeting
- **Enhanced** with dark mode testing capabilities