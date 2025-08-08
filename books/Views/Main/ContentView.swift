// books-buildout/books/ContentView.swift
import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        Group {
            #if os(iOS)
            if UIDevice.current.userInterfaceIdiom == .pad {
                iPadLayout
            } else {
                iPhoneLayout
            }
            #endif
        }
    }
    
    // MARK: - iPad-Optimized Layout
    
    @ViewBuilder
    private var iPadLayout: some View {
        NavigationSplitView {
            // Sidebar for iPad
            VStack(spacing: 0) {
                // Header with enhanced boho styling
                VStack(spacing: Theme.Spacing.sm) {
                    HStack {
                        Image(systemName: "books.vertical.fill")
                            .font(.title2)
                            .foregroundColor(Color.theme.primary)
                            .shadow(color: Color.theme.primary.opacity(0.3), radius: 2, x: 0, y: 1)
                        
                        Text("Books")
                            .titleLarge()
                            .foregroundColor(Color.theme.primaryText)
                        
                        Spacer()
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.top, Theme.Spacing.md)
                    
                    Divider()
                        .background(Color.theme.outline.opacity(0.2))
                }
                .background(
                    LinearGradient(
                        colors: [Color.theme.surface, Color.theme.background],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                // Navigation Items with enhanced iPad styling
                List {
                    Button(action: { selectedTab = 0 }) {
                        Label("Library", systemImage: "books.vertical")
                            .font(.body)
                            .foregroundColor(selectedTab == 0 ? Color.theme.primary : Color.theme.primaryText)
                    }
                    .listRowBackground(selectedTab == 0 ? Color.theme.primaryContainer : Color.clear)
                    
                    Button(action: { selectedTab = 1 }) {
                        Label("Search", systemImage: "magnifyingglass")
                            .font(.body)
                            .foregroundColor(selectedTab == 1 ? Color.theme.primary : Color.theme.primaryText)
                    }
                    .listRowBackground(selectedTab == 1 ? Color.theme.primaryContainer : Color.clear)
                    
                    Button(action: { selectedTab = 2 }) {
                        Label("Stats", systemImage: "chart.bar")
                            .font(.body)
                            .foregroundColor(selectedTab == 2 ? Color.theme.primary : Color.theme.primaryText)
                    }
                    .listRowBackground(selectedTab == 2 ? Color.theme.primaryContainer : Color.clear)
                    
                    Button(action: { selectedTab = 3 }) {
                        Label("Culture", systemImage: "globe")
                            .font(.body)
                            .foregroundColor(selectedTab == 3 ? Color.theme.primary : Color.theme.primaryText)
                    }
                    .listRowBackground(selectedTab == 3 ? Color.theme.primaryContainer : Color.clear)
                }
                .listStyle(.sidebar)
                .scrollContentBackground(.hidden)
                .background(Color.theme.background)
            }
            .frame(minWidth: 280)
            .navigationSplitViewColumnWidth(min: 280, ideal: 320, max: 400)
            .background(Color.theme.background)
        } detail: {
            NavigationStack {
                Group {
                    switch selectedTab {
                    case 0:
                        LibraryView()
                    case 1:
                        SearchView()
                    case 2:
                        StatsView()
                    case 3:
                        CulturalDiversityView()
                    default:
                        LibraryView()
                    }
                }
                // Enhanced navigation destinations inside the NavigationStack
                .navigationDestination(for: UserBook.self) { book in
                    BookDetailsView(book: book)
                }
                .navigationDestination(for: BookMetadata.self) { bookMetadata in
                    SearchResultDetailView(bookMetadata: bookMetadata)
                }
                .navigationDestination(for: String.self) { destination in
                    destinationView(for: destination)
                }
                .navigationDestination(for: AuthorSearchRequest.self) { authorRequest in
                    AuthorSearchResultsView(authorName: authorRequest.authorName)
                }
            }
            .background(Color.theme.background)
        }
        .navigationSplitViewStyle(.balanced)
        .tint(Color.theme.primary)
    }
    
    // MARK: - iPhone Layout
    
    @ViewBuilder
    private var iPhoneLayout: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                LibraryView()
                // Enhanced navigation destinations inside each NavigationStack
                    .navigationDestination(for: UserBook.self) { book in
                        BookDetailsView(book: book)
                    }
                    .navigationDestination(for: BookMetadata.self) { bookMetadata in
                        SearchResultDetailView(bookMetadata: bookMetadata)
                    }
                    .navigationDestination(for: String.self) { destination in
                        destinationView(for: destination)
                    }
                    .navigationDestination(for: AuthorSearchRequest.self) { authorRequest in
                        AuthorSearchResultsView(authorName: authorRequest.authorName)
                    }
            }
            .tabItem {
                Label("Library", systemImage: "books.vertical")
            }
            .tag(0)
            
            NavigationStack {
                SearchView()
                    .navigationDestination(for: UserBook.self) { book in
                        BookDetailsView(book: book)
                    }
                    .navigationDestination(for: BookMetadata.self) { bookMetadata in
                        SearchResultDetailView(bookMetadata: bookMetadata)
                    }
                    .navigationDestination(for: String.self) { destination in
                        destinationView(for: destination)
                    }
                    .navigationDestination(for: AuthorSearchRequest.self) { authorRequest in
                        AuthorSearchResultsView(authorName: authorRequest.authorName)
                    }
            }
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }
            .tag(1)
            
            NavigationStack {
                StatsView()
                    .navigationDestination(for: UserBook.self) { book in
                        BookDetailsView(book: book)
                    }
                    .navigationDestination(for: BookMetadata.self) { bookMetadata in
                        SearchResultDetailView(bookMetadata: bookMetadata)
                    }
                    .navigationDestination(for: String.self) { destination in
                        destinationView(for: destination)
                    }
                    .navigationDestination(for: AuthorSearchRequest.self) { authorRequest in
                        AuthorSearchResultsView(authorName: authorRequest.authorName)
                    }
            }
            .tabItem {
                Label("Stats", systemImage: "chart.bar")
            }
            .tag(2)
            
            NavigationStack {
                CulturalDiversityView()
                    .navigationDestination(for: UserBook.self) { book in
                        BookDetailsView(book: book)
                    }
                    .navigationDestination(for: BookMetadata.self) { bookMetadata in
                        SearchResultDetailView(bookMetadata: bookMetadata)
                    }
                    .navigationDestination(for: String.self) { destination in
                        destinationView(for: destination)
                    }
                    .navigationDestination(for: AuthorSearchRequest.self) { authorRequest in
                        AuthorSearchResultsView(authorName: authorRequest.authorName)
                    }
            }
            .tabItem {
                Label("Culture", systemImage: "globe")
            }
            .tag(3)
        }
        .tint(Color.theme.primary)
    }
    
    // MARK: - Destination View
    
    @ViewBuilder
    private func destinationView(for destination: String) -> some View {
        switch destination {
        case "Library":
            LibraryView()
        case "Search":
            SearchView()
        case "Stats":
            StatsView()
        case "Culture":
            CulturalDiversityView()
        default:
            // Handle author names or other string destinations
            if destination.starts(with: "author:") {
                let authorName = String(destination.dropFirst(7)) // Remove "author:" prefix
                AuthorSearchResultsView(authorName: authorName)
            } else {
                LibraryView()
            }
        }
    }
}

// MARK: - Author Search Request Type
struct AuthorSearchRequest: Hashable, Identifiable {
    let id = UUID()
    let authorName: String
    
    init(authorName: String) {
        self.authorName = authorName
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [UserBook.self, BookMetadata.self], inMemory: true)
}