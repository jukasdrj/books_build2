// books-buildout/books/ContentView.swift
import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab = 0
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                LibraryView()
            }
            .tabItem {
                Label("Library", systemImage: selectedTab == 0 ? "books.vertical.fill" : "books.vertical")
            }
            .tag(0)
            
            NavigationStack {
                LibraryView(filter: .wishlist)
            }
            .tabItem {
                Label("Wishlist", systemImage: selectedTab == 1 ? "wand.and.stars" : "wand.and.stars")
            }
            .tag(1)
            
            NavigationStack {
                SearchView()
            }
            .tabItem {
                Label("Search", systemImage: selectedTab == 2 ? "magnifyingglass" : "magnifyingglass")
            }
            .tag(2)
            
            NavigationStack {
                StatsView()
            }
            .tabItem {
                Label("Stats", systemImage: selectedTab == 3 ? "chart.bar.xaxis" : "chart.bar.xaxis")
            }
            .tag(3)
            
            NavigationStack {
                CulturalDiversityView()
            }
            .tabItem {
                Label("Diversity", systemImage: selectedTab == 4 ? "globe" : "globe")
            }
            .tag(4)
        }
        .background(Color.theme.background)
        .tint(Color.theme.primaryAction)
        .animation(Theme.Animation.pageTransition, value: selectedTab)
        .preferredColorScheme(nil) // Let system handle color scheme
        .accessibilityElement(children: .contain)
    }
}

// TEMP WORKAROUND: If SearchView is missing/undefined, provide a local stub to allow compilation
#if canImport(SwiftUI) && !canImport(SearchView)
struct SearchView: View {
    var body: some View {
        VStack {
            Image(systemName: "magnifyingglass")
                .resizable()
                .frame(width: 80, height: 80)
                .foregroundColor(.gray)
                .padding(.top, 100)
            Text("Search Coming Soon")
                .font(.title2)
                .padding(.top, 30)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.theme.background)
    }
}
#endif

#Preview("Light Mode") {
    ContentView()
        .modelContainer(for: [UserBook.self, BookMetadata.self], inMemory: true)
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    ContentView()
        .modelContainer(for: [UserBook.self, BookMetadata.self], inMemory: true)
        .preferredColorScheme(.dark)
}