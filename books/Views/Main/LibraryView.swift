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
        VStack(spacing: Theme.Spacing.lg) {
            if searchText.isEmpty {
                if libraryFilter.showWishlistOnly {
                    EmptyStateView(
                        icon: "heart",
                        title: "Your Wishlist is Empty",
                        message: "Books you want to read will appear here. Add some books to your wishlist to get started!",
                        actionTitle: "Find Books",
                        action: { showingAddBookFlow = true }
                    )
                } else if libraryFilter.isActive {
                    EmptyStateView(
                        icon: "line.3.horizontal.decrease.circle",
                        title: "No Books Match Your Filters",
                        message: "Try adjusting your filters or add more books to your library.",
                        actionTitle: "Clear Filters",
                        action: { 
                            withAnimation(.smooth) {
                                libraryFilter = LibraryFilter.all
                            }
                        }
                    )
                } else {
                    EmptyStateView(
                        icon: "books.vertical",
                        title: "Your Library is Empty",
                        message: "Start building your reading collection by adding your first book!",
                        actionTitle: "Add Your First Book",
                        action: { showingAddBookFlow = true }
                    )
                }
            } else {
                EmptyStateView(
                    icon: "magnifyingglass",
                    title: "No Results for \"\(searchText)\"",
                    message: "Try checking the spelling or using different search terms."
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.theme.background)
    }
}

// MARK: - Layout Views (unchanged - just showing for context)

struct UniformGridLayoutView: View {
    let books: [UserBook]
    
    var body: some View {
        let columns = [
            GridItem(.adaptive(minimum: 140), spacing: Theme.Spacing.md)
        ]
        
        LazyVGrid(columns: columns, spacing: Theme.Spacing.lg) {
            ForEach(books) { book in
                NavigationLink(value: book) {
                    BookCardView(book: book)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Theme.Spacing.md)
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