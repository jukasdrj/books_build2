import SwiftUI
import SwiftData

struct WishlistView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: [SortDescriptor(\UserBook.dateAdded, order: .reverse)])
    private var allBooks: [UserBook]
    
    private var wishlistBooks: [UserBook] {
        allBooks.filter { $0.onWishlist }
    }
    
    @State private var showingAddBook = false
    
    var body: some View {
        NavigationStack {
            Group {
                if wishlistBooks.isEmpty {
                    ContentUnavailableView {
                        Label("Your Wishlist is Empty", systemImage: "wand.and.stars")
                    } description: {
                        Text("Add books you want to read to your wishlist.")
                    } actions: {
                        Button("Add Book") {
                            showingAddBook = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        // CORRECTED: Because UserBook is now Identifiable (thanks to the 'id' property),
                        // we can remove `id: \.self`. SwiftUI will automatically and correctly
                        // use the unique UUID for each book, fixing the crash.
                        ForEach(wishlistBooks) { book in
                            BookListItem(book: book)
                        }
                    }
                }
            }
            .navigationTitle("Wishlist")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddBook = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddBook) {
            AddBookView()
        }
    }
}
