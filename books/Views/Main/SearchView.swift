import SwiftUI
import SwiftData

struct SearchView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appTheme) private var currentTheme
    
    @State private var searchService = BookSearchService.shared
    @State private var searchQuery = ""
    @State private var searchState: SearchState = .idle
    @State private var sortOption: BookSearchService.SortOption = .relevance
    @State private var showingSortOptions = false
    @State private var includeTranslations = true
    

    enum SearchState: Equatable {
        case idle
        case searching
        case results([BookMetadata])
        case error(String)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search Controls
            if case .results(let books) = searchState, !books.isEmpty {
                searchControlsBar
            }
            
            // Content Area with enhanced empty state
            Group {
                    switch searchState {
                    case .idle:
                        enhancedEmptyState
                        
                    case .searching:
                        UnifiedLoadingState(config: .init(
                            message: "Searching millions of books",
                            subtitle: "Using smart relevance sorting",
                            style: .spinner
                        ))
                        
                    case .results(let books):
                        if books.isEmpty {
                            noResultsState
                        } else {
                            searchResultsList(books: books)
                        }
                        
                    case .error(let message):
                        UnifiedErrorState(config: .init(
                            title: "Search Error",
                            message: message,
                            retryAction: performSearch,
                            style: .standard
                        ))
                    }
                }
                .background(
                    LinearGradient(
                        colors: [
                            currentTheme.background,
                            currentTheme.surface.opacity(0.5)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .animation(Theme.Animation.accessible, value: searchState)
            }
            .background(currentTheme.background)
            .searchable(text: $searchQuery, prompt: "Search by title, author, or ISBN")
            .searchSuggestions {
                if searchQuery.isEmpty {
                    Text("\"The Great Gatsby\"").searchCompletion("The Great Gatsby")
                    Text("\"Maya Angelou\"").searchCompletion("Maya Angelou")
                    Text("\"9780451524935\"").searchCompletion("9780451524935")
                }
            }
            .accessibilityLabel("Search for books")
            .accessibilityHint("Enter a book title, author name, or ISBN to search for books in the online database")
            .onSubmit(of: .search) {
                performSearch()
            }
            .onChange(of: searchQuery) { oldValue, newValue in
                // Clear results when search query is cleared
                if newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !oldValue.isEmpty {
                    clearSearchResults()
                }
            }
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
                .background(currentTheme.primaryContainer)
                .foregroundColor(currentTheme.onPrimaryContainer)
                .cornerRadius(16)
            }
            .accessibilityLabel("Sort by \(sortOption.displayName)")
            .accessibilityHint("Opens sort options menu")
            
            // Translations toggle
            Button {
                includeTranslations.toggle()
                // Re-search with new setting
                if case .results = searchState {
                    performSearch()
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: includeTranslations ? "globe" : "globe.badge.chevron.backward")
                        .font(.caption)
                    Text(includeTranslations ? "All Languages" : "English Only")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(includeTranslations ? currentTheme.tertiaryContainer : currentTheme.outline.opacity(0.1))
                .foregroundColor(includeTranslations ? currentTheme.tertiary : currentTheme.outline)
                .cornerRadius(16)
            }
            .accessibilityLabel(includeTranslations ? "Including all languages" : "English only")
            .accessibilityHint("Toggle to include or exclude translated works")
            
            Spacer()
            
            // Results count
            if case .results(let books) = searchState {
                Text("\(books.count) results")
                    .font(.caption)
                    .foregroundColor(currentTheme.onSurfaceVariant)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(currentTheme.surface)
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(currentTheme.outline.opacity(0.2)),
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
                    Text("Sort Search Results")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(currentTheme.onSurface)
                    
                    Text("Choose how to order your search results")
                        .font(.subheadline)
                        .foregroundColor(currentTheme.onSurfaceVariant)
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
                                performSearch()
                            }
                        } label: {
                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(currentTheme.primaryContainer)
                                        .frame(width: 40, height: 40)
                                    
                                    Image(systemName: option.systemImage)
                                        .font(.system(size: 18))
                                        .foregroundColor(currentTheme.onPrimaryContainer)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(option.displayName)
                                        .font(.headline)
                                        .foregroundColor(currentTheme.onSurface)
                                    
                                    Text(sortDescription(for: option))
                                        .font(.subheadline)
                                        .foregroundColor(currentTheme.onSurfaceVariant)
                                        .multilineTextAlignment(.leading)
                                }
                                
                                Spacer()
                                
                                if sortOption == option {
                                    Image(systemName: "checkmark")
                                        .font(.headline)
                                        .foregroundColor(currentTheme.primary)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(
                                sortOption == option ? 
                                    currentTheme.primaryContainer.opacity(0.3) : 
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
            .background(currentTheme.surface)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingSortOptions = false
                    }
                    .foregroundColor(currentTheme.primary)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
    
    private func sortDescription(for option: BookSearchService.SortOption) -> String {
        switch option {
        case .relevance:
            return "Best matches for your search terms"
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
            .listRowBackground(currentTheme.cardBackground)
            .listRowSeparator(.hidden)
            .padding(.vertical, Theme.Spacing.xs)
        }
        .listStyle(.plain)
        .background(currentTheme.surface)
        .scrollContentBackground(.hidden)
        .accessibilityLabel("\(books.count) search results sorted by \(sortOption.displayName)")
    }

    // MARK: - Enhanced Empty State for App Store Appeal
    @ViewBuilder
    private var enhancedEmptyState: some View {
        UnifiedHeroSection(config: .init(
            icon: "magnifyingglass.circle.fill",
            title: "Discover Your Next Great Read",
            subtitle: "Search millions of books with smart sorting and find exactly what you're looking for",
            style: .discovery,
            actions: [
                .init(
                    title: "Smart Relevance",
                    icon: "target",
                    description: "Find the most relevant results for your search"
                ) {},
                .init(
                    title: "Sort by Popularity",
                    icon: "star.fill",
                    description: "Discover trending and highly-rated books"
                ) {},
                .init(
                    title: "All Languages",
                    icon: "globe",
                    description: "Include translated works from around the world"
                ) {}
            ]
        ))
        .accessibilityLabel("Search for books")
        .accessibilityHint("Use the search field above to find books by title, author, or ISBN")
    }
    
    
    // MARK: - Enhanced No Results State
    @ViewBuilder
    private var noResultsState: some View {
        UnifiedHeroSection(config: .init(
            icon: "questionmark.circle.fill",
            title: "No Results Found",
            subtitle: "Try different search terms or check your spelling. You can also try including translated works.",
            style: .error,
            actions: [
                .init(
                    title: "Book titles",
                    icon: "book.fill",
                    description: "Try \"The Great Gatsby\""
                ) {
                    searchQuery = "The Great Gatsby"
                    performSearch()
                },
                .init(
                    title: "Author names",
                    icon: "person.fill",
                    description: "Try \"Maya Angelou\""
                ) {
                    searchQuery = "Maya Angelou"
                    performSearch()
                },
                .init(
                    title: "ISBN numbers",
                    icon: "barcode",
                    description: "Try \"9780451524935\""
                ) {
                    searchQuery = "9780451524935"
                    performSearch()
                }
            ]
        ))
        .accessibilityLabel("No search results found")
        .accessibilityHint("Try different search terms or check spelling")
    }
    
    
    // MARK: - Actions
    
    private func performSearch() {
        let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return }
        
        searchState = .searching
        
        // Add haptic feedback - respect VoiceOver and Reduce Motion
        HapticFeedbackManager.shared.lightImpact()
        
        Task {
            let result = await searchService.search(
                query: trimmedQuery,
                sortBy: sortOption,
                includeTranslations: includeTranslations
            )
            await MainActor.run {
                switch result {
                case .success(let books):
                    searchState = .results(books)
                    HapticFeedbackManager.shared.success()
                case .failure(let error):
                    searchState = .error(formatError(error))
                    HapticFeedbackManager.shared.error()
                }
            }
        }
    }
    
    private func clearSearch() {
        searchQuery = ""
        searchState = .idle
        sortOption = .relevance
        includeTranslations = true
        HapticFeedbackManager.shared.lightImpact()
    }
    
    private func clearSearchResults() {
        // Clear search results and return to discovery state
        searchState = .idle
        HapticFeedbackManager.shared.lightImpact()
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
    @Environment(\.appTheme) private var currentTheme
    let book: BookMetadata
    @State private var isImageLoading = true

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            ZStack {
                BookCoverImage(
                    imageURL: book.imageURL?.absoluteString, 
                    width: 50, 
                    height: 70
                )
                
                // Loading shimmer effect for book cover
                if isImageLoading {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(currentTheme.outline.opacity(0.3))
                        .frame(width: 50, height: 70)
                        .shimmer()
                }
            }
            .onAppear {
                // Simulate image loading completion
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    let animation = UIAccessibility.isReduceMotionEnabled ? 
                        Animation.linear(duration: 0.1) : Animation.easeOut(duration: 0.3)
                    withAnimation(animation) {
                        isImageLoading = false
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(book.title)
                    .titleMedium()
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text(book.authors.joined(separator: ", "))
                    .bodyMedium()
                    .foregroundStyle(currentTheme.secondaryText)
                    .lineLimit(1)
                
                HStack(spacing: Theme.Spacing.md) {
                    if let publishedYear = extractYear(from: book.publishedDate) {
                        Label(publishedYear, systemImage: "calendar")
                            .labelSmall()
                            .foregroundStyle(currentTheme.secondaryText)
                    }
                    
                    if let pageCount = book.pageCount {
                        Label("\(pageCount) pages", systemImage: "doc.text")
                            .labelSmall()
                            .foregroundStyle(currentTheme.secondaryText)
                    }
                    
                    // Quality indicators
                    if book.imageURL != nil {
                        Image(systemName: "photo")
                            .font(.caption2)
                            .foregroundStyle(currentTheme.tertiary)
                    }
                    
                    if book.bookDescription != nil && !book.bookDescription!.isEmpty {
                        Image(systemName: "text.alignleft")
                            .font(.caption2)
                            .foregroundStyle(currentTheme.tertiary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, Theme.Spacing.xs)
        .frame(minHeight: 44)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(book.title) by \(book.authors.joined(separator: ", "))")
        .accessibilityHint("Double tap to view book details")
        .accessibilityIdentifier("SearchResultRow_\(book.googleBooksID)")
    }
    
    // Helper function to extract year from various date formats
    private func extractYear(from dateString: String?) -> String? {
        guard let dateString = dateString, !dateString.isEmpty else { return nil }
        
        // If it's already just a year (4 digits), return as-is
        if dateString.count == 4, Int(dateString) != nil {
            return dateString
        }
        
        // Extract first 4 characters as year from formats like "2011-10-18"
        if dateString.count >= 4 {
            let yearSubstring = String(dateString.prefix(4))
            if Int(yearSubstring) != nil {
                return yearSubstring
            }
        }
        
        // Fallback: return the original string if we can't parse it
        return dateString
    }
}

// MARK: - Shimmer Effect Extension
extension View {
    func shimmer() -> some View {
        self.modifier(ShimmerModifier())
    }
}

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.clear, Color.white.opacity(0.3), Color.clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .rotationEffect(.degrees(30))
                    .offset(x: phase)
                    .clipped()
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 200
                }
            }
    }
}

#Preview {
    SearchView()
        .modelContainer(for: [UserBook.self, BookMetadata.self], inMemory: true)
        .preferredColorScheme(.dark)
}