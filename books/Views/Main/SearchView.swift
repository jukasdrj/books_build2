import SwiftUI
import SwiftData

struct SearchView: View {
    @Environment(\.modelContext) private var modelContext
    
    @State private var searchService = BookSearchService.shared
    @State private var searchText = ""
    @State private var searchState: SearchState = .idle
    
    enum SearchState: Equatable {
        case idle
        case searching
        case results([BookMetadata])
        case error(String)
    }

    var body: some View {
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
                    EnhancedLoadingView(message: "Searching for books...")
                    
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
                    EnhancedErrorView(
                        title: "Search Error",
                        message: message,
                        retryAction: performSearch
                    )
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
                HStack(spacing: 4) {
                    if case .searching = searchState {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    }
                    Text("Search")
                        .labelMedium()
                }
            }
            .materialButton(style: .filled, size: .medium)
            .disabled(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || searchState == .searching)
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
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        Task {
            let result = await searchService.search(query: trimmedQuery)
            await MainActor.run {
                switch result {
                case .success(let books):
                    searchState = .results(books)
                    // Success haptic feedback
                    let successFeedback = UINotificationFeedbackGenerator()
                    successFeedback.notificationOccurred(.success)
                case .failure(let error):
                    searchState = .error(formatError(error))
                    // Error haptic feedback
                    let errorFeedback = UINotificationFeedbackGenerator()
                    errorFeedback.notificationOccurred(.error)
                }
            }
        }
    }
    
    private func clearSearch() {
        searchText = ""
        searchState = .idle
        
        // Light haptic feedback for clear action
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
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
                
                // Animated progress circle
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
                        .linear(duration: 1.2)
                        .repeatForever(autoreverses: false),
                        value: isAnimating
                    )
                
                // Inner pulse
                Circle()
                    .fill(Color.theme.primaryAction.opacity(0.2))
                    .frame(width: 30, height: 30)
                    .scaleEffect(isAnimating ? 1.2 : 0.8)
                    .opacity(isAnimating ? 0.3 : 0.8)
                    .animation(
                        .easeInOut(duration: 1.0)
                        .repeatForever(autoreverses: true),
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
                    .font(.system(size: 50))
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
                // Haptic feedback for retry
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                retryAction()
            }) {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
                }
                .materialButton(style: .filled, size: .large)
            }
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
                    withAnimation(.easeOut(duration: 0.3)) {
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
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(book.title) by \(book.authors.joined(separator: ", "))")
        .accessibilityHint("Double tap to view book details")
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