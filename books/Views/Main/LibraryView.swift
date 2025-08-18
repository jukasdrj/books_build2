import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appTheme) private var currentTheme
    @State private var searchText: String = ""
    @State private var selectedLayout: LayoutType = .grid
    @State private var showingFilters = false
    @State private var showingSettings = false
    @State private var showingEnhancement = false
    @State private var libraryFilter = LibraryFilter.all
    
    
    @Query private var allBooks: [UserBook]
    
    @State private var stableFilteredBooks: [UserBook] = []
    @State private var bookCount: Int = 0
    
    // Memoization for expensive filtering operations
    @State private var memoizedFilteredBooks: [UserBook] = []
    @State private var lastFilterHash: Int = 0
    
    init(filter: LibraryFilter? = nil) {
        if let filter = filter {
            _libraryFilter = State(initialValue: filter)
        }
        _allBooks = Query(sort: \UserBook.dateAdded, order: .reverse)
    }
    
    enum LayoutType: String, CaseIterable {
        case grid = "Grid"
        case list = "List"
        
        var icon: String {
            switch self {
            case .grid: return "square.grid.2x2"
            case .list: return "list.bullet"
            }
        }
    }
    
    /// Optimized filtering with lazy evaluation (without state modification during view update)
    private func computeFilteredBooks() -> [UserBook] {
        // Perform optimized filtering with single-pass approach
        return allBooks.lazy
            .filter { book in
                // Combined filtering logic in single pass
                let matchesSearch = searchText.isEmpty || {
                    let title = book.metadata?.title ?? ""
                    let authors = book.metadata?.authors.joined(separator: " ") ?? ""
                    return title.localizedCaseInsensitiveContains(searchText) ||
                           authors.localizedCaseInsensitiveContains(searchText)
                }()
                
                let matchesStatus = libraryFilter.readingStatus.contains(book.readingStatus)
                let matchesWishlist = !libraryFilter.showWishlistOnly || book.onWishlist
                let matchesOwned = !libraryFilter.showOwnedOnly || book.owned
                let matchesFavorites = !libraryFilter.showFavoritesOnly || book.isFavorited
                
                return matchesSearch && matchesStatus && matchesWishlist && matchesOwned && matchesFavorites
            }
            .reduce(into: [UserBook]()) { result, book in
                result.append(book)
            }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            headerSection
            contentSection
        }
        .navigationTitle(libraryFilter.showWishlistOnly ? "Wishlist (\(bookCount))" : "Library (\(bookCount))")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "Search by title or author...")
        .sheet(isPresented: $showingFilters) {
            LibraryFilterView(filter: $libraryFilter)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingEnhancement) {
            LibraryEnrichmentView(modelContext: modelContext)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: Theme.Spacing.md) {
                    // Background import progress indicator (subtle)
                    BackgroundImportProgressIndicator()
                    
                    // Library enhancement insights button
                    Button { showingEnhancement.toggle() } label: {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundColor(currentTheme.primary)
                    }
                    .accessibilityLabel("Library insights")
                    .accessibilityHint("View data quality and enhancement recommendations")
                    
                    Button { showingFilters.toggle() } label: {
                        Image(systemName: libraryFilter.isActive ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                            .foregroundColor(libraryFilter.isActive ? currentTheme.primary : Color.primary)
                    }
                    
                    Button { showingSettings.toggle() } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
        }
        .onAppear {
            updateStableBooks()
            // Add sample data for development/testing if library is empty
            #if DEBUG
            // addSampleDataIfNeeded() // Commented out for production readiness
            #endif
        }
        .onChange(of: allBooks) { _, _ in
            // Debounced update to prevent bouncing during background imports
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                updateStableBooks()
            }
        }
        .onChange(of: searchText) { _, _ in
            // Debounce search updates
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                updateStableBooks()
            }
        }
        .onChange(of: libraryFilter) { _, _ in
            updateStableBooks()
        }
    }
    
    /// Hash function for memoization of filter criteria
    private func hashOf(_ searchText: String, _ filter: LibraryFilter) -> Int {
        var hasher = Hasher()
        hasher.combine(searchText)
        hasher.combine(filter.showWishlistOnly)
        hasher.combine(filter.showOwnedOnly)
        hasher.combine(filter.showFavoritesOnly)
        hasher.combine(filter.readingStatus)
        hasher.combine(allBooks.count) // Include data version
        return hasher.finalize()
    }
    
    private func updateStableBooks() {
        let currentFilterHash = hashOf(searchText, libraryFilter)
        
        // Check if we can use memoized results
        let newBooks: [UserBook]
        if currentFilterHash == lastFilterHash && !memoizedFilteredBooks.isEmpty {
            newBooks = memoizedFilteredBooks
        } else {
            // Compute new filtered books and update cache
            newBooks = computeFilteredBooks()
            memoizedFilteredBooks = newBooks
            lastFilterHash = currentFilterHash
        }
        
        let newCount = newBooks.count
        
        // Only update if there's a significant change
        if stableFilteredBooks.count != newCount || stableFilteredBooks != newBooks {
            // Use smooth animation for new books, no animation for re-filtering
            let shouldAnimate = newCount > stableFilteredBooks.count && newCount - stableFilteredBooks.count <= 5
            
            if shouldAnimate {
                // Gentle animation when adding small batches of books (background import)
                withAnimation(.easeInOut(duration: 0.4)) {
                    stableFilteredBooks = newBooks
                    bookCount = newCount
                }
            } else {
                // No animation for large changes or filtering operations
                withAnimation(.none) {
                    stableFilteredBooks = newBooks
                    bookCount = newCount
                }
            }
        }
    }
    
}

// MARK: - Layout Views (updated - iPad-optimized)

struct UniformGridLayoutView: View {
    let books: [UserBook]
    
    var body: some View {
        let columns = createAdaptiveColumns()
        
        LazyVGrid(columns: columns, spacing: adaptiveSpacing()) {
            ForEach(books) { book in
                NavigationLink(value: book) {
                    BookCardView(book: book)
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel("View details for \(book.metadata?.title ?? "Unknown Title")")
                .accessibilityHint("Opens book details screen")
            }
        }
        .padding(adaptivePadding())
    }
    
    // MARK: - iPad-Optimized Layout
    
    private func createAdaptiveColumns() -> [GridItem] {
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            // iPad: More columns with better max width for larger screens
            return [GridItem(.adaptive(minimum: 140, maximum: 160), spacing: Theme.Spacing.lg)]
        }
        #endif
        
        // iPhone: Standard layout
        return [GridItem(.adaptive(minimum: 140), spacing: Theme.Spacing.md)]
    }
    
    private func adaptiveSpacing() -> CGFloat {
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            return Theme.Spacing.xl // More generous spacing on iPad
        }
        #endif
        
        return Theme.Spacing.lg
    }
    
    private func adaptivePadding() -> EdgeInsets {
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            // iPad: More generous padding for better use of screen real estate
            return EdgeInsets(
                top: Theme.Spacing.xl, 
                leading: Theme.Spacing.xxl, 
                bottom: Theme.Spacing.xl, 
                trailing: Theme.Spacing.xxl
            )
        }
        #endif
        
        // iPhone: Standard padding
        return EdgeInsets(
            top: Theme.Spacing.md, 
            leading: Theme.Spacing.md, 
            bottom: Theme.Spacing.md, 
            trailing: Theme.Spacing.md
        )
    }
}

struct ListLayoutView: View {
    let books: [UserBook]
    
    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(books) { book in
                NavigationLink(value: book) {
                    BookRowView(userBook: book)
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel("View details for \(book.metadata?.title ?? "Unknown Title")")
                
                if book.id != books.last?.id {
                    Divider()
                        .padding(.leading, 80) // Align with text
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
    }
}

// MARK: - LibraryView Extension

private extension LibraryView {
    // MARK: - View Components
    
    var headerSection: some View {
        VStack(spacing: 0) {
            // Import status banner (shows when import is active)
            ImportStatusBanner()
            
            // Quick filter bar
            QuickFilterBar(filter: $libraryFilter) { }
            
            Divider()
            
            // Layout toggle section
            layoutToggleSection
        }
    }
    
    var layoutToggleSection: some View {
        HStack {
            if libraryFilter.isActive {
                HStack(spacing: Theme.Spacing.xs) {
                    Circle()
                        .fill(currentTheme.primary)
                        .frame(width: 8, height: 8)
                    Text("Filtered")
                        .labelSmall()
                        .foregroundColor(currentTheme.primary)
                }
            }
            
            Spacer()
            
            Picker("Layout", selection: $selectedLayout) {
                ForEach(LayoutType.allCases, id: \.self) { layout in
                    Image(systemName: layout.icon).tag(layout)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 120)
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(currentTheme.surface)
    }
    
    var contentSection: some View {
        VStack(spacing: 0) {
            Divider()
            
            // Content section - Use stable filtered books
            if stableFilteredBooks.isEmpty {
                Text("No books to display")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
            } else {
                ScrollView(.vertical) {
                    if selectedLayout == .grid {
                        UniformGridLayoutView(books: stableFilteredBooks)
                    } else {
                        ListLayoutView(books: stableFilteredBooks)
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        LibraryView()
    }
    .modelContainer(for: [UserBook.self, BookMetadata.self], inMemory: true)
}
