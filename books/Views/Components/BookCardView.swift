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
            // Book cover with unified design and completeness indicator
            ZStack(alignment: .topTrailing) {
                UnifiedBookCoverView(
                    imageURL: book.metadata?.imageURL?.absoluteString,
                    width: 120,
                    height: 180,
                    style: .card
                )
                
                // Data completeness indicator
                DataCompletenessIndicator(book: book)
                    .offset(x: -4, y: 4)
            }
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
        .nativeCard()
        .nativeInteractive()
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
        var components: [String] = []
        
        // Title and author
        let title = book.metadata?.title ?? "Unknown Title"
        components.append(title)
        
        if let authors = book.metadata?.authors, !authors.isEmpty {
            components.append("by \(authors.joined(separator: ", "))")
        }
        
        // Status using accessibility label
        components.append("Status: \(book.readingStatus.accessibilityLabel)")
        
        // Rating
        if let rating = book.rating {
            components.append("Rated \(rating) out of 5 stars")
        }
        
        // Progress
        if book.readingStatus == .reading && book.readingProgress > 0 {
            let percentage = Int(book.readingProgress * 100)
            components.append("\(percentage) percent complete")
        }
        
        return components.joined(separator: ". ")
    }
}