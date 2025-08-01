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
            VStack(spacing: 0) {
                // Search Bar
                searchBar
                    .padding()
                    .background(Color.theme.surface)
                
                Divider()
                
                // Content Area
                Group {
                    switch searchState {
                    case .idle:
                        ContentUnavailableView(
                            "Search for a Book", 
                            systemImage: "books.vertical", 
                            description: Text("Find your next read by searching the online database.")
                        )
                        .foregroundColor(Color.theme.primaryText)
                        
                    case .searching:
                        VStack(spacing: Theme.Spacing.md) {
                            ProgressView()
                                .scaleEffect(1.2)
                                .tint(Color.theme.primaryAction)
                            Text("Searching...")
                                .bodyMedium()
                                .foregroundColor(Color.theme.secondaryText)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        
                    case .results(let books):
                        if books.isEmpty {
                            ContentUnavailableView(
                                "No Results Found", 
                                systemImage: "questionmark.circle", 
                                description: Text("Try checking the spelling or using a different search term.")
                            )
                            .foregroundColor(Color.theme.primaryText)
                        } else {
                            searchResultsList(books: books)
                        }
                        
                    case .error(let message):
                        ContentUnavailableView(
                            "Search Error", 
                            systemImage: "exclamationmark.triangle", 
                            description: Text(message)
                        )
                        .foregroundColor(Color.theme.error)
                    }
                }
                .background(Color.theme.surface)
                .animation(Theme.Animation.standardEaseInOut, value: searchState)
            }
            .navigationTitle("Search Books")
            .navigationBarTitleDisplayMode(.large)
            .background(Color.theme.background)
            .navigationDestination(for: BookMetadata.self) { book in
                SearchResultDetailView(bookMetadata: book)
            }
        }
    }
    
    // MARK: - Search Bar Component
    @ViewBuilder
    private var searchBar: some View {
        HStack(spacing: Theme.Spacing.sm) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Color.theme.secondaryText)
                    .font(.system(size: 16))
                
                TextField("Search by title, author, or ISBN", text: $searchText)
                    .bodyMedium()
                    .onSubmit(performSearch)
                    .submitLabel(.search)
                
                if !searchText.isEmpty {
                    Button(action: clearSearch) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color.theme.secondaryText)
                            .font(.system(size: 16))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background(Color.theme.surfaceVariant)
            .cornerRadius(Theme.CornerRadius.medium)
            
            Button(action: performSearch) {
                Text("Search")
                    .labelMedium()
            }
            .materialButton(style: .filled, size: .medium)
            .disabled(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }
    
    // MARK: - Search Results List
    @ViewBuilder
    private func searchResultsList(books: [BookMetadata]) -> some View {
        List(books) { book in
            NavigationLink(value: book) {
                SearchResultRow(book: book)
            }
            .listRowBackground(Color.theme.cardBackground)
            .listRowSeparator(.hidden)
            .padding(.vertical, Theme.Spacing.xs)
        }
        .listStyle(.plain)
        .background(Color.theme.surface)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Actions
    private func performSearch() {
        let trimmedQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return }
        
        searchState = .searching
        Task {
            let result = await searchService.search(query: trimmedQuery)
            await MainActor.run {
                switch result {
                case .success(let books):
                    searchState = .results(books)
                case .failure(let error):
                    searchState = .error(formatError(error))
                }
            }
        }
    }
    
    private func clearSearch() {
        searchText = ""
        searchState = .idle
    }
    
    private func formatError(_ error: Error) -> String {
        // Provide user-friendly error messages
        if error.localizedDescription.contains("network") || error.localizedDescription.contains("internet") {
            return "Please check your internet connection and try again."
        } else if error.localizedDescription.contains("timeout") {
            return "The search took too long. Please try again."
        } else {
            return "Something went wrong. Please try again later."
        }
    }
}

// MARK: - Search Result Row (Enhanced)
struct SearchResultRow: View {
    let book: BookMetadata

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            BookCoverImage(
                imageURL: book.imageURL?.absoluteString, 
                width: 50, 
                height: 70
            )
            
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(book.title)
                    .titleMedium()
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text(book.authors.joined(separator: ", "))
                    .bodyMedium()
                    .foregroundStyle(Color.theme.secondaryText)
                    .lineLimit(1)
                
                HStack(spacing: Theme.Spacing.md) {
                    if let year = book.publishedDate {
                        Label(year, systemImage: "calendar")
                            .labelSmall()
                            .foregroundStyle(Color.theme.secondaryText)
                    }
                    
                    if let pageCount = book.pageCount {
                        Label("\(pageCount) pages", systemImage: "doc.text")
                            .labelSmall()
                            .foregroundStyle(Color.theme.secondaryText)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(Color.theme.tertiaryLabel)
        }
        .padding(.vertical, Theme.Spacing.xs)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(book.title) by \(book.authors.joined(separator: ", "))")
        .accessibilityHint("Double tap to view book details")
    }
}

#Preview {
    SearchView()
        .modelContainer(for: [UserBook.self, BookMetadata.self], inMemory: true)
        .preferredColorScheme(.dark)
}