import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var searchText: String = ""
    @State private var selectedLayout: LayoutType = .grid
    @State private var showingAddBookFlow = false
    @State private var showingFilters = false
    @State private var showingSettings = false
    @State private var libraryFilter = LibraryFilter.all
    @State private var themeObserver = 0 // Simple state to trigger refresh on theme change
    
    private let themeManager = ThemeManager.shared
    
    @Query private var allBooks: [UserBook]
    
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
    
    private var filteredBooks: [UserBook] {
        var books = allBooks
        
        // Apply search filter first
        if !searchText.isEmpty {
            books = books.filter { book in
                let title = book.metadata?.title ?? ""
                let authors = book.metadata?.authors.joined(separator: " ") ?? ""
                return title.localizedCaseInsensitiveContains(searchText) ||
                       authors.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply library filters
        books = books.filter { book in
            // Reading status filter
            guard libraryFilter.readingStatus.contains(book.readingStatus) else {
                return false
            }
            
            // Wishlist filter
            if libraryFilter.showWishlistOnly && !book.onWishlist {
                return false
            }
            
            // Owned filter
            if libraryFilter.showOwnedOnly && !book.owned {
                return false
            }
            
            // Favorites filter
            if libraryFilter.showFavoritesOnly && !book.isFavorited {
                return false
            }
            
            return true
        }
        
        return books
    }
    
    private var navigationTitle: String {
        if libraryFilter.showWishlistOnly {
            return "Wishlist (\(filteredBooks.count))"
        } else {
            return "Library (\(filteredBooks.count))"
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Quick filter bar
            QuickFilterBar(filter: $libraryFilter) {
                // No longer needed since we removed "More Filters" button
            }
            
            Divider()
            
            // Layout toggle
            HStack {
                // Active filters indicator
                if libraryFilter.isActive {
                    HStack(spacing: Theme.Spacing.xs) {
                        Circle()
                            .fill(Color.theme.primary)
                            .frame(width: 8, height: 8)
                        
                        Text("Filtered")
                            .labelSmall()
                            .foregroundColor(Color.theme.primary)
                    }
                }
                
                Spacer()
                
                Picker("Layout", selection: $selectedLayout) {
                    ForEach(LayoutType.allCases, id: \.self) { layout in
                        Image(systemName: layout.icon)
                            .tag(layout)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 120)
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background(Color.theme.surface)
            
            Divider()
            
            // Main content
            if filteredBooks.isEmpty {
                emptyStateView
            } else {
                ScrollView(.vertical) {
                    Group {
                        if selectedLayout == .grid {
                            UniformGridLayoutView(books: filteredBooks)
                        } else {
                            ListLayoutView(books: filteredBooks)
                        }
                    }
                    .padding(.bottom, Theme.Spacing.xl) // Tab bar padding
                }
            }
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "Search by title or author...")
        .sheet(isPresented: $showingAddBookFlow) {
            SearchView()
        }
        .sheet(isPresented: $showingFilters) {
            LibraryFilterView(filter: $libraryFilter)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: Theme.Spacing.md) {
                    // Refresh button (only show when theme changes or for manual refresh)
                    Button {
                        themeObserver += 1
                        HapticFeedbackManager.shared.lightImpact()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    
                    // Filter button
                    Button {
                        showingFilters.toggle()
                    } label: {
                        Image(systemName: libraryFilter.isActive ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                            .foregroundColor(libraryFilter.isActive ? Color.theme.primary : Color.primary)
                    }
                    
                    // Settings Button
                    Button {
                        showingSettings.toggle()
                    } label: {
                        Image(systemName: "gearshape")
                    }

                    // Main add button
                    Button {
                        showingAddBookFlow.toggle()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .onChange(of: themeManager.currentTheme) { _, _ in
            // Trigger refresh when theme changes
            themeObserver += 1
        }
        .id(themeObserver) // Force refresh when theme changes
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: Theme.Spacing.xl) {
            if searchText.isEmpty {
                if libraryFilter.showWishlistOnly {
                    AppStoreHeroSection(
                        title: "Discover Your Next Read",
                        subtitle: "Books you want to read will appear here",
                        icon: "heart.circle.fill"
                    )
                    
                    VStack(spacing: Theme.Spacing.md) {
                        FeatureHighlightCard(
                            icon: "magnifyingglass",
                            title: "Search & Discover",
                            description: "Find books from millions of titles",
                            accentColor: Color.theme.primary
                        )
                        
                        FeatureHighlightCard(
                            icon: "square.and.arrow.down",
                            title: "Import from Goodreads",
                            description: "Instantly add your reading history",
                            accentColor: Color.theme.secondary
                        )
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                    
                    Button("Start Building Your Wishlist") {
                        showingAddBookFlow = true
                        HapticFeedbackManager.shared.lightImpact()
                    }
                    .materialButton(style: .filled, size: .large)
                    .shadow(color: Color.theme.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                    
                } else if libraryFilter.isActive {
                    EmptyStateView(
                        icon: "line.3.horizontal.decrease.circle",
                        title: "No Books Match Your Filters",
                        message: "Try adjusting your filters or add more books to your library to see them here.",
                        actionTitle: "Clear All Filters",
                        action: { 
                            withAnimation(.smooth) {
                                libraryFilter = LibraryFilter.all
                            }
                            HapticFeedbackManager.shared.lightImpact()
                        }
                    )
                } else {
                    // Main empty state - perfect for App Store screenshots
                    AppStoreHeroSection(
                        title: "Your Reading Journey Starts Here",
                        subtitle: "Track books, celebrate diversity, reach your reading goals",
                        icon: "books.vertical.circle.fill"
                    )
                    
                    VStack(spacing: Theme.Spacing.md) {
                        FeatureHighlightCard(
                            icon: "chart.bar.fill",
                            title: "Beautiful Reading Stats",
                            description: "Track your progress with gorgeous charts",
                            accentColor: Color.theme.primary
                        )
                        
                        FeatureHighlightCard(
                            icon: "globe",
                            title: "Cultural Diversity Insights",
                            description: "Explore voices from around the world",
                            accentColor: Color.theme.tertiary
                        )
                        
                        FeatureHighlightCard(
                            icon: "paintbrush.fill",
                            title: "5 Gorgeous Themes",
                            description: "Personalize your reading sanctuary",
                            accentColor: Color.theme.secondary
                        )
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                    
                    Button("Add Your First Book") {
                        showingAddBookFlow = true  
                        HapticFeedbackManager.shared.lightImpact()
                    }
                    .materialButton(style: .filled, size: .large)
                    .shadow(color: Color.theme.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                }
            } else {
                EmptyStateView(
                    icon: "magnifyingglass",
                    title: "No Results for \"\(searchText)\"",
                    message: "Try adjusting your search terms or explore our book discovery features.",
                    actionTitle: "Browse All Books",
                    action: {
                        searchText = ""
                        HapticFeedbackManager.shared.lightImpact()
                    }
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                .buttonStyle(.plain)
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
                .buttonStyle(.plain)
                
                if book.id != books.last?.id {
                    Divider()
                        .padding(.leading, 80) // Align with text
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
    }
}

#Preview {
    NavigationStack {
        LibraryView()
    }
    .modelContainer(for: [UserBook.self, BookMetadata.self], inMemory: true)
}