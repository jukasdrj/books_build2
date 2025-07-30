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
                    .font(.headline)
                    .lineLimit(2)
                Text(userBook.metadata?.authors.joined(separator: ", ") ?? "Unknown Author")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                if userBook.readingStatus != .toRead {
                    Text(userBook.readingStatus.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.vertical, 2)
                        .padding(.horizontal, 6)
                        .background(Color.accentColor.opacity(0.2))
                        .clipShape(Capsule())
                        .padding(.top, 2)
                }
            }
        }
        .padding(.vertical, 4)
    }
}