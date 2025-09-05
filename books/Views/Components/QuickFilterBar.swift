import SwiftUI
import SwiftData

struct QuickFilterBar: View {
    @Environment(\.unifiedThemeStore) private var themeStore
    @Environment(\.modelContext) private var modelContext
    @Binding var filter: LibraryFilter
    let onShowFullFilters: () -> Void
    
    // iOS 26 Enhanced State Management
    @State private var isExpanded = false
    @State private var selectedQuickFilter: QuickFilterType? = nil
    @State private var contextualSuggestions: [String] = []
    
    // Legacy theme access for compatibility
    private var theme: AppColorTheme {
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
    
    private var secondaryColor: Color {
        if let liquidVariant = themeStore.currentTheme.liquidGlassVariant {
            return liquidVariant.colorDefinition.secondary.color
        } else {
            return themeStore.appTheme.secondary
        }
    }
    
    enum QuickFilterType: String, CaseIterable {
        case readingStatus = "Status"
        case favorites = "Favorites"
        case recentlyAdded = "Recent"
        case highRated = "Top Rated"
        case genres = "Genres"
        
        var systemImage: String {
            switch self {
            case .readingStatus: return "book.fill"
            case .favorites: return "star.fill"
            case .recentlyAdded: return "clock.fill"
            case .highRated: return "trophy.fill"
            case .genres: return "tag.fill"
            }
        }
        
        var description: String {
            switch self {
            case .readingStatus: return "Filter by reading progress"
            case .favorites: return "Show only starred books"
            case .recentlyAdded: return "Recently added to library"
            case .highRated: return "4+ star rated books"
            case .genres: return "Filter by book categories"
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
            loadContextualSuggestions()
        }
    }
    
    // MARK: - iOS 26 Liquid Glass Implementation
    @ViewBuilder
    private var liquidGlassImplementation: some View {
        VStack(spacing: 0) {
            // Main filter bar with enhanced glass effects
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.md) {
                    // Enhanced Clear All button with glass styling
                    if filter.isActive {
                        Button {
                            withAnimation(LiquidGlassTheme.FluidAnimation.smooth.springAnimation) {
                                filter = LibraryFilter.all
                                selectedQuickFilter = nil
                            }
                            HapticFeedbackManager.shared.mediumImpact()
                        } label: {
                            HStack(spacing: Theme.Spacing.xs) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("Clear All")
                                    .font(LiquidGlassTheme.typography.labelMedium)
                                    .fontWeight(.medium)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .foregroundStyle(.primary)
                            .background {
                                Capsule()
                                    .fill(.regularMaterial)
                                    .overlay {
                                        Capsule()
                                            .strokeBorder(.separator.opacity(0.5), lineWidth: 0.5)
                                    }
                                    .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                            }
                        }
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                        .accessibilityLabel("Clear all filters")
                    }
                    
                    // Enhanced Reading Status chips with better hierarchy
                    ForEach(ReadingStatus.allCases, id: \.self) { status in
                        let isSelected = filter.readingStatus == [status]
                        let isPartiallySelected = filter.readingStatus.contains(status) && filter.readingStatus.count > 1
                        
                        Button {
                            withAnimation(LiquidGlassTheme.FluidAnimation.quick.springAnimation) {
                                if isSelected {
                                    // Expand to show all statuses
                                    filter.readingStatus = Set(ReadingStatus.allCases)
                                    selectedQuickFilter = nil
                                } else {
                                    // Select only this status
                                    filter.readingStatus = [status]
                                    selectedQuickFilter = .readingStatus
                                }
                            }
                            HapticFeedbackManager.shared.lightImpact()
                        } label: {
                            HStack(spacing: 6) {
                                // Enhanced status indicator with better visual hierarchy
                                ZStack {
                                    Circle()
                                        .fill(status.textColor(theme: theme))
                                        .frame(width: 10, height: 10)
                                    
                                    if isPartiallySelected {
                                        Circle()
                                            .strokeBorder(.white, lineWidth: 1.5)
                                            .frame(width: 10, height: 10)
                                    }
                                }
                                
                                Text(status.displayName)
                                    .font(LiquidGlassTheme.typography.labelMedium)
                                    .fontWeight(.medium)
                                    .tracking(0.1)
                                
                                // Selection indicator
                                if isSelected {
                                    Image(systemName: "checkmark")
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.white)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .foregroundStyle(isSelected ? .white : .primary)
                            .background {
                                let capsuleShape = Capsule()
                                Group {
                                    if isSelected {
                                        capsuleShape.fill(
                                            LinearGradient(
                                                colors: [
                                                    status.textColor(theme: theme),
                                                    status.textColor(theme: theme).opacity(0.8)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                    } else {
                                        capsuleShape.fill(.thinMaterial)
                                    }
                                }
                                .overlay {
                                    if !isSelected {
                                        capsuleShape.strokeBorder(
                                            isPartiallySelected ? 
                                                status.textColor(theme: theme).opacity(0.4) : 
                                                .separator.opacity(0.3),
                                            lineWidth: isPartiallySelected ? 1 : 0.5
                                        )
                                    }
                                }
                                .shadow(
                                    color: isSelected ? 
                                        status.textColor(theme: theme).opacity(0.25) : 
                                        .black.opacity(0.06),
                                    radius: isSelected ? 6 : 4,
                                    x: 0,
                                    y: isSelected ? 3 : 2
                                )
                            }
                        }
                        .scaleEffect(isSelected ? 1.05 : 1.0)
                        .animation(LiquidGlassTheme.FluidAnimation.quick.springAnimation, value: isSelected)
                        .accessibilityLabel("Filter by \(status.displayName)")
                        .accessibilityValue(isSelected ? "Selected" : "Not selected")
                        .accessibilityHint(isSelected ? "Double tap to show all books" : "Double tap to filter by \(status.displayName) only")
                    }
                    
                    // Quick action filters with enhanced styling
                    if !filter.showFavoritesOnly {
                        quickActionButton(
                            title: "Favorites",
                            icon: "star.fill",
                            isSelected: false
                        ) {
                            withAnimation(LiquidGlassTheme.FluidAnimation.smooth.springAnimation) {
                                filter.showFavoritesOnly = true
                                selectedQuickFilter = .favorites
                            }
                            HapticFeedbackManager.shared.lightImpact()
                        }
                    }
                    
                    // More filters indicator
                    Button {
                        withAnimation(LiquidGlassTheme.FluidAnimation.smooth.springAnimation) {
                            onShowFullFilters()
                        }
                        HapticFeedbackManager.shared.mediumImpact()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.caption)
                            Text("More")
                                .font(LiquidGlassTheme.typography.labelSmall)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .foregroundStyle(.secondary)
                        .background {
                            Capsule()
                                .fill(.ultraThinMaterial)
                                .overlay {
                                    Capsule()
                                        .strokeBorder(.separator.opacity(0.2), lineWidth: 0.5)
                                }
                        }
                    }
                    .accessibilityLabel("Show more filter options")
                }
                .padding(.horizontal, Theme.Spacing.lg)
            }
            .padding(.vertical, Theme.Spacing.md)
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
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(.separator.opacity(0.3))
                            .frame(height: 0.5)
                    }
            }
            
            // Contextual suggestions bar (optional)
            if !contextualSuggestions.isEmpty && selectedQuickFilter != nil {
                contextualSuggestionsBar
            }
        }
    }
    
    // MARK: - Material Design Legacy Implementation
    @ViewBuilder
    private var materialDesignImplementation: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.sm) {
                // Show All button when filters are active
                if filter.isActive {
                    Button("Clear All") {
                        withAnimation(.smooth) {
                            filter = LibraryFilter.all
                            selectedQuickFilter = nil
                        }
                        HapticFeedbackManager.shared.lightImpact()
                    }
                    .materialChip(isSelected: false, backgroundColor: theme.tertiaryContainer)
                }
                
                // Enhanced Reading status chips
                ForEach(ReadingStatus.allCases, id: \.self) { status in
                    let isSelected = filter.readingStatus == [status]
                    
                    Button(action: {
                        withAnimation(.smooth) {
                            if isSelected {
                                filter.readingStatus = Set(ReadingStatus.allCases)
                                selectedQuickFilter = nil
                            } else {
                                filter.readingStatus = [status]
                                selectedQuickFilter = .readingStatus
                            }
                        }
                        HapticFeedbackManager.shared.lightImpact()
                    }) {
                        HStack(spacing: Theme.Spacing.xs) {
                            Circle()
                                .fill(status.textColor(theme: theme))
                                .frame(width: 8, height: 8)
                            
                            Text(status.displayName)
                                .labelMedium()
                        }
                    }
                    .materialChip(isSelected: isSelected)
                    .accessibilityLabel("Filter by \(status.displayName)")
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
        .padding(.vertical, Theme.Spacing.sm)
        .background(theme.surface)
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private func quickActionButton(title: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .fontWeight(.medium)
                Text(title)
                    .font(LiquidGlassTheme.typography.labelMedium)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .foregroundStyle(isSelected ? .white : .primary)
            .background {
                Capsule()
                    .fill(isSelected ? primaryColor : .thinMaterial)
                    .overlay {
                        if !isSelected {
                            Capsule()
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
        .accessibilityLabel(title)
    }
    
    @ViewBuilder
    private var contextualSuggestionsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.sm) {
                ForEach(contextualSuggestions, id: \.self) { suggestion in
                    Text(suggestion)
                        .font(LiquidGlassTheme.typography.labelSmall)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background {
                            Capsule()
                                .fill(.thinMaterial)
                                .overlay {
                                    Capsule()
                                        .strokeBorder(secondaryColor.opacity(0.3), lineWidth: 0.5)
                                }
                        }
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
        }
        .padding(.vertical, Theme.Spacing.xs)
        .background(.ultraThinMaterial)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
    
    // MARK: - Data Methods
    
    private func loadContextualSuggestions() {
        // Load contextual suggestions based on user's library
        // This could include popular genres, recently read authors, etc.
        contextualSuggestions = ["Recent reads", "Popular authors", "New releases"]
    }
}

#Preview {
    QuickFilterBar(filter: .constant(LibraryFilter.all)) {
// print("Show full filters")
    }
}