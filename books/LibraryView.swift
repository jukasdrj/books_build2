// books-buildout/books/LibraryView.swift
import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: [SortDescriptor(\UserBook.dateAdded, order: .reverse)]) 
    private var allBooks: [UserBook]
    
    private var libraryBooks: [UserBook] {
        allBooks.filter { !$0.onWishlist && $0.readingStatus != .toRead }
    }

    var body: some View {
        NavigationStack {
            Group {
                if libraryBooks.isEmpty {
                    ContentUnavailableView {
                        Label("Your Library is Empty", systemImage: "book.closed")
                    } description: {
                        Text("Add a book from the Search tab to get started.")
                    }
                } else {
                    List {
                        ForEach(libraryBooks) { userBook in
                            NavigationLink(value: userBook) {
                                BookRowView(userBook: userBook)
                            }
                        }
                        .onDelete(perform: deleteItems)
                    }
                }
            }
            .navigationTitle("Library")
            .navigationDestination(for: UserBook.self) { book in
                BookDetailsView(book: book)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let bookToDelete = libraryBooks[index]
                if let bookIndex = allBooks.firstIndex(of: bookToDelete) {
                    modelContext.delete(allBooks[bookIndex])
                }
            }
        }
    }
}

#Preview {
    LibraryView()
        .modelContainer(for: [UserBook.self, BookMetadata.self], inMemory: true)
}