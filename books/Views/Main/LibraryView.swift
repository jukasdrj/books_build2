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
            // Debounced update to prevent bouncing during background imports and app resume
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                updateStableBooks()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            // Handle app resume - refresh state after a delay to prevent bouncing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                print("[LibraryView] App became active, refreshing library state")
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
    
    /// Performance optimization: Virtual scrolling for large datasets
    @State private var isLargeDataset: Bool = false
    
    var body: some View {
        let columns = createAdaptiveColumns()
        
        // Use virtual scrolling for large datasets (500+ books for better performance)
        if books.count > 500 {
            VirtualizedGridView(books: books, columns: columns)
                .padding(adaptivePadding())
                .onAppear {
                    isLargeDataset = true
                }
        } else {
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
        // Use virtual scrolling for large datasets in list view too
        if books.count > 500 {
            VirtualizedListView(books: books)
                .padding(.horizontal, Theme.Spacing.md)
        } else {
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
                        .shadow(color: currentTheme.primary.opacity(0.3), radius: 2, x: 0, y: 1)
                    Text("Filtered")
                        .labelSmall()
                        .foregroundColor(currentTheme.primary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.regularMaterial)
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(currentTheme.primary.opacity(0.2), lineWidth: 1)
                        }
                        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                }
            }
            
            Spacer()
            
            // Liquid Glass segmented control
            HStack(spacing: 0) {
                ForEach(LayoutType.allCases, id: \.self) { layout in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedLayout = layout
                        }
                    } label: {
                        Image(systemName: layout.icon)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(selectedLayout == layout ? .white : currentTheme.onSurface)
                            .frame(width: 44, height: 32)
                    }
                    .background {
                        RoundedRectangle(cornerRadius: layout == .grid ? 8 : 8)
                            .fill(selectedLayout == layout ? currentTheme.primary : Color.clear)
                            .shadow(
                                color: selectedLayout == layout ? currentTheme.primary.opacity(0.3) : .clear,
                                radius: selectedLayout == layout ? 4 : 0,
                                x: 0, y: selectedLayout == layout ? 2 : 0
                            )
                    }
                }
            }
            .background {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.regularMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(currentTheme.outline.opacity(0.1), lineWidth: 1)
                    }
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(currentTheme.outline.opacity(0.1))
                        .frame(height: 0.5)
                }
        }
    }
    
    var contentSection: some View {
        VStack(spacing: 0) {
            // Subtle glass divider
            Rectangle()
                .fill(currentTheme.outline.opacity(0.1))
                .frame(height: 0.5)
            
            // Content section with glass background
            if stableFilteredBooks.isEmpty {
                VStack(spacing: Theme.Spacing.lg) {
                    Image(systemName: "books.vertical")
                        .font(.system(size: 64, weight: .light))
                        .foregroundStyle(.secondary)
                    
                    Text("No books to display")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background {
                    // Glass background with theme integration
                    LinearGradient(
                        colors: [
                            currentTheme.background.opacity(0.7),
                            currentTheme.surface.opacity(0.3)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .background(.regularMaterial)
                }
            } else {
                ScrollView(.vertical) {
                    if selectedLayout == .grid {
                        UniformGridLayoutView(books: stableFilteredBooks)
                    } else {
                        ListLayoutView(books: stableFilteredBooks)
                    }
                }
                .background {
                    // Immersive glass background that preserves theme colors
                    LinearGradient(
                        colors: [
                            currentTheme.background.opacity(0.8),
                            currentTheme.surface.opacity(0.4),
                            currentTheme.surfaceVariant.opacity(0.2)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .background(.thinMaterial)
                }
            }
        }
    }
}

// MARK: - Virtual Scrolling Components for Large Datasets

/// High-performance grid view for large datasets using virtual scrolling
struct VirtualizedGridView: View {
    let books: [UserBook]
    let columns: [GridItem]
    
    @State private var visibleRange: Range<Int> = 0..<50
    @State private var scrollOffset: CGFloat = 0
    @State private var scrollDebounceTask: Task<Void, Never>?
    
    private let itemHeight: CGFloat = 300 // Approximate BookCardView height
    private let batchSize = 50
    
    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView(.vertical) {
                    LazyVStack(spacing: 0) {
                        // Top spacer for items before visible range
                        if visibleRange.lowerBound > 0 {
                            Color.clear
                                .frame(height: CGFloat(visibleRange.lowerBound / columnsPerRow) * itemHeight)
                                .id("spacer-top")
                        }
                        
                        // Visible items in grid format
                        let visibleBooks = Array(books[visibleRange])
                        LazyVGrid(columns: columns, spacing: Theme.Spacing.lg) {
                            ForEach(visibleBooks) { book in
                                NavigationLink(value: book) {
                                    BookCardView(book: book)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .accessibilityLabel("View details for \(book.metadata?.title ?? "Unknown Title")")
                                .id(book.id)
                            }
                        }
                        
                        // Bottom spacer for items after visible range
                        if visibleRange.upperBound < books.count {
                            Color.clear
                                .frame(height: CGFloat((books.count - visibleRange.upperBound) / columnsPerRow) * itemHeight)
                                .id("spacer-bottom")
                        }
                    }
                    .background(
                        GeometryReader { scrollGeometry in
                            Color.clear.preference(
                                key: ScrollOffsetPreferenceKey.self,
                                value: scrollGeometry.frame(in: .named("scroll")).minY
                            )
                        }
                    )
                }
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
                    updateVisibleRange(for: offset, viewHeight: geometry.size.height)
                }
            }
        }
    }
    
    private var columnsPerRow: Int {
        columns.count > 0 ? columns.count : 2 // Fallback to 2 columns
    }
    
    private func updateVisibleRange(for offset: CGFloat, viewHeight: CGFloat) {
        // Cancel previous debounce task
        scrollDebounceTask?.cancel()
        
        // Debounce scroll updates to prevent excessive calculations
        scrollDebounceTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 16_000_000) // 16ms debounce (~60fps)
            
            guard !Task.isCancelled else { return }
            
            let rowHeight = itemHeight + Theme.Spacing.lg
            let visibleStartRow = max(0, Int((-offset - viewHeight) / rowHeight))
            let visibleEndRow = min(books.count / columnsPerRow, Int((-offset + viewHeight * 2) / rowHeight))
            
            let newStart = max(0, visibleStartRow * columnsPerRow - batchSize)
            let newEnd = min(books.count, (visibleEndRow + 1) * columnsPerRow + batchSize)
            
            let newRange = newStart..<newEnd
            
            // Only update if range changed significantly
            if abs(newRange.lowerBound - visibleRange.lowerBound) > batchSize / 2 ||
               abs(newRange.upperBound - visibleRange.upperBound) > batchSize / 2 {
                visibleRange = newRange
            }
        }
    }
}

/// High-performance list view for large datasets using virtual scrolling
struct VirtualizedListView: View {
    let books: [UserBook]
    
    @State private var visibleRange: Range<Int> = 0..<50
    @State private var scrollDebounceTask: Task<Void, Never>?
    
    private let itemHeight: CGFloat = 80 // Approximate BookRowView height
    private let batchSize = 100
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical) {
                LazyVStack(spacing: 0) {
                    // Top spacer
                    if visibleRange.lowerBound > 0 {
                        Color.clear
                            .frame(height: CGFloat(visibleRange.lowerBound) * itemHeight)
                    }
                    
                    // Visible items
                    let visibleBooks = Array(books[visibleRange])
                    ForEach(visibleBooks) { book in
                        NavigationLink(value: book) {
                            BookRowView(userBook: book)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .accessibilityLabel("View details for \(book.metadata?.title ?? "Unknown Title")")
                        .id(book.id)
                        
                        if book.id != visibleBooks.last?.id {
                            Divider()
                                .padding(.leading, 80)
                        }
                    }
                    
                    // Bottom spacer
                    if visibleRange.upperBound < books.count {
                        Color.clear
                            .frame(height: CGFloat(books.count - visibleRange.upperBound) * itemHeight)
                    }
                }
                .background(
                    GeometryReader { scrollGeometry in
                        Color.clear.preference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: scrollGeometry.frame(in: .named("scroll")).minY
                        )
                    }
                )
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
                updateVisibleRange(for: offset, viewHeight: geometry.size.height)
            }
        }
    }
    
    private func updateVisibleRange(for offset: CGFloat, viewHeight: CGFloat) {
        // Cancel previous debounce task
        scrollDebounceTask?.cancel()
        
        // Debounce scroll updates to prevent excessive calculations
        scrollDebounceTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 16_000_000) // 16ms debounce (~60fps)
            
            guard !Task.isCancelled else { return }
            
            let visibleStart = max(0, Int((-offset - viewHeight) / itemHeight))
            let visibleEnd = min(books.count, Int((-offset + viewHeight * 2) / itemHeight))
            
            let newStart = max(0, visibleStart - batchSize)
            let newEnd = min(books.count, visibleEnd + batchSize)
            
            let newRange = newStart..<newEnd
            
            // Only update if range changed significantly
            if abs(newRange.lowerBound - visibleRange.lowerBound) > batchSize / 2 ||
               abs(newRange.upperBound - visibleRange.upperBound) > batchSize / 2 {
                visibleRange = newRange
            }
        }
    }
}

/// Preference key for tracking scroll offset in virtual scrolling
struct ScrollOffsetPreferenceKey: PreferenceKey {
    nonisolated(unsafe) static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    NavigationStack {
        LibraryView()
    }
    .modelContainer(for: [UserBook.self, BookMetadata.self], inMemory: true)
}
