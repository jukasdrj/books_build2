import SwiftUI

struct QuickFilterBar: View {
    @Environment(\.appTheme) private var theme
    @Binding var filter: LibraryFilter
    let onShowFullFilters: () -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.sm) {
                // Show All button when filters are active
                if filter.isActive {
                    Button("Show All") {
                        withAnimation(.smooth) {
                            filter = LibraryFilter.all
                        }
                        HapticFeedbackManager.shared.lightImpact()
                    }
                    .materialChip(isSelected: false, backgroundColor: theme.tertiaryContainer)
                }
                
                // Reading status chips
                ForEach(ReadingStatus.allCases, id: \.self) { status in
                    let isSelected = filter.readingStatus == [status]
                    
                    Button(action: {
                        withAnimation(.smooth) {
                            if isSelected {
                                // If this status is the only one selected, show all statuses
                                filter.readingStatus = Set(ReadingStatus.allCases)
                            } else {
                                // Select only this status
                                filter.readingStatus = [status]
                            }
                        }
                        HapticFeedbackManager.shared.lightImpact()
                    }) {
                        HStack(spacing: Theme.Spacing.xs) {
                            Circle()
                                .fill(status.textColor)
                                .frame(width: 8, height: 8)
                            
                            Text(status.rawValue)
                                .labelMedium()
                        }
                    }
                    .materialChip(isSelected: isSelected)
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
        .padding(.vertical, Theme.Spacing.sm)
        .background(theme.surface)
    }
}

#Preview {
    QuickFilterBar(filter: .constant(LibraryFilter.all)) {
        print("Show full filters")
    }
}