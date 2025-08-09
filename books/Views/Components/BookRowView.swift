//
//  BookRowView.swift
//  books
//
//  Unified row design with Material Design 3 consistency
//

import SwiftUI

struct BookRowView: View {
    @Environment(\.appTheme) private var theme
    let userBook: UserBook
    
    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Book cover with unified design
            UnifiedBookCoverView(
                imageURL: userBook.metadata?.imageURL?.absoluteString,
                width: 60,
                height: 90,
                style: .row
            )
            
            // Book information with standardized layout
            UnifiedBookInfoView(
                title: userBook.metadata?.title ?? "Unknown Title",
                authors: userBook.metadata?.authors ?? [],
                rating: userBook.rating,
                status: userBook.readingStatus,
                progress: userBook.readingProgress,
                language: userBook.metadata?.language,
                layout: .row
            )
            
            Spacer()
            
            // Cultural language indicator (consistent with card design)
            if let language = userBook.metadata?.language, language != "en" {
                UnifiedLanguageIndicator(language: language)
            }
        }
        .frame(minHeight: UnifiedBookCard.Dimensions.rowHeight)
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(theme.surface)
        .materialCard(
            elevation: Theme.Elevation.level1
        )
        .materialInteractive(
            pressedScale: UnifiedBookCard.InteractiveStates.rowPressedScale,
            pressedOpacity: UnifiedBookCard.InteractiveStates.pressedOpacity
        )
        .contentShape(Rectangle())
        // Enhanced accessibility
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityHint("Double tap to view book details")
        .accessibilityAddTraits(.isButton)
    }
    
    // MARK: - Enhanced Accessibility
    
    private var accessibilityDescription: String {
        var description = userBook.metadata?.title ?? "Unknown Title"
        
        if let authors = userBook.metadata?.authors, !authors.isEmpty {
            description += " by \(authors.joined(separator: ", "))"
        }
        
        if let rating = userBook.rating {
            description += ". Rated \(rating) out of 5 stars"
        }
        
        if userBook.readingStatus != .toRead {
            description += ". Status: \(userBook.readingStatus.rawValue)"
            
            if userBook.readingStatus == .reading && userBook.readingProgress > 0 {
                description += ". \(Int(userBook.readingProgress * 100))% complete"
            }
        }
        
        if let language = userBook.metadata?.language, language != "en" {
            description += ". Language: \(language)"
        }
        
        return description
    }
}