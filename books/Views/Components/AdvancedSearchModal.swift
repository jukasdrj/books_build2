//
//  AdvancedSearchModal.swift
//  books
//
//  iOS 26 Enhanced Advanced Search Interface
//  Multi-criteria search with intelligent suggestions and progressive enhancement
//

import SwiftUI
import SwiftData

struct AdvancedSearchModal: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.unifiedThemeStore) private var themeStore
    @Environment(\.modelContext) private var modelContext
    @Environment(\.searchHistory) private var searchHistory
    @Environment(\.searchDebouncer) private var searchDebouncer
    
    // Search criteria
    @State private var searchQuery = ""
    @State private var selectedAuthors: Set<String> = []
    @State private var selectedGenres: Set<String> = []
    @State private var selectedLanguages: Set<String> = []
    @State private var publishedYearRange: ClosedRange<Int>?
    @State private var pageCountRange: ClosedRange<Int>?
    @State private var ratingRange: ClosedRange<Double> = 0.0...5.0
    @State private var includeUnratedBooks = true
    @State private var sortOption: BookSearchService.SortOption = .relevance
    @State private var includeTranslations = true
    
    // UI State
    @State private var activeSection: SearchSection = .query
    @State private var searchResults: [BookMetadata] = []
    @State private var isSearching = false
    @State private var showingSuggestions = false
    @FocusState private var isSearchFieldFocused: Bool
    
    // Results
    let onSearchComplete: ([BookMetadata], AdvancedSearchCriteria) -> Void
    
    // Legacy theme access
    private var currentTheme: AppColorTheme {
        themeStore.appTheme
    }
    
    // iOS 26 Liquid Glass theme colors
    private var primaryColor: Color {
        if let liquidVariant = themeStore.currentTheme.liquidGlassVariant {
            return liquidVariant.colorDefinition.primary.color
        } else {
            return themeStore.appTheme.primaryAction
        }
    }
    
    enum SearchSection: String, CaseIterable, Identifiable {
        case query = "Query"
        case filters = "Filters"
        case sorting = "Sorting"
        case results = "Results"
        
        var id: String { rawValue }
        
        var systemImage: String {
            switch self {
            case .query: return "magnifyingglass"
            case .filters: return "line.3.horizontal.decrease.circle"
            case .sorting: return "arrow.up.arrow.down"
            case .results: return "list.bullet"
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
            // Auto-focus search field for immediate interaction
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isSearchFieldFocused = true
            }
        }
    }
    
    // MARK: - iOS 26 Liquid Glass Implementation
    @ViewBuilder
    private var liquidGlassImplementation: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Enhanced section picker with glass effects
                liquidGlassSectionPicker
                
                // Dynamic content based on active section
                ScrollView {
                    LazyVStack(spacing: Theme.Spacing.lg) {
                        switch activeSection {
                        case .query:
                            liquidGlassQuerySection
                        case .filters:
                            liquidGlassFiltersSection
                        case .sorting:
                            liquidGlassSortingSection
                        case .results:
                            liquidGlassResultsSection
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.vertical, Theme.Spacing.md)
                }
                .background {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .overlay {
                            LinearGradient(
                                colors: [
                                    .clear,
                                    primaryColor.opacity(0.02)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        }
                }
                
                // Action buttons with enhanced glass styling
                liquidGlassActionButtons
            }
            .navigationTitle("Advanced Search")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.primary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear All") {
                        clearAllCriteria()
                    }
                    .foregroundStyle(primaryColor)
                    .disabled(!hasAnyCriteria)
                }
            }
        }
        .progressiveGlassEffect(
            material: .ultraThinMaterial,
            level: .optimized
        )
    }
    
    // MARK: - Material Design Implementation
    @ViewBuilder
    private var materialDesignImplementation: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Section picker
                materialDesignSectionPicker
                
                // Content
                ScrollView {
                    VStack(spacing: Theme.Spacing.lg) {
                        switch activeSection {
                        case .query:
                            materialDesignQuerySection
                        case .filters:
                            materialDesignFiltersSection
                        case .sorting:
                            materialDesignSortingSection
                        case .results:
                            materialDesignResultsSection
                        }
                    }
                    .padding(Theme.Spacing.lg)
                }
                
                // Action buttons
                materialDesignActionButtons
            }
            .navigationTitle("Advanced Search")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear All") {
                        clearAllCriteria()
                    }
                    .disabled(!hasAnyCriteria)
                }
            }
        }
    }
    
    // MARK: - Liquid Glass Components
    
    @ViewBuilder
    private var liquidGlassSectionPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.md) {
                ForEach(SearchSection.allCases) { section in
                    let isSelected = activeSection == section
                    
                    Button {
                        withAnimation(LiquidGlassTheme.FluidAnimation.smooth.springAnimation) {
                            activeSection = section
                        }
                        HapticFeedbackManager.shared.lightImpact()
                    } label: {
                        HStack(spacing: Theme.Spacing.xs) {
                            Image(systemName: section.systemImage)
                                .font(.callout)
                                .fontWeight(.medium)
                            Text(section.rawValue)
                                .font(LiquidGlassTheme.typography.labelLarge)
                                .fontWeight(.medium)
                                .tracking(0.1)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .foregroundStyle(isSelected ? .white : .primary)
                        .background {
                            let capsuleShape = Capsule()
                            if isSelected {
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
                                    capsuleShape
                                        .fill(.thinMaterial)
                                        .opacity(0.3)
                                        .blendMode(.overlay)
                                }
                                .shadow(
                                    color: primaryColor.opacity(0.3),
                                    radius: 8,
                                    x: 0,
                                    y: 4
                                )
                            } else {
                                capsuleShape.fill(.thinMaterial)
                                    .overlay {
                                        capsuleShape
                                            .strokeBorder(.separator.opacity(0.3), lineWidth: 0.5)
                                    }
                                    .shadow(
                                        color: .black.opacity(0.06),
                                        radius: 4,
                                        x: 0,
                                        y: 2
                                    )
                            }
                        }
                    }
                    .scaleEffect(isSelected ? 1.05 : 1.0)
                    .animation(LiquidGlassTheme.FluidAnimation.quick.springAnimation, value: isSelected)
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
        }
        .padding(.vertical, Theme.Spacing.md)
        .background {
            Rectangle()
                .fill(.regularMaterial)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(.separator.opacity(0.3))
                        .frame(height: 0.5)
                }
        }
    }
    
    @ViewBuilder
    private var liquidGlassQuerySection: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Main search field with enhanced styling
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                Text("Search Query")
                    .font(LiquidGlassTheme.typography.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                HStack(spacing: Theme.Spacing.md) {
                    Image(systemName: "magnifyingglass")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    
                    TextField("Enter title, author, ISBN, or keywords...", text: $searchQuery)
                        .font(LiquidGlassTheme.typography.bodyLarge)
                        .textFieldStyle(.plain)
                        .focused($isSearchFieldFocused)
                        .onSubmit {
                            performAdvancedSearch()
                        }
                        .onChange(of: searchQuery) { oldValue, newValue in
                            searchDebouncer.debouncedSearch(query: newValue) { query in
                                await updateSearchSuggestions(for: query)
                            }
                        }
                    
                    if !searchQuery.isEmpty {
                        Button {
                            withAnimation(.smooth) {
                                searchQuery = ""
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.vertical, Theme.Spacing.md)
                .background {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.thinMaterial)
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(
                                    isSearchFieldFocused ? primaryColor : Color.secondary.opacity(0.3),
                                    lineWidth: isSearchFieldFocused ? 2 : 1
                                )
                        }
                        .shadow(
                            color: isSearchFieldFocused ? primaryColor.opacity(0.15) : .black.opacity(0.06),
                            radius: isSearchFieldFocused ? 8 : 4,
                            x: 0,
                            y: isSearchFieldFocused ? 4 : 2
                        )
                }
                .scaleEffect(isSearchFieldFocused ? 1.02 : 1.0)
                .animation(.smooth, value: isSearchFieldFocused)
            }
            .progressiveGlassEffect(
                material: .regularMaterial,
                level: .optimized
            )
            
            // Search suggestions
            if showingSuggestions && !searchQuery.isEmpty {
                liquidGlassSearchSuggestions
            }
            
            // Quick search presets
            liquidGlassQuickPresets
        }
    }
    
    @ViewBuilder
    private var liquidGlassSearchSuggestions: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Suggestions")
                .font(LiquidGlassTheme.typography.titleSmall)
                .foregroundStyle(.secondary)
            
            LazyVStack(spacing: Theme.Spacing.sm) {
                let suggestions = searchDebouncer.getSmartSuggestions(for: searchQuery)
                ForEach(suggestions) { suggestion in
                    Button {
                        searchQuery = suggestion.text
                        showingSuggestions = false
                        performAdvancedSearch()
                    } label: {
                        HStack(spacing: Theme.Spacing.md) {
                            Image(systemName: suggestion.type.systemImage)
                                .font(.callout)
                                .foregroundStyle(suggestion.type == .autoComplete ? primaryColor : .secondary)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(suggestion.text)
                                    .font(LiquidGlassTheme.typography.bodyMedium)
                                    .foregroundStyle(.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                if let metadata = suggestion.metadata {
                                    Text(metadata)
                                        .font(LiquidGlassTheme.typography.labelSmall)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "arrow.up.left")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(Theme.Spacing.md)
                        .background {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(.thinMaterial)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .strokeBorder(.separator.opacity(0.2), lineWidth: 0.5)
                                }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .progressiveGlassEffect(
            material: .regularMaterial,
            level: .minimal
        )
        .transition(.move(edge: .top).combined(with: .opacity))
    }
    
    @ViewBuilder
    private var liquidGlassQuickPresets: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Quick Searches")
                .font(LiquidGlassTheme.typography.titleSmall)
                .foregroundStyle(.secondary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Theme.Spacing.sm) {
                ForEach([
                    ("Fiction Bestsellers", "book.fill", "Fiction"),
                    ("Recent Releases", "clock.fill", "2024"),
                    ("Award Winners", "trophy.fill", "award"),
                    ("Short Reads", "timer", "<200 pages")
                ], id: \.0) { title, icon, query in
                    Button {
                        applyQuickPreset(title: title, query: query)
                    } label: {
                        VStack(spacing: Theme.Spacing.sm) {
                            Image(systemName: icon)
                                .font(.title2)
                                .foregroundStyle(primaryColor)
                            
                            Text(title)
                                .font(LiquidGlassTheme.typography.labelMedium)
                                .fontWeight(.medium)
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(Theme.Spacing.md)
                        .frame(maxWidth: .infinity, minHeight: 80)
                        .background {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(.thinMaterial)
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
                                    color: primaryColor.opacity(0.1),
                                    radius: 6,
                                    x: 0,
                                    y: 3
                                )
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .progressiveGlassEffect(
            material: .regularMaterial,
            level: .optimized
        )
    }
    
    @ViewBuilder
    private var liquidGlassFiltersSection: some View {
        VStack(spacing: Theme.Spacing.xl) {
            // Language filters
            FilterSectionCard(title: "Languages", icon: "globe") {
                // Simplified language selection for demo
                Text("Language filtering coming soon")
                    .font(LiquidGlassTheme.typography.bodyMedium)
                    .foregroundStyle(.secondary)
            }
            
            // Date range filters
            FilterSectionCard(title: "Publication Year", icon: "calendar") {
                if let yearRange = publishedYearRange {
                    HStack {
                        Text("\(yearRange.lowerBound) - \(yearRange.upperBound)")
                            .font(LiquidGlassTheme.typography.bodyMedium)
                            .foregroundStyle(.primary)
                        
                        Spacer()
                        
                        Button("Clear") {
                            withAnimation(.smooth) {
                                publishedYearRange = nil
                            }
                        }
                        .foregroundStyle(primaryColor)
                    }
                } else {
                    Button("Set Year Range") {
                        withAnimation(.smooth) {
                            publishedYearRange = 2020...2024
                        }
                    }
                    .foregroundStyle(primaryColor)
                }
            }
            
            // Page count filters
            FilterSectionCard(title: "Page Count", icon: "doc.text") {
                HStack(spacing: Theme.Spacing.sm) {
                    FilterPresetButton("Short (<200)", isSelected: pageCountRange == 0...200) {
                        pageCountRange = pageCountRange == 0...200 ? nil : 0...200
                    }
                    
                    FilterPresetButton("Medium", isSelected: pageCountRange == 200...400) {
                        pageCountRange = pageCountRange == 200...400 ? nil : 200...400
                    }
                    
                    FilterPresetButton("Long (400+)", isSelected: pageCountRange == 400...2000) {
                        pageCountRange = pageCountRange == 400...2000 ? nil : 400...2000
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var liquidGlassSortingSection: some View {
        VStack(spacing: Theme.Spacing.lg) {
            FilterSectionCard(title: "Sort Results", icon: "arrow.up.arrow.down") {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: Theme.Spacing.sm) {
                    ForEach(BookSearchService.SortOption.allCases) { option in
                        let isSelected = sortOption == option
                        
                        Button {
                            withAnimation(.smooth) {
                                sortOption = option
                            }
                            HapticFeedbackManager.shared.lightImpact()
                        } label: {
                            VStack(spacing: Theme.Spacing.sm) {
                                Image(systemName: option.systemImage)
                                    .font(.title3)
                                    .foregroundStyle(isSelected ? .white : primaryColor)
                                
                                Text(option.displayName)
                                    .font(LiquidGlassTheme.typography.labelMedium)
                                    .fontWeight(.medium)
                                    .foregroundStyle(isSelected ? .white : .primary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(Theme.Spacing.md)
                            .frame(maxWidth: .infinity, minHeight: 80)
                            .background {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(isSelected ? primaryColor : Color(uiColor: .systemGray5))
                                    .overlay {
                                        if !isSelected {
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .strokeBorder(.separator.opacity(0.3), lineWidth: 0.5)
                                        }
                                    }
                                    .shadow(
                                        color: isSelected ? primaryColor.opacity(0.25) : .black.opacity(0.06),
                                        radius: isSelected ? 6 : 4,
                                        x: 0,
                                        y: isSelected ? 3 : 2
                                    )
                            }
                        }
                        .buttonStyle(.plain)
                        .scaleEffect(isSelected ? 1.05 : 1.0)
                        .animation(.smooth, value: isSelected)
                    }
                }
            }
            
            FilterSectionCard(title: "Options", icon: "gearshape") {
                Toggle("Include Translations", isOn: $includeTranslations)
                    .font(LiquidGlassTheme.typography.bodyMedium)
                    .tint(primaryColor)
            }
        }
    }
    
    @ViewBuilder
    private var liquidGlassResultsSection: some View {
        VStack(spacing: Theme.Spacing.lg) {
            if isSearching {
                UnifiedLoadingState(config: .init(
                    message: "Searching with advanced criteria",
                    subtitle: "Finding the perfect matches",
                    style: .spinner
                ))
            } else if searchResults.isEmpty {
                UnifiedHeroSection(config: .init(
                    icon: "magnifyingglass.circle",
                    title: "No Results Yet",
                    subtitle: "Configure your search criteria and tap Search to find books",
                    style: .discovery
                ))
            } else {
                LazyVStack(spacing: Theme.Spacing.md) {
                    ForEach(searchResults) { book in
                        SearchResultRow(book: book)
                            .progressiveGlassEffect(
                                material: .thinMaterial,
                                level: .minimal
                            )
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var liquidGlassActionButtons: some View {
        HStack(spacing: Theme.Spacing.md) {
            Button {
                performAdvancedSearch()
            } label: {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .font(.headline)
                    Text("Search")
                        .font(LiquidGlassTheme.typography.labelLarge)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
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
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(.thinMaterial)
                                .opacity(0.3)
                                .blendMode(.overlay)
                        }
                        .shadow(
                            color: primaryColor.opacity(0.3),
                            radius: 12,
                            x: 0,
                            y: 6
                        )
                }
            }
            .disabled(searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .buttonStyle(.plain)
            
            if hasAnyCriteria {
                Button {
                    clearAllCriteria()
                } label: {
                    Text("Clear")
                        .font(LiquidGlassTheme.typography.labelLarge)
                        .fontWeight(.medium)
                        .foregroundStyle(primaryColor)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 24)
                        .background {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(.thinMaterial)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .strokeBorder(primaryColor.opacity(0.3), lineWidth: 1)
                                }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.md)
        .background {
            Rectangle()
                .fill(.regularMaterial)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(.separator.opacity(0.3))
                        .frame(height: 0.5)
                }
        }
    }
    
    // MARK: - Material Design Components (Simplified)
    
    @ViewBuilder
    private var materialDesignSectionPicker: some View {
        // Simplified implementation
        Text("Material Design Implementation")
            .padding()
    }
    
    @ViewBuilder
    private var materialDesignQuerySection: some View {
        Text("Material Design Query Section")
            .padding()
    }
    
    @ViewBuilder
    private var materialDesignFiltersSection: some View {
        Text("Material Design Filters Section")
            .padding()
    }
    
    @ViewBuilder
    private var materialDesignSortingSection: some View {
        Text("Material Design Sorting Section")
            .padding()
    }
    
    @ViewBuilder
    private var materialDesignResultsSection: some View {
        Text("Material Design Results Section")
            .padding()
    }
    
    @ViewBuilder
    private var materialDesignActionButtons: some View {
        Text("Material Design Action Buttons")
            .padding()
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private func FilterSectionCard<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundStyle(primaryColor)
                
                Text(title)
                    .font(LiquidGlassTheme.typography.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Spacer()
            }
            
            content()
        }
        .padding(Theme.Spacing.lg)
        .progressiveGlassEffect(
            material: .regularMaterial,
            level: .optimized
        )
    }
    
    @ViewBuilder
    private func FilterPresetButton(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(LiquidGlassTheme.typography.labelMedium)
                .fontWeight(.medium)
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background {
                    Capsule()
                        .fill(isSelected ? primaryColor : Color(uiColor: .systemGray5))
                        .overlay {
                            if !isSelected {
                                Capsule()
                                    .strokeBorder(.separator.opacity(0.3), lineWidth: 0.5)
                            }
                        }
                }
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Business Logic
    
    private var hasAnyCriteria: Bool {
        !selectedAuthors.isEmpty ||
        !selectedGenres.isEmpty ||
        !selectedLanguages.isEmpty ||
        publishedYearRange != nil ||
        pageCountRange != nil ||
        ratingRange != 0.0...5.0 ||
        !includeUnratedBooks ||
        sortOption != .relevance ||
        !includeTranslations
    }
    
    private func clearAllCriteria() {
        withAnimation(.smooth) {
            selectedAuthors.removeAll()
            selectedGenres.removeAll()
            selectedLanguages.removeAll()
            publishedYearRange = nil
            pageCountRange = nil
            ratingRange = 0.0...5.0
            includeUnratedBooks = true
            sortOption = .relevance
            includeTranslations = true
        }
        HapticFeedbackManager.shared.mediumImpact()
    }
    
    private func applyQuickPreset(title: String, query: String) {
        withAnimation(.smooth) {
            searchQuery = query
            
            // Apply preset-specific filters
            switch title {
            case "Recent Releases":
                publishedYearRange = 2024...2024
            case "Short Reads":
                pageCountRange = 0...200
            default:
                break
            }
        }
        
        HapticFeedbackManager.shared.lightImpact()
        performAdvancedSearch()
    }
    
    private func performAdvancedSearch() {
        guard !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isSearching = true
        showingSuggestions = false
        
        // Add to search history
        searchHistory.addToHistory(searchQuery)
        
        let criteria = AdvancedSearchCriteria(
            query: searchQuery,
            authors: Array(selectedAuthors),
            genres: Array(selectedGenres),
            languages: Array(selectedLanguages),
            publishedYearRange: publishedYearRange,
            pageCountRange: pageCountRange,
            ratingRange: ratingRange,
            includeUnratedBooks: includeUnratedBooks,
            sortOption: sortOption,
            includeTranslations: includeTranslations
        )
        
        Task {
            // Simulate search - in real implementation, this would use the search service
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            
            await MainActor.run {
                isSearching = false
                // Mock results for demo
                searchResults = []
                
                onSearchComplete(searchResults, criteria)
                HapticFeedbackManager.shared.success()
            }
        }
    }
    
    private func updateSearchSuggestions(for query: String) async {
        await MainActor.run {
            showingSuggestions = !query.isEmpty
        }
    }
}

// MARK: - Advanced Search Criteria

struct AdvancedSearchCriteria {
    let query: String
    let authors: [String]
    let genres: [String]
    let languages: [String]
    let publishedYearRange: ClosedRange<Int>?
    let pageCountRange: ClosedRange<Int>?
    let ratingRange: ClosedRange<Double>
    let includeUnratedBooks: Bool
    let sortOption: BookSearchService.SortOption
    let includeTranslations: Bool
    
    var isEmpty: Bool {
        query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        authors.isEmpty &&
        genres.isEmpty &&
        languages.isEmpty &&
        publishedYearRange == nil &&
        pageCountRange == nil &&
        ratingRange == 0.0...5.0 &&
        includeUnratedBooks &&
        sortOption == .relevance &&
        includeTranslations
    }
    
    var summary: String {
        var components: [String] = []
        
        if !query.isEmpty {
            components.append("Query: \"\(query)\"")
        }
        if !authors.isEmpty {
            components.append("Authors: \(authors.joined(separator: ", "))")
        }
        if let yearRange = publishedYearRange {
            components.append("Years: \(yearRange.lowerBound)-\(yearRange.upperBound)")
        }
        if let pageRange = pageCountRange {
            components.append("Pages: \(pageRange.lowerBound)-\(pageRange.upperBound)")
        }
        
        return components.isEmpty ? "No criteria" : components.joined(separator: " • ")
    }
}

#Preview {
    AdvancedSearchModal { results, criteria in
        print("Search completed with \(results.count) results")
        print("Criteria: \(criteria.summary)")
    }
    .environment(\.unifiedThemeStore, UnifiedThemeStore())
    .environment(\.searchHistory, SearchHistoryService.shared)
    .environment(\.searchDebouncer, SearchDebouncer())
}