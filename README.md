# Books Reading Tracker

Note: Live Activities (ActivityKit) is present in the codebase but temporarily disabled for the initial App Store release due to certificate/licensing setup. The rest of the app is fully functional.

A comprehensive SwiftUI application for tracking your personal book library with advanced CSV import capabilities.

## Table of Contents

- [Features](#features)
- [Quick Start](#quick-start)
- [Setup](#setup)
- [Build](#build)
- [Run](#run)
- [Troubleshooting](#troubleshooting)
- [Product Roadmap](#product-roadmap)
- [Contributing](#contributing)
- [License](#license)
- [Acknowledgments](#acknowledgments)

## Features

### Core Reading Tracking
- **Personal Library Management**: Track books with detailed metadata, ratings, and reading status
- **Reading Goals**: Set and monitor yearly reading targets with visual progress
- **Cultural Diversity Tracking**: Monitor diversity across gender, ethnicity, and language with standardized ISO codes
- **Comprehensive Search**: Find books by title, author, genre, or ISBN with real-time filtering
- **Visual Analytics**: Beautiful charts showing reading patterns and genre breakdowns

### Advanced CSV Import System
- **Background Processing**: Import large libraries without blocking the UI
- **Smart Data Validation**: ISBN checksum verification, advanced date parsing, and data quality scoring
- **Intelligent Reading Progress**: Automatically sets reading progress and page counts based on import status
- **Smart Book Matching**: ISBN lookup with fallback to title/author search
- **Concurrent Processing**: 5x faster imports with parallel API calls
- **State Persistence**: Resume interrupted imports after app crashes or termination
- **Cultural Data Integration**: Streamlined diversity tracking with standardized selectors
- **Live Activities (Temporarily Disabled)**: The UI and plumbing exist, but the feature is gated off until certificate/licensing is resolved for release.

### User Experience
- **Dynamic Theming**: Multiple themes with system integration
- **Accessibility**: Full VoiceOver support and accessibility compliance
- **Haptic Feedback**: Contextual feedback for user interactions
- **Responsive Design**: Optimized for all iPhone and iPad screen sizes

## Quick Start

### For End Users
1. **Install Requirements**: iOS 16.0+
2. **Download App**: Install from App Store or TestFlight
3. **First Launch**: Grant necessary permissions when prompted
4. **Add Your First Book**: Use the "+" button or try CSV import

### For Developers
1. **Clone Repository**: Download the complete project
2. **Open in Xcode**: Requires Xcode 15+ for Swift 6 support
3. **Configure Signing**: Set development team and bundle identifiers
4. **Build and Run**: Test on simulator or device

## Setup

### Google Books API configuration

To securely manage your Google Books API credentials, this project uses a combination of `xcconfig` files for local development and the device's Keychain for secure storage.

**How it Works:**
1.  **Local Configuration (`xcconfig`):** Your API key is stored in a `Config.xcconfig` file at the project root. This file is listed in `.gitignore` to prevent your key from being committed to source control.
2.  **First Launch:** When the app is run for the first time, it reads the API key from the `xcconfig` file (via the `Info.plist`) and securely saves it to the device's Keychain.
3.  **Subsequent Launches:** On all subsequent launches, the app retrieves the API key directly from the Keychain.

This ensures that the API key is not stored in plain text within the app bundle and is protected by the device's security.

**Setup:**
1.  Create a `Config.xcconfig` file in the project root with the following content:
    ```
    GOOGLE_BOOKS_API_KEY = YOUR_API_KEY_HERE
    ```
2.  For debugging, you can use the `Config.test.xcconfig` file to provide a test key for debug builds.

### Diagnostics and Debug Console (Debug builds)
- GoogleBooksDiagnostics collects lightweight request/response metadata and can export a textual report.
- Open the Debug Console from the Search screen toolbar menu (…) → Open Debug Console (Debug builds only).
- You can also export diagnostics from the same menu → Export Diagnostics.

### Prerequisites
**Required Software**:
- **Xcode**: Version 15.0+ (for Swift 6 support)
- **macOS**: macOS 13.0+ (Ventura) or later
- **Apple Developer Account**: Required for device testing and distribution
- **Command Line Tools**: Xcode command line tools installed

**Optional Tools**:
- **Git**: For version control and collaboration
- **SwiftLint**: Code style enforcement

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
Z67H8Y8DW.com.oooefam.booksV3

// Widget extension bundle identifier
Z67H8Y8DW.com.oooefam.booksV3.BooksWidgets

// App Group identifier
group.Z67H8Y8DW.com.oooefam.booksV3
```

## Build

To open the project, use one of the following methods:

1.  **Using Finder:** Navigate to the project's root directory and double-click on `books.xcodeproj`.
2.  **Using the Command Line:**
    ```bash
    open books.xcodeproj
    ```

### Scheme Selection

Xcode uses schemes to define which targets to build, what build configuration to use, and what executable to run. This project includes the following schemes:

*   **books:** This is the main scheme for the application. Use this scheme to build, run, and test the main app.
*   **Book_Tracker_Widget:** This scheme is for the widget extension. Use it to build and run the widget on the home screen.

To select a scheme, click on the active scheme name in the Xcode toolbar (next to the run/stop buttons) and choose the desired scheme from the dropdown menu.

### Build Settings

For the most part, the default build settings should be sufficient. However, you may need to adjust the following:

*   **Build Configuration:** You can switch between `Debug` and `Release` configurations in the scheme editor. `Debug` is for development and includes debugging symbols, while `Release` is optimized for performance and is used for App Store distribution.
*   **Compiler Flags:** If you need to add custom compiler flags, you can do so in the "Swift Compiler - Custom Flags" or "Apple Clang - Custom Compiler Flags" sections of the build settings.

### Signing and Capabilities

To run the app on a physical device or distribute it to the App Store, you will need to configure code signing.

1.  Select the `books` project in the Project Navigator.
2.  Go to the "Signing & Capabilities" tab.
3.  Select your development team from the "Team" dropdown menu. If you don't have a team set up, you will need to add your Apple ID in Xcode's preferences.
4.  Ensure that a signing certificate and provisioning profile are automatically generated or manually selected.

Repeat this process for the `Book_Tracker_Widget` target.

#### Capabilities

This project uses the following capabilities:

*   **App Groups:** To share data between the main app and the widget extension.
*   **iCloud:** To sync data across devices.

## Run

### Simulator
To run the app on the simulator:

1.  Select a simulator from the device dropdown in the Xcode toolbar.
2.  Click the "Run" button or press `Cmd+R`.

### Physical Device
To run the app on a physical device:

1.  Connect your device to your Mac.
2.  Select your device from the device dropdown in the Xcode toolbar.
3.  Click the "Run" button or press `Cmd+R`.

## Troubleshooting

Here are some common build errors and their solutions:

*   **"Code signing is required for product type 'Application' in SDK 'iOS...'"**: This usually means there's an issue with your code signing configuration. Double-check your team selection and provisioning profiles in the "Signing & Capabilities" tab.
*   **"No such module 'SomeFramework'"**: This error indicates that a dependency is missing. Make sure you have opened the `.xcworkspace` file and that all dependencies have been correctly installed. You can try running `pod install` or `carthage update` if you are using CocoaPods or Carthage.
*   **Build fails with a "Command PhaseScriptExecution failed with a nonzero exit code" error**: This can have many causes. Check the build logs for more specific error messages. It could be a script failing, a missing file, or a permission issue.
*   **The widget is not updating**: Make sure the App Group identifier is correctly configured for both the main app and the widget extension. Also, check the widget's timeline provider to ensure it's providing up-to-date information.

**Widget Extension Build Errors** (Live Activities are temporarily disabled):
```swift
// Issue: "No such module 'ActivityKit'"
// Solution: The Live Activities feature has been temporarily disabled due to a certificate issue. All related code has been commented out.

// Issue: App Groups not working
// Solution: Verify identical group identifiers in both targets
group.Z67H8Y8DW.com.oooefam.booksV3 (exactly matching)
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

## Product Roadmap

### Immediate Next Steps (Low-Risk, High-Impact)

1.  **Resolve Certificate Issue:** The highest priority is to resolve the `ActivityKit` certificate issue to re-enable Live Activities. This is a critical feature for the app's user experience.
2.  **CloudKit Integration:** Implement robust iCloud syncing to ensure data consistency across a user's devices. This is a high-value feature that significantly improves the user experience.
3.  **UI/UX Polish:** Conduct a thorough review of the user interface to identify and address any inconsistencies or areas for improvement. This includes refining animations, improving layout on different screen sizes, and ensuring a consistent design language.

### Future Enhancements

*   **Advanced Analytics:** Expand the analytics dashboard with more detailed reading insights, such as reading streaks, average time to finish a book, and comparisons to previous time periods.
*   **Social Features:** Introduce social features like reading challenges with friends, sharing book recommendations, and creating book clubs.
*   **Book Recommendations:** Implement a personalized book recommendation engine based on a user's reading history and preferences.
*   **Export Options:** Allow users to export their library to different formats, such as JSON or PDF.

## Contributing

### Development Guidelines
- **Swift 6 Compliance**: All code must be concurrency-safe
- **Test Coverage**: Maintain >80% test coverage
- **Documentation**: Document all public APIs
- **Accessibility**: Ensure VoiceOver compatibility
- **Performance**: Profile and optimize critical paths

### Code Style
- SwiftUI best practices
- Actor-based concurrency patterns
- Comprehensive error handling
- Clean architecture principles

## License

This project is licensed under the a private license.

## Acknowledgments

- **Apple Developer Documentation**: iOS development best practices
- **SwiftUI Community**: UI patterns and components
- **ISBN APIs**: Book metadata providers
- **Open Source Community**: Various utility libraries

---

**Current Version**: 2.0 (Phase 2 Complete - Live Activities temporarily disabled)
**Last Updated**: August 2024
**Minimum iOS**: 16.0

# Auto-versioning enabled
