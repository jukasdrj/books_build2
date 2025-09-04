import SwiftUI

struct AuthorSearchResultsView: View {
    @Environment(\.unifiedThemeStore) private var themeStore
    
    // Legacy theme access for compatibility during migration
    private var currentTheme: AppColorTheme {
        themeStore.appTheme
    }
    let authorName: String
    
    @State private var searchState: SearchState = .searching
    @State private var searchService = BookSearchService.shared
    @State private var sortOption: BookSearchService.SortOption = .relevance
    @State private var showingSortOptions = false
    
    enum SearchState: Equatable {
        case searching
        case results([BookMetadata])
        case error(String)
        
        static func == (lhs: SearchState, rhs: SearchState) -> Bool {
            switch (lhs, rhs) {
            case (.searching, .searching):
                return true
            case (.results(let lhsBooks), .results(let rhsBooks)):
                return lhsBooks.map(\.googleBooksID) == rhsBooks.map(\.googleBooksID)
            case (.error(let lhsMessage), .error(let rhsMessage)):
                return lhsMessage == rhsMessage
            default:
                return false
            }
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
        .onAppear {
            MigrationTracker.shared.markViewAsAccessed("AuthorSearchResultsView")
            MigrationTracker.shared.markViewAsMigrated("AuthorSearchResultsView")
        }
    }
    
    // MARK: - iOS 26 Liquid Glass Implementation
    @ViewBuilder
    private var liquidGlassImplementation: some View {
        VStack(spacing: 0) {
            // Enhanced search controls with Liquid Glass styling
            if case .results(let books) = searchState, !books.isEmpty {
                liquidGlassSearchControlsBar
            }
            
            // Content area with immersive glass backgrounds
            Group {
                switch searchState {
                case .searching:
                    UnifiedLoadingState(config: .init(
                        message: "Searching books by \(authorName)",
                        subtitle: "Using smart relevance sorting",
                        style: .spinner
                    ))
                    .task(id: authorName) {
                        await performAuthorSearch()
                    }
                    
                case .results(let items):
                    if items.isEmpty {
                        liquidGlassAuthorNotFoundState
                    } else {
                        liquidGlassSearchResultsList(books: items)
                    }
                    
                case .error(let message):
                    UnifiedErrorState(config: .init(
                        title: "Search Error",
                        message: message,
                        retryAction: {
                            Task {
                                await performAuthorSearch()
                            }
                        },
                        style: .standard
                    ))
                }
            }
            .liquidGlassBackground(
                material: .ultraThin,
                vibrancy: .subtle
            )
            .liquidGlassTransition(value: searchState, animation: .smooth)
        }
        .navigationTitle("Books by \(authorName)")
        .navigationBarTitleDisplayMode(.large)
        .liquidGlassNavigation(material: .regular, vibrancy: .medium)
        .liquidGlassModal(isPresented: $showingSortOptions) {
            liquidGlassSortOptionsSheet
        }
    }
    
    // MARK: - Material Design Legacy Implementation (Backward Compatibility)
    @ViewBuilder
    private var materialDesignImplementation: some View {
        VStack(spacing: 0) {
            // Search Controls (similar to SearchView)
            if case .results(let books) = searchState, !books.isEmpty {
                searchControlsBar
            }
            
            // Content Area
            Group {
                switch searchState {
                case .searching:
                    UnifiedLoadingState(config: .init(
                        message: "Searching books by \(authorName)",
                        subtitle: "Using smart relevance sorting",
                        style: .spinner
                    ))
                        .task(id: authorName) {
                            await performAuthorSearch()
                        }
                        
                case .results(let items):
                    if items.isEmpty {
                        authorNotFoundState
                    } else {
                        searchResultsList(books: items)
                    }
                    
                case .error(let message):
                    UnifiedErrorState(config: .init(
                        title: "Search Error",
                        message: message,
                        retryAction: {
                            Task {
                                await performAuthorSearch()
                            }
                        },
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
        .navigationTitle("Books by \(authorName)")
        .navigationBarTitleDisplayMode(.large)
        .background(currentTheme.background)
        .sheet(isPresented: $showingSortOptions) {
            sortOptionsSheet
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
    
    // MARK: - Liquid Glass Search Controls Bar
    @ViewBuilder
    private var liquidGlassSearchControlsBar: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Enhanced sort button with liquid glass styling
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
                    Capsule()
                        .fill(.regularMaterial)
                        .overlay {
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            primaryColor.opacity(0.15),
                                            primaryColor.opacity(0.05)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        .overlay {
                            Capsule()
                                .strokeBorder(primaryColor.opacity(0.2), lineWidth: 1)
                        }
                        .shadow(color: primaryColor.opacity(0.1), radius: 6, x: 0, y: 3)
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                }
            }
            .accessibilityLabel("Sort by \(sortOption.displayName)")
            .accessibilityHint("Opens sort options menu")
            
            Spacer()
            
            // Enhanced results count with liquid glass styling
            if case .results(let books) = searchState {
                Text("\(books.count) books")
                    .font(LiquidGlassTheme.typography.labelSmall)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background {
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .overlay {
                                Capsule()
                                    .strokeBorder(.secondary.opacity(0.1), lineWidth: 0.5)
                            }
                            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    }
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.md)
        .background {
            Rectangle()
                .fill(.regularMaterial)
                .overlay {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    .clear,
                                    primaryColor.opacity(0.02)
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
    
    // MARK: - Liquid Glass Sort Options Sheet
    @ViewBuilder
    private var liquidGlassSortOptionsSheet: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Enhanced header with liquid glass styling
                VStack(spacing: 8) {
                    Text("Sort \(authorName)'s Books")
                        .font(LiquidGlassTheme.typography.titleLarge)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Text("Choose how to order the search results")
                        .font(LiquidGlassTheme.typography.bodyMedium)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 20)
                .padding(.horizontal, 20)
                
                // Enhanced sort options with liquid glass styling
                LazyVStack(spacing: 0) {
                    ForEach(BookSearchService.SortOption.allCases) { option in
                        Button {
                            sortOption = option
                            showingSortOptions = false
                            HapticFeedbackManager.shared.mediumImpact()
                            
                            // Re-search with new sort option
                            if case .results = searchState {
                                Task {
                                    await performAuthorSearch()
                                }
                            }
                        } label: {
                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(.regularMaterial)
                                        .overlay {
                                            Circle()
                                                .fill(
                                                    RadialGradient(
                                                        colors: [
                                                            primaryColor.opacity(0.2),
                                                            primaryColor.opacity(0.05)
                                                        ],
                                                        center: .center,
                                                        startRadius: 2,
                                                        endRadius: 20
                                                    )
                                                )
                                        }
                                        .overlay {
                                            Circle()
                                                .strokeBorder(primaryColor.opacity(0.2), lineWidth: 1)
                                        }
                                        .shadow(color: primaryColor.opacity(0.1), radius: 4, x: 0, y: 2)
                                        .frame(width: 40, height: 40)
                                    
                                    Image(systemName: option.systemImage)
                                        .font(.system(size: 18))
                                        .foregroundStyle(primaryColor)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(option.displayName)
                                        .font(LiquidGlassTheme.typography.titleSmall)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.primary)
                                    
                                    Text(sortDescription(for: option))
                                        .font(LiquidGlassTheme.typography.bodySmall)
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.leading)
                                }
                                
                                Spacer()
                                
                                if sortOption == option {
                                    ZStack {
                                        Circle()
                                            .fill(primaryColor.opacity(0.15))
                                            .frame(width: 24, height: 24)
                                        
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(primaryColor)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background {
                                if sortOption == option {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(.thinMaterial)
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .fill(
                                                    LinearGradient(
                                                        colors: [
                                                            primaryColor.opacity(0.1),
                                                            primaryColor.opacity(0.03)
                                                        ],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                        }
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .strokeBorder(primaryColor.opacity(0.2), lineWidth: 1)
                                        }
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        
                        if option != BookSearchService.SortOption.allCases.last {
                            Divider()
                                .padding(.leading, 76)
                                .opacity(0.5)
                        }
                    }
                }
                .padding(.top, 20)
                
                Spacer()
            }
            .liquidGlassBackground(material: .regular, vibrancy: .medium)
            .liquidGlassNavigation(material: .thin, vibrancy: .medium)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingSortOptions = false
                    }
                    .foregroundStyle(primaryColor)
                    .font(LiquidGlassTheme.typography.labelLarge)
                    .fontWeight(.medium)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Liquid Glass Search Results List
    @ViewBuilder
    private func liquidGlassSearchResultsList(books: [BookMetadata]) -> some View {
        List(books) { book in
            NavigationLink(value: book) {
                SearchResultRow(book: book)
            }
            .listRowBackground(
                RoundedRectangle(cornerRadius: 8)
                    .liquidGlassCard(
                        material: .regular,
                        depth: .floating,
                        radius: .compact,
                        vibrancy: .medium
                    )
            )
            .listRowSeparator(.hidden)
            .padding(.vertical, Theme.Spacing.xs)
        }
        .listStyle(.plain)
        .liquidGlassBackground(
            material: .ultraThin,
            vibrancy: .subtle
        )
        .scrollContentBackground(.hidden)
        .accessibilityLabel("\(books.count) books by \(authorName) sorted by \(sortOption.displayName)")
    }
    
    // MARK: - Liquid Glass Author Not Found State
    @ViewBuilder
    private var liquidGlassAuthorNotFoundState: some View {
        UnifiedHeroSection(config: .init(
            icon: "person.circle.fill",
            title: "No Books Found",
            subtitle: "We couldn't find any books by \"\(authorName)\" in our database.",
            style: .error,
            actions: [
                .init(
                    title: "Check Spelling",
                    icon: "textformat.abc",
                    description: "Verify the author's name spelling"
                ) {},
                .init(
                    title: "Try Individual Names",
                    icon: "person.2.fill",
                    description: "Search for individual names if it's a multi-author work"
                ) {}
            ]
        ))
        .liquidGlassBackground(
            material: .ultraThin,
            vibrancy: .subtle
        )
        .accessibilityLabel("No books found by \(authorName)")
        .accessibilityHint("Try checking the spelling or search for a different author")
    }
    
    // MARK: - Search Controls Bar
    @ViewBuilder
    private var searchControlsBar: some View {
        HStack(spacing: 12) {
            // Sort button
            Button {
                showingSortOptions = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: sortOption.systemImage)
                        .font(.caption)
                    Text(sortOption.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(currentTheme.primaryContainer)
                .foregroundColor(currentTheme.onPrimaryContainer)
                .cornerRadius(16)
            }
            .accessibilityLabel("Sort by \(sortOption.displayName)")
            .accessibilityHint("Opens sort options menu")
            
            Spacer()
            
            // Results count
            if case .results(let books) = searchState {
                Text("\(books.count) books")
                    .font(.caption)
                    .foregroundColor(currentTheme.onSurfaceVariant)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(currentTheme.surface)
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(currentTheme.outline.opacity(0.2)),
            alignment: .bottom
        )
    }
    
    // MARK: - Sort Options Sheet
    @ViewBuilder
    private var sortOptionsSheet: some View {
        VStack(spacing: 0) {
            // Header with Close button
            HStack {
                Text("Sort \(authorName)'s Books")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(currentTheme.onSurface)
                
                Spacer()
                
                Button("Done") {
                    showingSortOptions = false
                }
                .foregroundColor(currentTheme.primary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            Text("Choose how to order the search results")
                .font(.subheadline)
                .foregroundColor(currentTheme.onSurfaceVariant)
                .padding(.horizontal, 20)
                .padding(.top, 8)
            
            // Sort options
            VStack(spacing: 0) {
                    ForEach(BookSearchService.SortOption.allCases) { option in
                        Button {
                            sortOption = option
                            showingSortOptions = false
                            HapticFeedbackManager.shared.mediumImpact()
                            
                            // Re-search with new sort option
                            if case .results = searchState {
                                Task {
                                    await performAuthorSearch()
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
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
    
    private func sortDescription(for option: BookSearchService.SortOption) -> String {
        switch option {
        case .relevance:
            return "Best matches for this author"
        case .newest:
            return "Most recently published books first"
        case .popularity:
            return "Popular and well-known books first"
        }
    }
    
    // MARK: - Search Results List
    @ViewBuilder
    private func searchResultsList(books: [BookMetadata]) -> some View {
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
        .accessibilityLabel("\(books.count) books by \(authorName) sorted by \(sortOption.displayName)")
    }
    
    // MARK: - Author Not Found State
    @ViewBuilder
    private var authorNotFoundState: some View {
        UnifiedHeroSection(config: .init(
            icon: "person.circle.fill",
            title: "No Books Found",
            subtitle: "We couldn't find any books by \"\(authorName)\" in our database.",
            style: .error,
            actions: [
                .init(
                    title: "Check Spelling",
                    icon: "textformat.abc",
                    description: "Verify the author's name spelling"
                ) {},
                .init(
                    title: "Try Individual Names",
                    icon: "person.2.fill",
                    description: "Search for individual names if it's a multi-author work"
                ) {}
            ]
        ))
        .accessibilityLabel("No books found by \(authorName)")
        .accessibilityHint("Try checking the spelling or search for a different author")
    }
    
    // MARK: - Search Function
    private func performAuthorSearch() async {
        searchState = .searching
        
        // Use the dedicated author search method for proper proxy API formatting
        let result = await searchService.searchByAuthor(
            authorName,
            sortBy: sortOption,
            maxResults: 40,
            includeTranslations: true
        )
        
        await MainActor.run {
            switch result {
            case .success(let books):
                // Filter results to ensure they actually match the author
                let filteredBooks = books.filter { book in
                    book.authors.contains { author in
                        author.localizedCaseInsensitiveContains(authorName) ||
                        authorName.localizedCaseInsensitiveContains(author)
                    }
                }
                searchState = .results(filteredBooks)
                HapticFeedbackManager.shared.success()
                
            case .failure(let error):
                searchState = .error(formatError(error))
                HapticFeedbackManager.shared.error()
            }
        }
    }
    
    private func formatError(_ error: Error) -> String {
        if error.localizedDescription.contains("network") || error.localizedDescription.contains("internet") {
            return "Please check your internet connection and try again."
        } else if error.localizedDescription.contains("timeout") {
            return "The search took too long. Please try again."
        } else {
            return "Something went wrong searching for \(authorName)'s books. Please try again later."
        }
    }
}