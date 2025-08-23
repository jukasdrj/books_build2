# Books Reading Tracker

> A sophisticated SwiftUI iOS app for book tracking with cultural diversity features and iOS 26 Liquid Glass design

[![iOS](https://img.shields.io/badge/iOS-16.0+-blue.svg)]()
[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)]()
[![Xcode](https://img.shields.io/badge/Xcode-15+-blue.svg)]()
[![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0-green.svg)]()

## Quick Start

- [📱 Installation](#installation)
- [🛠️ Development Setup](docs/development/CLAUDE.md)
- [🏗️ Architecture Overview](docs/architecture/overview.md)
- [📚 Feature Documentation](docs/features/)

## ✨ Features

### 🎨 **iOS 26 Liquid Glass Design System**
- Complete iOS 26 Liquid Glass implementation with 5 material variants
- Fluid animations and spring-based transitions
- Enhanced iPad search interface with translucent glass materials
- Accessibility-compliant with VoiceOver and dynamic type support

### 📚 **Personal Library Management**
- SwiftData-powered library with cultural diversity tracking
- Advanced reading analytics with interactive charts
- Comprehensive book metadata with Google Books API integration
- Smart duplicate detection and data validation

### 📥 **Advanced CSV Import System**
- **Background Processing**: Import large libraries without UI blocking
- **Batch API Integration**: 4x faster imports with ISBNdb batch processing
- **Smart Data Validation**: ISBN checksum verification and quality scoring
- **State Persistence**: Resume interrupted imports across app lifecycle
- **CloudFlare Workers Proxy**: Secure, cached API integration

### 🌍 **Cultural Diversity Tracking**
- Author demographics with inclusive gender options
- Regional categorization with standardized ISO codes
- Language and translation tracking
- Visual diversity analytics and goal setting

### 🔍 **Intelligent Search**
- Real-time search with provider routing (Google Books, ISBNdb)
- Advanced filtering by status, genre, and cultural metadata
- Enhanced iPad interface with glass capsule controls
- Empty state with immersive depth shadows

## 🏗️ Architecture

### **Core Technologies**
- **SwiftUI + SwiftData**: Modern iOS development with Swift 6 concurrency
- **iOS 26 Liquid Glass**: Complete design system with 5 glass materials
- **CloudFlare Workers**: Optimized proxy with batch API support
- **Background Processing**: BGTaskScheduler integration for imports
- **Comprehensive Testing**: 35+ test files with full coverage

### **Key Services**
- **BookSearchService**: CloudFlare proxy integration with batch support
- **CSVImportService**: Advanced import with background processing
- **DataCompletenessService**: Smart prompt generation and quality analysis
- **BackgroundImportCoordinator**: Singleton coordinator for seamless imports

## 📁 Project Structure

```
books_build2/
├── books/                          # Main iOS app
│   ├── Views/                     # SwiftUI views organized by feature
│   ├── Models/                    # SwiftData models
│   ├── Services/                  # Business logic and API integration
│   └── Theme/                     # iOS 26 Liquid Glass design system
├── docs/                          # Comprehensive documentation
│   ├── architecture/             # System design and iOS 26 implementation
│   ├── features/                 # Feature-specific documentation
│   ├── development/              # Setup and development guides
│   └── project/                  # Roadmaps and project plans
├── server/                       # CloudFlare Workers proxy
├── test-resources/               # Test data and CSV samples
├── booksTests/                   # Unit and integration tests
└── Marketing/                    # App Store assets and copy
```

## 🚀 Installation

### For End Users
1. **Requirements**: iOS 16.0+, iPhone or iPad
2. **Installation**: Download from App Store or TestFlight
3. **First Launch**: Grant permissions for optimal experience

### For Developers
```bash
# Clone the repository
git clone <repository-url>
cd books_build2

# Open in Xcode
open books.xcodeproj

# Build and run
⌘+R
```

See [Development Setup Guide](docs/development/CLAUDE.md) for detailed instructions.

## 📚 Documentation

### **Architecture & Design**
- [📖 System Overview](docs/architecture/overview.md)
- [🎨 iOS 26 Liquid Glass System](docs/architecture/ios26-liquid-glass.md)
- [⚙️ Background Processing](docs/architecture/background-processing.md)

### **Features & Implementation**
- [📥 CSV Import System](docs/features/csv-import.md)
- [⚡ Batch Processing](docs/features/batch-processing.md)
- [🔍 Search Optimization](docs/features/search-optimization.md)

### **Development & Deployment**
- [🛠️ Development Setup](docs/development/CLAUDE.md)
- [📋 Code Review](docs/development/code-review.md)
- [🚀 Deployment Checklist](docs/development/deployment-checklist.md)

### **Project Management**
- [🗺️ Feature Roadmap](docs/project/feature-roadmap.md)
- [🎨 UI Enhancement Plan](docs/project/ui-enhancement-plan.md)
- [📝 Changelog](docs/project/CHANGELOG.md)

## ⚡ Performance

### **Technical Excellence**
- **Build Status**: ✅ Successfully builds for iPad Pro 13-inch (M4)
- **Swift 6 Compliance**: Full concurrency model with Sendable conformance
- **Thread Safety**: Proper actor isolation with @MainActor patterns
- **iOS 26 Ready**: Complete Liquid Glass implementation

### **Performance Metrics**
- **CSV Import**: Up to 4x faster with batch API integration
- **Search Response**: <500ms with CloudFlare edge caching
- **Memory Usage**: Optimized with JSON caching and virtual scrolling
- **Background Processing**: 30+ seconds execution time with state persistence

## 🧪 Testing

```bash
# Run unit tests
⌘+U

# Run UI tests
⌘+Shift+U

# Performance testing
See docs/development/deployment-checklist.md
```

**Test Coverage**: 35+ test files covering:
- Model behavior and SwiftData integration
- Service layer with API mocking
- CSV import workflows and validation
- Background processing and state management
- UI components and navigation flows

## 🎯 Current Status (December 2024)

### ✅ **Completed Features**
- **iOS 26 Migration Phase 1**: Complete Liquid Glass foundation
- **Background Import System**: Production-ready with state persistence  
- **Data Quality Engine**: Smart prompt generation and completeness tracking
- **Batch API Integration**: CloudFlare Workers with ISBNdb support
- **Performance Optimization**: JSON caching and memory management

### 🔄 **In Progress**
- **UI Polish Phase 1**: Integration of data quality features
- **Enhanced Analytics**: Advanced cultural diversity insights
- **Live Activities**: Temporarily disabled pending App Store approval

## 🤝 Contributing

This is a private project. For contribution guidelines, see [Development Setup](docs/development/CLAUDE.md).

## 📄 License

Private License - See [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with **SwiftUI** and **SwiftData** for modern iOS development
- **CloudFlare Workers** for scalable API proxy infrastructure
- **Google Books API** and **ISBNdb** for comprehensive book metadata
- **iOS 26 Liquid Glass** design system for cutting-edge user experience

---

**Note**: Live Activities (ActivityKit) infrastructure is present but temporarily disabled for initial App Store release. All other features are fully functional and production-ready.

For detailed technical information, architecture decisions, and implementation guides, explore the comprehensive documentation in the [`docs/`](docs/) directory.

# Auto-versioning enabled
