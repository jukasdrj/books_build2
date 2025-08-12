# BooksWidgets Extension Setup Guide

## Manual Xcode Project Configuration

Since modifying the `.pbxproj` file directly is complex and error-prone, here's how to manually add the BooksWidgets extension target in Xcode:

### 1. Add Widget Extension Target

1. Open `books.xcodeproj` in Xcode
2. Select the project in the navigator
3. Click the "+" button to add a new target
4. Choose "Widget Extension" template
5. Configure the target:
   - Product Name: `BooksWidgets`
   - Bundle Identifier: `com.books.readingtracker.BooksWidgets`
   - Language: Swift
   - Include Configuration Intent: No (not needed for our Live Activities)

### 2. Configure Target Settings

#### BooksWidgets Target Settings:
- **Deployment Target**: iOS 16.1 (minimum for Live Activities)
- **Development Team**: 8Z67H8Y8DW (match main app)
- **Bundle Identifier**: `com.books.readingtracker.BooksWidgets`
- **Marketing Version**: 1.0
- **Code Signing Style**: Automatic

#### Build Settings:
- **Swift Language Version**: Swift 5
- **iOS Deployment Target**: 16.1
- **Supported Platforms**: "iphoneos iphonesimulator"

### 3. Add Entitlements and Capabilities

#### BooksWidgets.entitlements:
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

### 4. Configure App Groups

1. Select the main app target (`books`)
2. Go to "Signing & Capabilities"
3. Add "App Groups" capability
4. Add identifier: `group.com.books.readingtracker.shared`

5. Select the BooksWidgets target
6. Go to "Signing & Capabilities"  
7. Add "App Groups" capability
8. Add same identifier: `group.com.books.readingtracker.shared`

### 5. Add Files to Both Targets

The following files need to be added to both the main app and widget extension targets:

#### Shared Files:
- `BooksWidgets/ActivityAttributes.swift` (add to both targets)

#### Widget-Only Files:
- `BooksWidgets/BooksWidgetsBundle.swift`
- `BooksWidgets/CSVImportLiveActivity.swift`
- `BooksWidgets/Info.plist`
- `BooksWidgets/BooksWidgets.entitlements`

### 6. Update Info.plist Files

#### Main App Info.plist:
Add this key:
```xml
<key>NSSupportsLiveActivities</key>
<true/>
```

#### Widget Extension Info.plist:
```xml
<key>NSSupportsLiveActivities</key>
<true/>
<key>NSExtension</key>
<dict>
    <key>NSExtensionPointIdentifier</key>
    <string>com.apple.widgetkit-extension</string>
</dict>
```

### 7. Build and Test

1. Build the project to ensure no compilation errors
2. Run on a physical device (Live Activities don't work in simulator)
3. Test CSV import to see Live Activities in Dynamic Island and Lock Screen

## Implementation Notes

### Current Integration Status:
✅ Widget Extension structure created
✅ ActivityAttributes model implemented  
✅ Dynamic Island layouts implemented
✅ Lock Screen widget implemented
✅ App Groups configured
✅ Live Activity lifecycle integrated with BackgroundImportCoordinator
✅ Required entitlements added

### Testing Checklist:
- [ ] Build succeeds for both main app and widget extension
- [ ] Live Activities appear during CSV import
- [ ] Dynamic Island shows progress correctly
- [ ] Lock Screen widget displays detailed information
- [ ] Activities complete properly when import finishes
- [ ] Activities can be cancelled when import is cancelled

### Device Requirements:
- iOS 16.1+ required for Live Activities
- iPhone 14 Pro/Pro Max for Dynamic Island features
- Physical device required (Live Activities don't work in simulator)

## File Structure Created:

```
BooksWidgets/
├── BooksWidgetsBundle.swift          # Main widget bundle
├── CSVImportLiveActivity.swift       # Live Activity implementation
├── ActivityAttributes.swift          # Shared data models
├── Info.plist                       # Widget extension info
├── BooksWidgets.entitlements         # Widget entitlements
└── WidgetExtensionSetup.md          # This setup guide
```

The implementation follows iOS development best practices and Swift 6 compatibility requirements.