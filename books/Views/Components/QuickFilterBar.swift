//
//  QuickFilterBar.swift
//  books
//
//  Enhanced iOS 26 filtering interface with progressive enhancement
//  Features intelligent quick filters with Material Design 3 and Liquid Glass compatibility
//

import SwiftUI

enum QuickFilterType: String, CaseIterable {
    case all = "All"
    case wishlist = "Wishlist"
    case owned = "Owned"
    case favorites = "Favorites"
    case currentlyReading = "Reading"
    case completed = "Completed"
    case toRead = "To Read"
    
    var icon: String {
        switch self {
        case .all: return "books.vertical"
        case .wishlist: return "heart"
        case .owned: return "checkmark.circle"
        case .favorites: return "star.fill"
        case .currentlyReading: return "book"
        case .completed: return "checkmark.circle.fill"
        case .toRead: return "plus.circle"
        }
    }
}

struct QuickFilterBar: View {
    @Binding var filter: LibraryFilter
    @Binding var selectedQuickFilter: QuickFilterType?
    @Environment(\.appTheme) private var theme
    
    var body: some View {
        VStack(spacing: 0) {
            mainFilterBar
        }
        .onAppear {
            loadContextualSuggestions()
        }
    }
    
    // MARK: - Main Filter Bar
    @ViewBuilder
    private var mainFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.md) {
                clearAllButton
                
                ForEach(QuickFilterType.allCases, id: \.self) { type in
                    filterChip(for: type)
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
        }
    }
    
    // MARK: - Clear All Button
    @ViewBuilder
    private var clearAllButton: some View {
        if filter.isActive {
            Button {
                withAnimation(.smooth) {
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
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .foregroundStyle(.primary)
                .background {
                    Capsule()
                        .fill(Color.gray.opacity(0.1))
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
    }
    
    // MARK: - Filter Chips
    @ViewBuilder
    private func filterChip(for type: QuickFilterType) -> some View {
        let isSelected = selectedQuickFilter == type
        let primaryColor = theme.primary
        
        Button {
            withAnimation(.smooth) {
                applyFilter(type: type)
            }
            HapticFeedbackManager.shared.lightImpact()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: type.icon)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : theme.primary)
                
                Text(type.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .foregroundStyle(isSelected ? .white : .primary)
            .background {
                Capsule()
                    .fill(isSelected ? primaryColor : Color.gray.opacity(0.1))
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
            .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .animation(.smooth, value: isSelected)
        .accessibilityLabel("\(type.rawValue) filter")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
    
    // MARK: - Filter Logic
    private func applyFilter(type: QuickFilterType) {
        switch type {
        case .all:
            filter = LibraryFilter.all
            selectedQuickFilter = nil
        case .wishlist:
            filter = LibraryFilter.wishlistOnly
            selectedQuickFilter = .wishlist
        case .owned:
            filter = LibraryFilter(showOwnedOnly: true)
            selectedQuickFilter = .owned
        case .favorites:
            filter = LibraryFilter.favorites
            selectedQuickFilter = .favorites
        case .currentlyReading:
            filter = LibraryFilter.currentlyReading
            selectedQuickFilter = .currentlyReading
        case .completed:
            var completedFilter = LibraryFilter()
            completedFilter.readingStatus = [.read]
            filter = completedFilter
            selectedQuickFilter = .completed
        case .toRead:
            var toReadFilter = LibraryFilter()
            toReadFilter.readingStatus = [.toRead]
            filter = toReadFilter
            selectedQuickFilter = .toRead
        }
    }
    
    private func loadContextualSuggestions() {
        // Placeholder for contextual suggestions loading
        // This could analyze user behavior and suggest relevant filters
    }
}

#Preview {
    QuickFilterBar(
        filter: .constant(LibraryFilter.all),
        selectedQuickFilter: .constant(nil)
    )
}