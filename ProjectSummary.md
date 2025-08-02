# 📚 Books Reading Tracker - Project Summary

This summary provides a high-level overview of the project for efficient context loading. For full details, refer to `Documentation.md` and `FileDirectory.md`.

---

## 核心理念

-   **Purpose**: A SwiftUI reading tracker for iOS with a strong focus on tracking cultural diversity in reading.
-   **Target User**: The developer's wife, an avid reader who wants to track reading history, stats, and works from diverse cultures.
-   **Design Philosophy**: Material Design 3 with a vibrant, intuitive, and adaptive UI supporting dark mode.

---

## 🏗️ Architecture & Tech Stack

-   **UI**: SwiftUI
-   **Data**: SwiftData with `UserBook` and `BookMetadata` models.
-   **Navigation**: 4-tab `TabView` in `ContentView.swift` (Library, Wishlist, Search, Stats).
-   **API Integration**: `BookSearchService.swift` handles Google Books API calls.
-   **Theming**: A centralized theme system in `Theme.swift` and `Color+Extensions.swift` provides Material Design 3 colors, typography, and spacing (`Theme.Color.*`, `Theme.Typography.*`).
-   **Asynchronous Operations**: Uses `async/await` for network requests and image loading.
-   **Caching**: `ImageCache.swift` provides an in-memory cache for book cover images.

---

## 🔑 Key Files & Directories

### Root Documentation
-   `Documentation.md`: Comprehensive project details.
-   `FileDirectory.md`: Detailed descriptions of every file.
-   `Roadmap.md`: Future feature planning.
-   `Accomplished.md`: Log of completed work.
-   `ProjectSummary.md`: **This file.** High-level summary for quick context.

### Core Application (`/books`)
-   `booksApp.swift`: App entry point, configures SwiftData `ModelContainer`.
-   `ContentView.swift`: Sets up the main 4-tab navigation structure.

### Models (`/books/Models/`)
-   `BookMetadata.swift`: Stores book info from Google Books API + extensive cultural data. (One-to-many with UserBook).
-   `UserBook.swift`: Stores user-specific data like reading status, progress, ratings, and notes. (Many-to-one with BookMetadata).

### Main Views
-   `LibraryView.swift`: Displays the user's book collection with grid/list layouts and filtering.
-   `WishlistView.swift`: Manages books the user wants to read.
-   `SearchView.swift`: Interface for searching the Google Books API.
-   `StatsView.swift`: Visualizes reading analytics, including cultural diversity metrics.
-   `BookDetailsView.swift`: Shows all details for a specific book in the user's library.

### Key Components
-   `BookCardView.swift`: Reusable card UI for displaying a book in a grid.
-   `BookRowView.swift`: Reusable row UI for displaying a book in a list.
-   `BookCoverImage.swift`: Handles loading and caching of book cover images, with shimmer effects.
-   `shared_components.swift`: A collection of smaller, app-wide reusable UI components.

---

## 💡 Key Development Patterns

-   **Theming**: Access theme properties via static `Theme` properties (e.g., `Theme.Color.PrimaryAction`, `Theme.Typography.bodyLarge`).
-   **Color System**: Use `Color.theme.*` for adaptive dark/light mode colors defined programmatically in `Color+Extensions.swift`.
-   **Array Storage in SwiftData**: Arrays of strings (like authors, genres) are stored as a single `String` separated by `|||` and accessed via a computed property.
-   **Loading States**: Use the `ShimmerModifier` and `EnhancedLoadingView` for professional, animated loading states.
-   **User Feedback**: Provide haptic feedback and use the `SuccessToast` view for non-intrusive success messages.
-   **File Organization**: Core views are kept in the main `books/` directory, with specialized components in subfolders like `/Charts` and `/Models`.