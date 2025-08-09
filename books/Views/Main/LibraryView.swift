import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appTheme) private var currentTheme
    @State private var searchText: String = ""
    @State private var selectedLayout: LayoutType = .grid
    @State private var showingFilters = false
    @State private var showingSettings = false
    @State private var libraryFilter = LibraryFilter.all
    
    
    @Query private var allBooks: [UserBook]
    
    @State private var stableFilteredBooks: [UserBook] = []
    @State private var bookCount: Int = 0
    
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
    
    var body: some View {
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

            // Quick filter bar
            QuickFilterBar(filter: $libraryFilter) { }
            
            Divider()
            
            // Layout toggle section
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
        .navigationTitle(libraryFilter.showWishlistOnly ? "Wishlist (\(bookCount))" : "Library (\(bookCount))")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "Search by title or author...")
        .sheet(isPresented: $showingFilters) {
            LibraryFilterView(filter: $libraryFilter)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: Theme.Spacing.md) {
                    Button { 
                        updateStableBooks()
                        HapticFeedbackManager.shared.lightImpact()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    
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
        }
        .onChange(of: filteredBooks) { _, newBooks in
            updateStableBooks()
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
    
    private func updateStableBooks() {
        let newBooks = filteredBooks
        let newCount = newBooks.count
        
        // Only update if there's a significant change
        if stableFilteredBooks.count != newCount || stableFilteredBooks != newBooks {
            withAnimation(.none) { // Disable animation to prevent bouncing
                stableFilteredBooks = newBooks
                bookCount = newCount
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