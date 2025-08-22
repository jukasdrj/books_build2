import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("selectedTab") private var selectedTab = 0
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appTheme) private var theme
    @Environment(\.themeStore) private var themeStore
    
    // For tracking badge counts
    @State private var libraryCount = 0
    @State private var wishlistCount = 0
    @State private var completedBooksCount = 0
    @State private var currentlyReadingCount = 0
    
    // Barcode scanning
    @State private var showingBarcodeScanner = false
    
    
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
        .fullStatusBarTheming() // Apply complete status bar theming (background + style)
        .preferredColorScheme(getPreferredColorScheme()) // Apply color scheme based on theme
        .keyboardAvoidingLayout() // Prevent keyboard constraint conflicts
        .onAppear {
            updateBadgeCounts()
            
            // Initialize import infrastructure once
            Task { @MainActor in
                ImportStateManager.shared.setModelContext(modelContext)
                _ = BackgroundImportCoordinator.initialize(with: modelContext)
            }
            
            // Prevent navigation bar bounce by ensuring consistent state
            withAnimation(.easeInOut(duration: 0.0)) {
                // Force navigation bar layout consistency
            }
        }
        .onDisappear {
            // Clean up when view disappears (app going to background)
            Task { @MainActor in
                print("[ContentView] View disappeared, cleaning up if needed")
            }
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            // Haptic feedback on tab switch
            HapticFeedbackManager.shared.lightImpact()
            updateBadgeCounts()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            // Handle app resume - refresh badge counts and prevent tab bar bouncing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                print("[ContentView] App became active, refreshing badge counts")
                updateBadgeCounts()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .memoryPressureDetected)) { _ in
            // Handle memory pressure by clearing JSON caches
            Task { @MainActor in
                print("[ContentView] Memory pressure detected, clearing JSON caches")
                let books = try? modelContext.fetch(FetchDescriptor<UserBook>())
                books?.forEach { book in
                    book.clearJSONCaches()
                }
            }
        }
    }
    
    // MARK: - Theme Helper Functions
    
    private func getPreferredColorScheme() -> ColorScheme? {
        // Determine the preferred color scheme based on the current theme
        // Since all our themes support both light and dark modes, let system decide
        // This allows proper adaptation to system appearance changes
        return nil
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
    
    private func tabTitle(for tabIndex: Int) -> String {
        switch tabIndex {
        case 0:
            return "Library"
        case 1:
            return "Search Books"
        case 2:
            return "Stats"
        case 3:
            return "Culture"
        default:
            return "PaperTracks"
        }
    }
    
    // MARK: - Barcode Scanning
    
    private func handleBarcodeScanned(_ scannedBarcode: String) {
        showingBarcodeScanner = false
        
        HapticFeedbackManager.shared.lightImpact()
        
        // Navigate to search tab first
        selectedTab = 1
        
        // Trigger search with the scanned barcode using the full search method
        Task {
            let searchService = BookSearchService.shared
            let result = await searchService.search(query: scannedBarcode, sortBy: .relevance, includeTranslations: true)
            
            await MainActor.run {
                switch result {
                case .success(let books):
                    if !books.isEmpty {
                        HapticFeedbackManager.shared.success()
                        // Post notification to SearchView to update with results
                        NotificationCenter.default.post(
                            name: .barcodeSearchCompleted,
                            object: nil,
                            userInfo: [
                                "query": scannedBarcode,
                                "results": books,
                                "fromBarcodeScanner": true
                            ]
                        )
                    } else {
                        HapticFeedbackManager.shared.error()
                        // Post notification for no results
                        NotificationCenter.default.post(
                            name: .barcodeSearchCompleted,
                            object: nil,
                            userInfo: [
                                "query": scannedBarcode,
                                "results": [],
                                "fromBarcodeScanner": true
                            ]
                        )
                    }
                case .failure(let error):
                    HapticFeedbackManager.shared.error()
                    print("Barcode search failed: \(error)")
                    // Post notification for error
                    NotificationCenter.default.post(
                        name: .barcodeSearchError,
                        object: nil,
                        userInfo: [
                            "query": scannedBarcode,
                            "error": error.localizedDescription,
                            "fromBarcodeScanner": true
                        ]
                    )
                }
            }
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
                                        colors: [theme.primary.opacity(0.2), theme.secondary.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "books.vertical.fill")
                                .font(.headline)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [theme.primary, theme.secondary],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        .shadow(color: theme.primary.opacity(0.15), radius: 4, x: 0, y: 2)
                        
                        Text("PaperTracks")
                            .titleLarge()
                            .foregroundColor(theme.primaryText)
                        
                        Spacer()
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.top, Theme.Spacing.md)
                    
                    Divider()
                        .background(theme.outline.opacity(0.2))
                }
                .background(
                    LinearGradient(
                        colors: [theme.surface, theme.background],
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
                .background(theme.background)
            }
            .frame(minWidth: 280)
            .navigationSplitViewColumnWidth(min: 280, ideal: 320, max: 400)
            .background(theme.background)
        } detail: {
            NavigationStack {
                ZStack(alignment: .top) {
                    Group {
                        switch selectedTab {
                        case 0:
                            LibraryView()
                        case 1:
                            SearchView()
                        case 2:
                            LiquidGlassStatsView()
                        case 3:
                            LiquidGlassCulturalDiversityView()
                        default:
                            LibraryView()
                        }
                    }
                    
                    // Import completion notification banner (iPad)
                    ImportCompletionBanner()
                }
            }
            .withNavigationDestinations() // Apply navigation destinations inside NavigationStack
            .background(theme.background)
        }
        .navigationSplitViewStyle(.balanced)
        .tint(theme.primary)
    }
    
    // MARK: - Enhanced iPhone Layout with Custom Tab Bar
    
    @ViewBuilder
    private var iPhoneLayout: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                ZStack(alignment: .bottom) {
                // Main content
                Group {
                    switch selectedTab {
                    case 0:
                        LibraryView()
                    case 1:
                        SearchView()
                    case 2:
                        LiquidGlassStatsView()
                    case 3:
                        LiquidGlassCulturalDiversityView()
                    default:
                        LibraryView()
                    }
                }
                .ignoresSafeArea(.keyboard)
                .padding(.bottom, 72) // Add padding to prevent custom tab bar from blocking content
                .animation(.easeInOut(duration: 0.3), value: selectedTab)
                // Add navigation title based on selected tab with consistent display mode
                .navigationTitle(tabTitle(for: selectedTab))
                .navigationBarTitleDisplayMode(.large)
                // Add pull-down gesture for easier reachability
                .onTapGesture(count: 2) {
                    // Double tap anywhere to scroll to top for one-handed use
                    withAnimation(.easeOut(duration: 0.5)) {
                        // This would trigger scroll to top in individual views
                        NotificationCenter.default.post(name: .scrollToTop, object: nil)
                    }
                    HapticFeedbackManager.shared.lightImpact()
                }
                .toolbar {
                    if selectedTab == 1 { // Search tab
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button {
                                showingBarcodeScanner = true
                            } label: {
                                Image(systemName: "barcode.viewfinder")
                                    .font(.title3)
                            }
                            .accessibilityLabel("Scan book barcode")
                            .accessibilityHint("Opens the camera to scan a book's ISBN barcode")
                            .foregroundColor(theme.primaryAction)
                        }
                    }
                }
                
                // Custom Enhanced Tab Bar
                EnhancedTabBar(
                    selectedTab: $selectedTab,
                    libraryCount: libraryCount,
                    wishlistCount: wishlistCount,
                    completedBooksCount: completedBooksCount,
                    currentlyReadingCount: currentlyReadingCount
                )
                }
                
                // Import completion notification banner (top layer)
                ImportCompletionBanner()
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .withNavigationDestinations() // Apply navigation destinations inside NavigationStack
            .sheet(isPresented: $showingBarcodeScanner) {
                BarcodeScannerView { scannedBarcode in
                    handleBarcodeScanned(scannedBarcode)
                }
            }
        }
    }
    
}

// MARK: - Enhanced Navigation Item for iPad
struct EnhancedNavItem: View {
    @Environment(\.appTheme) private var theme
    
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
                .fill(theme.primary)
                .frame(width: 3)
                .opacity(isSelected ? 1 : 0)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
            
            // Icon with animation
            Image(systemName: isSelected ? selectedIcon : icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(isSelected ? theme.primary : theme.onSurface)
                .scaleEffect(isSelected ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
            
            // Title
            Text(title)
                .font(.system(size: 16, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? theme.primary : theme.onSurface)
            
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
                            .fill(theme.primary)
                            .shadow(color: theme.primary.opacity(0.3), radius: 2, x: 0, y: 1)
                    )
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
            }
        }
        .padding(.vertical, Theme.Spacing.sm)
        .padding(.horizontal, Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? theme.primaryContainer.opacity(0.3) : Color.clear)
                .animation(.easeInOut(duration: 0.2), value: isSelected)
        )
        .contentShape(Rectangle())
    }
}

// MARK: - Enhanced Custom Tab Bar for iPhone
struct EnhancedTabBar: View {
    @Environment(\.appTheme) private var theme
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
                        .fill(selectedTab == index ? theme.primary : Color.clear)
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
            .padding(.vertical, 12) // Increased for better thumb accessibility
            .background {
                ZStack {
                    // Liquid Glass base
                    Color.clear
                        .background(.regularMaterial)
                    
                    // Theme-aware tint with subtle depth
                    LinearGradient(
                        colors: [
                            theme.surface.opacity(0.5),
                            theme.surfaceVariant.opacity(0.2)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .blendMode(.overlay)
                }
            }
            .overlay(
                Rectangle()
                    .frame(height: 0.5)
                    .foregroundColor(theme.outline.opacity(0.2)),
                alignment: .top
            )
        }
        .background(theme.surface.opacity(0.95))
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
    @Environment(\.appTheme) private var theme
    let item: TabBarItem
    let isSelected: Bool
    let badge: Int?
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            // Enhanced haptic feedback for different interactions
            if isSelected {
                HapticFeedbackManager.shared.lightImpact() // Already selected
            } else {
                HapticFeedbackManager.shared.mediumImpact() // Tab switch
            }
            action()
        }) {
            VStack(spacing: 6) { // Increased spacing for better thumb targets
                ZStack {
                    // Enhanced background with glass effect for selected state
                    Circle()
                        .fill(.thinMaterial)
                        .overlay {
                            Circle()
                                .fill(theme.primaryContainer.opacity(isSelected ? 0.3 : 0.0))
                        }
                        .frame(width: 36, height: 36) // Larger target for thumb accessibility
                        .scaleEffect(isSelected ? 1.0 : 0.8)
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
                    
                    // Icon
                    Image(systemName: isSelected ? item.selectedIcon : item.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(isSelected ? theme.primary : theme.onSurfaceVariant)
                        .scaleEffect(isSelected ? 1.05 : 1.0)
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
                                    .fill(theme.error)
                                    .shadow(color: theme.error.opacity(0.3), radius: 2, x: 0, y: 1)
                            )
                            .offset(x: 10, y: -10)
                            .scaleEffect(isSelected ? 1.05 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
                    }
                }
                
                // Title with dynamic badge count
                Text(badgeTitle)
                    .font(.caption2)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? theme.primary : theme.onSurfaceVariant)
                    .lineLimit(1)
                    .animation(.easeInOut(duration: 0.2), value: isSelected)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, minHeight: 56) // iOS 26 minimum touch target for thumb accessibility
        .contentShape(Rectangle())
        .background {
            // Invisible expanded touch area for easier thumb access
            Rectangle()
                .fill(Color.clear)
                .frame(minHeight: 64) // Extra touch area beyond visual bounds
        }
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

// MARK: - Conditional Modifier Extension
extension View {
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [UserBook.self, BookMetadata.self], inMemory: true)
}

// MARK: - Notification Names
extension Notification.Name {
    static let barcodeSearchCompleted = Notification.Name("barcodeSearchCompleted")
    static let barcodeSearchError = Notification.Name("barcodeSearchError")
    static let scrollToTop = Notification.Name("scrollToTop")
}
