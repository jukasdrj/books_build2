import SwiftUI
import SwiftData

struct SearchView: View {
    @Environment(\.modelContext) private var modelContext
    
    @State private var searchService = BookSearchService.shared
    @State private var searchQuery = ""
    @State private var searchState: SearchState = .idle
    @State private var sortOption: BookSearchService.SortOption = .relevance
    @State private var showingSortOptions = false
    @State private var includeTranslations = true
    
    @State private var showingBarcodeScanner = false
    @State private var barcodeSearchResult: BookMetadata?
    @State private var showingBarcodeSearchResult = false
    @State private var navigationPath = NavigationPath()

    enum SearchState: Equatable {
        case idle
        case searching
        case results([BookMetadata])
        case error(String)
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                // ScreenshotMode visual banner (purple gradient, visible only in ScreenshotMode)
                if ScreenshotMode.isEnabled {
                    ZStack {
                        LinearGradient(
                            colors: [Color.purple.opacity(0.85), Color.purple.opacity(0.65)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        HStack {
                            Image(systemName: "camera.aperture")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("Screenshot Mode")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 32)
                    .cornerRadius(0)
                    .shadow(color: Color.purple.opacity(0.15), radius: 7, x: 0, y: 4)
                }

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
                        EnhancedLoadingView(message: "Searching millions of books")
                        
                    case .results(let books):
                        if books.isEmpty {
                            noResultsState
                        } else {
                            searchResultsList(books: books)
                        }
                        
                    case .error(let message):
                        EnhancedErrorView(
                            title: "Search Error",
                            message: message,
                            retryAction: performSearch
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
            .navigationTitle("Search Books")
            .navigationBarTitleDisplayMode(.large)
            .background(Color.theme.background)
            .searchable(text: $searchQuery, prompt: "Search by title, author, or ISBN")
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 8) {
                        if !searchQuery.isEmpty {
                            Button("Clear") {
                                clearSearch()
                            }
                            .accessibilityLabel("Clear search")
                            .accessibilityHint("Clear the search field and results")
                            .foregroundColor(Color.theme.primaryAction)
                        }
                        
                        Button {
                            showingBarcodeScanner = true
                        } label: {
                            Label("Scan Barcode", systemImage: "barcode.viewfinder")
                        }
                        .accessibilityLabel("Scan book barcode")
                        .accessibilityHint("Opens the camera to scan a book's ISBN barcode")
                        .foregroundColor(Color.theme.primaryAction)
                    }
                }
            }
            .sheet(isPresented: $showingSortOptions) {
                sortOptionsSheet
            }
            .sheet(isPresented: $showingBarcodeScanner) {
                BarcodeScannerView { scannedBarcode in
                    handleBarcodeScanned(scannedBarcode)
                }
            }
            .navigationDestination(for: BookMetadata.self) { bookMetadata in
                SearchResultDetailView(
                    bookMetadata: bookMetadata, 
                    fromBarcodeScanner: true
                ) {
                    // onReturnToBarcode callback - goes back to scanner
                    showingBarcodeScanner = true
                }
            }
            // .navigationDestination(isPresented: $showingBarcodeSearchResult) {
            //     if let bookMetadata = barcodeSearchResult {
            //         SearchResultDetailView(bookMetadata: bookMetadata, fromBarcodeScanner: true) {
            //             showingBarcodeSearchResult = false
            //             showingBarcodeScanner = true
            //         }
            //     }
            // }
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
                .background(includeTranslations ? Color.theme.tertiaryContainer : Color.theme.outline.opacity(0.1))
                .foregroundColor(includeTranslations ? Color.theme.tertiary : Color.theme.outline)
                .cornerRadius(16)
            }
            .accessibilityLabel(includeTranslations ? "Including all languages" : "English only")
            .accessibilityHint("Toggle to include or exclude translated works")
            
            Spacer()
            
            // Results count
            if case .results(let books) = searchState {
                Text("\(books.count) results")
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
                    Text("Sort Search Results")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.theme.onSurface)
                    
                    Text("Choose how to order your search results")
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
                                performSearch()
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
            .listRowBackground(Color.theme.cardBackground)
            .listRowSeparator(.hidden)
            .padding(.vertical, Theme.Spacing.xs)
        }
        .listStyle(.plain)
        .background(Color.theme.surface)
        .scrollContentBackground(.hidden)
        .accessibilityLabel("\(books.count) search results sorted by \(sortOption.displayName)")
    }

    // MARK: - Enhanced Empty State for App Store Appeal
    @ViewBuilder
    private var enhancedEmptyState: some View {
        VStack(spacing: Theme.Spacing.xl) {
            // Beautiful hero section
            VStack(spacing: Theme.Spacing.lg) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.theme.primary.opacity(0.2),
                                    Color.theme.secondary.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "magnifyingglass.circle.fill")
                        .font(.system(size: 48, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.theme.primary, Color.theme.secondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .shadow(color: Color.theme.primary.opacity(0.15), radius: 20, x: 0, y: 10)
                
                VStack(spacing: Theme.Spacing.md) {
                    Text("Discover Your Next Great Read")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(Color.theme.primaryText)
                        .multilineTextAlignment(.center)
                    
                    Text("Search millions of books with smart sorting and find exactly what you're looking for")
                        .font(.body)
                        .foregroundColor(Color.theme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Theme.Spacing.md)
                }
            }
            .accessibilityLabel("Search for books")
            .accessibilityHint("Use the search field above to find books by title, author, or ISBN")
            
            // Search features highlight
            VStack(spacing: 12) {
                searchFeatureRow(
                    icon: "target",
                    title: "Smart Relevance",
                    description: "Find the most relevant results for your search"
                )
                
                searchFeatureRow(
                    icon: "star.fill",
                    title: "Sort by Popularity",
                    description: "Discover trending and highly-rated books"
                )
                
                searchFeatureRow(
                    icon: "globe",
                    title: "All Languages",
                    description: "Include translated works from around the world"
                )
            }
            .padding(.horizontal, Theme.Spacing.lg)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, Theme.Spacing.xl)
    }
    
    @ViewBuilder
    private func searchFeatureRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color.theme.primary)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color.theme.primaryText)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(Color.theme.secondaryText)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.theme.surfaceVariant.opacity(0.3))
        .cornerRadius(12)
    }
    
    // MARK: - Enhanced No Results State
    @ViewBuilder
    private var noResultsState: some View {
        VStack(spacing: Theme.Spacing.xl) {
            VStack(spacing: Theme.Spacing.lg) {
                ZStack {
                    Circle()
                        .fill(Color.theme.outline.opacity(0.1))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 40, weight: .light))
                        .foregroundColor(Color.theme.outline)
                }
                
                VStack(spacing: Theme.Spacing.md) {
                    Text("No Results Found")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.theme.primaryText)
                    
                    Text("Try different search terms or check your spelling. You can also try including translated works.")
                        .font(.body)
                        .foregroundColor(Color.theme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Theme.Spacing.md)
                }
            }
            .accessibilityLabel("No search results found")
            .accessibilityHint("Try different search terms or check spelling")
            
            // Search suggestions
            VStack(spacing: 8) {
                Text("Try searching for:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color.theme.primaryText)
                
                LazyVStack(spacing: 6) {
                    suggestionButton("Book titles: \"The Great Gatsby\"")
                    suggestionButton("Author names: \"Maya Angelou\"")
                    suggestionButton("ISBN numbers: \"9780451524935\"")
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, Theme.Spacing.xl)
    }
    
    @ViewBuilder
    private func suggestionButton(_ text: String) -> some View {
        Button {
            let suggestion = text.components(separatedBy: ": \"").last?.replacingOccurrences(of: "\"", with: "") ?? ""
            searchQuery = suggestion
            performSearch()
        } label: {
            Text(text)
                .font(.caption)
                .foregroundColor(Color.theme.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.theme.primaryContainer.opacity(0.3))
                .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Actions
    private func handleBarcodeScanned(_ scannedBarcode: String) {
        showingBarcodeScanner = false
        
        HapticFeedbackManager.shared.lightImpact()
        
        Task {
            let result = await searchService.search(
                query: scannedBarcode,
                sortBy: sortOption,
                includeTranslations: includeTranslations
            )
            await MainActor.run {
                switch result {
                case .success(let books):
                    if let firstBook = books.first {
                        navigationPath.append(firstBook)
                        HapticFeedbackManager.shared.success()
                    } else {
                        // FALLBACK: If no books found, show traditional search
                        searchQuery = scannedBarcode
                        performSearch()
                    }
                case .failure(let error):
                    // FALLBACK: If search fails, show traditional search
                    searchQuery = scannedBarcode
                    searchState = .error(formatError(error))
                    HapticFeedbackManager.shared.error()
                }
            }
        }
    }
    
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
        navigationPath.removeLast(navigationPath.count)
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

// MARK: - Enhanced Loading View
struct EnhancedLoadingView: View {
    let message: String
    @State private var isAnimating = false
    @State private var dotCount = 0
    
    private let timer = Timer.publish(every: 0.6, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.theme.outline.opacity(0.3), lineWidth: 3)
                    .frame(width: 60, height: 60)
                
                // Animated progress circle - respect Reduce Motion
                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(
                        LinearGradient(
                            colors: [Color.theme.primaryAction, Color.theme.primaryAction.opacity(0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    .animation(
                        UIAccessibility.isReduceMotionEnabled ? 
                            .linear(duration: 0.1) :
                            .linear(duration: 1.2).repeatForever(autoreverses: false),
                        value: isAnimating
                    )
                
                // Inner pulse - respect Reduce Motion
                Circle()
                    .fill(Color.theme.primaryAction.opacity(0.2))
                    .frame(width: 30, height: 30)
                    .scaleEffect(isAnimating ? 1.2 : 0.8)
                    .opacity(isAnimating ? 0.3 : 0.8)
                    .animation(
                        UIAccessibility.isReduceMotionEnabled ?
                            .linear(duration: 0.1) :
                            .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                        value: isAnimating
                    )
            }
            
            VStack(spacing: Theme.Spacing.sm) {
                Text(message + String(repeating: ".", count: dotCount))
                    .bodyMedium()
                    .foregroundColor(Color.theme.primaryText)
                    .multilineTextAlignment(.center)
                
                Text("Using smart relevance sorting")
                    .labelSmall()
                    .foregroundColor(Color.theme.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            isAnimating = true
        }
        .onReceive(timer) { _ in
            dotCount = (dotCount + 1) % 4
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
        .accessibilityHint("Loading content, please wait")
    }
}

// MARK: - Enhanced Error View
struct EnhancedErrorView: View {
    let title: String
    let message: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            VStack(spacing: Theme.Spacing.md) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .headlineSmall()
                    .foregroundColor(Color.theme.error)
                
                Text(title)
                    .titleMedium()
                    .foregroundColor(Color.theme.primaryText)
                
                Text(message)
                    .bodyMedium()
                    .foregroundColor(Color.theme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.lg)
            }
            
            Button(action: {
                // Haptic feedback for retry - respect VoiceOver
                if !UIAccessibility.isVoiceOverRunning {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                }
                retryAction()
            }) {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
                }
            }
            .materialButton(style: .filled, size: .large)
            .frame(minHeight: 44)
            .accessibilityLabel("Retry search")
            .accessibilityHint("Attempts to search again")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Theme.Spacing.lg)
    }
}

// MARK: - Search Result Row (Enhanced)
struct SearchResultRow: View {
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
                        .fill(Color.theme.outline.opacity(0.3))
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
                    .foregroundStyle(Color.theme.secondaryText)
                    .lineLimit(1)
                
                HStack(spacing: Theme.Spacing.md) {
                    if let publishedYear = extractYear(from: book.publishedDate) {
                        Label(publishedYear, systemImage: "calendar")
                            .labelSmall()
                            .foregroundStyle(Color.theme.secondaryText)
                    }
                    
                    if let pageCount = book.pageCount {
                        Label("\(pageCount) pages", systemImage: "doc.text")
                            .labelSmall()
                            .foregroundStyle(Color.theme.secondaryText)
                    }
                    
                    // Quality indicators
                    if book.imageURL != nil {
                        Image(systemName: "photo")
                            .font(.caption2)
                            .foregroundStyle(Color.theme.tertiary)
                    }
                    
                    if book.bookDescription != nil && !book.bookDescription!.isEmpty {
                        Image(systemName: "text.alignleft")
                            .font(.caption2)
                            .foregroundStyle(Color.theme.tertiary)
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