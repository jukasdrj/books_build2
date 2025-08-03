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
                    LibraryView(selectedTab: $selectedTab)
                }
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "books.vertical.fill" : "books.vertical")
                    Text("Library")
                }
                .tag(0)
                
                NavigationStack {
                    LibraryView(filter: .wishlist, selectedTab: $selectedTab)
                }
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "heart.text.square.fill" : "heart.text.square")
                    Text("Wishlist")
                }
                .tag(1)
                
                NavigationStack {
                    SearchView(selectedTab: $selectedTab)
                }
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "magnifyingglass.circle.fill" : "magnifyingglass")
                    Text("Search")
                }
                .tag(2)
                
                NavigationStack {
                    StatsView()
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

#Preview {
    ContentView()
        .modelContainer(for: [UserBook.self, BookMetadata.self], inMemory: true)
}