// books-buildout/books/ContentView.swift
import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            // Beautiful gradient background for boho aesthetic
            LinearGradient(
                colors: [
                    Color.theme.gradientStart.opacity(0.2),
                    Color.theme.gradientEnd.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            TabView(selection: $selectedTab) {
                NavigationStack {
                    LibraryView()
                        .navigationDestination(for: UserBook.self) { book in
                            BookDetailsView(book: book)
                        }
                        .navigationDestination(for: String.self) { authorName in
                            AuthorSearchResultsView(authorName: authorName)
                        }
                }
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "books.vertical.fill" : "books.vertical")
                    Text("Library")
                }
                .tag(0)
                
                NavigationStack {
                    WishlistLibraryView()
                        .navigationDestination(for: UserBook.self) { book in
                            BookDetailsView(book: book)
                        }
                }
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "heart.text.square.fill" : "heart.text.square")
                    Text("Wishlist")
                }
                .tag(1)
                
                NavigationStack {
                    SearchView()
                        .navigationDestination(for: UserBook.self) { book in
                            BookDetailsView(book: book)
                        }
                        .navigationDestination(for: BookMetadata.self) { metadata in
                            SearchResultDetailView(bookMetadata: metadata)
                        }
                }
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "magnifyingglass.circle.fill" : "magnifyingglass")
                    Text("Search")
                }
                .tag(2)
                
                NavigationStack {
                    StatsView()
                        .navigationDestination(for: UserBook.self) { book in
                            BookDetailsView(book: book)
                        }
                        .navigationDestination(for: String.self) { authorName in
                            AuthorSearchResultsView(authorName: authorName)
                        }
                }
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "chart.bar.fill" : "chart.bar")
                    Text("Stats")
                }
                .tag(3)
            }
            .tint(Color.theme.primary) // Beautiful purple tint for tabs
        }
    }
}

// MARK: - Wishlist View (Filter of LibraryView)

struct WishlistLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<UserBook> { $0.onWishlist == true }, sort: \UserBook.dateAdded, order: .reverse) 
    private var wishlistBooks: [UserBook]
    
    @State private var searchText: String = ""
    @State private var selectedLayout: LibraryView.LayoutType = .grid
    
    private var filteredBooks: [UserBook] {
        if searchText.isEmpty {
            return wishlistBooks
        } else {
            return wishlistBooks.filter { book in
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
                    ForEach(LibraryView.LayoutType.allCases, id: \.self) { layout in
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
            
            // Wishlist content
            if filteredBooks.isEmpty {
                EmptyWishlistView(searchText: searchText)
            } else {
                ScrollView(.vertical) {
                    Group {
                        if selectedLayout == .grid {
                            WishlistGridView(books: filteredBooks)
                        } else {
                            WishlistListView(books: filteredBooks)
                        }
                    }
                    .padding(.bottom, Theme.Spacing.xl) // Tab bar padding
                }
            }
        }
        .navigationTitle("Wishlist (\(filteredBooks.count))")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "Search wishlist...")
    }
}

// MARK: - Wishlist Layout Views

struct WishlistGridView: View {
    let books: [UserBook]
    
    var body: some View {
        let columns = [
            GridItem(.fixed(140), spacing: Theme.Spacing.md),
            GridItem(.fixed(140), spacing: Theme.Spacing.md)
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

struct WishlistListView: View {
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

// MARK: - Empty Wishlist View

struct EmptyWishlistView: View {
    let searchText: String
    
    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()
            
            Image(systemName: searchText.isEmpty ? "heart.text.square" : "magnifyingglass")
                .font(.system(size: 64))
                .foregroundColor(Color.theme.primary.opacity(0.6))
            
            VStack(spacing: Theme.Spacing.sm) {
                Text(searchText.isEmpty ? "Your Wishlist is Empty" : "No Results Found")
                    .titleLarge()
                    .foregroundColor(Color.theme.primaryText)
                    .multilineTextAlignment(.center)
                
                Text(searchText.isEmpty ? 
                     "Books you want to read will appear here when you add them to your wishlist." :
                     "Try adjusting your search terms or check the spelling.")
                    .bodyMedium()
                    .foregroundColor(Color.theme.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            if searchText.isEmpty {
                NavigationLink("Discover New Books") {
                    SearchView()
                }
                .materialButton(style: .filled, size: .large)
                .padding(.top, Theme.Spacing.md)
            }
            
            Spacer()
        }
        .padding(Theme.Spacing.xl)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [UserBook.self, BookMetadata.self], inMemory: true)
}