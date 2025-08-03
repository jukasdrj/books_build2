//
//  LibraryView.swift
//  Booky
//
//  Created by Charnold on 11/10/2023.
//

import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Book.title, order: .forward) private var books: [Book]
    @State private var searchText: String = ""
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                let columns = [GridItem(.adaptive(minimum: 150, maximum: 200))]
                
                LazyVGrid(columns: columns, spacing: Theme.Spacing.lg) {
                    ForEach(books) { book in
                        NavigationLink {
                            EditBookView(book: book)
                        } label: {
                            BookCardView(book: book)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("Library")
            .searchable(text: $searchText)
        }
    }
}


#Preview {
    LibraryView()
        .modelContainer(for: Book.self, inMemory: true)
}
