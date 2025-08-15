# GEMINI.md - Project Context

## Project Overview

This project is a sophisticated SwiftUI application for iOS called "Books Reading Tracker". It allows users to track their personal book library, set reading goals, and monitor reading habits. The application is written in Swift and utilizes modern iOS technologies like SwiftUI, SwiftData, and ActivityKit for Live Activities.

The architecture is well-documented and follows modern best practices, including a clean, modular design, a robust background processing system for CSV imports, and a focus on performance and resilience. The project is designed to be Swift 6 compliant, with a strong emphasis on concurrency safety using an actor-based model.

### Key Features:

*   **Personal Library Management:** Track books with detailed metadata, ratings, and reading status.
*   **Advanced CSV Import:** A robust system for importing large book libraries from CSV files (e.g., Goodreads exports) with background processing, state persistence, and smart data validation.
*   **Live Activities:** Real-time import progress tracking in the Dynamic Island and on the Lock Screen.
*   **Visual Analytics:** Charts and visualizations for reading patterns and genre breakdowns.
*   **Cultural Diversity Tracking:** Monitor the diversity of authors read.
*   **Accessibility:** Full VoiceOver support.

## Building and Running

The project is a standard Xcode project.

### Prerequisites:

*   **Xcode:** Version 15.0+
*   **macOS:** macOS 13.0+ (Ventura) or later
*   **Apple Developer Account:** Required for device testing and distribution.

### Setup and Build:

1.  **Open the project in Xcode:**
    ```bash
    open books.xcodeproj
    ```
2.  **Configure Signing:** In the project settings for the `books` and `BooksWidgets` targets, select your development team under the "Signing & Capabilities" tab.
3.  **Google Books API Key:** The project uses a `Config.xcconfig` file to manage the Google Books API key. Create a `Config.xcconfig` file in the project root with the following content:
    ```
    GOOGLE_BOOKS_API_KEY = YOUR_API_KEY_HERE
    GOOGLE_BOOKS_API_KEY_FALLBACK =
    ```
4.  **Select a scheme:**
    *   **books:** The main application.
    *   **BooksWidgets:** The widget extension for Live Activities.
5.  **Build and Run:** Press `Cmd+R` to build and run the selected scheme on a simulator or a connected device.

## Development Conventions

*   **Swift 6 Compliant:** The codebase is designed to be fully concurrency-safe using Swift's actor-based concurrency model.
*   **Testing:** The project has a comprehensive testing architecture, including unit, integration, and UI tests. The goal is to maintain high test coverage, especially for critical paths like the import workflow.
*   **Architecture:** The project follows a clean, layered architecture with a clear separation of concerns between the UI, coordination, service, and infrastructure layers. Detailed architecture documents (`ARCHITECTURE.md`, `BACKGROUND_IMPORT_ARCHITECTURE.md`) are available in the project root.
*   **Code Style:** The project follows SwiftUI best practices and emphasizes clean, readable, and well-documented code.
*   **Error Handling:** Comprehensive error handling is expected for all operations, especially asynchronous ones.
*   **State Management:** The app uses a combination of `@Observable` for local view state and a more robust `ImportStateManager` for persisting the state of background import processes.
