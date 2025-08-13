## BooksWidgets Extension Manual Configuration

This document provides the necessary steps to manually configure the `BooksWidgets` extension in Xcode.

### Step 1: Add Widget Extension Target

1.  Open `books.xcodeproj` in Xcode.
2.  Select the project in the navigator (top-level "books" entry).
3.  Click the "+" button at the bottom left to add a new target.
4.  Choose **"Widget Extension"** from the template list.
5.  Configure the new target:
    *   **Product Name**: `BooksWidgets`
*   **Bundle Identifier**: `Z67H8Y8DW.com.oooefam.booksV3.BooksWidgets`
    *   **Language**: Swift
    *   **Include Configuration Intent**: No

### Step 2: Configure Target Settings

*   **iOS Deployment Target**: 16.1
*   **Swift Language Version**: Swift 6
*   **Supported Platforms**: "iphoneos iphonesimulator"
*   **Development Team**: [Your Team ID]
*   **Code Signing Style**: Automatic

### Step 3: Configure App Groups

**For both the main app (`books`) and the widget extension (`BooksWidgets`) targets:**

1.  Select the target in Xcode.
2.  Go to the **"Signing & Capabilities"** tab.
3.  Click the **"+ Capability"** button.
4.  Add **"App Groups"**.
5.  Add the group identifier: `group.Z67H8Y8DW.com.oooefam.booksV3`

### Step 4: Add Required Files

Add the following files from the `/BooksWidgets/` directory to the `BooksWidgets` target:

*   `BooksWidgets/BooksWidgetsBundle.swift`
*   `BooksWidgets/CSVImportLiveActivity.swift`
*   `BooksWidgets/EnhancedLiveActivityViews.swift`
*   `BooksWidgets/ActivityAttributes.swift` (add to **both** targets)
*   `BooksWidgets/Info.plist`
*   `BooksWidgets/BooksWidgets.entitlements`

### Step 5: Configure Entitlements

**Main App Entitlements (`books.entitlements`):**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.Z67H8Y8DW.com.oooefam.booksV3</string>
    </array>
    <key>com.apple.developer.ActivityKit</key>
    <true/>
</dict>
</plist>
```

**Widget Extension Entitlements (`BooksWidgets.entitlements`):**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.Z67H8Y8DW.com.oooefam.booksV3</string>
    </array>
    <key>com.apple.developer.ActivityKit</key>
    <true/>
</dict>
</plist>
```

### Step 6: Update Info.plist Files

**Main App `Info.plist` additions:**

```xml
<key>NSSupportsLiveActivities</key>
<true/>
<key>UIBackgroundModes</key>
<array>
    <string>background-processing</string>
    <string>background-fetch</string>
</array>
```

**Widget Extension `Info.plist`:**

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

1.  **Clean Build**: Product > Clean Build Folder
2.  **Build Both Targets**: Ensure both the main app and widget extension build successfully.
3.  **Run on Device**: Live Activities require a physical device.
4.  **Test CSV Import**: Verify Live Activities appear during the import process.
5.  **Check Dynamic Island**: Confirm proper layouts on supported devices.

