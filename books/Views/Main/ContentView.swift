// books-buildout/books/ContentView.swift
import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            // The gradient is now handled by the theme's background color
            Color.theme.background.ignoresSafeArea()
            
            TabView(selection: $selectedTab) {
                NavigationStack {
                    LibraryView()
                        .navigationDestination(for: UserBook.self) { book in
                            BookDetailsView(book: book)
                        }
                        .navigationDestination(for: String.self) { authorName in
                            AuthorSearchResultsView(authorName: authorName)
                        }
                        .navigationDestination(for: BookMetadata.self) { metadata in
                            SearchResultDetailView(bookMetadata: metadata)
                        }
                }
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "books.vertical.fill" : "books.vertical")
                    Text("Library")
                }
                .tag(0)
                
                NavigationStack {
                    // This now uses a filtered view of the library
                    LibraryView(isWishlist: true)
                        .navigationDestination(for: UserBook.self) { book in
                            BookDetailsView(book: book)
                        }
                        .navigationDestination(for: BookMetadata.self) { metadata in
                            SearchResultDetailView(bookMetadata: metadata)
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
                        .navigationDestination(for: BookMetadata.self) { metadata in
                            SearchResultDetailView(bookMetadata: metadata)
                        }
                }
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "chart.bar.fill" : "chart.bar")
                    Text("Stats")
                }
                .tag(3)
            }
            .tint(Color.theme.primary) // Tint color now from the theme
        }
        .onAppear {
            // Initialize theme manager on app launch
            _ = ThemeManager.shared
        }
    }
}


#Preview {
    ContentView()
        .modelContainer(for: [UserBook.self, BookMetadata.self], inMemory: true)
}