import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("selectedTab") private var selectedTab = 0
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appTheme) private var theme
    @Environment(\.unifiedThemeStore) private var unifiedThemeStore
    
    // For tracking badge counts
    @State private var libraryCount = 0
    @State private var wishlistCount = 0
    @State private var completedBooksCount = 0
    @State private var currentlyReadingCount = 0
    
    // NavigationSplitView selection state
    @State private var selectedBook: UserBook?
    
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
            return "Reading Insights"
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
        NavigationSplitView(columnVisibility: .constant(.all)) {
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
                .background {
                    // Unified sidebar glass background that flows to content column
                    LinearGradient(
                        colors: [
                            theme.surface.opacity(0.98),
                            theme.background.opacity(0.95),
                            theme.surfaceVariant.opacity(0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .background(.thinMaterial)
                }
                
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
                            title: "Insights",
                            icon: "chart.line.uptrend.xyaxis",
                            selectedIcon: "chart.line.uptrend.xyaxis.fill",
                            badge: completedBooksCount,
                            isSelected: selectedTab == 2,
                            tag: 2
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
            .background {
                // Sidebar root background with glass depth
                LinearGradient(
                    colors: [
                        theme.background.opacity(0.98),
                        theme.surface.opacity(0.9)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .background(.ultraThinMaterial)
            }
        } content: {
            ZStack(alignment: .top) {
                Group {
                    switch selectedTab {
                    case 0:
                        LibraryViewForSplitView(selectedBook: $selectedBook)
                    case 1:
                        SearchView()
                    case 2:
                        ReadingInsightsView()
                    default:
                        LibraryViewForSplitView(selectedBook: $selectedBook)
                    }
                }
                
                // Import completion notification banner (iPad)
                ImportCompletionBanner()
            }
            .navigationSplitViewColumnWidth(min: 400, ideal: 600, max: 800)
            .background {
                // Content column glass background that bridges sidebar and detail
                LinearGradient(
                    colors: [
                        theme.background.opacity(0.92),
                        theme.surface.opacity(0.7),
                        theme.surfaceVariant.opacity(0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .background(.regularMaterial)
            }
        } detail: {
            NavigationStack {
                if let selectedBook = selectedBook {
                    BookDetailsView(book: selectedBook)
                        .navigationBarTitleDisplayMode(.large)
                } else {
                    LiquidGlassDetailPlaceholder()
                        .navigationBarTitleDisplayMode(.large)
                }
            }
            .withNavigationDestinations()
            .background {
                // Cohesive glass background that matches the content column
                LinearGradient(
                    colors: [
                        theme.background.opacity(0.95),
                        theme.surface.opacity(0.8),
                        theme.surfaceVariant.opacity(0.4)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .background(.regularMaterial)
            }
        }
        .navigationSplitViewStyle(.balanced)
        .tint(theme.primary)
        .liquidGlassNavigationSplitView()
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
                        ReadingInsightsView()
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
        TabBarItem(title: "Insights", icon: "chart.line.uptrend.xyaxis", selectedIcon: "chart.line.uptrend.xyaxis.fill")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Apple's enhanced liquid glass selection indicator
            HStack {
                ForEach(0..<tabItems.count, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(selectedTab == index ? theme.primary : Color.clear)
                        .liquidGlassVibrancy(selectedTab == index ? .maximum : .subtle)
                        .frame(height: 3)
                        .shadow(
                            color: theme.primary.opacity(selectedTab == index ? 0.3 : 0),
                            radius: selectedTab == index ? 2 : 0,
                            x: 0,
                            y: 1
                        )
                        .animation(
                            LiquidGlassTheme.respectingUserPreferences(.flowing).springAnimation,
                            value: selectedTab
                        )
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
            .liquidGlassCard(
                material: .regular,
                depth: .floating,
                radius: .minimal,
                vibrancy: .medium
            )
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
                    // Apple's Liquid Glass button background with adaptive behavior
                    Circle()
                        .fill(Color.clear)
                        .background {
                            if isSelected {
                                Circle()
                                    .fill(.regularMaterial)
                            }
                        }
                        .overlay {
                            Circle()
                                .fill(theme.primaryContainer.opacity(isSelected ? 0.4 : 0.0))
                                .blur(radius: 0.5) // Apple's performance-optimized blur
                        }
                        .frame(width: 40, height: 40) // Apple's recommended touch target
                        .scaleEffect(isSelected ? 1.05 : 0.85)
                        .animation(
                            LiquidGlassTheme.respectingUserPreferences(.smooth).springAnimation,
                            value: isSelected
                        )
                    
                    // Icon with Apple's enhanced vibrancy
                    Image(systemName: isSelected ? item.selectedIcon : item.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(isSelected ? theme.primary : theme.onSurfaceVariant)
                        .liquidGlassVibrancy(isSelected ? .prominent : .medium)
                        .scaleEffect(isSelected ? 1.08 : 1.0)
                        .animation(
                            LiquidGlassTheme.respectingUserPreferences(.quick).springAnimation,
                            value: isSelected
                        )
                    
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
                                    .liquidGlassVibrancy(.maximum)
                                    .shadow(color: theme.error.opacity(0.4), radius: 3, x: 0, y: 2)
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
        if let badge = badge, badge > 0 && (item.title == "Library" || item.title == "Insights") {
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
// MARK: - Liquid Glass Detail Placeholder
struct LiquidGlassDetailPlaceholder: View {
    @Environment(\.appTheme) private var theme
    
    var body: some View {
        VStack(spacing: Theme.Spacing.xxl) {
            Spacer()
            
            // Glass book icon with depth
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 120, height: 120)
                    .overlay {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        theme.primary.opacity(0.1),
                                        theme.secondary.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .shadow(
                        color: theme.primary.opacity(0.15),
                        radius: 20,
                        x: 0,
                        y: 8
                    )
                
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [theme.primary.opacity(0.9), theme.secondary.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            // Title and subtitle with liquid glass styling
            VStack(spacing: Theme.Spacing.md) {
                Text("Select a Book")
                    .font(.system(size: 28, weight: .medium, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [theme.onSurface, theme.onSurface.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text("Choose a book from your library to explore its details, track your progress, and discover cultural insights")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(theme.onSurfaceVariant.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, Theme.Spacing.xl)
            }
            
            Spacer()
            
            // Subtle glass card showing available features
            HStack(spacing: Theme.Spacing.lg) {
                FeatureHint(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Track Progress",
                    theme: theme
                )
                
                FeatureHint(
                    icon: "star.fill",
                    title: "Rate & Review",
                    theme: theme
                )
                
                FeatureHint(
                    icon: "globe.americas.fill",
                    title: "Cultural Insights",
                    theme: theme
                )
            }
            .padding(.horizontal, Theme.Spacing.xl)
            .padding(.bottom, Theme.Spacing.xxl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            // Immersive glass background with subtle animation
            Rectangle()
                .fill(.clear)
        }
    }
}

struct FeatureHint: View {
    let icon: String
    let title: String
    let theme: AppColorTheme
    
    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [theme.primary.opacity(0.8), theme.secondary.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(theme.onSurfaceVariant.opacity(0.9))
                .multilineTextAlignment(.center)
        }
        .frame(width: 80, height: 60)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    theme.outline.opacity(0.1),
                                    theme.outline.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
                .shadow(
                    color: .black.opacity(0.06),
                    radius: 8,
                    x: 0,
                    y: 4
                )
        }
    }
}

extension View {
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// Applies Liquid Glass styling and proper navigation behavior to NavigationSplitView
    func liquidGlassNavigationSplitView() -> some View {
        self.modifier(LiquidGlassNavigationSplitViewModifier())
    }
}

struct LiquidGlassNavigationSplitViewModifier: ViewModifier {
    @Environment(\.appTheme) private var theme
    
    func body(content: Content) -> some View {
        content
            .preferredColorScheme(nil) // Let system decide based on theme
            .background {
                // Global glass foundation that unifies all columns
                LinearGradient(
                    colors: [
                        theme.background.opacity(0.95),
                        theme.surface.opacity(0.8)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
            }
    }
}

// MARK: - LibraryView for NavigationSplitView
struct LibraryViewForSplitView: View {
    @Binding var selectedBook: UserBook?
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appTheme) private var currentTheme
    @State private var searchText: String = ""
    @State private var selectedLayout: LayoutType = .grid
    @State private var showingFilters = false
    @State private var showingSettings = false
    @State private var showingEnhancement = false
    @State private var libraryFilter = LibraryFilter.all
    
    @Query private var allBooks: [UserBook]
    @State private var stableFilteredBooks: [UserBook] = []
    @State private var bookCount: Int = 0
    
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
    
    init(selectedBook: Binding<UserBook?>, filter: LibraryFilter? = nil) {
        self._selectedBook = selectedBook
        if let filter = filter {
            _libraryFilter = State(initialValue: filter)
        }
        _allBooks = Query(sort: \UserBook.dateAdded, order: .reverse)
    }
    
    private func computeFilteredBooks() -> [UserBook] {
        let filteredBooks = allBooks.lazy
            .filter { book in
                let matchesSearch = searchText.isEmpty || {
                    let title = book.metadata?.title ?? ""
                    let authors = book.metadata?.authors.joined(separator: " ") ?? ""
                    return title.localizedCaseInsensitiveContains(searchText) ||
                           authors.localizedCaseInsensitiveContains(searchText)
                }()
                
                let matchesStatus = libraryFilter.readingStatus.contains(book.readingStatus)
                let matchesWishlist = !libraryFilter.showWishlistOnly || book.onWishlist
                let matchesOwned = !libraryFilter.showOwnedOnly || book.owned
                let matchesFavorites = !libraryFilter.showFavoritesOnly || book.isFavorited
                
                return matchesSearch && matchesStatus && matchesWishlist && matchesOwned && matchesFavorites
            }
            .reduce(into: [UserBook]()) { result, book in
                result.append(book)
            }
        
        return sortBooks(filteredBooks, by: libraryFilter.sortBy, ascending: libraryFilter.sortAscending)
    }
    
    private func sortBooks(_ books: [UserBook], by sortOption: LibrarySortOption, ascending: Bool) -> [UserBook] {
        let sorted = books.sorted { book1, book2 in
            let result: Bool
            
            switch sortOption {
            case .dateAdded:
                result = book1.dateAdded < book2.dateAdded
            case .title:
                let title1 = book1.metadata?.title ?? ""
                let title2 = book2.metadata?.title ?? ""
                result = title1.localizedStandardCompare(title2) == .orderedAscending
            case .author:
                let author1 = book1.metadata?.authors.first ?? ""
                let author2 = book2.metadata?.authors.first ?? ""
                result = author1.localizedStandardCompare(author2) == .orderedAscending
            case .completeness:
                let completeness1 = DataCompletenessService.calculateBookCompleteness(book1)
                let completeness2 = DataCompletenessService.calculateBookCompleteness(book2)
                result = completeness1 < completeness2
            case .rating:
                let rating1 = book1.rating ?? 0
                let rating2 = book2.rating ?? 0
                result = rating1 < rating2
            }
            
            return ascending ? result : !result
        }
        
        return sorted
    }
    
    private func updateStableBooks() {
        let newBooks = computeFilteredBooks()
        let newCount = newBooks.count
        
        if stableFilteredBooks.count != newCount || stableFilteredBooks != newBooks {
            let shouldAnimate = newCount > stableFilteredBooks.count && newCount - stableFilteredBooks.count <= 5
            
            if shouldAnimate {
                withAnimation(.easeInOut(duration: 0.4)) {
                    stableFilteredBooks = newBooks
                    bookCount = newCount
                }
            } else {
                withAnimation(.none) {
                    stableFilteredBooks = newBooks
                    bookCount = newCount
                }
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header section (same as LibraryView)
            VStack(spacing: 0) {
                ImportStatusBanner()
                QuickFilterBar(filter: $libraryFilter) { }
                Divider()
                layoutToggleSection
            }
            
            // Content section with button actions instead of NavigationLinks
            if stableFilteredBooks.isEmpty {
                VStack(spacing: Theme.Spacing.lg) {
                    Image(systemName: "books.vertical")
                        .font(.system(size: 64, weight: .light))
                        .foregroundStyle(.secondary)
                    
                    Text("No books to display")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background {
                    LinearGradient(
                        colors: [
                            currentTheme.background.opacity(0.7),
                            currentTheme.surface.opacity(0.3)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .background(.regularMaterial)
                }
            } else {
                ScrollView(.vertical) {
                    if selectedLayout == .grid {
                        SplitViewGridLayout(books: stableFilteredBooks, selectedBook: $selectedBook)
                    } else {
                        SplitViewListLayout(books: stableFilteredBooks, selectedBook: $selectedBook)
                    }
                }
                .background {
                    LinearGradient(
                        colors: [
                            currentTheme.background.opacity(0.8),
                            currentTheme.surface.opacity(0.4),
                            currentTheme.surfaceVariant.opacity(0.2)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .background(.thinMaterial)
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
        .sheet(isPresented: $showingEnhancement) {
            LibraryEnhancementView()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: Theme.Spacing.md) {
                    BackgroundImportProgressIndicator()
                    
                    Button { showingEnhancement.toggle() } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .foregroundColor(currentTheme.primary)
                            
                            let qualityReport = DataCompletenessService.analyzeLibraryQuality(allBooks)
                            let booksNeedingAttention = qualityReport.booksNeedingAttention
                            
                            if booksNeedingAttention > 0 {
                                Text("\(booksNeedingAttention)")
                                    .font(.caption2)
                                    .foregroundColor(.white)
                                    .background(
                                        Circle()
                                            .fill(Color.red)
                                            .frame(width: 16, height: 16)
                                    )
                                    .offset(x: 8, y: -4)
                            }
                        }
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
        .onChange(of: allBooks) { _, _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                updateStableBooks()
            }
        }
        .onChange(of: searchText) { _, _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                updateStableBooks()
            }
        }
        .onChange(of: libraryFilter) { _, _ in
            updateStableBooks()
        }
    }
    
    var layoutToggleSection: some View {
        HStack {
            if libraryFilter.isActive {
                HStack(spacing: Theme.Spacing.xs) {
                    Circle()
                        .fill(currentTheme.primary)
                        .frame(width: 8, height: 8)
                        .shadow(color: currentTheme.primary.opacity(0.3), radius: 2, x: 0, y: 1)
                    Text("Filtered")
                        .labelSmall()
                        .foregroundColor(currentTheme.primary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.regularMaterial)
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(currentTheme.primary.opacity(0.2), lineWidth: 1)
                        }
                        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                }
            }
            
            Spacer()
            
            HStack(spacing: 0) {
                ForEach(LayoutType.allCases, id: \.self) { layout in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedLayout = layout
                        }
                    } label: {
                        Image(systemName: layout.icon)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(selectedLayout == layout ? .white : currentTheme.onSurface)
                            .frame(width: 44, height: 32)
                    }
                    .background {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(selectedLayout == layout ? currentTheme.primary : Color.clear)
                            .shadow(
                                color: selectedLayout == layout ? currentTheme.primary.opacity(0.3) : .clear,
                                radius: selectedLayout == layout ? 4 : 0,
                                x: 0, y: selectedLayout == layout ? 2 : 0
                            )
                    }
                }
            }
            .background {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.regularMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(currentTheme.outline.opacity(0.1), lineWidth: 1)
                    }
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(currentTheme.outline.opacity(0.1))
                        .frame(height: 0.5)
                }
        }
    }
}

// MARK: - Split View Layout Components
struct SplitViewGridLayout: View {
    let books: [UserBook]
    @Binding var selectedBook: UserBook?
    @Environment(\.appTheme) private var theme
    
    var body: some View {
        let columns = [GridItem(.adaptive(minimum: 140, maximum: 160), spacing: Theme.Spacing.lg)]
        
        LazyVGrid(columns: columns, spacing: Theme.Spacing.xl) {
            ForEach(books) { book in
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedBook = book
                    }
                    HapticFeedbackManager.shared.lightImpact()
                    
                    #if DEBUG
                    print("[SplitView] Selected book: \(book.metadata?.title ?? "Unknown")")
                    #endif
                } label: {
                    LiquidGlassBookCardView(book: book)
                }
                .contentShape(Rectangle())
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel("View details for \(book.metadata?.title ?? "Unknown Title")")
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            selectedBook?.id == book.id ? theme.primary.opacity(0.5) : Color.clear,
                            lineWidth: 2
                        )
                        .animation(.easeInOut(duration: 0.2), value: selectedBook?.id)
                }
            }
        }
        .padding(EdgeInsets(
            top: Theme.Spacing.xl, 
            leading: Theme.Spacing.xxl, 
            bottom: Theme.Spacing.xl, 
            trailing: Theme.Spacing.xxl
        ))
    }
}

struct SplitViewListLayout: View {
    let books: [UserBook]
    @Binding var selectedBook: UserBook?
    @Environment(\.appTheme) private var theme
    
    var body: some View {
        LazyVStack(spacing: 12) {
            ForEach(books) { book in
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedBook = book
                    }
                    HapticFeedbackManager.shared.lightImpact()
                    
                    #if DEBUG
                    print("[SplitView] Selected book: \(book.metadata?.title ?? "Unknown")")
                    #endif
                } label: {
                    LiquidGlassBookRowView(book: book)
                }
                .contentShape(Rectangle())
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel("View details for \(book.metadata?.title ?? "Unknown Title")")
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            selectedBook?.id == book.id ? theme.primary.opacity(0.5) : Color.clear,
                            lineWidth: 2
                        )
                        .animation(.easeInOut(duration: 0.2), value: selectedBook?.id)
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
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
