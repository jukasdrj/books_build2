import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("selectedTab") private var selectedTab = 0
    @Environment(\.modelContext) private var modelContext
    
    // Theme manager for observing theme changes
    @State private var themeManager = ThemeManager.shared
    
    // For tracking badge counts
    @State private var libraryCount = 0
    @State private var wishlistCount = 0
    @State private var completedBooksCount = 0
    @State private var currentlyReadingCount = 0
    
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
        .themeAware()
        .onAppear {
            updateBadgeCounts()
            // Ensure theme is properly applied to system UI when app launches
            ThemeManager.shared.refreshSystemUI()
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            // Haptic feedback on tab switch
            HapticFeedbackManager.shared.lightImpact()
            updateBadgeCounts()
        }
        .onChange(of: themeManager.currentTheme) { oldTheme, newTheme in
            // Force system UI refresh when theme changes
            Task { @MainActor in
                // Small delay to ensure theme propagation
                try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
                themeManager.refreshSystemUI()
            }
        }
    }
    
    // MARK: - Badge Count Helpers
    
    private func updateBadgeCounts() {
        Task { @MainActor in
            let books = try? modelContext.fetch(FetchDescriptor<UserBook>())
            
            libraryCount = books?.filter { !$0.onWishlist }.count ?? 0
            wishlistCount = books?.filter { $0.onWishlist }.count ?? 0
            completedBooksCount = books?.filter { $0.readingStatus == .read }.count ?? 0
            currentlyReadingCount = books?.filter { $0.readingStatus == .reading }.count ?? 0
        }
    }
    
    // MARK: - iPad-Optimized Layout
    
    @ViewBuilder
    private var iPadLayout: some View {
        NavigationSplitView {
            // Enhanced sidebar for iPad with badges and animations
            VStack(spacing: 0) {
                // Header with enhanced boho styling
                VStack(spacing: Theme.Spacing.sm) {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.theme.primary.opacity(0.2), Color.theme.secondary.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "books.vertical.fill")
                                .font(.headline)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.theme.primary, Color.theme.secondary],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        .shadow(color: Color.theme.primary.opacity(0.15), radius: 4, x: 0, y: 2)
                        
                        Text("PaperTracks")
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
                
                // Enhanced Navigation Items with badges and animations
                List {
                    Button(action: { 
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedTab = 0
                        }
                        HapticFeedbackManager.shared.lightImpact()
                    }) {
                        EnhancedNavItem(
                            title: "Library",
                            icon: "books.vertical",
                            selectedIcon: "books.vertical.fill",
                            badge: libraryCount,
                            isSelected: selectedTab == 0,
                            tag: 0
                        )
                    }
                    .listRowBackground(Color.clear)
                    .buttonStyle(.plain)
                    
                    Button(action: { 
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedTab = 1
                        }
                        HapticFeedbackManager.shared.lightImpact()
                    }) {
                        EnhancedNavItem(
                            title: "Search",
                            icon: "magnifyingglass",
                            selectedIcon: "magnifyingglass",
                            badge: nil,
                            isSelected: selectedTab == 1,
                            tag: 1
                        )
                    }
                    .listRowBackground(Color.clear)
                    .buttonStyle(.plain)
                    
                    Button(action: { 
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedTab = 2
                        }
                        HapticFeedbackManager.shared.lightImpact()
                    }) {
                        EnhancedNavItem(
                            title: "Stats",
                            icon: "chart.bar",
                            selectedIcon: "chart.bar.fill",
                            badge: completedBooksCount,
                            isSelected: selectedTab == 2,
                            tag: 2
                        )
                    }
                    .listRowBackground(Color.clear)
                    .buttonStyle(.plain)
                    
                    Button(action: { 
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedTab = 3
                        }
                        HapticFeedbackManager.shared.lightImpact()
                    }) {
                        EnhancedNavItem(
                            title: "Culture",
                            icon: "globe",
                            selectedIcon: "globe.americas.fill",
                            badge: nil,
                            isSelected: selectedTab == 3,
                            tag: 3
                        )
                    }
                    .listRowBackground(Color.clear)
                    .buttonStyle(.plain)
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
    
    // MARK: - Enhanced iPhone Layout with Custom Tab Bar
    
    @ViewBuilder
    private var iPhoneLayout: some View {
        ZStack(alignment: .bottom) {
            // Main content
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
                .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea(.keyboard)
            .padding(.bottom, 80) // Add padding to prevent custom tab bar from blocking content
            
            // Custom Enhanced Tab Bar
            EnhancedTabBar(
                selectedTab: $selectedTab,
                libraryCount: libraryCount,
                wishlistCount: wishlistCount,
                completedBooksCount: completedBooksCount,
                currentlyReadingCount: currentlyReadingCount
            )
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
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

// MARK: - Enhanced Navigation Item for iPad
struct EnhancedNavItem: View {
    let title: String
    let icon: String
    let selectedIcon: String
    let badge: Int?
    let isSelected: Bool
    let tag: Int
    
    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Animated selection indicator
            Rectangle()
                .fill(Color.theme.primary)
                .frame(width: 3)
                .opacity(isSelected ? 1 : 0)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
            
            // Icon with animation
            Image(systemName: isSelected ? selectedIcon : icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(isSelected ? Color.theme.primary : Color.theme.onSurface)
                .scaleEffect(isSelected ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
            
            // Title
            Text(title)
                .font(.system(size: 16, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? Color.theme.primary : Color.theme.onSurface)
            
            Spacer()
            
            // Badge
            if let badge = badge, badge > 0 {
                Text("\(badge)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.theme.primary)
                            .shadow(color: Color.theme.primary.opacity(0.3), radius: 2, x: 0, y: 1)
                    )
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
            }
        }
        .padding(.vertical, Theme.Spacing.sm)
        .padding(.horizontal, Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.theme.primaryContainer.opacity(0.3) : Color.clear)
                .animation(.easeInOut(duration: 0.2), value: isSelected)
        )
        .contentShape(Rectangle())
    }
}

// MARK: - Enhanced Custom Tab Bar for iPhone
struct EnhancedTabBar: View {
    @Binding var selectedTab: Int
    let libraryCount: Int
    let wishlistCount: Int
    let completedBooksCount: Int
    let currentlyReadingCount: Int
    
    private let tabItems: [TabBarItem] = [
        TabBarItem(title: "Library", icon: "books.vertical", selectedIcon: "books.vertical.fill"),
        TabBarItem(title: "Search", icon: "magnifyingglass", selectedIcon: "magnifyingglass"),
        TabBarItem(title: "Stats", icon: "chart.bar", selectedIcon: "chart.bar.fill"),
        TabBarItem(title: "Culture", icon: "globe", selectedIcon: "globe.americas.fill")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Animated selection indicator line
            HStack {
                ForEach(0..<tabItems.count, id: \.self) { index in
                    Rectangle()
                        .fill(selectedTab == index ? Color.theme.primary : Color.clear)
                        .frame(height: 2)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedTab)
                }
            }
            
            HStack(spacing: 0) {
                ForEach(0..<tabItems.count, id: \.self) { index in
                    EnhancedTabBarButton(
                        item: tabItems[index],
                        isSelected: selectedTab == index,
                        badge: badgeCount(for: index),
                        action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                selectedTab = index
                            }
                            HapticFeedbackManager.shared.lightImpact()
                        }
                    )
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background(
                .regularMaterial,
                in: RoundedRectangle(cornerRadius: 0)
            )
            .overlay(
                Rectangle()
                    .frame(height: 0.5)
                    .foregroundColor(Color.theme.outline.opacity(0.2)),
                alignment: .top
            )
        }
        .background(Color.theme.surface.opacity(0.95))
    }
    
    private func badgeCount(for index: Int) -> Int? {
        switch index {
        case 0: return libraryCount > 0 ? libraryCount : nil
        case 2: return completedBooksCount > 0 ? completedBooksCount : nil
        default: return nil
        }
    }
}

// MARK: - Tab Bar Models
struct TabBarItem {
    let title: String
    let icon: String
    let selectedIcon: String
}

struct EnhancedTabBarButton: View {
    let item: TabBarItem
    let isSelected: Bool
    let badge: Int?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    // Background circle for selected state
                    Circle()
                        .fill(Color.theme.primaryContainer.opacity(0.3))
                        .frame(width: 32, height: 32)
                        .scaleEffect(isSelected ? 1.0 : 0.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
                    
                    // Icon
                    Image(systemName: isSelected ? item.selectedIcon : item.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(isSelected ? Color.theme.primary : Color.theme.onSurfaceVariant)
                        .scaleEffect(isSelected ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
                    
                    // Badge
                    if let badge = badge, badge > 0 {
                        Text("\(badge)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.theme.error)
                                    .shadow(color: Color.theme.error.opacity(0.3), radius: 2, x: 0, y: 1)
                            )
                            .offset(x: 12, y: -12)
                            .scaleEffect(isSelected ? 1.1 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
                    }
                }
                
                // Title with dynamic badge count
                Text(badgeTitle)
                    .font(.caption2)
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundColor(isSelected ? Color.theme.primary : Color.theme.onSurfaceVariant)
                    .lineLimit(1)
                    .animation(.easeInOut(duration: 0.2), value: isSelected)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }
    
    private var badgeTitle: String {
        if let badge = badge, badge > 0 && (item.title == "Library" || item.title == "Stats") {
            return "\(item.title) (\(badge))"
        }
        return item.title
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
