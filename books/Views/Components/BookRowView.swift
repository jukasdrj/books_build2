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
                    .lineLimit(2)
                Text(userBook.metadata?.authors.joined(separator: ", ") ?? "Unknown Author")
                    .bodyMedium()
                    .foregroundStyle(Color.theme.secondaryText)
                
                if userBook.readingStatus != .toRead {
                    StatusBadge(status: userBook.readingStatus, style: .capsule)
                        .padding(.top, 2)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(userBook.metadata?.title ?? "Unknown Title") by \(userBook.metadata?.authors.joined(separator: ", ") ?? "Unknown Author")")
        .accessibilityHint("Double tap to view book details")
    }
}