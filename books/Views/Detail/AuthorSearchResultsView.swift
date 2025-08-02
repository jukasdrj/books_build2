import SwiftUI

struct AuthorSearchResultsView: View {
    let authorName: String
    
    @State private var searchState: SearchState = .searching
    @State private var searchService = BookSearchService.shared
    
    enum SearchState {
        case searching
        case results([BookMetadata])
        case error(String)
    }
    
    var body: some View {
        VStack {
            switch searchState {
            case .searching:
                ProgressView("Searching books by \(authorName)...")
                    .task(id: authorName) {
                        // Ensure task runs only for the correct authorName
                        await performAuthorSearch()
                    }
            case .results(let items):
                if items.isEmpty {
                    ContentUnavailableView("No Books Found",
                                           systemImage: "questionmark.circle",
                                           description: Text("No results for \"\(authorName)\"."))
                } else {
                    List(items) { book in
                        NavigationLink(value: book) {
                            SearchResultRow(book: book)
                        }
                    }
                }
            case .error(let message):
                ContentUnavailableView("Search Error",
                                       systemImage: "exclamationmark.triangle",
                                       description: Text(message))
            }
        }
        .navigationTitle(authorName)
        .navigationDestination(for: BookMetadata.self) { book in
            SearchResultDetailView(bookMetadata: book)
        }
    }
    
    private func performAuthorSearch() async {
        let query = "inauthor:\(authorName)"
        let result = await searchService.search(query: query)
        await MainActor.run {
            switch result {
            case .success(let books):
                searchState = .results(books)
            case .failure(let error):
                searchState = .error(error.localizedDescription)
            }
        }
    }
}