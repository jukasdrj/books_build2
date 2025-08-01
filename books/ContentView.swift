// books-buildout/books/ContentView.swift
import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                LibraryView()
            }
            .tabItem {
                Label("Library", systemImage: "books.vertical.fill")
            }
            .tag(0)
            
            NavigationStack {
                WishlistView()
            }
            .tabItem {
                Label("Wishlist", systemImage: "wand.and.stars")
            }
            .tag(1)
            
            NavigationStack {
                SearchView()
            }
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }
            .tag(2)
            
            NavigationStack {
                StatsView()
            }
            .tabItem {
                Label("Stats", systemImage: "chart.bar.xaxis")
            }
            .tag(3)
            
            NavigationStack {
                CulturalDiversityView()
            }
            .tabItem {
                Label("Diversity", systemImage: "globe")
            }
            .tag(4)
        }
        .background(Color.theme.background)
        .tint(Color.theme.primaryAction)
        .animation(Theme.Animation.pageTransition, value: selectedTab)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [UserBook.self, BookMetadata.self], inMemory: true)
}