import SwiftUI
import SwiftData

struct SearchView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.unifiedThemeStore) private var themeStore
    
    // Legacy theme access for compatibility during migration
    private var currentTheme: AppColorTheme {
        themeStore.appTheme
    }
    
    @State private var searchService = BookSearchService.shared
    @State private var searchQuery = ""
    @State private var searchState: SearchState = .idle
    @State private var sortOption: BookSearchService.SortOption = .relevance
    @State private var showingSortOptions = false
    @State private var includeTranslations = false
    @State private var fromBarcodeScanner = false
    @FocusState private var isSearchFieldFocused: Bool
    
    // Unified navigation for both iPad and iPhone
    

    enum SearchState: Equatable {
        case idle
        case searching
        case results([BookMetadata])
        case error(String)
    }

    var body: some View {
        Group {
            if themeStore.currentTheme.isLiquidGlass {
                liquidGlassImplementation
            } else {
                materialDesignImplementation
            }
        }
        .onAppear {
            MigrationTracker.shared.markViewAsAccessed("SearchView")
            MigrationTracker.shared.markViewAsMigrated("SearchView")
            
            #if DEBUG
            print("[SearchView] 🎨 Current theme: \(themeStore.currentTheme.rawValue)")
            print("[SearchView] 🔍 Is Liquid Glass: \(themeStore.currentTheme.isLiquidGlass)")
            print("[SearchView] 🖼️ Using implementation: \(themeStore.currentTheme.isLiquidGlass ? "Liquid Glass" : "Material Design")")
            #endif
            
            // Reset search state when view appears to ensure clean state
            if case .error = searchState {
                searchState = .idle
            }
            
            // 🍎 Apple HIG: Start with search field focused for immediate keyboard appearance
            // "This provides a more transient experience that brings people directly back 
            // to their previous tab after they exit search, and is ideal when you want 
            // search to resolve quickly and seamlessly."
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isSearchFieldFocused = true
            }
        }
    }
    
    // MARK: - Liquid Glass Theme Colors
    private var primaryColor: Color {
        if let liquidVariant = themeStore.currentTheme.liquidGlassVariant {
            return liquidVariant.colorDefinition.primary.color
        } else {
            return themeStore.appTheme.primaryAction
        }
    }
    
    private var secondaryColor: Color {
        if let liquidVariant = themeStore.currentTheme.liquidGlassVariant {
            return liquidVariant.colorDefinition.secondary.color
        } else {
            return themeStore.appTheme.secondary
        }
    }
    
    // MARK: - iOS 26 Liquid Glass Material Hierarchy
    enum LiquidGlassMaterialLevel {
        case background    // .ultraThinMaterial - Immersive backgrounds
        case surface      // .regularMaterial - Primary interactive surfaces  
        case elevated     // .thinMaterial - Elevated controls and cards
        case floating     // .thickMaterial - Modal overlays and sheets
        
        var material: Material {
            switch self {
            case .background: return .ultraThinMaterial
            case .surface: return .regularMaterial  
            case .elevated: return .thinMaterial
            case .floating: return .thickMaterial
            }
        }
    }

    // MARK: - Search Suggestions
    private var searchSuggestions: [String] {
        guard !searchQuery.isEmpty else { return [] }
        
        let baseSuggestions = [
            "Fiction", "Non-fiction", "Mystery", "Romance", "Science Fiction",
            "Fantasy", "Biography", "History", "Self-help", "Poetry"
        ]
        
        // Filter suggestions based on current search query
        return baseSuggestions.filter { suggestion in
            suggestion.localizedCaseInsensitiveContains(searchQuery)
        }.prefix(5).map { $0 }
    }
    
    // MARK: - Liquid Glass Main Content
    @ViewBuilder
    private var liquidGlassMainContent: some View {
        VStack(spacing: 0) {
            // Search Controls with Liquid Glass styling
            if case .results(let books) = searchState, !books.isEmpty {
                if UIDevice.current.userInterfaceIdiom == .pad {
                    liquidGlassiPadControlsBar
                } else {
                    liquidGlassiPhoneControlsBar
                }
            }
            
            // Content Area with immersive glass backgrounds
            liquidGlassContentArea
        }
    }

    // MARK: - iOS 26 Liquid Glass Implementation
    @ViewBuilder
    private var liquidGlassImplementation: some View {
        liquidGlassMainContent
            .searchable(
                text: $searchQuery, 
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search by title, author, or ISBN"
            ) {
                // HIG Clarity: Enhanced search suggestions with better contrast
                if !searchQuery.isEmpty && searchState != .searching {
                    ForEach(searchSuggestions, id: \.self) { suggestion in
                        Label(suggestion, systemImage: "magnifyingglass")
                            .searchCompletion(suggestion)
                            .foregroundStyle(.primary) // Enhanced contrast
                            .font(LiquidGlassTheme.typography.bodyMedium)
                            .tracking(0.1) // Enhanced readability
                    }
                } else if searchQuery.isEmpty {
                    // HIG Deference: Content-focused examples that educate without overwhelming
                    Text("\"The Great Gatsby\"")
                        .searchCompletion("The Great Gatsby")
                        .foregroundStyle(.primary.opacity(0.8))
                    Text("\"Maya Angelou\"")
                        .searchCompletion("Maya Angelou")
                        .foregroundStyle(.primary.opacity(0.8))
                    Text("\"9780451524935\"")
                        .searchCompletion("9780451524935")
                        .foregroundStyle(.primary.opacity(0.8))
                }
            }
            .submitLabel(.search)
            .if(UIDevice.current.userInterfaceIdiom != .pad) { view in
                view.keyboardToolbar() // Add Done button to prevent constraint conflicts
            }
            .liquidGlassAccessibility(
                label: "Search for books",
                hint: "Enter a book title, author name, or ISBN to search for books in the online database"
            )
            .onSubmit(of: .search) {
                performSearch()
            }
            .onChange(of: searchQuery) { oldValue, newValue in
                // Clear results when search query is cleared
                if newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !oldValue.isEmpty {
                    clearSearchResults()
                }
            }
            .liquidGlassModal(isPresented: $showingSortOptions) {
                liquidGlassSortOptionsSheet
            }
            .onReceive(NotificationCenter.default.publisher(for: .barcodeSearchCompleted)) { notification in
                handleBarcodeSearchCompleted(notification)
            }
            .onReceive(NotificationCenter.default.publisher(for: .barcodeSearchError)) { notification in
                handleBarcodeSearchError(notification)
            }
        .background {
            // Immersive Liquid Glass background
            Rectangle()
                .fill(LiquidGlassMaterialLevel.background.material)
                .overlay {
                    LinearGradient(
                        colors: [
                            .clear,
                            primaryColor.opacity(0.05),
                            primaryColor.opacity(0.02)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
        }
        .keyboardAvoidingLayout()
    }
    
    // MARK: - Material Design Legacy Support (Backward Compatibility)
    @ViewBuilder
    private var materialDesignMainContent: some View {
        VStack(spacing: 0) {
            
            // Search Controls - device-specific layout
            if case .results(let books) = searchState, !books.isEmpty {
                if UIDevice.current.userInterfaceIdiom == .pad {
                    iPadSearchControlsBar
                } else {
                    iPhoneSearchControlsBar
                }
            }
            
            // Content Area with HIG Clarity enhancements
            Group {
                    switch searchState {
                    case .idle:
                        enhancedEmptyState
                        
                    case .searching:
                        UnifiedLoadingState(config: .init(
                            message: "Searching millions of books",
                            subtitle: "Using smart relevance sorting",
                            style: .spinner
                        ))
                        
                    case .results(let books):
                        if books.isEmpty {
                            noResultsState
                        } else {
                            searchResultsList(books: books)
                        }
                        
                    case .error(let message):
                        UnifiedErrorState(config: .init(
                            title: "Search Error",
                            message: message,
                            retryAction: retrySearch,
                            style: .standard
                        ))
                    }
                }
                .background {
                    // HIG Deference: Content-first background that doesn't compete
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .overlay {
                            LinearGradient(
                                colors: [
                                    .clear,
                                    primaryColor.opacity(0.02),
                                    primaryColor.opacity(0.01)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        }
                }
                .liquidGlassTransition(value: searchState, animation: .smooth)
            }
            .keyboardAvoidingLayout() // Prevent keyboard constraint conflicts
    }
    
    // MARK: - Material Design Legacy Implementation (Backward Compatibility)
    @ViewBuilder
    private var materialDesignImplementation: some View {
        materialDesignMainContent
            .searchable(
                text: $searchQuery, 
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search by title, author, or ISBN"
            ) {
                // HIG Clarity: Enhanced search suggestions with better contrast
                if !searchQuery.isEmpty && searchState != .searching {
                    ForEach(searchSuggestions, id: \.self) { suggestion in
                        Label(suggestion, systemImage: "magnifyingglass")
                            .searchCompletion(suggestion)
                            .foregroundStyle(.primary) // Enhanced contrast
                            .font(LiquidGlassTheme.typography.bodyMedium)
                            .tracking(0.1) // Enhanced readability
                    }
                } else if searchQuery.isEmpty {
                    // HIG Deference: Content-focused examples that educate without overwhelming
                    Text("\"The Great Gatsby\"")
                        .searchCompletion("The Great Gatsby")
                        .foregroundStyle(.primary.opacity(0.8))
                    Text("\"Maya Angelou\"")
                        .searchCompletion("Maya Angelou")
                        .foregroundStyle(.primary.opacity(0.8))
                    Text("\"9780451524935\"")
                        .searchCompletion("9780451524935")
                        .foregroundStyle(.primary.opacity(0.8))
                }
            }
            .submitLabel(.search)
            .if(UIDevice.current.userInterfaceIdiom != .pad) { view in
                view.keyboardToolbar() // Add Done button to prevent constraint conflicts
            }
            .liquidGlassAccessibility(
                label: "Search for books",
                hint: "Enter a book title, author name, or ISBN to search for books in the online database"
            )
            .onSubmit(of: .search) {
                performSearch()
            }
            .onChange(of: searchQuery) { oldValue, newValue in
                // Clear results when search query is cleared
                if newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !oldValue.isEmpty {
                    clearSearchResults()
                }
            }
            .liquidGlassModal(isPresented: $showingSortOptions) {
                sortOptionsSheet
            }
            .onReceive(NotificationCenter.default.publisher(for: .barcodeSearchCompleted)) { notification in
                handleBarcodeSearchCompleted(notification)
            }
            .onReceive(NotificationCenter.default.publisher(for: .barcodeSearchError)) { notification in
                handleBarcodeSearchError(notification)
            }
    }
    
    // MARK: - Liquid Glass iPad Search Bar
    @ViewBuilder
    private var liquidGlassiPadSearchBar: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Main search container with enhanced glass effect
            HStack(spacing: Theme.Spacing.md) {
                // Search icon with glass vibrancy
                Image(systemName: "magnifyingglass")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .opacity(0.7)
                
                // Enhanced search field
                TextField("Search by title, author, or ISBN", text: $searchQuery)
                    .font(.title3)
                    .fontWeight(.regular)
                    .textFieldStyle(.plain)
                    .focused($isSearchFieldFocused)
                    .onSubmit {
                        performSearch()
                    }
                    .opacity(searchQuery.isEmpty ? 0.6 : 1.0)
                    .keyboardDismissMode(.onDrag)
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("Done") {
                                isSearchFieldFocused = false
                            }
                        }
                    }
                
                // Clear button with enhanced glass effect
                if !searchQuery.isEmpty {
                    Button {
                        withAnimation(LiquidGlassTheme.FluidAnimation.quick.springAnimation) {
                            searchQuery = ""
                            clearSearchResults()
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, Theme.Spacing.xl)
            .padding(.vertical, Theme.Spacing.lg)
            .background {
                // Enhanced Liquid Glass background
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(LiquidGlassMaterialLevel.surface.material)
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        primaryColor.opacity(0.3),
                                        primaryColor.opacity(0.1),
                                        .clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                    .shadow(
                        color: primaryColor.opacity(0.15),
                        radius: 12,
                        x: 0,
                        y: 4
                    )
                    .shadow(
                        color: .black.opacity(0.05),
                        radius: 4,
                        x: 0,
                        y: 2
                    )
            }
            .scaleEffect(isSearchFieldFocused ? 1.02 : 1.0)
            .animation(LiquidGlassTheme.FluidAnimation.smooth.springAnimation, value: isSearchFieldFocused)
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.md)
        .background {
            // Ultra-thin material backdrop
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .top)
                .onTapGesture {
                    if UIDevice.current.userInterfaceIdiom == .pad {
                        isSearchFieldFocused = false
                    }
                }
        }
        .keyboardAvoidingLayout()
    }
    
    // MARK: - Liquid Glass Content Area
    @ViewBuilder
    private var liquidGlassContentArea: some View {
        Group {
            switch searchState {
            case .idle:
                liquidGlassEmptyState
                
            case .searching:
                UnifiedLoadingState(config: .init(
                    message: "Searching millions of books",
                    subtitle: "Using smart relevance sorting",
                    style: .spinner
                ))
                
            case .results(let books):
                if books.isEmpty {
                    liquidGlassNoResultsState
                } else {
                    liquidGlassSearchResultsList(books: books)
                }
                
            case .error(let message):
                UnifiedErrorState(config: .init(
                    title: "Search Error",
                    message: message,
                    retryAction: retrySearch,
                    style: .standard
                ))
            }
        }
        .animation(LiquidGlassTheme.FluidAnimation.smooth.springAnimation, value: searchState)
    }
    
    // MARK: - Liquid Glass Search Controls
    @ViewBuilder
    private var liquidGlassiPadControlsBar: some View {
        // Use existing enhanced controls bar which already has Liquid Glass styling
        iPadSearchControlsBar
    }
    
    @ViewBuilder
    private var liquidGlassiPhoneControlsBar: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Enhanced sort button with glass material
            Button {
                showingSortOptions = true
            } label: {
                HStack(spacing: 3) {
                    Image(systemName: sortOption.systemImage)
                        .font(.caption)
                    Text(sortOption.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .foregroundStyle(.primary)
                .background {
                    Capsule()
                        .fill(LiquidGlassMaterialLevel.elevated.material)
                        .overlay {
                            Capsule()
                                .strokeBorder(.primary.opacity(0.2), lineWidth: 0.5)
                        }
                        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                }
            }
            .accessibilityLabel("Sort by \(sortOption.displayName)")
            
            // Enhanced translations toggle with glass material
            Button {
                withAnimation(LiquidGlassTheme.FluidAnimation.quick.springAnimation) {
                    includeTranslations.toggle()
                }
                // Re-search logic
                let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedQuery.isEmpty {
                    switch searchState {
                    case .results, .error:
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            performSearch()
                        }
                    default:
                        break
                    }
                }
            } label: {
                HStack(spacing: 3) {
                    Image(systemName: includeTranslations ? "globe" : "globe.badge.chevron.backward")
                        .font(.caption)
                    Text(includeTranslations ? "All" : "EN")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .foregroundStyle(includeTranslations ? .white : .primary)
                .background {
                    let capsuleShape = Capsule()
                    Group {
                        if includeTranslations {
                            capsuleShape.fill(
                                LinearGradient(
                                    colors: [
                                        primaryColor,
                                        primaryColor.opacity(0.8)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay {
                                // Chrome-like reflective overlay for active state
                                capsuleShape
                                    .fill(.thickMaterial)
                                    .opacity(0.3)
                                    .blendMode(.overlay)
                            }
                        } else {
                            capsuleShape.fill(LiquidGlassMaterialLevel.elevated.material)
                        }
                    }
                    .overlay {
                        if !includeTranslations {
                            capsuleShape.strokeBorder(.primary.opacity(0.2), lineWidth: 0.5)
                        }
                    }
                    .shadow(
                        color: includeTranslations ? primaryColor.opacity(0.25) : .black.opacity(0.08),
                        radius: includeTranslations ? 6 : 4,
                        x: 0,
                        y: includeTranslations ? 3 : 2
                    )
                }
            }
            .accessibilityLabel(includeTranslations ? "Including all languages" : "English only")
            
            Spacer()
            
            // Results count with glass material
            if case .results(let books) = searchState {
                Text("\(books.count)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background {
                        Capsule()
                            .fill(LiquidGlassMaterialLevel.background.material)
                            .overlay {
                                Capsule().strokeBorder(.secondary.opacity(0.1), lineWidth: 0.5)
                            }
                    }
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background {
            Rectangle()
                .fill(LiquidGlassMaterialLevel.elevated.material)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(.separator.opacity(0.3))
                        .frame(height: 0.5)
                }
        }
    }
    
    // MARK: - Liquid Glass Search Suggestions
    @ViewBuilder
    private var liquidGlassSearchSuggestions: some View {
        if searchQuery.isEmpty {
            Group {
                Text("\"The Great Gatsby\"").searchCompletion("The Great Gatsby")
                Text("\"Maya Angelou\"").searchCompletion("Maya Angelou") 
                Text("\"9780451524935\"").searchCompletion("9780451524935")
            }
        }
    }
    
    // MARK: - Liquid Glass Empty State
    @ViewBuilder
    private var liquidGlassEmptyState: some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            liquidGlassiPadEmptyState
        } else {
            liquidGlassiPhoneEmptyState
        }
    }
    
    @ViewBuilder
    private var liquidGlassiPadEmptyState: some View {
        VStack(spacing: Theme.Spacing.xl) {
            // Enhanced hero content with depth
            VStack(spacing: Theme.Spacing.lg) {
                ZStack {
                    // Multiple depth layers for enhanced glass effect
                    Circle()
                        .fill(LiquidGlassMaterialLevel.surface.material)
                        .frame(width: 160, height: 160)
                        .overlay {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            primaryColor.opacity(0.2),
                                            primaryColor.opacity(0.1),
                                            .clear
                                        ],
                                        center: .center,
                                        startRadius: 10,
                                        endRadius: 80
                                    )
                                )
                        }
                        .shadow(
                            color: primaryColor.opacity(0.2),
                            radius: 25,
                            x: 0,
                            y: 10
                        )
                        .shadow(
                            color: .black.opacity(0.1),
                            radius: 12,
                            x: 0,
                            y: 6
                        )
                    
                    // Animated icon with vibrancy
                    Image(systemName: "magnifyingglass.circle.fill")
                        .font(.system(size: 72, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    primaryColor,
                                    primaryColor.opacity(0.7)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: primaryColor.opacity(0.3), radius: 6, x: 0, y: 3)
                }
                .scaleEffect(1.0)
                .offset(y: sin(Date().timeIntervalSince1970 * 0.5) * 2) // Subtle floating animation
                .animation(
                    Animation.easeInOut(duration: 3.0)
                        .repeatForever(autoreverses: true),
                    value: UUID()
                )
                
                VStack(spacing: Theme.Spacing.sm) {
                    Text("Discover Your Next Great Read")
                        .font(.largeTitle)
                        .fontWeight(.light)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.primary)
                    
                    Text("Search millions of books with smart sorting and powerful filters")
                        .font(.title3)
                        .fontWeight(.regular)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            }
            
            // Enhanced example searches with glass capsules
            VStack(spacing: Theme.Spacing.md) {
                Text("Try these searches:")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 200), spacing: Theme.Spacing.md)
                ], spacing: Theme.Spacing.md) {
                    ForEach([
                        ("The Great Gatsby", "book.fill"),
                        ("Maya Angelou", "person.fill"),
                        ("9780451524935", "barcode")
                    ], id: \.0) { example, icon in
                        Button {
                            withAnimation(LiquidGlassTheme.FluidAnimation.smooth.springAnimation) {
                                searchQuery = example
                                performSearch()
                            }
                        } label: {
                            HStack(spacing: Theme.Spacing.xs) {
                                Image(systemName: icon)
                                    .font(.callout)
                                    .fontWeight(.medium)
                                Text(example)
                                    .font(.callout)
                                    .fontWeight(.medium)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .foregroundStyle(.primary)
                            .background {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(LiquidGlassMaterialLevel.elevated.material)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .strokeBorder(
                                                LinearGradient(
                                                    colors: [
                                                        primaryColor.opacity(0.3),
                                                        primaryColor.opacity(0.1)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1
                                            )
                                    }
                                    .shadow(
                                        color: primaryColor.opacity(0.15),
                                        radius: 12,
                                        x: 0,
                                        y: 6
                                    )
                                    .shadow(
                                        color: .black.opacity(0.05),
                                        radius: 4,
                                        x: 0,
                                        y: 2
                                    )
                            }
                        }
                        .buttonStyle(.plain)
                        .scaleEffect(1.0)
                        .animation(LiquidGlassTheme.FluidAnimation.quick.springAnimation, value: searchQuery)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            // Immersive multi-layer background
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay {
                    LinearGradient(
                        colors: [
                            .clear,
                            primaryColor.opacity(0.03),
                            primaryColor.opacity(0.01)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
        }
        .accessibilityLabel("Search for books")
        .accessibilityHint("Use the search field above to find books by title, author, or ISBN")
    }
    
    @ViewBuilder
    private var liquidGlassiPhoneEmptyState: some View {
        UnifiedHeroSection(config: .init(
            icon: "magnifyingglass.circle.fill",
            title: "Discover Your Next Great Read",
            subtitle: "Search millions of books with smart sorting and find exactly what you're looking for",
            style: .discovery,
            actions: [
                .init(
                    title: "Smart Relevance",
                    icon: "target",
                    description: "Find the most relevant results for your search"
                ) {},
                .init(
                    title: "Sort by Popularity",
                    icon: "star.fill",
                    description: "Discover trending and highly-rated books"
                ) {},
                .init(
                    title: "All Languages",
                    icon: "globe",
                    description: "Include translated works from around the world"
                ) {}
            ]
        ))
        .liquidGlassBackground(
            material: .ultraThin, // HIG Depth: Consistent material hierarchy
            vibrancy: .subtle     // HIG Deference: Content-supporting background
        )
        .accessibilityLabel("Search for books")
        .accessibilityHint("Use the search field above to find books by title, author, or ISBN")
    }
    
    // MARK: - Liquid Glass No Results State
    @ViewBuilder
    private var liquidGlassNoResultsState: some View {
        UnifiedHeroSection(config: .init(
            icon: "questionmark.circle.fill",
            title: "No Results Found",
            subtitle: "Try different search terms or check your spelling. You can also try including translated works.",
            style: .error,
            actions: [
                .init(
                    title: "Book titles",
                    icon: "book.fill",
                    description: "Try \"The Great Gatsby\""
                ) {
                    searchQuery = "The Great Gatsby"
                    performSearch()
                },
                .init(
                    title: "Author names",
                    icon: "person.fill",
                    description: "Try \"Maya Angelou\""
                ) {
                    searchQuery = "Maya Angelou"
                    performSearch()
                },
                .init(
                    title: "ISBN numbers",
                    icon: "barcode",
                    description: "Try \"9780451524935\""
                ) {
                    searchQuery = "9780451524935"
                    performSearch()
                }
            ]
        ))
        .background {
            Rectangle()
                .fill(LiquidGlassMaterialLevel.elevated.material)
        }
        .accessibilityLabel("No search results found")
        .accessibilityHint("Try different search terms or check spelling")
    }
    
    // MARK: - Liquid Glass Search Results List
    @ViewBuilder
    private func liquidGlassSearchResultsList(books: [BookMetadata]) -> some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            liquidGlassiPadSearchResultsGrid(books: books)
        } else {
            liquidGlassiPhoneSearchResultsList(books: books)
        }
    }
    
    @ViewBuilder
    private func liquidGlassiPadSearchResultsGrid(books: [BookMetadata]) -> some View {
        ScrollView {
            LazyVStack(spacing: 0) { // Clean list-style layout
                ForEach(books) { book in
                    NavigationLink(value: book) {
                        liquidGlassSearchResultCard(book: book)
                    }
                    .onTapGesture {
                        HapticFeedbackManager.shared.lightImpact()
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.bottom, Theme.Spacing.xl)
        }
        .liquidGlassBackground(
            material: .ultraThin, // HIG Depth: Consistent material hierarchy
            vibrancy: .subtle     // HIG Deference: Content-supporting background
        )
        .accessibilityLabel("Search results: \(books.count) \(books.count == 1 ? "book" : "books") found, sorted by \(sortOption.displayName.lowercased())")
        .accessibilityHint("Swipe up or down to browse through search results")
    }
    
    @ViewBuilder
    private func liquidGlassSearchResultCard(book: BookMetadata) -> some View {
        VStack(spacing: 0) {
            SearchResultRow(book: book)
                .padding(Theme.Spacing.xl) // Enhanced generous padding
        }
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous) // Increased radius
                .fill(.thinMaterial) // Lighter material for better distinction
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    primaryColor.opacity(0.2),
                                    primaryColor.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
                .shadow(
                    color: primaryColor.opacity(0.12), // Colored shadow
                    radius: 12,
                    x: 0,
                    y: 6
                )
                .shadow(
                    color: .black.opacity(0.06), // Subtle depth shadow
                    radius: 4,
                    x: 0,
                    y: 2
                )
        }
    }
    
    @ViewBuilder
    private func liquidGlassiPhoneSearchResultsList(books: [BookMetadata]) -> some View {
        List(books) { book in
            NavigationLink(value: book) {
                SearchResultRow(book: book)
            }
            .listRowBackground(Color.clear) // Clean transparent background
            .listRowSeparator(.visible) // Show clean system separators
            .padding(.vertical, Theme.Spacing.xs) // Minimal padding
        }
        .listStyle(.plain)
        .liquidGlassBackground(
            material: .ultraThin, // HIG Depth: Ultra-light for list background
            vibrancy: .subtle     // HIG Deference: Minimal interference with content
        )
        .scrollContentBackground(.hidden)
        .accessibilityLabel("Search results: \(books.count) \(books.count == 1 ? "book" : "books") found, sorted by \(sortOption.displayName.lowercased())")
        .accessibilityHint("Swipe up or down to browse through search results")
    }
    
    // MARK: - Liquid Glass Sort Options Sheet
    @ViewBuilder
    private var liquidGlassSortOptionsSheet: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text("Sort Search Results")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Text("Choose how to order your search results")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 20)
                .padding(.horizontal, 20)
                
                // Sort options with enhanced glass styling
                LazyVStack(spacing: 0) {
                    ForEach(BookSearchService.SortOption.allCases) { option in
                        Button {
                            let newSortOption = option
                            sortOption = newSortOption
                            showingSortOptions = false
                            
                            HapticFeedbackManager.shared.mediumImpact()
                            
                            let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !trimmedQuery.isEmpty {
                                switch searchState {
                                case .results, .error:
                                    Task { @MainActor in
                                        performSearch()
                                    }
                                default:
                                    break
                                }
                            }
                        } label: {
                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(LiquidGlassMaterialLevel.elevated.material)
                                        .frame(width: 40, height: 40)
                                        .overlay {
                                            Circle()
                                                .strokeBorder(
                                                    primaryColor.opacity(0.2),
                                                    lineWidth: 1
                                                )
                                        }
                                    
                                    Image(systemName: option.systemImage)
                                        .font(.system(size: 18))
                                        .foregroundStyle(primaryColor)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(option.displayName)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    
                                    Text(sortDescription(for: option))
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.leading)
                                }
                                
                                Spacer()
                                
                                if sortOption == option {
                                    Image(systemName: "checkmark")
                                        .font(.headline)
                                        .foregroundStyle(primaryColor)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background {
                                if sortOption == option {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(LiquidGlassMaterialLevel.elevated.material)
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 12)
                                                .strokeBorder(
                                                    primaryColor.opacity(0.3),
                                                    lineWidth: 1
                                                )
                                        }
                                } else {
                                    Color.clear
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        
                        if option != BookSearchService.SortOption.allCases.last {
                            Divider()
                                .padding(.leading, 76)
                        }
                    }
                }
                .padding(.top, 20)
                
                Spacer()
            }
            .background(.regularMaterial)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingSortOptions = false
                    }
                    .foregroundStyle(primaryColor)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Enhanced iPad Search Bar with Liquid Glass
    @ViewBuilder
    private var simpleiPadSearchBar: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Main search container with glass effect
            HStack(spacing: Theme.Spacing.md) {
                // Search icon with glass vibrancy
                Image(systemName: "magnifyingglass")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .opacity(0.7)
                
                // Enhanced search field with keyboard constraint fix
                TextField("Search by title, author, or ISBN", text: $searchQuery)
                    .font(.title3)
                    .fontWeight(.regular)
                    .textFieldStyle(.plain)
                    .focused($isSearchFieldFocused)
                    .onSubmit {
                        performSearch()
                    }
                    .opacity(searchQuery.isEmpty ? 0.6 : 1.0)
                    .keyboardDismissMode(.onDrag)
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("Done") {
                                isSearchFieldFocused = false
                            }
                        }
                    }
                
                // Clear button with glass effect
                if !searchQuery.isEmpty {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            searchQuery = ""
                            clearSearchResults()
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, Theme.Spacing.xl)
            .padding(.vertical, Theme.Spacing.lg)
            .background {
                // Liquid Glass background
                RoundedRectangle(cornerRadius: 16)
                    .fill(LiquidGlassMaterialLevel.surface.material)
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.primary.opacity(0.1), lineWidth: 0.5)
                    }
                    .shadow(
                        color: .black.opacity(0.04),
                        radius: 8,
                        x: 0,
                        y: 2
                    )
            }
            .scaleEffect(isSearchFieldFocused ? 1.02 : 1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSearchFieldFocused)
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.md)
        .background {
            // Subtle background blur with targeted keyboard dismissal
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .top)
                .onTapGesture {
                    // Dismiss keyboard on search bar background tap for iPad only
                    if UIDevice.current.userInterfaceIdiom == .pad {
                        isSearchFieldFocused = false
                    }
                }
        }
        .keyboardAvoidingLayout()
    }
    
    // MARK: - iPad Prominent Search Bar
    @ViewBuilder
    private var iPadProminentSearchBar: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Main search field with enhanced styling
            HStack(spacing: Theme.Spacing.sm) {
                // Search icon
                Image(systemName: "magnifyingglass")
                    .font(.title2)
                    .foregroundColor(currentTheme.onSurfaceVariant)
                    .scaleEffect(searchQuery.isEmpty ? 1.0 : 0.9)
                    .animation(.easeInOut(duration: 0.2), value: searchQuery.isEmpty)
                
                // Enhanced search field
                TextField("Search by title, author, or ISBN", text: $searchQuery)
                    .font(.title3)
                    .foregroundColor(currentTheme.onSurface)
                    .textFieldStyle(.plain)
                    .focused($isSearchFieldFocused)
                    .onSubmit {
                        performSearch()
                    }
                    .onChange(of: searchQuery) { oldValue, newValue in
                        // Clear results when search query is cleared
                        if newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !oldValue.isEmpty {
                            clearSearchResults()
                        }
                    }
                
                // Clear button for iPad
                if !searchQuery.isEmpty {
                    Button {
                        searchQuery = ""
                        clearSearchResults()
                        HapticFeedbackManager.shared.lightImpact()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(currentTheme.onSurfaceVariant)
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                }
                
                // Search button
                Button {
                    performSearch()
                } label: {
                    Text("Search")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 
                                    currentTheme.outline.opacity(0.3) : currentTheme.primary
                                )
                        )
                }
                .disabled(searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .animation(.easeInOut(duration: 0.2), value: searchQuery.isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(currentTheme.surface)
                    .stroke(
                        isSearchFieldFocused ? currentTheme.primary : currentTheme.outline.opacity(0.2),
                        lineWidth: isSearchFieldFocused ? 2 : 1
                    )
                    .shadow(
                        color: isSearchFieldFocused ? currentTheme.primary.opacity(0.1) : Color.clear,
                        radius: isSearchFieldFocused ? 8 : 0,
                        x: 0,
                        y: 2
                    )
            )
            .animation(.easeInOut(duration: 0.2), value: isSearchFieldFocused)
            
            // Quick filters for iPad
            iPadQuickFilters
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            LinearGradient(
                colors: [currentTheme.background, currentTheme.surface.opacity(0.3)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(currentTheme.outline.opacity(0.2)),
            alignment: .bottom
        )
    }
    
    // MARK: - iPad Quick Filters
    @ViewBuilder
    private var iPadQuickFilters: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Sort selector
            Menu {
                ForEach(BookSearchService.SortOption.allCases) { option in
                    Button {
                        sortOption = option
                        HapticFeedbackManager.shared.mediumImpact()
                        if case .results = searchState, !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            performSearch()
                        }
                    } label: {
                        HStack {
                            Text(option.displayName)
                            if sortOption == option {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: sortOption.systemImage)
                        .font(.callout)
                    Text(sortOption.displayName)
                        .font(.callout)
                        .fontWeight(.medium)
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(currentTheme.primaryContainer.opacity(0.8))
                )
                .foregroundColor(currentTheme.onPrimaryContainer)
            }
            .menuStyle(.borderlessButton)
            
            // Language toggle
            Button {
                includeTranslations.toggle()
                HapticFeedbackManager.shared.lightImpact()
                if case .results = searchState, !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    performSearch()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: includeTranslations ? "globe" : "globe.badge.chevron.backward")
                        .font(.callout)
                    Text(includeTranslations ? "All Languages" : "English Only")
                        .font(.callout)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            includeTranslations ? 
                            currentTheme.tertiaryContainer.opacity(0.8) : 
                            currentTheme.outline.opacity(0.1)
                        )
                )
                .foregroundColor(
                    includeTranslations ? 
                    currentTheme.primary : 
                    currentTheme.onSurfaceVariant
                )
            }
            
            Spacer()
            
            // Results count for iPad
            if case .results(let books) = searchState {
                Text("\(books.count) results")
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundColor(currentTheme.onSurfaceVariant)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(currentTheme.surfaceVariant.opacity(0.5))
                    )
            }
        }
    }
    
    // MARK: - iPad Search Controls Bar with Liquid Glass
    @ViewBuilder
    private var iPadSearchControlsBar: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Sort button with glass capsule
            Button {
                withAnimation(LiquidGlassTheme.FluidAnimation.quick.springAnimation) {
                    showingSortOptions = true
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: sortOption.systemImage)
                        .font(.caption)
                        .fontWeight(.medium)
                    Text(sortOption.displayName)
                        .font(LiquidGlassTheme.typography.labelMedium)
                        .fontWeight(.medium)
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .foregroundStyle(.primary)
                .background {
                    let capsuleShape = Capsule()
                    capsuleShape
                        .fill(LiquidGlassMaterialLevel.surface.material)
                        .overlay {
                            capsuleShape
                                .strokeBorder(.primary.opacity(0.1), lineWidth: 0.5)
                        }
                        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                }
            }
            .accessibilityLabel("Sort by \(sortOption.displayName)")
            .accessibilityHint("Opens sort options menu")
            
            // Translations toggle with enhanced glass effect
            Button {
                withAnimation(LiquidGlassTheme.FluidAnimation.quick.springAnimation) {
                    includeTranslations.toggle()
                }
                // Re-search with new setting - if we have a valid query and previous search attempt
                let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedQuery.isEmpty {
                    switch searchState {
                    case .results, .error:
                        // Add a small delay to ensure state is properly synchronized
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            performSearch()
                        }
                    default:
                        break
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: includeTranslations ? "globe" : "globe.badge.chevron.backward")
                        .font(.caption)
                        .fontWeight(.medium)
                    Text(includeTranslations ? "All Languages" : "English Only")
                        .font(LiquidGlassTheme.typography.labelMedium)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .foregroundStyle(includeTranslations ? .white : .primary)
                .background {
                    let capsuleShape = Capsule()
                    let primaryGradient = LinearGradient(
                        colors: [currentTheme.primary, currentTheme.primary.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    Group {
                        if includeTranslations {
                            capsuleShape.fill(primaryGradient)
                        } else {
                            capsuleShape.fill(.regularMaterial)
                        }
                    }
                    .overlay {
                        if !includeTranslations {
                            capsuleShape.strokeBorder(.primary.opacity(0.1), lineWidth: 0.5)
                        }
                    }
                    .shadow(
                        color: includeTranslations ? currentTheme.primary.opacity(0.2) : .black.opacity(0.08),
                        radius: includeTranslations ? 6 : 4,
                        x: 0,
                        y: includeTranslations ? 3 : 2
                    )
                }
            }
            .accessibilityLabel(includeTranslations ? "Including all languages" : "English only")
            .accessibilityHint("Toggle to include or exclude translated works")
            
            Spacer()
            
            // Results count with liquid glass styling
            if case .results(let books) = searchState {
                Text("\(books.count) results")
                    .font(LiquidGlassTheme.typography.labelSmall)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background {
                        let capsuleShape = Capsule()
                        capsuleShape
                            .fill(LiquidGlassMaterialLevel.background.material)
                            .overlay {
                                capsuleShape.strokeBorder(.secondary.opacity(0.1), lineWidth: 0.5)
                            }
                    }
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.md)
        .background {
            // Liquid glass background with subtle depth
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    .clear,
                                    currentTheme.primary.opacity(0.02)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(.separator.opacity(0.3))
                        .frame(height: 0.5)
                }
        }
    }
    
    // MARK: - iPhone Search Controls Bar - Compact Design
    @ViewBuilder
    private var iPhoneSearchControlsBar: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Compact sort button
            Button {
                showingSortOptions = true
            } label: {
                HStack(spacing: 3) {
                    Image(systemName: sortOption.systemImage)
                        .font(.caption)
                    Text(sortOption.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .foregroundStyle(.primary)
                .background {
                    Capsule()
                        .fill(currentTheme.surfaceVariant)
                        .overlay {
                            Capsule()
                                .strokeBorder(currentTheme.outline.opacity(0.2), lineWidth: 0.5)
                        }
                }
            }
            .accessibilityLabel("Sort by \(sortOption.displayName)")
            
            // Compact translations toggle
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    includeTranslations.toggle()
                }
                // Re-search with new setting
                let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedQuery.isEmpty {
                    switch searchState {
                    case .results, .error:
                        // Add a small delay to ensure state is properly synchronized
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            performSearch()
                        }
                    default:
                        break
                    }
                }
            } label: {
                HStack(spacing: 3) {
                    Image(systemName: includeTranslations ? "globe" : "globe.badge.chevron.backward")
                        .font(.caption)
                    Text(includeTranslations ? "All" : "EN")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .foregroundStyle(includeTranslations ? .white : .primary)
                .background {
                    Capsule()
                        .fill(includeTranslations ? currentTheme.primary : currentTheme.surfaceVariant)
                        .overlay {
                            if !includeTranslations {
                                Capsule()
                                    .strokeBorder(currentTheme.outline.opacity(0.2), lineWidth: 0.5)
                            }
                        }
                }
            }
            .accessibilityLabel(includeTranslations ? "Including all languages" : "English only")
            
            Spacer()
            
            // Compact results count
            if case .results(let books) = searchState {
                Text("\(books.count)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background {
                        Capsule()
                            .fill(currentTheme.surfaceVariant.opacity(0.5))
                    }
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background {
            Rectangle()
                .fill(currentTheme.surface)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(currentTheme.outline.opacity(0.1))
                        .frame(height: 0.5)
                }
        }
    }
    
    // MARK: - Sort Options Sheet
    @ViewBuilder
    private var sortOptionsSheet: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text("Sort Search Results")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(currentTheme.onSurface)
                    
                    Text("Choose how to order your search results")
                        .font(.subheadline)
                        .foregroundColor(currentTheme.onSurfaceVariant)
                }
                .padding(.top, 20)
                .padding(.horizontal, 20)
                
                // Sort options
                LazyVStack(spacing: 0) {
                    ForEach(BookSearchService.SortOption.allCases) { option in
                        Button {
                            // Update the sort option first with explicit state capture
                            let newSortOption = option
                            sortOption = newSortOption
                            showingSortOptions = false
                            
                            HapticFeedbackManager.shared.mediumImpact()
                            
                            // Re-search with new sort option after ensuring state is set
                            let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !trimmedQuery.isEmpty {
                                switch searchState {
                                case .results, .error:
                                    // Ensure we use the captured option value
                                    Task { @MainActor in
                                        performSearch()
                                    }
                                default:
                                    break
                                }
                            }
                        } label: {
                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(currentTheme.primaryContainer)
                                        .frame(width: 40, height: 40)
                                    
                                    Image(systemName: option.systemImage)
                                        .font(.system(size: 18))
                                        .foregroundColor(currentTheme.onPrimaryContainer)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(option.displayName)
                                        .font(.headline)
                                        .foregroundColor(currentTheme.onSurface)
                                    
                                    Text(sortDescription(for: option))
                                        .font(.subheadline)
                                        .foregroundColor(currentTheme.onSurfaceVariant)
                                        .multilineTextAlignment(.leading)
                                }
                                
                                Spacer()
                                
                                if sortOption == option {
                                    Image(systemName: "checkmark")
                                        .font(.headline)
                                        .foregroundColor(currentTheme.primary)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(
                                sortOption == option ? 
                                    currentTheme.primaryContainer.opacity(0.3) : 
                                    Color.clear
                            )
                        }
                        .buttonStyle(.plain)
                        
                        if option != BookSearchService.SortOption.allCases.last {
                            Divider()
                                .padding(.leading, 76)
                        }
                    }
                }
                .padding(.top, 20)
                
                Spacer()
            }
            .background(currentTheme.surface)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingSortOptions = false
                    }
                    .foregroundColor(currentTheme.primary)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
    
    private func sortDescription(for option: BookSearchService.SortOption) -> String {
        switch option {
        case .relevance:
            return "Best matches for your search terms"
        case .newest:
            return "Most recently published books first"
        case .popularity:
            return "Popular and well-known books first"
        }
    }
    
    // MARK: - Search Results List
    @ViewBuilder
    private func searchResultsList(books: [BookMetadata]) -> some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            iPadSearchResultsGrid(books: books)
        } else {
            iPhoneSearchResultsList(books: books)
        }
    }
    
    // MARK: - iPad Grid Layout
    @ViewBuilder
    private func iPadSearchResultsGrid(books: [BookMetadata]) -> some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(.adaptive(minimum: 320, maximum: 400), spacing: Theme.Spacing.md)
                ],
                spacing: Theme.Spacing.md
            ) {
                ForEach(books) { book in
                    NavigationLink(value: book) {
                        iPadSearchResultCard(book: book)
                    }
                    .onTapGesture {
                        HapticFeedbackManager.shared.lightImpact()
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(currentTheme.background)
        .accessibilityLabel("Search results: \(books.count) \(books.count == 1 ? "book" : "books") found, sorted by \(sortOption.displayName.lowercased())")
        .accessibilityHint("Swipe up or down to browse through search results")
    }
    
    // MARK: - iPad Search Result Card
    @ViewBuilder
    private func iPadSearchResultCard(book: BookMetadata) -> some View {
        // Simplified placeholder - use iPhone layout for now
        SearchResultRow(book: book)
    }
    
    // MARK: - iPhone List Layout
    @ViewBuilder
    private func iPhoneSearchResultsList(books: [BookMetadata]) -> some View {
        List(books) { book in
            NavigationLink(value: book) {
                SearchResultRow(book: book)
            }
            .listRowBackground(currentTheme.cardBackground)
            .listRowSeparator(.hidden)
            .padding(.vertical, Theme.Spacing.xs)
        }
        .listStyle(.plain)
        .background(currentTheme.surface)
        .scrollContentBackground(.hidden)
        .accessibilityLabel("Search results: \(books.count) \(books.count == 1 ? "book" : "books") found, sorted by \(sortOption.displayName.lowercased())")
        .accessibilityHint("Swipe up or down to browse through search results")
    }

    // MARK: - Enhanced Empty State for App Store Appeal
    @ViewBuilder
    private var enhancedEmptyState: some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            iPadEnhancedEmptyState
        } else {
            iPhoneEnhancedEmptyState
        }
    }
    
    // MARK: - iPad Empty State with Liquid Glass Depth
    @ViewBuilder
    private var iPadEnhancedEmptyState: some View {
        VStack(spacing: Theme.Spacing.xl) {
            // Hero content with enhanced glass depth
            VStack(spacing: Theme.Spacing.lg) {
                ZStack {
                    // Enhanced backdrop with multiple depth layers
                    Circle()
                        .fill(LiquidGlassMaterialLevel.surface.material)
                        .frame(width: 140, height: 140)
                        .overlay {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            currentTheme.primary.opacity(0.15),
                                            currentTheme.secondary.opacity(0.08)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        .shadow(
                            color: currentTheme.primary.opacity(0.15),
                            radius: 20,
                            x: 0,
                            y: 8
                        )
                        .shadow(
                            color: .black.opacity(0.1),
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                    
                    // Icon with vibrancy effects
                    Image(systemName: "magnifyingglass.circle.fill")
                        .font(.system(size: 64, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [currentTheme.primary, currentTheme.secondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: currentTheme.primary.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                
                VStack(spacing: Theme.Spacing.sm) {
                    Text("Discover Your Next Great Read")
                        .font(LiquidGlassTheme.typography.displaySmall)
                        .fontWeight(.light)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.primary)
                    
                    Text("Search millions of books with smart sorting and powerful filters")
                        .font(LiquidGlassTheme.typography.titleMedium)
                        .fontWeight(.regular)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            }
            
            // Enhanced quick search examples with glass capsules
            VStack(spacing: Theme.Spacing.md) {
                Text("Try these searches:")
                    .font(LiquidGlassTheme.typography.titleSmall)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: Theme.Spacing.md) {
                    ForEach([
                        ("The Great Gatsby", "book.fill"),
                        ("Maya Angelou", "person.fill"),
                        ("9780451524935", "barcode")
                    ], id: \.0) { example, icon in
                        Button {
                            withAnimation(LiquidGlassTheme.FluidAnimation.smooth.springAnimation) {
                                searchQuery = example
                                performSearch()
                            }
                        } label: {
                            HStack(spacing: Theme.Spacing.xs) {
                                Image(systemName: icon)
                                    .font(.callout)
                                    .fontWeight(.medium)
                                Text(example)
                                    .font(LiquidGlassTheme.typography.labelLarge)
                                    .fontWeight(.medium)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .foregroundStyle(.primary)
                            .background {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(LiquidGlassMaterialLevel.elevated.material)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .strokeBorder(
                                                LinearGradient(
                                                    colors: [
                                                        currentTheme.primary.opacity(0.2),
                                                        currentTheme.primary.opacity(0.05)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1
                                            )
                                    }
                                    .shadow(
                                        color: currentTheme.primary.opacity(0.1),
                                        radius: 8,
                                        x: 0,
                                        y: 4
                                    )
                                    .shadow(
                                        color: .black.opacity(0.05),
                                        radius: 2,
                                        x: 0,
                                        y: 1
                                    )
                            }
                        }
                        .buttonStyle(.plain)
                        .scaleEffect(1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: searchQuery)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            // Immersive liquid glass background
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay {
                    LinearGradient(
                        colors: [
                            currentTheme.background.opacity(0.8),
                            currentTheme.surface.opacity(0.4),
                            currentTheme.primary.opacity(0.02)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
        }
        .accessibilityLabel("Search for books")
        .accessibilityHint("Use the search field above to find books by title, author, or ISBN")
    }
    
    // MARK: - iPhone Empty State
    @ViewBuilder
    private var iPhoneEnhancedEmptyState: some View {
        UnifiedHeroSection(config: .init(
            icon: "magnifyingglass.circle.fill",
            title: "Discover Your Next Great Read",
            subtitle: "Search millions of books with smart sorting and find exactly what you're looking for",
            style: .discovery,
            actions: [
                .init(
                    title: "Smart Relevance",
                    icon: "target",
                    description: "Find the most relevant results for your search"
                ) {},
                .init(
                    title: "Sort by Popularity",
                    icon: "star.fill",
                    description: "Discover trending and highly-rated books"
                ) {},
                .init(
                    title: "All Languages",
                    icon: "globe",
                    description: "Include translated works from around the world"
                ) {}
            ]
        ))
        .accessibilityLabel("Search for books")
        .accessibilityHint("Use the search field above to find books by title, author, or ISBN")
    }
    
    
    // MARK: - Enhanced No Results State
    @ViewBuilder
    private var noResultsState: some View {
        UnifiedHeroSection(config: .init(
            icon: "questionmark.circle.fill",
            title: "No Results Found",
            subtitle: "Try different search terms or check your spelling. You can also try including translated works.",
            style: .error,
            actions: [
                .init(
                    title: "Book titles",
                    icon: "book.fill",
                    description: "Try \"The Great Gatsby\""
                ) {
                    searchQuery = "The Great Gatsby"
                    performSearch()
                },
                .init(
                    title: "Author names",
                    icon: "person.fill",
                    description: "Try \"Maya Angelou\""
                ) {
                    searchQuery = "Maya Angelou"
                    performSearch()
                },
                .init(
                    title: "ISBN numbers",
                    icon: "barcode",
                    description: "Try \"9780451524935\""
                ) {
                    searchQuery = "9780451524935"
                    performSearch()
                }
            ]
        ))
        .accessibilityLabel("No search results found")
        .accessibilityHint("Try different search terms or check spelling")
    }
    
    
    // MARK: - Actions
    
    private func performSearch() {
        let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return }
        
        searchState = .searching
        
        // Add haptic feedback - respect VoiceOver and Reduce Motion
        HapticFeedbackManager.shared.lightImpact()
        
        Task {
            let result = await searchService.search(
                query: trimmedQuery,
                sortBy: sortOption,
                includeTranslations: includeTranslations
            )
            await MainActor.run {
                switch result {
                case .success(let books):
                    searchState = .results(books)
                    HapticFeedbackManager.shared.success()
                case .failure(let error):
                    searchState = .error(formatError(error))
                    HapticFeedbackManager.shared.error()
                }
            }
        }
    }
    
    private func clearSearch() {
        searchQuery = ""
        searchState = .idle
        sortOption = .relevance
        includeTranslations = false
        HapticFeedbackManager.shared.lightImpact()
    }
    
    private func clearSearchResults() {
        // Clear search results and return to discovery state
        searchState = .idle
        HapticFeedbackManager.shared.lightImpact()
    }
    
    private func formatError(_ error: Error) -> String {
        // Provide user-friendly error messages
        if error.localizedDescription.contains("network") || error.localizedDescription.contains("internet") {
            return "Please check your internet connection and try again."
        } else if error.localizedDescription.contains("timeout") {
            return "The search took too long. Please try again."
        } else {
            return "Something went wrong. Please try again later."
        }
    }
    
    private func retrySearch() {
        // Enhanced retry logic that validates state before attempting search
        let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // If query is empty, reset to idle state instead of attempting search
        guard !trimmedQuery.isEmpty else {
            searchState = .idle
            HapticFeedbackManager.shared.lightImpact()
            return
        }
        
        // Clear any existing error state and retry
        searchState = .searching
        HapticFeedbackManager.shared.lightImpact()
        
        // Add a small delay to prevent rapid retry attempts
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            await performSearchWithRetry()
        }
    }
    
    private func performSearchWithRetry() async {
        let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Double-check query is still valid
        guard !trimmedQuery.isEmpty else {
            await MainActor.run {
                searchState = .idle
            }
            return
        }
        
        let result = await searchService.search(
            query: trimmedQuery,
            sortBy: sortOption,
            includeTranslations: includeTranslations
        )
        
        await MainActor.run {
            switch result {
            case .success(let books):
                searchState = .results(books)
                HapticFeedbackManager.shared.success()
            case .failure(let error):
                searchState = .error(formatError(error))
                HapticFeedbackManager.shared.error()
            }
        }
    }
    
    // MARK: - Barcode Scanning Integration
    
    private func handleBarcodeSearchCompleted(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let query = userInfo["query"] as? String,
              let results = userInfo["results"] as? [BookMetadata],
              let fromBarcode = userInfo["fromBarcodeScanner"] as? Bool,
              fromBarcode else {
            return
        }
        
        // Update search state with barcode results
        searchQuery = query
        fromBarcodeScanner = true
        
        if results.isEmpty {
            searchState = .error("No books found for the scanned ISBN. Try searching by title or author instead.")
        } else {
            searchState = .results(results)
            HapticFeedbackManager.shared.success()
        }
    }
    
    private func handleBarcodeSearchError(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let query = userInfo["query"] as? String,
              let errorMessage = userInfo["error"] as? String,
              let fromBarcode = userInfo["fromBarcodeScanner"] as? Bool,
              fromBarcode else {
            return
        }
        
        // Update search state with error
        searchQuery = query
        fromBarcodeScanner = true
        searchState = .error("Barcode search failed: \(errorMessage)")
        HapticFeedbackManager.shared.error()
    }
}


// MARK: - Search Result Row (Enhanced)
struct SearchResultRow: View {
    @Environment(\.unifiedThemeStore) private var themeStore
    let book: BookMetadata
    @State private var isImageLoading = true
    
    // Legacy theme access for compatibility during migration
    private var currentTheme: AppColorTheme {
        themeStore.appTheme
    }
    
    // Liquid Glass theme colors
    private var primaryColor: Color {
        if let liquidVariant = themeStore.currentTheme.liquidGlassVariant {
            return liquidVariant.colorDefinition.primary.color
        } else {
            return themeStore.appTheme.primaryAction
        }
    }
    
    private var secondaryColor: Color {
        if let liquidVariant = themeStore.currentTheme.liquidGlassVariant {
            return liquidVariant.colorDefinition.secondary.color
        } else {
            return themeStore.appTheme.secondary
        }
    }

    var body: some View {
        Group {
            if themeStore.currentTheme.isLiquidGlass {
                liquidGlassImplementation
            } else {
                materialDesignImplementation
            }
        }
    }
    
    // MARK: - iOS 26 Liquid Glass Implementation
    @ViewBuilder
    private var liquidGlassImplementation: some View {
        HStack(spacing: Theme.Spacing.lg) { // Increased spacing between cover and content
            ZStack {
                BookCoverImage(
                    imageURL: book.imageURL?.absoluteString, 
                    width: 65, // Larger cover for better presence
                    height: 95
                )
                .optimizedLiquidGlassCard(
                    material: .regular,
                    depth: .elevated, // Enhanced depth for better presence
                    radius: .comfortable, // More rounded for modern look
                    vibrancy: .medium
                )
                .shadow(
                    color: primaryColor.opacity(0.15), // Stronger colored shadow
                    radius: 8,
                    x: 0,
                    y: 4
                )
                
                // Enhanced loading shimmer for Liquid Glass
                if isImageLoading {
                    RoundedRectangle(cornerRadius: 8) // Increased radius
                        .fill(.thinMaterial)
                        .overlay {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            primaryColor.opacity(0.15),
                                            primaryColor.opacity(0.08)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        .frame(width: 65, height: 95)
                        .liquidGlassShimmer()
                }
            }
            
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) { // More breathing room
                // Enhanced title with better hierarchy
                Text(book.title)
                    .font(.system(size: 17, weight: .semibold, design: .default))
                    .tracking(0.3) // iOS 26 enhanced letter spacing for clarity
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // Enhanced author styling
                Text(book.authors.joined(separator: ", "))
                    .font(.system(size: 15, weight: .medium, design: .default))
                    .tracking(0.15) // Subtle letter spacing for readability
                    .foregroundStyle(secondaryColor)
                    .lineLimit(1)
                
                // Clean minimal metadata - text only, no backgrounds
                HStack(spacing: Theme.Spacing.sm) {
                    if let publishedYear = extractYear(from: book.publishedDate) {
                        Text(publishedYear)
                            .font(.system(size: 12, weight: .regular, design: .default))
                            .foregroundStyle(.tertiary)
                    }
                    
                    if book.pageCount != nil && extractYear(from: book.publishedDate) != nil {
                        Text("•")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(.tertiary)
                    }
                    
                    if let pageCount = book.pageCount {
                        Text("\(pageCount) pages")
                            .font(.system(size: 12, weight: .regular, design: .default))
                            .foregroundStyle(.tertiary)
                    }
                    
                    Spacer()
                    
                    // Simple quality indicator
                    if book.imageURL != nil {
                        Circle()
                            .fill(.tertiary)
                            .frame(width: 4, height: 4)
                    }
                    
                    Spacer()
                }
                .font(LiquidGlassTheme.typography.labelSmall)
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Liquid Glass chevron with enhanced styling
            Image(systemName: "chevron.right")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(secondaryColor.opacity(0.6))
                .padding(8)
                .background {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .overlay {
                            Circle()
                                .fill(primaryColor.opacity(0.05))
                        }
                        .shadow(
                            color: primaryColor.opacity(0.1),
                            radius: 2,
                            x: 0,
                            y: 1
                        )
                }
        }
        .padding(.vertical, Theme.Spacing.sm)
        .onAppear {
            // Simulate image loading completion
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let animation = UIAccessibility.isReduceMotionEnabled ? 
                    Animation.linear(duration: 0.1) : Animation.easeOut(duration: 0.3)
                withAnimation(animation) {
                    isImageLoading = false
                }
            }
        }
    }
    
    @ViewBuilder
    private func liquidGlassMetadataLabel(text: String, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(secondaryColor.opacity(0.7))
            Text(text)
                .font(LiquidGlassTheme.typography.labelSmall)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay {
                    Capsule()
                        .strokeBorder(.secondary.opacity(0.1), lineWidth: 0.5)
                }
        }
    }
    
    // Enhanced metadata label with better visual presence
    private func enhancedLiquidGlassMetadataLabel(text: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            primaryColor.opacity(0.8),
                            primaryColor.opacity(0.5)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Text(text)
                .font(.system(size: 13, weight: .medium, design: .default))
                .foregroundStyle(.secondary)
                .tracking(0.1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.thinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    primaryColor.opacity(0.15),
                                    primaryColor.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                }
        }
    }
    
    // MARK: - Material Design Legacy Implementation
    @ViewBuilder
    private var materialDesignImplementation: some View {
        HStack(spacing: Theme.Spacing.md) {
            ZStack {
                BookCoverImage(
                    imageURL: book.imageURL?.absoluteString, 
                    width: 50, 
                    height: 70
                )
                
                // Loading shimmer effect for book cover
                if isImageLoading {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(currentTheme.outline.opacity(0.3))
                        .frame(width: 50, height: 70)
                        .shimmer()
                }
            }
            .onAppear {
                // Simulate image loading completion
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    let animation = UIAccessibility.isReduceMotionEnabled ? 
                        Animation.linear(duration: 0.1) : Animation.easeOut(duration: 0.3)
                    withAnimation(animation) {
                        isImageLoading = false
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(book.title)
                    .titleMedium()
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text(book.authors.joined(separator: ", "))
                    .bodyMedium()
                    .foregroundStyle(currentTheme.secondaryText)
                    .lineLimit(1)
                
                HStack(spacing: Theme.Spacing.md) {
                    if let publishedYear = extractYear(from: book.publishedDate) {
                        Label(publishedYear, systemImage: "calendar")
                            .labelSmall()
                            .foregroundStyle(currentTheme.secondaryText)
                    }
                    
                    if let pageCount = book.pageCount {
                        Label("\(pageCount) pages", systemImage: "doc.text")
                            .labelSmall()
                            .foregroundStyle(currentTheme.secondaryText)
                    }
                    
                    // Quality indicators
                    if book.imageURL != nil {
                        Image(systemName: "photo")
                            .font(.caption2)
                            .foregroundStyle(currentTheme.tertiary)
                    }
                    
                    if book.bookDescription != nil && !book.bookDescription!.isEmpty {
                        Image(systemName: "text.alignleft")
                            .font(.caption2)
                            .foregroundStyle(currentTheme.tertiary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, Theme.Spacing.xs)
        .frame(minHeight: 44)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(book.title) by \(book.authors.joined(separator: ", "))")
        .accessibilityHint("Double tap to view book details")
        .accessibilityIdentifier("SearchResultRow_\(book.googleBooksID)")
    }
    
    // Helper function to extract year from various date formats
    private func extractYear(from dateString: String?) -> String? {
        guard let dateString = dateString, !dateString.isEmpty else { return nil }
        
        // If it's already just a year (4 digits), return as-is
        if dateString.count == 4, Int(dateString) != nil {
            return dateString
        }
        
        // Extract first 4 characters as year from formats like "2011-10-18"
        if dateString.count >= 4 {
            let yearSubstring = String(dateString.prefix(4))
            if Int(yearSubstring) != nil {
                return yearSubstring
            }
        }
        
        // Fallback: return the original string if we can't parse it
        return dateString
    }
}

// MARK: - Shimmer Effect Extension
extension View {
    func shimmer() -> some View {
        self.modifier(ShimmerModifier())
    }
    
    func liquidGlassShimmer() -> some View {
        self.modifier(LiquidGlassShimmerModifier())
    }
}

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.clear, Color.white.opacity(0.3), Color.clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .rotationEffect(.degrees(30))
                    .offset(x: phase)
                    .clipped()
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 200
                }
            }
    }
}

struct LiquidGlassShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.white.opacity(0.4),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .rotationEffect(.degrees(30))
                    .offset(x: phase)
                    .clipped()
            )
            .onAppear {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    phase = 200
                }
            }
    }
}

#Preview {
    SearchView()
        .modelContainer(for: [UserBook.self, BookMetadata.self], inMemory: true)
        .environment(\.unifiedThemeStore, UnifiedThemeStore())
        .preferredColorScheme(.dark)
        .onAppear {
            // Mark as migrated in preview for testing
            MigrationTracker.shared.markViewAsMigrated("SearchView")
        }
}