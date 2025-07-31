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
        let filtered = switch filter {
        case .library:
            allBooks.filter { !$0.onWishlist && $0.readingStatus != .toRead }
        case .wishlist:
            allBooks.filter { $0.onWishlist }
        }
        
        // Remove any potential duplicates based on ID to prevent ForEach errors
        var uniqueBooks: [UserBook] = []
        var seenIDs: Set<UUID> = []
        
        for book in filtered {
            if !seenIDs.contains(book.id) {
                uniqueBooks.append(book)
                seenIDs.insert(book.id)
            }
        }
        
        return uniqueBooks
    }
    
    init(filter: Filter = .library) {
        self.filter = filter
    }
    
    var body: some View {
        Group {
            if displayedBooks.isEmpty {
                ContentUnavailableView {
                    Label(filter.emptyTitle, systemImage: filter.emptySystemImage)
                        .foregroundColor(Theme.Color.PrimaryText)
                } description: {
                    Text(filter.emptyDescription)
                        .foregroundColor(Theme.Color.SecondaryText)
                }
            } else {
                List {
                    ForEach(displayedBooks, id: \.id) { book in
                        NavigationLink(value: book) {
                            BookListItem(book: book)
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing) {
                            // Add swipe action for author search
                            if let firstAuthor = book.metadata?.authors.first {
                                NavigationLink(value: firstAuthor) {
                                    Label("Author", systemImage: "person.fill")
                                }
                                .tint(Theme.Color.PrimaryAction)
                            }
                        }
                    }
                    .onDelete(perform: deleteItems)
                }
                .background(Theme.Color.Surface)
            }
        }
        .background(Theme.Color.Surface)
        .navigationTitle(filter.navigationTitle)
        // Handle navigation destinations at the LibraryView level
        .navigationDestination(for: UserBook.self) { book in
            BookDetailsView(book: book)
        }
        .navigationDestination(for: String.self) { authorName in
            AuthorSearchResultsView(authorName: authorName)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !displayedBooks.isEmpty && filter == .library {
                    EditButton()
                }
            }
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        guard filter == .library else { return }   // Disallow delete from wishlist
        withAnimation {
            for index in offsets {
                let bookToDelete = displayedBooks[index]
                if let actualBook = allBooks.first(where: { $0.id == bookToDelete.id }) {
                    modelContext.delete(actualBook)
                }
            }
        }
    }
}

#Preview {
    LibraryView()
        .modelContainer(for: [UserBook.self, BookMetadata.self], inMemory: true)
}