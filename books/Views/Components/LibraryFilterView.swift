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
    
    @ViewBuilder
    private var ratingQualitySection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Rating & Quality")
                .titleMedium()
                .foregroundColor(currentTheme.primaryText)
            
            // Rating Range Slider
            if !filter.showUnratedOnly {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    HStack {
                        Text("Rating Range")
                            .bodyMedium()
                            .foregroundColor(currentTheme.primaryText)
                        
                        Spacer()
                        
                        Text("\(Int(filter.ratingRange.lowerBound))★ - \(Int(filter.ratingRange.upperBound))★")
                            .labelMedium()
                            .foregroundColor(currentTheme.secondaryText)
                    }
                    
                    // Custom range slider would go here - simplified for now
                    HStack(spacing: Theme.Spacing.sm) {
                        ForEach(1...5, id: \.self) { rating in
                            Button {
                                withAnimation(.smooth) {
                                    let ratingDouble = Double(rating)
                                    if filter.ratingRange.contains(ratingDouble) {
                                        // Remove from range (simplified logic)
                                        if rating <= 3 {
                                            filter.ratingRange = ratingDouble+1...filter.ratingRange.upperBound
                                        } else {
                                            filter.ratingRange = filter.ratingRange.lowerBound...ratingDouble-1
                                        }
                                    } else {
                                        // Add to range (simplified logic)
                                        let newLower = min(filter.ratingRange.lowerBound, ratingDouble)
                                        let newUpper = max(filter.ratingRange.upperBound, ratingDouble)
                                        filter.ratingRange = newLower...newUpper
                                    }
                                }
                                HapticFeedbackManager.shared.lightImpact()
                            } label: {
                                Image(systemName: filter.ratingRange.contains(Double(rating)) ? "star.fill" : "star")
                                    .foregroundColor(filter.ratingRange.contains(Double(rating)) ? currentTheme.warning : currentTheme.outline)
                                    .font(.title2)
                            }
                        }
                    }
                }
            }
            
            // Data Quality Filter
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("Data Quality")
                    .bodyMedium()
                    .foregroundColor(currentTheme.primaryText)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: Theme.Spacing.sm) {
                    ForEach(LibraryFilter.DataQualityLevel.allCases, id: \.self) { quality in
                        Button {
                            withAnimation(.smooth) {
                                if filter.dataQualityFilter == quality {
                                    filter.dataQualityFilter = nil
                                } else {
                                    filter.dataQualityFilter = quality
                                }
                            }
                            HapticFeedbackManager.shared.lightImpact()
                        } label: {
                            VStack(spacing: Theme.Spacing.xs) {
                                Image(systemName: quality.systemImage)
                                    .font(.title3)
                                    .foregroundColor(filter.dataQualityFilter == quality ? currentTheme.onPrimary : currentTheme.primary)
                                
                                Text(quality.rawValue)
                                    .labelSmall()
                                    .foregroundColor(filter.dataQualityFilter == quality ? currentTheme.onPrimary : currentTheme.primaryText)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.horizontal, Theme.Spacing.xs)
                            .padding(.vertical, Theme.Spacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                                    .fill(filter.dataQualityFilter == quality ? currentTheme.primary : currentTheme.surfaceVariant)
                            )
                        }
                        .buttonStyle(.plain)
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
    
    @ViewBuilder
    private var dateMetadataSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Date & Metadata")
                .titleMedium()
                .foregroundColor(currentTheme.primaryText)
            
            // Publication Year Range
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack {
                    Text("Publication Year")
                        .bodyMedium()
                        .foregroundColor(currentTheme.primaryText)
                    
                    Spacer()
                    
                    if let yearRange = filter.publishedYearRange {
                        Button("Clear") {
                            withAnimation(.smooth) {
                                filter.publishedYearRange = nil
                            }
                        }
                        .buttonStyle(.borderless)
                        .foregroundColor(currentTheme.primary)
                        .font(.caption)
                    }
                }
                
                if let yearRange = filter.publishedYearRange {
                    Text("\(yearRange.lowerBound) - \(yearRange.upperBound)")
                        .labelMedium()
                        .foregroundColor(currentTheme.secondaryText)
                } else {
                    Button("Set Year Range") {
                        // For now, set a common range - in full implementation would show year picker
                        withAnimation(.smooth) {
                            filter.publishedYearRange = 2000...2024
                        }
                        HapticFeedbackManager.shared.lightImpact()
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(currentTheme.primary)
                }
            }
            
            // Page Count Range
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack {
                    Text("Page Count")
                        .bodyMedium()
                        .foregroundColor(currentTheme.primaryText)
                    
                    Spacer()
                    
                    if let pageRange = filter.pageCountRange {
                        Button("Clear") {
                            withAnimation(.smooth) {
                                filter.pageCountRange = nil
                            }
                        }
                        .buttonStyle(.borderless)
                        .foregroundColor(currentTheme.primary)
                        .font(.caption)
                    }
                }
                
                if let pageRange = filter.pageCountRange {
                    Text("\(pageRange.lowerBound) - \(pageRange.upperBound) pages")
                        .labelMedium()
                        .foregroundColor(currentTheme.secondaryText)
                } else {
                    HStack(spacing: Theme.Spacing.sm) {
                        Button("Short (<200)") {
                            withAnimation(.smooth) {
                                filter.pageCountRange = 0...200
                            }
                        }
                        .buttonStyle(.bordered)
                        .font(.caption)
                        
                        Button("Medium (200-400)") {
                            withAnimation(.smooth) {
                                filter.pageCountRange = 200...400
                            }
                        }
                        .buttonStyle(.bordered)
                        .font(.caption)
                        
                        Button("Long (400+)") {
                            withAnimation(.smooth) {
                                filter.pageCountRange = 400...2000
                            }
                        }
                        .buttonStyle(.bordered)
                        .font(.caption)
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
}

// MARK: - Advanced Filter Components

struct AdvancedFilterChip: View {
    @Environment(\.appTheme) private var currentTheme
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void
    
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
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.smooth, value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    LibraryFilterView(filter: .constant(LibraryFilter.all))
}