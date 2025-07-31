import SwiftUI
import SwiftData

struct LibraryView: View {
    enum Filter {
        case library
        case wishlist
        
        var navigationTitle: String {
            switch self {
            case .library:  "Library"
            case .wishlist: "Wishlist"
            }
        }
        
        var emptyTitle: String {
            switch self {
            case .library:  "Your Library is Empty"
            case .wishlist: "Your Wishlist is Empty"
            }
        }
        
        var emptySystemImage: String {
            switch self {
            case .library:  "book.closed"
            case .wishlist: "wand.and.stars"
            }
        }
        
        var emptyDescription: String {
            switch self {
            case .library:  "Add a book from the Search tab to get started."
            case .wishlist: "Add books you want to read to your wishlist."
            }
        }
    }
    
    let filter: Filter
    
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\UserBook.dateAdded, order: .reverse)])
    private var allBooks: [UserBook]
    
    private var displayedBooks: [UserBook] {
        switch filter {
        case .library:
            allBooks.filter { !$0.onWishlist && $0.readingStatus != .toRead }
        case .wishlist:
            allBooks.filter { $0.onWishlist }
        }
    }
    
    init(filter: Filter = .library) {
        self.filter = filter
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if displayedBooks.isEmpty {
                    ContentUnavailableView {
                        Label(filter.emptyTitle, systemImage: filter.emptySystemImage)
                    } description: {
                        Text(filter.emptyDescription)
                    }
                } else {
                    List {
                        ForEach(displayedBooks) { book in
                            BookListItem(book: book)
                        }
                        .onDelete(perform: deleteItems)
                    }
                }
            }
            .navigationTitle(filter.navigationTitle)
            .navigationDestination(for: UserBook.self) { book in
                BookDetailsView(book: book)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !displayedBooks.isEmpty && filter == .library {
                        EditButton()
                    }
                }
            }
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        guard filter == .library else { return }   // Disallow delete from wishlist
        withAnimation {
            for index in offsets {
                let bookToDelete = displayedBooks[index]
                if let actualIndex = allBooks.firstIndex(of: bookToDelete) {
                    modelContext.delete(allBooks[actualIndex])
                }
            }
        }
    }
}

#Preview {
    LibraryView()
        .modelContainer(for: [UserBook.self, BookMetadata.self], inMemory: true)
}