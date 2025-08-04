import SwiftUI
import SwiftData

struct SearchView: View {
    @Environment(\.modelContext) private var modelContext
    
    @State private var searchService = BookSearchService.shared
    @State private var searchQuery = ""
    @State private var searchState: SearchState = .idle
    
    @State private var showingBarcodeScanner = false

    enum SearchState: Equatable {
        case idle
        case searching
        case results([BookMetadata])
        case error(String)
    }

    var body: some View {
        VStack(spacing: 0) {
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
            .animation(Theme.Animation.accessible, value: searchState) // Use accessibility-aware animation
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
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !searchQuery.isEmpty {
                    Button("Clear") {
                        clearSearch()
                    }
                    .accessibilityLabel("Clear search")
                    .accessibilityHint("Clear the search field and results")
                    .foregroundColor(Color.theme.primaryAction)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
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
        .sheet(isPresented: $showingBarcodeScanner) {
            BarcodeScannerView { scannedBarcode in
                searchQuery = scannedBarcode
                showingBarcodeScanner = false
                performSearch()
            }
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
        .accessibilityLabel("\(books.count) search results")
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
                    
                    Text("Search millions of books by title, author, or ISBN")
                        .font(.body)
                        .foregroundColor(Color.theme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Theme.Spacing.md)
                }
            }
            .accessibilityLabel("Search for books")
            .accessibilityHint("Use the search field above to find books by title, author, or ISBN")
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, Theme.Spacing.xl)
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
                    
                    Text("Try checking the spelling or using different search terms")
                        .font(.body)
                        .foregroundColor(Color.theme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Theme.Spacing.md)
                }
            }
            .accessibilityLabel("No search results found")
            .accessibilityHint("Try different search terms or check spelling")
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, Theme.Spacing.xl)
    }
    
    // MARK: - Actions
    private func performSearch() {
        let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return }
        
        searchState = .searching
        
        // Add haptic feedback - respect VoiceOver and Reduce Motion
        HapticFeedbackManager.shared.lightImpact()
        
        Task {
            let result = await searchService.search(query: trimmedQuery)
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
                
                Text("This may take a moment")
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