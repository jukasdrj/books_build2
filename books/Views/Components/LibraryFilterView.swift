import SwiftUI

enum LibrarySortOption: String, CaseIterable, Codable {
    case dateAdded = "date_added"
    case title = "title"
    case author = "author"
    case completeness = "completeness"
    case rating = "rating"
    
    var displayName: String {
        switch self {
        case .dateAdded: return "Date Added"
        case .title: return "Title"
        case .author: return "Author"
        case .completeness: return "Data Completeness"
        case .rating: return "Rating"
        }
    }
    
    var icon: String {
        switch self {
        case .dateAdded: return "calendar.badge.plus"
        case .title: return "textformat.abc"
        case .author: return "person"
        case .completeness: return "chart.bar.doc.horizontal"
        case .rating: return "star.fill"
        }
    }
}

struct LibraryFilter: Codable, Equatable {
    var readingStatus: Set<ReadingStatus> = Set(ReadingStatus.allCases)
    var showWishlistOnly: Bool = false
    var showOwnedOnly: Bool = false
    var showFavoritesOnly: Bool = false
    var sortBy: LibrarySortOption = .dateAdded
    var sortAscending: Bool = false
    
    // iOS 26 Enhanced Filtering Options
    var ratingRange: ClosedRange<Double> = 0.0...5.0
    var showUnratedOnly: Bool = false
    var publishedYearRange: ClosedRange<Int>?
    var selectedGenres: Set<String> = []
    var selectedAuthors: Set<String> = []
    var pageCountRange: ClosedRange<Int>?
    var showWithNotesOnly: Bool = false
    var showRecentlyAddedOnly: Bool = false // Last 30 days
    var showCurrentlyReadingOnly: Bool = false
    var dataQualityFilter: DataQualityLevel?
    var languageFilter: Set<String> = []
    
    enum DataQualityLevel: String, Codable, CaseIterable {
        case high = "High Quality" // 80%+
        case medium = "Medium Quality" // 50-79%
        case low = "Needs Attention" // <50%
        
        var threshold: Double {
            switch self {
            case .high: return 0.8
            case .medium: return 0.5
            case .low: return 0.0
            }
        }
        
        var systemImage: String {
            switch self {
            case .high: return "checkmark.seal.fill"
            case .medium: return "checkmark.circle"
            case .low: return "exclamationmark.triangle"
            }
        }
    }
    
    var isActive: Bool {
        return readingStatus != Set(ReadingStatus.allCases) ||
               showWishlistOnly ||
               showOwnedOnly ||
               showFavoritesOnly ||
               sortBy != .dateAdded ||
               ratingRange != 0.0...5.0 ||
               showUnratedOnly ||
               publishedYearRange != nil ||
               !selectedGenres.isEmpty ||
               !selectedAuthors.isEmpty ||
               pageCountRange != nil ||
               showWithNotesOnly ||
               showRecentlyAddedOnly ||
               showCurrentlyReadingOnly ||
               dataQualityFilter != nil ||
               !languageFilter.isEmpty
    }
    
    /// Count of active filters for UI display
    var activeFilterCount: Int {
        var count = 0
        if readingStatus != Set(ReadingStatus.allCases) { count += 1 }
        if showWishlistOnly { count += 1 }
        if showOwnedOnly { count += 1 }
        if showFavoritesOnly { count += 1 }
        if ratingRange != 0.0...5.0 || showUnratedOnly { count += 1 }
        if publishedYearRange != nil { count += 1 }
        if !selectedGenres.isEmpty { count += 1 }
        if !selectedAuthors.isEmpty { count += 1 }
        if pageCountRange != nil { count += 1 }
        if showWithNotesOnly { count += 1 }
        if showRecentlyAddedOnly { count += 1 }
        if showCurrentlyReadingOnly { count += 1 }
        if dataQualityFilter != nil { count += 1 }
        if !languageFilter.isEmpty { count += 1 }
        return count
    }
    
    static let all = LibraryFilter()
    static let wishlistOnly = LibraryFilter(showWishlistOnly: true)
    static let favorites = LibraryFilter(showFavoritesOnly: true)
    static let currentlyReading = LibraryFilter(showCurrentlyReadingOnly: true)
    static let recentlyAdded = LibraryFilter(showRecentlyAddedOnly: true)
    static let highQualityOnly = LibraryFilter(dataQualityFilter: .high)
    static let needsAttention = LibraryFilter(dataQualityFilter: .low)
}

struct LibraryFilterView: View {
    @Binding var filter: LibraryFilter
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var currentTheme
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.xl) {
                    // Quick Filter Options
                    quickFiltersSection
                    
                    // Advanced Filter Options
                    advancedFiltersSection
                    
                    // Sorting Section
                    sortingSection
                    
                    // Reading Status Section
                    readingStatusSection
                    
                    // Rating and Quality Section
                    ratingQualitySection
                    
                    // Date and Metadata Section
                    dateMetadataSection
                }
                .padding(Theme.Spacing.lg)
            }
            .background(currentTheme.background)
            .navigationTitle(filter.activeFilterCount > 0 ? "Filters (\(filter.activeFilterCount))" : "Filter Library")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        withAnimation(.smooth) {
                            filter = LibraryFilter.all
                        }
                        HapticFeedbackManager.shared.lightImpact()
                    }
                    .disabled(!filter.isActive)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(currentTheme.primary)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    @ViewBuilder
    private var quickFiltersSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Quick Filters")
                .titleMedium()
                .foregroundColor(currentTheme.primaryText)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Theme.Spacing.sm) {
                QuickFilterChip(
                    title: "💜 Wishlist", 
                    subtitle: "Books you want to read",
                    isSelected: filter.showWishlistOnly
                ) {
                    withAnimation(.smooth) {
                        filter.showWishlistOnly.toggle()
                        if filter.showWishlistOnly {
                            filter.showOwnedOnly = false
                        }
                    }
                    HapticFeedbackManager.shared.lightImpact()
                }
                
                QuickFilterChip(
                    title: "📚 Owned", 
                    subtitle: "Books in your collection",
                    isSelected: filter.showOwnedOnly
                ) {
                    withAnimation(.smooth) {
                        filter.showOwnedOnly.toggle()
                        if filter.showOwnedOnly {
                            filter.showWishlistOnly = false
                        }
                    }
                    HapticFeedbackManager.shared.lightImpact()
                }
                
                QuickFilterChip(
                    title: "⭐ Favorites", 
                    subtitle: "Your starred books",
                    isSelected: filter.showFavoritesOnly,
                    fullWidth: true
                ) {
                    withAnimation(.smooth) {
                        filter.showFavoritesOnly.toggle()
                    }
                    HapticFeedbackManager.shared.lightImpact()
                }
            }
        }
        .padding(Theme.Spacing.lg)
        .progressiveGlassEffect(
            material: .regularMaterial,
            level: .optimized
        )
    }
    
    @ViewBuilder
    private var sortingSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Sort By")
                .titleMedium()
                .foregroundColor(currentTheme.primaryText)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Theme.Spacing.sm), count: 2), spacing: Theme.Spacing.sm) {
                ForEach(LibrarySortOption.allCases, id: \.self) { option in
                    Button(action: {
                        withAnimation(.smooth) {
                            if filter.sortBy == option {
                                // Toggle sort direction if same option selected
                                filter.sortAscending.toggle()
                            } else {
                                filter.sortBy = option
                                // Set default direction for each option
                                filter.sortAscending = (option == .title || option == .author)
                            }
                        }
                        HapticFeedbackManager.shared.lightImpact()
                    }) {
                        HStack(spacing: Theme.Spacing.sm) {
                            Image(systemName: option.icon)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(filter.sortBy == option ? currentTheme.onPrimary : currentTheme.primary)
                            
                            Text(option.displayName)
                                .labelMedium()
                                .foregroundColor(filter.sortBy == option ? currentTheme.onPrimary : currentTheme.primaryText)
                                .multilineTextAlignment(.leading)
                            
                            Spacer()
                            
                            if filter.sortBy == option {
                                Image(systemName: filter.sortAscending ? "chevron.up" : "chevron.down")
                                    .font(.caption)
                                    .foregroundColor(currentTheme.onPrimary)
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.sm)
                        .padding(.vertical, Theme.Spacing.xs)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                .fill(filter.sortBy == option ? currentTheme.primary : currentTheme.surfaceVariant)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                .stroke(filter.sortBy == option ? currentTheme.primary : currentTheme.outline.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(Theme.Spacing.lg)
        .progressiveGlassEffect(
            material: .regularMaterial,
            level: .optimized
        )
    }
    
    @ViewBuilder
    private var readingStatusSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Text("Reading Status")
                    .titleMedium()
                    .foregroundColor(currentTheme.primaryText)
                
                Spacer()
                
                Button(filter.readingStatus.count == ReadingStatus.allCases.count ? "Deselect All" : "Select All") {
                    withAnimation(.smooth) {
                        if filter.readingStatus.count == ReadingStatus.allCases.count {
                            filter.readingStatus = []
                        } else {
                            filter.readingStatus = Set(ReadingStatus.allCases)
                        }
                    }
                    HapticFeedbackManager.shared.lightImpact()
                }
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Theme.Spacing.sm) {
                ForEach(ReadingStatus.allCases, id: \.self) { status in
                    ReadingStatusFilterChip(
                        status: status,
                        isSelected: filter.readingStatus.contains(status)
                    ) {
                        withAnimation(.smooth) {
                            if filter.readingStatus.contains(status) {
                                filter.readingStatus.remove(status)
                            } else {
                                filter.readingStatus.insert(status)
                            }
                        }
                        HapticFeedbackManager.shared.lightImpact()
                    }
                }
            }
        }
        .padding(Theme.Spacing.lg)
        .progressiveGlassEffect(
            material: .regularMaterial,
            level: .optimized
        )
    }
}

// MARK: - Supporting Views

struct QuickFilterChip: View {
    @Environment(\.appTheme) private var currentTheme
    let title: String
    let subtitle: String
    let isSelected: Bool
    let fullWidth: Bool
    let action: () -> Void
    
    init(title: String, subtitle: String, isSelected: Bool, fullWidth: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.isSelected = isSelected
        self.fullWidth = fullWidth
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(title)
                    .labelLarge()
                    .foregroundColor(isSelected ? currentTheme.onPrimary : currentTheme.primaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(subtitle)
                    .labelSmall()
                    .foregroundColor(isSelected ? currentTheme.onPrimary.opacity(0.8) : currentTheme.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .fill(isSelected ? currentTheme.primary : currentTheme.surfaceVariant)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .stroke(isSelected ? currentTheme.primary : currentTheme.outline.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .conditionalModifier(fullWidth) { view in
            view.gridCellColumns(2)
        }
    }
}

struct ReadingStatusFilterChip: View {
    @Environment(\.appTheme) private var currentTheme
    let status: ReadingStatus
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.sm) {
                Circle()
                    .fill(status.textColor(theme: currentTheme))
                    .frame(width: 12, height: 12)
                
                Text(status.rawValue)
                    .labelMedium()
                    .foregroundColor(isSelected ? currentTheme.onPrimary : currentTheme.primaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .foregroundColor(currentTheme.onPrimary)
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .fill(isSelected ? currentTheme.primary : currentTheme.surfaceVariant)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .stroke(isSelected ? currentTheme.primary : currentTheme.outline.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct FilterToggleRow: View {
    @Environment(\.appTheme) private var currentTheme
    let title: String
    let subtitle: String
    let icon: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .foregroundColor(currentTheme.primary)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .bodyMedium()
                    .foregroundColor(currentTheme.primaryText)
                
                Text(subtitle)
                    .labelSmall()
                    .foregroundColor(currentTheme.secondaryText)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .tint(currentTheme.primary)
                .onChange(of: isOn) { _, newValue in
                    HapticFeedbackManager.shared.lightImpact()
                }
        }
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.xs)
    }
    
    // MARK: - iOS 26 Advanced Filter Sections
    
    @ViewBuilder
    private var advancedFiltersSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Smart Filters")
                .titleMedium()
                .foregroundColor(currentTheme.primaryText)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Theme.Spacing.sm) {
                AdvancedFilterChip(
                    title: "📖 Currently Reading", 
                    subtitle: "Books in progress",
                    isSelected: filter.showCurrentlyReadingOnly
                ) {
                    withAnimation(.smooth) {
                        filter.showCurrentlyReadingOnly.toggle()
                    }
                    HapticFeedbackManager.shared.lightImpact()
                }
                
                AdvancedFilterChip(
                    title: "📝 With Notes", 
                    subtitle: "Books with personal notes",
                    isSelected: filter.showWithNotesOnly
                ) {
                    withAnimation(.smooth) {
                        filter.showWithNotesOnly.toggle()
                    }
                    HapticFeedbackManager.shared.lightImpact()
                }
                
                AdvancedFilterChip(
                    title: "🕒 Recently Added", 
                    subtitle: "Last 30 days",
                    isSelected: filter.showRecentlyAddedOnly
                ) {
                    withAnimation(.smooth) {
                        filter.showRecentlyAddedOnly.toggle()
                    }
                    HapticFeedbackManager.shared.lightImpact()
                }
                
                AdvancedFilterChip(
                    title: "⭐ Unrated", 
                    subtitle: "Books needing ratings",
                    isSelected: filter.showUnratedOnly
                ) {
                    withAnimation(.smooth) {
                        filter.showUnratedOnly.toggle()
                        if filter.showUnratedOnly {
                            filter.ratingRange = 0.0...5.0 // Reset rating range
                        }
                    }
                    HapticFeedbackManager.shared.lightImpact()
                }
            }
        }
        .padding(Theme.Spacing.lg)
        .progressiveGlassEffect(
            material: .regularMaterial,
            level: .optimized
        )
    }\n    \n    @ViewBuilder\n    private var ratingQualitySection: some View {\n        VStack(alignment: .leading, spacing: Theme.Spacing.md) {\n            Text(\"Rating & Quality\")\n                .titleMedium()\n                .foregroundColor(currentTheme.primaryText)\n            \n            // Rating Range Slider\n            if !filter.showUnratedOnly {\n                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {\n                    HStack {\n                        Text(\"Rating Range\")\n                            .bodyMedium()\n                            .foregroundColor(currentTheme.primaryText)\n                        \n                        Spacer()\n                        \n                        Text(\"\\(Int(filter.ratingRange.lowerBound))★ - \\(Int(filter.ratingRange.upperBound))★\")\n                            .labelMedium()\n                            .foregroundColor(currentTheme.secondaryText)\n                    }\n                    \n                    // Custom range slider would go here - simplified for now\n                    HStack(spacing: Theme.Spacing.sm) {\n                        ForEach(1...5, id: \\.self) { rating in\n                            Button {\n                                withAnimation(.smooth) {\n                                    let ratingDouble = Double(rating)\n                                    if filter.ratingRange.contains(ratingDouble) {\n                                        // Remove from range (simplified logic)\n                                        if rating <= 3 {\n                                            filter.ratingRange = ratingDouble+1...filter.ratingRange.upperBound\n                                        } else {\n                                            filter.ratingRange = filter.ratingRange.lowerBound...ratingDouble-1\n                                        }\n                                    } else {\n                                        // Add to range (simplified logic)\n                                        let newLower = min(filter.ratingRange.lowerBound, ratingDouble)\n                                        let newUpper = max(filter.ratingRange.upperBound, ratingDouble)\n                                        filter.ratingRange = newLower...newUpper\n                                    }\n                                }\n                                HapticFeedbackManager.shared.lightImpact()\n                            } label: {\n                                Image(systemName: filter.ratingRange.contains(Double(rating)) ? \"star.fill\" : \"star\")\n                                    .foregroundColor(filter.ratingRange.contains(Double(rating)) ? currentTheme.warning : currentTheme.outline)\n                                    .font(.title2)\n                            }\n                        }\n                    }\n                }\n            }\n            \n            // Data Quality Filter\n            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {\n                Text(\"Data Quality\")\n                    .bodyMedium()\n                    .foregroundColor(currentTheme.primaryText)\n                \n                LazyVGrid(columns: [\n                    GridItem(.flexible()),\n                    GridItem(.flexible()),\n                    GridItem(.flexible())\n                ], spacing: Theme.Spacing.sm) {\n                    ForEach(LibraryFilter.DataQualityLevel.allCases, id: \\.self) { quality in\n                        Button {\n                            withAnimation(.smooth) {\n                                if filter.dataQualityFilter == quality {\n                                    filter.dataQualityFilter = nil\n                                } else {\n                                    filter.dataQualityFilter = quality\n                                }\n                            }\n                            HapticFeedbackManager.shared.lightImpact()\n                        } label: {\n                            VStack(spacing: Theme.Spacing.xs) {\n                                Image(systemName: quality.systemImage)\n                                    .font(.title3)\n                                    .foregroundColor(filter.dataQualityFilter == quality ? currentTheme.onPrimary : currentTheme.primary)\n                                \n                                Text(quality.rawValue)\n                                    .labelSmall()\n                                    .foregroundColor(filter.dataQualityFilter == quality ? currentTheme.onPrimary : currentTheme.primaryText)\n                                    .multilineTextAlignment(.center)\n                            }\n                            .padding(.horizontal, Theme.Spacing.xs)\n                            .padding(.vertical, Theme.Spacing.sm)\n                            .background(\n                                RoundedRectangle(cornerRadius: Theme.CornerRadius.small)\n                                    .fill(filter.dataQualityFilter == quality ? currentTheme.primary : currentTheme.surfaceVariant)\n                            )\n                        }\n                        .buttonStyle(.plain)\n                    }\n                }\n            }\n        }\n        .padding(Theme.Spacing.lg)\n        .progressiveGlassEffect(\n            material: .regularMaterial,\n            level: .optimized\n        )\n    }\n    \n    @ViewBuilder\n    private var dateMetadataSection: some View {\n        VStack(alignment: .leading, spacing: Theme.Spacing.md) {\n            Text(\"Date & Metadata\")\n                .titleMedium()\n                .foregroundColor(currentTheme.primaryText)\n            \n            // Publication Year Range\n            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {\n                HStack {\n                    Text(\"Publication Year\")\n                        .bodyMedium()\n                        .foregroundColor(currentTheme.primaryText)\n                    \n                    Spacer()\n                    \n                    if let yearRange = filter.publishedYearRange {\n                        Button(\"Clear\") {\n                            withAnimation(.smooth) {\n                                filter.publishedYearRange = nil\n                            }\n                        }\n                        .buttonStyle(.borderless)\n                        .foregroundColor(currentTheme.primary)\n                        .font(.caption)\n                    }\n                }\n                \n                if let yearRange = filter.publishedYearRange {\n                    Text(\"\\(yearRange.lowerBound) - \\(yearRange.upperBound)\")\n                        .labelMedium()\n                        .foregroundColor(currentTheme.secondaryText)\n                } else {\n                    Button(\"Set Year Range\") {\n                        // For now, set a common range - in full implementation would show year picker\n                        withAnimation(.smooth) {\n                            filter.publishedYearRange = 2000...2024\n                        }\n                        HapticFeedbackManager.shared.lightImpact()\n                    }\n                    .buttonStyle(.bordered)\n                    .foregroundColor(currentTheme.primary)\n                }\n            }\n            \n            // Page Count Range\n            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {\n                HStack {\n                    Text(\"Page Count\")\n                        .bodyMedium()\n                        .foregroundColor(currentTheme.primaryText)\n                    \n                    Spacer()\n                    \n                    if let pageRange = filter.pageCountRange {\n                        Button(\"Clear\") {\n                            withAnimation(.smooth) {\n                                filter.pageCountRange = nil\n                            }\n                        }\n                        .buttonStyle(.borderless)\n                        .foregroundColor(currentTheme.primary)\n                        .font(.caption)\n                    }\n                }\n                \n                if let pageRange = filter.pageCountRange {\n                    Text(\"\\(pageRange.lowerBound) - \\(pageRange.upperBound) pages\")\n                        .labelMedium()\n                        .foregroundColor(currentTheme.secondaryText)\n                } else {\n                    HStack(spacing: Theme.Spacing.sm) {\n                        Button(\"Short (<200)\") {\n                            withAnimation(.smooth) {\n                                filter.pageCountRange = 0...200\n                            }\n                        }\n                        .buttonStyle(.bordered)\n                        .font(.caption)\n                        \n                        Button(\"Medium (200-400)\") {\n                            withAnimation(.smooth) {\n                                filter.pageCountRange = 200...400\n                            }\n                        }\n                        .buttonStyle(.bordered)\n                        .font(.caption)\n                        \n                        Button(\"Long (400+)\") {\n                            withAnimation(.smooth) {\n                                filter.pageCountRange = 400...2000\n                            }\n                        }\n                        .buttonStyle(.bordered)\n                        .font(.caption)\n                    }\n                }\n            }\n        }\n        .padding(Theme.Spacing.lg)\n        .progressiveGlassEffect(\n            material: .regularMaterial,\n            level: .optimized\n        )\n    }\n}\n\n// MARK: - Advanced Filter Components\n\nstruct AdvancedFilterChip: View {\n    @Environment(\\.appTheme) private var currentTheme\n    let title: String\n    let subtitle: String\n    let isSelected: Bool\n    let action: () -> Void\n    \n    var body: some View {\n        Button(action: action) {\n            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {\n                Text(title)\n                    .labelLarge()\n                    .foregroundColor(isSelected ? currentTheme.onPrimary : currentTheme.primaryText)\n                    .frame(maxWidth: .infinity, alignment: .leading)\n                \n                Text(subtitle)\n                    .labelSmall()\n                    .foregroundColor(isSelected ? currentTheme.onPrimary.opacity(0.8) : currentTheme.secondaryText)\n                    .frame(maxWidth: .infinity, alignment: .leading)\n            }\n            .padding(Theme.Spacing.md)\n            .background(\n                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)\n                    .fill(isSelected ? currentTheme.primary : currentTheme.surfaceVariant)\n            )\n            .overlay(\n                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)\n                    .stroke(isSelected ? currentTheme.primary : currentTheme.outline.opacity(0.3), lineWidth: 1)\n            )\n            .scaleEffect(isSelected ? 1.02 : 1.0)\n            .animation(.smooth, value: isSelected)\n        }\n        .buttonStyle(.plain)\n    }\n}

#Preview {\n    LibraryFilterView(filter: .constant(LibraryFilter.all))\n}