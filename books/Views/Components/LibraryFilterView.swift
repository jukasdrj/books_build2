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
    
    var isActive: Bool {
        return readingStatus != Set(ReadingStatus.allCases) ||
               showWishlistOnly ||
               showOwnedOnly ||
               showFavoritesOnly ||
               sortBy != .dateAdded
    }
    
    static let all = LibraryFilter()
    static let wishlistOnly = LibraryFilter(showWishlistOnly: true)
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
                    
                    // Sorting Section
                    sortingSection
                    
                    // Reading Status Section
                    readingStatusSection
                }
                .padding(Theme.Spacing.lg)
            }
            .background(currentTheme.background)
            .navigationTitle("Filter Library")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        withAnimation(.smooth) {
                            filter = LibraryFilter.all
                        }
                        HapticFeedbackManager.shared.lightImpact()
                    }
                    .nativeTextButton()
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
        .nativeCard()
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
        .nativeCard()
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
                .nativeTextButton()
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
        .nativeCard()
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

#Preview {
    LibraryFilterView(filter: .constant(LibraryFilter.all))
}