# BooksWidgets Extension Manual Configuration (Live Activities Temporarily Disabled)

This document provides the necessary steps to manually configure the `BooksWidgets` extension in Xcode. The Live Activities functionality has been temporarily disabled due to a certificate issue, but the widget target can still be configured.

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
*   `BooksWidgets/Info.plist`
*   `BooksWidgets/BooksWidgets.entitlements`

### Step 5: Build and Test

1.  **Clean Build**: Product > Clean Build Folder
2.  **Build Both Targets**: Ensure both the main app and widget extension build successfully.
3.  **Run on Device**: Test the widget on a physical device or simulator.
