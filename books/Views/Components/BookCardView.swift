import SwiftUI

struct BookCardView: View {
    let book: UserBook
    let useFlexibleLayout: Bool
    
    // Define consistent dimensions
    private let cardWidth: CGFloat = 140
    private let imageHeight: CGFloat = 200
    private let textAreaHeight: CGFloat = 95 // Increased for better rating display
    
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
        .materialCard(
            backgroundColor: Color.theme.cardBackground,
            cornerRadius: Theme.CornerRadius.medium,
            elevation: Theme.Elevation.card
        )
        .overlay(
            // Subtle boho border gradient
            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.theme.primary.opacity(0.1),
                            Color.theme.tertiary.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        )
        .materialInteractive()
        .contentShape(Rectangle()) // Makes the entire card tappable
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityHint("Double tap to view book details")
    }
    
    // MARK: - Cover Image with Enhanced Overlay
    @ViewBuilder
    private var coverImageWithOverlay: some View {
        ZStack(alignment: .topTrailing) {
            BookCoverImage(
                imageURL: book.metadata?.imageURL?.absoluteString,
                width: cardWidth,
                height: imageHeight
            )
            .materialCard(cornerRadius: Theme.CornerRadius.small)
            
            // Enhanced status and indicators overlay
            VStack(alignment: .trailing, spacing: Theme.Spacing.xs) {
                // Status indicator with beautiful styling
                if book.readingStatus != .toRead {
                    StatusBadge(status: book.readingStatus, style: .compact)
                        .padding(Theme.Spacing.xs)
                        .background(
                            Color.black.opacity(0.6)
                                .background(.ultraThinMaterial)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.small))
                }
            }
            .padding(Theme.Spacing.xs)
        }
        .frame(height: imageHeight) // Ensure consistent image area height
    }
    
    // MARK: - Fixed Layout (for grid alignment)
    @ViewBuilder
    private var fixedBookInfo: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            // Title section with enhanced styling
            Text(book.metadata?.title ?? "Unknown Title")
                .titleSmall()
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(height: 38, alignment: .top)
                .foregroundColor(Color.theme.primaryText)
            
            // Author section with enhanced styling
            Text(book.metadata?.authors.joined(separator: ", ") ?? "Unknown Author")
                .bodySmall()
                .foregroundColor(Color.theme.secondaryText)
                .lineLimit(1)
                .frame(height: 18, alignment: .top)
            
            // Enhanced bottom section with prominent rating display
            enhancedBottomInfoSection
                .frame(height: 36, alignment: .top)
        }
        .frame(width: cardWidth, height: textAreaHeight, alignment: .top)
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.xs)
    }
    
    // MARK: - Flexible Layout (for standalone cards)
    @ViewBuilder
    private var flexibleBookInfo: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            // Title section
            Text(book.metadata?.title ?? "Unknown Title")
                .titleSmall()
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .foregroundColor(Color.theme.primaryText)
            
            // Author section
            Text(book.metadata?.authors.joined(separator: ", ") ?? "Unknown Author")
                .bodySmall()
                .foregroundColor(Color.theme.secondaryText)
                .lineLimit(1)
            
            // Enhanced information with natural spacing
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                // Rating first (most prominent)
                if let rating = book.rating, rating > 0 {
                    enhancedRatingStars(rating: rating)
                }
                
                // Cultural information
                if let originalLanguage = book.metadata?.originalLanguage,
                   originalLanguage != book.metadata?.language {
                    enhancedCulturalBadge(language: originalLanguage)
                }
            }
        }
        .frame(width: cardWidth, alignment: .leading)
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.xs)
    }
    
    // MARK: - Enhanced Helper Components with Boho Styling ✨
    
    @ViewBuilder
    private var enhancedBottomInfoSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            // Priority 1: Rating (always show if available, more prominent)
            if let rating = book.rating, rating > 0 {
                enhancedRatingStars(rating: rating)
                    .frame(height: 18)
            } else {
                Spacer().frame(height: 18)
            }
            
            // Priority 2: Cultural information
            if let originalLanguage = book.metadata?.originalLanguage,
               originalLanguage != book.metadata?.language {
                enhancedCulturalBadge(language: originalLanguage)
                    .frame(height: 18)
            } else {
                Spacer().frame(height: 18)
            }
        }
    }
    
    @ViewBuilder
    private func enhancedCulturalBadge(language: String) -> some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: "globe")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(Color.theme.tertiary)
            
            Text(language)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Color.theme.tertiary)
        }
        .padding(.horizontal, Theme.Spacing.xs)
        .padding(.vertical, 2)
        .background(
            Color.theme.tertiary.opacity(0.12)
                .background(.ultraThinMaterial)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.theme.tertiary.opacity(0.3), lineWidth: 0.5)
        )
    }
    
    @ViewBuilder
    private func enhancedRatingStars(rating: Int) -> some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(
                        star <= rating ? 
                        Color.theme.warning : // Golden amber for filled stars
                        Color.theme.secondaryText.opacity(0.3)
                    )
                    .shadow(
                        color: star <= rating ? Color.theme.warning.opacity(0.3) : Color.clear,
                        radius: 1,
                        x: 0,
                        y: 0.5
                    )
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(
            Color.theme.cardBackground
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
    
    // MARK: - Legacy components for backward compatibility
    @ViewBuilder
    private func culturalInfoBadge(language: String) -> some View {
        enhancedCulturalBadge(language: language)
    }
    
    @ViewBuilder
    private func ratingStars(rating: Int) -> some View {
        enhancedRatingStars(rating: rating)
    }
    
    // MARK: - Accessibility
    private var accessibilityDescription: String {
        let title = book.metadata?.title ?? "Unknown Title"
        let author = book.metadata?.authors.joined(separator: ", ") ?? "Unknown Author"
        let status = book.readingStatus.rawValue
        let rating = book.rating != nil ? "\(book.rating!) star rating" : "No rating"
        
        return "\(title) by \(author). Status: \(status). \(rating)."
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