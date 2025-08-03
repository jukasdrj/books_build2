import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var searchText: String = ""
    @State private var selectedLayout: LayoutType = .grid
    @State private var showingAddBookFlow = false
    @State private var showingFilters = false
    @State private var showingSettings = false
    
    let isWishlist: Bool
    
    @Query private var allBooks: [UserBook]
    
    init(isWishlist: Bool = false) {
        self.isWishlist = isWishlist
        let predicate = #Predicate<UserBook> { book in
            isWishlist ? book.onWishlist == true : true
        }
        _allBooks = Query(filter: predicate, sort: \UserBook.dateAdded, order: .reverse)
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
        if searchText.isEmpty {
            return allBooks
        } else {
            return allBooks.filter { book in
                let title = book.metadata?.title ?? ""
                let authors = book.metadata?.authors.joined(separator: " ") ?? ""
                return title.localizedCaseInsensitiveContains(searchText) ||
                       authors.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Layout toggle
            HStack {
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
                ContentUnavailableView(
                    searchText.isEmpty ? (isWishlist ? "Wishlist is Empty" : "Library is Empty") : "No results for \"\(searchText)\"",
                    systemImage: searchText.isEmpty ? (isWishlist ? "heart" : "books.vertical") : "magnifyingglass"
                )
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
        .navigationTitle(isWishlist ? "Wishlist (\(filteredBooks.count))" : "Library (\(filteredBooks.count))")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "Search by title or author...")
        .sheet(isPresented: $showingAddBookFlow) {
            SearchView(isPresented: $showingAddBookFlow)
        }
        .sheet(isPresented: $showingFilters) {
            // Filter view will go here
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: Theme.Spacing.md) {
                    
                    // Filter button
                    Button {
                        showingFilters.toggle()
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                    .disabled(true) // TODO: Implement filters
                    
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
    }
}

// MARK: - Layout Views

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