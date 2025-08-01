import SwiftUI

struct BookCardView: View {
    let book: UserBook
    let useFlexibleLayout: Bool
    
    // Define consistent dimensions
    private let cardWidth: CGFloat = 140
    private let imageHeight: CGFloat = 200
    private let textAreaHeight: CGFloat = 85 // Fixed height for text area when in grid
    
    init(book: UserBook, useFlexibleLayout: Bool = false) {
        self.book = book
        self.useFlexibleLayout = useFlexibleLayout
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Cover Image with Status Overlay
            coverImageWithOverlay
            
            // Book Information - Smart Layout
            if useFlexibleLayout {
                flexibleBookInfo
            } else {
                fixedBookInfo
            }
        }
        .frame(width: cardWidth)
        .contentShape(Rectangle()) // Makes the entire card tappable
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityHint("Double tap to view book details")
    }
    
    // MARK: - Cover Image with Overlay
    @ViewBuilder
    private var coverImageWithOverlay: some View {
        ZStack(alignment: .topTrailing) {
            BookCoverImage(
                imageURL: book.metadata?.imageURL?.absoluteString,
                width: cardWidth,
                height: imageHeight
            )
            .materialCard()
            
            // Status and favorite indicators
            VStack(alignment: .trailing, spacing: Theme.Spacing.xs) {
                // Status indicator
                if book.readingStatus != .toRead {
                    StatusBadge(status: book.readingStatus, style: .compact)
                        .padding(Theme.Spacing.xs)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
                
                // Favorite indicator
                if book.isFavorited {
                    Image(systemName: "heart.fill")
                        .labelSmall()
                        .foregroundColor(Color.theme.accentHighlight)
                        .padding(Theme.Spacing.xs)
                        .background(
                            Circle()
                                .fill(Material.regular)
                        )
                }
            }
            .padding(Theme.Spacing.xs)
        }
        .frame(height: imageHeight) // Ensure consistent image area height
    }
    
    // MARK: - Fixed Layout (for grid alignment)
    @ViewBuilder
    private var fixedBookInfo: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Title section (Fixed height)
            Text(book.metadata?.title ?? "Unknown Title")
                .titleSmall()
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(height: 36, alignment: .top)
            
            Spacer(minLength: 2)
            
            // Author section (Fixed height)
            Text(book.metadata?.authors.joined(separator: ", ") ?? "Unknown Author")
                .bodySmall()
                .foregroundColor(Color.theme.secondaryText)
                .lineLimit(1)
                .frame(height: 16, alignment: .top)
            
            Spacer(minLength: 4)
            
            // Bottom section - Cultural info, rating, or spacer (Fixed height)
            bottomInfoSection
                .frame(height: 28, alignment: .top)
        }
        .frame(width: cardWidth, height: textAreaHeight, alignment: .top)
    }
    
    // MARK: - Flexible Layout (for standalone cards)
    @ViewBuilder
    private var flexibleBookInfo: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            // Title section (Natural height)
            Text(book.metadata?.title ?? "Unknown Title")
                .titleSmall() // For standalone cards, .titleSmall() is more legible
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            // Author section
            Text(book.metadata?.authors.joined(separator: ", ") ?? "Unknown Author")
                .bodySmall()
                .foregroundColor(Color.theme.secondaryText)
                .lineLimit(1)
            
            // Cultural information and rating with natural spacing
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                // Cultural information
                if let originalLanguage = book.metadata?.originalLanguage,
                   originalLanguage != book.metadata?.language {
                    culturalInfoBadge(language: originalLanguage)
                }
                
                // Rating stars (if rated)
                if let rating = book.rating, rating > 0 {
                    ratingStars(rating: rating)
                }
            }
        }
        .frame(width: cardWidth, alignment: .leading)
    }
    
    // MARK: - Helper Components
    @ViewBuilder
    private var bottomInfoSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Priority 1: Cultural information
            if let originalLanguage = book.metadata?.originalLanguage,
               originalLanguage != book.metadata?.language {
                culturalInfoBadge(language: originalLanguage)
                    .frame(height: 16)
                
                // Rating on second line if space and rated
                if let rating = book.rating, rating > 0 {
                    ratingStars(rating: rating)
                        .frame(height: 12)
                } else {
                    Spacer().frame(height: 12)
                }
            }
            // Priority 2: Rating only (if no cultural info)
            else if let rating = book.rating, rating > 0 {
                ratingStars(rating: rating)
                    .frame(height: 16)
                Spacer().frame(height: 12)
            }
            // Priority 3: Empty space (maintains consistent height)
            else {
                Spacer().frame(height: 28)
            }
        }
    }
    
    @ViewBuilder
    private func culturalInfoBadge(language: String) -> some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: "globe")
                .labelSmall()
                .foregroundColor(Color.theme.accentHighlight)
            
            Text(language)
                .culturalTag()
                .foregroundColor(Color.theme.accentHighlight)
        }
    }
    
    @ViewBuilder
    private func ratingStars(rating: Int) -> some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .labelSmall()
                    .foregroundColor(star <= rating ? Color.theme.accentHighlight : Color.theme.secondaryText.opacity(0.3))
            }
        }
    }
    
    // MARK: - Accessibility
    private var accessibilityDescription: String {
        let title = book.metadata?.title ?? "Unknown Title"
        let author = book.metadata?.authors.joined(separator: ", ") ?? "Unknown Author"
        let status = book.readingStatus.rawValue
        let rating = book.rating != nil ? "\(book.rating!) star rating" : "No rating"
        let favorite = book.isFavorited ? "Favorited" : ""
        
        return "\(title) by \(author). Status: \(status). \(rating). \(favorite)"
    }
}

#Preview {
    VStack(spacing: Theme.Spacing.lg) {
        // Grid alignment example
        HStack(spacing: Theme.Spacing.md) {
            BookCardView(book: UserBook(
                readingStatus: .read,
                metadata: BookMetadata(
                    googleBooksID: "1",
                    title: "Short",
                    authors: ["Author One"]
                )
            ), useFlexibleLayout: false)
            
            BookCardView(book: UserBook(
                readingStatus: .reading,
                isFavorited: true,
                rating: 5,
                metadata: BookMetadata(
                    googleBooksID: "2",
                    title: "The Midnight Library: A Novel About Infinite Possibilities",
                    authors: ["Matt Haig"],
                    language: "English",
                    originalLanguage: "Spanish"
                )
            ), useFlexibleLayout: false)
        }
        
        Text("Fixed Layout (Grid)")
            .labelSmall()
            .foregroundColor(Color.theme.secondaryText)
        
        Divider()
        
        // Flexible layout example
        BookCardView(book: UserBook(
            readingStatus: .read,
            metadata: BookMetadata(
                googleBooksID: "3",
                title: "Brief",
                authors: ["Solo Author"]
            )
        ), useFlexibleLayout: true)
        
        Text("Flexible Layout (Standalone)")
            .labelSmall()
            .foregroundColor(Color.theme.secondaryText)
    }
    .padding()
    .background(Color.theme.surface)
    .preferredColorScheme(.dark) // Test dark mode
}