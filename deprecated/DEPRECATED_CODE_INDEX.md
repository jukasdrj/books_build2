# Deprecated Code Index

> **⚠️ CRITICAL**: This document catalogs all deprecated code, files, and references found in the codebase as of September 2025. Use this to clean up legacy code and avoid using deprecated patterns.

## Summary of Findings

- **11 deprecated/legacy files** identified
- **120+ files using old MD3/Material Design patterns**
- **50+ files using deprecated theming system**
- **Multiple obsolete UI patterns** requiring modernization
- **Legacy dependency patterns** that can be removed

---

## 📁 Deprecated Files & Legacy References

### Core Deprecated Views
```
deprecated/LiquidGlassCulturalDiversityView.swift.deprecated
deprecated/LiquidGlassStatsView.swift.deprecated
books/Theme/LiquidGlassComponentGuide.swift.bak
```

**Status**: ✅ Already moved to deprecated folder  
**Replacement**: `ReadingInsightsView.swift` (unified implementation)  
**Action Required**: None - properly deprecated

---

## 🎨 Material Design 3 (MD3) Legacy System

### Files with Heavy MD3 Dependencies
```
books/Theme/Theme.swift:1-600                     # Complete MD3 theme system
books/Extensions/Color+Extensions.swift:1-500     # MD3 color extensions  
books/Styling/ThemeMigrationHelper.swift:1-58     # MD3 migration helpers
books/Stores/ThemeStore.swift:1-127               # Old theme store
```

### MD3 Pattern Usage (17 files found)
- **Theme.swift**: Lines 3-178 contain full MD3 design system
- **Color+Extensions.swift**: Lines 199-444 contain MD3 color implementations
- **ThemeMigrationHelper.swift**: Lines 4-58 contain `Color.theme` migration helpers

**⚠️ High Priority**: Replace with `UnifiedThemeStore` and iOS 26 Liquid Glass system

---

## 🔧 Deprecated Theming System References

### Environment Key Patterns (Legacy)
```swift
@Environment(\.appTheme) private var theme         # Found in 50+ files
@Environment(\.themeStore) private var themeStore  # Found in 10+ files
```

**Should be**: `@Environment(\.unifiedThemeStore) private var themeStore`

### Files Still Using Old Theme Environment (Sample)
```
books/Views/Main/ContentView.swift:8
books/Views/Main/LibraryView.swift:6
books/Views/Import/CSVImportView.swift:15
books/Views/Detail/BookDetailsView.swift:7
books/Views/Components/BookRowView.swift:11
books/Views/Components/SharedComponents.swift:6
```

**Action Required**: Migrate to `@Environment(\.unifiedThemeStore)`

---

## 🧩 Legacy UI Patterns & Components

### Deprecated SwiftUI Patterns
| Pattern | Location | Lines | Modern Alternative |
|---------|----------|-------|-------------------|
| `NavigationView` | `books/Theme/LiquidGlassComponentGuide.swift.bak` | 120 | `NavigationStack` |
| `TabView` with old styling | Multiple files | Various | iOS 26 native TabView |
| `@StateObject`/`@ObservedObject` | 25+ files | Various | `@Observable` (Swift 6) |
| `.preferredColorScheme()` | `ContentView.swift`, `iOS26ContentView.swift` | 35, 83 | System-managed color scheme |

### Deprecated Animation Patterns
```swift
.animation(.easeInOut(duration: 0.1), value: false)  # SimpleiOSMigration.swift:125
```
**Should use**: iOS 26 Liquid Glass fluid animations

---

## 📦 Unnecessary Dependencies & Dead Imports

### UIKit Imports (Modern SwiftUI Patterns Available)
```
books/Extensions/Color+Extensions.swift:2          # UIKit import
books/Views/Components/BookCoverImage.swift:9      # UIKit import  
books/Theme/LiquidGlassPerformance.swift:2         # UIKit import
books/Utilities/BarcodeScanner.swift:1             # UIKit import (needed for scanner)
```

**Analysis**: Most UIKit imports can be removed except:
- `BarcodeScanner.swift` (requires camera access)
- `HapticFeedbackManager.swift` (haptic feedback)
- `BackgroundTaskManager.swift` (background processing)

### Combine Framework Usage (3 files)
```
books/Services/MetadataEnrichmentService.swift     # @Published, ObservableObject
books/Services/IncompleteBookAnalyzer.swift        # @Published, ObservableObject  
books/Services/CSVImportService.swift              # @Published, ObservableObject
```
**Modern Alternative**: Use `@Observable` macro (Swift 6)

---

## 🏗️ Migration-Specific Legacy Files

### Migration Helper Files (Can be removed post-migration)
```
books/Theme/MigrationPattern.swift:1-149           # Migration template
books/Theme/iOS26Migration.swift:1-317             # iOS 26 migration guide
books/Theme/SimpleiOSMigration.swift:1-209         # Simple iOS migration
books/Styling/ThemeMigrationHelper.swift:1-58      # Theme migration helpers
```

**Status**: Keep until full iOS 26 migration is complete, then remove

### Migration Tracker Files
```
books/Theme/MigrationTracker.swift                 # Track migration progress
books/Theme/ThemeSystemBridge.swift                # Bridge old/new systems
```

**Status**: Can be removed once migration is 100% complete

---

## 🗑️ Dead Code Patterns

### Unused Color Extensions
```swift
// Color+Extensions.swift:199
// Legacy static references removed - use @Environment(\.appTheme) instead
extension Color {
    // Empty extension with comment only
}
```

### Commented-Out Theme References
```swift
// Theme.swift:169-177
enum Color {
    // Legacy color aliases removed - use @Environment(\.appTheme) instead
    // This enum is kept temporarily for compatibility but should not be used in new code.
}
```

### Empty/Placeholder Methods
```swift
// Theme.swift:444 - Empty helper method section
// MARK: - Helper Method for Color Adaptation
```

---

## 🔍 Search Patterns for Engineers

### Find All MD3 References
```bash
grep -r "md3\|material.?design\|material.?3" . --include="*.swift"
```

### Find Old Theme Usage
```bash
grep -r "@Environment.*appTheme\|Color\.theme" . --include="*.swift"
```

### Find ObservableObject Usage  
```bash
grep -r "ObservableObject\|@Published\|@StateObject" . --include="*.swift"
```

### Find NavigationView Usage
```bash
grep -r "NavigationView\|navigationBarTitleDisplayMode" . --include="*.swift"
```

---

## 📋 Action Items by Priority

### 🔴 High Priority (Breaks iOS 26 compatibility)
1. **Migrate Theme System**: Replace all `@Environment(\.appTheme)` with `@Environment(\.unifiedThemeStore)`
2. **Remove MD3 Dependencies**: Delete `Theme.swift` Material Design 3 system
3. **Update Navigation**: Replace `NavigationView` with `NavigationStack`

### 🟡 Medium Priority (Performance/Maintenance)
1. **Observable Migration**: Replace `@StateObject`/`@ObservedObject` with `@Observable`
2. **Clean UIKit Imports**: Remove unnecessary UIKit imports
3. **Animation Updates**: Replace old animations with Liquid Glass fluid animations

### 🟢 Low Priority (Post-Migration Cleanup)
1. **Remove Migration Files**: Delete migration helper files after completion
2. **Clean Comments**: Remove deprecated code comments and empty extensions
3. **Update Documentation**: Update inline documentation to reflect new patterns

---

## 🛠️ Automated Cleanup Scripts

### Remove Deprecated Comments
```bash
# Remove lines containing "Legacy" or "deprecated" in comments
sed -i '' '/\/\/ Legacy\|\/\/ DEPRECATED\|\/\/ deprecated/d' **/*.swift
```

### Find Empty Extensions
```bash
# Find extensions with only comments
grep -l "extension.*{[[:space:]]*\/\/" **/*.swift
```

---

## ✅ Migration Completion Checklist

- [ ] All `@Environment(\.appTheme)` replaced with `@Environment(\.unifiedThemeStore)`
- [ ] Material Design 3 system completely removed
- [ ] All `NavigationView` updated to `NavigationStack`
- [ ] ObservableObject patterns migrated to `@Observable`
- [ ] Unnecessary UIKit imports removed
- [ ] Migration helper files deleted
- [ ] Empty extensions and dead code removed
- [ ] Documentation updated

---

## 📚 Additional Resources

- **New Theme System**: `books/Theme/ThemeSystemBridge.swift` 
- **iOS 26 Components**: `books/Theme/LiquidGlassComponents.swift`
- **Migration Examples**: `books/Theme/MigrationPattern.swift`
- **Current Themes**: 11 variants (5 MD3 + 6 Liquid Glass) in `UnifiedThemeStore`

---

*Generated: September 2025*  
*Next Review: After iOS 26 migration completion*