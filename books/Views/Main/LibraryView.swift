import SwiftUI
import SwiftData

struct LibraryView: View {
    enum Filter {
        case library
        case wishlist
        
        var navigationTitle: String {
            switch self {
            case .library:  "My Library"
            case .wishlist: "Wishlist"
            }
        }
        
        var emptyTitle: String {
            switch self {
            case .library:  "Your Library Awaits"
            case .wishlist: "Your Reading Wishlist"
            }
        }
        
        var emptySystemImage: String {
            switch self {
            case .library:  "books.vertical"
            case .wishlist: "heart.text.square"
            }
        }
        
        var emptyDescription: String {
            switch self {
            case .library:  "Start building your personal library by discovering and adding books you love."
            case .wishlist: "Save books you want to read for later. Your future self will thank you!"
            }
        }
        
        var emptyActionTitle: String {
            switch self {
            case .library:  "Discover Books"
            case .wishlist: "Browse Books"
            }
        }
    }
    
    let filter: Filter
    @Binding var selectedTab: Int
    
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\UserBook.dateAdded, order: .reverse)])
    private var allBooks: [UserBook]
    
    @State private var selectedSortOption: SortOption = .dateAdded
    @State private var selectedViewMode: ViewMode = .grid
    @State private var showingSortMenu = false
    @State private var isRefreshing = false
    
    private var displayedBooks: [UserBook] {
        let filtered = switch filter {
        case .library:
            // Library shows all books that are NOT on the wishlist
            allBooks.filter { !$0.onWishlist }
        case .wishlist:
            // Wishlist shows only books marked as wishlist items
            allBooks.filter { $0.onWishlist }
        }
        
        // Remove any potential duplicates based on ID to prevent ForEach errors
        var uniqueBooks: [UserBook] = []
        var seenIDs: Set<UUID> = []
        
        for book in filtered {
            if !seenIDs.contains(book.id) {
                uniqueBooks.append(book)
                seenIDs.insert(book.id)
            }
        }
        
        return sortBooks(uniqueBooks, by: selectedSortOption)
    }
    
    init(filter: Filter = .library, selectedTab: Binding<Int> = .constant(0)) {
        self.filter = filter
        self._selectedTab = selectedTab
    }
    
    var body: some View {
        Group {
            if displayedBooks.isEmpty && !isRefreshing {
                emptyStateView
            } else {
                booksView
            }
        }
        .background(Color.theme.surface)
        .navigationTitle(filter.navigationTitle)
        .navigationDestination(for: UserBook.self) { book in
            BookDetailsView(book: book)
        }
        .navigationDestination(for: String.self) { authorName in
            AuthorSearchResultsView(authorName: authorName)
        }
        .toolbar {
            toolbarContent
        }
    }
    
    // MARK: - Empty State View
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: Theme.Spacing.xl) {
            VStack(spacing: Theme.Spacing.lg) {
                // Animated book stack illustration
                ZStack {
                    // Background books
                    ForEach(0..<3, id: \.self) { index in
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                            .fill(Color.theme.primaryAction.opacity(0.1 + Double(index) * 0.1))
                            .frame(width: 80 - CGFloat(index * 4), height: 120 - CGFloat(index * 6))
                            .offset(x: CGFloat(index * 8), y: CGFloat(index * -4))
                            .rotationEffect(.degrees(Double(index * 2)))
                    }
                    
                    Image(systemName: filter.emptySystemImage)
                        .font(.system(size: 40))
                        .foregroundColor(Color.theme.primaryAction)
                }
                .frame(height: 120)
                
                VStack(spacing: Theme.Spacing.sm) {
                    Text(filter.emptyTitle)
                        .headlineSmall()
                        .foregroundColor(Color.theme.primaryText)
                    
                    Text(filter.emptyDescription)
                        .bodyMedium()
                        .foregroundColor(Color.theme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Theme.Spacing.lg)
                }
            }
            
            // Action button - Fixed: Switch to Search tab instead of NavigationLink
            Button(action: {
                // Haptic feedback for tab switch - respect VoiceOver
                if !UIAccessibility.isVoiceOverRunning {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                }
                
                // Switch to Search tab (tab index 2)
                selectedTab = 2
            }) {
                Label(filter.emptyActionTitle, systemImage: "magnifyingglass")
            }
            .materialButton(style: .filled, size: .large)
            .frame(minHeight: 44)
            .accessibilityLabel("Browse books to add to your \(filter == .library ? "library" : "wishlist")")
            .accessibilityHint("Switches to the search tab to find new books")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Books View with Pull-to-Refresh
    @ViewBuilder
    private var booksView: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.lg) {
                // Header with stats
                LibraryHeaderView(books: displayedBooks, filter: filter)
                
                // Loading indicator during refresh
                if isRefreshing {
                    HStack(spacing: Theme.Spacing.sm) {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(Color.theme.primaryAction)
                        Text("Refreshing library...")
                            .bodyMedium()
                            .foregroundColor(Color.theme.secondaryText)
                    }
                    .padding()
                    .background(Color.theme.cardBackground)
                    .cornerRadius(Theme.CornerRadius.medium)
                }
                
                // Books grid/list
                if selectedViewMode == .grid {
                    booksGrid
                } else {
                    booksListView
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.bottom, Theme.Spacing.xl)
        }
        .refreshable {
            await performRefresh()
        }
    }
    
    // MARK: - Pull-to-Refresh Action
    private func performRefresh() async {
        isRefreshing = true
        
        // Haptic feedback for refresh start - respect VoiceOver
        if !UIAccessibility.isVoiceOverRunning {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }
        
        // Simulate data refresh operations
        await withTaskGroup(of: Void.self) { group in
            // Simulate updating book metadata
            group.addTask {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            }
            
            // Simulate checking for reading progress updates
            group.addTask {
                try? await Task.sleep(nanoseconds: 800_000_000) // 0.8 seconds
            }
            
            // Wait for all refresh tasks to complete
            await group.waitForAll()
        }
        
        // Success haptic feedback - respect VoiceOver
        if !UIAccessibility.isVoiceOverRunning {
            let successFeedback = UINotificationFeedbackGenerator()
            successFeedback.notificationOccurred(.success)
        }
        
        isRefreshing = false
    }
    
    @ViewBuilder
    private var booksGrid: some View {
        let columns = [
            GridItem(.flexible(minimum: 140, maximum: 160), spacing: Theme.Spacing.md),
            GridItem(.flexible(minimum: 140, maximum: 160), spacing: Theme.Spacing.md)
        ]
        
        LazyVGrid(columns: columns, spacing: Theme.Spacing.lg, pinnedViews: []) {
            ForEach(Array(displayedBooks.enumerated()), id: \.element.id) { index, book in
                NavigationLink(value: book) {
                    BookCardView(
                        book: book, 
                        useFlexibleLayout: shouldUseFlexibleLayout(for: index, totalBooks: displayedBooks.count)
                    )
                }
                .buttonStyle(.plain)
                .onAppear {
                    // Light haptic feedback when books appear
                    if index == 0 {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                    }
                }
            }
        }
        .animation(.none, value: displayedBooks) // Prevent animation glitches
    }
    
    @ViewBuilder
    private var booksListView: some View {
        LazyVStack(spacing: Theme.Spacing.sm) {
            ForEach(displayedBooks, id: \.id) { book in
                NavigationLink(value: book) {
                    BookListItem(book: book)
                        .materialCard()
                        .padding(.horizontal, Theme.Spacing.xs)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Toolbar Content
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            HStack(spacing: Theme.Spacing.sm) {
                // View mode toggle
                Button(action: {
                    let animation = UIAccessibility.isReduceMotionEnabled ? 
                        .linear(duration: 0.1) : Theme.Animation.smooth
                    withAnimation(animation) {
                        selectedViewMode = selectedViewMode == .grid ? .list : .grid
                    }
                    
                    // Haptic feedback for view mode change - respect VoiceOver
                    if !UIAccessibility.isVoiceOverRunning {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                    }
                }) {
                    Image(systemName: selectedViewMode == .grid ? "rectangle.grid.2x2" : "list.bullet")
                        .labelMedium()
                }
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
                .accessibilityLabel("Switch to \(selectedViewMode == .grid ? "list" : "grid") view")
                
                // Sort menu
                Menu {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Button(action: {
                            selectedSortOption = option
                            
                            // Haptic feedback for sort change - respect VoiceOver
                            if !UIAccessibility.isVoiceOverRunning {
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                            }
                        }) {
                            HStack {
                                Text(option.displayName)
                                if selectedSortOption == option {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                        .labelMedium()
                }
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
                .accessibilityLabel("Sort books")
                .accessibilityValue("Currently sorted by \(selectedSortOption.displayName)")
                
                if !displayedBooks.isEmpty && filter == .library {
                    EditButton()
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    private func sortBooks(_ books: [UserBook], by option: SortOption) -> [UserBook] {
        switch option {
        case .dateAdded:
            return books.sorted { $0.dateAdded > $1.dateAdded }
        case .title:
            return books.sorted { 
                ($0.metadata?.title ?? "").localizedCaseInsensitiveCompare($1.metadata?.title ?? "") == .orderedAscending
            }
        case .author:
            return books.sorted {
                let author1 = $0.metadata?.authors.first ?? ""
                let author2 = $1.metadata?.authors.first ?? ""
                return author1.localizedCaseInsensitiveCompare(author2) == .orderedAscending
            }
        case .rating:
            return books.sorted { 
                ($0.rating ?? 0) > ($1.rating ?? 0)
            }
        case .status:
            return books.sorted { $0.readingStatus.rawValue < $1.readingStatus.rawValue }
        }
    }
    
    // MARK: - Helper function to determine layout type
    private func shouldUseFlexibleLayout(for index: Int, totalBooks: Int) -> Bool {
        // Check if this is the last book and it's alone on its row
        let isLastBook = index == totalBooks - 1
        let isOddTotal = totalBooks % 2 == 1
        
        return isLastBook && isOddTotal
    }
}

// MARK: - Supporting Types
enum ViewMode {
    case grid
    case list
}

enum SortOption: CaseIterable {
    case dateAdded
    case title
    case author
    case rating
    case status
    
    var displayName: String {
        switch self {
        case .dateAdded: return "Date Added"
        case .title: return "Title"
        case .author: return "Author"
        case .rating: return "Rating"
        case .status: return "Status"
        }
    }
}

// MARK: - Library Header View
struct LibraryHeaderView: View {
    let books: [UserBook]
    let filter: LibraryView.Filter
    
    private var totalBooks: Int { books.count }
    private var readBooks: Int { books.filter { $0.readingStatus == .read }.count }
    private var currentlyReading: Int { books.filter { $0.readingStatus == .reading }.count }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("\(totalBooks) books")
                    .titleLarge()
                    .foregroundColor(Color.theme.primaryText)
                
                if filter == .library {
                    HStack(spacing: Theme.Spacing.md) {
                        StatsPill(icon: "checkmark.circle.fill", value: readBooks, label: "Read", color: Color.theme.success)
                        StatsPill(icon: "book.circle.fill", value: currentlyReading, label: "Reading", color: Color.theme.accentHighlight)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, Theme.Spacing.xs)
    }
}

struct StatsPill: View {
    let icon: String
    let value: Int
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            
            Text("\(max(0, value))") // Ensure non-negative values
                .labelMedium()
                .foregroundColor(Color.theme.primaryText)
            
            Text(label)
                .labelSmall()
                .foregroundColor(Color.theme.secondaryText)
        }
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .cornerRadius(Theme.CornerRadius.large)
    }
}

#Preview {
    NavigationStack {
        LibraryView()
            .modelContainer(for: [UserBook.self, BookMetadata.self], inMemory: true)
    }
}