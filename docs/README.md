# Documentation Index

> Comprehensive documentation for the Books Reading Tracker iOS app

## 📖 **Quick Navigation**

### **Getting Started**
- [📱 Main README](../README.md) - Project overview and installation
- [🛠️ Development Setup](development/CLAUDE.md) - Complete setup guide
- [🚀 Deployment Checklist](development/deployment-checklist.md) - Production readiness

### **Architecture & Design**
- [🏗️ System Overview](architecture/overview.md) - Overall architecture and design decisions
- [🎨 iOS 26 Liquid Glass](architecture/ios26-liquid-glass.md) - Complete design system implementation  
- [⚙️ Background Processing](architecture/background-processing.md) - CSV import and background tasks
- [💻 macOS Migration](architecture/MACOS_MIGRATION_PLAN.md) - Future macOS app plans

### **Features & Implementation**
- [📥 CSV Import System](features/csv-import.md) - Advanced import with validation
- [⚡ Batch Processing](features/batch-processing.md) - CloudFlare Workers batch API
- [🔍 Search Optimization](features/search-optimization.md) - Proxy and caching strategy
- [📊 Implementation Examples](features/) - Code samples and integration guides

### **Development Resources**
- [📋 Code Review](development/code-review.md) - Comprehensive codebase analysis
- [📁 Project Structure](development/FileDirectory.md) - File organization guide
- [📝 Development Notes](development/sourceTodo.md) - Technical notes and TODOs
- [🔧 Widget Configuration](development/BooksWidgets_Manual_Configuration.md) - Live Activities setup

### **Project Management**
- [🗺️ Feature Roadmap](project/feature-roadmap.md) - Complete development roadmap
- [🎨 UI Enhancement Plan](project/ui-enhancement-plan.md) - Data quality UI implementation
- [📈 Project Summary](project/ProjectSummary.md) - Executive overview
- [📝 Changelog](project/CHANGELOG.md) - Version history

## 📚 **Documentation Standards**

### **File Organization**
```
docs/
├── README.md                    # This index file
├── architecture/               # System design and technical architecture
├── development/               # Setup guides and development resources  
├── features/                  # Feature-specific implementation guides
├── project/                   # Project management and planning
├── deployment/               # Deployment and production guides
└── api/                      # API documentation and references
```

### **Cross-Reference Guidelines**
- **Internal Links**: Use relative paths from document location
- **External Links**: Full URLs with descriptive link text
- **Code References**: Include file path and line numbers where applicable
- **Screenshots**: Store in relevant feature documentation folders

### **Content Standards**
- **Headers**: Use consistent H1/H2/H3 hierarchy
- **Code Blocks**: Always specify language for syntax highlighting
- **Examples**: Provide real, working code examples
- **Updates**: Include "Last Updated" date for time-sensitive content

## 🎯 **Current Status**

### ✅ **Completed Documentation**
- **Architecture**: Complete system overview and iOS 26 implementation
- **Features**: Comprehensive CSV import and batch processing guides
- **Development**: Full setup and deployment procedures
- **Project**: Detailed roadmaps and enhancement plans

### 🔄 **In Progress**
- **API Documentation**: CloudFlare Workers endpoint reference
- **User Guides**: End-user feature documentation
- **Troubleshooting**: Common issues and solutions

### 📋 **Planned Enhancements**
- **Architecture Decision Records (ADRs)**: Design decision documentation
- **Performance Guides**: Optimization and monitoring procedures
- **Contributing Guidelines**: External contributor onboarding

## 🔗 **Key External References**

### **Apple Documentation**
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
- [SwiftData Guide](https://developer.apple.com/documentation/swiftdata/)
- [iOS 26 Design Guidelines](https://developer.apple.com/design/human-interface-guidelines/)

### **Third-Party Services**
- [CloudFlare Workers Docs](https://developers.cloudflare.com/workers/)
- [Google Books API](https://developers.google.com/books/)
- [ISBNdb API Documentation](https://isbndb.com/api/docs)

### **Development Tools**
- [Xcode Documentation](https://developer.apple.com/documentation/xcode/)
- [Swift 6 Language Guide](https://docs.swift.org/swift-book/)
- [TestFlight Integration](https://developer.apple.com/testflight/)

---

## 📞 **Documentation Feedback**

For documentation improvements, issues, or suggestions:
1. Review existing documentation for accuracy
2. Check cross-references and links
3. Verify code examples work correctly
4. Ensure screenshots are current with iOS 26 implementation

**Last Updated**: December 2024 - iOS 26 Migration Phase 1 Complete