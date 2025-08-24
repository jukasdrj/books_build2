import SwiftUI
import SwiftData

// MARK: - iOS 26 Enhanced Content View
// Modern implementation using native TabView with Liquid Glass design

@available(iOS 26.0, *)
struct iOS26ContentView: View {
    @AppStorage("selectedTab") private var selectedTab = 0
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appTheme) private var theme
    @Environment(\.themeStore) private var themeStore
    
    // Badge counts for tabs
    @State private var libraryCount = 0
    @State private var wishlistCount = 0
    @State private var completedBooksCount = 0
    @State private var currentlyReadingCount = 0
    
    // Barcode scanning
    @State private var showingBarcodeScanner = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Library Tab
            NavigationStack {
                LibraryView()
                    .withNavigationDestinations()
                    // .toolbar {
                    //     ToolbarItemGroup(placement: .navigationBarTrailing) {
                    //         libraryToolbarItems
                    //     }
                    // }
                    .navigationTitle("Library")
                    .navigationBarTitleDisplayMode(.large)
            }
            .tabItem {
                Label("Library", systemImage: "books.vertical")
            }
            .badge(libraryCount > 0 ? libraryCount : 0)
            .tag(0)
            
            // Search Tab
            NavigationStack {
                SearchView()
                    .withNavigationDestinations()
                    // .toolbar {
                    //     ToolbarItem(placement: .navigationBarTrailing) {
                    //         Button {
                    //             showingBarcodeScanner = true
                    //         } label: {
                    //             Image(systemName: "barcode.viewfinder")
                    //                 .font(.title3)
                    //         }
                    //         .accessibilityLabel("Scan book barcode")
                    //         .accessibilityHint("Opens the camera to scan a book's ISBN barcode")
                    //     }
                    // }
                    .navigationTitle("Search Books")
                    .navigationBarTitleDisplayMode(.large)
            }
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }
            .tag(1)
            
            // Stats Tab
            NavigationStack {
                StatsView()
                    .withNavigationDestinations()
                    .navigationTitle("Reading Stats")
                    .navigationBarTitleDisplayMode(.large)
            }
            .tabItem {
                Label("Stats", systemImage: "chart.bar")
            }
            .badge(completedBooksCount > 0 ? completedBooksCount : 0)
            .tag(2)
            
            // Culture Tab
            NavigationStack {
                CulturalDiversityView()
                    .withNavigationDestinations()
                    .navigationTitle("Cultural Diversity")
                    .navigationBarTitleDisplayMode(.large)
            }
            .tabItem {
                Label("Culture", systemImage: "globe.americas")
            }
            .tag(3)
        }
        .tabViewStyle(.automatic) // Fallback for compatibility
        .tint(theme.primary)
        .preferredColorScheme(getPreferredColorScheme())
        .liquidGlassStatusBarTheming()
        .sheet(isPresented: $showingBarcodeScanner) {
            BarcodeScannerView { scannedBarcode in
                handleBarcodeScanned(scannedBarcode)
            }
        }
        .onAppear {
            setupInitialState()
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            handleTabChange(from: oldValue, to: newValue)
        }
        .overlay(alignment: .top) {
            ImportCompletionBanner()
        }
    }
    
    // MARK: - Toolbar Items
    
    @ViewBuilder
    private var libraryToolbarItems: some View {
        Button {
            // Enhancement insights action
        } label: {
            Image(systemName: "chart.line.uptrend.xyaxis")
        }
        .accessibilityLabel("Library insights")
        .accessibilityHint("View data quality and enhancement recommendations")
        
        Button {
            // Filter action
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
        }
        .accessibilityLabel("Filter")
        
        Button {
            // Settings action
        } label: {
            Image(systemName: "gearshape")
        }
        .accessibilityLabel("Settings")
    }
    
    // MARK: - Helper Functions
    
    private func getPreferredColorScheme() -> ColorScheme? {
        // Let system decide for better adaptation
        return nil
    }
    
    private func setupInitialState() {
        updateBadgeCounts()
        
        // Set up import state manager
        Task { @MainActor in
            ImportStateManager.shared.setModelContext(modelContext)
        }
        
        // Ensure smooth tab bar presentation
        withAnimation(.easeInOut(duration: 0.0)) {
            // Force consistent state
        }
    }
    
    private func handleTabChange(from oldTab: Int, to newTab: Int) {
        // Haptic feedback with improved timing
        HapticFeedbackManager.shared.lightImpact()
        
        // Update badge counts
        updateBadgeCounts()
        
        // Tab-specific setup
        switch newTab {
        case 1: // Search tab
            // Prepare search functionality if needed
            break
        case 2: // Stats tab
            // Update stats data if needed
            break
        default:
            break
        }
    }
    
    private func updateBadgeCounts() {
        Task { @MainActor in
            let books = try? modelContext.fetch(FetchDescriptor<UserBook>())
            
            libraryCount = books?.filter { !$0.onWishlist }.count ?? 0
            wishlistCount = books?.filter { $0.onWishlist }.count ?? 0
            completedBooksCount = books?.filter { $0.readingStatus == .read }.count ?? 0
            currentlyReadingCount = books?.filter { $0.readingStatus == .reading }.count ?? 0
        }
    }
    
    private func handleBarcodeScanned(_ scannedBarcode: String) {
        showingBarcodeScanner = false
        
        HapticFeedbackManager.shared.lightImpact()
        
        // Switch to search tab
        selectedTab = 1
        
        // Perform search
        Task {
            let searchService = BookSearchService.shared
            let result = await searchService.search(
                query: scannedBarcode,
                sortBy: .relevance,
                includeTranslations: true
            )
            
            await MainActor.run {
                switch result {
                case .success(let books):
                    if !books.isEmpty {
                        HapticFeedbackManager.shared.success()
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
}

// MARK: - Liquid Glass Status Bar Theming

extension View {
    func liquidGlassStatusBarTheming() -> some View {
        self.modifier(LiquidGlassStatusBarModifier())
    }
}

struct LiquidGlassStatusBarModifier: ViewModifier {
    @Environment(\.appTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme
    
    func body(content: Content) -> some View {
        content
            .preferredColorScheme(colorScheme)
            .statusBarHidden(false)
            .background(
                // Enhanced status bar background with vibrancy
                LinearGradient(
                    colors: [
                        theme.background.opacity(0.95),
                        theme.background.opacity(0.8)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea(.container, edges: .top)
                .frame(height: 0)
            )
    }
}

// MARK: - iPad Specific Implementation

@available(iOS 26.0, *)
struct iOS26iPadContentView: View {
    @AppStorage("selectedTab") private var selectedTab = 0
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appTheme) private var theme
    
    // Badge counts
    @State private var libraryCount = 0
    @State private var completedBooksCount = 0
    
    var body: some View {
        NavigationSplitView {
            // Enhanced sidebar with liquid glass styling
            liquidGlassSidebar
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
                .withNavigationDestinations()
            }
        }
        .navigationSplitViewStyle(.balanced)
        .tint(theme.primary)
        .liquidGlassStatusBarTheming()
        .onAppear {
            updateBadgeCounts()
            Task { @MainActor in
                ImportStateManager.shared.setModelContext(modelContext)
            }
        }
        .overlay(alignment: .top) {
            ImportCompletionBanner()
        }
    }
    
    @ViewBuilder
    private var liquidGlassSidebar: some View {
        VStack(spacing: 0) {
            // Enhanced header
            liquidGlassHeader
            
            // Navigation items with enhanced styling
            List {
                LiquidGlassNavigationItem(
                    title: "Library",
                    icon: "books.vertical",
                    selectedIcon: "books.vertical.fill",
                    badge: libraryCount,
                    isSelected: selectedTab == 0
                )
                .tag(0)
                
                LiquidGlassNavigationItem(
                    title: "Search",
                    icon: "magnifyingglass",
                    selectedIcon: "magnifyingglass",
                    badge: nil,
                    isSelected: selectedTab == 1
                )
                .tag(1)
                
                LiquidGlassNavigationItem(
                    title: "Stats",
                    icon: "chart.bar",
                    selectedIcon: "chart.bar.fill",
                    badge: completedBooksCount,
                    isSelected: selectedTab == 2
                )
                .tag(2)
                
                LiquidGlassNavigationItem(
                    title: "Culture",
                    icon: "globe",
                    selectedIcon: "globe.americas.fill",
                    badge: nil,
                    isSelected: selectedTab == 3
                )
                .tag(3)
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
            .background(.regularMaterial.opacity(0.7))
        }
        .frame(minWidth: 280)
        .liquidGlassCard(
            material: .regular,
            depth: .elevated,
            radius: .minimal,
            vibrancy: .medium
        )
    }
    
    @ViewBuilder
    private var liquidGlassHeader: some View {
        VStack(spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    theme.primary.opacity(0.3),
                                    theme.secondary.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                        .liquidGlassVibrancy(.prominent)
                    
                    Image(systemName: "books.vertical.fill")
                        .font(.headline)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [theme.primary, theme.secondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .liquidGlassVibrancy(.maximum)
                }
                .shadow(
                    color: theme.primary.opacity(0.2),
                    radius: 6,
                    x: 0,
                    y: 3
                )
                
                Text("PaperTracks")
                    .font(LiquidGlassTheme.typography.titleLarge)
                    .foregroundColor(theme.primaryText)
                    .liquidGlassVibrancy(.maximum)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            
            Divider()
                .background(theme.outline.opacity(0.3))
        }
        .background(
            LinearGradient(
                colors: [
                    theme.surface.opacity(0.9),
                    theme.background.opacity(0.7)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .overlay(.ultraThinMaterial.opacity(0.5))
        )
    }
    
    private func updateBadgeCounts() {
        Task { @MainActor in
            let books = try? modelContext.fetch(FetchDescriptor<UserBook>())
            libraryCount = books?.filter { !$0.onWishlist }.count ?? 0
            completedBooksCount = books?.filter { $0.readingStatus == .read }.count ?? 0
        }
    }
}

// MARK: - Liquid Glass Navigation Item

struct LiquidGlassNavigationItem: View {
    let title: String
    let icon: String
    let selectedIcon: String
    let badge: Int?
    let isSelected: Bool
    
    @Environment(\.appTheme) private var theme
    
    var body: some View {
        HStack(spacing: 12) {
            // Selection indicator
            Rectangle()
                .fill(theme.primary)
                .frame(width: 3)
                .opacity(isSelected ? 1 : 0)
                .animation(LiquidGlassTheme.FluidAnimation.smooth.springAnimation, value: isSelected)
            
            // Icon with enhanced vibrancy
            Image(systemName: isSelected ? selectedIcon : icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(isSelected ? theme.primary : theme.onSurface)
                .liquidGlassVibrancy(isSelected ? .maximum : .medium)
                .scaleEffect(isSelected ? 1.1 : 1.0)
                .animation(LiquidGlassTheme.FluidAnimation.smooth.springAnimation, value: isSelected)
            
            // Title
            Text(title)
                .font(LiquidGlassTheme.typography.bodyMedium)
                .fontWeight(isSelected ? .semibold : .medium)
                .foregroundColor(isSelected ? theme.primary : theme.onSurface)
                .liquidGlassVibrancy(isSelected ? .maximum : .medium)
            
            Spacer()
            
            // Badge with liquid glass styling
            if let badge = badge, badge > 0 {
                Text("\(badge)")
                    .font(LiquidGlassTheme.typography.labelSmall)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(theme.primary)
                            .overlay(.thinMaterial.opacity(0.3))
                            .shadow(
                                color: theme.primary.opacity(0.4),
                                radius: 3,
                                x: 0,
                                y: 1
                            )
                    )
                    .liquidGlassVibrancy(.prominent)
                    .scaleEffect(isSelected ? 1.05 : 1.0)
                    .animation(LiquidGlassTheme.FluidAnimation.smooth.springAnimation, value: isSelected)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isSelected ? theme.primaryContainer.opacity(0.3) : Color.clear)
                .overlay(.ultraThinMaterial.opacity(isSelected ? 0.5 : 0))
                .animation(LiquidGlassTheme.FluidAnimation.smooth.springAnimation, value: isSelected)
        )
        .contentShape(Rectangle())
    }
}

// MARK: - Fallback for iOS < 26

struct iOS26ContentViewWrapper: View {
    var body: some View {
        if #available(iOS 26.0, *) {
            iOS26ContentView()
        } else {
            ContentView() // Fallback to current implementation
        }
    }
}

#Preview {
    if #available(iOS 26.0, *) {
        iOS26ContentView()
            .modelContainer(for: [UserBook.self, BookMetadata.self], inMemory: true)
            .environment(\.appTheme, AppColorTheme(variant: .purpleBoho))
    } else {
        ContentView()
            .modelContainer(for: [UserBook.self, BookMetadata.self], inMemory: true)
    }
}