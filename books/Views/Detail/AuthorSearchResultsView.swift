import SwiftUI

struct AuthorSearchResultsView: View {
    let authorName: String
    
    @State private var searchState: SearchState = .searching
    @State private var searchService = BookSearchService.shared
    @State private var sortOption: BookSearchService.SortOption = .relevance
    @State private var showingSortOptions = false
    
    enum SearchState: Equatable {
        case searching
        case results([BookMetadata])
        case error(String)
        
        static func == (lhs: SearchState, rhs: SearchState) -> Bool {
            switch (lhs, rhs) {
            case (.searching, .searching):
                return true
            case (.results(let lhsBooks), .results(let rhsBooks)):
                return lhsBooks.map(\.googleBooksID) == rhsBooks.map(\.googleBooksID)
            case (.error(let lhsMessage), .error(let rhsMessage)):
                return lhsMessage == rhsMessage
            default:
                return false
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Controls (similar to SearchView)
            if case .results(let books) = searchState, !books.isEmpty {
                searchControlsBar
            }
            
            // Content Area
            Group {
                switch searchState {
                case .searching:
                    EnhancedLoadingView(message: "Searching books by \(authorName)")
                        .task(id: authorName) {
                            await performAuthorSearch()
                        }
                        
                case .results(let items):
                    if items.isEmpty {
                        authorNotFoundState
                    } else {
                        searchResultsList(books: items)
                    }
                    
                case .error(let message):
                    EnhancedErrorView(
                        title: "Search Error",
                        message: message,
                        retryAction: {
                            Task {
                                await performAuthorSearch()
                            }
                        }
                    )
                }
            }
            .background(
                LinearGradient(
                    colors: [
                        Color.theme.background,
                        Color.theme.surface.opacity(0.5)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .animation(Theme.Animation.accessible, value: searchState)
        }
        .navigationTitle("Books by \(authorName)")
        .navigationBarTitleDisplayMode(.large)
        .background(Color.theme.background)
        .sheet(isPresented: $showingSortOptions) {
            sortOptionsSheet
        }
    }
    
    // MARK: - Search Controls Bar
    @ViewBuilder
    private var searchControlsBar: some View {
        HStack(spacing: 12) {
            // Sort button
            Button {
                showingSortOptions = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: sortOption.systemImage)
                        .font(.caption)
                    Text(sortOption.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.theme.primaryContainer)
                .foregroundColor(Color.theme.onPrimaryContainer)
                .cornerRadius(16)
            }
            .accessibilityLabel("Sort by \(sortOption.displayName)")
            .accessibilityHint("Opens sort options menu")
            
            Spacer()
            
            // Results count
            if case .results(let books) = searchState {
                Text("\(books.count) books")
                    .font(.caption)
                    .foregroundColor(Color.theme.onSurfaceVariant)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.theme.surface)
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color.theme.outline.opacity(0.2)),
            alignment: .bottom
        )
    }
    
    // MARK: - Sort Options Sheet
    @ViewBuilder
    private var sortOptionsSheet: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text("Sort \(authorName)'s Books")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.theme.onSurface)
                    
                    Text("Choose how to order the search results")
                        .font(.subheadline)
                        .foregroundColor(Color.theme.onSurfaceVariant)
                }
                .padding(.top, 20)
                .padding(.horizontal, 20)
                
                // Sort options
                LazyVStack(spacing: 0) {
                    ForEach(BookSearchService.SortOption.allCases) { option in
                        Button {
                            sortOption = option
                            showingSortOptions = false
                            HapticFeedbackManager.shared.mediumImpact()
                            
                            // Re-search with new sort option
                            if case .results = searchState {
                                Task {
                                    await performAuthorSearch()
                                }
                            }
                        } label: {
                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(Color.theme.primaryContainer)
                                        .frame(width: 40, height: 40)
                                    
                                    Image(systemName: option.systemImage)
                                        .font(.system(size: 18))
                                        .foregroundColor(Color.theme.onPrimaryContainer)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(option.displayName)
                                        .font(.headline)
                                        .foregroundColor(Color.theme.onSurface)
                                    
                                    Text(sortDescription(for: option))
                                        .font(.subheadline)
                                        .foregroundColor(Color.theme.onSurfaceVariant)
                                        .multilineTextAlignment(.leading)
                                }
                                
                                Spacer()
                                
                                if sortOption == option {
                                    Image(systemName: "checkmark")
                                        .font(.headline)
                                        .foregroundColor(Color.theme.primary)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(
                                sortOption == option ? 
                                    Color.theme.primaryContainer.opacity(0.3) : 
                                    Color.clear
                            )
                        }
                        .buttonStyle(.plain)
                        
                        if option != BookSearchService.SortOption.allCases.last {
                            Divider()
                                .padding(.leading, 76)
                        }
                    }
                }
                .padding(.top, 20)
                
                Spacer()
            }
            .background(Color.theme.surface)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingSortOptions = false
                    }
                    .foregroundColor(Color.theme.primary)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
    
    private func sortDescription(for option: BookSearchService.SortOption) -> String {
        switch option {
        case .relevance:
            return "Best matches for this author"
        case .newest:
            return "Most recently published books first"
        case .popularity:
            return "Popular and well-known books first"
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
        .accessibilityLabel("\(books.count) books by \(authorName) sorted by \(sortOption.displayName)")
    }
    
    // MARK: - Author Not Found State
    @ViewBuilder
    private var authorNotFoundState: some View {
        VStack(spacing: Theme.Spacing.xl) {
            VStack(spacing: Theme.Spacing.lg) {
                ZStack {
                    Circle()
                        .fill(Color.theme.outline.opacity(0.1))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 40, weight: .light))
                        .foregroundColor(Color.theme.outline)
                }
                
                VStack(spacing: Theme.Spacing.md) {
                    Text("No Books Found")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.theme.primaryText)
                    
                    Text("We couldn't find any books by \"\(authorName)\" in our database.")
                        .font(.body)
                        .foregroundColor(Color.theme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Theme.Spacing.md)
                }
            }
            .accessibilityLabel("No books found by \(authorName)")
            .accessibilityHint("Try checking the spelling or search for a different author")
            
            // Suggestion
            VStack(spacing: 8) {
                Text("Try:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color.theme.primaryText)
                
                Text("• Check the author's name spelling")
                    .font(.caption)
                    .foregroundColor(Color.theme.secondaryText)
                
                Text("• Search for individual names if it's a multi-author work")
                    .font(.caption)
                    .foregroundColor(Color.theme.secondaryText)
            }
            .padding(.horizontal, Theme.Spacing.lg)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, Theme.Spacing.xl)
    }
    
    // MARK: - Search Function
    private func performAuthorSearch() async {
        searchState = .searching
        
        // Use the enhanced search functionality with author-specific optimization
        let result = await searchService.search(
            query: authorName, // Let the service handle the inauthor: optimization
            sortBy: sortOption,
            maxResults: 40,
            includeTranslations: true
        )
        
        await MainActor.run {
            switch result {
            case .success(let books):
                // Filter results to ensure they actually match the author
                let filteredBooks = books.filter { book in
                    book.authors.contains { author in
                        author.localizedCaseInsensitiveContains(authorName) ||
                        authorName.localizedCaseInsensitiveContains(author)
                    }
                }
                searchState = .results(filteredBooks)
                HapticFeedbackManager.shared.success()
                
            case .failure(let error):
                searchState = .error(formatError(error))
                HapticFeedbackManager.shared.error()
            }
        }
    }
    
    private func formatError(_ error: Error) -> String {
        if error.localizedDescription.contains("network") || error.localizedDescription.contains("internet") {
            return "Please check your internet connection and try again."
        } else if error.localizedDescription.contains("timeout") {
            return "The search took too long. Please try again."
        } else {
            return "Something went wrong searching for \(authorName)'s books. Please try again later."
        }
    }
}