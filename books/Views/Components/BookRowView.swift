// books-buildout/books/BookRowView.swift
import SwiftUI

struct BookRowView: View {
    var userBook: UserBook
    
    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            BookCoverImage(
                imageURL: userBook.metadata?.imageURL?.absoluteString,
                width: 60,
                height: 90
            )
            
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text(userBook.metadata?.title ?? "Unknown Title")
                    .titleMedium()
                    .lineLimit(2)
                    .foregroundColor(Color.theme.primaryText)
                
                Text(userBook.metadata?.authors.joined(separator: ", ") ?? "Unknown Author")
                    .bodyMedium()
                    .foregroundStyle(Color.theme.secondaryText)
                    .lineLimit(1)
                
                // Bottom row - rating and status
                HStack(spacing: Theme.Spacing.sm) {
                    if let rating = userBook.rating {
                        enhancedRowRatingStars(rating: rating)
                    }
                    
                    Spacer()
                    
                    if userBook.readingStatus != .toRead {
                        StatusBadge(status: userBook.readingStatus, style: .compact)
                    }
                }
                
                // Reading progress for current reads
                if userBook.readingStatus == .reading && userBook.readingProgress > 0 {
                    HStack(spacing: Theme.Spacing.sm) {
                        ProgressView(value: userBook.readingProgress)
                            .progressViewStyle(LinearProgressViewStyle(tint: Color.theme.primary))
                            .frame(width: 100)
                            .scaleEffect(y: 0.6)
                        
                        Text("\(Int(userBook.readingProgress * 100))%")
                            .labelSmall()
                            .foregroundColor(Color.theme.secondaryText)
                    }
                }
            }
            
            Spacer()
            
            // Cultural language indicator
            if let primaryLanguage = userBook.metadata?.language, primaryLanguage != "en" {
                Text(primaryLanguage.uppercased())
                    .labelSmall()
                    .fontWeight(.semibold)
                    .foregroundColor(Color.theme.tertiary)
                    .padding(.horizontal, Theme.Spacing.xs)
                    .padding(.vertical, 2)
                    .background(Color.theme.tertiary.opacity(0.1))
                    .cornerRadius(Theme.CornerRadius.small)
            }
            
            // Favorite indicator
            if userBook.isFavorited {
                Image(systemName: "heart.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color.theme.error)
            }
        }
        .padding(.vertical, Theme.Spacing.sm)
        .materialInteractive()
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(userBook.metadata?.title ?? "Unknown Title") by \(userBook.metadata?.authors.joined(separator: ", ") ?? "Unknown Author")")
        .accessibilityHint("Double tap to view book details")
    }
    
    // MARK: - Enhanced Rating Stars for Row Layout
    
    @ViewBuilder
    private func enhancedRowRatingStars(rating: Int) -> some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(star <= rating ? Color.theme.warning : Color.theme.outline.opacity(0.3))
            }
            
            Text("(\(rating))")
                .labelSmall()
                .foregroundColor(Color.theme.warning)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: Theme.Spacing.md) {
        ForEach(sampleRowBooks) { book in
            BookRowView(userBook: book)
            Divider()
        }
    }
    .padding(Theme.Spacing.md)
    .background(Color.theme.surface)
}

// MARK: - Sample Data for Preview

private let sampleRowBooks: [UserBook] = [
    {
        let book = UserBook(
            readingStatus: .reading,
            isFavorited: true,
            rating: 4,
            currentPage: 120
        )
        let metadata = BookMetadata(
            googleBooksID: "row1",
            title: "The Seven Husbands of Evelyn Hugo",
            authors: ["Taylor Jenkins Reid"],
            pageCount: 400,
            imageURL: URL(string: "https://books.google.com/books/content?id=example1"),
            language: "en"
        )
        book.metadata = metadata
        book.readingProgress = 0.3
        return book
    }(),
    {
        let book = UserBook(
            readingStatus: .read,
            rating: 5
        )
        let metadata = BookMetadata(
            googleBooksID: "row2",
            title: "Persepolis",
            authors: ["Marjane Satrapi"],
            pageCount: 160,
            imageURL: URL(string: "https://books.google.com/books/content?id=example2"),
            language: "fr"
        )
        book.metadata = metadata
        return book
    }(),
    {
        let book = UserBook(
            readingStatus: .toRead
        )
        let metadata = BookMetadata(
            googleBooksID: "row3",
            title: "Klara and the Sun",
            authors: ["Kazuo Ishiguro"],
            language: "en"
        )
        book.metadata = metadata
        return book
    }()
]