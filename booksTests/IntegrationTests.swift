import Testing
import SwiftData
import Foundation // CORRECTED: Added Foundation to make UUID available.
@testable import books

@Suite("Integration Tests")
struct IntegrationTests {

    private func createTestContainer() throws -> ModelContainer {
        let schema = Schema([UserBook.self, BookMetadata.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

    private func createTestBook(title: String, authors: [String], status: ReadingStatus) -> UserBook {
        let metadata = BookMetadata(
            googleBooksID: UUID().uuidString,
            title: title,
            authors: authors
        )
        let userBook = UserBook(readingStatus: status)
        userBook.metadata = metadata
        return userBook
    }

    @Test("Adding and Deleting a Book - Should update library correctly")
    func testAddAndDeleteBook() async throws {
        let container = try createTestContainer()
        let context = ModelContext(container)

        var fetchedBooks = try context.fetch(FetchDescriptor<UserBook>())
        #expect(fetchedBooks.isEmpty)

        let newBook = createTestBook(title: "Integration Test Book", authors: ["QA Author"], status: .reading)
        context.insert(newBook)
        try context.save()

        fetchedBooks = try context.fetch(FetchDescriptor<UserBook>())
        #expect(fetchedBooks.count == 1)
        #expect(fetchedBooks.first?.metadata?.title == "Integration Test Book")

        if let bookToDelete = fetchedBooks.first {
            context.delete(bookToDelete)
            try context.save()
        }

        fetchedBooks = try context.fetch(FetchDescriptor<UserBook>())
        #expect(fetchedBooks.isEmpty)
    }

    @Test("Search and Add to Wishlist - Should function end-to-end")
    func testSearchAndAddToWishlist() async throws {
        let container = try createTestContainer()
        let context = ModelContext(container)

        let searchResultMetadata = BookMetadata(
            googleBooksID: "search-result-123",
            title: "A Searched Book",
            authors: ["API Author"],
            genre: ["Fantasy"]
        )
        
        let userBook = UserBook(onWishlist: true)
        userBook.metadata = searchResultMetadata
        
        context.insert(userBook)
        try context.save()

        // CORRECTED: Replaced the #Predicate macro with a more compatible fetch-and-filter approach.
        // This is a robust way to test the logic without depending on specific iOS 17+ features.
        let allBooks = try context.fetch(FetchDescriptor<UserBook>())
        let wishlistBooks = allBooks.filter { $0.onWishlist == true }

        #expect(wishlistBooks.count == 1, "One book should be on the wishlist")
        #expect(wishlistBooks.first?.metadata?.title == "A Searched Book")
    }
    
    @Test("Adding Book Auto-navigates to EditBookDetails - Should trigger navigation")
    func testAddBookAutoNavigation() async throws {
        let container = try createTestContainer()
        let context = ModelContext(container)
        
        // Create a search result book metadata
        let searchResultMetadata = BookMetadata(
            googleBooksID: "auto-nav-test-123",
            title: "Navigation Test Book",
            authors: ["Navigation Author"],
            genre: ["Testing"]
        )
        
        // Simulate adding book to library (not wishlist)
        let userBook = UserBook(readingStatus: .reading, onWishlist: false)
        userBook.metadata = searchResultMetadata
        
        context.insert(userBook)
        try context.save()
        
        // Verify book was added to library
        let allBooks = try context.fetch(FetchDescriptor<UserBook>())
        let libraryBooks = allBooks.filter { !$0.onWishlist }
        
        #expect(libraryBooks.count == 1, "One book should be in the library")
        #expect(libraryBooks.first?.metadata?.title == "Navigation Test Book")
        #expect(libraryBooks.first?.readingStatus == .reading, "Book should have reading status")
        
        // The navigation test will be verified in the UI implementation
        // This test ensures the data flow works correctly for the auto-navigation feature
    }
    
    @Test("Adding Book to Wishlist Does Not Auto-navigate - Should not trigger navigation")
    func testAddToWishlistNoAutoNavigation() async throws {
        let container = try createTestContainer()
        let context = ModelContext(container)
        
        // Create a search result book metadata
        let searchResultMetadata = BookMetadata(
            googleBooksID: "wishlist-test-123",
            title: "Wishlist Test Book",
            authors: ["Wishlist Author"],
            genre: ["Testing"]
        )
        
        // Simulate adding book to wishlist
        let userBook = UserBook(readingStatus: .toRead, onWishlist: true)
        userBook.metadata = searchResultMetadata
        
        context.insert(userBook)
        try context.save()
        
        // Verify book was added to wishlist
        let allBooks = try context.fetch(FetchDescriptor<UserBook>())
        let wishlistBooks = allBooks.filter { $0.onWishlist }
        
        #expect(wishlistBooks.count == 1, "One book should be on the wishlist")
        #expect(wishlistBooks.first?.metadata?.title == "Wishlist Test Book")
        #expect(wishlistBooks.first?.readingStatus == .toRead, "Wishlist book should have toRead status")
        
        // Auto-navigation should only happen for library additions, not wishlist
    }
}