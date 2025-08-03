//
//  BookCardView.swift
//  Booky
//
//  Created by Charnold on 12/10/2023.
//

import SwiftUI

struct BookCardView: View {
    let book: Book
    var body: some View {
        VStack (alignment: .leading, spacing: Theme.Spacing.sm){
            BookCoverView(book: book, width: 150, height: 220)
            
            VStack (alignment: .leading){
                Text(book.title)
                    .font(.headline)
                    .lineLimit(1)
                Text(book.author)
                    .font(.subheadline)
                    .lineLimit(1)
            }
        }
        .padding(Theme.Spacing.md)
        .materialCard()
        .materialInteractive()
    }
}

#Preview {
    BookCardView(book: Book(title: "Atomic Habit", author: "James Clear", dateAdded: .now, dateStarted: .now, dateCompleted: .now, summary: "", rating: 4, status: .completed))
}
