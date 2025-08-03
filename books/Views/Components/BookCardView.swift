//
//  BookCardView.swift
//  books
//
//  Clean, uniform card design with purple boho styling
//

import SwiftUI

struct BookCardView: View {
    let book: UserBook
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Book cover - fixed size for uniformity
            BookCoverImage(
                imageURL: book.metadata?.imageURL?.absoluteString,
                width: 120,
                height: 180
            )
            .overlay(alignment: .topTrailing) {
                if book.isFavorited {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color.theme.error)
                        .background(Color.theme.surface.opacity(0.9))
                        .clipShape(Circle())
                        .padding(Theme.Spacing.xs)
                }
            }
            
            // Book information - fixed height for uniformity
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(book.metadata?.title ?? "Unknown Title")
                    .titleMedium()
                    .lineLimit(2)
                    .foregroundColor(Color.theme.primaryText)
                    .frame(height: 44, alignment: .top) // Fixed height for 2 lines
                
                Text(book.metadata?.authors.joined(separator: ", ") ?? "Unknown Author")
                    .bodyMedium()
                    .lineLimit(1)
                    .foregroundColor(Color.theme.secondaryText)
                    .frame(height: 20, alignment: .top) // Fixed height for 1 line
                
                // Bottom row - rating and status
                HStack(spacing: Theme.Spacing.sm) {
                    if let rating = book.rating {
                        enhancedRatingStars(rating: rating)
                    } else {
                        // Placeholder to maintain consistent spacing
                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { _ in
                                Image(systemName: "star")
                                    .font(.system(size: 10))
                                    .foregroundColor(Color.theme.outline.opacity(0.3))
                            }
                        }
                    }
                    
                    Spacer()
                    
                    if book.readingStatus != .toRead {
                        StatusBadge(status: book.readingStatus, style: .compact)
                    }
                }
                .frame(height: 16) // Fixed height for consistency
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: 140, height: 260) // Fixed card size for perfect uniformity
        .padding(Theme.Spacing.sm)
        .materialCard()
        .materialInteractive()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(book.metadata?.title ?? "Unknown Title") by \(book.metadata?.authors.joined(separator: ", ") ?? "Unknown Author")")
        .accessibilityHint("Double tap to view book details")
    }
    
    // MARK: - Enhanced Rating Stars (Compact for uniform cards)
    
    @ViewBuilder
    private func enhancedRatingStars(rating: Int) -> some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(star <= rating ? Color.theme.warning : Color.theme.outline.opacity(0.3))
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        LazyVGrid(columns: [
            GridItem(.fixed(140), spacing: Theme.Spacing.md),
            GridItem(.fixed(140), spacing: Theme.Spacing.md)
        ], spacing: Theme.Spacing.lg) {
            ForEach(sampleUserBooks) { book in
                BookCardView(book: book)
            }
        }
        .padding(Theme.Spacing.md)
    }
    .background(Color.theme.surface)
}

// MARK: - Sample Data for Preview

private let sampleUserBooks: [UserBook] = [
    {
        let book = UserBook(
            readingStatus: .reading,
            rating: 4
        )
        let metadata = BookMetadata(
            googleBooksID: "sample1",
            title: "The Seven Husbands of Evelyn Hugo",
            authors: ["Taylor Jenkins Reid"],
            pageCount: 400,
            imageURL: URL(string: "https://books.google.com/books/content?id=example1"),
            language: "en"
        )
        book.metadata = metadata
        return book
    }(),
    {
        let book = UserBook(
            readingStatus: .read,
            isFavorited: true,
            rating: 5
        )
        let metadata = BookMetadata(
            googleBooksID: "sample2",
            title: "Klara and the Sun",
            authors: ["Kazuo Ishiguro"],
            pageCount: 320,
            imageURL: URL(string: "https://books.google.com/books/content?id=example2"),
            language: "en"
        )
        book.metadata = metadata
        return book
    }(),
    {
        let book = UserBook(
            readingStatus: .toRead
        )
        let metadata = BookMetadata(
            googleBooksID: "sample3",
            title: "Persepolis",
            authors: ["Marjane Satrapi"],
            pageCount: 160,
            imageURL: URL(string: "https://books.google.com/books/content?id=example3"),
            language: "fr"
        )
        book.metadata = metadata
        return book
    }(),
    {
        let book = UserBook(
            readingStatus: .dnf,
            rating: 2
        )
        let metadata = BookMetadata(
            googleBooksID: "sample4",
            title: "A Very Long Book Title That Should Be Truncated",
            authors: ["Author With Very Long Name"],
            language: "es"
        )
        book.metadata = metadata
        return book
    }()
]