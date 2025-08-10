# Development Commands & Workflows

## Primary Development Commands (Xcode)
- **Build**: ⌘+B or Product → Build
- **Run**: ⌘+R or Product → Run  
- **Test**: ⌘+U or Product → Test
- **Clean**: ⌘+Shift+K or Product → Clean Build Folder

## Project Structure
- **Main Project**: `books.xcodeproj`
- **Scheme**: `books.xcscheme` (Debug/Release configurations)
- **Targets**:
  - `books` - Main application
  - `booksTests` - Unit tests (model, service, integration tests)
  - `booksUITests` - UI automation tests

## Testing Strategy
### Unit Tests (`booksTests` target)
Run comprehensive test suite covering:
- Model behavior and SwiftData operations
- Service integration (BookSearchService, CSVImportService)
- Import workflows and duplicate detection
- Image caching and haptic feedback

### UI Tests (`booksUITests` target)  
- Navigation flows between tabs and detail views
- Theme switching and visual regression
- CSV import workflows end-to-end
- App launch and critical user paths

### CSV Test Suite (External)
Located in `test_csv_files/`:
```bash
cd test_csv_files
swift test_csv_import.swift
```

## Build Status
- ✅ Successfully builds for iPhone 16 simulator (arm64-apple-ios18.0-simulator)
- ✅ All SwiftUI previews working with proper theme environment injection
- ✅ Material Design modifiers corrected and functional

## No External Dependencies
This project uses only built-in iOS frameworks:
- SwiftUI, SwiftData, Foundation
- No CocoaPods, SPM packages, or third-party libraries
- Clean, dependency-free architecture