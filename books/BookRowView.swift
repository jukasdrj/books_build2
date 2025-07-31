// books-buildout/books/BookRowView.swift
import SwiftUI

struct BookRowView: View {
    var userBook: UserBook
    
    var body: some View {
        HStack(spacing: 15) {
            BookCoverImage(
                imageURL: userBook.metadata?.imageURL?.absoluteString,
                width: 60,
                height: 90
            )
            
            VStack(alignment: .leading) {
                Text(userBook.metadata?.title ?? "Unknown Title")
                    .titleMedium()
                    .foregroundColor(Theme.Color.PrimaryText)
                    .lineLimit(2)
                Text(userBook.metadata?.authors.joined(separator: ", ") ?? "Unknown Author")
                    .bodyMedium()
                    .foregroundStyle(Theme.Color.SecondaryText)
                
                if userBook.readingStatus != .toRead {
                    Text(userBook.readingStatus.rawValue)
                        .labelSmall()
                        .fontWeight(.medium)
                        .padding(.vertical, 2)
                        .padding(.horizontal, 6)
                        .background(Theme.Color.PrimaryAction.opacity(0.2))
                        .foregroundColor(Theme.Color.PrimaryAction)
                        .clipShape(Capsule())
                        .padding(.top, 2)
                }
            }
        }
        .padding(.vertical, 4)
    }
}