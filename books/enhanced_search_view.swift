import SwiftUI
import SwiftData

struct SearchView: View {
    @Environment(\.modelContext) private var modelContext
    
    @State private var searchService = BookSearchService.shared
    @State private var searchText = ""
    @State private var searchState: SearchState = .idle
    
    enum SearchState {
        case idle
        case searching
        case results([BookMetadata])
        case error(String)
    }

    var body: some View {
        NavigationStack {
            VStack {
                // Search Bar
                HStack {
                    TextField("Search by title, author, or ISBN", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit(performSearch)
                    
                    Button(action: performSearch) {
                        Image(systemName: "magnifyingglass")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(searchText.isEmpty)
                }
                .padding()

                // Content Area
                Group {
                    switch searchState {
                    case .idle:
                        ContentUnavailableView("Search for a Book", systemImage: "books.vertical", description: Text("Find your next read by searching the online database."))
                    case .searching:
                        ProgressView("Searching...")
                            .padding()
                    case .results(let books):
                        if books.isEmpty {
                            ContentUnavailableView("No Results Found", systemImage: "questionmark.circle", description: Text("Try checking the spelling or using a different search term."))
                        } else {
                            // The List now handles navigation
                            List(books) { book in
                                NavigationLink(value: book) {
                                    SearchResultRow(book: book)
                                }
                            }
                        }
                    case .error(let message):
                        ContentUnavailableView("Search Error", systemImage: "exclamationmark.triangle", description: Text(message))
                    }
                }
                Spacer()
            }
            .navigationTitle("Search Books")
            // This modifier tells the NavigationStack what to do when a BookMetadata value is tapped
            .navigationDestination(for: BookMetadata.self) { book in
                SearchResultDetailView(bookMetadata: book)
            }
        }
    }

    private func performSearch() {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        searchState = .searching
        Task {
            let result = await searchService.search(query: searchText)
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
}

// MARK: - Search Result Row (Simplified)

struct SearchResultRow: View {
    let book: BookMetadata

    var body: some View {
        HStack {
            BookCoverImage(imageURL: book.imageURL?.absoluteString, width: 50, height: 70)
            
            VStack(alignment: .leading) {
                Text(book.title).font(.headline).lineLimit(2)
                Text(book.authors.joined(separator: ", ")).font(.subheadline).foregroundStyle(.secondary)
                if let year = book.publishedDate {
                    Text(year).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
