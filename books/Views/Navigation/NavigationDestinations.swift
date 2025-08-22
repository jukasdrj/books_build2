import SwiftUI

/// A centralized view modifier that provides all navigation destinations for the app
/// This eliminates the need to duplicate navigation destinations across multiple NavigationStacks
struct NavigationDestinations: ViewModifier {
    func body(content: Content) -> some View {
        content
            .navigationDestination(for: UserBook.self) { book in
                BookDetailsView(book: book)
            }
            .navigationDestination(for: BookMetadata.self) { bookMetadata in
                SearchResultDetailView(
                    bookMetadata: bookMetadata,
                    fromBarcodeScanner: false
                )
            }
            .navigationDestination(for: String.self) { destination in
                destinationView(for: destination)
            }
            .navigationDestination(for: AuthorSearchRequest.self) { authorRequest in
                AuthorSearchResultsView(authorName: authorRequest.authorName)
            }
    }
    
    /// Provides the appropriate view for string-based navigation destinations
    @ViewBuilder
    private func destinationView(for destination: String) -> some View {
        switch destination {
        case "Library":
            LibraryView()
        case "Search":
            SearchView()
        case "Stats":
            StatsView()
        case "Culture":
            CulturalDiversityView()
        case "library-incomplete-books":
            IncompleteBookListView()
        default:
            // Handle author names or other string destinations
            if destination.starts(with: "author:") {
                let authorName = String(destination.dropFirst(7)) // Remove "author:" prefix
                AuthorSearchResultsView(authorName: authorName)
            } else {
                LibraryView()
            }
        }
    }
}

extension View {
    /// Applies all standard navigation destinations to a NavigationStack
    /// Usage: NavigationStack { ... }.withNavigationDestinations()
    func withNavigationDestinations() -> some View {
        modifier(NavigationDestinations())
    }
}
