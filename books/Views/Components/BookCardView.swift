//
//  BookCardView.swift
//  books
//
//  Unified card design with Material Design 3 consistency
//

import SwiftUI

struct BookCardView: View {
    let book: UserBook
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Book cover with unified design
            UnifiedBookCoverView(
                imageURL: book.metadata?.imageURL?.absoluteString,
                width: 120,
                height: 180,
                style: .card
            )
            .accessibilityHidden(true) // Cover is decorative, info is in text
            
            // Book information with standardized layout
            UnifiedBookInfoView(
                title: book.metadata?.title ?? "Unknown Title",
                authors: book.metadata?.authors ?? [],
                rating: book.rating,
                status: book.readingStatus,
                progress: book.readingProgress,
                language: book.metadata?.language,
                layout: .card
            )
        }
        .frame(width: UnifiedBookCard.Dimensions.cardWidth, height: UnifiedBookCard.Dimensions.cardHeight)
        .padding(Theme.Spacing.sm)
        .materialCard(elevation: Theme.Elevation.card)
        .materialInteractive(
            pressedScale: UnifiedBookCard.InteractiveStates.pressedScale,
            pressedOpacity: UnifiedBookCard.InteractiveStates.pressedOpacity
        )
        // Enhanced accessibility
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityHint("Double tap to view book details")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: "View Details") {
            // This will be handled by the NavigationLink
        }
    }
    
    // MARK: - Enhanced Accessibility
    
    private var accessibilityDescription: String {
        var description = book.metadata?.title ?? "Unknown Title"
        
        if let authors = book.metadata?.authors, !authors.isEmpty {
            description += " by \(authors.joined(separator: ", "))"
        }
        
        if let rating = book.rating {
            description += ". Rated \(rating) out of 5 stars"
        } else {
            description += ". Not rated"
        }
        
        if book.readingStatus != .toRead {
            description += ". Status: \(book.readingStatus.rawValue)"
            
            if book.readingStatus == .reading && book.readingProgress > 0 {
                description += ". \(Int(book.readingProgress * 100))% complete"
            }
        }
        
        return description
    }
}