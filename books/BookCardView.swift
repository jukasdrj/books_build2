import SwiftUI

struct BookCardView: View {
    let book: UserBook
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Cover Image with Status Overlay
            ZStack(alignment: .topTrailing) {
                BookCoverImage(
                    imageURL: book.metadata?.imageURL?.absoluteString,
                    width: 140,
                    height: 200
                )
                .materialCard(shadow: true)
                
                // Status indicator
                if book.readingStatus != .toRead {
                    StatusBadgeCompact(status: book.readingStatus)
                        .offset(x: -Theme.Spacing.xs, y: Theme.Spacing.xs)
                }
                
                // Favorite indicator
                if book.isFavorited {
                    Image(systemName: "heart.fill")
                        .font(.caption)
                        .foregroundColor(Theme.Color.AccentHighlight)
                        .background(
                            Circle()
                                .fill(.white)
                                .frame(width: 20, height: 20)
                        )
                        .offset(x: -Theme.Spacing.xs, y: Theme.Spacing.lg + 8)
                }
            }
            
            // Book Information
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(book.metadata?.title ?? "Unknown Title")
                    .titleSmall()
                    .foregroundColor(Theme.Color.PrimaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text(book.metadata?.authors.joined(separator: ", ") ?? "Unknown Author")
                    .bodySmall()
                    .foregroundColor(Theme.Color.SecondaryText)
                    .lineLimit(1)
                
                // Rating stars (if rated)
                if let rating = book.rating, rating > 0 {
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= rating ? "star.fill" : "star")
                                .font(.caption2)
                                .foregroundColor(star <= rating ? Theme.Color.AccentHighlight : Theme.Color.SecondaryText.opacity(0.3))
                        }
                    }
                    .padding(.top, 2)
                }
                
                // Cultural information (if available)
                if let originalLanguage = book.metadata?.originalLanguage,
                   originalLanguage != book.metadata?.language {
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: "globe")
                            .font(.caption2)
                            .foregroundColor(Theme.Color.AccentHighlight)
                        
                        Text(originalLanguage)
                            .labelSmall()
                            .foregroundColor(Theme.Color.AccentHighlight)
                    }
                    .padding(.top, 2)
                }
            }
            .frame(maxWidth: 140, alignment: .leading)
        }
        .frame(width: 140)
        .contentShape(Rectangle()) // Makes the entire card tappable
    }
}

struct StatusBadgeCompact: View {
    let status: ReadingStatus
    
    var body: some View {
        HStack(spacing: 2) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)
            
            Text(statusText)
                .labelSmall()
                .foregroundColor(.white)
        }
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(.black.opacity(0.7))
        )
    }
    
    private var statusText: String {
        switch status {
        case .reading: return "Reading"
        case .read: return "Read"
        case .toRead: return "To Read"
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .read: return Theme.Color.Success
        case .reading: return Theme.Color.AccentHighlight  
        case .toRead: return Theme.Color.SecondaryText
        }
    }
}

#Preview {
    let metadata = BookMetadata(
        googleBooksID: "preview-id",
        title: "The Midnight Library: A Novel About Infinite Possibilities",
        authors: ["Matt Haig"],
        publishedDate: "2020",
        pageCount: 304,
        originalLanguage: "English"
    )
    
    let sampleBook = UserBook(
        readingStatus: .reading,
        isFavorited: true,
        rating: 5,
        metadata: metadata
    )
    
    return BookCardView(book: sampleBook)
        .padding()
        .background(Theme.Color.Surface)
}