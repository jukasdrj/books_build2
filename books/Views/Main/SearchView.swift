import SwiftUI
import SwiftData

struct SearchView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appTheme) private var currentTheme
    
    @State private var searchService = BookSearchService.shared
    @State private var searchQuery = ""
    @State private var searchState: SearchState = .idle
    @State private var sortOption: BookSearchService.SortOption = .relevance
    @State private var showingSortOptions = false
    @State private var includeTranslations = true
    @State private var fromBarcodeScanner = false
    @FocusState private var isSearchFieldFocused: Bool
    

    enum SearchState: Equatable {
        case idle
        case searching
        case results([BookMetadata])
        case error(String)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar for iPad
            if UIDevice.current.userInterfaceIdiom == .pad {
                simpleiPadSearchBar
            }
            
            // Search Controls
            if case .results(let books) = searchState, !books.isEmpty {
                searchControlsBar
            }
            
            // Content Area with enhanced empty state
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
                .background(
                    LinearGradient(
                        colors: [
                            currentTheme.background,
                            currentTheme.surface.opacity(0.5)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .animation(Theme.Animation.accessible, value: searchState)
            }
            .background(currentTheme.background)
            .keyboardAvoidingLayout() // Prevent keyboard constraint conflicts
            .if(UIDevice.current.userInterfaceIdiom != .pad) { view in
                view.searchable(text: $searchQuery, prompt: "Search by title, author, or ISBN") {
                    // Search suggestions appear properly below the search field
                    if searchQuery.isEmpty {
                        Text("\"The Great Gatsby\"").searchCompletion("The Great Gatsby")
                        Text("\"Maya Angelou\"").searchCompletion("Maya Angelou") 
                        Text("\"9780451524935\"").searchCompletion("9780451524935")
                    }
                }
                .keyboardToolbar() // Add Done button to prevent constraint conflicts
            }
            .accessibilityLabel("Search for books")
            .accessibilityHint("Enter a book title, author name, or ISBN to search for books in the online database")
            .onSubmit(of: .search) {
                performSearch()
            }
            .onChange(of: searchQuery) { oldValue, newValue in
                // Clear results when search query is cleared
                if newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !oldValue.isEmpty {
                    clearSearchResults()
                }
            }
            .sheet(isPresented: $showingSortOptions) {
                sortOptionsSheet
            }
            .onReceive(NotificationCenter.default.publisher(for: .barcodeSearchCompleted)) { notification in
                handleBarcodeSearchCompleted(notification)
            }
            .onReceive(NotificationCenter.default.publisher(for: .barcodeSearchError)) { notification in
                handleBarcodeSearchError(notification)
            }
            .onAppear {
                // Reset search state when view appears to ensure clean state
                if case .error = searchState {
                    searchState = .idle
                }
            }
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
                    .fill(.regularMaterial)
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
            // Subtle background blur
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .top)
        }
        .keyboardAvoidingLayout()
        .onTapGesture {
            // Dismiss keyboard on background tap for iPad
            if UIDevice.current.userInterfaceIdiom == .pad {
                isSearchFieldFocused = false
            }
        }
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
    
    // MARK: - Search Controls Bar with Liquid Glass
    @ViewBuilder
    private var searchControlsBar: some View {
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
                        .fill(.regularMaterial)
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
                        performSearch()
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
                            .fill(.ultraThinMaterial)
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
                            sortOption = option
                            showingSortOptions = false
                            HapticFeedbackManager.shared.mediumImpact()
                            
                            // Re-search with new sort option - if we have a valid query and previous search attempt
                            let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !trimmedQuery.isEmpty {
                                switch searchState {
                                case .results, .error:
                                    performSearch()
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
        // Use iPhone layout for now (working implementation)
        iPhoneSearchResultsList(books: books)
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
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(currentTheme.background)
        .accessibilityLabel("\(books.count) search results sorted by \(sortOption.displayName)")
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
        .accessibilityLabel("\(books.count) search results sorted by \(sortOption.displayName)")
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
                        .fill(.regularMaterial)
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
                                    .fill(.thinMaterial)
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
        includeTranslations = true
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
    @Environment(\.appTheme) private var currentTheme
    let book: BookMetadata
    @State private var isImageLoading = true

    var body: some View {
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
                    if let publishedYear = self.extractYear(from: book.publishedDate) {
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

#Preview {
    SearchView()
        .modelContainer(for: [UserBook.self, BookMetadata.self], inMemory: true)
        .preferredColorScheme(.dark)
}