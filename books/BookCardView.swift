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
            // Cover Image with Status Overlay (Always Fixed Height)
            ZStack(alignment: .topTrailing) {
                BookCoverImage(
                    imageURL: book.metadata?.imageURL?.absoluteString,
                    width: cardWidth,
                    height: imageHeight
                )
                .materialCard(shadow: true)
                
                // Status indicator using the new centralized badge
                if book.readingStatus != .toRead {
                    StatusBadge(status: book.readingStatus, style: .compact)
                        .padding(4)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                        .offset(x: -Theme.Spacing.xs, y: Theme.Spacing.xs)
                }
                
                // Favorite indicator
                if book.isFavorited {
                    Image(systemName: "heart.fill")
                        .font(.caption)
                        .foregroundColor(Color.theme.accentHighlight)
                        .background(
                            Circle()
                                .fill(.white)
                                .frame(width: 20, height: 20)
                        )
                        .offset(x: -Theme.Spacing.xs, y: Theme.Spacing.lg + 8)
                }
            }
            .frame(height: imageHeight) // Ensure consistent image area height
            
            // Book Information - Smart Layout
            if useFlexibleLayout {
                flexibleBookInfo
            } else {
                fixedBookInfo
            }
        }
        .frame(width: cardWidth)
        .contentShape(Rectangle()) // Makes the entire card tappable
    }
    
    // MARK: - Fixed Layout (for grid alignment)
    @ViewBuilder
    private var fixedBookInfo: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Title section (Fixed height)
            Text(book.metadata?.title ?? "Unknown Title")
                .titleSmall()
                .foregroundColor(Color.theme.primaryText)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(height: 36, alignment: .top) // Fixed height for 2 lines
            
            Spacer(minLength: 2)
            
            // Author section (Fixed height)
            Text(book.metadata?.authors.joined(separator: ", ") ?? "Unknown Author")
                .bodySmall()
                .foregroundColor(Color.theme.secondaryText)
                .lineLimit(1)
                .frame(height: 16, alignment: .top) // Fixed height for 1 line
            
            Spacer(minLength: 4)
            
            // Bottom section - Cultural info, rating, or spacer (Fixed height)
            VStack(alignment: .leading, spacing: 2) {
                // Priority 1: Cultural information
                if let originalLanguage = book.metadata?.originalLanguage,
                   originalLanguage != book.metadata?.language {
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: "globe")
                            .font(.caption2)
                            .foregroundColor(Color.theme.accentHighlight)
                        
                        Text(originalLanguage)
                            .labelSmall()
                            .foregroundColor(Color.theme.accentHighlight)
                    }
                    .frame(height: 16)
                    
                    // Rating on second line if space and rated
                    if let rating = book.rating, rating > 0 {
                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .font(.caption2)
                                    .foregroundColor(star <= rating ? Color.theme.accentHighlight : Color.theme.secondaryText.opacity(0.3))
                            }
                        }
                        .frame(height: 12)
                    } else {
                        // Spacer to maintain consistent height
                        Spacer()
                            .frame(height: 12)
                    }
                }
                // Priority 2: Rating only (if no cultural info)
                else if let rating = book.rating, rating > 0 {
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= rating ? "star.fill" : "star")
                                .font(.caption2)
                                .foregroundColor(star <= rating ? Color.theme.accentHighlight : Color.theme.secondaryText.opacity(0.3))
                        }
                    }
                    .frame(height: 16)
                    
                    Spacer()
                        .frame(height: 12)
                }
                // Priority 3: Empty space (maintains consistent height)
                else {
                    Spacer()
                        .frame(height: 28) // Same total height as cultural info + rating
                }
            }
            .frame(height: 28, alignment: .top) // Fixed height for bottom section
        }
        .frame(width: cardWidth, height: textAreaHeight, alignment: .top)
    }
    
    // MARK: - Flexible Layout (for standalone cards)
    @ViewBuilder
    private var flexibleBookInfo: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            // Title section (Natural height)
            Text(book.metadata?.title ?? "Unknown Title")
                .titleSmall()
                .foregroundColor(Color.theme.primaryText)
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
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: "globe")
                            .font(.caption2)
                            .foregroundColor(Color.theme.accentHighlight)
                        
                        Text(originalLanguage)
                            .labelSmall()
                            .foregroundColor(Color.theme.accentHighlight)
                    }
                }
                
                // Rating stars (if rated)
                if let rating = book.rating, rating > 0 {
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= rating ? "star.fill" : "star")
                                .font(.caption2)
                                .foregroundColor(star <= rating ? Color.theme.accentHighlight : Color.theme.secondaryText.opacity(0.3))
                        }
                    }
                }
            }
        }
        .frame(width: cardWidth, alignment: .leading)
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
            .foregroundColor(Theme.Color.SecondaryText)
        
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
            .foregroundColor(Theme.Color.SecondaryText)
    }
    .padding()
    .background(Color.theme.surface)
}