# Books Reading Tracker - Setup and Configuration Guide

## Table of Contents

1. [Quick Start](#quick-start)
2. [System Requirements](#system-requirements)
3. [Development Setup](#development-setup)
4. [Widget Extension Configuration](#widget-extension-configuration)
5. [App Configuration](#app-configuration)
6. [Testing Setup](#testing-setup)
7. [Production Deployment](#production-deployment)
8. [Troubleshooting](#troubleshooting)

## Quick Start

### For End Users

1. **Install Requirements**: iOS 16.0+ (iOS 16.1+ recommended for Live Activities)
2. **Download App**: Install from App Store or TestFlight
3. **First Launch**: Grant necessary permissions when prompted
4. **Add Your First Book**: Use the "+" button or try CSV import
5. **Enable Live Activities**: Allow notifications for import progress tracking

### For Developers

1. **Clone Repository**: Download the complete project
2. **Open in Xcode**: Requires Xcode 15+ for Swift 6 support
3. **Configure Signing**: Set development team and bundle identifiers
4. **Build and Run**: Test on simulator or device
5. **Setup Widget Extension**: Manual configuration required (see below)

## System Requirements

### Minimum Requirements

**iOS Device Requirements**:
- **iOS Version**: 16.0 or later
- **Device Storage**: 100MB free space (more for large libraries)
- **RAM**: 2GB recommended for smooth import performance
- **Network**: Internet connection required for book metadata lookup

### Recommended Configuration

**For Optimal Experience**:
- **iOS Version**: 16.1 or later (Live Activities support)
- **Device**: iPhone 14 Pro/Pro Max (Dynamic Island features)
- **Storage**: 500MB+ for extensive libraries with cover images
- **Network**: Wi-Fi recommended for large CSV imports

### Live Activities Support

**Feature Compatibility**:
```swift
// Live Activities device support
iOS 16.1+ → Full Live Activities support
iOS 16.0  → Limited Live Activities (Lock Screen only)
iOS 15.x  → Fallback to traditional progress indicators
iOS 14.x  → Basic progress indicators only
```

**Dynamic Island Features**:
- **iPhone 14 Pro/Pro Max**: Complete Dynamic Island experience
- **Other Devices**: Lock Screen Live Activities only
- **iPad**: Lock Screen widgets (when Apple adds support)

## Development Setup

### Prerequisites

**Required Software**:
- **Xcode**: Version 15.0+ (for Swift 6 support)
- **macOS**: macOS 13.0+ (Ventura) or later
- **Apple Developer Account**: Required for device testing and distribution
- **Command Line Tools**: Xcode command line tools installed

**Optional Tools**:
- **Git**: For version control and collaboration
- **SwiftLint**: Code style enforcement
- **SF Symbols**: Apple's icon library for UI development

### Project Configuration

**1. Clone and Open Project**
```bash
# Clone the repository
git clone <repository-url>
cd books_build2

# Open in Xcode
open books.xcodeproj
```

**2. Configure Development Team**
```swift
// In Xcode project settings:
// 1. Select "books" target
// 2. Go to "Signing & Capabilities"
// 3. Set your development team
// 4. Ensure "Automatically manage signing" is enabled
```

**3. Verify Bundle Identifiers**
```swift
// Main app bundle identifier
com.books.readingtracker

// Widget extension bundle identifier  
com.books.readingtracker.BooksWidgets

// App Group identifier
group.com.books.readingtracker.shared
```

### Dependencies and Frameworks

**Built-in Frameworks Used**:
- **SwiftUI**: Modern declarative UI framework
- **SwiftData**: Modern Core Data replacement
- **ActivityKit**: Live Activities support (iOS 16.1+)
- **WidgetKit**: Widget extension support
- **BackgroundTasks**: Background processing capabilities

**No External Dependencies**:
The project uses only Apple's native frameworks, eliminating dependency management complexity and reducing security risks.

## Widget Extension Configuration

### Manual Xcode Setup Required

Due to the complexity of modifying `.pbxproj` files programmatically, the BooksWidgets extension target requires manual setup in Xcode:

### Step 1: Add Widget Extension Target

**Create Extension Target**:
1. Open `books.xcodeproj` in Xcode
2. Select the project in the navigator (top-level "books" entry)
3. Click the "+" button at bottom left to add new target
4. Choose **"Widget Extension"** from the template list
5. Configure the new target:
   - **Product Name**: `BooksWidgets`
   - **Bundle Identifier**: `com.books.readingtracker.BooksWidgets`
   - **Language**: Swift
   - **Include Configuration Intent**: ❌ No (not needed for Live Activities)

### Step 2: Configure Target Settings

**BooksWidgets Target Configuration**:
```swift
// Deployment settings
iOS Deployment Target: 16.1
Swift Language Version: Swift 6
Supported Platforms: "iphoneos iphonesimulator"

// Signing settings
Development Team: [Your Team ID]
Bundle Identifier: com.books.readingtracker.BooksWidgets
Code Signing Style: Automatic
```

**Build Settings Verification**:
- Ensure **"Automatically manage signing"** is enabled
- Verify **deployment target is 16.1** (required for Live Activities)
- Confirm **Swift version is set to 6.0**

### Step 3: Configure App Groups

**Add App Groups Capability**:

**For Main App (`books` target)**:
1. Select `books` target in Xcode
2. Go to **"Signing & Capabilities"** tab
3. Click **"+ Capability"** button
4. Add **"App Groups"**
5. Add group identifier: `group.com.books.readingtracker.shared`

**For Widget Extension (`BooksWidgets` target)**:
1. Select `BooksWidgets` target in Xcode
2. Go to **"Signing & Capabilities"** tab
3. Click **"+ Capability"** button
4. Add **"App Groups"**
5. Add same group identifier: `group.com.books.readingtracker.shared`

### Step 4: Add Required Files

**Copy Widget Extension Files**:

The following files from the `/BooksWidgets/` directory need to be added to the widget extension target:

```bash
BooksWidgets/
├── BooksWidgetsBundle.swift          # → Add to BooksWidgets target only
├── CSVImportLiveActivity.swift       # → Add to BooksWidgets target only  
├── EnhancedLiveActivityViews.swift   # → Add to BooksWidgets target only
├── ActivityAttributes.swift          # → Add to BOTH targets (shared model)
├── Info.plist                       # → Widget extension Info.plist
└── BooksWidgets.entitlements         # → Widget extension entitlements
```

**File Target Membership**:
- **Widget Extension Only**: Implementation files (Bundle, LiveActivity, Views)
- **Both Targets**: Shared data models (ActivityAttributes)
- **Main App Only**: All other app files

### Step 5: Configure Entitlements

**Main App Entitlements** (`books.entitlements`):
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.books.readingtracker.shared</string>
    </array>
    <key>com.apple.developer.ActivityKit</key>
    <true/>
</dict>
</plist>
```

**Widget Extension Entitlements** (`BooksWidgets.entitlements`):
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.books.readingtracker.shared</string>
    </array>
    <key>com.apple.developer.ActivityKit</key>
    <true/>
</dict>
</plist>
```

### Step 6: Update Info.plist Files

**Main App Info.plist** additions:
```xml
<key>NSSupportsLiveActivities</key>
<true/>
<key>UIBackgroundModes</key>
<array>
    <string>background-processing</string>
    <string>background-fetch</string>
</array>
```

**Widget Extension Info.plist**:
```xml
<key>NSSupportsLiveActivities</key>
<true/>
<key>NSExtension</key>
<dict>
    <key>NSExtensionPointIdentifier</key>
    <string>com.apple.widgetkit-extension</string>
</dict>
```

### Step 7: Build and Test

**Verification Steps**:
1. **Clean Build**: Product → Clean Build Folder
2. **Build Both Targets**: Ensure both main app and widget extension build successfully
3. **Run on Device**: Live Activities require physical device (not simulator)
4. **Test CSV Import**: Verify Live Activities appear during import process
5. **Check Dynamic Island**: Confirm proper layouts on supported devices

## App Configuration

### Background Processing Setup

**App Delegate Configuration**:
The app requires proper background processing setup for CSV imports:

```swift
// In booksApp.swift or AppDelegate
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // Register background tasks
    BackgroundTaskManager.shared.registerBackgroundTasks()
    return true
}
```

**Background Modes Registration**:
Ensure Info.plist includes required background modes:
```xml
<key>UIBackgroundModes</key>
<array>
    <string>background-processing</string>
    <string>background-fetch</string>
</array>
```

### Permissions Configuration

**Required Permissions**:
- **File Access**: For CSV file import (automatic via DocumentPicker)
- **Network Access**: For book metadata lookup (automatic)
- **Background App Refresh**: For background import processing

**Optional Permissions**:
- **Camera Access**: For barcode scanning (requested when used)
- **Notifications**: For import completion alerts (requested when relevant)

**Privacy Descriptions** (Info.plist):
```xml
<key>NSCameraUsageDescription</key>
<string>Camera access is used to scan book barcodes for quick addition to your library.</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>Photo library access allows you to save book cover images.</string>
```

### SwiftData Configuration

**Database Setup**:
The app automatically configures SwiftData with proper migration support:

```swift
// Automatic configuration in booksApp.swift
.modelContainer(for: [
    UserBook.self,
    BookMetadata.self,
    // Additional models...
]) { result in
    // Migration and setup handled automatically
}
```

**Data Migration**:
- Automatic schema migration between app versions
- Backup creation before major migrations
- Data integrity validation after migrations

## Testing Setup

### Unit Testing Configuration

**Test Target Setup**:
The project includes comprehensive test coverage:

```bash
booksTests/
├── ModelTests.swift                  # SwiftData model testing
├── ServiceTests.swift                # Service layer testing
├── CSVImportTests.swift              # Import functionality testing
├── BackgroundProcessingTests.swift   # Background task testing
├── LiveActivityTests.swift           # Live Activities testing
└── [Additional test files...]
```

**Test Configuration**:
- Mock implementations for external dependencies
- Test database with sample data
- Performance benchmarking tests
- Accessibility testing validation

### UI Testing Setup

**UI Test Coverage**:
```bash
booksUITests/
├── ImportWorkflowTests.swift         # End-to-end import testing
├── AccessibilityTests.swift          # VoiceOver compliance testing
├── PerformanceTests.swift            # UI responsiveness testing
└── NavigationTests.swift             # App navigation testing
```

### Live Activities Testing

**Physical Device Requirements**:
- **Simulator Limitation**: Live Activities don't work in iOS Simulator
- **Device Testing**: Requires iPhone/iPad with iOS 16.1+
- **Dynamic Island**: iPhone 14 Pro/Pro Max for complete testing

**Testing Checklist**:
- [ ] Live Activities appear during CSV import
- [ ] Dynamic Island shows correct progress information
- [ ] Lock Screen widget displays properly
- [ ] Activities update in real-time during import
- [ ] Activities complete properly when import finishes
- [ ] Activities cancel when import is cancelled
- [ ] Proper fallback on unsupported devices

## Production Deployment

### App Store Preparation

**Pre-Submission Requirements**:
1. **Complete Testing**: All features tested on physical devices
2. **Live Activities Testing**: Verified on multiple device types
3. **Accessibility Validation**: VoiceOver and accessibility compliance
4. **Performance Optimization**: Memory and battery usage verified
5. **Privacy Policy**: Updated for any data collection practices

**Build Configuration**:
```swift
// Release build settings
Configuration: Release
Code Optimization Level: Optimize for Speed [-O]
Swift Compilation Mode: Whole Module Optimization
Strip Debug Symbols: Yes (for release)
```

### Metadata and Screenshots

**App Store Connect Configuration**:
- **App Description**: Highlight Live Activities and background import features
- **Keywords**: Include "CSV import", "Live Activities", "reading tracker"
- **Screenshots**: Show Dynamic Island and Lock Screen Live Activities
- **Privacy Labels**: Specify no data collection beyond local storage

**Required Screenshots**:
- Library view with books
- CSV import process
- Live Activities in Dynamic Island
- Lock Screen Live Activities
- Analytics and charts screens

### Submission Checklist

**Technical Requirements**:
- [ ] Both main app and widget extension build without warnings
- [ ] All tests pass
- [ ] App follows iOS Human Interface Guidelines
- [ ] Live Activities work properly on test devices
- [ ] Background processing functions correctly
- [ ] Proper error handling and user feedback

**Content Requirements**:
- [ ] App metadata complete
- [ ] Privacy policy updated
- [ ] Screenshots represent current features
- [ ] App description is accurate and compelling
- [ ] Keywords optimized for discovery

## Troubleshooting

### Common Setup Issues

**Widget Extension Build Errors**:
```swift
// Issue: "No such module 'ActivityKit'"
// Solution: Ensure deployment target is iOS 16.1+
iOS Deployment Target → 16.1

// Issue: App Groups not working
// Solution: Verify identical group identifiers in both targets
group.com.books.readingtracker.shared (exactly matching)

// Issue: Live Activities not appearing
// Solution: Test on physical device with iOS 16.1+
// Simulator doesn't support Live Activities
```

**Background Processing Issues**:
```swift
// Issue: Import doesn't continue in background
// Solution: Verify background modes in Info.plist
<key>UIBackgroundModes</key>
<array>
    <string>background-processing</string>
    <string>background-fetch</string>
</array>

// Issue: App terminated during import
// Solution: Check Background App Refresh settings
Settings → General → Background App Refresh → Books Reading Tracker → On
```

**Performance Issues**:
```swift
// Issue: Import is slow
// Solution: Check network connection and concurrent settings
ConcurrentImportConfig.maxConcurrentRequests = 5  // Adjust as needed

// Issue: High memory usage
// Solution: Enable chunked processing for large files
ImportConfiguration.enableChunkedProcessing = true
```

### Debugging Tips

**Live Activities Debugging**:
1. **Check Device Support**: Only iOS 16.1+ on physical devices
2. **Verify Entitlements**: Both targets need ActivityKit entitlement
3. **Monitor Console**: Use Console.app to see Live Activities logs
4. **Test Permission**: Ensure Live Activities are enabled in Settings

**Import Debugging**:
1. **Enable Detailed Logging**: Set debug flags for verbose output
2. **Test Small Files**: Start with small CSV files to isolate issues
3. **Check Network**: Verify internet connection for metadata lookup
4. **Monitor Background Time**: Check remaining background execution time

### Performance Optimization

**Memory Usage**:
- Monitor memory usage during large imports
- Enable chunked processing for files >1000 books
- Implement memory warnings handling

**Battery Optimization**:
- Use efficient processing algorithms
- Batch network requests to minimize radio usage
- Respect Low Power Mode settings

**Network Efficiency**:
- Implement request caching for repeated ISBN lookups
- Use appropriate timeout values
- Handle network failures gracefully

### Support Resources

**Apple Documentation**:
- [ActivityKit Documentation](https://developer.apple.com/documentation/activitykit)
- [WidgetKit Framework](https://developer.apple.com/documentation/widgetkit)
- [Background Tasks](https://developer.apple.com/documentation/backgroundtasks)
- [SwiftData Guide](https://developer.apple.com/documentation/swiftdata)

**Community Resources**:
- [Swift Forums](https://forums.swift.org/)
- [Apple Developer Forums](https://developer.apple.com/forums/)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/ios)

---

## Configuration Summary

### Successful Setup Indicators

**Development Environment**:
- ✅ Xcode 15+ with Swift 6 support
- ✅ Both main app and widget extension targets build successfully
- ✅ App Groups configured identically in both targets
- ✅ Proper entitlements for Live Activities and background processing

**Testing Environment**:
- ✅ Physical device with iOS 16.1+ for Live Activities testing
- ✅ All unit and integration tests passing
- ✅ Background processing working correctly
- ✅ CSV import completing successfully with progress updates

**Production Environment**:
- ✅ Release builds optimized and tested
- ✅ App Store metadata and screenshots prepared
- ✅ Privacy policy updated for current features
- ✅ All required permissions and descriptions configured

The setup process ensures a robust, performant, and user-friendly application ready for both development and production deployment. The manual Widget Extension configuration is necessary due to Xcode project complexity, but results in a fully functional Live Activities experience that enhances the CSV import process significantly.

---

**Setup Guide Version**: 2.0 (Phase 2 Complete)  
**Last Updated**: August 2024  
**Xcode Version**: 15.0+  
**iOS Deployment Target**: 16.0 (16.1 for Live Activities)